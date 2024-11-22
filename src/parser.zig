const std = @import("std");
const assert = std.debug.assert;
const expectEqual = std.testing.expectEqual;
const expectEqualStrings = std.testing.expectEqualStrings;
const expectEqualSlices = std.testing.expectEqualSlices;
const expectStringStartsWith = std.testing.expectStringStartsWith;
const expectError = std.testing.expectError;

const Lexer = @import("lexer.zig");
const AST = @import("ast.zig");
const diagnostics = @import("diagnostics.zig");

const parseStatement = @import("parser/statements.zig").parseStatement;

const Token = @import("consts.zig").Token;
const TokenType = @import("consts.zig").TokenType;

pub const ParserError = error{ SyntaxError, OutOfMemory };

const Self = @This();

gpa: std.mem.Allocator,
buffer: [:0]const u8,
tokens: []const Token,
cur_token: Token.Index,
pool: AST.Pool,
errors: std.ArrayList(u8),

pub fn init(gpa: std.mem.Allocator, buffer: [:0]const u8) !Self {
    var lexer = Lexer.init(gpa, buffer);

    return Self{
        .cur_token = 0,
        .gpa = gpa,
        .buffer = buffer,
        .tokens = lexer.tokenize(),
        .pool = AST.Pool.init(gpa),
        .errors = std.ArrayList(u8).init(gpa),
    };
}

pub fn deinit(self: *Self) void {
    self.errors.deinit();
    self.pool.deinit();
    self.gpa.free(self.tokens);
}

pub fn parse(self: *Self) ParserError!AST.Node.Index {
    var nodes = std.ArrayList(AST.Node.Index).init(self.gpa);
    defer nodes.deinit();

    while (!self.match(TokenType.Eof)) {
        if (self.match(TokenType.NewLine) or self.match(TokenType.LineComment) or self.match(TokenType.MultilineComment)) {
            continue;
        }

        try nodes.append(try parseStatement(self));
    }

    const subrange = self.pool.listToSubrange(nodes.items);

    assert(self.pool.nodes.items[0].tag == .root);
    self.pool.nodes.items[0].data = .{ .lhs = subrange.start, .rhs = subrange.end };
    return 0;
}

pub fn token(self: Self) Token {
    if (self.cur_token >= self.tokens.len) {
        return .{ .type = .Eof, .start = 0, .end = 0 };
    }
    return self.tokens[self.cur_token];
}

pub fn advance(self: *Self) Token.Index {
    //std.debug.print("advancing from {}\n", .{self.lexer.getToken(self.cur_token)});
    self.cur_token += 1;
    return self.cur_token;
}

pub fn match(self: *Self, token_type: TokenType) bool {
    if (self.peekMatch(token_type)) {
        _ = self.advance();
        return true;
    }
    return false;
}

pub fn peekMatch(self: Self, token_type: TokenType) bool {
    return self.token().type == token_type;
}

pub fn peekMatchMany(self: Self, comptime token_types: anytype) bool {
    inline for (token_types, 0..) |tok_type, i| {
        if (self.tokens[self.cur_token + i].type != tok_type) {
            return false;
        }
    }
    return true;
}

pub fn consume(self: *Self, token_type: TokenType, comptime error_msg: diagnostics.DiagnosticMessage, args: anytype) ParserError!Token.Index {
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
    if (self.cur_token - 1 >= 0) {
        self.cur_token -= 1;
    }
}

pub fn fail(self: *Self, comptime error_msg: diagnostics.DiagnosticMessage, args: anytype) ParserError {
    self.emitError(error_msg, args);
    return ParserError.SyntaxError;
}

pub fn emitError(self: *Self, comptime error_msg: diagnostics.DiagnosticMessage, args: anytype) void {
    // std.debug.print("TS" ++ error_msg.code ++ ": " ++ error_msg.message ++ "\n", args);
    // std.debug.print("Token {}\n", .{self.token()});

    std.fmt.format(self.errors.writer(), "TS" ++ error_msg.code ++ ": " ++ error_msg.message ++ "\n", args) catch unreachable;
    std.fmt.format(self.errors.writer(), "Token: {}\n", .{self.token()}) catch unreachable;
}

pub fn needsSemicolon(pool: AST.Pool, node: AST.Node.Index) bool {
    if (node == AST.Node.Empty) {
        return false;
    }
    const nodeRaw = pool.getRawNode(node);
    var tag = nodeRaw.tag;
    if (tag == .export_node or tag == .export_default) {
        tag = pool.getRawNode(nodeRaw.data.lhs).tag;
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

pub fn expectAST(fn_ptr: fn (parser: *Self) ParserError!AST.Node.Index, expected: AST.Node, text: [:0]const u8) !void {
    var parser = try Self.init(std.testing.allocator, text);
    defer parser.deinit();

    const node = try fn_ptr(&parser);
    try std.testing.expectEqualDeep(expected, parser.pool.getNode(node));
}

pub fn expectMaybeAST(fn_ptr: fn (parser: *Self) ParserError!?AST.Node.Index, expected: ?AST.Node, text: [:0]const u8) !void {
    var parser = try Self.init(std.testing.allocator, text);
    defer parser.deinit();

    const maybe_node = try fn_ptr(&parser);
    if (expected) |expected_node| {
        if (maybe_node == null) {
            std.debug.print("expected {any}, got null\n", .{expected});
            return error.TestExpectedEqual;
        }

        try std.testing.expectEqualDeep(expected_node, parser.pool.getNode(maybe_node.?));
    } else {
        try expectEqual(null, maybe_node);
    }
}

pub fn expectASTAndToken(fn_ptr: fn (parser: *Self) ParserError!?AST.Node.Index, expected: ?AST.Node, tok_type: TokenType, token_value: []const u8, text: [:0]const u8) !void {
    var parser = try Self.init(std.testing.allocator, text);
    defer parser.deinit();

    const maybe_node = try fn_ptr(&parser);
    if (expected) |expected_node| {
        if (maybe_node) |node| {
            try std.testing.expectEqualDeep(expected_node, parser.pool.getNode(node));
            try parser.expectToken(tok_type, node);
            try parser.expectTokenValue(token_value, node);
        } else if (expected != null) {
            std.debug.print("expected {any}, got null\n", .{expected});
            return error.TestExpectedEqual;
        }
    } else {
        try expectEqual(null, maybe_node);
    }
}

pub fn expectSyntaxError(
    fn_ptr: anytype,
    comptime text: [:0]const u8,
    comptime expected_error: diagnostics.DiagnosticMessage,
    args: anytype,
) !void {
    var parser = try Self.init(std.testing.allocator, text);
    defer parser.deinit();

    const nodeOrError = fn_ptr(&parser);

    try expectError(ParserError.SyntaxError, nodeOrError);
    var buffer: [512]u8 = undefined;
    const expected_string = try std.fmt.bufPrint(&buffer, "TS" ++ expected_error.code ++ ": " ++ expected_error.message ++ "\n", args);
    try expectStringStartsWith(parser.errors.items, expected_string);
}

pub fn expectToken(self: *Self, tok_type: TokenType, node: AST.Node.Index) !void {
    const raw = self.pool.getRawNode(node);
    try expectEqual(tok_type, self.tokens[raw.main_token].type);
}

pub fn expectTokenValue(self: *Self, expected_value: []const u8, node: AST.Node.Index) !void {
    const raw = self.pool.getRawNode(node);
    try expectEqualStrings(expected_value, self.tokens[raw.main_token].literal(self.buffer));
}

pub fn expectSimpleMethod(parser: Self, node_idx: AST.Node.Index, expected_flags: anytype, expected_name: []const u8) !void {
    const node = parser.pool.getNode(node_idx);
    try expectEqual(expected_flags, node.object_method.flags);

    const name_node = parser.pool.getRawNode(node.object_method.name);
    const name_token = parser.tokens[name_node.main_token].literal(parser.buffer);
    try expectEqualStrings(expected_name, name_token);
}

pub fn expectNodesToEqual(parser: Self, expected_nodes: []const AST.Raw) !void {
    try expectEqualSlices(AST.Raw, expected_nodes, parser.pool.nodes.items[1..]);
}

pub fn expectTSError(parser: Self, comptime expected_error: diagnostics.DiagnosticMessage, comptime args: anytype) !void {
    var buffer: [512]u8 = undefined;
    const expected_string = try std.fmt.bufPrint(&buffer, "TS" ++ expected_error.code ++ ": " ++ expected_error.message, args);
    try expectEqualStrings(expected_string, parser.errors.items[0]);
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
