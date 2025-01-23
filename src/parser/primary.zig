const std = @import("std");

const Token = @import("../consts.zig").Token;
const TokenType = @import("../consts.zig").TokenType;
const isAllowedIdentifier = @import("../consts.zig").isAllowedIdentifier;

const AST = @import("../ast.zig");
const Parser = @import("../parser.zig");
const diagnostics = @import("../diagnostics.zig");

const parseAssignment = @import("binary.zig").parseAssignment;
const parseClassStatement = @import("classes.zig").parseClassStatement;
const parseFunctionStatement = @import("functions.zig").parseFunctionStatement;
const parseAsyncFunctionStatement = @import("functions.zig").parseAsyncFunctionStatement;
const parseMethodGetter = @import("functions.zig").parseMethodGetter;
const parseMethodSetter = @import("functions.zig").parseMethodSetter;
const parseMethodGenerator = @import("functions.zig").parseMethodGenerator;
const parseMethodAsyncGenerator = @import("functions.zig").parseMethodAsyncGenerator;
const parseMethod = @import("functions.zig").parseMethod;
const parseObjectElementName = @import("functions.zig").parseObjectElementName;
const parseExpression = @import("expressions.zig").parseExpression;

const ParserError = Parser.ParserError;

const expectEqual = std.testing.expectEqual;
const expectEqualDeep = std.testing.expectEqualDeep;
const expectEqualStrings = std.testing.expectEqualStrings;
const expectError = std.testing.expectError;
const testParser = Parser.testParser;
const expectAST = Parser.expectAST;
const expectToken = Parser.expectToken;
const expectSyntaxError = Parser.expectSyntaxError;

pub fn parsePrimaryExpression(parser: *Parser) ParserError!?AST.Node.Index {
    return try parseIdentifier(parser) orelse
        try parseLiteral(parser) orelse
        try parseArrayLiteral(parser) orelse
        try parseObjectLiteral(parser) orelse
        try parseFunctionStatement(parser) orelse
        try parseAsyncFunctionStatement(parser) orelse
        try parseClassStatement(parser) orelse
        try parseGroupingExpression(parser);
}

pub fn parseIdentifier(parser: *Parser) ParserError!?AST.Node.Index {
    if (parser.match(TokenType.Identifier) or try parseKeywordAsIdentifier(parser)) {
        return parser.addNode(parser.cur_token - 1, AST.Node{ .simple_value = .{ .kind = .identifier } });
    }

    return null;
}

pub fn parseKeywordAsIdentifier(parser: *Parser) ParserError!bool {
    if (parser.peekMatchMany(.{ TokenType.Async, TokenType.Function })) {
        return false;
    }

    if (isAllowedIdentifier(parser.token().type)) {
        _ = parser.advance();
        return true;
    }

    return false;
}

const literal_map = .{
    .{ TokenType.This, .this },
    .{ TokenType.Null, .null },
    .{ TokenType.Undefined, .undefined },
    .{ TokenType.True, .true },
    .{ TokenType.False, .false },
    .{ TokenType.NumberConstant, .number },
    .{ TokenType.BigIntConstant, .bigint },
    .{ TokenType.StringConstant, .string },
};

pub fn parseLiteral(parser: *Parser) ParserError!?AST.Node.Index {
    inline for (literal_map) |literal| {
        if (parser.match(literal[0])) {
            return parser.addNode(parser.cur_token - 1, AST.Node{ .simple_value = .{ .kind = literal[1] } });
        }
    }

    return null;
}

pub fn parseArrayLiteral(parser: *Parser) ParserError!?AST.Node.Index {
    if (!parser.match(TokenType.OpenSquareBracket)) {
        return null;
    }

    var values = std.ArrayList(AST.Node.Index).init(parser.gpa);
    defer values.deinit();

    while (true) {
        while (parser.match(TokenType.Comma)) {
            try values.append(AST.Node.Empty);
        }

        if (parser.match(TokenType.CloseSquareBracket)) {
            break;
        }

        try values.append(try parseSpreadExpression(parser) orelse try parseAssignment(parser));
        const comma = parser.consumeOrNull(TokenType.Comma);

        if (parser.match(TokenType.CloseSquareBracket)) {
            break;
        } else if (comma == null) {
            return parser.fail(diagnostics.ARG_expected, .{","});
        }
    }

    return parser.addNode(parser.cur_token, AST.Node{
        .array_literal = values.items,
    });
}

pub fn parseObjectLiteral(parser: *Parser) ParserError!?AST.Node.Index {
    if (!parser.match(TokenType.OpenCurlyBrace)) {
        return null;
    }

    var nodes = std.ArrayList(AST.Node.Index).init(parser.gpa);
    defer nodes.deinit();

    while (!parser.match(TokenType.CloseCurlyBrace)) {
        const node = try parseObjectField(parser) orelse
            try parseSpreadExpression(parser) orelse
            return parser.fail(diagnostics.property_assignment_expected, .{});

        try nodes.append(node);

        if (parser.match(TokenType.CloseCurlyBrace)) {
            break;
        }

        _ = try parser.consume(TokenType.Comma, diagnostics.ARG_expected, .{","});
    }

    return parser.addNode(parser.cur_token, AST.Node{
        .object_literal = nodes.items,
    });
}

pub fn parseObjectField(parser: *Parser) ParserError!?AST.Node.Index {
    const method_node = try parseMethodGetter(parser) orelse
        try parseMethodSetter(parser) orelse
        try parseMethodGenerator(parser) orelse
        try parseMethodAsyncGenerator(parser) orelse
        try parseMethod(parser);

    if (method_node) |node| {
        return node;
    }

    const identifier = try parseObjectElementName(parser);

    if (identifier == null) {
        return null;
    }

    if (parser.match(TokenType.Colon)) {
        return parser.addNode(parser.cur_token, AST.Node{
            .object_literal_field = .{
                .left = identifier.?,
                .right = try parseAssignment(parser),
            },
        });
    } else if (parser.peekMatch(TokenType.Comma) or parser.peekMatch(TokenType.CloseCurlyBrace)) {
        return parser.addNode(parser.cur_token, AST.Node{
            .object_literal_field_shorthand = identifier.?,
        });
    }

    return null;
}

pub fn parseSpreadExpression(parser: *Parser) ParserError!?AST.Node.Index {
    if (!parser.match(TokenType.DotDotDot)) {
        return null;
    }

    return parser.addNode(parser.cur_token, AST.Node{
        .spread = try parseAssignment(parser),
    });
}

pub fn parseGroupingExpression(parser: *Parser) ParserError!?AST.Node.Index {
    if (parser.match(TokenType.OpenParen)) {
        const node = parser.addNode(parser.cur_token, AST.Node{
            .grouping = try parseExpression(parser),
        });

        _ = try parser.consume(TokenType.CloseParen, diagnostics.ARG_expected, .{")"});
        return node;
    }

    return null;
}

test "should parse primary expression" {
    const test_cases = .{
        .{
            "this",
            "^   ",
            AST.Node{ .simple_value = .{ .kind = .this } },
        },
        .{
            "identifier",
            "^         ",
            AST.Node{ .simple_value = .{ .kind = .identifier } },
        },
        .{
            "123",
            "^  ",
            AST.Node{ .simple_value = .{ .kind = .number } },
        },
        .{
            "{a: 1}",
            "^     ",
            AST.Node{ .object_literal = @constCast(&[_]AST.Node.Index{4}) },
        },
        .{
            "[1, 2]",
            "^     ",
            AST.Node{ .array_literal = @constCast(&[_]AST.Node.Index{ 9, 10 }) },
        },
        .{
            "function() {}",
            "^            ",
            AST.Node{ .function_decl = .{ .flags = AST.FunctionFlags.None, .name = 0, .params = &[_]AST.Node.Index{}, .body = 12, .return_type = 0 } },
        },
        .{
            "function*() {}",
            "^             ",
            AST.Node{ .function_decl = .{ .flags = AST.FunctionFlags.Generator, .name = 0, .params = &[_]AST.Node.Index{}, .body = 14, .return_type = 0 } },
        },
        .{
            "async function() {}",
            "^                  ",
            AST.Node{ .function_decl = .{ .flags = AST.FunctionFlags.Async, .name = 0, .params = &[_]AST.Node.Index{}, .body = 16, .return_type = 0 } },
        },
        .{
            "async function*() {}",
            "^                   ",
            AST.Node{ .function_decl = .{ .flags = AST.FunctionFlags.Async | AST.FunctionFlags.Generator, .name = 0, .params = &[_]AST.Node.Index{}, .body = 18, .return_type = 0 } },
        },
        .{
            "(a, b)",
            "^     ",
            AST.Node{ .grouping = 24 },
        },
        .{
            "class {}",
            "^       ",
            AST.Node{ .class = .{ .abstract = false, .name = 0, .implements = &.{}, .super_class = 0, .body = &.{} } },
        },
    };

    inline for (test_cases) |test_case| {
        var parser, const maybe_node = try Parser.once(test_case[0], parsePrimaryExpression);
        defer parser.deinit();

        try parser.expectAST(maybe_node, test_case[2]);
        try parser.expectTokenAt(test_case[1], maybe_node.?);
    }
}

test "should parse identifier" {
    const test_cases = .{
        .{
            "identifier",
            "^         ",
        },
        .{
            "$identifier",
            "^         ",
        },
        .{
            "_identifier",
            "^          ",
        },
        .{
            "\\u00FFidentifier",
            "^                ",
        },
        .{
            "\\u{FF}identifier",
            "^                ",
        },
    };

    inline for (test_cases) |test_case| {
        var parser, const maybe_node = try Parser.once(test_case[0], parseIdentifier);
        defer parser.deinit();

        try parser.expectAST(maybe_node, AST.Node{ .simple_value = .{ .kind = .identifier } });
        try parser.expectToken(TokenType.Identifier, test_case[0], maybe_node.?);
        try parser.expectTokenAt(test_case[1], maybe_node.?);
    }
}

test "should parse allowed keyword as identifier" {
    const text = .{
        "abstract",
        "^       ",
    };

    var parser, const maybe_node = try Parser.once(text[0], parseIdentifier);
    defer parser.deinit();

    try parser.expectAST(maybe_node, AST.Node{ .simple_value = .{ .kind = .identifier } });
    try parser.expectToken(TokenType.Abstract, "abstract", maybe_node.?);
    try parser.expectTokenAt(text[1], maybe_node.?);
}

test "should return null if no identifier" {
    const text =
        \\123
    ;

    var parser, const maybe_node = try Parser.once(text, parseIdentifier);
    defer parser.deinit();

    try parser.expectAST(maybe_node, null);
}

test "should return null if not allowed keyword" {
    const text =
        \\break
    ;

    var parser, const maybe_node = try Parser.once(text, parseIdentifier);
    defer parser.deinit();

    try parser.expectAST(maybe_node, null);
}

test "should parse literal" {
    const test_cases = .{
        .{
            "this",
            "^   ",
            AST.SimpleValueKind.this,
            TokenType.This,
            "this",
        },
        .{
            "null",
            "^   ",
            AST.SimpleValueKind.null,
            TokenType.Null,
            "null",
        },
        .{
            "undefined",
            "^   ",
            AST.SimpleValueKind.undefined,
            TokenType.Undefined,
            "undefined",
        },
        .{
            "true",
            "^   ",
            AST.SimpleValueKind.true,
            TokenType.True,
            "true",
        },
        .{
            "false",
            "^    ",
            AST.SimpleValueKind.false,
            TokenType.False,
            "false",
        },
        .{
            "123",
            "^  ",
            AST.SimpleValueKind.number,
            TokenType.NumberConstant,
            "123",
        },
        .{
            "123n",
            "^   ",
            AST.SimpleValueKind.bigint,
            TokenType.BigIntConstant,
            "123n",
        },
        .{
            "\"hello\"",
            "^        ",
            AST.SimpleValueKind.string,
            TokenType.StringConstant,
            "\"hello\"",
        },
    };

    inline for (test_cases) |test_case| {
        var parser, const maybe_node = try Parser.once(test_case[0], parseLiteral);
        defer parser.deinit();

        try parser.expectAST(maybe_node, AST.Node{ .simple_value = .{ .kind = test_case[2] } });
        try parser.expectToken(test_case[3], test_case[4], maybe_node.?);
        try parser.expectTokenAt(test_case[1], maybe_node.?);
    }
}

test "should return null if no literal" {
    const text =
        \\identifier
    ;

    var parser, const maybe_node = try Parser.once(text, parseLiteral);
    defer parser.deinit();

    try parser.expectAST(maybe_node, null);
}

test "should return null if not array literal" {
    const text =
        \\1
    ;

    var parser, const maybe_node = try Parser.once(text, parseArrayLiteral);
    defer parser.deinit();

    try parser.expectAST(maybe_node, null);
}

test "should parse array literal" {
    const expects_map = .{
        .{ "[,]", &[_]AST.Node.Index{0} },
        .{ "[, 1 + 2]", &[_]AST.Node.Index{ 0, 3 } },
        .{ "[1, 2, 3]", &[_]AST.Node.Index{ 1, 2, 3 } },
        .{ "[1, 2, 3,]", &[_]AST.Node.Index{ 1, 2, 3 } },
        .{ "[1, 2, 3 + 4,]", &[_]AST.Node.Index{ 1, 2, 5 } },
        .{ "[1,,,]", &[_]AST.Node.Index{ 1, 0, 0 } },
        .{ "[...a]", &[_]AST.Node.Index{3} },
        .{ "[1, ...a]", &[_]AST.Node.Index{ 1, 4 } },
    };

    inline for (expects_map) |expected_items| {
        var parser, const maybe_node = try Parser.once(expected_items[0], parseArrayLiteral);
        defer parser.deinit();

        try parser.expectAST(maybe_node, AST.Node{ .array_literal = @constCast(expected_items[1]) });
    }
}

test "should return null if not object literal" {
    const text =
        \\1
    ;

    var parser, const maybe_node = try Parser.once(text, parseObjectLiteral);
    defer parser.deinit();

    try parser.expectAST(maybe_node, null);
}

test "should parse object literal" {
    const text =
        \\{
        \\    a: 1,
        \\    b: 2,
        \\    c,
        \\    ...d,
        \\    [1 + 2]: e,
        \\}
    ;
    const expected_fields = &[_]AST.Node.Index{ 4, 8, 11, 14, 25 };

    var parser, const maybe_node = try Parser.once(text, parseObjectLiteral);
    defer parser.deinit();

    try parser.expectAST(maybe_node, AST.Node{ .object_literal = @constCast(expected_fields) });
}

test "should parse methods on object literal" {
    const text =
        \\{
        \\    a() {},
        \\    async b() {},
        \\    *c() {},
        \\    async *d() {},
        \\    get e() {},
        \\    set e(a) {},
        \\}
    ;

    var parser, const node = try Parser.once(text, parseObjectLiteral);
    defer parser.deinit();
    try expectEqualStrings("object_literal", @tagName(parser.getNode(node.?)));
    try expectEqual(6, parser.getNode(node.?).object_literal.len);

    const expected_methods = .{
        .{ AST.FunctionFlags.None, "a" },
        .{ AST.FunctionFlags.Async, "b" },
        .{ AST.FunctionFlags.Generator, "c" },
        .{ AST.FunctionFlags.Async | AST.FunctionFlags.Generator, "d" },
        .{ AST.FunctionFlags.Getter, "e" },
        .{ AST.FunctionFlags.Setter, "e" },
    };

    inline for (expected_methods, 0..) |expected_method, i| {
        try parser.expectSimpleMethod(parser.getNode(node.?).object_literal[i], expected_method[0], expected_method[1]);
    }
}

test "should fail parsing object literal if comma is missing between fields" {
    const text =
        \\{
        \\    a: 1,
        \\    b: 2
        \\    c,
        \\}
    ;

    var parser, const nodeOrError = try Parser.onceAny(text, parseObjectLiteral);
    defer parser.deinit();

    try parser.expectSyntaxError(nodeOrError, diagnostics.ARG_expected, .{","});
}

test "should fail parsing object literal if field name is invalid" {
    const test_cases = .{ "{ - }", "{ a - b }" };

    inline for (test_cases) |test_case| {
        var parser, const nodeOrError = try Parser.onceAny(test_case, parseObjectLiteral);
        defer parser.deinit();

        try parser.expectSyntaxError(nodeOrError, diagnostics.property_assignment_expected, .{});
    }
}

test "should fail parsing object literal if there is multiple closing commas" {
    const text =
        \\{
        \\    a: 1,,
        \\}
    ;

    var parser, const nodeOrError = try Parser.onceAny(text, parseObjectLiteral);
    defer parser.deinit();

    try parser.expectSyntaxError(nodeOrError, diagnostics.property_assignment_expected, .{});
}

test "should parse grouping expression" {
    const text = "(a, b)";

    var parser, const maybe_node = try Parser.once(text, parseGroupingExpression);
    defer parser.deinit();

    try parser.expectAST(maybe_node, AST.Node{ .grouping = 5 });
}

test "should return null if no grouping expression" {
    const text =
        \\1
    ;

    var parser, const maybe_node = try Parser.once(text, parseGroupingExpression);
    defer parser.deinit();

    try parser.expectAST(maybe_node, null);
}
