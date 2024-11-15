const std = @import("std");

const Token = @import("../consts.zig").Token;
const TokenType = @import("../consts.zig").TokenType;
const isAllowedIdentifier = @import("../consts.zig").isAllowedIdentifier;

const AST = @import("../ast.zig");
const Parser = @import("../parser.zig");
const diagnostics = @import("../diagnostics.zig");

const ParserError = Parser.ParserError;

const expectEqual = std.testing.expectEqual;
const expectEqualDeep = std.testing.expectEqualDeep;
const expectEqualStrings = std.testing.expectEqualStrings;
const expectError = std.testing.expectError;
const expectAST = Parser.expectAST;
const expectASTAndToken = Parser.expectASTAndToken;
const expectSyntaxError = Parser.expectSyntaxError;

pub fn parsePrimaryExpression(parser: *Parser) ParserError!?AST.Node.Index {
    return try parseIdentifier(parser) orelse
        try parseLiteral(parser) orelse
        try parseArrayLiteral(parser) orelse
        try parseObjectLiteral(parser) orelse
        try parser.parseFunctionStatement(AST.FunctionFlags.None) orelse
        try parser.parseAsyncFunctionStatement() orelse
        // try self.parseClassExpression() orelse
        // try self.parseGeneratorExpression() orelse
        try parseGroupingExpression(parser);
}

pub fn parseIdentifier(parser: *Parser) ParserError!?AST.Node.Index {
    if (parser.match(TokenType.Identifier) or try parseKeywordAsIdentifier(parser) != null) {
        return try parser.pool.addNode(parser.cur_token - 1, AST.Node{ .simple_value = .{ .kind = .identifier } });
    }

    return null;
}

pub fn parseKeywordAsIdentifier(parser: *Parser) ParserError!?Token.Index {
    if (parser.peekMatchMany(.{ TokenType.Async, TokenType.Function })) {
        return null;
    }

    if (isAllowedIdentifier(parser.token().type)) {
        return parser.advance();
    }
    return null;
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
            return try parser.pool.addNode(parser.cur_token - 1, AST.Node{ .simple_value = .{ .kind = literal[1] } });
        }
    }

    return null;
}

pub fn parseArrayLiteral(parser: *Parser) ParserError!?AST.Node.Index {
    if (!parser.match(TokenType.OpenSquareBracket)) {
        return null;
    }

    var values = std.ArrayList(AST.Node.Index).init(parser.arena.allocator());
    defer values.deinit();

    while (true) {
        while (parser.match(TokenType.Comma)) {
            try values.append(AST.Node.Empty);
        }

        if (parser.match(TokenType.CloseSquareBracket)) {
            break;
        }

        try values.append(try parser.parseAssignment());
        const comma = parser.consumeOrNull(TokenType.Comma);

        if (parser.match(TokenType.CloseSquareBracket)) {
            break;
        } else if (comma == null) {
            return parser.fail(diagnostics.ARG_expected, .{","});
        }
    }

    return try parser.pool.addNode(parser.cur_token, AST.Node{
        .array_literal = values.items,
    });
}

pub fn parseObjectLiteral(parser: *Parser) ParserError!?AST.Node.Index {
    if (!parser.match(TokenType.OpenCurlyBrace)) {
        return null;
    }

    var nodes = std.ArrayList(AST.Node.Index).init(parser.arena.allocator());
    defer nodes.deinit();

    var seen_comma = true;
    while (!parser.match(TokenType.CloseCurlyBrace)) {
        if (!seen_comma) {
            return parser.fail(diagnostics.ARG_expected, .{","});
        }

        const node = try parseObjectField(parser);

        if (seen_comma and node == null) {
            return parser.fail(diagnostics.expression_expected, .{});
        }

        try nodes.append(node.?);
        seen_comma = parser.consumeOrNull(TokenType.Comma) != null;
    }

    return try parser.pool.addNode(parser.cur_token, AST.Node{
        .object_literal = try nodes.toOwnedSlice(),
    });
}

pub fn parseObjectField(parser: *Parser) ParserError!?AST.Node.Index {
    const method_node = try parser.parseMethodGetter() orelse
        try parser.parseMethodSetter() orelse
        try parser.parseMethodGenerator(AST.FunctionFlags.None) orelse
        try parser.parseMethodAsyncGenerator() orelse
        try parser.parseMethod(AST.FunctionFlags.None);
    if (method_node) |node| {
        return node;
    }

    const identifier = try parser.parseObjectElementName();

    if (identifier == null) {
        return null;
    }

    if (parser.match(TokenType.Colon)) {
        return try parser.pool.addNode(parser.cur_token, AST.Node{
            .object_literal_field = .{
                .left = identifier.?,
                .right = try parser.parseAssignment(),
            },
        });
    } else if (parser.peekMatch(TokenType.Comma) or parser.peekMatch(TokenType.CloseCurlyBrace)) {
        _ = parser.advance();
        return try parser.pool.addNode(parser.cur_token, AST.Node{
            .object_literal_field_shorthand = identifier.?,
        });
    }

    return null;
}

pub fn parseGroupingExpression(parser: *Parser) ParserError!?AST.Node.Index {
    if (parser.match(TokenType.OpenParen)) {
        const node = try parser.pool.addNode(parser.cur_token, AST.Node{
            .grouping = try parser.parseExpression(),
        });

        _ = try parser.consume(TokenType.CloseParen, diagnostics.ARG_expected, .{")"});
        return node;
    }

    return null;
}

test "should parse primary expression" {
    const text =
        \\this
        \\identifier
        \\123
        \\{a: 1}
        \\[1, 2]
        \\function() {}
        \\function*() {}
        \\async function() {}
        \\async function*() {}
        \\(a, b)
    ;
    var parser = try Parser.init(std.testing.allocator, text);
    defer parser.deinit();

    const expected_nodes = .{
        AST.Node{ .simple_value = .{ .kind = .this } },
        AST.Node{ .simple_value = .{ .kind = .identifier } },
        AST.Node{ .simple_value = .{ .kind = .number } },
        AST.Node{ .object_literal = @constCast(&[_]AST.Node.Index{7}) },
        AST.Node{ .array_literal = @constCast(&[_]AST.Node.Index{ 9, 10 }) },
        AST.Node{ .function_decl = .{ .flags = AST.FunctionFlags.None, .name = 0, .params = &[_]AST.Node.Index{}, .body = 12, .return_type = 0 } },
        AST.Node{ .function_decl = .{ .flags = AST.FunctionFlags.Generator, .name = 0, .params = &[_]AST.Node.Index{}, .body = 14, .return_type = 0 } },
        AST.Node{ .function_decl = .{ .flags = AST.FunctionFlags.Async, .name = 0, .params = &[_]AST.Node.Index{}, .body = 16, .return_type = 0 } },
        AST.Node{ .function_decl = .{ .flags = AST.FunctionFlags.Async | AST.FunctionFlags.Generator, .name = 0, .params = &[_]AST.Node.Index{}, .body = 18, .return_type = 0 } },
        AST.Node{ .grouping = 24 },
    };

    inline for (expected_nodes) |expected_node| {
        const node = try parsePrimaryExpression(&parser);
        try expectEqualDeep(expected_node, parser.pool.getNode(node.?));
    }
}

test "should parse identifier" {
    const text =
        \\identifier
    ;

    try expectASTAndToken(parseIdentifier, AST.Node{ .simple_value = .{ .kind = .identifier } }, TokenType.Identifier, "identifier", text);
}

test "should return null if no identifier" {
    const text =
        \\123
    ;

    try expectAST(parseIdentifier, null, text);
}

test "should parse literal" {
    const test_cases = .{
        .{ "this", AST.SimpleValueKind.this, TokenType.This, null },
        .{ "null", AST.SimpleValueKind.null, TokenType.Null, null },
        .{ "undefined", AST.SimpleValueKind.undefined, TokenType.Undefined, null },
        .{ "true", AST.SimpleValueKind.true, TokenType.True, null },
        .{ "false", AST.SimpleValueKind.false, TokenType.False, null },
        .{ "123", AST.SimpleValueKind.number, TokenType.NumberConstant, "123" },
        .{ "123n", AST.SimpleValueKind.bigint, TokenType.BigIntConstant, "123n" },
        .{ "\"hello\"", AST.SimpleValueKind.string, TokenType.StringConstant, "\"hello\"" },
    };

    inline for (test_cases) |test_case| {
        try expectASTAndToken(parseLiteral, AST.Node{ .simple_value = .{ .kind = test_case[1] } }, test_case[2], test_case[3], test_case[0]);
    }
}

test "should return null if no literal" {
    const text =
        \\identifier
    ;

    try expectAST(parseLiteral, null, text);
}

test "should return null if not array literal" {
    const text =
        \\1
    ;

    try expectAST(parseArrayLiteral, null, text);
}

test "should parse array literal" {
    const expects_map = .{
        .{ "[1, 2, 3]", &[_]AST.Node.Index{ 1, 2, 3 } },
        .{ "[1, 2, 3,]", &[_]AST.Node.Index{ 1, 2, 3 } },
        .{ "[1,,,]", &[_]AST.Node.Index{ 1, 0, 0 } },
    };

    inline for (expects_map) |expected_items| {
        try expectAST(parseArrayLiteral, AST.Node{ .array_literal = @constCast(expected_items[1]) }, expected_items[0]);
    }
}

test "should return null if not object literal" {
    const text =
        \\1
    ;

    try expectAST(parseObjectLiteral, null, text);
}

test "should parse object literal" {
    const text =
        \\{
        \\    a: 1,
        \\    b: 2,
        \\    c,
        \\}
    ;
    const expected_fields = &[_]AST.Node.Index{ 4, 8, 11 };

    try expectAST(parseObjectLiteral, AST.Node{ .object_literal = @constCast(expected_fields) }, text);
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
    var parser = try Parser.init(std.testing.allocator, text);
    defer parser.deinit();

    const node = try parseObjectLiteral(&parser);
    try expectEqualStrings("object_literal", @tagName(parser.pool.getNode(node.?)));
    try expectEqual(6, parser.pool.getNode(node.?).object_literal.len);

    const expected_methods = .{
        .{ AST.FunctionFlags.None, "a" },
        .{ AST.FunctionFlags.Async, "b" },
        .{ AST.FunctionFlags.Generator, "c" },
        .{ AST.FunctionFlags.Async | AST.FunctionFlags.Generator, "d" },
        .{ AST.FunctionFlags.Getter, "e" },
        .{ AST.FunctionFlags.Setter, "e" },
    };

    inline for (expected_methods, 0..) |expected_method, i| {
        try parser.expectSimpleMethod(parser.pool.getNode(node.?).object_literal[i], expected_method[0], expected_method[1]);
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

    try expectSyntaxError(parseObjectLiteral, text, diagnostics.ARG_expected, .{","});
}

test "should fail parsing object literal if there is multiple closing commas" {
    const text =
        \\{
        \\    a: 1,,
        \\}
    ;

    try expectSyntaxError(parseObjectLiteral, text, diagnostics.expression_expected, .{});
}

test "should parse grouping expression" {
    const text =
        \\(a, b)
    ;

    try expectAST(parseGroupingExpression, AST.Node{ .grouping = 5 }, text);
}

test "should return null if no grouping expression" {
    const text =
        \\1
    ;

    try expectAST(parseGroupingExpression, null, text);
}
