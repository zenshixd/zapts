const std = @import("std");
const Parser = @import("../parser.zig");
const AST = @import("../ast.zig");
const Token = @import("../consts.zig").Token;
const TokenType = @import("../consts.zig").TokenType;
const ParserError = Parser.ParserError;
const diagnostics = @import("../diagnostics.zig");

const parseIdentifier = @import("primary.zig").parseIdentifier;
const parseKeywordAsIdentifier = @import("primary.zig").parseKeywordAsIdentifier;

const Marker = @import("../test_parser.zig").Marker;
const MarkerList = @import("../test_parser.zig").MarkerList;
const TestParser = @import("../test_parser.zig");

const expectEqual = std.testing.expectEqual;

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
        const new_node = self.addNode(self.cur_token, AST.Node{
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
        const new_node = self.addNode(self.cur_token, AST.Node{
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
        return self.addNode(self.cur_token, AST.Node{
            .typeof = try parseSymbolType(self),
        });
    } else if (self.match(TokenType.Keyof)) {
        return self.addNode(self.cur_token, AST.Node{
            .keyof = try parseSymbolType(self),
        });
    }

    return try parseSymbolArrayType(self);
}

fn parseSymbolArrayType(self: *Parser) ParserError!?AST.Node.Index {
    const node = try parsePrimarySymbolType(self) orelse return null;

    if (self.match(TokenType.OpenSquareBracket)) {
        if (self.match(TokenType.CloseSquareBracket)) {
            return self.addNode(self.cur_token, AST.Node{ .array_type = node });
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

    return self.addNode(self.cur_token, AST.Node{ .object_type = list.items });
}

fn parseObjectPropertyType(self: *Parser) ParserError!?AST.Node.Index {
    const identifier = try parseIdentifier(self) orelse return null;

    var right: AST.Node.Index = AST.Node.Empty;

    if (self.match(TokenType.Colon)) {
        right = try parseSymbolType(self);
    }

    return self.addNode(self.cur_token, AST.Node{
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

    const start_token = self.consumeOrNull(TokenType.OpenParen) orelse {
        self.cur_token = cp;
        return null;
    };

    const list = try parseFunctionArgumentsType(self);
    defer list.deinit();

    const return_type = try parseOptionalDataType(self);
    const fn_type = self.addNode(start_token, AST.Node{ .function_type = .{
        .generic_params = if (generics) |g| g.items else &.{},
        .params = list.items,
        .return_type = return_type,
    } });

    return self.addNode(cp, AST.Node{
        .object_type_field = .{
            .name = identifier,
            .type = fn_type,
        },
    });
}

fn parseFunctionType(self: *Parser) ParserError!?AST.Node.Index {
    const cur_token = self.cur_token;
    const generics = if (self.match(TokenType.LessThan)) try parseGenericParams(self) else null;
    defer {
        if (generics) |g| {
            g.deinit();
        }
    }

    const start_token = self.consumeOrNull(TokenType.OpenParen) orelse {
        self.cur_token = cur_token;
        return null;
    };

    var params = try parseFunctionArgumentsType(self);
    defer params.deinit();

    _ = try self.consume(TokenType.Arrow, diagnostics.ARG_expected, .{"=>"});

    const return_type = try parseSymbolType(self);

    return self.addNode(start_token, AST.Node{ .function_type = .{
        .generic_params = if (generics) |g| g.items else &.{},
        .params = params.items,
        .return_type = return_type,
    } });
}

fn parseFunctionArgumentsType(self: *Parser) ParserError!std.ArrayList(AST.Node.Index) {
    var args = std.ArrayList(AST.Node.Index).init(self.gpa);
    errdefer args.deinit();

    while (!self.match(TokenType.CloseParen)) {
        const identifier = try self.consume(TokenType.Identifier, diagnostics.identifier_expected, .{});
        const arg_type = try parseOptionalDataType(self);
        try args.append(self.addNode(identifier, AST.Node{ .function_param = .{
            .identifier = identifier,
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

    return self.addNode(self.cur_token, AST.Node{ .tuple_type = list.items });
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
            return self.addNode(self.cur_token.dec(1), AST.Node{ .simple_type = .{ .kind = primitive_type[1] } });
        }
    }

    return null;
}
fn parseGenericType(self: *Parser) ParserError!?AST.Node.Index {
    const identifier = self.consumeOrNull(TokenType.Identifier) orelse return null;

    if (self.match(TokenType.LessThan)) {
        var params = try parseGenericParams(self);
        defer params.deinit();

        return self.addNode(identifier, AST.Node{ .generic_type = .{
            .name = identifier,
            .params = params.items,
        } });
    }

    return parseTypeIdentifier(self, identifier);
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

fn parseTypeIdentifier(self: *Parser, identifier: Token.Index) ?AST.Node.Index {
    const type_map = .{
        .{ "number", .number },
        .{ "bigint", .bigint },
        .{ "string", .string },
        .{ "boolean", .boolean },
    };

    const value = self.tokens[identifier.int()].literal(self.buffer);
    inline for (type_map) |type_item| {
        if (std.mem.eql(u8, type_item[0], value)) {
            return self.addNode(identifier, AST.Node{ .simple_type = .{ .kind = type_item[1] } });
        }
    }

    return self.addNode(identifier, AST.Node{ .simple_type = .{ .kind = .identifier } });
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

    return self.addNode(self.cur_token, AST.Node{ .type_decl = .{
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
    return self.addNode(self.cur_token, AST.Node{ .interface_decl = .{
        .name = identifier,
        .extends = &.{},
        .body = list.items,
    } });
}

test "should parse optional data type" {
    const text = ": number";

    try TestParser.run(text, parseOptionalDataType, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectAST(node, AST.Node{ .simple_type = .{ .kind = .number } });
        }
    });
}

test "should return Empty node if no data type" {
    const text = "ident";

    try TestParser.run(text, parseOptionalDataType, struct {
        pub fn expect(_: TestParser, node: ?AST.Node.Index, _: MarkerList(text)) !void {
            try expectEqual(AST.Node.Empty, node);
        }
    });
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
        try TestParser.run(test_case[0], parseSymbolType, struct {
            pub fn expect(t: TestParser, node: ?AST.Node.Index, _: MarkerList(test_case[0])) !void {
                try t.expectAST(node, test_case[1]);
            }
        });
    }
}

test "should return syntax error if its not a symbol type" {
    const text = "+";

    try TestParser.runAny(text, parseSymbolType, struct {
        pub fn expect(t: TestParser, nodeOrError: Parser.ParserError!AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectSyntaxError(nodeOrError, diagnostics.type_expected, .{});
        }
    });
}

test "should parse unary type operators" {
    const tests = .{
        .{ "keyof Array", AST.Node{ .keyof = AST.Node.at(1) } },
        .{ "typeof Array", AST.Node{ .typeof = AST.Node.at(1) } },
    };

    inline for (tests) |test_case| {
        try TestParser.run(test_case[0], parseSymbolType, struct {
            pub fn expect(t: TestParser, node: ?AST.Node.Index, _: MarkerList(test_case[0])) !void {
                try t.expectAST(node, test_case[1]);
            }
        });
    }
}

test "should parse generic type" {
    const text = "Array<number>";

    try TestParser.run(text, parseSymbolType, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectAST(node, AST.Node{ .generic_type = .{
                .name = Token.at(0),
                .params = @constCast(&[_]AST.Node.Index{AST.Node.at(1)}),
            } });
        }
    });
}

test "should parse generic type with multiple params" {
    const text = "Array<number, string>";

    try TestParser.run(text, parseSymbolType, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectAST(node, AST.Node{ .generic_type = .{
                .name = Token.at(0),
                .params = @constCast(&[_]AST.Node.Index{ AST.Node.at(1), AST.Node.at(2) }),
            } });
        }
    });
}

test "should parse nested generic type" {
    const text = "Array<Array<number>>";

    try TestParser.run(text, parseSymbolType, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectAST(node, AST.Node{ .generic_type = .{
                .name = Token.at(0),
                .params = @constCast(&[_]AST.Node.Index{AST.Node.at(2)}),
            } });
        }
    });
}

test "should parse array type" {
    const text = "number[]";

    try TestParser.run(text, parseSymbolType, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectAST(node, AST.Node{ .array_type = AST.Node.at(1) });
        }
    });
}

test "should parse tuple type" {
    const text = "[number, string]";

    try TestParser.run(text, parseSymbolType, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectAST(node, AST.Node{ .tuple_type = @constCast(&[_]AST.Node.Index{ AST.Node.at(1), AST.Node.at(2) }) });
        }
    });
}

test "should parse object type" {
    const texts = .{
        "{ a: number, b: string }",
        "{ a: number; b: string }",
    };

    inline for (texts) |text| {
        try TestParser.run(text, parseObjectType, struct {
            pub fn expect(t: TestParser, _: ?AST.Node.Index, _: MarkerList(text)) !void {
                try t.expectNodesToEqual(&[_]AST.Raw{
                    .{ .tag = .simple_value, .main_token = Token.at(1), .data = .{ .lhs = 1, .rhs = 0 } },
                    .{ .tag = .simple_value, .main_token = Token.at(1), .data = .{ .lhs = 1, .rhs = 0 } },
                    .{ .tag = .simple_type, .main_token = Token.at(3), .data = .{ .lhs = 3, .rhs = 0 } },
                    .{ .tag = .object_type_field, .main_token = Token.at(4), .data = .{ .lhs = 2, .rhs = 3 } },
                    .{ .tag = .simple_value, .main_token = Token.at(5), .data = .{ .lhs = 1, .rhs = 0 } },
                    .{ .tag = .simple_value, .main_token = Token.at(5), .data = .{ .lhs = 1, .rhs = 0 } },
                    .{ .tag = .simple_type, .main_token = Token.at(7), .data = .{ .lhs = 5, .rhs = 0 } },
                    .{ .tag = .object_type_field, .main_token = Token.at(8), .data = .{ .lhs = 6, .rhs = 7 } },
                    .{ .tag = .object_type, .main_token = Token.at(9), .data = .{ .lhs = 0, .rhs = 2 } },
                });
            }
        });
    }
}

test "should parse method type" {
    const texts = .{
        "fn(a: number, b: string): boolean",
        "fn(a: number, b: string,): boolean",
    };

    inline for (texts, 0..) |text, i| {
        try TestParser.run(text, parseObjectMethodType, struct {
            pub fn expect(t: TestParser, _: ?AST.Node.Index, _: MarkerList(text)) !void {
                try t.expectNodesToEqual(&[_]AST.Raw{
                    .{ .tag = .simple_value, .main_token = Token.at(0), .data = .{ .lhs = 1, .rhs = 0 } },
                    .{ .tag = .simple_type, .main_token = Token.at(4), .data = .{ .lhs = 3, .rhs = 0 } },
                    .{ .tag = .function_param, .main_token = Token.at(2), .data = .{ .lhs = 2, .rhs = 2 } },
                    .{ .tag = .simple_type, .main_token = Token.at(8), .data = .{ .lhs = 5, .rhs = 0 } },
                    .{ .tag = .function_param, .main_token = Token.at(6), .data = .{ .lhs = 6, .rhs = 4 } },
                    .{ .tag = .simple_type, .main_token = Token.at(11).inc(i), .data = .{ .lhs = 6, .rhs = 0 } },
                    .{ .tag = .function_type, .main_token = Token.at(1), .data = .{ .lhs = 2, .rhs = 6 } },
                    .{ .tag = .object_type_field, .main_token = Token.at(0), .data = .{ .lhs = 1, .rhs = 7 } },
                });
            }
        });
    }
}

test "should parse method with generics" {
    const texts = .{
        "fn<T>(a: T, b: T): boolean",
        "fn<T,>(a: T, b: T): boolean",
    };

    inline for (texts, 0..) |text, i| {
        try TestParser.run(text, parseObjectMethodType, struct {
            pub fn expect(t: TestParser, _: ?AST.Node.Index, _: MarkerList(text)) !void {
                try t.expectNodesToEqual(&[_]AST.Raw{
                    .{ .tag = .simple_value, .main_token = Token.at(0), .data = .{ .lhs = 1, .rhs = 0 } },
                    .{ .tag = .simple_type, .main_token = Token.at(2), .data = .{ .lhs = 1, .rhs = 0 } },
                    .{ .tag = .simple_type, .main_token = Token.at(7).inc(i), .data = .{ .lhs = 1, .rhs = 0 } },
                    .{ .tag = .function_param, .main_token = Token.at(5).inc(i), .data = .{ .lhs = 5 + i, .rhs = 3 } },
                    .{ .tag = .simple_type, .main_token = Token.at(11).inc(i), .data = .{ .lhs = 1, .rhs = 0 } },
                    .{ .tag = .function_param, .main_token = Token.at(9).inc(i), .data = .{ .lhs = 9 + i, .rhs = 5 } },
                    .{ .tag = .simple_type, .main_token = Token.at(14).inc(i), .data = .{ .lhs = 6, .rhs = 0 } },
                    .{ .tag = .function_type, .main_token = Token.at(4).inc(i), .data = .{ .lhs = 3, .rhs = 7 } },
                    .{ .tag = .object_type_field, .main_token = Token.at(0), .data = .{ .lhs = 1, .rhs = 8 } },
                });
            }
        });
    }
}

test "should return syntax error if there is no comma between generic params" {
    const text = "fn<T B>(a: T): boolean";

    try TestParser.runAny(text, parseObjectMethodType, struct {
        pub fn expect(t: TestParser, nodeOrError: Parser.ParserError!?AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectSyntaxError(nodeOrError, diagnostics.ARG_expected, .{","});
        }
    });
}

test "should parse method type with types" {
    const text = "fn(a, b)";

    try TestParser.run(text, parseObjectMethodType, struct {
        pub fn expect(t: TestParser, _: ?AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectNodesToEqual(&[_]AST.Raw{
                .{ .tag = .simple_value, .main_token = Token.at(0), .data = .{ .lhs = 1, .rhs = 0 } },
                .{ .tag = .function_param, .main_token = Token.at(2), .data = .{ .lhs = 2, .rhs = 0 } },
                .{ .tag = .function_param, .main_token = Token.at(4), .data = .{ .lhs = 4, .rhs = 0 } },
                .{ .tag = .function_type, .main_token = Token.at(1), .data = .{ .lhs = 2, .rhs = 0 } },
                .{ .tag = .object_type_field, .main_token = Token.at(0), .data = .{ .lhs = 1, .rhs = 4 } },
            });
        }
    });
}

test "should return null if its not method type" {
    const text = "[number, string]";

    try TestParser.run(text, parseObjectMethodType, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectAST(node, null);
        }
    });
}

test "should return syntax error if there is no comma after params" {
    const text = "fn(a: number b: string): boolean";

    try TestParser.runAny(text, parseObjectMethodType, struct {
        pub fn expect(t: TestParser, nodeOrError: Parser.ParserError!?AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectSyntaxError(nodeOrError, diagnostics.ARG_expected, .{","});
        }
    });
}

test "should return syntax error if param is not identifier" {
    const text = "fn(void): boolean";

    try TestParser.runAny(text, parseObjectMethodType, struct {
        pub fn expect(t: TestParser, nodeOrError: Parser.ParserError!?AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectSyntaxError(nodeOrError, diagnostics.identifier_expected, .{});
        }
    });
}

test "should parse type identifier" {
    const text = "Array";

    try TestParser.run(text, parseSymbolType, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectAST(node, AST.Node{ .simple_type = .{ .kind = .identifier } });
        }
    });
}

test "should parse type union" {
    const text = "number | string";

    try TestParser.run(text, parseSymbolType, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectAST(node, AST.Node{ .type_union = .{
                .left = AST.Node.at(1),
                .right = AST.Node.at(2),
            } });
        }
    });
}

test "should parse type intersection" {
    const text = "number & string";

    try TestParser.run(text, parseSymbolType, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectAST(node, AST.Node{ .type_intersection = .{
                .left = AST.Node.at(1),
                .right = AST.Node.at(2),
            } });
        }
    });
}
