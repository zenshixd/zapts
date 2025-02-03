const std = @import("std");
const Parser = @import("../parser.zig");
const AST = @import("../ast.zig");
const Token = @import("../consts.zig").Token;
const TokenType = @import("../consts.zig").TokenType;
const CompilationError = @import("../consts.zig").CompilationError;
const diagnostics = @import("../diagnostics.zig");

const parseAssignment = @import("binary.zig").parseAssignment;
const expectAssignment = @import("binary.zig").expectAssignment;
const parseBinaryExpression = @import("binary.zig").parseBinaryExpression;
const parsePrimaryExpression = @import("primary.zig").parsePrimaryExpression;
const parseIdentifier = @import("primary.zig").parseIdentifier;
const expectIdentifier = @import("primary.zig").expectIdentifier;

const TestParser = @import("../test_parser.zig");
const MarkerList = @import("../test_parser.zig").MarkerList;
const Marker = @import("../test_parser.zig").Marker;

pub fn parseExpression(self: *Parser) CompilationError!?AST.Node.Index {
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

pub fn expectExpression(self: *Parser) CompilationError!AST.Node.Index {
    return try parseExpression(self) orelse self.fail(diagnostics.expression_expected, .{});
}

pub fn parseConditionalExpression(self: *Parser) CompilationError!?AST.Node.Index {
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

pub fn parseShortCircuitExpression(self: *Parser) CompilationError!?AST.Node.Index {
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
pub fn parseUnary(self: *Parser) CompilationError!?AST.Node.Index {
    inline for (unary_operators) |unary_operator| {
        const main_token = self.cur_token;
        if (self.match(unary_operator.token)) {
            const node = try expectUnary(self);
            return self.addNode(main_token, @unionInit(AST.Node, unary_operator.tag, node));
        }
    }

    return try parseUpdateExpression(self) orelse return null;
}

pub fn expectUnary(self: *Parser) CompilationError!AST.Node.Index {
    return try parseUnary(self) orelse self.fail(diagnostics.expression_expected, .{});
}

pub fn parseUpdateExpression(self: *Parser) CompilationError!?AST.Node.Index {
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

pub fn parseLeftHandSideExpression(self: *Parser) CompilationError!?AST.Node.Index {
    return try parseCallableExpression(self);
}

pub fn parseNewExpression(self: *Parser) CompilationError!?AST.Node.Index {
    const main_token = self.cur_token;
    if (!self.match(TokenType.New)) {
        return null;
    }

    return self.addNode(main_token, AST.Node{
        .new_expr = try expectCallableExpression(self),
    });
}

pub fn parseMemberExpression(self: *Parser) CompilationError!?AST.Node.Index {
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

pub fn parseCallableExpression(self: *Parser) CompilationError!?AST.Node.Index {
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

pub fn expectCallableExpression(self: *Parser) CompilationError!AST.Node.Index {
    return try parseCallableExpression(self) orelse self.fail(diagnostics.expression_expected, .{});
}

pub fn parseIndexAccess(self: *Parser, expr: AST.Node.Index) CompilationError!?AST.Node.Index {
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

pub fn parsePropertyAccess(self: *Parser, expr: AST.Node.Index) CompilationError!?AST.Node.Index {
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

    try TestParser.run(text, parseExpression, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, comptime markers: MarkerList(text)) !void {
            try t.expectAST(node, AST.Node{ .comma = .{
                .left = AST.Node.at(3),
                .right = AST.Node.at(4),
            } });
            try t.expectTokenAt(markers[0], node.?);
        }
    });
}

test "should parse conditional expression" {
    const text =
        \\a ? b : c
        \\> ^
    ;

    try TestParser.run(text, parseExpression, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, comptime markers: MarkerList(text)) !void {
            try t.expectAST(node, AST.Node{ .ternary_expr = .{
                .expr = AST.Node.at(1),
                .body = AST.Node.at(2),
                .@"else" = AST.Node.at(3),
            } });
            try t.expectTokenAt(markers[0], node.?);
        }
    });
}

test "should return syntax error if short circuit expression is missing" {
    const text =
        \\a ? b
        \\>    ^
    ;

    try TestParser.runAny(text, parseExpression, struct {
        pub fn expect(t: TestParser, nodeOrError: CompilationError!?AST.Node.Index, comptime markers: MarkerList(text)) !void {
            try t.expectSyntaxErrorAt(nodeOrError, diagnostics.ARG_expected, .{":"}, markers[0]);
        }
    });
}

test "should parse short circuit expression" {
    const text =
        \\a ?? b
        \\> ^
    ;

    try TestParser.run(text, parseExpression, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, comptime markers: MarkerList(text)) !void {
            try t.expectAST(node, AST.Node{ .coalesce = .{
                .left = AST.Node.at(1),
                .right = AST.Node.at(2),
            } });
            try t.expectTokenAt(markers[0], node.?);
        }
    });
}

test "should parse unary expression" {
    const tests = .{
        .{ "+a", AST.Node{ .plus = AST.Node.at(1) } },
        .{ "-a", AST.Node{ .minus = AST.Node.at(1) } },
        .{ "!a", AST.Node{ .not = AST.Node.at(1) } },
        .{ "~a", AST.Node{ .bitwise_negate = AST.Node.at(1) } },
        .{ "typeof a", AST.Node{ .typeof = AST.Node.at(1) } },
        .{ "void a", AST.Node{ .void = AST.Node.at(1) } },
        .{ "delete a", AST.Node{ .delete = AST.Node.at(1) } },
    };

    inline for (tests) |test_case| {
        try TestParser.run(test_case[0], parseUnary, struct {
            pub fn expect(t: TestParser, node: ?AST.Node.Index, _: MarkerList(test_case[0])) !void {
                try t.expectAST(node, test_case[1]);
                try t.expectTokenAt(comptime Marker.fromText("^"), node.?);
            }
        });
    }
}

test "should parse update expression" {
    const tests = .{
        .{
            \\ ++a
            \\>^
            ,
            AST.Node{ .plusplus_pre = AST.Node.at(1) },
        },
        .{
            \\ --a
            \\>^
            ,
            AST.Node{ .minusminus_pre = AST.Node.at(1) },
        },
        .{
            \\a++
            \\>^
            ,
            AST.Node{ .plusplus_post = AST.Node.at(1) },
        },
        .{
            \\a--
            \\>^
            ,
            AST.Node{ .minusminus_post = AST.Node.at(1) },
        },
    };

    inline for (tests) |test_case| {
        try TestParser.run(test_case[0], parseUnary, struct {
            pub fn expect(t: TestParser, node: ?AST.Node.Index, comptime markers: MarkerList(test_case[0])) !void {
                try t.expectAST(node, test_case[1]);
                try t.expectTokenAt(markers[0], node.?);
            }
        });
    }
}

test "should parse left hand side expression" {
    const text = "a()";

    try TestParser.run(text, parseLeftHandSideExpression, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectAST(node, AST.Node{ .call_expr = .{ .node = AST.Node.at(1), .params = &.{} } });
        }
    });
}

test "should return syntax error if left hand side expression is missing" {
    const text =
        \\()
        \\>^
    ;

    try TestParser.runAny(text, parseLeftHandSideExpression, struct {
        pub fn expect(t: TestParser, nodeOrError: CompilationError!?AST.Node.Index, comptime markers: MarkerList(text)) !void {
            try t.expectSyntaxErrorAt(nodeOrError, diagnostics.expression_expected, .{}, markers[0]);
        }
    });
}

test "should parse new expression" {
    const text = "new a";

    try TestParser.run(text, parseNewExpression, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectAST(node, AST.Node{ .new_expr = AST.Node.at(1) });
        }
    });
}

test "should return null if new expression is missing" {
    const text = "a";

    try TestParser.run(text, parseNewExpression, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectAST(node, null);
        }
    });
}

test "should parse member expression" {
    const tests = .{
        .{
            \\ new a()
            \\>^
            ,
            AST.Node{ .new_expr = AST.Node.at(2) },
        },
        .{
            \\ a
            \\>^
            ,
            AST.Node{ .simple_value = .{ .kind = .identifier } },
        },
        .{
            \\a.b
            \\>^
            ,
            AST.Node{ .property_access = .{ .left = AST.Node.at(1), .right = AST.Node.at(2) } },
        },
        .{
            \\a[0]
            \\>^
            ,
            AST.Node{ .index_access = .{ .left = AST.Node.at(1), .right = AST.Node.at(2) } },
        },
    };

    inline for (tests) |test_case| {
        try TestParser.run(test_case[0], parseMemberExpression, struct {
            pub fn expect(t: TestParser, node: ?AST.Node.Index, comptime markers: MarkerList(test_case[0])) !void {
                try t.expectAST(node, test_case[1]);
                try t.expectTokenAt(markers[0], node.?);
            }
        });
    }
}

test "should return syntax error if property access key is not identifier" {
    const text =
        \\a.'123'
        \\> ^
    ;

    try TestParser.runAny(text, parseMemberExpression, struct {
        pub fn expect(t: TestParser, nodeOrError: CompilationError!?AST.Node.Index, comptime markers: MarkerList(text)) !void {
            try t.expectSyntaxErrorAt(nodeOrError, diagnostics.identifier_expected, .{}, markers[0]);
        }
    });
}

test "should parse chained member expression" {
    const tests = .{
        .{
            \\new a().b
            \\>      ^
            ,
            &[_]AST.Raw{
                .{ .tag = .simple_value, .main_token = Token.at(1), .data = .{ .lhs = 1, .rhs = 0 } },
                .{ .tag = .call_expr, .main_token = Token.at(1), .data = .{ .lhs = 1, .rhs = 0 } },
                .{ .tag = .new_expr, .main_token = Token.at(0), .data = .{ .lhs = 2, .rhs = 0 } },
                .{ .tag = .simple_value, .main_token = Token.at(5), .data = .{ .lhs = 1, .rhs = 0 } },
                .{ .tag = .property_access, .main_token = Token.at(4), .data = .{ .lhs = 3, .rhs = 4 } },
            },
        },
        .{
            \\a.b
            \\>^
            ,
            &[_]AST.Raw{
                .{ .tag = .simple_value, .main_token = Token.at(0), .data = .{ .lhs = 1, .rhs = 0 } },
                .{ .tag = .simple_value, .main_token = Token.at(2), .data = .{ .lhs = 1, .rhs = 0 } },
                .{ .tag = .property_access, .main_token = Token.at(1), .data = .{ .lhs = 1, .rhs = 2 } },
            },
        },
    };

    inline for (tests) |test_case| {
        try TestParser.run(test_case[0], parseMemberExpression, struct {
            pub fn expect(t: TestParser, node: ?AST.Node.Index, comptime markers: MarkerList(test_case[0])) !void {
                try t.expectNodesToEqual(test_case[1]);
                try t.expectTokenAt(markers[0], node.?);
            }
        });
    }
}

test "should parse callable expression" {
    const tests = .{
        .{ "a()", AST.Node{ .call_expr = .{
            .node = AST.Node.at(1),
            .params = &.{},
        } } },
        .{ "a(b)", AST.Node{ .call_expr = .{
            .node = AST.Node.at(1),
            .params = @constCast(&[_]AST.Node.Index{AST.Node.at(2)}),
        } } },
        .{ "a(b, c)", AST.Node{ .call_expr = .{
            .node = AST.Node.at(1),
            .params = @constCast(&[_]AST.Node.Index{ AST.Node.at(2), AST.Node.at(3) }),
        } } },
        .{ "a(b + c)", AST.Node{ .call_expr = .{
            .node = AST.Node.at(1),
            .params = @constCast(&[_]AST.Node.Index{AST.Node.at(4)}),
        } } },
        .{ "a(b,)", AST.Node{ .call_expr = .{
            .node = AST.Node.at(1),
            .params = @constCast(&[_]AST.Node.Index{AST.Node.at(2)}),
        } } },
    };
    const marker = "^";

    inline for (tests) |test_case| {
        try TestParser.run(test_case[0], parseCallableExpression, struct {
            pub fn expect(t: TestParser, node: ?AST.Node.Index, _: MarkerList(test_case[0])) !void {
                try t.expectAST(node, test_case[1]);
                try t.expectTokenAt(comptime Marker.fromText(marker), node.?);
            }
        });
    }
}

test "should parse chained callable expression" {
    const text =
        \\ a(1)(2)(3)
        \\>^   ^  ^
    ;

    try TestParser.run(text, parseCallableExpression, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, comptime markers: MarkerList(text)) !void {
            const call_expr1 = AST.Node{ .call_expr = .{
                .node = AST.Node.at(5),
                .params = @constCast(&[_]AST.Node.Index{AST.Node.at(6)}),
            } };
            try t.expectAST(node, call_expr1);
            try t.expectTokenAt(markers[2], node.?);

            const call_expr2 = AST.Node{ .call_expr = .{
                .node = AST.Node.at(3),
                .params = @constCast(&[_]AST.Node.Index{AST.Node.at(4)}),
            } };
            try t.expectAST(call_expr1.call_expr.node, call_expr2);
            try t.expectTokenAt(markers[1], call_expr1.call_expr.node);

            const call_expr3 = AST.Node{ .call_expr = .{
                .node = AST.Node.at(1),
                .params = @constCast(&[_]AST.Node.Index{AST.Node.at(2)}),
            } };
            try t.expectAST(call_expr2.call_expr.node, call_expr3);
            try t.expectTokenAt(markers[0], call_expr2.call_expr.node);
        }
    });
}

test "should return syntax error if comma is missing between params" {
    const text =
        \\a(b c)
        \\>   ^
    ;

    try TestParser.runAny(text, parseCallableExpression, struct {
        pub fn expect(t: TestParser, nodeOrError: CompilationError!?AST.Node.Index, comptime markers: MarkerList(text)) !void {
            try t.expectSyntaxErrorAt(nodeOrError, diagnostics.ARG_expected, .{","}, markers[0]);
        }
    });
}
