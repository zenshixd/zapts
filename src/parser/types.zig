const std = @import("std");
const Parser = @import("../parser.zig");
const AST = @import("../ast.zig");
const Token = @import("../consts.zig").Token;
const TokenType = @import("../consts.zig").TokenType;
const ParserError = Parser.ParserError;
const diagnostics = @import("../diagnostics.zig");

const parseIdentifier = @import("primary.zig").parseIdentifier;
const parseKeywordAsIdentifier = @import("primary.zig").parseKeywordAsIdentifier;

const expectEqual = std.testing.expectEqual;
const expectAST = Parser.expectAST;
const expectMaybeAST = Parser.expectMaybeAST;
const expectSyntaxError = Parser.expectSyntaxError;

pub fn parseOptionalDataType(self: *Parser) ParserError!AST.Node.Index {
    if (self.match(TokenType.Colon)) {
        return try parseSymbolType(self);
    }

    return AST.Node.Empty;
}

pub fn parseSymbolType(self: *Parser) ParserError!AST.Node.Index {
    return try parseSymbolUnionType(self) orelse
        return self.fail(diagnostics.type_expected, .{});
}

fn parseSymbolUnionType(self: *Parser) ParserError!?AST.Node.Index {
    var node = try parseSymbolIntersectionType(self) orelse return null;

    if (self.match(TokenType.Bar)) {
        const new_node = self.pool.addNode(self.cur_token, AST.Node{
            .type_union = .{
                .left = node,
                .right = try parseSymbolUnionType(self) orelse return self.fail(diagnostics.type_expected, .{}),
            },
        });

        node = new_node;
    }

    return node;
}

fn parseSymbolIntersectionType(self: *Parser) ParserError!?AST.Node.Index {
    var node = try parseSymbolTypeUnary(self) orelse return null;

    if (self.match(TokenType.Ampersand)) {
        const new_node = self.pool.addNode(self.cur_token, AST.Node{
            .type_intersection = .{
                .left = node,
                .right = try parseSymbolIntersectionType(self) orelse return self.fail(diagnostics.type_expected, .{}),
            },
        });

        node = new_node;
    }

    return node;
}

fn parseSymbolTypeUnary(self: *Parser) ParserError!?AST.Node.Index {
    if (self.match(TokenType.Typeof)) {
        return self.pool.addNode(self.cur_token, AST.Node{
            .typeof = try parseSymbolType(self),
        });
    } else if (self.match(TokenType.Keyof)) {
        return self.pool.addNode(self.cur_token, AST.Node{
            .keyof = try parseSymbolType(self),
        });
    }

    return try parseSymbolArrayType(self);
}

fn parseSymbolArrayType(self: *Parser) ParserError!?AST.Node.Index {
    const node = try parsePrimarySymbolType(self) orelse return null;

    if (self.match(TokenType.OpenSquareBracket)) {
        if (self.match(TokenType.CloseSquareBracket)) {
            return self.pool.addNode(self.cur_token, AST.Node{ .array_type = node });
        }
        return self.fail(diagnostics.unexpected_token, .{});
    }

    return node;
}

fn parsePrimarySymbolType(self: *Parser) ParserError!?AST.Node.Index {
    return try parseObjectType(self) orelse
        try parseTupleType(self) orelse
        try parsePrimitiveType(self) orelse
        try parseGenericType(self);
}

fn parseObjectType(self: *Parser) ParserError!?AST.Node.Index {
    if (!self.match(TokenType.OpenCurlyBrace)) {
        return null;
    }

    var list = std.ArrayList(AST.Node.Index).init(self.gpa);
    defer list.deinit();

    while (!self.match(TokenType.CloseCurlyBrace)) {
        const record = try parseObjectMethodType(self) orelse
            try parseObjectPropertyType(self) orelse
            return self.fail(diagnostics.identifier_expected, .{});
        try list.append(record);

        if (self.match(TokenType.CloseCurlyBrace)) {
            break;
        }

        _ = self.consumeOrNull(TokenType.Comma) orelse self.consumeOrNull(TokenType.Semicolon) orelse return self.fail(diagnostics.ARG_expected, .{","});
    }

    return self.pool.addNode(self.cur_token, AST.Node{ .object_type = list.items });
}

fn parseObjectPropertyType(self: *Parser) ParserError!?AST.Node.Index {
    const identifier = self.consumeOrNull(TokenType.Identifier) orelse return null;

    var right: AST.Node.Index = AST.Node.Empty;

    if (self.match(TokenType.Colon)) {
        right = try parseSymbolType(self);
    }

    return self.pool.addNode(self.cur_token, AST.Node{
        .object_type_field = .{
            .name = identifier,
            .type = right,
        },
    });
}

fn parseObjectMethodType(self: *Parser) ParserError!?AST.Node.Index {
    const cp = self.cur_token;
    const identifier = try parseIdentifier(self) orelse {
        self.cur_token = cp;
        return null;
    };

    const generics = if (self.match(TokenType.LessThan)) try parseGenericParams(self) else null;
    defer {
        if (generics != null) {
            generics.?.deinit();
        }
    }

    if (!self.match(TokenType.OpenParen)) {
        self.cur_token = cp;
        return null;
    }
    const list = try parseFunctionArgumentsType(self);
    defer list.deinit();

    const return_type = try parseOptionalDataType(self);

    return self.pool.addNode(self.cur_token, AST.Node{ .function_type = .{
        .name = identifier,
        .generic_params = if (generics) |g| g.items else &[_]AST.Node.Index{},
        .params = list.items,
        .return_type = return_type,
    } });
}

fn parseFunctionArgumentsType(self: *Parser) ParserError!std.ArrayList(AST.Node.Index) {
    var args = std.ArrayList(AST.Node.Index).init(self.gpa);
    errdefer args.deinit();

    while (!self.match(TokenType.CloseParen)) {
        const identifier = try self.consume(TokenType.Identifier, diagnostics.identifier_expected, .{});
        const arg_type = try parseOptionalDataType(self);
        try args.append(self.pool.addNode(identifier, AST.Node{ .function_param = .{
            .node = identifier,
            .type = arg_type,
        } }));

        if (self.match(TokenType.CloseParen)) {
            break;
        }

        _ = try self.consume(TokenType.Comma, diagnostics.ARG_expected, .{","});
    }

    return args;
}

fn parseTupleType(self: *Parser) ParserError!?AST.Node.Index {
    if (!self.match(TokenType.OpenSquareBracket)) {
        return null;
    }

    var list = std.ArrayList(AST.Node.Index).init(self.gpa);
    defer list.deinit();

    while (!self.match(TokenType.CloseSquareBracket)) {
        const node = try parseSymbolType(self);
        try list.append(node);

        if (self.match(TokenType.CloseSquareBracket)) {
            break;
        }

        _ = try self.consume(TokenType.Comma, diagnostics.ARG_expected, .{","});
    }

    return self.pool.addNode(self.cur_token, AST.Node{ .tuple_type = list.items });
}

const primitive_types = .{
    .{ TokenType.NumberConstant, .number },
    .{ TokenType.BigIntConstant, .bigint },
    .{ TokenType.StringConstant, .string },
    .{ TokenType.True, .true },
    .{ TokenType.False, .false },
    .{ TokenType.Null, .null },
    .{ TokenType.Undefined, .undefined },
    .{ TokenType.Void, .void },
    .{ TokenType.Any, .any },
    .{ TokenType.Unknown, .unknown },
};

fn parsePrimitiveType(self: *Parser) ParserError!?AST.Node.Index {
    inline for (primitive_types) |primitive_type| {
        if (self.match(primitive_type[0])) {
            return self.pool.addNode(self.cur_token - 1, AST.Node{ .simple_type = .{ .kind = primitive_type[1] } });
        }
    }

    return null;
}
fn parseGenericType(self: *Parser) ParserError!?AST.Node.Index {
    var node = parseTypeIdentifier(self) orelse return null;

    if (self.match(TokenType.LessThan)) {
        var params = try parseGenericParams(self);
        defer params.deinit();

        node = self.pool.addNode(self.cur_token, AST.Node{ .generic_type = .{
            .name = node,
            .params = params.items,
        } });
    }

    return node;
}

fn parseGenericParams(self: *Parser) ParserError!std.ArrayList(AST.Node.Index) {
    var params = std.ArrayList(AST.Node.Index).init(self.gpa);
    errdefer params.deinit();

    while (!self.match(TokenType.GreaterThan)) {
        try params.append(try parseSymbolType(self));

        if (self.match(TokenType.GreaterThan)) {
            break;
        }

        _ = try self.consume(TokenType.Comma, diagnostics.ARG_expected, .{","});
    }

    return params;
}

fn parseTypeIdentifier(self: *Parser) ?AST.Node.Index {
    const identifier = self.consumeOrNull(TokenType.Identifier) orelse return null;

    const type_map = .{
        .{ "number", .number },
        .{ "bigint", .bigint },
        .{ "string", .string },
        .{ "boolean", .boolean },
    };

    const value = self.tokens[identifier].literal(self.buffer);
    inline for (type_map) |type_item| {
        if (std.mem.eql(u8, type_item[0], value)) {
            return self.pool.addNode(identifier, AST.Node{ .simple_type = .{ .kind = type_item[1] } });
        }
    }

    return self.pool.addNode(identifier, AST.Node{ .simple_type = .{ .kind = .identifier } });
}

fn parseTypeDeclaration(self: *Parser) ParserError!?AST.Node.Index {
    if (!self.match(TokenType.Type)) {
        return null;
    }

    const identifier = self.consumeOrNull(TokenType.Identifier) orelse
        try parseKeywordAsIdentifier(self) orelse
        return self.fail(diagnostics.identifier_expected, .{});

    _ = try self.consume(TokenType.Equal, diagnostics.ARG_expected, .{"="});

    const identifier_data_type = try parseSymbolType(self);

    return self.pool.addNode(self.cur_token, AST.Node{ .type_decl = .{
        .left = identifier,
        .right = identifier_data_type,
    } });
}

fn parseInterfaceDeclaration(self: *Parser) ParserError!?AST.Node.Index {
    if (!self.match(TokenType.Interface)) {
        return null;
    }

    const identifier = self.consumeOrNull(TokenType.Identifier) orelse try parseKeywordAsIdentifier(self) orelse return self.fail(diagnostics.identifier_expected, .{});
    _ = try self.consume(TokenType.OpenCurlyBrace, diagnostics.ARG_expected, .{"{"});

    var list = std.ArrayList(AST.Node.Index).init(self.gpa);
    defer list.deinit();

    var has_comma = true;
    while (true) {
        if (self.match(TokenType.CloseCurlyBrace)) {
            break;
        }
        if (!has_comma) {
            try self.emitError(diagnostics.ARG_expected, .{";"});
        }
        const node = try parseObjectMethodType(self) orelse
            try parseObjectPropertyType(self) orelse
            return self.fail(diagnostics.property_or_signature_expected, .{});

        try list.append(node);
        has_comma = self.match(TokenType.Comma) or self.match(TokenType.Semicolon);
    }
    return self.pool.addNode(self.cur_token, AST.Node{ .interface_decl = .{
        .name = identifier,
        .extends = &[_]AST.Node.Index{},
        .body = list.items,
    } });
}

test "should parse optional data type" {
    const text = ": number";

    try expectAST(parseOptionalDataType, AST.Node{ .simple_type = .{ .kind = .number } }, text);
}

test "should return Empty node if no data type" {
    const text = "ident";
    var parser = try Parser.init(std.testing.allocator, text);
    defer parser.deinit();

    const node = try parseOptionalDataType(&parser);

    try expectEqual(AST.Node.Empty, node);
}

test "should parse primary symbol type" {
    const tests = .{
        .{ "number", AST.Node{ .simple_type = .{ .kind = .number } } },
        .{ "bigint", AST.Node{ .simple_type = .{ .kind = .bigint } } },
        .{ "string", AST.Node{ .simple_type = .{ .kind = .string } } },
        .{ "boolean", AST.Node{ .simple_type = .{ .kind = .boolean } } },
        .{ "null", AST.Node{ .simple_type = .{ .kind = .null } } },
        .{ "undefined", AST.Node{ .simple_type = .{ .kind = .undefined } } },
        .{ "void", AST.Node{ .simple_type = .{ .kind = .void } } },
        .{ "any", AST.Node{ .simple_type = .{ .kind = .any } } },
        .{ "unknown", AST.Node{ .simple_type = .{ .kind = .unknown } } },
    };

    inline for (tests) |test_case| {
        const text = test_case[0];
        try expectAST(parseSymbolType, test_case[1], text);
    }
}

test "should return syntax error if its not a symbol type" {
    const text = "+";

    try expectSyntaxError(parseSymbolType, text, diagnostics.type_expected, .{});
}

test "should parse unary type operators" {
    const tests = .{
        .{ "keyof Array", AST.Node{ .keyof = 1 } },
        .{ "typeof Array", AST.Node{ .typeof = 1 } },
    };

    inline for (tests) |test_case| {
        const text = test_case[0];
        try expectAST(parseSymbolType, test_case[1], text);
    }
}

test "should parse generic type" {
    const text = "Array<number>";

    try expectAST(parseSymbolType, AST.Node{ .generic_type = .{
        .name = 1,
        .params = @constCast(&[_]AST.Node.Index{2}),
    } }, text);
}

test "should parse generic type with multiple params" {
    const text = "Array<number, string>";

    try expectAST(parseSymbolType, AST.Node{ .generic_type = .{
        .name = 1,
        .params = @constCast(&[_]AST.Node.Index{ 2, 3 }),
    } }, text);
}

// TODO: one day i will fix this case, too much trouble for now
//test "should parse nested generic type" {
//    const text = "Array<Array<number>>";
//
//    try expectAST(parseSymbolType, AST.Node{ .generic_type = .{
//        .name = 1,
//        .params = @constCast(&[_]AST.Node.Index{4}),
//    } }, text);
//}

test "should parse array type" {
    const text = "number[]";

    try expectAST(parseSymbolType, AST.Node{ .array_type = 1 }, text);
}

test "should parse tuple type" {
    const text = "[number, string]";

    try expectAST(parseSymbolType, AST.Node{ .tuple_type = @constCast(&[_]AST.Node.Index{ 1, 2 }) }, text);
}

test "should parse object type" {
    const texts = .{
        "{ a: number, b: string }",
        "{ a: number; b: string }",
    };

    inline for (texts) |text| {
        var parser = try Parser.init(std.testing.allocator, text);
        defer parser.deinit();

        _ = try parseObjectType(&parser);

        try parser.expectNodesToEqual(&[_]AST.Raw{
            .{ .tag = .simple_value, .main_token = 1, .data = .{ .lhs = 1, .rhs = 0 } },
            .{ .tag = .simple_type, .main_token = 3, .data = .{ .lhs = 3, .rhs = 0 } },
            .{ .tag = .object_type_field, .main_token = 4, .data = .{ .lhs = 1, .rhs = 2 } },
            .{ .tag = .simple_value, .main_token = 5, .data = .{ .lhs = 1, .rhs = 0 } },
            .{ .tag = .simple_type, .main_token = 7, .data = .{ .lhs = 5, .rhs = 0 } },
            .{ .tag = .object_type_field, .main_token = 8, .data = .{ .lhs = 5, .rhs = 5 } },
            .{ .tag = .object_type, .main_token = 9, .data = .{ .lhs = 0, .rhs = 2 } },
        });
    }
}

test "should parse method type" {
    const texts = .{
        "fn(a: number, b: string): boolean",
        "fn(a: number, b: string,): boolean",
    };

    inline for (texts) |text| {
        try expectMaybeAST(parseObjectMethodType, AST.Node{ .function_type = .{
            .name = 1,
            .generic_params = &[_]AST.Node.Index{},
            .params = @constCast(&[_]AST.Node.Index{ 3, 5 }),
            .return_type = 6,
        } }, text);
    }
}

test "should parse method with generics" {
    const texts = .{
        "fn<T>(a: T, b: T): boolean",
        "fn<T,>(a: T, b: T): boolean",
    };

    inline for (texts) |text| {
        try expectMaybeAST(parseObjectMethodType, AST.Node{ .function_type = .{
            .name = 1,
            .generic_params = @constCast(&[_]AST.Node.Index{2}),
            .params = @constCast(&[_]AST.Node.Index{ 4, 6 }),
            .return_type = 7,
        } }, text);
    }
}

test "should return syntax error if there is no comma between generic params" {
    const text = "fn<T B>(a: T): boolean";

    try expectSyntaxError(parseObjectMethodType, text, diagnostics.ARG_expected, .{","});
}

test "should parse method type with types" {
    const text = "fn(a, b)";

    try expectMaybeAST(parseObjectMethodType, AST.Node{ .function_type = .{
        .name = 1,
        .generic_params = &[_]AST.Node.Index{},
        .params = @constCast(&[_]AST.Node.Index{ 2, 3 }),
        .return_type = 0,
    } }, text);
}

test "should return null if its not method type" {
    const text = "[number, string]";

    try expectMaybeAST(parseObjectMethodType, null, text);
}

test "should return syntax error if there is no comma after params" {
    const text = "fn(a: number b: string): boolean";

    try expectSyntaxError(parseObjectMethodType, text, diagnostics.ARG_expected, .{","});
}

test "should return syntax error if param is not identifier" {
    const text = "fn(void): boolean";

    try expectSyntaxError(parseObjectMethodType, text, diagnostics.identifier_expected, .{});
}

test "should parse type identifier" {
    const text = "Array";

    try expectAST(parseSymbolType, AST.Node{ .simple_type = .{ .kind = .identifier } }, text);
}

test "should parse type union" {
    const text = "number | string";

    try expectAST(parseSymbolType, AST.Node{ .type_union = .{
        .left = 1,
        .right = 2,
    } }, text);
}

test "should parse type intersection" {
    const text = "number & string";

    try expectAST(parseSymbolType, AST.Node{ .type_intersection = .{
        .left = 1,
        .right = 2,
    } }, text);
}
