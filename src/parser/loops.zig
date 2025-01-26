const std = @import("std");
const Parser = @import("../parser.zig");
const AST = @import("../ast.zig");
const TokenType = @import("../consts.zig").TokenType;
const ParserError = Parser.ParserError;
const diagnostics = @import("../diagnostics.zig");

const parseStatement = @import("statements.zig").parseStatement;
const parseExpression = @import("expressions.zig").parseExpression;
const parseDeclaration = @import("statements.zig").parseDeclaration;

const TestParser = @import("../test_parser.zig");
const MarkerList = @import("../test_parser.zig").MarkerList;
const Marker = @import("../test_parser.zig").Marker;

const expectEqual = std.testing.expectEqual;
const expectEqualDeep = std.testing.expectEqualDeep;
const expectEqualStrings = std.testing.expectEqualStrings;
const expectError = std.testing.expectError;

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
        .{ "for(;;) {}", AST.Node{ .@"for" = .{ .classic = .{
            .init = AST.Node.Empty,
            .cond = AST.Node.Empty,
            .post = AST.Node.Empty,
            .body = AST.Node.at(1),
        } } } },
        .{ "while(true) {}", AST.Node{ .@"while" = .{
            .cond = AST.Node.at(1),
            .body = AST.Node.at(2),
        } } },
        .{ "do {} while(true);", AST.Node{ .do_while = .{
            .body = AST.Node.at(1),
            .cond = AST.Node.at(2),
        } } },
    };

    inline for (test_cases) |test_case| {
        try TestParser.run(test_case[0], parseBreakableStatement, struct {
            pub fn expect(t: TestParser, node: ?AST.Node.Index, _: MarkerList(test_case[0])) !void {
                try t.expectAST(node, test_case[1]);
            }
        });
    }
}

test "should return null if while loop is empty" {
    const text = "identifier";

    try TestParser.run(text, parseWhileStatement, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectAST(node, null);
        }
    });
}

test "should parse while loop" {
    const text = "while (true) {}";

    try TestParser.run(text, parseWhileStatement, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectAST(node, AST.Node{ .@"while" = .{
                .cond = AST.Node.at(1),
                .body = AST.Node.at(2),
            } });
        }
    });
}

test "should return null if do while loop is empty" {
    const text = "identifier";

    try TestParser.run(text, parseDoWhileStatement, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectAST(node, null);
        }
    });
}

test "should parse do while loop" {
    const text = "do {} while (true);";

    try TestParser.run(text, parseDoWhileStatement, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectAST(node, AST.Node{ .do_while = .{
                .cond = AST.Node.at(2),
                .body = AST.Node.at(1),
            } });
        }
    });
}

test "should return null if for loop is not a for loop" {
    const text = "identifier";

    try TestParser.run(text, parseForStatement, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectAST(node, null);
        }
    });
}

test "should parse classic for loops" {
    const text = "for (let i = 0; i < 10; i++) {}";

    try TestParser.run(text, parseForStatement, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectAST(node, AST.Node{ .@"for" = .{
                .classic = .{
                    .init = AST.Node.at(3),
                    .cond = AST.Node.at(7),
                    .post = AST.Node.at(10),
                    .body = AST.Node.at(11),
                },
            } });
        }
    });
}

test "should parse empty for loops" {
    const text = "for (;;) {}";

    try TestParser.run(text, parseForStatement, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectAST(node, AST.Node{ .@"for" = .{
                .classic = .{
                    .init = AST.Node.Empty,
                    .cond = AST.Node.Empty,
                    .post = AST.Node.Empty,
                    .body = AST.Node.at(1),
                },
            } });
        }
    });
}

test "should parse in for loops" {
    const text = "for (let i in [1, 2, 3]) {}";

    try TestParser.run(text, parseForStatement, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectAST(node, AST.Node{ .@"for" = .{
                .in = .{
                    .left = AST.Node.at(4),
                    .right = AST.Node.at(8),
                    .body = AST.Node.at(9),
                },
            } });
        }
    });
}

test "should parse of for loops" {
    const text = "for (let i of [1, 2, 3]) {}";

    try TestParser.run(text, parseForStatement, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectAST(node, AST.Node{ .@"for" = .{
                .of = .{
                    .left = AST.Node.at(6),
                    .right = AST.Node.at(10),
                    .body = AST.Node.at(11),
                },
            } });
        }
    });
}

test "should throw SyntaxError if for loop if its not of or in loop" {
    const text = "for (let i as [1, 2, 3]) {}";

    try TestParser.runAny(text, parseForStatement, struct {
        pub fn expect(t: TestParser, nodeOrError: Parser.ParserError!?AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectSyntaxError(nodeOrError, diagnostics.declaration_or_statement_expected, .{});
        }
    });
}
