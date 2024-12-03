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
    .{ .Equal, "assignment" },
    .{ .PlusEqual, "plus_assign" },
    .{ .MinusEqual, "minus_assign" },
    .{ .StarEqual, "multiply_assign" },
    .{ .StarStarEqual, "exp_assign" },
    .{ .SlashEqual, "div_assign" },
    .{ .PercentEqual, "modulo_assign" },
    .{ .AmpersandEqual, "bitwise_and_assign" },
    .{ .BarEqual, "bitwise_or_assign" },
    .{ .CaretEqual, "bitwise_xor_assign" },
    .{ .BarBarEqual, "or_assign" },
    .{ .AmpersandAmpersandEqual, "and_assign" },
    .{ .GreaterThanGreaterThanEqual, "bitwise_shift_right_assign" },
    .{ .GreaterThanGreaterThanGreaterThanEqual, "bitwise_unsigned_right_shift_assign" },
    .{ .LessThanLessThanEqual, "bitwise_shift_left_assign" },
    .{ .QuestionMarkQuestionMarkEqual, "coalesce_assign" },
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
    .{ .token = TokenType.QuestionMarkQuestionMark, .tag = "coalesce" },
    .{ .token = TokenType.BarBar, .tag = "or" },
    .{ .token = TokenType.AmpersandAmpersand, .tag = "and" },
    .{ .token = TokenType.Bar, .tag = "bitwise_or" },
    .{ .token = TokenType.Caret, .tag = "bitwise_xor" },
    .{ .token = TokenType.Ampersand, .tag = "bitwise_and" },
    .{ .token = TokenType.EqualEqual, .tag = "eq" },
    .{ .token = TokenType.ExclamationMarkEqual, .tag = "neq" },
    .{ .token = TokenType.EqualEqualEqual, .tag = "eqq" },
    .{ .token = TokenType.ExclamationMarkEqualEqual, .tag = "neqq" },
    .{ .token = TokenType.LessThan, .tag = "lt" },
    .{ .token = TokenType.GreaterThan, .tag = "gt" },
    .{ .token = TokenType.LessThanEqual, .tag = "lte" },
    .{ .token = TokenType.GreaterThanEqual, .tag = "gte" },
    .{ .token = TokenType.Instanceof, .tag = "instanceof" },
    .{ .token = TokenType.In, .tag = "in" },
    .{ .token = TokenType.LessThanLessThan, .tag = "bitwise_shift_left" },
    .{ .token = TokenType.GreaterThanGreaterThan, .tag = "bitwise_shift_right" },
    .{ .token = TokenType.GreaterThanGreaterThanGreaterThan, .tag = "bitwise_unsigned_right_shift" },
    .{ .token = TokenType.Plus, .tag = "plus_expr" },
    .{ .token = TokenType.Minus, .tag = "minus_expr" },
    .{ .token = TokenType.Star, .tag = "multiply_expr" },
    .{ .token = TokenType.Slash, .tag = "div_expr" },
    .{ .token = TokenType.Percent, .tag = "modulo_expr" },
    .{ .token = TokenType.StarStar, .tag = "exp_expr" },
};
pub fn parseBinaryExpression(parser: *Parser, operator_index: comptime_int) ParserError!AST.Node.Index {
    var node = if (operator_index + 1 < binary_operators.len)
        try parseBinaryExpression(parser, operator_index + 1)
    else
        try parseUnary(parser);

    while (parser.match(binary_operators[operator_index].token)) {
        const new_node = parser.addNode(parser.cur_token, @unionInit(AST.Node, binary_operators[operator_index].tag, .{
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
        try expectEqualDeep(@unionInit(AST.Node, binary_operators[i].tag, .{ .left = 1, .right = 2 }), parser.getNode(node));
    }
}

test "should parse casting expression" {
    const text = "<T>a";

    // TODO: fix this test
    try expectAST(parseAssignment, AST.Node{ .simple_value = .{ .kind = .identifier } }, text);
}

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
