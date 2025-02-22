const std = @import("std");
const Parser = @import("../parser.zig");
const ParserError = @import("../parser.zig").ParserError;
const AST = @import("../ast.zig");
const Token = @import("../consts.zig").Token;
const TokenType = @import("../consts.zig").TokenType;
const StringId = @import("../string_interner.zig").StringId;
const diagnostics = @import("../diagnostics.zig");

const parseAssignment = @import("binary.zig").parseAssignment;
const expectAssignment = @import("binary.zig").expectAssignment;
const parseBinaryExpression = @import("binary.zig").parseBinaryExpression;
const parsePrimaryExpression = @import("primary.zig").parsePrimaryExpression;
const parseIdentifier = @import("primary.zig").parseIdentifier;
const expectIdentifier = @import("primary.zig").expectIdentifier;

const snap = @import("../tests/snapshots.zig").snap;
const TestParser = @import("../tests/test_parser.zig");
const Marker = TestParser.Marker;

pub fn parseExpression(self: *Parser) ParserError!?AST.Node.Index {
    var node = try parseAssignment(self) orelse return null;
    while (self.match(TokenType.Comma)) {
        const new_node = self.addNode(self.cur_token.dec(1), AST.Node{
            .comma = .{
                .left = node,
                .right = try expectAssignment(self),
            },
        });

        node = new_node;
    }

    return node;
}

pub fn expectExpression(self: *Parser) ParserError!AST.Node.Index {
    return try parseExpression(self) orelse self.fail(diagnostics.expression_expected, .{});
}

pub fn parseConditionalExpression(self: *Parser) ParserError!?AST.Node.Index {
    var node = try parseShortCircuitExpression(self) orelse return null;

    const main_token = self.cur_token;
    if (self.match(TokenType.QuestionMark)) {
        const true_expr = try expectAssignment(self);
        _ = try self.consume(TokenType.Colon, diagnostics.ARG_expected, .{":"});
        const false_expr = try expectAssignment(self);
        const new_node = self.addNode(main_token, AST.Node{ .ternary_expr = .{
            .expr = node,
            .body = true_expr,
            .@"else" = false_expr,
        } });

        node = new_node;
    }

    return node;
}

pub fn parseShortCircuitExpression(self: *Parser) ParserError!?AST.Node.Index {
    return try parseBinaryExpression(self);
}
const unary_operators = .{
    .{ .token = TokenType.Minus, .tag = "minus" },
    .{ .token = TokenType.Plus, .tag = "plus" },
    .{ .token = TokenType.ExclamationMark, .tag = "not" },
    .{ .token = TokenType.Tilde, .tag = "bitwise_negate" },
    .{ .token = TokenType.Typeof, .tag = "typeof" },
    .{ .token = TokenType.Void, .tag = "void" },
    .{ .token = TokenType.Delete, .tag = "delete" },
};
pub fn parseUnary(self: *Parser) ParserError!?AST.Node.Index {
    inline for (unary_operators) |unary_operator| {
        const main_token = self.cur_token;
        if (self.match(unary_operator.token)) {
            const node = try expectUnary(self);
            return self.addNode(main_token, @unionInit(AST.Node, unary_operator.tag, node));
        }
    }

    return try parseUpdateExpression(self) orelse return null;
}

pub fn expectUnary(self: *Parser) ParserError!AST.Node.Index {
    return try parseUnary(self) orelse self.fail(diagnostics.expression_expected, .{});
}

pub fn parseUpdateExpression(self: *Parser) ParserError!?AST.Node.Index {
    if (self.match(TokenType.PlusPlus)) {
        return self.addNode(self.cur_token.dec(1), AST.Node{
            .plusplus_pre = try expectUnary(self),
        });
    } else if (self.match(TokenType.MinusMinus)) {
        return self.addNode(self.cur_token.dec(1), AST.Node{
            .minusminus_pre = try expectUnary(self),
        });
    }

    const node = try parseLeftHandSideExpression(self) orelse return null;

    if (self.match(TokenType.PlusPlus)) {
        return self.addNode(self.cur_token.dec(1), AST.Node{
            .plusplus_post = node,
        });
    } else if (self.match(TokenType.MinusMinus)) {
        return self.addNode(self.cur_token.dec(1), AST.Node{
            .minusminus_post = node,
        });
    }

    return node;
}

pub fn parseLeftHandSideExpression(self: *Parser) ParserError!?AST.Node.Index {
    return try parseCallableExpression(self);
}

pub fn parseNewExpression(self: *Parser) ParserError!?AST.Node.Index {
    const main_token = self.cur_token;
    if (!self.match(TokenType.New)) {
        return null;
    }

    return self.addNode(main_token, AST.Node{
        .new_expr = try expectCallableExpression(self),
    });
}

pub fn parseMemberExpression(self: *Parser) ParserError!?AST.Node.Index {
    var node = try parseNewExpression(self) orelse
        try parsePrimaryExpression(self) orelse
        return null;

    while (true) {
        const new_node = try parsePropertyAccess(self, node) orelse
            try parseIndexAccess(self, node) orelse break;

        node = new_node;
    }

    return node;
}

pub fn parseCallableExpression(self: *Parser) ParserError!?AST.Node.Index {
    var main_token = self.cur_token;
    var node = try parseMemberExpression(self) orelse return null;

    while (self.match(TokenType.OpenParen)) {
        var nodes = std.ArrayList(AST.Node.Index).init(self.gpa);
        defer nodes.deinit();

        while (!self.match(TokenType.CloseParen)) {
            try nodes.append(try expectAssignment(self));

            if (self.match(TokenType.CloseParen)) {
                break;
            }

            _ = try self.consume(TokenType.Comma, diagnostics.ARG_expected, .{","});
        }

        const new_node = self.addNode(main_token, AST.Node{
            .call_expr = .{
                .node = node,
                .params = nodes.items,
            },
        });
        node = new_node;
        main_token = self.cur_token;
    }

    return node;
}

pub fn expectCallableExpression(self: *Parser) ParserError!AST.Node.Index {
    return try parseCallableExpression(self) orelse self.fail(diagnostics.expression_expected, .{});
}

pub fn parseIndexAccess(self: *Parser, expr: AST.Node.Index) ParserError!?AST.Node.Index {
    const main_token = self.cur_token;
    if (!self.match(TokenType.OpenSquareBracket)) {
        return null;
    }

    const node = self.addNode(main_token, AST.Node{
        .index_access = .{
            .left = expr,
            .right = try expectExpression(self),
        },
    });

    _ = try self.consume(TokenType.CloseSquareBracket, diagnostics.ARG_expected, .{"]"});

    return node;
}

pub fn parsePropertyAccess(self: *Parser, expr: AST.Node.Index) ParserError!?AST.Node.Index {
    const main_token = self.cur_token;
    if (!self.match(TokenType.Dot)) {
        return null;
    }

    const identifier = try expectIdentifier(self);

    return self.addNode(main_token, AST.Node{
        .property_access = .{
            .left = expr,
            .right = identifier,
        },
    });
}

test "should parse comma expression" {
    const text =
        \\a = b, c
        \\>    ^
    ;

    const t, const node, const markers = try TestParser.run(text, parseExpression);
    defer t.deinit();

    try t.expectASTSnapshot(node, snap(@src(),
        \\ast.Node{
        \\    .comma = ast.Node.Binary{
        \\        .left = ast.Node.Index(2),
        \\        .right = ast.Node.Index(3),
        \\    },
        \\}
    ));
    try t.expectTokenAt(markers[0], node.?);
}

test "should parse conditional expression" {
    const text =
        \\a ? b : c
        \\> ^
    ;

    const t, const node, const markers = try TestParser.run(text, parseExpression);
    defer t.deinit();

    try t.expectASTSnapshot(node, snap(@src(),
        \\ast.Node{
        \\    .ternary_expr = ast.Node.If{
        \\        .expr = ast.Node.Index(0),
        \\        .body = ast.Node.Index(1),
        \\        .else = ast.Node.Index(2),
        \\    },
        \\}
    ));
    try t.expectTokenAt(markers[0], node.?);
}

test "should return syntax error if short circuit expression is missing" {
    const text =
        \\a ? b
        \\>    ^
    ;

    const t, const nodeOrError, const markers = try TestParser.runCatch(text, parseExpression);
    defer t.deinit();

    try t.expectSyntaxErrorAt(nodeOrError, diagnostics.ARG_expected, .{":"}, markers[0]);
}

test "should parse short circuit expression" {
    const text =
        \\a ?? b
        \\> ^
    ;

    const t, const node, const markers = try TestParser.run(text, parseExpression);
    defer t.deinit();

    try t.expectASTSnapshot(node, snap(@src(),
        \\ast.Node{
        \\    .coalesce = ast.Node.Binary{
        \\        .left = ast.Node.Index(0),
        \\        .right = ast.Node.Index(1),
        \\    },
        \\}
    ));
    try t.expectTokenAt(markers[0], node.?);
}

test "should parse unary expression" {
    const tests = .{
        .{
            "+a",
            snap(@src(),
                \\ast.Node{
                \\    .plus = ast.Node.Index(0),
                \\}
            ),
        },
        .{
            "-a",
            snap(@src(),
                \\ast.Node{
                \\    .minus = ast.Node.Index(0),
                \\}
            ),
        },
        .{
            "!a",
            snap(@src(),
                \\ast.Node{
                \\    .not = ast.Node.Index(0),
                \\}
            ),
        },
        .{
            "~a",
            snap(@src(),
                \\ast.Node{
                \\    .bitwise_negate = ast.Node.Index(0),
                \\}
            ),
        },
        .{
            "typeof a",
            snap(@src(),
                \\ast.Node{
                \\    .typeof = ast.Node.Index(0),
                \\}
            ),
        },
        .{
            "void a",
            snap(@src(),
                \\ast.Node{
                \\    .void = ast.Node.Index(0),
                \\}
            ),
        },
        .{
            "delete a",
            snap(@src(),
                \\ast.Node{
                \\    .delete = ast.Node.Index(0),
                \\}
            ),
        },
    };

    inline for (tests) |test_case| {
        const t, const node, _ = try TestParser.run(test_case[0], parseUnary);
        defer t.deinit();

        try t.expectASTSnapshot(node, test_case[1]);
        try t.expectTokenAt(Marker.fromText("^"), node.?);
    }
}

test "should parse update expression" {
    const tests = .{
        .{
            \\ ++a
            \\>^
            ,
            snap(@src(),
                \\ast.Node{
                \\    .plusplus_pre = ast.Node.Index(0),
                \\}
            ),
        },
        .{
            \\ --a
            \\>^
            ,
            snap(@src(),
                \\ast.Node{
                \\    .minusminus_pre = ast.Node.Index(0),
                \\}
            ),
        },
        .{
            \\a++
            \\>^
            ,
            snap(@src(),
                \\ast.Node{
                \\    .plusplus_post = ast.Node.Index(0),
                \\}
            ),
        },
        .{
            \\a--
            \\>^
            ,
            snap(@src(),
                \\ast.Node{
                \\    .minusminus_post = ast.Node.Index(0),
                \\}
            ),
        },
    };

    inline for (tests) |test_case| {
        const t, const node, const markers = try TestParser.run(test_case[0], parseUnary);
        defer t.deinit();

        try t.expectASTSnapshot(node, test_case[1]);
        try t.expectTokenAt(markers[0], node.?);
    }
}

test "should parse left hand side expression" {
    const text = "a()";

    const t, const node, _ = try TestParser.run(text, parseLeftHandSideExpression);
    defer t.deinit();

    try t.expectASTSnapshot(node, snap(@src(),
        \\ast.Node{
        \\    .call_expr = ast.Node.CallExpression{
        \\        .node = ast.Node.Index(0),
        \\        .params = [_]ast.Node.Index{},
        \\    },
        \\}
    ));
}

test "should return syntax error if left hand side expression is missing" {
    const text =
        \\()
        \\>^
    ;

    const t, const nodeOrError, const markers = try TestParser.runCatch(text, parseLeftHandSideExpression);
    defer t.deinit();

    try t.expectSyntaxErrorAt(nodeOrError, diagnostics.expression_expected, .{}, markers[0]);
}

test "should parse new expression" {
    const text = "new a";

    const t, const node, _ = try TestParser.run(text, parseNewExpression);
    defer t.deinit();

    try t.expectASTSnapshot(node, snap(@src(),
        \\ast.Node{
        \\    .new_expr = ast.Node.Index(0),
        \\}
    ));
}

test "should return null if new expression is missing" {
    const t, const node, _ = try TestParser.run("a", parseNewExpression);
    defer t.deinit();

    try t.expectAST(node, null);
}

test "should parse member expression" {
    const tests = .{
        .{
            \\ new a()
            \\>^
            ,
            snap(@src(),
                \\ast.Node{
                \\    .new_expr = ast.Node.Index(1),
                \\}
            ),
        },
        .{
            \\ a
            \\>^
            ,
            snap(@src(),
                \\ast.Node{
                \\    .simple_value = ast.Node.SimpleValue{
                \\        .kind = ast.SimpleValueKind.identifier,
                \\        .id = string_interner.StringId(1),
                \\    },
                \\}
            ),
        },
        .{
            \\a.b
            \\>^
            ,
            snap(@src(),
                \\ast.Node{
                \\    .property_access = ast.Node.Binary{
                \\        .left = ast.Node.Index(0),
                \\        .right = ast.Node.Index(1),
                \\    },
                \\}
            ),
        },
        .{
            \\a[0]
            \\>^
            ,
            snap(@src(),
                \\ast.Node{
                \\    .index_access = ast.Node.Binary{
                \\        .left = ast.Node.Index(0),
                \\        .right = ast.Node.Index(1),
                \\    },
                \\}
            ),
        },
    };

    inline for (tests) |test_case| {
        const t, const node, const markers = try TestParser.run(test_case[0], parseMemberExpression);
        defer t.deinit();

        try t.expectASTSnapshot(node, test_case[1]);
        try t.expectTokenAt(markers[0], node.?);
    }
}

test "should return syntax error if property access key is not identifier" {
    const text =
        \\a.'123'
        \\> ^
    ;

    const t, const nodeOrError, const markers = try TestParser.runCatch(text, parseMemberExpression);
    defer t.deinit();

    try t.expectSyntaxErrorAt(nodeOrError, diagnostics.identifier_expected, .{}, markers[0]);
}

test "should parse chained member expression" {
    const tests = .{
        .{
            \\new a().b
            \\>      ^
            ,
            snap(@src(),
                \\ast.Node{
                \\    .property_access = ast.Node.Binary{
                \\        .left = ast.Node.Index(2),
                \\        .right = ast.Node.Index(3),
                \\    },
                \\}
            ),
        },
        .{
            \\a.b
            \\>^
            ,
            snap(@src(),
                \\ast.Node{
                \\    .property_access = ast.Node.Binary{
                \\        .left = ast.Node.Index(0),
                \\        .right = ast.Node.Index(1),
                \\    },
                \\}
            ),
        },
    };

    inline for (tests) |test_case| {
        const t, const node, const markers = try TestParser.run(test_case[0], parseMemberExpression);
        defer t.deinit();

        try t.expectASTSnapshot(node, test_case[1]);
        try t.expectTokenAt(markers[0], node.?);
    }
}

test "should parse callable expression" {
    const tests = .{
        .{
            "a()",
            snap(@src(),
                \\ast.Node{
                \\    .call_expr = ast.Node.CallExpression{
                \\        .node = ast.Node.Index(0),
                \\        .params = [_]ast.Node.Index{},
                \\    },
                \\}
            ),
        },
        .{
            "a(b)",
            snap(@src(),
                \\ast.Node{
                \\    .call_expr = ast.Node.CallExpression{
                \\        .node = ast.Node.Index(0),
                \\        .params = [_]ast.Node.Index{
                \\            ast.Node.Index(1)
                \\        },
                \\    },
                \\}
            ),
        },
        .{
            "a(b, c)",
            snap(@src(),
                \\ast.Node{
                \\    .call_expr = ast.Node.CallExpression{
                \\        .node = ast.Node.Index(0),
                \\        .params = [_]ast.Node.Index{
                \\            ast.Node.Index(1), 
                \\            ast.Node.Index(2)
                \\        },
                \\    },
                \\}
            ),
        },
        .{
            "a(b + c)",
            snap(@src(),
                \\ast.Node{
                \\    .call_expr = ast.Node.CallExpression{
                \\        .node = ast.Node.Index(0),
                \\        .params = [_]ast.Node.Index{
                \\            ast.Node.Index(3)
                \\        },
                \\    },
                \\}
            ),
        },
        .{
            "a(b,)",
            snap(@src(),
                \\ast.Node{
                \\    .call_expr = ast.Node.CallExpression{
                \\        .node = ast.Node.Index(0),
                \\        .params = [_]ast.Node.Index{
                \\            ast.Node.Index(1)
                \\        },
                \\    },
                \\}
            ),
        },
    };
    const marker = "^";

    inline for (tests) |test_case| {
        const t, const node, _ = try TestParser.run(test_case[0], parseCallableExpression);
        defer t.deinit();

        try t.expectASTSnapshot(node, test_case[1]);
        try t.expectTokenAt(comptime Marker.fromText(marker), node.?);
    }
}

test "should parse chained callable expression" {
    const text =
        \\ a(1)(2)(3)
        \\>^   ^  ^
    ;

    const t, const node, const markers = try TestParser.run(text, parseCallableExpression);
    defer t.deinit();

    try t.expectASTSnapshot(node, snap(@src(),
        \\ast.Node{
        \\    .call_expr = ast.Node.CallExpression{
        \\        .node = ast.Node.Index(4),
        \\        .params = [_]ast.Node.Index{
        \\            ast.Node.Index(5)
        \\        },
        \\    },
        \\}
    ));
    try t.expectTokenAt(markers[2], node.?);

    const call_expr1 = t.parser.getNode(node.?);
    try t.expectASTSnapshot(call_expr1.call_expr.node, snap(@src(),
        \\ast.Node{
        \\    .call_expr = ast.Node.CallExpression{
        \\        .node = ast.Node.Index(2),
        \\        .params = [_]ast.Node.Index{
        \\            ast.Node.Index(3)
        \\        },
        \\    },
        \\}
    ));
    try t.expectTokenAt(markers[1], call_expr1.call_expr.node);

    const call_expr2 = t.parser.getNode(call_expr1.call_expr.node);
    try t.expectASTSnapshot(call_expr2.call_expr.node, snap(@src(),
        \\ast.Node{
        \\    .call_expr = ast.Node.CallExpression{
        \\        .node = ast.Node.Index(0),
        \\        .params = [_]ast.Node.Index{
        \\            ast.Node.Index(1)
        \\        },
        \\    },
        \\}
    ));
    try t.expectTokenAt(markers[0], call_expr2.call_expr.node);
}

test "should return syntax error if comma is missing between params" {
    const text =
        \\a(b c)
        \\>   ^
    ;

    const t, const nodeOrError, const markers = try TestParser.runCatch(text, parseCallableExpression);
    defer t.deinit();

    try t.expectSyntaxErrorAt(nodeOrError, diagnostics.ARG_expected, .{","}, markers[0]);
}
