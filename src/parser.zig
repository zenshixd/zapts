const std = @import("std");

const Token = @import("consts.zig").Token;
const TokenType = @import("consts.zig").TokenType;

const Reporter = @import("reporter.zig");
const StringInterner = @import("string_interner.zig");
const StringId = @import("string_interner.zig").StringId;
const Type = @import("type.zig");

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
const TestParser = @import("test_parser.zig");
const MarkerList = @import("test_parser.zig").MarkerList;

const parseStatement = @import("parser/statements.zig").parseStatement;

const Parser = @This();
pub const ParserError = error{ SyntaxError, OutOfMemory };

const Checkpoint = struct {
    tok_idx: Token.Index,
    node_idx: u32,
    extra_idx: u32,
};

gpa: std.mem.Allocator,
buffer: [:0]const u8,
reporter: *Reporter,
lexer: Lexer,
tokens: std.ArrayList(Token),
cur_token: Token.Index = Token.at(0),
nodes: std.ArrayList(AST.Raw),
extra: std.ArrayList(u32),
str_interner: StringInterner = .{},
types: std.ArrayList(Type),

pub fn init(gpa: std.mem.Allocator, buffer: [:0]const u8, reporter: *Reporter) Parser {
    var nodes = std.ArrayList(AST.Raw).init(gpa);
    _ = nodes.addOne() catch @panic("out of memory");

    return .{
        .gpa = gpa,
        .reporter = reporter,
        .buffer = buffer,
        .lexer = .{ .reporter = reporter, .buffer = buffer },
        .tokens = std.ArrayList(Token).init(gpa),
        .nodes = nodes,
        .extra = std.ArrayList(u32).init(gpa),
        .types = Type.initArray(gpa),
    };
}

pub fn deinit(self: *Parser) void {
    self.tokens.deinit();
    self.nodes.deinit();
    self.extra.deinit();
    self.types.deinit();
    self.str_interner.deinit(self.gpa);
}

pub const getNode = AST.getNode;
pub const getRawNode = AST.getRawNode;
pub const addNode = AST.addNode;
pub const listToSubrange = AST.listToSubrange;

pub fn lookupStr(self: *Parser, string_id: StringId) []const u8 {
    return self.str_interner.lookup(string_id).?;
}

pub fn internStr(self: *Parser, tok_idx: Token.Index) StringId {
    if (tok_idx == Token.Empty) {
        return StringId.none;
    }

    return self.str_interner.intern(self.gpa, self.tokens.items[tok_idx.int()].literal(self.buffer));
}
pub fn parse(self: *Parser) ParserError!AST.Node.Index {
    var nodes = std.ArrayList(AST.Node.Index).init(self.gpa);
    defer nodes.deinit();

    while (!self.match(TokenType.Eof)) {
        if (self.match(TokenType.NewLine) or self.match(TokenType.LineComment) or self.match(TokenType.MultilineComment)) {
            continue;
        }

        if (try parseStatement(self)) |node| {
            try nodes.append(node);
        }
    }

    const subrange = self.listToSubrange(nodes.items);

    self.nodes.items[0] = .{
        .tag = .root,
        .main_token = Token.at(0),
        .data = .{ .lhs = subrange.start.int(), .rhs = subrange.end.int() },
    };
    return AST.Node.at(0);
}

pub fn endIndexAt(self: *Parser, at: u32) u32 {
    if (at == 0) {
        return 0;
    }

    return self.tokens.items[at - 1].end;
}

pub fn advance(self: *Parser) Token.Index {
    //std.debug.print("advancing from {}\n", .{self.lexer.getToken(self.cur_token)});
    self.cur_token = self.cur_token.inc(1);
    return self.cur_token;
}

pub fn advanceBy(self: *Parser, offset: u32) Token.Index {
    self.cur_token = self.cur_token.inc(offset);
    return self.cur_token;
}

pub fn match(self: *Parser, comptime token_type: anytype) bool {
    if (comptime TokenType.isTokenType(token_type)) {
        return self.matchOne(token_type);
    }

    if (comptime TokenType.isArrayOfTokenType(token_type)) {
        return self.matchMany(token_type);
    }

    @compileError("Expected TokenType or []const TokenType");
}

pub fn matchOne(self: *Parser, comptime token_type: TokenType) bool {
    if (self.peekMatch(token_type)) {
        _ = self.advance();
        return true;
    }

    return false;
}

pub fn matchMany(self: *Parser, comptime token_types: anytype) bool {
    if (self.peekMatchMany(token_types)) {
        self.cur_token = self.cur_token.inc(token_types.len);
        return true;
    }

    return false;
}

pub fn peekMatch(self: *Parser, token_type: TokenType) bool {
    return self.peekMatchAt(token_type, self.cur_token.int());
}

pub fn peekMatchMany(self: *Parser, comptime token_types: anytype) bool {
    inline for (token_types, 0..) |tok_type, i| {
        if (!self.peekMatchAt(tok_type, self.cur_token.inc(i).int())) {
            return false;
        }
    }

    return true;
}

pub fn peekMatchAt(self: *Parser, token_type: TokenType, index: u32) bool {
    if (index == self.tokens.items.len) {
        const tok = self.lexer.next(self.endIndexAt(index));
        self.tokens.append(tok) catch unreachable;
    } else if (index > self.tokens.items.len) {
        @panic("peekMatchAt: index out of bounds");
    }

    return self.tokens.items[index].type == token_type;
}

pub fn consume(self: *Parser, token_type: TokenType, comptime error_msg: diagnostics.DiagnosticMessage, args: anytype) ParserError!Token.Index {
    if (self.consumeOrNull(token_type)) |tok| {
        return tok;
    }

    return self.fail(error_msg, args);
}

pub fn consumeOrNull(self: *Parser, token_type: TokenType) ?Token.Index {
    if (self.peekMatch(token_type)) {
        const tok = self.cur_token;
        _ = self.advance();
        return tok;
    }

    return null;
}

pub fn checkpoint(self: *Parser) Checkpoint {
    return Checkpoint{
        .tok_idx = self.cur_token,
        .node_idx = @intCast(self.nodes.items.len),
        .extra_idx = @intCast(self.extra.items.len),
    };
}

pub fn rewindTo(self: *Parser, cp: Checkpoint) void {
    self.cur_token = cp.tok_idx;
    self.nodes.items.len = cp.node_idx;
    self.extra.items.len = cp.extra_idx;
}

pub fn setContext(self: *Parser, context: Context) void {
    self.lexer.setContext(context);
    self.tokens.items.len = self.cur_token.int();
}

pub fn unsetContext(self: *Parser, context: Context) void {
    self.lexer.unsetContext(context);
}

pub fn fail(self: *Parser, comptime error_msg: diagnostics.DiagnosticMessage, args: anytype) ParserError {
    self.reporter.put(error_msg, args, self.cur_token);
    return ParserError.SyntaxError;
}

pub fn needsSemicolon(self: Parser, node: AST.Node.Index) bool {
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

var test_reporter: Reporter = undefined;
pub fn testInstance(text: [:0]const u8) Parser {
    test_reporter = Reporter.init(std.testing.allocator);
    return Parser.init(std.testing.allocator, text, &test_reporter);
}

pub fn testDeinit(self: *Parser) void {
    self.reporter.deinit();
    self.deinit();
}

test "should parse statements" {
    const text =
        \\a;
        \\b;
        \\c;
    ;

    try TestParser.run(text, parse, struct {
        pub fn expect(t: TestParser, node_idx: AST.Node.Index, _: MarkerList(text)) !void {
            const node = t.parser.getNode(node_idx);
            try std.testing.expectEqualDeep(AST.Node{
                .root = @constCast(&[_]AST.Node.Index{ AST.Node.at(1), AST.Node.at(2), AST.Node.at(3) }),
            }, node);
        }
    });
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
