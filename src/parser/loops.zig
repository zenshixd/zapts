const std = @import("std");
const Token = @import("../consts.zig").Token;
const Parser = @import("../parser.zig");
const ParserError = @import("../parser.zig").ParserError;
const AST = @import("../ast.zig");
const TokenType = @import("../consts.zig").TokenType;
const diagnostics = @import("../diagnostics.zig");
const snap = @import("../tests/snapshots.zig").snap;

const parseStatement = @import("statements.zig").parseStatement;
const expectStatement = @import("statements.zig").expectStatement;
const parseEmptyStatement = @import("statements.zig").parseEmptyStatement;
const parseExpression = @import("expressions.zig").parseExpression;
const expectExpression = @import("expressions.zig").expectExpression;
const parseDeclaration = @import("statements.zig").parseDeclaration;

const TestParser = @import("../tests/test_parser.zig");
const Marker = TestParser.Marker;

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
    const main_token = self.cur_token;
    if (!self.match(TokenType.Do)) {
        return null;
    }

    const node = try expectStatement(self);
    _ = try self.consume(TokenType.While, diagnostics.ARG_expected, .{"while"});
    _ = try self.consume(TokenType.OpenParen, diagnostics.ARG_expected, .{"("});
    const condition = try expectExpression(self);
    _ = try self.consume(TokenType.CloseParen, diagnostics.ARG_expected, .{")"});
    _ = try self.consume(TokenType.Semicolon, diagnostics.ARG_expected, .{";"});

    return self.addNode(main_token, AST.Node{
        .do_while = .{
            .cond = condition,
            .body = node,
        },
    });
}

pub fn parseWhileStatement(self: *Parser) ParserError!?AST.Node.Index {
    const main_token = self.cur_token;
    if (!self.match(TokenType.While)) {
        return null;
    }

    _ = try self.consume(TokenType.OpenParen, diagnostics.ARG_expected, .{"("});
    const condition = try expectExpression(self);
    _ = try self.consume(TokenType.CloseParen, diagnostics.ARG_expected, .{")"});

    return self.addNode(main_token, AST.Node{
        .@"while" = .{
            .cond = condition,
            .body = try expectStatement(self),
        },
    });
}

pub fn parseForStatement(self: *Parser) ParserError!?AST.Node.Index {
    const main_token = self.cur_token;
    if (!self.match(TokenType.For)) {
        return null;
    }

    _ = try self.consume(TokenType.OpenParen, diagnostics.ARG_expected, .{"("});

    const for_inner = try parseForInStatement(self, main_token) orelse
        try parseForOfStatement(self, main_token) orelse
        try parseForClassicStatement(self, main_token);

    return for_inner;
}

pub fn parseForClassicStatement(self: *Parser, main_token: Token.Index) ParserError!AST.Node.Index {
    const init_node = if (self.peekMatch(TokenType.Semicolon)) AST.Node.Empty else try parseDeclaration(self) orelse try expectExpression(self);

    _ = try self.consume(TokenType.Semicolon, diagnostics.ARG_expected, .{";"});
    const cond_node = if (self.peekMatch(TokenType.Semicolon)) AST.Node.Empty else try expectExpression(self);
    _ = try self.consume(TokenType.Semicolon, diagnostics.ARG_expected, .{";"});
    const post_node = if (self.peekMatch(TokenType.CloseParen)) AST.Node.Empty else try expectExpression(self);
    _ = try self.consume(TokenType.CloseParen, diagnostics.ARG_expected, .{")"});

    return self.addNode(main_token, AST.Node{ .@"for" = .{
        .classic = .{
            .init = init_node,
            .cond = cond_node,
            .post = post_node,
            .body = try expectStatement(self),
        },
    } });
}

pub fn parseForInStatement(self: *Parser, main_token: Token.Index) ParserError!?AST.Node.Index {
    const cp = self.checkpoint();
    const init_node = try parseDeclaration(self) orelse try parseExpression(self) orelse return null;
    if (!self.match(TokenType.In)) {
        self.rewindTo(cp);
        return null;
    }
    const right = try expectExpression(self);
    _ = try self.consume(TokenType.CloseParen, diagnostics.ARG_expected, .{")"});

    return self.addNode(main_token, AST.Node{ .@"for" = .{
        .in = .{
            .left = init_node,
            .right = right,
            .body = try expectStatement(self),
        },
    } });
}

pub fn parseForOfStatement(self: *Parser, main_token: Token.Index) ParserError!?AST.Node.Index {
    const cp = self.checkpoint();

    const init_node = try parseDeclaration(self) orelse try parseExpression(self) orelse return null;
    if (!self.match(TokenType.Of)) {
        self.rewindTo(cp);
        return null;
    }
    const right = try expectExpression(self);
    _ = try self.consume(TokenType.CloseParen, diagnostics.ARG_expected, .{")"});

    return self.addNode(main_token, AST.Node{ .@"for" = .{
        .of = .{
            .left = init_node,
            .right = right,
            .body = try expectStatement(self),
        },
    } });
}

test "should parse breakable statement" {
    const test_cases = .{
        .{
            \\ for(;;) {}
            \\>^
            ,
            snap(@src(),
                \\ast.Node{
                \\    .for = ast.Node.For{
                \\        .classic = ast.Node.ForClassic{
                \\            .init = ast.Node.Index.empty,
                \\            .cond = ast.Node.Index.empty,
                \\            .post = ast.Node.Index.empty,
                \\            .body = ast.Node.Index(0),
                \\        },
                \\    },
                \\}
            ),
        },
        .{
            \\ while(true) {}
            \\>^
            ,
            snap(@src(),
                \\ast.Node{
                \\    .while = ast.Node.While{
                \\        .cond = ast.Node.Index(0),
                \\        .body = ast.Node.Index(1),
                \\    },
                \\}
            ),
        },
        .{
            \\ do {} while(true);
            \\>^
            ,
            snap(@src(),
                \\ast.Node{
                \\    .do_while = ast.Node.While{
                \\        .cond = ast.Node.Index(1),
                \\        .body = ast.Node.Index(0),
                \\    },
                \\}
            ),
        },
    };

    inline for (test_cases) |test_case| {
        const t, const node, const markers = try TestParser.run(test_case[0], parseBreakableStatement);
        defer t.deinit();

        try t.expectASTSnapshot(node, test_case[1]);
        try t.expectTokenAt(markers[0], node.?);
    }
}

test "should return null if while loop is empty" {
    const text = "identifier";

    const t, const node, _ = try TestParser.run(text, parseWhileStatement);
    defer t.deinit();

    try t.expectAST(node, null);
}

test "should parse while loop" {
    const text = "while (true) {}";

    const t, const node, _ = try TestParser.run(text, parseWhileStatement);
    defer t.deinit();

    try t.expectASTSnapshot(node, snap(@src(),
        \\ast.Node{
        \\    .while = ast.Node.While{
        \\        .cond = ast.Node.Index(0),
        \\        .body = ast.Node.Index(1),
        \\    },
        \\}
    ));
}

test "should return syntax error if loop condition is missing" {
    const text =
        \\while () {}
        \\>      ^
    ;

    const t, const nodeOrError, const markers = try TestParser.runCatch(text, parseWhileStatement);
    defer t.deinit();

    try t.expectSyntaxErrorAt(nodeOrError, diagnostics.expression_expected, .{}, markers[0]);
}

test "should return syntax error if opening paren is missing" {
    const text =
        \\while true) {}
        \\>     ^
    ;

    const t, const nodeOrError, const markers = try TestParser.runCatch(text, parseWhileStatement);
    defer t.deinit();

    try t.expectSyntaxErrorAt(nodeOrError, diagnostics.ARG_expected, .{"("}, markers[0]);
}

test "should return syntax error if closing paren is missing" {
    const text =
        \\while (true {}
        \\>           ^
    ;

    const t, const nodeOrError, const markers = try TestParser.runCatch(text, parseWhileStatement);
    defer t.deinit();

    try t.expectSyntaxErrorAt(nodeOrError, diagnostics.ARG_expected, .{")"}, markers[0]);
}

test "should return syntax error if body is missing" {
    const text =
        \\while (true)
        \\>           ^
    ;

    const t, const nodeOrError, const markers = try TestParser.runCatch(text, parseWhileStatement);
    defer t.deinit();

    try t.expectSyntaxErrorAt(nodeOrError, diagnostics.statement_expected, .{}, markers[0]);
}

test "should return null if do while loop is empty" {
    const text = "identifier";

    const t, const node, _ = try TestParser.run(text, parseDoWhileStatement);
    defer t.deinit();

    try t.expectAST(node, null);
}

test "should parse do while loop" {
    const text = "do {} while (true);";

    const t, const node, _ = try TestParser.run(text, parseDoWhileStatement);
    defer t.deinit();

    try t.expectASTSnapshot(node, snap(@src(),
        \\ast.Node{
        \\    .do_while = ast.Node.While{
        \\        .cond = ast.Node.Index(1),
        \\        .body = ast.Node.Index(0),
        \\    },
        \\}
    ));
}

test "should return syntax error if body missing in do while loop" {
    const text =
        \\ do while(true)
        \\>              ^
    ;

    const t, const nodeOrError, const markers = try TestParser.runCatch(text, parseDoWhileStatement);
    defer t.deinit();

    try t.expectSyntaxErrorAt(nodeOrError, diagnostics.statement_expected, .{}, markers[0]);
}

test "should return syntax error if condition missing in do while loop" {
    const text =
        \\ do {} while()
        \\>            ^
    ;

    const t, const nodeOrError, const markers = try TestParser.runCatch(text, parseDoWhileStatement);
    defer t.deinit();

    try t.expectSyntaxErrorAt(nodeOrError, diagnostics.expression_expected, .{}, markers[0]);
}

test "should return syntax error if while is missing" {
    const text =
        \\ do {} (true)
        \\>      ^
    ;

    const t, const nodeOrError, const markers = try TestParser.runCatch(text, parseDoWhileStatement);
    defer t.deinit();

    try t.expectSyntaxErrorAt(nodeOrError, diagnostics.ARG_expected, .{"while"}, markers[0]);
}

test "should return syntax error if open paren is missing in do while loop" {
    const text =
        \\do {} while 1)
        \\>           ^
    ;

    const t, const nodeOrError, const markers = try TestParser.runCatch(text, parseDoWhileStatement);
    defer t.deinit();

    try t.expectSyntaxErrorAt(nodeOrError, diagnostics.ARG_expected, .{"("}, markers[0]);
}

test "should return syntax error if close paren is missing in do while loop" {
    const text =
        \\do {} while(1
        \\>            ^
    ;

    const t, const nodeOrError, const markers = try TestParser.runCatch(text, parseDoWhileStatement);
    defer t.deinit();

    try t.expectSyntaxErrorAt(nodeOrError, diagnostics.ARG_expected, .{")"}, markers[0]);
}

test "should return null if for loop is not a for loop" {
    const text = "identifier";

    const t, const node, _ = try TestParser.run(text, parseForStatement);
    defer t.deinit();

    try t.expectAST(node, null);
}

test "should parse classic for loops" {
    const text =
        \\ for (let i = 0; i < 10; i++) {}
        \\>^
    ;

    const t, const node, _ = try TestParser.run(text, parseForStatement);
    defer t.deinit();

    try t.expectASTSnapshot(node, snap(@src(),
        \\ast.Node{
        \\    .for = ast.Node.For{
        \\        .classic = ast.Node.ForClassic{
        \\            .init = ast.Node.Index(2),
        \\            .cond = ast.Node.Index(5),
        \\            .post = ast.Node.Index(7),
        \\            .body = ast.Node.Index(8),
        \\        },
        \\    },
        \\}
    ));
}

test "should return syntax error if semicolon is missing in classic for loop" {
    const text =
        \\for (let i = 0 i < 10 i++) {}
        \\>              ^
    ;

    const t, const nodeOrError, const markers = try TestParser.runCatch(text, parseForStatement);
    defer t.deinit();

    try t.expectSyntaxErrorAt(nodeOrError, diagnostics.ARG_expected, .{";"}, markers[0]);
}

test "should parse empty for loops" {
    const text = "for (;;) {}";

    const t, const node, _ = try TestParser.run(text, parseForStatement);
    defer t.deinit();

    try t.expectASTSnapshot(node, snap(@src(),
        \\ast.Node{
        \\    .for = ast.Node.For{
        \\        .classic = ast.Node.ForClassic{
        \\            .init = ast.Node.Index.empty,
        \\            .cond = ast.Node.Index.empty,
        \\            .post = ast.Node.Index.empty,
        \\            .body = ast.Node.Index(0),
        \\        },
        \\    },
        \\}
    ));
}

test "should parse in for loops" {
    const text =
        \\ for (let i in [1, 2, 3]) {}
        \\>^
    ;

    const t, const node, const markers = try TestParser.run(text, parseForStatement);
    defer t.deinit();

    try t.expectASTSnapshot(node, snap(@src(),
        \\ast.Node{
        \\    .for = ast.Node.For{
        \\        .in = ast.Node.ForItems{
        \\            .left = ast.Node.Index(1),
        \\            .right = ast.Node.Index(5),
        \\            .body = ast.Node.Index(6),
        \\        },
        \\    },
        \\}
    ));
    try t.expectTokenAt(markers[0], node.?);
}

test "should parse of for loops" {
    const text =
        \\ for (let i of [1, 2, 3]) {}
        \\>^
    ;

    const t, const node, _ = try TestParser.run(text, parseForStatement);
    defer t.deinit();

    try t.expectASTSnapshot(node, snap(@src(),
        \\ast.Node{
        \\    .for = ast.Node.For{
        \\        .of = ast.Node.ForItems{
        \\            .left = ast.Node.Index(1),
        \\            .right = ast.Node.Index(5),
        \\            .body = ast.Node.Index(6),
        \\        },
        \\    },
        \\}
    ));
}

test "should throw SyntaxError if for loop if its not of or in loop" {
    const text =
        \\for (let i as [1, 2, 3]) {}
        \\>          ^
    ;

    const t, const nodeOrError, const markers = try TestParser.runCatch(text, parseForStatement);
    defer t.deinit();

    try t.expectSyntaxErrorAt(nodeOrError, diagnostics.ARG_expected, .{";"}, markers[0]);
}
