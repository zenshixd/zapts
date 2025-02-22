const std = @import("std");
const Parser = @import("../parser.zig");
const ParserError = @import("../parser.zig").ParserError;
const AST = @import("../ast.zig");
const Token = @import("../consts.zig").Token;
const TokenType = @import("../consts.zig").TokenType;
const StringId = @import("../string_interner.zig").StringId;
const diagnostics = @import("../diagnostics.zig");
const snap = @import("../tests/snapshots.zig").snap;

const parseIdentifier = @import("primary.zig").parseIdentifier;
const parseKeywordAsIdentifier = @import("primary.zig").parseKeywordAsIdentifier;

const TestParser = @import("../tests/test_parser.zig");
const Marker = TestParser.Marker;

const expectEqual = std.testing.expectEqual;

pub fn parseOptionalDataType(self: *Parser) ParserError!AST.Node.Index {
    if (self.match(TokenType.Colon)) {
        return try expectType(self);
    }

    return AST.Node.Empty;
}

pub fn parseType(self: *Parser) ParserError!?AST.Node.Index {
    return try parseUnionType(self);
}

pub fn expectType(self: *Parser) ParserError!AST.Node.Index {
    return try parseType(self) orelse self.fail(diagnostics.type_expected, .{});
}

fn parseUnionType(self: *Parser) ParserError!?AST.Node.Index {
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

fn parseIntersectionType(self: *Parser) ParserError!?AST.Node.Index {
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

fn parseTypeUnary(self: *Parser) ParserError!?AST.Node.Index {
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

fn parseArrayType(self: *Parser) ParserError!?AST.Node.Index {
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

fn parsePrimaryType(self: *Parser) ParserError!?AST.Node.Index {
    return try parseObjectType(self) orelse
        try parseTupleType(self) orelse
        try parsePrimitiveType(self) orelse
        try parseGenericType(self);
}

fn parseObjectType(self: *Parser) ParserError!?AST.Node.Index {
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

fn parseObjectPropertyType(self: *Parser) ParserError!?AST.Node.Index {
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

fn parseObjectMethodType(self: *Parser) ParserError!?AST.Node.Index {
    const cp = self.checkpoint();
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

    return self.addNode(cp.tok_idx, AST.Node{
        .object_type_field = .{
            .name = identifier,
            .type = fn_type,
        },
    });
}

fn parseFunctionType(self: *Parser) ParserError!?AST.Node.Index {
    const cur_token = self.checkpoint();
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

fn parseFunctionArgumentsType(self: *Parser) ParserError!std.ArrayList(AST.Node.Index) {
    var args = std.ArrayList(AST.Node.Index).init(self.gpa);
    errdefer args.deinit();

    while (!self.match(TokenType.CloseParen)) {
        const identifier = try self.consume(TokenType.Identifier, diagnostics.identifier_expected, .{});
        const arg_type = try parseOptionalDataType(self);
        try args.append(self.addNode(identifier, AST.Node{ .function_param = .{
            .identifier = self.internStr(identifier),
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
    .{ TokenType.NumberConstant, .number_literal },
    .{ TokenType.BigIntConstant, .bigint_literal },
    .{ TokenType.StringConstant, .string_literal },
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
        const token = self.cur_token;
        if (self.match(primitive_type[0])) {
            return self.addNode(token, AST.Node{
                .simple_type = .{
                    .kind = primitive_type[1],
                    .id = self.internStr(token),
                },
            });
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
            .name = self.internStr(identifier),
            .params = params.items,
        } });
    }

    return parseTypeIdentifier(self, identifier);
}

fn parseGenericParams(self: *Parser) ParserError!std.ArrayList(AST.Node.Index) {
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
            return self.addNode(identifier, AST.Node{
                .simple_type = .{
                    .kind = type_item[1],
                    .id = self.internStr(identifier),
                },
            });
        }
    }

    return self.addNode(identifier, AST.Node{
        .simple_type = .{
            .kind = .identifier,
            .id = self.internStr(identifier),
        },
    });
}

fn parseTypeDeclaration(self: *Parser) ParserError!?AST.Node.Index {
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
    const text =
        \\: number
        \\> ^
    ;

    const t, const node, const markers = try TestParser.run(text, parseOptionalDataType);
    defer t.deinit();

    try t.expectASTSnapshot(node, snap(@src(),
        \\ast.Node{
        \\    .simple_type = ast.Node.SimpleValue{
        \\        .kind = ast.SimpleValueKind.number,
        \\        .id = string_interner.StringId(1),
        \\    },
        \\}
    ));
    try t.expectTokenAt(markers[0], node.?);
}

test "should return Empty node if no data type" {
    const text = "ident";

    const t, const node, _ = try TestParser.run(text, parseOptionalDataType);
    defer t.deinit();

    try expectEqual(node, AST.Node.Empty);
}

test "should parse primary symbol type" {
    const tests = .{
        .{
            \\ number
            \\>^
            ,
            snap(@src(),
                \\ast.Node{
                \\    .simple_type = ast.Node.SimpleValue{
                \\        .kind = ast.SimpleValueKind.number,
                \\        .id = string_interner.StringId(1),
                \\    },
                \\}
            ),
        },
        .{
            \\ bigint
            \\>^
            ,
            snap(@src(),
                \\ast.Node{
                \\    .simple_type = ast.Node.SimpleValue{
                \\        .kind = ast.SimpleValueKind.bigint,
                \\        .id = string_interner.StringId(1),
                \\    },
                \\}
            ),
        },
        .{
            \\ string
            \\>^
            ,
            snap(@src(),
                \\ast.Node{
                \\    .simple_type = ast.Node.SimpleValue{
                \\        .kind = ast.SimpleValueKind.string,
                \\        .id = string_interner.StringId(1),
                \\    },
                \\}
            ),
        },
        .{
            \\ boolean
            \\>^
            ,
            snap(@src(),
                \\ast.Node{
                \\    .simple_type = ast.Node.SimpleValue{
                \\        .kind = ast.SimpleValueKind.boolean,
                \\        .id = string_interner.StringId(1),
                \\    },
                \\}
            ),
        },
        .{
            \\ null
            \\>^
            ,
            snap(@src(),
                \\ast.Node{
                \\    .simple_type = ast.Node.SimpleValue{
                \\        .kind = ast.SimpleValueKind.null,
                \\        .id = string_interner.StringId(1),
                \\    },
                \\}
            ),
        },
        .{
            \\ undefined
            \\>^
            ,
            snap(@src(),
                \\ast.Node{
                \\    .simple_type = ast.Node.SimpleValue{
                \\        .kind = ast.SimpleValueKind.undefined,
                \\        .id = string_interner.StringId(1),
                \\    },
                \\}
            ),
        },
        .{
            \\ void
            \\>^
            ,
            snap(@src(),
                \\ast.Node{
                \\    .simple_type = ast.Node.SimpleValue{
                \\        .kind = ast.SimpleValueKind.void,
                \\        .id = string_interner.StringId(1),
                \\    },
                \\}
            ),
        },
        .{
            \\ any
            \\>^
            ,
            snap(@src(),
                \\ast.Node{
                \\    .simple_type = ast.Node.SimpleValue{
                \\        .kind = ast.SimpleValueKind.any,
                \\        .id = string_interner.StringId(1),
                \\    },
                \\}
            ),
        },
        .{
            \\ unknown
            \\>^
            ,
            snap(@src(),
                \\ast.Node{
                \\    .simple_type = ast.Node.SimpleValue{
                \\        .kind = ast.SimpleValueKind.unknown,
                \\        .id = string_interner.StringId(1),
                \\    },
                \\}
            ),
        },
    };

    inline for (tests) |test_case| {
        const t, const node, const markers = try TestParser.run(test_case[0], parseType);
        defer t.deinit();

        try t.expectASTSnapshot(node, test_case[1]);
        try t.expectTokenAt(markers[0], node.?);
    }
}

test "should return syntax error if its not a symbol type" {
    const text = "+";

    const t, const nodeOrError, _ = try TestParser.runCatch(text, expectType);
    defer t.deinit();

    try t.expectSyntaxError(nodeOrError, diagnostics.type_expected, .{});
}

test "should parse unary type operators" {
    const tests = .{
        .{
            \\ keyof Array
            \\>^
            ,
            snap(@src(),
                \\ast.Node{
                \\    .keyof = ast.Node.Index(0),
                \\}
            ),
        },
        .{
            \\ typeof Array
            \\>^
            ,
            snap(@src(),
                \\ast.Node{
                \\    .typeof = ast.Node.Index(0),
                \\}
            ),
        },
    };

    inline for (tests) |test_case| {
        const t, const node, const markers = try TestParser.run(test_case[0], parseType);
        defer t.deinit();

        try t.expectASTSnapshot(node, test_case[1]);
        try t.expectTokenAt(markers[0], node.?);
    }
}

test "should return syntax error if type after unary operator is missing" {
    const text =
        \\ keyof
        \\>     ^
    ;

    const t, const nodeOrError, const markers = try TestParser.runCatch(text, expectType);
    defer t.deinit();

    try t.expectSyntaxErrorAt(nodeOrError, diagnostics.type_expected, .{}, markers[0]);
}

test "should parse generic type" {
    const text =
        \\ Array<number>
        \\>^     ^
    ;

    const t, const node, const markers = try TestParser.run(text, parseType);
    defer t.deinit();

    try t.expectASTSnapshot(node, snap(@src(),
        \\ast.Node{
        \\    .generic_type = ast.Node.GenericType{
        \\        .name = string_interner.StringId(2),
        \\        .params = [_]ast.Node.Index{
        \\            ast.Node.Index(0)
        \\        },
        \\    },
        \\}
    ));
    try t.expectTokenAt(markers[0], node.?);

    try t.expectASTSnapshot(t.parser.getNode(node.?).generic_type.params[0], snap(@src(),
        \\ast.Node{
        \\    .simple_type = ast.Node.SimpleValue{
        \\        .kind = ast.SimpleValueKind.number,
        \\        .id = string_interner.StringId(1),
        \\    },
        \\}
    ));
    try t.expectTokenAt(markers[1], t.parser.getNode(node.?).generic_type.params[0]);
}

test "should parse generic type with multiple params" {
    const text =
        \\ Array<number, string>
        \\>^
    ;

    const t, const node, const markers = try TestParser.run(text, parseType);
    defer t.deinit();

    try t.expectASTSnapshot(node, snap(@src(),
        \\ast.Node{
        \\    .generic_type = ast.Node.GenericType{
        \\        .name = string_interner.StringId(3),
        \\        .params = [_]ast.Node.Index{
        \\            ast.Node.Index(0), 
        \\            ast.Node.Index(1)
        \\        },
        \\    },
        \\}
    ));
    try t.expectTokenAt(markers[0], node.?);
}

test "should parse nested generic type" {
    const text =
        \\ Array<Array<number>>
        \\>^     ^
    ;

    const t, const node, const markers = try TestParser.run(text, parseType);
    defer t.deinit();

    try t.expectASTSnapshot(node, snap(@src(),
        \\ast.Node{
        \\    .generic_type = ast.Node.GenericType{
        \\        .name = string_interner.StringId(2),
        \\        .params = [_]ast.Node.Index{
        \\            ast.Node.Index(1)
        \\        },
        \\    },
        \\}
    ));
    try t.expectTokenAt(markers[0], node.?);

    try t.expectASTSnapshot(t.parser.getNode(node.?).generic_type.params[0], snap(@src(),
        \\ast.Node{
        \\    .generic_type = ast.Node.GenericType{
        \\        .name = string_interner.StringId(2),
        \\        .params = [_]ast.Node.Index{
        \\            ast.Node.Index(0)
        \\        },
        \\    },
        \\}
    ));
    try t.expectTokenAt(markers[1], t.parser.getNode(node.?).generic_type.params[0]);
}

test "should parse array type" {
    const text =
        \\ number[]
        \\>      ^
    ;

    const t, const node, const markers = try TestParser.run(text, parseType);
    defer t.deinit();

    try t.expectASTSnapshot(node, snap(@src(),
        \\ast.Node{
        \\    .array_type = ast.Node.Index(0),
        \\}
    ));
    try t.expectTokenAt(markers[0], node.?);
}

test "should return syntax error if closing bracket is missing" {
    const text =
        \\ number[
        \\>       ^
    ;

    const t, const nodeOrError, const markers = try TestParser.runCatch(text, parseType);
    defer t.deinit();

    try t.expectSyntaxErrorAt(nodeOrError, diagnostics.type_expected, .{}, markers[0]);
}

test "should parse index type" {
    const text =
        \\ obj[number]
        \\>   ^
    ;

    const t, const node, const markers = try TestParser.run(text, parseType);
    defer t.deinit();

    try t.expectASTSnapshot(node, snap(@src(),
        \\ast.Node{
        \\    .index_type = ast.Node.Index(1),
        \\}
    ));
    try t.expectTokenAt(markers[0], node.?);
}

test "should parse tuple type" {
    const text =
        \\ [number, string]
        \\>^
    ;

    const t, const node, const markers = try TestParser.run(text, parseType);
    defer t.deinit();

    try t.expectASTSnapshot(node, snap(@src(),
        \\ast.Node{
        \\    .tuple_type = [_]ast.Node.Index{
        \\        ast.Node.Index(0), 
        \\        ast.Node.Index(1)
        \\    },
        \\}
    ));
    try t.expectTokenAt(markers[0], node.?);
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
        const t, const node, const markers = try TestParser.run(text, parseObjectType);
        defer t.deinit();

        try t.expectASTSnapshot(node, snap(@src(),
            \\ast.Node{
            \\    .object_type = [_]ast.Node.Index{
            \\        ast.Node.Index(2), 
            \\        ast.Node.Index(5)
            \\    },
            \\}
        ));
        try t.expectTokenAt(markers[0], node.?);
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

    inline for (texts) |text| {
        const t, const node, const markers = try TestParser.run(text, parseObjectMethodType);
        defer t.deinit();

        try t.expectASTSnapshot(node, snap(@src(),
            \\ast.Node{
            \\    .object_type_field = ast.Node.ObjectTypeField{
            \\        .name = ast.Node.Index(0),
            \\        .type = ast.Node.Index(6),
            \\    },
            \\}
        ));
        try t.expectTokenAt(markers[0], node.?);

        const fn_type = t.parser.getNode(node.?).object_type_field.type;
        try t.expectASTSnapshot(fn_type, snap(@src(),
            \\ast.Node{
            \\    .function_type = ast.Node.FunctionType{
            \\        .generic_params = [_]ast.Node.Index{},
            \\        .params = [_]ast.Node.Index{
            \\            ast.Node.Index(2), 
            \\            ast.Node.Index(4)
            \\        },
            \\        .return_type = ast.Node.Index(5),
            \\    },
            \\}
        ));
        try t.expectTokenAt(markers[1], fn_type);
        try t.expectTokenAt(markers[2], t.parser.getNode(fn_type).function_type.params[0]);
        try t.expectTokenAt(markers[3], t.parser.getNode(fn_type).function_type.params[1]);
    }
}

test "should parse method with generics" {
    const texts = .{
        "fn<T>(a: T, b: T): boolean",
        "fn<T,>(a: T, b: T): boolean",
    };

    inline for (texts) |text| {
        const t, const node, _ = try TestParser.run(text, parseObjectMethodType);
        defer t.deinit();

        try t.expectASTSnapshot(node, snap(@src(),
            \\ast.Node{
            \\    .object_type_field = ast.Node.ObjectTypeField{
            \\        .name = ast.Node.Index(0),
            \\        .type = ast.Node.Index(7),
            \\    },
            \\}
        ));
        try t.expectASTSnapshot(t.parser.getNode(node.?).object_type_field.type, snap(@src(),
            \\ast.Node{
            \\    .function_type = ast.Node.FunctionType{
            \\        .generic_params = [_]ast.Node.Index{
            \\            ast.Node.Index(1)
            \\        },
            \\        .params = [_]ast.Node.Index{
            \\            ast.Node.Index(3), 
            \\            ast.Node.Index(5)
            \\        },
            \\        .return_type = ast.Node.Index(6),
            \\    },
            \\}
        ));
    }
}

test "should return syntax error if there is no comma between generic params" {
    const text =
        \\fn<T B>(a: T): boolean
        \\>    ^
    ;

    const t, const nodeOrError, const markers = try TestParser.runCatch(text, parseObjectMethodType);
    defer t.deinit();

    try t.expectSyntaxErrorAt(nodeOrError, diagnostics.ARG_expected, .{","}, markers[0]);
}

test "should parse method type without types" {
    const text = "fn(a, b)";

    const t, const node, _ = try TestParser.run(text, parseObjectMethodType);
    defer t.deinit();

    try t.expectASTSnapshot(node, snap(@src(),
        \\ast.Node{
        \\    .object_type_field = ast.Node.ObjectTypeField{
        \\        .name = ast.Node.Index(0),
        \\        .type = ast.Node.Index(3),
        \\    },
        \\}
    ));

    try t.expectASTSnapshot(t.parser.getNode(node.?).object_type_field.type, snap(@src(),
        \\ast.Node{
        \\    .function_type = ast.Node.FunctionType{
        \\        .generic_params = [_]ast.Node.Index{},
        \\        .params = [_]ast.Node.Index{
        \\            ast.Node.Index(1), 
        \\            ast.Node.Index(2)
        \\        },
        \\        .return_type = ast.Node.Index.empty,
        \\    },
        \\}
    ));
}

test "should return null if its not method type" {
    const text = "[number, string]";

    const t, const node, _ = try TestParser.run(text, parseObjectMethodType);
    defer t.deinit();

    try t.expectAST(node, null);
}

test "should return syntax error if there is no comma after params" {
    const text =
        \\fn(a: number b: string): boolean
        \\>            ^
    ;

    const t, const nodeOrError, const markers = try TestParser.runCatch(text, parseObjectMethodType);
    defer t.deinit();

    try t.expectSyntaxErrorAt(nodeOrError, diagnostics.ARG_expected, .{","}, markers[0]);
}

test "should return syntax error if param is not identifier" {
    const text =
        \\fn(void): boolean
        \\>  ^
    ;

    const t, const nodeOrError, const markers = try TestParser.runCatch(text, parseObjectMethodType);
    defer t.deinit();

    try t.expectSyntaxErrorAt(nodeOrError, diagnostics.identifier_expected, .{}, markers[0]);
}

test "should parse type identifier" {
    const text =
        \\ Array
        \\>^   
    ;

    const t, const node, const markers = try TestParser.run(text, parseType);
    defer t.deinit();

    try t.expectASTSnapshot(node, snap(@src(),
        \\ast.Node{
        \\    .simple_type = ast.Node.SimpleValue{
        \\        .kind = ast.SimpleValueKind.identifier,
        \\        .id = string_interner.StringId(1),
        \\    },
        \\}
    ));
    try t.expectTokenAt(markers[0], node.?);
}

test "should parse type union" {
    const text =
        \\ number | string
        \\>       ^
    ;

    const t, const node, const markers = try TestParser.run(text, parseType);
    defer t.deinit();

    try t.expectASTSnapshot(node, snap(@src(),
        \\ast.Node{
        \\    .type_union = ast.Node.Binary{
        \\        .left = ast.Node.Index(0),
        \\        .right = ast.Node.Index(1),
        \\    },
        \\}
    ));
    try t.expectTokenAt(markers[0], node.?);
}

test "should return syntax error if right is missing in union operator" {
    const text =
        \\ number |
        \\>        ^
    ;

    const t, const nodeOrError, const markers = try TestParser.runCatch(text, parseType);
    defer t.deinit();

    try t.expectSyntaxErrorAt(nodeOrError, diagnostics.type_expected, .{}, markers[0]);
}

test "should parse type intersection" {
    const text =
        \\ number & string
        \\>       ^
    ;

    const t, const node, const markers = try TestParser.run(text, parseType);
    defer t.deinit();

    try t.expectASTSnapshot(node, snap(@src(),
        \\ast.Node{
        \\    .type_intersection = ast.Node.Binary{
        \\        .left = ast.Node.Index(0),
        \\        .right = ast.Node.Index(1),
        \\    },
        \\}
    ));
    try t.expectTokenAt(markers[0], node.?);
}

test "should return syntax error if right is missing in intersection operator" {
    const text =
        \\ number &
        \\>        ^
    ;

    const t, const nodeOrError, const markers = try TestParser.runCatch(text, parseType);
    defer t.deinit();

    try t.expectSyntaxErrorAt(nodeOrError, diagnostics.type_expected, .{}, markers[0]);
}
