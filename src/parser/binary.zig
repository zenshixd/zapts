const std = @import("std");
const Parser = @import("../parser.zig");
const AST = @import("../ast.zig");
const TokenType = @import("../consts.zig").TokenType;
const ParserError = Parser.ParserError;
const diagnostics = @import("../diagnostics.zig");

const parseSymbolType = @import("types.zig").parseSymbolType;
const parseUnary = @import("expressions.zig").parseUnary;
const parseAsyncArrowFunction = @import("functions.zig").parseAsyncArrowFunction;
const parseArrowFunction = @import("functions.zig").parseArrowFunction;
const parseConditionalExpression = @import("expressions.zig").parseConditionalExpression;

const expectEqual = std.testing.expectEqual;
const expectEqualDeep = std.testing.expectEqualDeep;
const expectAST = Parser.expectAST;
const expectMaybeAST = Parser.expectMaybeAST;

const assignment_map = .{
    .{ TokenType.Equal, "assignment" },
    .{ TokenType.PlusEqual, "plus_assign" },
    .{ TokenType.MinusEqual, "minus_assign" },
    .{ TokenType.StarEqual, "multiply_assign" },
    .{ TokenType.StarStarEqual, "exp_assign" },
    .{ TokenType.SlashEqual, "div_assign" },
    .{ TokenType.PercentEqual, "modulo_assign" },
    .{ TokenType.AmpersandEqual, "bitwise_and_assign" },
    .{ TokenType.BarEqual, "bitwise_or_assign" },
    .{ TokenType.CaretEqual, "bitwise_xor_assign" },
    .{ TokenType.BarBarEqual, "or_assign" },
    .{ TokenType.AmpersandAmpersandEqual, "and_assign" },
    .{ [_]TokenType{ TokenType.GreaterThan, TokenType.GreaterThanEqual }, "bitwise_shift_right_assign" },
    .{ [_]TokenType{ TokenType.GreaterThan, TokenType.GreaterThan, TokenType.GreaterThanEqual }, "bitwise_unsigned_right_shift_assign" },
    .{ TokenType.LessThanLessThanEqual, "bitwise_shift_left_assign" },
    .{ TokenType.QuestionMarkQuestionMarkEqual, "coalesce_assign" },
};
pub fn parseAssignment(parser: *Parser) ParserError!AST.Node.Index {
    const node = try parseAsyncArrowFunction(parser) orelse
        try parseArrowFunction(parser) orelse
        try parseConditionalExpression(parser);

    inline for (assignment_map) |assignment| {
        if (parser.match(assignment[0])) {
            const tag = assignment[1];
            return parser.addNode(parser.cur_token, @unionInit(AST.Node, tag, .{
                .left = node,
                .right = try parseAssignment(parser),
            }));
        }
    }

    return node;
}

pub const binary_operators = .{
    .{ TokenType.QuestionMarkQuestionMark, "coalesce" },
    .{ TokenType.BarBar, "or" },
    .{ TokenType.AmpersandAmpersand, "and" },
    .{ TokenType.Bar, "bitwise_or" },
    .{ TokenType.Caret, "bitwise_xor" },
    .{ TokenType.Ampersand, "bitwise_and" },
    .{ TokenType.EqualEqual, "eq" },
    .{ TokenType.ExclamationMarkEqual, "neq" },
    .{ TokenType.EqualEqualEqual, "eqq" },
    .{ TokenType.ExclamationMarkEqualEqual, "neqq" },
    .{ TokenType.LessThan, "lt" },
    .{ TokenType.GreaterThan, "gt" },
    .{ TokenType.LessThanEqual, "lte" },
    .{ TokenType.GreaterThanEqual, "gte" },
    .{ TokenType.Instanceof, "instanceof" },
    .{ TokenType.In, "in" },
    .{ TokenType.LessThanLessThan, "bitwise_shift_left" },
    .{ [_]TokenType{ TokenType.GreaterThan, TokenType.GreaterThan }, "bitwise_shift_right" },
    .{ [_]TokenType{ TokenType.GreaterThan, TokenType.GreaterThan, TokenType.GreaterThan }, "bitwise_unsigned_right_shift" },
    .{ TokenType.Plus, "plus_expr" },
    .{ TokenType.Minus, "minus_expr" },
    .{ TokenType.Star, "multiply_expr" },
    .{ TokenType.Slash, "div_expr" },
    .{ TokenType.Percent, "modulo_expr" },
    .{ TokenType.StarStar, "exp_expr" },
};

fn binaryOperatorMatches(parser: *Parser, operator_index: comptime_int) bool {
    if (@TypeOf(binary_operators[operator_index][0]) == TokenType and binary_operators[operator_index][0] == TokenType.GreaterThan) {
        const is_match = parser.peekMatch(TokenType.GreaterThan) and
            !parser.peekMatchMany(.{ TokenType.GreaterThan, TokenType.GreaterThan }) and
            !parser.peekMatchMany(.{ TokenType.GreaterThan, TokenType.GreaterThanEqual });

        if (is_match) {
            _ = parser.advance();
        }

        return is_match;
    }

    if (@TypeOf(binary_operators[operator_index][0]) == [2]TokenType and std.meta.eql(binary_operators[operator_index][0], .{ TokenType.GreaterThan, TokenType.GreaterThan })) {
        const is_match = parser.peekMatchMany(.{ TokenType.GreaterThan, TokenType.GreaterThan }) and
            !parser.peekMatchMany(.{ TokenType.GreaterThan, TokenType.GreaterThan, TokenType.GreaterThan }) and
            !parser.peekMatchMany(.{ TokenType.GreaterThan, TokenType.GreaterThan, TokenType.GreaterThanEqual });

        if (is_match) {
            parser.cur_token += @intCast(binary_operators[operator_index][0].len);
        }

        return is_match;
    }

    return parser.match(binary_operators[operator_index][0]);
}

pub fn parseBinaryExpression(parser: *Parser, operator_index: comptime_int) ParserError!AST.Node.Index {
    var node = if (operator_index + 1 < binary_operators.len)
        try parseBinaryExpression(parser, operator_index + 1)
    else
        try parseUnary(parser);

    while (binaryOperatorMatches(parser, operator_index)) {
        const new_node = parser.addNode(parser.cur_token, @unionInit(AST.Node, binary_operators[operator_index][1], .{
            .left = node,
            .right = if (operator_index + 1 < binary_operators.len)
                try parseBinaryExpression(parser, operator_index + 1)
            else
                try parseUnary(parser),
        }));
        node = new_node;
    }
    return node;
}

test "should parse binary expression" {
    const test_cases = .{
        "a ?? b",
        "a || b",
        "a && b",
        "a | b",
        "a ^ b",
        "a & b",
        "a == b",
        "a != b",
        "a === b",
        "a !== b",
        "a < b",
        "a > b",
        "a <= b",
        "a >= b",
        "a instanceof b",
        "a in b",
        "a << b",
        "a >> b",
        "a >>> b",
        "a + b",
        "a - b",
        "a * b",
        "a / b",
        "a % b",
        "a ** b",
    };

    try expectEqual(test_cases.len, binary_operators.len);
    inline for (test_cases, 0..) |test_case, i| {
        var parser = Parser.init(std.testing.allocator, test_case);
        defer parser.deinit();

        const node = try parseBinaryExpression(&parser, 0);
        try expectEqualDeep(@unionInit(AST.Node, binary_operators[i][1], .{ .left = 1, .right = 2 }), parser.getNode(node));
    }
}

//test "should parse casting expression" {
//    const text = "<T>a";
//
//    // TODO: fix this test
//    try expectAST(parseAssignment, AST.Node{ .simple_value = .{ .kind = .identifier } }, text);
//}

test "should parse assignment expression" {
    const test_cases = .{
        "a = b",
        "a += b",
        "a -= b",
        "a *= b",
        "a **= b",
        "a /= b",
        "a %= b",
        "a &= b",
        "a |= b",
        "a ^= b",
        "a ||= b",
        "a &&= b",
        "a >>= b",
        "a >>>= b",
        "a <<= b",
        "a ??= b",
    };

    try expectEqual(test_cases.len, assignment_map.len);
    inline for (test_cases, 0..) |test_case, i| {
        var parser = Parser.init(std.testing.allocator, test_case);
        defer parser.deinit();

        const node = try parseAssignment(&parser);
        try expectEqualDeep(@unionInit(AST.Node, assignment_map[i][1], .{ .left = 2, .right = 4 }), parser.getNode(node));
    }
}
