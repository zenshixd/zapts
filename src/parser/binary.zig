const std = @import("std");
const Parser = @import("../parser.zig");
const ParserError = @import("../parser.zig").ParserError;
const AST = @import("../ast.zig");
const TokenType = @import("../consts.zig").TokenType;

const diagnostics = @import("../diagnostics.zig");

const parseType = @import("types.zig").parseType;
const parseUnary = @import("expressions.zig").parseUnary;
const expectUnary = @import("expressions.zig").expectUnary;
const parseAsyncArrowFunction = @import("functions.zig").parseAsyncArrowFunction;
const parseArrowFunction = @import("functions.zig").parseArrowFunction;
const parseConditionalExpression = @import("expressions.zig").parseConditionalExpression;

const TestParser = @import("../test_parser.zig");
const MarkerList = @import("../test_parser.zig").MarkerList;
const Marker = @import("../test_parser.zig").Marker;

const expectEqual = std.testing.expectEqual;
const expectEqualDeep = std.testing.expectEqualDeep;

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
pub fn parseAssignment(parser: *Parser) ParserError!?AST.Node.Index {
    const node = try parseAsyncArrowFunction(parser) orelse
        try parseArrowFunction(parser) orelse
        try parseConditionalExpression(parser) orelse
        return null;

    inline for (assignment_map) |assignment| {
        const main_token = parser.cur_token;
        if (parser.match(assignment[0])) {
            const tag = assignment[1];
            return parser.addNode(main_token, @unionInit(AST.Node, tag, .{
                .left = node,
                .right = try expectAssignment(parser),
            }));
        }
    }

    return node;
}

pub fn expectAssignment(parser: *Parser) ParserError!AST.Node.Index {
    return try parseAssignment(parser) orelse parser.fail(diagnostics.expression_expected, .{});
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
            _ = parser.advanceBy(binary_operators[operator_index][0].len);
        }

        return is_match;
    }

    return parser.match(binary_operators[operator_index][0]);
}

pub fn parseBinaryExpression(parser: *Parser) ParserError!?AST.Node.Index {
    return try parseBinaryExpressionExtra(parser, 0);
}

pub fn parseBinaryExpressionExtra(parser: *Parser, operator_index: comptime_int) ParserError!?AST.Node.Index {
    var node = if (operator_index + 1 < binary_operators.len)
        try parseBinaryExpressionExtra(parser, operator_index + 1) orelse return null
    else
        try parseUnary(parser) orelse return null;

    var main_token = parser.cur_token;
    while (binaryOperatorMatches(parser, operator_index)) {
        const right = if (operator_index + 1 < binary_operators.len)
            try expectBinaryExpressionExtra(parser, operator_index + 1)
        else
            try expectUnary(parser);

        const new_node = parser.addNode(main_token, @unionInit(AST.Node, binary_operators[operator_index][1], .{
            .left = node,
            .right = right,
        }));
        node = new_node;
        main_token = parser.cur_token;
    }
    return node;
}

pub fn expectBinaryExpressionExtra(parser: *Parser, operator_index: comptime_int) ParserError!AST.Node.Index {
    return try parseBinaryExpressionExtra(parser, operator_index) orelse parser.fail(diagnostics.expression_expected, .{});
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
    const marker = "  ^";

    try expectEqual(test_cases.len, binary_operators.len);
    inline for (test_cases, 0..) |test_case, i| {
        try TestParser.run(test_case, parseBinaryExpression, struct {
            pub fn expect(t: TestParser, node: ?AST.Node.Index, _: MarkerList(test_case)) !void {
                try t.expectAST(node, @unionInit(AST.Node, binary_operators[i][1], .{
                    .left = AST.Node.at(1),
                    .right = AST.Node.at(2),
                }));
                try t.expectTokenAt(comptime Marker.fromText(marker), node.?);
            }
        });
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
    const marker = "  ^";

    try expectEqual(test_cases.len, assignment_map.len);
    inline for (test_cases, 0..) |test_case, i| {
        try TestParser.run(test_case, parseAssignment, struct {
            pub fn expect(t: TestParser, node: ?AST.Node.Index, _: MarkerList(test_case)) !void {
                try t.expectAST(node, @unionInit(AST.Node, assignment_map[i][1], .{
                    .left = AST.Node.at(1),
                    .right = AST.Node.at(2),
                }));
                try t.expectTokenAt(comptime Marker.fromText(marker), node.?);
            }
        });
    }
}
