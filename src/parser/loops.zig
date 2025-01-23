const std = @import("std");
const Parser = @import("../parser.zig");
const AST = @import("../ast.zig");
const TokenType = @import("../consts.zig").TokenType;
const ParserError = Parser.ParserError;
const diagnostics = @import("../diagnostics.zig");

const parseStatement = @import("statements.zig").parseStatement;
const parseExpression = @import("expressions.zig").parseExpression;
const parseDeclaration = @import("statements.zig").parseDeclaration;

const expectEqual = std.testing.expectEqual;
const expectEqualDeep = std.testing.expectEqualDeep;
const expectEqualStrings = std.testing.expectEqualStrings;
const expectError = std.testing.expectError;
const expectAST = Parser.expectAST;
const expectSyntaxError = Parser.expectSyntaxError;

pub fn parseBreakableStatement(parser: *Parser) ParserError!?AST.Node.Index {
    return try parseDoWhileStatement(parser) orelse
        try parseWhileStatement(parser) orelse
        try parseForStatement(parser);
}

pub fn parseDoWhileStatement(self: *Parser) ParserError!?AST.Node.Index {
    if (!self.match(TokenType.Do)) {
        return null;
    }

    const node = try parseStatement(self);
    _ = try self.consume(TokenType.While, diagnostics.ARG_expected, .{"while"});
    _ = try self.consume(TokenType.OpenParen, diagnostics.ARG_expected, .{"("});
    const condition = try parseExpression(self);
    _ = try self.consume(TokenType.CloseParen, diagnostics.ARG_expected, .{")"});
    _ = try self.consume(TokenType.Semicolon, diagnostics.ARG_expected, .{";"});

    return self.addNode(self.cur_token, AST.Node{ .do_while = .{
        .cond = condition,
        .body = node,
    } });
}

pub fn parseWhileStatement(self: *Parser) ParserError!?AST.Node.Index {
    if (!self.match(TokenType.While)) {
        return null;
    }

    _ = try self.consume(TokenType.OpenParen, diagnostics.ARG_expected, .{"("});
    const condition = try parseExpression(self);
    _ = try self.consume(TokenType.CloseParen, diagnostics.ARG_expected, .{")"});

    return self.addNode(self.cur_token, AST.Node{ .@"while" = .{
        .cond = condition,
        .body = try parseStatement(self),
    } });
}

pub fn parseForStatement(self: *Parser) ParserError!?AST.Node.Index {
    if (!self.match(TokenType.For)) {
        return null;
    }

    _ = try self.consume(TokenType.OpenParen, diagnostics.ARG_expected, .{"("});

    const for_inner = try parseForClassicStatement(self) orelse
        try parseForInStatement(self) orelse
        try parseForOfStatement(self) orelse
        return self.fail(diagnostics.declaration_or_statement_expected, .{});

    return for_inner;
}

pub fn parseForClassicStatement(self: *Parser) ParserError!?AST.Node.Index {
    const cp = self.cur_token;
    const init_node = if (self.peekMatch(TokenType.Semicolon)) AST.Node.Empty else try parseDeclaration(self) orelse try parseExpression(self);

    if (!self.match(TokenType.Semicolon)) {
        // TODO: there is no cleanup of created AST nodes - need to figure out how to do it
        self.cur_token = cp;
        return null;
    }
    const cond_node = if (self.peekMatch(TokenType.Semicolon)) AST.Node.Empty else try parseExpression(self);
    _ = try self.consume(TokenType.Semicolon, diagnostics.ARG_expected, .{";"});
    const post_node = if (self.peekMatch(TokenType.CloseParen)) AST.Node.Empty else try parseExpression(self);
    _ = try self.consume(TokenType.CloseParen, diagnostics.ARG_expected, .{")"});

    return self.addNode(self.cur_token, AST.Node{ .@"for" = .{ .classic = .{
        .init = init_node,
        .cond = cond_node,
        .post = post_node,
        .body = try parseStatement(self),
    } } });
}

pub fn parseForInStatement(self: *Parser) ParserError!?AST.Node.Index {
    const cp = self.cur_token;
    const init_node = try parseDeclaration(self) orelse try parseExpression(self);
    if (!self.match(TokenType.In)) {
        // TODO: there is no cleanup of created AST nodes - need to figure out how to do it
        self.cur_token = cp;
        return null;
    }
    const right = try parseExpression(self);
    _ = try self.consume(TokenType.CloseParen, diagnostics.ARG_expected, .{")"});

    return self.addNode(self.cur_token, AST.Node{ .@"for" = .{ .in = .{
        .left = init_node,
        .right = right,
        .body = try parseStatement(self),
    } } });
}

pub fn parseForOfStatement(self: *Parser) ParserError!?AST.Node.Index {
    const cp = self.cur_token;

    const init_node = try parseDeclaration(self) orelse try parseExpression(self);
    if (!self.match(TokenType.Of)) {
        self.cur_token = cp;
        return null;
    }
    const right = try parseExpression(self);
    _ = try self.consume(TokenType.CloseParen, diagnostics.ARG_expected, .{")"});

    return self.addNode(self.cur_token, AST.Node{ .@"for" = .{ .of = .{
        .left = init_node,
        .right = right,
        .body = try parseStatement(self),
    } } });
}

test "should parse breakable statement" {
    const test_cases = .{
        .{ "for(;;) {}", AST.Node{ .@"for" = .{ .classic = .{ .init = AST.Node.Empty, .cond = AST.Node.Empty, .post = AST.Node.Empty, .body = 1 } } } },
        .{ "while(true) {}", AST.Node{ .@"while" = .{ .cond = 1, .body = 2 } } },
        .{ "do {} while(true);", AST.Node{ .do_while = .{ .body = 1, .cond = 2 } } },
    };

    inline for (test_cases) |test_case| {
        var parser, const node = try Parser.once(test_case[0], parseBreakableStatement);
        defer parser.deinit();

        try parser.expectAST(node, test_case[1]);
    }
}

test "should return null if while loop is empty" {
    const text = "identifier";

    var parser, const node = try Parser.once(text, parseWhileStatement);
    defer parser.deinit();

    try parser.expectAST(node, null);
}

test "should parse while loop" {
    const text = "while (true) {}";

    var parser, const node = try Parser.once(text, parseWhileStatement);
    defer parser.deinit();

    try parser.expectAST(node, AST.Node{ .@"while" = .{
        .cond = 1,
        .body = 2,
    } });
}

test "should return null if do while loop is empty" {
    const text = "identifier";

    var parser, const node = try Parser.once(text, parseDoWhileStatement);
    defer parser.deinit();

    try parser.expectAST(node, null);
}

test "should parse do while loop" {
    const text = "do {} while (true);";

    var parser, const node = try Parser.once(text, parseDoWhileStatement);
    defer parser.deinit();

    try parser.expectAST(node, AST.Node{ .do_while = .{
        .cond = 2,
        .body = 1,
    } });
}

test "should return null if for loop is not a for loop" {
    const text = "identifier";

    var parser, const node = try Parser.once(text, parseForStatement);
    defer parser.deinit();

    try parser.expectAST(node, null);
}

test "should parse classic for loops" {
    const text = "for (let i = 0; i < 10; i++) {}";

    var parser, const node = try Parser.once(text, parseForStatement);
    defer parser.deinit();

    try parser.expectAST(node, AST.Node{ .@"for" = .{
        .classic = .{
            .init = 3,
            .cond = 7,
            .post = 10,
            .body = 11,
        },
    } });
}

test "should parse empty for loops" {
    const text = "for (;;) {}";

    var parser, const node = try Parser.once(text, parseForStatement);
    defer parser.deinit();

    try parser.expectAST(node, AST.Node{ .@"for" = .{
        .classic = .{
            .init = 0,
            .cond = 0,
            .post = 0,
            .body = 1,
        },
    } });
}

test "should parse in for loops" {
    const text = "for (let i in [1, 2, 3]) {}";

    var parser, const node = try Parser.once(text, parseForStatement);
    defer parser.deinit();

    try parser.expectAST(node, AST.Node{ .@"for" = .{
        .in = .{
            .left = 4,
            .right = 8,
            .body = 9,
        },
    } });
}

test "should parse of for loops" {
    const text = "for (let i of [1, 2, 3]) {}";

    var parser, const node = try Parser.once(text, parseForStatement);
    defer parser.deinit();

    try parser.expectAST(node, AST.Node{ .@"for" = .{
        .of = .{
            .left = 6,
            .right = 10,
            .body = 11,
        },
    } });
}

test "should throw SyntaxError if for loop if its not of or in loop" {
    const text = "for (let i as [1, 2, 3]) {}";

    var parser, const node = try Parser.onceAny(text, parseForStatement);
    defer parser.deinit();

    try parser.expectSyntaxError(node, diagnostics.declaration_or_statement_expected, .{});
}
