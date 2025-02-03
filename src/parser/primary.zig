const std = @import("std");

const Token = @import("../consts.zig").Token;
const TokenType = @import("../consts.zig").TokenType;
const isAllowedIdentifier = @import("../consts.zig").isAllowedIdentifier;
const ALLOWED_KEYWORDS_AS_IDENTIFIERS = @import("../consts.zig").ALLOWED_KEYWORDS_AS_IDENTIFIERS;

const AST = @import("../ast.zig");
const Parser = @import("../parser.zig");
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

const CompilationError = @import("../consts.zig").CompilationError;

const Marker = @import("../test_parser.zig").Marker;
const MarkerList = @import("../test_parser.zig").MarkerList;
const TestParser = @import("../test_parser.zig");

const expectEqual = std.testing.expectEqual;
const expectEqualDeep = std.testing.expectEqualDeep;
const expectEqualStrings = std.testing.expectEqualStrings;
const expectError = std.testing.expectError;

pub fn parsePrimaryExpression(parser: *Parser) CompilationError!?AST.Node.Index {
    return try parseIdentifier(parser) orelse
        try parseLiteral(parser) orelse
        try parseArrayLiteral(parser) orelse
        try parseObjectLiteral(parser) orelse
        try parseFunctionStatement(parser) orelse
        try parseAsyncFunctionStatement(parser) orelse
        try parseClassStatement(parser) orelse
        try parseGroupingExpression(parser) orelse
        try parseTemplateLiteral(parser);
}

pub fn parseIdentifier(parser: *Parser) CompilationError!?AST.Node.Index {
    const identifier = parser.consumeOrNull(TokenType.Identifier) orelse
        parseKeywordAsIdentifier(parser) orelse
        return null;

    return parser.addNode(identifier, AST.Node{ .simple_value = .{ .kind = .identifier } });
}

pub fn expectIdentifier(parser: *Parser) CompilationError!AST.Node.Index {
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

pub fn parseLiteral(parser: *Parser) CompilationError!?AST.Node.Index {
    inline for (literal_map) |literal| {
        if (parser.match(literal[0])) {
            return parser.addNode(parser.cur_token.dec(1), AST.Node{ .simple_value = .{ .kind = literal[1] } });
        }
    }

    return null;
}

pub fn parseArrayLiteral(parser: *Parser) CompilationError!?AST.Node.Index {
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

pub fn parseObjectLiteral(parser: *Parser) CompilationError!?AST.Node.Index {
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

pub fn parseObjectField(parser: *Parser) CompilationError!?AST.Node.Index {
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

pub fn parseSpreadExpression(parser: *Parser) CompilationError!?AST.Node.Index {
    if (!parser.match(TokenType.DotDotDot)) {
        return null;
    }

    return parser.addNode(parser.cur_token.dec(1), AST.Node{
        .spread = try expectAssignment(parser),
    });
}

pub fn parseGroupingExpression(parser: *Parser) CompilationError!?AST.Node.Index {
    if (parser.match(TokenType.OpenParen)) {
        const node = parser.addNode(parser.cur_token.dec(1), AST.Node{
            .grouping = try expectExpression(parser),
        });

        _ = try parser.consume(TokenType.CloseParen, diagnostics.ARG_expected, .{")"});
        return node;
    }

    return null;
}

pub fn parseTemplateLiteral(parser: *Parser) CompilationError!?AST.Node.Index {
    const main_token = parser.cur_token;
    var list = std.ArrayList(AST.Node.Index).init(parser.gpa);
    defer list.deinit();

    if (parser.consumeOrNull(TokenType.TemplateNoSubstitution)) |tok| {
        try list.append(parser.addNode(tok, AST.Node{ .template_part = tok }));

        return parser.addNode(main_token, AST.Node{
            .template_literal = list.items,
        });
    }

    const head = parser.consumeOrNull(TokenType.TemplateHead) orelse return null;

    try list.append(parser.addNode(head, AST.Node{ .template_part = head }));
    while (true) {
        parser.unsetContext(.template);
        try list.append(try expectExpression(parser));

        parser.setContext(.template);
        if (parser.consumeOrNull(TokenType.TemplateTail)) |tok| {
            try list.append(parser.addNode(tok, AST.Node{ .template_part = tok }));
            break;
        }

        const tok = try parser.consume(TokenType.TemplateMiddle, diagnostics.ARG_expected, .{"}"});

        try list.append(parser.addNode(tok, AST.Node{ .template_part = tok }));
    }

    parser.unsetContext(.template);
    return parser.addNode(main_token, AST.Node{
        .template_literal = list.items,
    });
}

test "should parse primary expression" {
    const test_cases = .{
        .{
            \\ this
            \\>^   
            ,
            AST.Node{ .simple_value = .{ .kind = .this } },
        },
        .{
            \\ identifier
            \\>^         
            ,
            AST.Node{ .simple_value = .{ .kind = .identifier } },
        },
        .{
            \\ 123
            \\>^  
            ,
            AST.Node{ .simple_value = .{ .kind = .number } },
        },
        .{
            \\ {a: 1}
            \\>^     
            ,
            AST.Node{ .object_literal = @constCast(&[_]AST.Node.Index{AST.Node.at(3)}) },
        },
        .{
            \\ [1, 2]
            \\>^     
            ,
            AST.Node{ .array_literal = @constCast(&[_]AST.Node.Index{ AST.Node.at(1), AST.Node.at(2) }) },
        },
        .{
            \\ function() {}
            \\>^
            ,
            AST.Node{ .function_decl = .{ .flags = AST.FunctionFlags.None, .name = Token.Empty, .params = &.{}, .body = AST.Node.at(1), .return_type = AST.Node.Empty } },
        },
        .{
            \\ function*() {}
            \\>^
            ,
            AST.Node{ .function_decl = .{ .flags = AST.FunctionFlags.Generator, .name = Token.Empty, .params = &.{}, .body = AST.Node.at(1), .return_type = AST.Node.Empty } },
        },
        .{
            \\ async function() {}
            \\>^
            ,
            AST.Node{ .function_decl = .{ .flags = AST.FunctionFlags.Async, .name = Token.Empty, .params = &.{}, .body = AST.Node.at(1), .return_type = AST.Node.Empty } },
        },
        .{
            \\ async function*() {}
            \\>^
            ,
            AST.Node{ .function_decl = .{
                .flags = AST.FunctionFlags.Async | AST.FunctionFlags.Generator,
                .name = Token.Empty,
                .params = &.{},
                .body = AST.Node.at(1),
                .return_type = AST.Node.Empty,
            } },
        },
        .{
            \\ (a, b)
            \\>^
            ,
            AST.Node{ .grouping = AST.Node.at(3) },
        },
        .{
            \\ class {}
            \\>^       
            ,
            AST.Node{ .class = .{ .abstract = false, .name = Token.Empty, .implements = &.{}, .super_class = AST.Node.Empty, .body = &.{} } },
        },
        .{
            \\ `aaaa`
            \\>^
            ,
            AST.Node{ .template_literal = @constCast(&[_]AST.Node.Index{AST.Node.at(1)}) },
        },
    };

    inline for (test_cases) |test_case| {
        try TestParser.run(test_case[0], parsePrimaryExpression, struct {
            pub fn expect(t: TestParser, node: ?AST.Node.Index, comptime markers: MarkerList(test_case[0])) !void {
                try t.expectAST(node, test_case[1]);
                try t.expectTokenAt(markers[0], node.?);
            }
        });
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
        try TestParser.run(test_case[0], parseIdentifier, struct {
            pub fn expect(t: TestParser, node: ?AST.Node.Index, comptime markers: MarkerList(test_case[0])) !void {
                try t.expectAST(node, AST.Node{ .simple_value = .{ .kind = .identifier } });
                try t.expectToken(TokenType.Identifier, std.mem.sliceTo(test_case[0][1..], '\n'), node.?);
                try t.expectTokenAt(markers[0], node.?);
            }
        });
    }
}

test "should parse allowed keyword as identifier" {
    const text =
        \\ abstract
        \\>^
    ;

    try TestParser.run(text, parseIdentifier, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, comptime markers: MarkerList(text)) !void {
            try t.expectAST(node, AST.Node{ .simple_value = .{ .kind = .identifier } });
            try t.expectToken(TokenType.Abstract, "abstract", node.?);
            try t.expectTokenAt(markers[0], node.?);
        }
    });
}

test "should return null if no identifier" {
    const text =
        \\123
    ;

    try TestParser.run(text, parseIdentifier, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectAST(node, null);
        }
    });
}

test "should return null if not allowed keyword" {
    const text =
        \\break
    ;

    try TestParser.run(text, parseIdentifier, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectAST(node, null);
        }
    });
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
        try TestParser.run(test_case[0], parseLiteral, struct {
            pub fn expect(t: TestParser, node: ?AST.Node.Index, comptime markers: MarkerList(test_case[0])) !void {
                try t.expectAST(node, AST.Node{ .simple_value = .{ .kind = test_case[1] } });
                try t.expectToken(test_case[2], test_case[3], node.?);
                try t.expectTokenAt(markers[0], node.?);
            }
        });
    }
}

test "should return null if no literal" {
    const text =
        \\identifier
    ;

    try TestParser.run(text, parseLiteral, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectAST(node, null);
        }
    });
}

test "should return null if not array literal" {
    const text =
        \\1
    ;

    try TestParser.run(text, parseArrayLiteral, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectAST(node, null);
        }
    });
}

test "should parse array literal" {
    const expects_map = .{
        .{ "[,]", &[_]AST.Node.Index{AST.Node.Empty} },
        .{ "[, 1 + 2]", &[_]AST.Node.Index{ AST.Node.Empty, AST.Node.at(3) } },
        .{ "[1, 2, 3]", &[_]AST.Node.Index{ AST.Node.at(1), AST.Node.at(2), AST.Node.at(3) } },
        .{ "[1, 2, 3,]", &[_]AST.Node.Index{ AST.Node.at(1), AST.Node.at(2), AST.Node.at(3) } },
        .{ "[1, 2, 3 + 4,]", &[_]AST.Node.Index{ AST.Node.at(1), AST.Node.at(2), AST.Node.at(5) } },
        .{ "[1,,,]", &[_]AST.Node.Index{ AST.Node.at(1), AST.Node.Empty, AST.Node.Empty } },
        .{ "[...a]", &[_]AST.Node.Index{AST.Node.at(2)} },
        .{ "[1, ...a]", &[_]AST.Node.Index{ AST.Node.at(1), AST.Node.at(3) } },
    };

    inline for (expects_map) |expected_items| {
        try TestParser.run(expected_items[0], parseArrayLiteral, struct {
            pub fn expect(t: TestParser, node: ?AST.Node.Index, _: MarkerList(expected_items[0])) !void {
                try t.expectAST(node, AST.Node{ .array_literal = @constCast(expected_items[1]) });
            }
        });
    }
}

test "should return null if not object literal" {
    const text =
        \\1
    ;

    try TestParser.run(text, parseObjectLiteral, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectAST(node, null);
        }
    });
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
    const expected_fields = [_]AST.Node.Index{ AST.Node.at(3), AST.Node.at(6), AST.Node.at(8), AST.Node.at(10), AST.Node.at(16) };

    try TestParser.run(text, parseObjectLiteral, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectAST(node, AST.Node{ .object_literal = @constCast(&expected_fields) });
        }
    });
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

    try TestParser.run(text, parseObjectLiteral, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, _: MarkerList(text)) !void {
            var expected_fields = [_]AST.Node.Index{ AST.Node.at(3), AST.Node.at(6), AST.Node.at(9), AST.Node.at(12), AST.Node.at(15), AST.Node.at(19) };
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
    });
}

test "should fail parsing object literal if comma is missing between fields" {
    const text =
        \\{
        \\    a: 1,
        \\    b: 2
        \\    c,
        \\}
    ;

    try TestParser.runAny(text, parseObjectLiteral, struct {
        pub fn expect(t: TestParser, nodeOrError: CompilationError!?AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectSyntaxError(nodeOrError, diagnostics.ARG_expected, .{","});
        }
    });
}

test "should fail parsing object literal if field name is invalid" {
    const test_cases = .{ "{ - }", "{ a - b }" };

    inline for (test_cases) |test_case| {
        try TestParser.runAny(test_case, parseObjectLiteral, struct {
            pub fn expect(t: TestParser, nodeOrError: CompilationError!?AST.Node.Index, _: MarkerList(test_case)) !void {
                try t.expectSyntaxError(nodeOrError, diagnostics.property_assignment_expected, .{});
            }
        });
    }
}

test "should fail parsing object literal if there is multiple closing commas" {
    const text =
        \\{
        \\    a: 1,,
        \\}
    ;

    try TestParser.runAny(text, parseObjectLiteral, struct {
        pub fn expect(t: TestParser, nodeOrError: CompilationError!?AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectSyntaxError(nodeOrError, diagnostics.property_assignment_expected, .{});
        }
    });
}

test "should parse grouping expression" {
    const text = "(a, b)";

    try TestParser.run(text, parseGroupingExpression, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectAST(node, AST.Node{ .grouping = AST.Node.at(3) });
        }
    });
}

test "should parse template literal with no substitution" {
    const text =
        \\ `aaaaaa`
        \\>^
    ;

    try TestParser.run(text, parseTemplateLiteral, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, comptime markers: MarkerList(text)) !void {
            const expected_node = AST.Node{ .template_literal = @constCast(&[_]AST.Node.Index{AST.Node.at(1)}) };
            try t.expectAST(node, expected_node);
            try t.expectTokenAt(markers[0], node.?);
        }
    });
}

test "should parse template literal" {
    const text =
        \\ `a${b}c`
        \\>^
    ;

    try TestParser.run(text, parseTemplateLiteral, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, comptime markers: MarkerList(text)) !void {
            const expected_node = AST.Node{
                .template_literal = @constCast(&[_]AST.Node.Index{ AST.Node.at(1), AST.Node.at(2), AST.Node.at(3) }),
            };
            try t.expectAST(node, expected_node);
            try t.expectTokenAt(markers[0], node.?);

            try t.expectAST(expected_node.template_literal[0], AST.Node{ .template_part = Token.at(0) });
            try t.expectAST(expected_node.template_literal[1], AST.Node{ .simple_value = .{ .kind = .identifier } });
            try t.expectAST(expected_node.template_literal[2], AST.Node{ .template_part = Token.at(2) });
        }
    });
}

test "should parse template literal with multiple substitutions" {
    const text =
        \\ `a${b}c${d}e`
        \\>^
    ;

    try TestParser.run(text, parseTemplateLiteral, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, comptime markers: MarkerList(text)) !void {
            const expected_node = AST.Node{
                .template_literal = @constCast(&[_]AST.Node.Index{ AST.Node.at(1), AST.Node.at(2), AST.Node.at(3), AST.Node.at(4), AST.Node.at(5) }),
            };
            try t.expectAST(node, expected_node);
            try t.expectTokenAt(markers[0], node.?);
        }
    });
}

test "should parse template literal with object as substitution" {
    const text =
        \\ `a${{a: 1}}e`
        \\>^
    ;

    try TestParser.run(text, parseTemplateLiteral, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, comptime markers: MarkerList(text)) !void {
            const expected_node = AST.Node{
                .template_literal = @constCast(&[_]AST.Node.Index{ AST.Node.at(1), AST.Node.at(5), AST.Node.at(6) }),
            };
            try t.expectAST(node, expected_node);
            try t.expectTokenAt(markers[0], node.?);

            try t.expectAST(expected_node.template_literal[0], AST.Node{ .template_part = Token.at(0) });
            try t.expectAST(expected_node.template_literal[1], AST.Node{ .object_literal = @constCast(&[_]AST.Node.Index{AST.Node.at(4)}) });
            try t.expectAST(expected_node.template_literal[2], AST.Node{ .template_part = Token.at(6) });
        }
    });
}

test "should return syntax error if substitution is unclosed" {
    const text =
        \\ `a${b
        \\>     ^
    ;

    try TestParser.runAny(text, parseTemplateLiteral, struct {
        pub fn expect(t: TestParser, nodeOrError: CompilationError!?AST.Node.Index, comptime markers: MarkerList(text)) !void {
            try t.expectSyntaxErrorAt(nodeOrError, diagnostics.ARG_expected, .{"}"}, markers[0]);
        }
    });
}

test "should return null if no grouping expression" {
    const text =
        \\1
    ;

    try TestParser.run(text, parseGroupingExpression, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectAST(node, null);
        }
    });
}
