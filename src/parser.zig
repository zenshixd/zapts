const std = @import("std");

const CompilationError = @import("consts.zig").CompilationError;
const Reporter = @import("reporter.zig");

const ErrorUnionOf = @import("meta.zig").ErrorUnionOf;
const ReturnTypeOf = @import("meta.zig").ReturnTypeOf;

const assert = std.debug.assert;
const expectEqual = std.testing.expectEqual;
const expectEqualStrings = std.testing.expectEqualStrings;
const expectEqualSlices = std.testing.expectEqualSlices;
const expectEqualDeep = std.testing.expectEqualDeep;
const expectStringStartsWith = std.testing.expectStringStartsWith;
const expectError = std.testing.expectError;

const Lexer = @import("lexer.zig");
const Context = @import("lexer.zig").Context;
const AST = @import("ast.zig");
const diagnostics = @import("diagnostics.zig");

const parseStatement = @import("parser/statements.zig").parseStatement;

const Token = @import("consts.zig").Token;
const TokenType = @import("consts.zig").TokenType;

const Self = @This();

const Checkpoint = struct {
    tok_idx: Token.Index,
    node_idx: u32,
    extra_idx: u32,
};

gpa: std.mem.Allocator,
reporter: *Reporter,
lexer: Lexer,
buffer: [:0]const u8,
tokens: std.ArrayList(Token),
cur_token: Token.Index,
nodes: std.ArrayList(AST.Raw),
extra: std.ArrayList(u32),

pub fn init(gpa: std.mem.Allocator, buffer: [:0]const u8, reporter: *Reporter) !Self {
    var nodes = std.ArrayList(AST.Raw).init(gpa);
    nodes.append(AST.Raw{ .tag = .root, .main_token = Token.at(0), .data = .{ .lhs = 0, .rhs = 0 } }) catch unreachable;

    return Self{
        .gpa = gpa,
        .reporter = reporter,
        .lexer = Lexer.init(gpa, buffer, reporter),
        .buffer = buffer,
        .tokens = std.ArrayList(Token).init(gpa),
        .cur_token = Token.at(0),
        .nodes = nodes,
        .extra = std.ArrayList(u32).init(gpa),
    };
}

pub fn deinit(self: *Self) void {
    self.nodes.deinit();
    self.extra.deinit();
    self.tokens.deinit();
}

pub const getNode = AST.getNode;
pub const getRawNode = AST.getRawNode;
pub const addNode = AST.addNode;

pub fn parse(self: *Self) CompilationError!AST.Node.Index {
    var nodes = std.ArrayList(AST.Node.Index).init(self.gpa);
    defer nodes.deinit();

    while (!self.match(TokenType.Eof)) {
        if (self.match(TokenType.NewLine) or self.match(TokenType.LineComment) or self.match(TokenType.MultilineComment)) {
            continue;
        }

        try nodes.append(try parseStatement(self));
    }

    const subrange = self.listToSubrange(nodes.items);

    assert(self.nodes.items[0].tag == .root);
    self.nodes.items[0].data = .{ .lhs = subrange.start, .rhs = subrange.end };
    return 0;
}

pub fn endIndexAt(self: *Self, at: u32) u32 {
    if (at == 0) {
        return 0;
    }

    return self.tokens.items[at - 1].end;
}

pub fn advance(self: *Self) Token.Index {
    //std.debug.print("advancing from {}\n", .{self.lexer.getToken(self.cur_token)});
    self.cur_token = self.cur_token.inc(1);
    return self.cur_token;
}

pub fn advanceBy(self: *Self, offset: u32) Token.Index {
    self.cur_token = self.cur_token.inc(offset);
    return self.cur_token;
}

pub fn match(self: *Self, comptime token_type: anytype) bool {
    return if (comptime TokenType.isTokenType(token_type))
        self.matchOne(token_type)
    else if (comptime TokenType.isArrayOfTokenType(token_type))
        self.matchMany(token_type)
    else
        @compileError("Expected TokenType or []const TokenType");
}

pub fn matchOne(self: *Self, comptime token_type: TokenType) bool {
    if (self.peekMatch(token_type)) {
        _ = self.advance();
        return true;
    }

    return false;
}

pub fn matchMany(self: *Self, comptime token_types: anytype) bool {
    if (self.peekMatchMany(token_types)) {
        self.cur_token = self.cur_token.inc(token_types.len);
        return true;
    }

    return false;
}

pub fn peekMatch(self: *Self, token_type: TokenType) bool {
    return self.peekMatchAt(token_type, self.cur_token.int());
}

pub fn peekMatchMany(self: *Self, comptime token_types: anytype) bool {
    inline for (token_types, 0..) |tok_type, i| {
        if (!self.peekMatchAt(tok_type, self.cur_token.inc(i).int())) {
            return false;
        }
    }

    return true;
}

pub fn peekMatchAt(self: *Self, token_type: TokenType, index: u32) bool {
    if (index == self.tokens.items.len) {
        const tok = self.lexer.next(self.endIndexAt(index));
        self.tokens.append(tok) catch unreachable;
    } else if (index > self.tokens.items.len) {
        @panic("peekMatchAt: index out of bounds");
    }

    return self.tokens.items[index].type == token_type;
}

pub fn consume(self: *Self, token_type: TokenType, comptime error_msg: diagnostics.DiagnosticMessage, args: anytype) CompilationError!Token.Index {
    if (self.consumeOrNull(token_type)) |tok| {
        return tok;
    }

    return self.fail(error_msg, args);
}

pub fn consumeOrNull(self: *Self, token_type: TokenType) ?Token.Index {
    if (self.peekMatch(token_type)) {
        const tok = self.cur_token;
        _ = self.advance();
        return tok;
    }

    return null;
}

pub fn checkpoint(self: *Self) Checkpoint {
    return Checkpoint{
        .tok_idx = self.cur_token,
        .node_idx = @intCast(self.nodes.items.len),
        .extra_idx = @intCast(self.extra.items.len),
    };
}

pub fn rewindTo(self: *Self, cp: Checkpoint) void {
    self.cur_token = cp.tok_idx;
    self.nodes.items.len = cp.node_idx;
    self.extra.items.len = cp.extra_idx;
}

pub fn setContext(self: *Self, context: Context) void {
    self.lexer.setContext(context);
    self.tokens.items.len = self.cur_token.int();
}

pub fn unsetContext(self: *Self, context: Context) void {
    self.lexer.unsetContext(context);
}

pub fn fail(self: *Self, comptime error_msg: diagnostics.DiagnosticMessage, args: anytype) CompilationError {
    self.reporter.put(error_msg, args, self.cur_token);
    return CompilationError.SyntaxError;
}

pub fn needsSemicolon(self: Self, node: AST.Node.Index) bool {
    if (node == AST.Node.Empty) {
        return false;
    }
    const nodeRaw = self.getRawNode(node);
    var tag = nodeRaw.tag;
    if (tag == .export_node or tag == .export_default) {
        tag = self.getRawNode(AST.Node.at(nodeRaw.data.lhs)).tag;
    }

    return switch (tag) {
        .block,
        .func_decl,
        .@"for",
        .for_in,
        .for_of,
        .@"while",
        .do_while,
        .@"if",
        .class_decl,
        .class_method,
        .interface_decl,
        .object_method,
        => false,
        else => true,
    };
}

test {
    _ = @import("parser/primary.zig");
    _ = @import("parser/binary.zig");
    _ = @import("parser/loops.zig");
    _ = @import("parser/imports.zig");
    _ = @import("parser/classes.zig");
    _ = @import("parser/functions.zig");
    _ = @import("parser/expressions.zig");
    _ = @import("parser/statements.zig");
    _ = @import("parser/types.zig");
}
