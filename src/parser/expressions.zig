const std = @import("std");
const Parser = @import("../parser.zig");
const AST = @import("../ast.zig");
const Token = @import("../consts.zig").Token;
const TokenType = @import("../consts.zig").TokenType;
const ParserError = Parser.ParserError;
const diagnostics = @import("../diagnostics.zig");

const parseAssignment = @import("binary.zig").parseAssignment;
const parseBinaryExpression = @import("binary.zig").parseBinaryExpression;
const parsePrimaryExpression = @import("primary.zig").parsePrimaryExpression;
const parseIdentifier = @import("primary.zig").parseIdentifier;

const expectAST = @import("../parser.zig").expectAST;
const expectMaybeAST = @import("../parser.zig").expectMaybeAST;
const expectSyntaxError = @import("../parser.zig").expectSyntaxError;

pub fn parseExpression(self: *Parser) ParserError!AST.Node.Index {
    var node = try parseAssignment(self);
    while (self.match(TokenType.Comma)) {
        const new_node = self.addNode(self.cur_token, AST.Node{
            .comma = .{
                .left = node,
                .right = try parseAssignment(self),
            },
        });

        node = new_node;
    }

    return node;
}

pub fn parseConditionalExpression(self: *Parser) ParserError!AST.Node.Index {
    var node = try parseShortCircuitExpression(self);

    if (self.match(TokenType.QuestionMark)) {
        const true_expr = try parseAssignment(self);
        _ = try self.consume(TokenType.Colon, diagnostics.ARG_expected, .{":"});
        const false_expr = try parseAssignment(self);
        const new_node = self.addNode(self.cur_token, AST.Node{ .ternary_expr = .{
            .expr = node,
            .body = true_expr,
            .@"else" = false_expr,
        } });

        node = new_node;
    }

    return node;
}

pub fn parseShortCircuitExpression(self: *Parser) ParserError!AST.Node.Index {
    return try parseBinaryExpression(self, 0);
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
pub fn parseUnary(self: *Parser) ParserError!AST.Node.Index {
    inline for (unary_operators) |unary_operator| {
        if (self.match(unary_operator.token)) {
            return self.addNode(self.cur_token, @unionInit(AST.Node, unary_operator.tag, try parseUnary(self)));
        }
    }

    return parseUpdateExpression(self);
}

pub fn parseUpdateExpression(self: *Parser) ParserError!AST.Node.Index {
    if (self.match(TokenType.PlusPlus)) {
        return self.addNode(self.cur_token, AST.Node{
            .plusplus_pre = try parseUnary(self),
        });
    } else if (self.match(TokenType.MinusMinus)) {
        return self.addNode(self.cur_token, AST.Node{
            .minusminus_pre = try parseUnary(self),
        });
    }

    const node = try parseLeftHandSideExpression(self);

    if (self.match(TokenType.PlusPlus)) {
        return self.addNode(self.cur_token, AST.Node{
            .plusplus_post = node,
        });
    } else if (self.match(TokenType.MinusMinus)) {
        return self.addNode(self.cur_token, AST.Node{
            .minusminus_post = node,
        });
    }

    return node;
}

pub fn parseLeftHandSideExpression(self: *Parser) ParserError!AST.Node.Index {
    return try parseCallableExpression(self) orelse return self.fail(diagnostics.identifier_expected, .{});
}

pub fn parseNewExpression(self: *Parser) ParserError!?AST.Node.Index {
    if (!self.match(TokenType.New)) {
        return null;
    }

    const maybe_node = try parseCallableExpression(self);
    if (maybe_node) |node| {
        return self.addNode(self.cur_token, AST.Node{
            .new_expr = node,
        });
    }

    self.rewind();
    return null;
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
    var node = try parseMemberExpression(self) orelse return null;

    while (self.match(TokenType.OpenParen)) {
        var nodes = std.ArrayList(AST.Node.Index).init(self.gpa);
        defer nodes.deinit();

        while (!self.match(TokenType.CloseParen)) {
            try nodes.append(try parseAssignment(self));

            if (self.match(TokenType.CloseParen)) {
                break;
            }

            _ = try self.consume(TokenType.Comma, diagnostics.ARG_expected, .{","});
        }

        const new_node = self.addNode(self.cur_token, AST.Node{
            .call_expr = .{
                .node = node,
                .params = nodes.items,
            },
        });
        node = new_node;
    }

    return node;
}

pub fn parseIndexAccess(self: *Parser, expr: AST.Node.Index) ParserError!?AST.Node.Index {
    if (!self.match(TokenType.OpenSquareBracket)) {
        return null;
    }

    const node = self.addNode(self.cur_token, AST.Node{
        .index_access = .{
            .left = expr,
            .right = try parseExpression(self),
        },
    });

    _ = try self.consume(TokenType.CloseSquareBracket, diagnostics.ARG_expected, .{"]"});

    return node;
}

pub fn parsePropertyAccess(self: *Parser, expr: AST.Node.Index) ParserError!?AST.Node.Index {
    if (!self.match(TokenType.Dot)) {
        return null;
    }

    const identifier = try parseIdentifier(self) orelse return self.fail(diagnostics.identifier_expected, .{});

    return self.addNode(self.cur_token, AST.Node{
        .property_access = .{
            .left = expr,
            .right = identifier,
        },
    });
}

test "should parse comma expression" {
    const text = "a = b, c";

    try expectAST(parseExpression, AST.Node{ .comma = .{
        .left = 5,
        .right = 7,
    } }, text);
}

test "should parse conditional expression" {
    const text = "a ? b : c";

    try expectAST(parseExpression, AST.Node{ .ternary_expr = .{
        .expr = 2,
        .body = 4,
        .@"else" = 6,
    } }, text);
}

test "should return syntax error if short circuit expression is missing" {
    const text = "a ? b";

    try expectSyntaxError(parseExpression, text, diagnostics.ARG_expected, .{":"});
}

test "should parse short circuit expression" {
    const text = "a ?? b";
    try expectAST(parseExpression, AST.Node{ .coalesce = .{
        .left = 2,
        .right = 3,
    } }, text);
}

test "should parse unary expression" {
    const tests = .{
        .{ "+a", AST.Node{ .plus = 1 } },
        .{ "-a", AST.Node{ .minus = 1 } },
        .{ "!a", AST.Node{ .not = 1 } },
        .{ "~a", AST.Node{ .bitwise_negate = 1 } },
        .{ "typeof a", AST.Node{ .typeof = 1 } },
        .{ "void a", AST.Node{ .void = 1 } },
        .{ "delete a", AST.Node{ .delete = 1 } },
    };

    inline for (tests) |test_case| {
        try expectAST(parseUnary, test_case[1], test_case[0]);
    }
}

test "should parse update expression" {
    const tests = .{
        .{ "++a", AST.Node{ .plusplus_pre = 1 } },
        .{ "--a", AST.Node{ .minusminus_pre = 1 } },
        .{ "a++", AST.Node{ .plusplus_post = 1 } },
        .{ "a--", AST.Node{ .minusminus_post = 1 } },
    };

    inline for (tests) |test_case| {
        try expectAST(parseUnary, test_case[1], test_case[0]);
    }
}

test "should parse left hand side expression" {
    const text = "a()";

    try expectAST(parseLeftHandSideExpression, AST.Node{ .call_expr = .{ .node = 1, .params = &.{} } }, text);
}

test "should return syntax error if left hand side expression is missing" {
    const text = "()";

    try expectSyntaxError(parseLeftHandSideExpression, text, diagnostics.identifier_expected, .{});
}

test "should parse new expression" {
    const text = "new a";

    try expectMaybeAST(parseNewExpression, AST.Node{ .new_expr = 1 }, text);
}

test "should return null if new expression is missing" {
    const text = "a";

    try expectMaybeAST(parseNewExpression, null, text);
}

test "should parse member expression" {
    const tests = .{
        .{ "new a()", AST.Node{ .new_expr = 2 } },
        .{ "a", AST.Node{ .simple_value = .{ .kind = .identifier } } },
        .{ "a.b", AST.Node{ .property_access = .{ .left = 1, .right = 2 } } },
        .{ "a[0]", AST.Node{ .index_access = .{ .left = 1, .right = 2 } } },
    };

    inline for (tests) |test_case| {
        try expectMaybeAST(parseMemberExpression, test_case[1], test_case[0]);
    }
}

test "should return syntax error if property access key is not identifier" {
    const text = "a.'123'";

    try expectSyntaxError(parseMemberExpression, text, diagnostics.identifier_expected, .{});
}

test "should parse chained member expression" {
    const tests = .{
        .{
            "new a().b",
            &[_]AST.Raw{
                .{ .tag = .simple_value, .main_token = 1, .data = .{ .lhs = 1, .rhs = 0 } },
                .{ .tag = .call_expr, .main_token = 4, .data = .{ .lhs = 1, .rhs = 0 } },
                .{ .tag = .new_expr, .main_token = 4, .data = .{ .lhs = 2, .rhs = 0 } },
                .{ .tag = .simple_value, .main_token = 5, .data = .{ .lhs = 1, .rhs = 0 } },
                .{ .tag = .property_access, .main_token = 6, .data = .{ .lhs = 3, .rhs = 4 } },
            },
        },
        .{
            "a.b",
            &[_]AST.Raw{
                .{ .tag = .simple_value, .main_token = 0, .data = .{ .lhs = 1, .rhs = 0 } },
                .{ .tag = .simple_value, .main_token = 2, .data = .{ .lhs = 1, .rhs = 0 } },
                .{ .tag = .property_access, .main_token = 3, .data = .{ .lhs = 1, .rhs = 2 } },
            },
        },
    };

    inline for (tests) |test_case| {
        var parser = Parser.init(std.testing.allocator, test_case[0]);
        defer parser.deinit();

        _ = try parseMemberExpression(&parser);
        try parser.expectNodesToEqual(test_case[1]);
    }
}

test "should parse callable expression" {
    const tests = .{
        .{ "a()", AST.Node{ .call_expr = .{ .node = 1, .params = @constCast(&[_]AST.Node.Index{}) } } },
        .{ "a(b)", AST.Node{ .call_expr = .{ .node = 1, .params = @constCast(&[_]AST.Node.Index{3}) } } },
        .{ "a(b, c)", AST.Node{ .call_expr = .{ .node = 1, .params = @constCast(&[_]AST.Node.Index{ 3, 5 }) } } },
        .{ "a(b + c)", AST.Node{ .call_expr = .{ .node = 1, .params = @constCast(&[_]AST.Node.Index{5}) } } },
        .{ "a(b,)", AST.Node{ .call_expr = .{ .node = 1, .params = @constCast(&[_]AST.Node.Index{3}) } } },
    };

    inline for (tests) |test_case| {
        try expectMaybeAST(parseCallableExpression, test_case[1], test_case[0]);
    }
}

test "should return syntax error if comma is missing between params" {
    const text = "a(b c)";

    try expectSyntaxError(parseCallableExpression, text, diagnostics.ARG_expected, .{","});
}
