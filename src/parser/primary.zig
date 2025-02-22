const std = @import("std");

const Token = @import("../consts.zig").Token;
const TokenType = @import("../consts.zig").TokenType;
const ALLOWED_KEYWORDS_AS_IDENTIFIERS = @import("../consts.zig").ALLOWED_KEYWORDS_AS_IDENTIFIERS;

const AST = @import("../ast.zig");
const Parser = @import("../parser.zig");
const ParserError = @import("../parser.zig").ParserError;
const StringId = @import("../string_interner.zig").StringId;
const diagnostics = @import("../diagnostics.zig");

const parseAssignment = @import("binary.zig").parseAssignment;
const expectAssignment = @import("binary.zig").expectAssignment;
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
const expectExpression = @import("expressions.zig").expectExpression;

const snap = @import("../tests/snapshots.zig").snap;
const TestParser = @import("../tests/test_parser.zig");
const Marker = TestParser.Marker;

const expectEqual = std.testing.expectEqual;
const expectEqualDeep = std.testing.expectEqualDeep;
const expectEqualStrings = std.testing.expectEqualStrings;
const expectError = std.testing.expectError;

pub fn parsePrimaryExpression(parser: *Parser) ParserError!?AST.Node.Index {
    return try parseIdentifier(parser) orelse
        try parseLiteral(parser) orelse
        try parseArrayLiteral(parser) orelse
        try parseObjectLiteral(parser) orelse
        try parseFunctionStatement(parser) orelse
        try parseAsyncFunctionStatement(parser) orelse
        try parseClassStatement(parser) orelse
        try parseGroupingExpression(parser) orelse
        try parseRegexLiteral(parser) orelse
        try parseTemplateLiteral(parser);
}

pub fn parseIdentifier(parser: *Parser) ParserError!?AST.Node.Index {
    const identifier = parser.consumeOrNull(TokenType.Identifier) orelse
        parseKeywordAsIdentifier(parser) orelse
        return null;

    return parser.addNode(identifier, AST.Node{ .simple_value = .{ .kind = .identifier, .id = parser.internStr(identifier) } });
}

pub fn expectIdentifier(parser: *Parser) ParserError!AST.Node.Index {
    return try parseIdentifier(parser) orelse parser.fail(diagnostics.identifier_expected, .{});
}

pub fn parseKeywordAsIdentifier(parser: *Parser) ?Token.Index {
    if (parser.peekMatchMany(.{ TokenType.Async, TokenType.Function })) {
        return null;
    }

    inline for (ALLOWED_KEYWORDS_AS_IDENTIFIERS) |keyword| {
        if (parser.consumeOrNull(keyword)) |tok| {
            return tok;
        }
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
        const main_token = parser.cur_token;
        if (parser.match(literal[0])) {
            return parser.addNode(main_token, AST.Node{ .simple_value = .{ .kind = literal[1], .id = parser.internStr(main_token) } });
        }
    }

    return null;
}

pub fn parseArrayLiteral(parser: *Parser) ParserError!?AST.Node.Index {
    if (!parser.match(TokenType.OpenSquareBracket)) {
        return null;
    }

    const main_token = parser.cur_token.dec(1);
    var values = std.ArrayList(AST.Node.Index).init(parser.gpa);
    defer values.deinit();

    while (true) {
        while (parser.match(TokenType.Comma)) {
            try values.append(AST.Node.Empty);
        }

        if (parser.match(TokenType.CloseSquareBracket)) {
            break;
        }

        try values.append(try parseSpreadExpression(parser) orelse try expectAssignment(parser));
        const comma = parser.consumeOrNull(TokenType.Comma);

        if (parser.match(TokenType.CloseSquareBracket)) {
            break;
        } else if (comma == null) {
            return parser.fail(diagnostics.ARG_expected, .{","});
        }
    }

    return parser.addNode(main_token, AST.Node{
        .array_literal = values.items,
    });
}

pub fn parseObjectLiteral(parser: *Parser) ParserError!?AST.Node.Index {
    if (!parser.match(TokenType.OpenCurlyBrace)) {
        return null;
    }

    const main_token = parser.cur_token.dec(1);
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

    return parser.addNode(main_token, AST.Node{
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

    const main_token = parser.cur_token;
    const identifier = try parseObjectElementName(parser);

    if (identifier == null) {
        return null;
    }

    if (parser.match(TokenType.Colon)) {
        return parser.addNode(main_token, AST.Node{
            .object_literal_field = .{
                .left = identifier.?,
                .right = try expectAssignment(parser),
            },
        });
    } else if (parser.peekMatch(TokenType.Comma) or parser.peekMatch(TokenType.CloseCurlyBrace)) {
        return parser.addNode(main_token, AST.Node{
            .object_literal_field_shorthand = identifier.?,
        });
    }

    return null;
}

pub fn parseSpreadExpression(parser: *Parser) ParserError!?AST.Node.Index {
    if (!parser.match(TokenType.DotDotDot)) {
        return null;
    }

    return parser.addNode(parser.cur_token.dec(1), AST.Node{
        .spread = try expectAssignment(parser),
    });
}

pub fn parseGroupingExpression(parser: *Parser) ParserError!?AST.Node.Index {
    if (parser.match(TokenType.OpenParen)) {
        const node = parser.addNode(parser.cur_token.dec(1), AST.Node{
            .grouping = try expectExpression(parser),
        });

        _ = try parser.consume(TokenType.CloseParen, diagnostics.ARG_expected, .{")"});
        return node;
    }

    return null;
}

pub fn parseTemplateLiteral(parser: *Parser) ParserError!?AST.Node.Index {
    const main_token = parser.cur_token;
    var list = std.ArrayList(AST.Node.Index).init(parser.gpa);
    defer list.deinit();

    if (parser.consumeOrNull(TokenType.TemplateNoSubstitution)) |tok| {
        try list.append(parser.addNode(tok, AST.Node{ .template_part = parser.internStr(tok) }));

        return parser.addNode(main_token, AST.Node{
            .template_literal = list.items,
        });
    }

    const head = parser.consumeOrNull(TokenType.TemplateHead) orelse return null;

    try list.append(parser.addNode(head, AST.Node{ .template_part = parser.internStr(head) }));
    while (true) {
        parser.unsetContext(.template);
        try list.append(try expectExpression(parser));

        parser.setContext(.template);
        if (parser.consumeOrNull(TokenType.TemplateTail)) |tok| {
            try list.append(parser.addNode(tok, AST.Node{ .template_part = parser.internStr(tok) }));
            break;
        }

        const tok = try parser.consume(TokenType.TemplateMiddle, diagnostics.ARG_expected, .{"}"});

        try list.append(parser.addNode(tok, AST.Node{ .template_part = parser.internStr(tok) }));
    }

    parser.unsetContext(.template);
    return parser.addNode(main_token, AST.Node{
        .template_literal = list.items,
    });
}

pub fn parseRegexLiteral(parser: *Parser) ParserError!?AST.Node.Index {
    parser.setContext(.regex);
    defer parser.unsetContext(.regex);

    const literal = parser.consumeOrNull(TokenType.RegexLiteral) orelse return null;
    return parser.addNode(literal, AST.Node{ .simple_value = .{ .kind = .regex, .id = parser.internStr(literal) } });
}

test "should parse primary expression" {
    const test_cases = .{
        .{
            \\ this
            \\>^   
            ,
            snap(@src(),
                \\ast.Node{
                \\    .simple_value = ast.Node.SimpleValue{
                \\        .kind = ast.SimpleValueKind.this,
                \\        .id = string_interner.StringId(1),
                \\    },
                \\}
            ),
        },
        .{
            \\ identifier
            \\>^         
            ,
            snap(@src(),
                \\ast.Node{
                \\    .simple_value = ast.Node.SimpleValue{
                \\        .kind = ast.SimpleValueKind.identifier,
                \\        .id = string_interner.StringId(1),
                \\    },
                \\}
            ),
        },
        .{
            \\ 123
            \\>^  
            ,
            snap(@src(),
                \\ast.Node{
                \\    .simple_value = ast.Node.SimpleValue{
                \\        .kind = ast.SimpleValueKind.number,
                \\        .id = string_interner.StringId(1),
                \\    },
                \\}
            ),
        },
        .{
            \\ {a: 1}
            \\>^     
            ,
            snap(@src(),
                \\ast.Node{
                \\    .object_literal = [_]ast.Node.Index{
                \\        ast.Node.Index(2)
                \\    },
                \\}
            ),
        },
        .{
            \\ [1, 2]
            \\>^     
            ,
            snap(@src(),
                \\ast.Node{
                \\    .array_literal = [_]ast.Node.Index{
                \\        ast.Node.Index(0), 
                \\        ast.Node.Index(1)
                \\    },
                \\}
            ),
        },
        .{
            \\ function() {}
            \\>^
            ,
            snap(@src(),
                \\ast.Node{
                \\    .function_decl = ast.Node.FunctionDeclaration{
                \\        .flags = 0,
                \\        .name = string_interner.StringId.none,
                \\        .params = [_]ast.Node.Index{},
                \\        .body = ast.Node.Index(0),
                \\        .return_type = ast.Node.Index.empty,
                \\    },
                \\}
            ),
        },
        .{
            \\ function*() {}
            \\>^
            ,
            snap(@src(),
                \\ast.Node{
                \\    .function_decl = ast.Node.FunctionDeclaration{
                \\        .flags = 2,
                \\        .name = string_interner.StringId.none,
                \\        .params = [_]ast.Node.Index{},
                \\        .body = ast.Node.Index(0),
                \\        .return_type = ast.Node.Index.empty,
                \\    },
                \\}
            ),
        },
        .{
            \\ async function() {}
            \\>^
            ,
            snap(@src(),
                \\ast.Node{
                \\    .function_decl = ast.Node.FunctionDeclaration{
                \\        .flags = 1,
                \\        .name = string_interner.StringId.none,
                \\        .params = [_]ast.Node.Index{},
                \\        .body = ast.Node.Index(0),
                \\        .return_type = ast.Node.Index.empty,
                \\    },
                \\}
            ),
        },
        .{
            \\ async function*() {}
            \\>^
            ,
            snap(@src(),
                \\ast.Node{
                \\    .function_decl = ast.Node.FunctionDeclaration{
                \\        .flags = 3,
                \\        .name = string_interner.StringId.none,
                \\        .params = [_]ast.Node.Index{},
                \\        .body = ast.Node.Index(0),
                \\        .return_type = ast.Node.Index.empty,
                \\    },
                \\}
            ),
        },
        .{
            \\ (a, b)
            \\>^
            ,
            snap(@src(),
                \\ast.Node{
                \\    .grouping = ast.Node.Index(2),
                \\}
            ),
        },
        .{
            \\ class {}
            \\>^       
            ,
            snap(@src(),
                \\ast.Node{
                \\    .class = ast.Node.ClassDeclaration{
                \\        .abstract = false,
                \\        .name = string_interner.StringId.none,
                \\        .super_class = ast.Node.Index.empty,
                \\        .implements = [_]string_interner.StringId{},
                \\        .body = [_]ast.Node.Index{},
                \\    },
                \\}
            ),
        },
        .{
            \\ /[a-z]/
            \\>^
            ,
            snap(@src(),
                \\ast.Node{
                \\    .simple_value = ast.Node.SimpleValue{
                \\        .kind = ast.SimpleValueKind.regex,
                \\        .id = string_interner.StringId(1),
                \\    },
                \\}
            ),
        },
        .{
            \\ `aaaa`
            \\>^
            ,
            snap(@src(),
                \\ast.Node{
                \\    .template_literal = [_]ast.Node.Index{
                \\        ast.Node.Index(0)
                \\    },
                \\}
            ),
        },
    };

    inline for (test_cases) |test_case| {
        const t, const node, const markers = try TestParser.run(test_case[0], parsePrimaryExpression);
        defer t.deinit();

        try t.expectASTSnapshot(node, test_case[1]);
        try t.expectTokenAt(markers[0], node.?);
    }
}

test "should parse identifier" {
    const test_cases = .{
        .{
            \\ identifier
            \\>^
            ,
        },
        .{
            \\ $identifier
            \\>^
            ,
        },
        .{
            \\ _identifier
            \\>^
            ,
        },
        .{
            \\ \u00FFidentifier
            \\>^
            ,
        },
        .{
            \\ \u{FF}identifier
            \\>^
            ,
        },
    };

    inline for (test_cases) |test_case| {
        const t, const node, const markers = try TestParser.run(test_case[0], parseIdentifier);
        defer t.deinit();

        try t.expectAST(node, AST.Node{ .simple_value = .{ .kind = .identifier, .id = StringId.at(1) } });
        try t.expectToken(TokenType.Identifier, std.mem.sliceTo(test_case[0][1..], '\n'), node.?);
        try t.expectTokenAt(markers[0], node.?);
    }
}

test "should parse allowed keyword as identifier" {
    const text =
        \\ abstract
        \\>^
    ;

    const t, const node, const markers = try TestParser.run(text, parseIdentifier);
    defer t.deinit();

    try t.expectASTSnapshot(node, snap(@src(),
        \\ast.Node{
        \\    .simple_value = ast.Node.SimpleValue{
        \\        .kind = ast.SimpleValueKind.identifier,
        \\        .id = string_interner.StringId(1),
        \\    },
        \\}
    ));
    try t.expectToken(TokenType.Abstract, "abstract", node.?);
    try t.expectTokenAt(markers[0], node.?);
}

test "should return null if no identifier" {
    const text =
        \\123
    ;

    const t, const node, _ = try TestParser.run(text, parseIdentifier);
    defer t.deinit();

    try t.expectAST(node, null);
}

test "should return null if not allowed keyword" {
    const text =
        \\break
    ;

    const t, const node, _ = try TestParser.run(text, parseIdentifier);
    defer t.deinit();

    try t.expectAST(node, null);
}

test "should parse literal" {
    const test_cases = .{
        .{
            \\ this
            \\>^   
            ,
            AST.SimpleValueKind.this,
            TokenType.This,
            "this",
        },
        .{
            \\ null
            \\>^   
            ,
            AST.SimpleValueKind.null,
            TokenType.Null,
            "null",
        },
        .{
            \\ undefined
            \\>^   
            ,
            AST.SimpleValueKind.undefined,
            TokenType.Undefined,
            "undefined",
        },
        .{
            \\ true
            \\>^   
            ,
            AST.SimpleValueKind.true,
            TokenType.True,
            "true",
        },
        .{
            \\ false
            \\>^   
            ,
            AST.SimpleValueKind.false,
            TokenType.False,
            "false",
        },
        .{
            \\ 123
            \\>^  
            ,
            AST.SimpleValueKind.number,
            TokenType.NumberConstant,
            "123",
        },
        .{
            \\ 123n
            \\>^   
            ,
            AST.SimpleValueKind.bigint,
            TokenType.BigIntConstant,
            "123n",
        },
        .{
            \\ "hello"
            \\>^      
            ,
            AST.SimpleValueKind.string,
            TokenType.StringConstant,
            "\"hello\"",
        },
    };

    inline for (test_cases) |test_case| {
        const t, const node, const markers = try TestParser.run(test_case[0], parseLiteral);
        defer t.deinit();

        try t.expectAST(node, AST.Node{
            .simple_value = .{
                .kind = test_case[1],
                .id = StringId.at(1),
            },
        });
        try t.expectToken(test_case[2], test_case[3], node.?);
        try t.expectTokenAt(markers[0], node.?);
    }
}

test "should return null if no literal" {
    const text =
        \\identifier
    ;

    const t, const node, _ = try TestParser.run(text, parseLiteral);
    defer t.deinit();

    try t.expectAST(node, null);
}

test "should return null if not array literal" {
    const text =
        \\1
    ;

    const t, const node, _ = try TestParser.run(text, parseArrayLiteral);
    defer t.deinit();

    try t.expectAST(node, null);
}

test "should parse array literal" {
    const expects_map = .{
        .{
            "[,]",
            snap(@src(),
                \\ast.Node{
                \\    .array_literal = [_]ast.Node.Index{
                \\        ast.Node.Index.empty
                \\    },
                \\}
            ),
        },
        .{
            "[, 1 + 2]",
            snap(@src(),
                \\ast.Node{
                \\    .array_literal = [_]ast.Node.Index{
                \\        ast.Node.Index.empty, 
                \\        ast.Node.Index(2)
                \\    },
                \\}
            ),
        },
        .{
            "[1, 2, 3]",
            snap(@src(),
                \\ast.Node{
                \\    .array_literal = [_]ast.Node.Index{
                \\        ast.Node.Index(0), 
                \\        ast.Node.Index(1), 
                \\        ast.Node.Index(2)
                \\    },
                \\}
            ),
        },
        .{
            "[1, 2, 3,]",
            snap(@src(),
                \\ast.Node{
                \\    .array_literal = [_]ast.Node.Index{
                \\        ast.Node.Index(0), 
                \\        ast.Node.Index(1), 
                \\        ast.Node.Index(2)
                \\    },
                \\}
            ),
        },
        .{
            "[1, 2, 3, 4,]",
            snap(@src(),
                \\ast.Node{
                \\    .array_literal = [_]ast.Node.Index{
                \\        ast.Node.Index(0), 
                \\        ast.Node.Index(1), 
                \\        ast.Node.Index(2), 
                \\        ast.Node.Index(3)
                \\    },
                \\}
            ),
        },
        .{
            "[1,,,]",
            snap(@src(),
                \\ast.Node{
                \\    .array_literal = [_]ast.Node.Index{
                \\        ast.Node.Index(0), 
                \\        ast.Node.Index.empty, 
                \\        ast.Node.Index.empty
                \\    },
                \\}
            ),
        },
        .{
            "[...a]",
            snap(@src(),
                \\ast.Node{
                \\    .array_literal = [_]ast.Node.Index{
                \\        ast.Node.Index(1)
                \\    },
                \\}
            ),
        },
        .{
            "[1, ...a]",
            snap(@src(),
                \\ast.Node{
                \\    .array_literal = [_]ast.Node.Index{
                \\        ast.Node.Index(0), 
                \\        ast.Node.Index(2)
                \\    },
                \\}
            ),
        },
    };

    inline for (expects_map) |expected_items| {
        const t, const node, _ = try TestParser.run(expected_items[0], parseArrayLiteral);
        defer t.deinit();

        try t.expectASTSnapshot(node, expected_items[1]);
    }
}

test "should return null if not object literal" {
    const text =
        \\1
    ;

    const t, const node, _ = try TestParser.run(text, parseObjectLiteral);
    defer t.deinit();

    try t.expectAST(node, null);
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

    const t, const node, _ = try TestParser.run(text, parseObjectLiteral);
    defer t.deinit();

    try t.expectASTSnapshot(node, snap(@src(),
        \\ast.Node{
        \\    .object_literal = [_]ast.Node.Index{
        \\        ast.Node.Index(2), 
        \\        ast.Node.Index(5), 
        \\        ast.Node.Index(7), 
        \\        ast.Node.Index(9), 
        \\        ast.Node.Index(15)
        \\    },
        \\}
    ));
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

    const t, const node, _ = try TestParser.run(text, parseObjectLiteral);
    defer t.deinit();

    var expected_fields = [_]AST.Node.Index{ AST.Node.at(2), AST.Node.at(5), AST.Node.at(8), AST.Node.at(11), AST.Node.at(14), AST.Node.at(18) };
    try t.expectAST(node, AST.Node{ .object_literal = &expected_fields });
    try expectEqualStrings("object_literal", @tagName(t.getNode(node.?)));
    try expectEqual(6, t.getNode(node.?).object_literal.len);

    const expected_methods = .{
        .{ AST.FunctionFlags.None, "a" },
        .{ AST.FunctionFlags.Async, "b" },
        .{ AST.FunctionFlags.Generator, "c" },
        .{ AST.FunctionFlags.Async | AST.FunctionFlags.Generator, "d" },
        .{ AST.FunctionFlags.Getter, "e" },
        .{ AST.FunctionFlags.Setter, "e" },
    };

    inline for (expected_methods, 0..) |expected_method, i| {
        try t.expectSimpleMethod(t.getNode(node.?).object_literal[i], expected_method[0], expected_method[1]);
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

    const t, const nodeOrError, _ = try TestParser.runCatch(text, parseObjectLiteral);
    defer t.deinit();

    try t.expectSyntaxError(nodeOrError, diagnostics.ARG_expected, .{","});
}

test "should fail parsing object literal if field name is invalid" {
    const test_cases = .{ "{ - }", "{ a - b }" };

    inline for (test_cases) |test_case| {
        const t, const nodeOrError, _ = try TestParser.runCatch(test_case, parseObjectLiteral);
        defer t.deinit();

        try t.expectSyntaxError(nodeOrError, diagnostics.property_assignment_expected, .{});
    }
}

test "should fail parsing object literal if there is multiple closing commas" {
    const text =
        \\{
        \\    a: 1,,
        \\}
    ;

    const t, const nodeOrError, _ = try TestParser.runCatch(text, parseObjectLiteral);
    defer t.deinit();

    try t.expectSyntaxError(nodeOrError, diagnostics.property_assignment_expected, .{});
}

test "should parse grouping expression" {
    const text = "(a, b)";

    const t, const node, _ = try TestParser.run(text, parseGroupingExpression);
    defer t.deinit();

    try t.expectASTSnapshot(node, snap(@src(),
        \\ast.Node{
        \\    .grouping = ast.Node.Index(2),
        \\}
    ));
}

test "should parse template literal with no substitution" {
    const text =
        \\ `aaaaaa`
        \\>^
    ;

    const t, const node, const markers = try TestParser.run(text, parseTemplateLiteral);
    defer t.deinit();

    try t.expectASTSnapshot(node, snap(@src(),
        \\ast.Node{
        \\    .template_literal = [_]ast.Node.Index{
        \\        ast.Node.Index(0)
        \\    },
        \\}
    ));
    try t.expectTokenAt(markers[0], node.?);
}

test "should parse template literal" {
    const text =
        \\ `a${b}c`
        \\>^
    ;

    const t, const node, const markers = try TestParser.run(text, parseTemplateLiteral);
    defer t.deinit();

    try t.expectASTSnapshot(node, snap(@src(),
        \\ast.Node{
        \\    .template_literal = [_]ast.Node.Index{
        \\        ast.Node.Index(0), 
        \\        ast.Node.Index(1), 
        \\        ast.Node.Index(2)
        \\    },
        \\}
    ));
    try t.expectTokenAt(markers[0], node.?);

    try t.expectASTSnapshot(t.parser.getNode(node.?).template_literal[0], snap(@src(),
        \\ast.Node{
        \\    .template_part = string_interner.StringId(1),
        \\}
    ));
    try t.expectASTSnapshot(t.parser.getNode(node.?).template_literal[1], snap(@src(),
        \\ast.Node{
        \\    .simple_value = ast.Node.SimpleValue{
        \\        .kind = ast.SimpleValueKind.identifier,
        \\        .id = string_interner.StringId(2),
        \\    },
        \\}
    ));
    try t.expectASTSnapshot(t.parser.getNode(node.?).template_literal[2], snap(@src(),
        \\ast.Node{
        \\    .template_part = string_interner.StringId(3),
        \\}
    ));
}

test "should parse template literal with multiple substitutions" {
    const text =
        \\ `a${b}c${d}e`
        \\>^
    ;

    const t, const node, const markers = try TestParser.run(text, parseTemplateLiteral);
    defer t.deinit();

    try t.expectASTSnapshot(node, snap(@src(),
        \\ast.Node{
        \\    .template_literal = [_]ast.Node.Index{
        \\        ast.Node.Index(0), 
        \\        ast.Node.Index(1), 
        \\        ast.Node.Index(2), 
        \\        ast.Node.Index(3), 
        \\        ast.Node.Index(4)
        \\    },
        \\}
    ));
    try t.expectTokenAt(markers[0], node.?);
}

test "should parse template literal with object as substitution" {
    const text =
        \\ `a${{a: 1}}e`
        \\>^
    ;

    const t, const node, const markers = try TestParser.run(text, parseTemplateLiteral);
    defer t.deinit();

    try t.expectASTSnapshot(node, snap(@src(),
        \\ast.Node{
        \\    .template_literal = [_]ast.Node.Index{
        \\        ast.Node.Index(0), 
        \\        ast.Node.Index(4), 
        \\        ast.Node.Index(5)
        \\    },
        \\}
    ));
    try t.expectTokenAt(markers[0], node.?);

    try t.expectASTSnapshot(t.parser.getNode(node.?).template_literal[0], snap(@src(),
        \\ast.Node{
        \\    .template_part = string_interner.StringId(1),
        \\}
    ));
    try t.expectASTSnapshot(t.parser.getNode(node.?).template_literal[1], snap(@src(),
        \\ast.Node{
        \\    .object_literal = [_]ast.Node.Index{
        \\        ast.Node.Index(3)
        \\    },
        \\}
    ));
    try t.expectASTSnapshot(t.parser.getNode(node.?).template_literal[2], snap(@src(),
        \\ast.Node{
        \\    .template_part = string_interner.StringId(4),
        \\}
    ));
}

test "should return syntax error if substitution is unclosed" {
    const text =
        \\ `a${b
        \\>     ^
    ;

    const t, const nodeOrError, const markers = try TestParser.runCatch(text, parseTemplateLiteral);
    defer t.deinit();

    try t.expectSyntaxErrorAt(nodeOrError, diagnostics.ARG_expected, .{"}"}, markers[0]);
}

test "should return null if no grouping expression" {
    const text =
        \\1
    ;

    const t, const node, _ = try TestParser.run(text, parseGroupingExpression);
    defer t.deinit();

    try t.expectAST(node, null);
}
