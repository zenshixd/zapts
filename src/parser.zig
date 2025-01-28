const std = @import("std");

const CompilationError = @import("errors.zig").CompilationError;
const CompilationErrorMessage = @import("errors.zig").CompilationErrorMessage;

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
const AST = @import("ast.zig");
const diagnostics = @import("diagnostics.zig");

const parseStatement = @import("parser/statements.zig").parseStatement;

const Token = @import("consts.zig").Token;
const TokenType = @import("consts.zig").TokenType;

const Self = @This();

gpa: std.mem.Allocator,
buffer: [:0]const u8,
tokens: []const Token,
cur_token: Token.Index,
nodes: std.ArrayList(AST.Raw),
extra: std.ArrayList(u32),
errors: std.MultiArrayList(CompilationErrorMessage),

pub fn init(gpa: std.mem.Allocator, buffer: [:0]const u8) !Self {
    var lexer = Lexer.init(gpa, buffer);
    var nodes = std.ArrayList(AST.Raw).init(gpa);
    nodes.append(AST.Raw{ .tag = .root, .main_token = Token.at(0), .data = .{ .lhs = 0, .rhs = 0 } }) catch unreachable;

    return Self{
        .cur_token = Token.at(0),
        .gpa = gpa,
        .buffer = buffer,
        .tokens = try lexer.tokenize(),
        .nodes = nodes,
        .extra = std.ArrayList(u32).init(gpa),
        .errors = std.MultiArrayList(CompilationErrorMessage){},
    };
}

pub fn deinit(self: *Self) void {
    for (self.errors.items(.message)) |message| {
        self.gpa.free(message);
    }
    self.errors.deinit(self.gpa);
    self.nodes.deinit();
    self.extra.deinit();
    self.gpa.free(self.tokens);
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

pub fn token(self: Self) Token {
    if (self.cur_token.int() >= self.tokens.len) {
        return .{ .type = .Eof, .start = 0, .end = 0 };
    }
    return self.tokens[self.cur_token.int()];
}

pub fn advance(self: *Self) Token.Index {
    //std.debug.print("advancing from {}\n", .{self.lexer.getToken(self.cur_token)});
    self.cur_token = self.cur_token.inc(1);
    return self.cur_token;
}

pub fn match(self: *Self, comptime token_type: anytype) bool {
    const typeInfo = @typeInfo(@TypeOf(token_type));
    const is_token_type = @TypeOf(token_type) == TokenType;
    const is_array_of_token_type = typeInfo == .array and typeInfo.array.child == TokenType;
    assert(is_token_type or is_array_of_token_type);

    if (is_token_type and self.peekMatch(token_type)) {
        _ = self.advance();
        return true;
    }

    if (is_array_of_token_type and self.peekMatchMany(token_type)) {
        self.cur_token = self.cur_token.inc(token_type.len);
        return true;
    }

    return false;
}

pub fn peekMatch(self: Self, token_type: TokenType) bool {
    return self.token().type == token_type;
}

pub fn peekMatchMany(self: Self, comptime token_types: anytype) bool {
    inline for (token_types, 0..) |tok_type, i| {
        if (self.tokens[self.cur_token.int() + i].type != tok_type) {
            return false;
        }
    }
    return true;
}

pub fn consume(self: *Self, token_type: TokenType, comptime error_msg: diagnostics.DiagnosticMessage, args: anytype) CompilationError!Token.Index {
    if (self.consumeOrNull(token_type)) |tok| {
        return tok;
    }

    return self.fail(error_msg, args);
}

pub fn consumeOrNull(self: *Self, token_type: TokenType) ?Token.Index {
    if (self.token().type == token_type) {
        const tok = self.cur_token;
        _ = self.advance();
        return tok;
    }

    return null;
}

pub fn rewind(self: *Self) void {
    if (self.cur_token.int() - 1 >= 0) {
        self.cur_token = self.cur_token.dec(1);
    }
}

pub fn fail(self: *Self, comptime error_msg: diagnostics.DiagnosticMessage, args: anytype) CompilationError {
    self.errors.append(self.gpa, CompilationErrorMessage.init(self.gpa, error_msg, args, self.cur_token)) catch @panic("Out of memory");
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
