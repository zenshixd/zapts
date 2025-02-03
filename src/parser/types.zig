const std = @import("std");
const Parser = @import("../parser.zig");
const AST = @import("../ast.zig");
const Token = @import("../consts.zig").Token;
const TokenType = @import("../consts.zig").TokenType;
const CompilationError = @import("../consts.zig").CompilationError;
const diagnostics = @import("../diagnostics.zig");

const parseIdentifier = @import("primary.zig").parseIdentifier;
const parseKeywordAsIdentifier = @import("primary.zig").parseKeywordAsIdentifier;

const Marker = @import("../test_parser.zig").Marker;
const MarkerList = @import("../test_parser.zig").MarkerList;
const TestParser = @import("../test_parser.zig");

const expectEqual = std.testing.expectEqual;

pub fn parseOptionalDataType(self: *Parser) CompilationError!AST.Node.Index {
    if (self.match(TokenType.Colon)) {
        return try expectType(self);
    }

    return AST.Node.Empty;
}

pub fn parseType(self: *Parser) CompilationError!?AST.Node.Index {
    return try parseUnionType(self);
}

pub fn expectType(self: *Parser) CompilationError!AST.Node.Index {
    return try parseType(self) orelse self.fail(diagnostics.type_expected, .{});
}

fn parseUnionType(self: *Parser) CompilationError!?AST.Node.Index {
    var node = try parseIntersectionType(self) orelse return null;

    const main_token = self.cur_token;
    if (self.match(TokenType.Bar)) {
        const new_node = self.addNode(main_token, AST.Node{
            .type_union = .{
                .left = node,
                .right = try parseUnionType(self) orelse return self.fail(diagnostics.type_expected, .{}),
            },
        });

        node = new_node;
    }

    return node;
}

fn parseIntersectionType(self: *Parser) CompilationError!?AST.Node.Index {
    var node = try parseTypeUnary(self) orelse return null;

    const main_token = self.cur_token;
    if (self.match(TokenType.Ampersand)) {
        const new_node = self.addNode(main_token, AST.Node{
            .type_intersection = .{
                .left = node,
                .right = try parseIntersectionType(self) orelse return self.fail(diagnostics.type_expected, .{}),
            },
        });

        node = new_node;
    }

    return node;
}

fn parseTypeUnary(self: *Parser) CompilationError!?AST.Node.Index {
    const main_token = self.cur_token;
    if (self.match(TokenType.Typeof)) {
        return self.addNode(main_token, AST.Node{
            .typeof = try expectType(self),
        });
    } else if (self.match(TokenType.Keyof)) {
        return self.addNode(main_token, AST.Node{
            .keyof = try expectType(self),
        });
    }

    return try parseArrayType(self);
}

fn parseArrayType(self: *Parser) CompilationError!?AST.Node.Index {
    const node = try parsePrimaryType(self) orelse return null;
    const main_token = self.cur_token;

    if (self.match(TokenType.OpenSquareBracket)) {
        if (self.match(TokenType.CloseSquareBracket)) {
            return self.addNode(main_token, AST.Node{ .array_type = node });
        }

        const index_type = try expectType(self);
        return self.addNode(main_token, AST.Node{ .index_type = index_type });
    }

    return node;
}

fn parsePrimaryType(self: *Parser) CompilationError!?AST.Node.Index {
    return try parseObjectType(self) orelse
        try parseTupleType(self) orelse
        try parsePrimitiveType(self) orelse
        try parseGenericType(self);
}

fn parseObjectType(self: *Parser) CompilationError!?AST.Node.Index {
    const main_token = self.cur_token;
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

    return self.addNode(main_token, AST.Node{ .object_type = list.items });
}

fn parseObjectPropertyType(self: *Parser) CompilationError!?AST.Node.Index {
    const main_token = self.cur_token;
    const identifier = try parseIdentifier(self) orelse return null;

    var right: AST.Node.Index = AST.Node.Empty;

    if (self.match(TokenType.Colon)) {
        right = try expectType(self);
    }

    return self.addNode(main_token, AST.Node{
        .object_type_field = .{
            .name = identifier,
            .type = right,
        },
    });
}

fn parseObjectMethodType(self: *Parser) CompilationError!?AST.Node.Index {
    const cp = self.cur_token;
    const identifier = try parseIdentifier(self) orelse {
        self.rewindTo(cp);
        return null;
    };

    const generics = if (self.match(TokenType.LessThan)) try parseGenericParams(self) else null;
    defer {
        if (generics != null) {
            generics.?.deinit();
        }
    }

    const start_token = self.consumeOrNull(TokenType.OpenParen) orelse {
        self.rewindTo(cp);
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

fn parseFunctionType(self: *Parser) CompilationError!?AST.Node.Index {
    const cur_token = self.cur_token;
    const generics = if (self.match(TokenType.LessThan)) try parseGenericParams(self) else null;
    defer {
        if (generics) |g| {
            g.deinit();
        }
    }

    const start_token = self.consumeOrNull(TokenType.OpenParen) orelse {
        self.rewindTo(cur_token);
        return null;
    };

    var params = try parseFunctionArgumentsType(self);
    defer params.deinit();

    _ = try self.consume(TokenType.Arrow, diagnostics.ARG_expected, .{"=>"});

    const return_type = try expectType(self);

    return self.addNode(start_token, AST.Node{ .function_type = .{
        .generic_params = if (generics) |g| g.items else &.{},
        .params = params.items,
        .return_type = return_type,
    } });
}

fn parseFunctionArgumentsType(self: *Parser) CompilationError!std.ArrayList(AST.Node.Index) {
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

fn parseTupleType(self: *Parser) CompilationError!?AST.Node.Index {
    const main_token = self.cur_token;
    if (!self.match(TokenType.OpenSquareBracket)) {
        return null;
    }

    var list = std.ArrayList(AST.Node.Index).init(self.gpa);
    defer list.deinit();

    while (!self.match(TokenType.CloseSquareBracket)) {
        const node = try expectType(self);
        try list.append(node);

        if (self.match(TokenType.CloseSquareBracket)) {
            break;
        }

        _ = try self.consume(TokenType.Comma, diagnostics.ARG_expected, .{","});
    }

    return self.addNode(main_token, AST.Node{ .tuple_type = list.items });
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

fn parsePrimitiveType(self: *Parser) CompilationError!?AST.Node.Index {
    inline for (primitive_types) |primitive_type| {
        if (self.match(primitive_type[0])) {
            return self.addNode(self.cur_token.dec(1), AST.Node{ .simple_type = .{ .kind = primitive_type[1] } });
        }
    }

    return null;
}
fn parseGenericType(self: *Parser) CompilationError!?AST.Node.Index {
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

fn parseGenericParams(self: *Parser) CompilationError!std.ArrayList(AST.Node.Index) {
    var params = std.ArrayList(AST.Node.Index).init(self.gpa);
    errdefer params.deinit();

    while (!self.match(TokenType.GreaterThan)) {
        try params.append(try expectType(self));

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

    const value = self.tokens.items[identifier.int()].literal(self.buffer);
    inline for (type_map) |type_item| {
        if (std.mem.eql(u8, type_item[0], value)) {
            return self.addNode(identifier, AST.Node{ .simple_type = .{ .kind = type_item[1] } });
        }
    }

    return self.addNode(identifier, AST.Node{ .simple_type = .{ .kind = .identifier } });
}

fn parseTypeDeclaration(self: *Parser) CompilationError!?AST.Node.Index {
    if (!self.match(TokenType.Type)) {
        return null;
    }

    const identifier = self.consumeOrNull(TokenType.Identifier) orelse
        parseKeywordAsIdentifier(self) orelse
        return self.fail(diagnostics.identifier_expected, .{});

    _ = try self.consume(TokenType.Equal, diagnostics.ARG_expected, .{"="});

    const identifier_data_type = try expectType(self);

    return self.addNode(self.cur_token, AST.Node{ .type_decl = .{
        .left = identifier,
        .right = identifier_data_type,
    } });
}

fn parseInterfaceDeclaration(self: *Parser) CompilationError!?AST.Node.Index {
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
    const text =
        \\: number
        \\> ^
    ;

    try TestParser.run(text, parseOptionalDataType, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, comptime markers: MarkerList(text)) !void {
            try t.expectAST(node, AST.Node{ .simple_type = .{ .kind = .number } });
            try t.expectTokenAt(markers[0], node.?);
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
        .{
            \\ number
            \\>^
            ,
            AST.Node{ .simple_type = .{ .kind = .number } },
        },
        .{
            \\ bigint
            \\>^
            ,
            AST.Node{ .simple_type = .{ .kind = .bigint } },
        },
        .{
            \\ string
            \\>^
            ,
            AST.Node{ .simple_type = .{ .kind = .string } },
        },
        .{
            \\ boolean
            \\>^
            ,
            AST.Node{ .simple_type = .{ .kind = .boolean } },
        },
        .{
            \\ null
            \\>^
            ,
            AST.Node{ .simple_type = .{ .kind = .null } },
        },
        .{
            \\ undefined
            \\>^
            ,
            AST.Node{ .simple_type = .{ .kind = .undefined } },
        },
        .{
            \\ void
            \\>^
            ,
            AST.Node{ .simple_type = .{ .kind = .void } },
        },
        .{
            \\ any
            \\>^
            ,
            AST.Node{ .simple_type = .{ .kind = .any } },
        },
        .{
            \\ unknown
            \\>^
            ,
            AST.Node{ .simple_type = .{ .kind = .unknown } },
        },
    };

    inline for (tests) |test_case| {
        try TestParser.run(test_case[0], parseType, struct {
            pub fn expect(t: TestParser, node: ?AST.Node.Index, comptime markers: MarkerList(test_case[0])) !void {
                try t.expectAST(node, test_case[1]);
                try t.expectTokenAt(markers[0], node.?);
            }
        });
    }
}

test "should return syntax error if its not a symbol type" {
    const text = "+";

    try TestParser.runAny(text, expectType, struct {
        pub fn expect(t: TestParser, nodeOrError: CompilationError!AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectSyntaxError(nodeOrError, diagnostics.type_expected, .{});
        }
    });
}

test "should parse unary type operators" {
    const tests = .{
        .{
            \\ keyof Array
            \\>^
            ,
            AST.Node{ .keyof = AST.Node.at(1) },
        },
        .{
            \\ typeof Array
            \\>^
            ,
            AST.Node{ .typeof = AST.Node.at(1) },
        },
    };

    inline for (tests) |test_case| {
        try TestParser.run(test_case[0], parseType, struct {
            pub fn expect(t: TestParser, node: ?AST.Node.Index, comptime markers: MarkerList(test_case[0])) !void {
                try t.expectAST(node, test_case[1]);
                try t.expectTokenAt(markers[0], node.?);
            }
        });
    }
}

test "should return syntax error if type after unary operator is missing" {
    const text =
        \\ keyof
        \\>     ^
    ;

    try TestParser.runAny(text, expectType, struct {
        pub fn expect(t: TestParser, nodeOrError: CompilationError!AST.Node.Index, comptime markers: MarkerList(text)) !void {
            try t.expectSyntaxErrorAt(nodeOrError, diagnostics.type_expected, .{}, markers[0]);
        }
    });
}

test "should parse generic type" {
    const text =
        \\ Array<number>
        \\>^     ^
    ;

    try TestParser.run(text, parseType, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, comptime markers: MarkerList(text)) !void {
            const generic = AST.Node{ .generic_type = .{
                .name = Token.at(0),
                .params = @constCast(&[_]AST.Node.Index{AST.Node.at(1)}),
            } };
            try t.expectAST(node, generic);
            try t.expectTokenAt(markers[0], node.?);

            try t.expectAST(generic.generic_type.params[0], AST.Node{
                .simple_type = .{ .kind = .number },
            });
            try t.expectTokenAt(markers[1], generic.generic_type.params[0]);
        }
    });
}

test "should parse generic type with multiple params" {
    const text =
        \\ Array<number, string>
        \\>^
    ;

    try TestParser.run(text, parseType, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, comptime markers: MarkerList(text)) !void {
            try t.expectAST(node, AST.Node{
                .generic_type = .{
                    .name = Token.at(0),
                    .params = @constCast(&[_]AST.Node.Index{ AST.Node.at(1), AST.Node.at(2) }),
                },
            });
            try t.expectTokenAt(markers[0], node.?);
        }
    });
}

test "should parse nested generic type" {
    const text =
        \\ Array<Array<number>>
        \\>^     ^
    ;

    try TestParser.run(text, parseType, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, comptime markers: MarkerList(text)) !void {
            const generic_type = AST.Node{
                .generic_type = .{
                    .name = Token.at(0),
                    .params = @constCast(&[_]AST.Node.Index{AST.Node.at(2)}),
                },
            };
            try t.expectAST(node, generic_type);
            try t.expectTokenAt(markers[0], node.?);

            try t.expectAST(generic_type.generic_type.params[0], AST.Node{
                .generic_type = .{
                    .name = Token.at(2),
                    .params = @constCast(&[_]AST.Node.Index{AST.Node.at(1)}),
                },
            });
            try t.expectTokenAt(markers[1], generic_type.generic_type.params[0]);
        }
    });
}

test "should parse array type" {
    const text =
        \\ number[]
        \\>      ^
    ;

    try TestParser.run(text, parseType, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, comptime markers: MarkerList(text)) !void {
            try t.expectAST(node, AST.Node{
                .array_type = AST.Node.at(1),
            });
            try t.expectTokenAt(markers[0], node.?);
        }
    });
}

test "should return syntax error if closing bracket is missing" {
    const text =
        \\ number[
        \\>       ^
    ;

    try TestParser.runAny(text, parseType, struct {
        pub fn expect(t: TestParser, nodeOrError: CompilationError!?AST.Node.Index, comptime markers: MarkerList(text)) !void {
            try t.expectSyntaxErrorAt(nodeOrError, diagnostics.type_expected, .{}, markers[0]);
        }
    });
}

test "should parse index type" {
    const text =
        \\ obj[number]
        \\>   ^
    ;

    try TestParser.run(text, parseType, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, comptime markers: MarkerList(text)) !void {
            try t.expectAST(node, AST.Node{
                .index_type = AST.Node.at(2),
            });
            try t.expectTokenAt(markers[0], node.?);
        }
    });
}

test "should parse tuple type" {
    const text =
        \\ [number, string]
        \\>^
    ;

    try TestParser.run(text, parseType, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, comptime markers: MarkerList(text)) !void {
            try t.expectAST(node, AST.Node{
                .tuple_type = @constCast(&[_]AST.Node.Index{ AST.Node.at(1), AST.Node.at(2) }),
            });
            try t.expectTokenAt(markers[0], node.?);
        }
    });
}

test "should parse object type" {
    const texts = .{
        \\ { a: number, b: string }
        \\>^ ^          ^
        ,
        \\ { a: number; b: string }
        \\>^ ^          ^
        ,
    };

    inline for (texts) |text| {
        try TestParser.run(text, parseObjectType, struct {
            pub fn expect(t: TestParser, node: ?AST.Node.Index, comptime markers: MarkerList(text)) !void {
                try t.expectNodesToEqual(&[_]AST.Raw{
                    .{ .tag = .simple_value, .main_token = Token.at(1), .data = .{ .lhs = 1, .rhs = 0 } },
                    .{ .tag = .simple_value, .main_token = Token.at(1), .data = .{ .lhs = 1, .rhs = 0 } },
                    .{ .tag = .simple_type, .main_token = Token.at(3), .data = .{ .lhs = 3, .rhs = 0 } },
                    .{ .tag = .object_type_field, .main_token = t.getTokenAt(markers[1]), .data = .{ .lhs = 2, .rhs = 3 } },
                    .{ .tag = .simple_value, .main_token = Token.at(5), .data = .{ .lhs = 1, .rhs = 0 } },
                    .{ .tag = .simple_value, .main_token = Token.at(5), .data = .{ .lhs = 1, .rhs = 0 } },
                    .{ .tag = .simple_type, .main_token = Token.at(7), .data = .{ .lhs = 5, .rhs = 0 } },
                    .{ .tag = .object_type_field, .main_token = t.getTokenAt(markers[2]), .data = .{ .lhs = 6, .rhs = 7 } },
                    .{ .tag = .object_type, .main_token = t.getTokenAt(markers[0]), .data = .{ .lhs = 0, .rhs = 2 } },
                });
                try t.expectTokenAt(markers[0], node.?);
            }
        });
    }
}

test "should parse method type" {
    const texts = .{
        \\ fn(a: number, b: string): boolean
        \\>^ ^^          ^
        ,
        \\ fn(a: number, b: string,): boolean
        \\>^ ^^          ^
        ,
    };

    inline for (texts, 0..) |text, i| {
        try TestParser.run(text, parseObjectMethodType, struct {
            pub fn expect(t: TestParser, _: ?AST.Node.Index, comptime markers: MarkerList(text)) !void {
                try t.expectNodesToEqual(&[_]AST.Raw{
                    .{ .tag = .simple_value, .main_token = Token.at(0), .data = .{ .lhs = 1, .rhs = 0 } },
                    .{ .tag = .simple_type, .main_token = Token.at(4), .data = .{ .lhs = 3, .rhs = 0 } },
                    .{ .tag = .function_param, .main_token = t.getTokenAt(markers[2]), .data = .{ .lhs = 2, .rhs = 2 } },
                    .{ .tag = .simple_type, .main_token = Token.at(8), .data = .{ .lhs = 5, .rhs = 0 } },
                    .{ .tag = .function_param, .main_token = t.getTokenAt(markers[3]), .data = .{ .lhs = 6, .rhs = 4 } },
                    .{ .tag = .simple_type, .main_token = Token.at(11).inc(i), .data = .{ .lhs = 6, .rhs = 0 } },
                    .{ .tag = .function_type, .main_token = t.getTokenAt(markers[1]), .data = .{ .lhs = 2, .rhs = 6 } },
                    .{ .tag = .object_type_field, .main_token = t.getTokenAt(markers[0]), .data = .{ .lhs = 1, .rhs = 7 } },
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
    const text =
        \\fn<T B>(a: T): boolean
        \\>    ^
    ;

    try TestParser.runAny(text, parseObjectMethodType, struct {
        pub fn expect(t: TestParser, nodeOrError: CompilationError!?AST.Node.Index, comptime markers: MarkerList(text)) !void {
            try t.expectSyntaxErrorAt(nodeOrError, diagnostics.ARG_expected, .{","}, markers[0]);
        }
    });
}

test "should parse method type without types" {
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
    const text =
        \\fn(a: number b: string): boolean
        \\>            ^
    ;

    try TestParser.runAny(text, parseObjectMethodType, struct {
        pub fn expect(t: TestParser, nodeOrError: CompilationError!?AST.Node.Index, comptime markers: MarkerList(text)) !void {
            try t.expectSyntaxErrorAt(nodeOrError, diagnostics.ARG_expected, .{","}, markers[0]);
        }
    });
}

test "should return syntax error if param is not identifier" {
    const text =
        \\fn(void): boolean
        \\>  ^
    ;

    try TestParser.runAny(text, parseObjectMethodType, struct {
        pub fn expect(t: TestParser, nodeOrError: CompilationError!?AST.Node.Index, comptime markers: MarkerList(text)) !void {
            try t.expectSyntaxErrorAt(nodeOrError, diagnostics.identifier_expected, .{}, markers[0]);
        }
    });
}

test "should parse type identifier" {
    const text =
        \\ Array
        \\>^   
    ;

    try TestParser.run(text, parseType, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, comptime markers: MarkerList(text)) !void {
            try t.expectAST(node, AST.Node{ .simple_type = .{ .kind = .identifier } });
            try t.expectTokenAt(markers[0], node.?);
        }
    });
}

test "should parse type union" {
    const text =
        \\ number | string
        \\>       ^
    ;

    try TestParser.run(text, parseType, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, comptime markers: MarkerList(text)) !void {
            try t.expectAST(node, AST.Node{ .type_union = .{
                .left = AST.Node.at(1),
                .right = AST.Node.at(2),
            } });
            try t.expectTokenAt(markers[0], node.?);
        }
    });
}

test "should return syntax error if right is missing in union operator" {
    const text =
        \\ number |
        \\>        ^
    ;

    try TestParser.runAny(text, parseType, struct {
        pub fn expect(t: TestParser, nodeOrError: CompilationError!?AST.Node.Index, comptime markers: MarkerList(text)) !void {
            try t.expectSyntaxErrorAt(nodeOrError, diagnostics.type_expected, .{}, markers[0]);
        }
    });
}

test "should parse type intersection" {
    const text =
        \\ number & string
        \\>       ^
    ;

    try TestParser.run(text, parseType, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, comptime markers: MarkerList(text)) !void {
            try t.expectAST(node, AST.Node{ .type_intersection = .{
                .left = AST.Node.at(1),
                .right = AST.Node.at(2),
            } });
            try t.expectTokenAt(markers[0], node.?);
        }
    });
}

test "should return syntax error if right is missing in intersection operator" {
    const text =
        \\ number &
        \\>        ^
    ;

    try TestParser.runAny(text, parseType, struct {
        pub fn expect(t: TestParser, nodeOrError: CompilationError!?AST.Node.Index, comptime markers: MarkerList(text)) !void {
            try t.expectSyntaxErrorAt(nodeOrError, diagnostics.type_expected, .{}, markers[0]);
        }
    });
}
