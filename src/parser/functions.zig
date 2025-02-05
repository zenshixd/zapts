const std = @import("std");

const Parser = @import("../parser.zig");
const ParserError = Parser.ParserError;

const AST = @import("../ast.zig");
const Token = @import("../consts.zig").Token;
const TokenType = @import("../consts.zig").TokenType;
const StringId = @import("../string_interner.zig").StringId;

const diagnostics = @import("../diagnostics.zig");

const parseAssignment = @import("binary.zig").parseAssignment;
const expectAssignment = @import("binary.zig").expectAssignment;
const parseKeywordAsIdentifier = @import("primary.zig").parseKeywordAsIdentifier;
const parseIdentifier = @import("primary.zig").parseIdentifier;
const parseOptionalDataType = @import("types.zig").parseOptionalDataType;
const parseBlock = @import("statements.zig").parseBlock;

const TestParser = @import("../test_parser.zig");
const MarkerList = @import("../test_parser.zig").MarkerList;
const Marker = @import("../test_parser.zig").Marker;

pub fn parseMethodAsyncGenerator(self: *Parser) ParserError!?AST.Node.Index {
    const main_token = self.cur_token;
    if (!self.match(TokenType.Async)) {
        return null;
    }

    return try parseMethodGeneratorExtra(self, main_token, AST.FunctionFlags.Async) orelse
        try parseMethodExtra(self, main_token, AST.FunctionFlags.Async);
}

pub fn parseMethodGenerator(self: *Parser) ParserError!?AST.Node.Index {
    const main_token = self.cur_token;
    return try parseMethodGeneratorExtra(self, main_token, AST.FunctionFlags.None);
}

pub fn parseMethodGeneratorExtra(self: *Parser, main_token: Token.Index, flags: u2) ParserError!?AST.Node.Index {
    if (!self.match(TokenType.Star)) {
        return null;
    }

    return try parseMethodExtra(self, main_token, flags | AST.FunctionFlags.Generator);
}

pub fn parseMethod(self: *Parser) ParserError!?AST.Node.Index {
    return try parseMethodExtra(self, self.cur_token, AST.FunctionFlags.None);
}

pub fn parseMethodExtra(self: *Parser, main_token: Token.Index, flags: u4) ParserError!?AST.Node.Index {
    const cur_token = self.checkpoint();
    const elem_name = try parseObjectElementName(self) orelse return null;

    if (!self.match(TokenType.OpenParen)) {
        self.rewindTo(cur_token);
        return null;
    }

    const args = try parseFunctionArguments(self);
    defer args.deinit();

    const return_type = try parseOptionalDataType(self);
    const body = try parseBlock(self) orelse return self.fail(diagnostics.ARG_expected, .{"{"});

    return self.addNode(main_token, AST.Node{ .object_method = .{
        .flags = flags,
        .name = elem_name,
        .params = args.items,
        .body = body,
        .return_type = return_type,
    } });
}

pub fn parseMethodGetter(self: *Parser) ParserError!?AST.Node.Index {
    const cp = self.checkpoint();
    if (!self.match(TokenType.Get)) {
        return null;
    }
    const elem_name = try parseObjectElementName(self) orelse {
        self.rewindTo(cp);
        return try parseMethod(self);
    };

    _ = try self.consume(TokenType.OpenParen, diagnostics.ARG_expected, .{"("});
    const args = try parseFunctionArguments(self);
    defer args.deinit();

    const return_type = try parseOptionalDataType(self);
    const body = try parseBlock(self) orelse return self.fail(diagnostics.ARG_expected, .{"{"});

    return self.addNode(cp.tok_idx, AST.Node{ .object_method = .{
        .flags = AST.FunctionFlags.Getter,
        .name = elem_name,
        .params = args.items,
        .body = body,
        .return_type = return_type,
    } });
}

pub fn parseMethodSetter(self: *Parser) ParserError!?AST.Node.Index {
    const cp = self.checkpoint();
    if (!self.match(TokenType.Set)) {
        return null;
    }
    const elem_name = try parseObjectElementName(self) orelse {
        self.rewindTo(cp);
        return try parseMethod(self);
    };

    _ = try self.consume(TokenType.OpenParen, diagnostics.ARG_expected, .{"("});
    const args = try parseFunctionArguments(self);
    defer args.deinit();

    const return_type = try parseOptionalDataType(self);
    const body = try parseBlock(self) orelse return self.fail(diagnostics.ARG_expected, .{"{"});

    return self.addNode(cp.tok_idx, AST.Node{ .object_method = .{
        .flags = AST.FunctionFlags.Setter,
        .name = elem_name,
        .params = args.items,
        .body = body,
        .return_type = return_type,
    } });
}

pub fn parseObjectElementName(self: *Parser) ParserError!?AST.Node.Index {
    const main_token = self.cur_token;
    if (self.match(TokenType.Identifier) or self.match(TokenType.PrivateIdentifier)) {
        return self.addNode(main_token, AST.Node{ .simple_value = .{ .kind = .identifier, .id = self.internStr(main_token) } });
    } else if (self.match(TokenType.StringConstant)) {
        return self.addNode(main_token, AST.Node{ .simple_value = .{ .kind = .string, .id = self.internStr(main_token) } });
    } else if (self.match(TokenType.NumberConstant)) {
        return self.addNode(main_token, AST.Node{ .simple_value = .{ .kind = .number, .id = self.internStr(main_token) } });
    } else if (self.match(TokenType.BigIntConstant)) {
        return self.addNode(main_token, AST.Node{ .simple_value = .{ .kind = .bigint, .id = self.internStr(main_token) } });
    } else if (self.match(TokenType.OpenSquareBracket)) {
        const node = try expectAssignment(self);
        _ = try self.consume(TokenType.CloseSquareBracket, diagnostics.ARG_expected, .{"]"});
        return self.addNode(main_token, AST.Node{ .computed_identifier = node });
    } else {
        if (parseKeywordAsIdentifier(self) != null) {
            return self.addNode(main_token, AST.Node{ .simple_value = .{ .kind = .identifier, .id = self.internStr(main_token) } });
        }
        return null;
    }
}

pub fn parseAsyncFunctionStatement(self: *Parser) ParserError!?AST.Node.Index {
    if (!self.match(TokenType.Async)) {
        return null;
    }

    return try parseFunctionStatementExtra(self, self.cur_token.dec(1), AST.FunctionFlags.Async) orelse self.fail(diagnostics.unexpected_keyword_or_identifier, .{});
}

pub fn parseFunctionStatement(self: *Parser) ParserError!?AST.Node.Index {
    return try parseFunctionStatementExtra(self, self.cur_token, AST.FunctionFlags.None);
}

pub fn parseFunctionStatementExtra(self: *Parser, main_token: Token.Index, flags: u4) ParserError!?AST.Node.Index {
    if (!self.match(TokenType.Function)) {
        return null;
    }

    var fn_flags = flags;
    if (self.match(TokenType.Star)) {
        fn_flags |= AST.FunctionFlags.Generator;
    }

    const func_name = self.internStr(self.consumeOrNull(TokenType.Identifier) orelse Token.Empty);

    _ = try self.consume(TokenType.OpenParen, diagnostics.ARG_expected, .{"("});

    const args = try parseFunctionArguments(self);
    defer args.deinit();

    const return_type = try parseOptionalDataType(self);
    const body = try parseBlock(self) orelse return self.fail(diagnostics.ARG_expected, .{"{"});

    return self.addNode(main_token, AST.Node{ .function_decl = .{
        .flags = fn_flags,
        .name = func_name,
        .params = args.items,
        .body = body,
        .return_type = return_type,
    } });
}

pub fn parseFunctionArguments(self: *Parser) ParserError!std.ArrayList(AST.Node.Index) {
    var args = std.ArrayList(AST.Node.Index).init(self.gpa);
    errdefer args.deinit();

    while (!self.match(TokenType.CloseParen)) {
        const identifier = try self.consume(TokenType.Identifier, diagnostics.identifier_expected, .{});
        const ident_id = self.internStr(identifier);
        const param_type = try parseOptionalDataType(self);
        try args.append(self.addNode(identifier, AST.Node{
            .function_param = .{
                .identifier = ident_id,
                .type = param_type,
            },
        }));

        if (self.match(TokenType.CloseParen)) {
            break;
        }

        _ = try self.consume(TokenType.Comma, diagnostics.ARG_expected, .{","});
    }

    return args;
}

pub fn parseAsyncArrowFunction(self: *Parser) ParserError!?AST.Node.Index {
    if (!self.match(TokenType.Async)) {
        return null;
    }

    return try parseArrowFunctionWith1Arg(self, self.cur_token.dec(1), .async_arrow) orelse try parseArrowFunctionWithParenthesis(self, self.cur_token.dec(1), .async_arrow);
}

pub fn parseArrowFunction(self: *Parser) ParserError!?AST.Node.Index {
    return try parseArrowFunctionWith1Arg(self, self.cur_token, .arrow) orelse try parseArrowFunctionWithParenthesis(self, self.cur_token, .arrow);
}

fn parseArrowFunctionWith1Arg(self: *Parser, main_token: Token.Index, arrow_type: anytype) ParserError!?AST.Node.Index {
    const cp = self.checkpoint();
    const arg = try parseIdentifier(self) orelse return null;
    if (!self.match(TokenType.Arrow)) {
        self.rewindTo(cp);
        return null;
    }

    var args = std.ArrayList(AST.Node.Index).initCapacity(self.gpa, 1) catch unreachable;
    defer args.deinit();

    args.appendAssumeCapacity(arg);

    const body = try parseConciseBody(self);
    return self.addNode(main_token, AST.Node{ .arrow_function = .{
        .type = arrow_type,
        .params = args.items,
        .body = body,
        .return_type = AST.Node.Empty,
    } });
}

fn parseArrowFunctionWithParenthesis(self: *Parser, main_token: Token.Index, arrow_type: anytype) ParserError!?AST.Node.Index {
    const cp = self.checkpoint();
    if (!self.match(TokenType.OpenParen)) {
        return null;
    }

    const args = try parseFunctionArguments(self);
    defer args.deinit();

    const return_type = try parseOptionalDataType(self);
    if (!self.match(TokenType.Arrow)) {
        self.rewindTo(cp);
        return null;
    }

    const body = try parseConciseBody(self);
    return self.addNode(main_token, AST.Node{ .arrow_function = .{
        .type = arrow_type,
        .params = args.items,
        .body = body,
        .return_type = return_type,
    } });
}

fn parseConciseBody(self: *Parser) ParserError!AST.Node.Index {
    return try parseBlock(self) orelse
        try expectAssignment(self);
}

test "should return null if its not function statement" {
    const text = "identifier";

    try TestParser.run(text, parseFunctionStatement, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectAST(node, null);
        }
    });
}

test "should parse function statement" {
    const text =
        \\ function(a: number, b, c: string) {}
        \\>^        ^          ^  ^
    ;

    try TestParser.run(text, parseFunctionStatement, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, comptime markers: MarkerList(text)) !void {
            const function_decl = AST.Node.FunctionDeclaration{
                .name = StringId.none,
                .flags = AST.FunctionFlags.None,
                .params = @constCast(&[_]AST.Node.Index{ AST.Node.at(2), AST.Node.at(3), AST.Node.at(5) }),
                .body = AST.Node.at(6),
                .return_type = AST.Node.Empty,
            };
            try t.expectAST(node, .{ .function_decl = function_decl });
            try t.expectTokenAt(markers[0], node.?);

            try t.expectAST(function_decl.params[0], AST.Node{
                .function_param = AST.Node.FunctionParam{ .identifier = StringId.at(1), .type = AST.Node.at(1) },
            });
            try t.expectTokenAt(markers[1], function_decl.params[0]);

            try t.expectAST(function_decl.params[1], AST.Node{
                .function_param = AST.Node.FunctionParam{ .identifier = StringId.at(3), .type = AST.Node.Empty },
            });
            try t.expectTokenAt(markers[2], function_decl.params[1]);

            try t.expectAST(function_decl.params[2], AST.Node{
                .function_param = AST.Node.FunctionParam{ .identifier = StringId.at(4), .type = AST.Node.at(4) },
            });
            try t.expectTokenAt(markers[3], function_decl.params[2]);
        }
    });
}

test "should parse function statement with name" {
    const text =
        \\ function foo(a: number, b, c: string): void {}
        \\>^
    ;

    try TestParser.run(text, parseFunctionStatement, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, comptime markers: MarkerList(text)) !void {
            try t.expectAST(node, .{
                .function_decl = .{
                    .name = StringId.at(1),
                    .flags = AST.FunctionFlags.None,
                    .params = @constCast(&[_]AST.Node.Index{ AST.Node.at(2), AST.Node.at(3), AST.Node.at(5) }),
                    .body = AST.Node.at(7),
                    .return_type = AST.Node.at(6),
                },
            });
            try t.expectTokenAt(markers[0], node.?);
        }
    });
}

test "should allow trailing comma in function params" {
    const text = "function(a: number, b: number,): void {}";

    try TestParser.run(text, parseFunctionStatement, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectAST(node, .{
                .function_decl = .{
                    .name = StringId.none,
                    .flags = AST.FunctionFlags.None,
                    .params = @constCast(&[_]AST.Node.Index{ AST.Node.at(2), AST.Node.at(4) }),
                    .body = AST.Node.at(6),
                    .return_type = AST.Node.at(5),
                },
            });
        }
    });
}

test "should return null if its not async function statement" {
    const text = "function(): void {}";

    try TestParser.run(text, parseAsyncFunctionStatement, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectAST(node, null);
        }
    });
}

test "should parse async function statement" {
    const text =
        \\ async function(): void {}
        \\>^
    ;

    try TestParser.run(text, parseAsyncFunctionStatement, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, comptime markers: MarkerList(text)) !void {
            try t.expectAST(node, .{
                .function_decl = .{
                    .name = StringId.none,
                    .flags = AST.FunctionFlags.Async,
                    .params = &.{},
                    .body = AST.Node.at(2),
                    .return_type = AST.Node.at(1),
                },
            });
            try t.expectTokenAt(markers[0], node.?);
        }
    });
}

test "should return syntax error if async keyword is not followed by function" {
    const text =
        \\async foo(): void {}
        \\>     ^
    ;

    try TestParser.runAny(text, parseAsyncFunctionStatement, struct {
        pub fn expect(t: TestParser, nodeOrError: ParserError!?AST.Node.Index, comptime markers: MarkerList(text)) !void {
            try t.expectSyntaxErrorAt(nodeOrError, diagnostics.unexpected_keyword_or_identifier, .{}, markers[0]);
        }
    });
}

test "should parse generator function statement" {
    const text =
        \\ function*(): void {}
        \\>^
    ;

    try TestParser.run(text, parseFunctionStatement, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, comptime markers: MarkerList(text)) !void {
            try t.expectAST(node, .{
                .function_decl = .{
                    .name = StringId.none,
                    .flags = AST.FunctionFlags.Generator,
                    .params = &.{},
                    .body = AST.Node.at(2),
                    .return_type = AST.Node.at(1),
                },
            });
            try t.expectTokenAt(markers[0], node.?);
        }
    });
}

test "should parse async generator function statement" {
    const text =
        \\ async function*(): void {}
        \\>^
    ;

    try TestParser.run(text, parseAsyncFunctionStatement, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, comptime markers: MarkerList(text)) !void {
            try t.expectAST(node, .{
                .function_decl = .{
                    .name = StringId.none,
                    .flags = AST.FunctionFlags.Async | AST.FunctionFlags.Generator,
                    .params = &.{},
                    .body = AST.Node.at(2),
                    .return_type = AST.Node.at(1),
                },
            });
            try t.expectTokenAt(markers[0], node.?);
        }
    });
}

test "should return syntax error if open paren is missing" {
    const text =
        \\function foo): void {}
        \\>           ^
    ;

    try TestParser.runAny(text, parseFunctionStatement, struct {
        pub fn expect(t: TestParser, nodeOrError: ParserError!?AST.Node.Index, comptime markers: MarkerList(text)) !void {
            try t.expectSyntaxErrorAt(nodeOrError, diagnostics.ARG_expected, .{"("}, markers[0]);
        }
    });
}

test "should return syntax error if close paren is missing" {
    const text =
        \\function foo(: void {}
        \\>            ^
    ;

    try TestParser.runAny(text, parseFunctionStatement, struct {
        pub fn expect(t: TestParser, nodeOrError: ParserError!?AST.Node.Index, comptime markers: MarkerList(text)) !void {
            try t.expectSyntaxErrorAt(nodeOrError, diagnostics.identifier_expected, .{}, markers[0]);
        }
    });
}

test "should return syntax error if block is missing" {
    const text =
        \\function foo(): void
        \\>                   ^
    ;

    try TestParser.runAny(text, parseFunctionStatement, struct {
        pub fn expect(t: TestParser, nodeOrError: ParserError!?AST.Node.Index, comptime markers: MarkerList(text)) !void {
            try t.expectSyntaxErrorAt(nodeOrError, diagnostics.ARG_expected, .{"{"}, markers[0]);
        }
    });
}

test "should return null if its not a method" {
    const text = "foo";

    try TestParser.run(text, parseMethod, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectAST(node, null);
        }
    });
}

test "should parse method" {
    const text =
        \\ foo(a: number, b,): void {}
        \\>^
    ;

    try TestParser.run(text, parseMethod, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, comptime markers: MarkerList(text)) !void {
            try t.expectAST(node, .{
                .object_method = .{
                    .name = AST.Node.at(1),
                    .params = @constCast(&[_]AST.Node.Index{ AST.Node.at(3), AST.Node.at(4) }),
                    .body = AST.Node.at(6),
                    .return_type = AST.Node.at(5),
                    .flags = AST.FunctionFlags.None,
                },
            });
            try t.expectTokenAt(markers[0], node.?);
        }
    });
}

test "should return syntax error if open bracket is missing" {
    const text = "foo(): void";

    try TestParser.runAny(text, parseMethod, struct {
        pub fn expect(t: TestParser, nodeOrError: ParserError!?AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectSyntaxError(nodeOrError, diagnostics.ARG_expected, .{"{"});
        }
    });
}

test "should return null if its not async method" {
    const text = "foo(): void {}";

    try TestParser.run(text, parseMethodAsyncGenerator, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectAST(node, null);
        }
    });
}

test "should parse async method" {
    const text =
        \\ async foo(): void {}
        \\>^
    ;

    try TestParser.run(text, parseMethodAsyncGenerator, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, comptime markers: MarkerList(text)) !void {
            try t.expectAST(node, .{
                .object_method = .{
                    .name = AST.Node.at(1),
                    .flags = AST.FunctionFlags.Async,
                    .params = &.{},
                    .body = AST.Node.at(3),
                    .return_type = AST.Node.at(2),
                },
            });
            try t.expectTokenAt(markers[0], node.?);
        }
    });
}

test "should return null if its not generator method" {
    const text = "foo(): void {}";

    try TestParser.run(text, parseMethodGenerator, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectAST(node, null);
        }
    });
}

test "should parse generator method" {
    const text =
        \\ *foo(): void {}
        \\>^
    ;

    try TestParser.run(text, parseMethodGenerator, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, comptime markers: MarkerList(text)) !void {
            try t.expectAST(node, .{
                .object_method = .{
                    .name = AST.Node.at(1),
                    .flags = AST.FunctionFlags.Generator,
                    .params = &.{},
                    .body = AST.Node.at(3),
                    .return_type = AST.Node.at(2),
                },
            });
            try t.expectTokenAt(markers[0], node.?);
        }
    });
}

test "should parse async generator method" {
    const text =
        \\ async *foo(): void {}
        \\>^
    ;

    try TestParser.run(text, parseMethodAsyncGenerator, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, comptime markers: MarkerList(text)) !void {
            try t.expectAST(node, .{
                .object_method = .{
                    .name = AST.Node.at(1),
                    .flags = AST.FunctionFlags.Async | AST.FunctionFlags.Generator,
                    .params = &.{},
                    .body = AST.Node.at(3),
                    .return_type = AST.Node.at(2),
                },
            });
            try t.expectTokenAt(markers[0], node.?);
        }
    });
}

test "should parse number, string, bigint and expresions as method names" {
    const tests = .{
        .{
            "123() {}",
            AST.Node{ .object_method = .{
                .flags = 0,
                .name = AST.Node.at(1),
                .params = &.{},
                .body = AST.Node.at(2),
                .return_type = AST.Node.Empty,
            } },
        },
        .{
            "123n() {}",
            AST.Node{ .object_method = .{
                .flags = 0,
                .name = AST.Node.at(1),
                .params = &.{},
                .body = AST.Node.at(2),
                .return_type = AST.Node.Empty,
            } },
        },
        .{
            "\"foo\"() {}",
            AST.Node{ .object_method = .{
                .flags = 0,
                .name = AST.Node.at(1),
                .params = &.{},
                .body = AST.Node.at(2),
                .return_type = AST.Node.Empty,
            } },
        },
        .{
            "#foo() {}",
            AST.Node{ .object_method = .{
                .flags = 0,
                .name = AST.Node.at(1),
                .params = &.{},
                .body = AST.Node.at(2),
                .return_type = AST.Node.Empty,
            } },
        },
        .{
            "[a + b]() {}",
            AST.Node{ .object_method = .{
                .flags = 0,
                .name = AST.Node.at(4),
                .params = &.{},
                .body = AST.Node.at(5),
                .return_type = AST.Node.Empty,
            } },
        },
    };

    inline for (tests) |test_case| {
        try TestParser.run(test_case[0], parseMethod, struct {
            pub fn expect(t: TestParser, node: ?AST.Node.Index, _: MarkerList(test_case[0])) !void {
                try t.expectAST(node, test_case[1]);
                try t.expectTokenAt(comptime Marker.fromText("^"), node.?);
            }
        });
    }
}

test "should return null if its not getter method" {
    const text = "foo(): void {}";

    try TestParser.run(text, parseMethodGetter, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectAST(node, null);
        }
    });
}

test "should parse getter method" {
    const text =
        \\ get foo(): void {}
        \\>^
    ;

    try TestParser.run(text, parseMethodGetter, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, comptime markers: MarkerList(text)) !void {
            try t.expectAST(node, .{ .object_method = .{
                .flags = AST.FunctionFlags.Getter,
                .name = AST.Node.at(1),
                .params = &.{},
                .body = AST.Node.at(3),
                .return_type = AST.Node.at(2),
            } });
            try t.expectTokenAt(markers[0], node.?);
        }
    });
}

test "should return syntax error if open bracket is missing when parsing getter" {
    const text =
        \\get foo(): void
        \\>              ^
    ;

    try TestParser.runAny(text, parseMethodGetter, struct {
        pub fn expect(t: TestParser, nodeOrError: ParserError!?AST.Node.Index, comptime markers: MarkerList(text)) !void {
            try t.expectSyntaxErrorAt(nodeOrError, diagnostics.ARG_expected, .{"{"}, markers[0]);
        }
    });
}

test "should return syntax error if open paren is missing when parsing getter" {
    const text =
        \\get foo): void {}
        \\>      ^
    ;

    try TestParser.runAny(text, parseMethodGetter, struct {
        pub fn expect(t: TestParser, nodeOrError: ParserError!?AST.Node.Index, comptime markers: MarkerList(text)) !void {
            try t.expectSyntaxErrorAt(nodeOrError, diagnostics.ARG_expected, .{"("}, markers[0]);
        }
    });
}

test "should return null if its not setter method" {
    const text = "foo(): void {}";

    try TestParser.run(text, parseMethodSetter, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectAST(node, null);
        }
    });
}

test "should parse setter method" {
    const text =
        \\ set foo(a: number): void {}
        \\>^
    ;

    try TestParser.run(text, parseMethodSetter, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, comptime markers: MarkerList(text)) !void {
            try t.expectAST(node, .{ .object_method = .{
                .name = AST.Node.at(1),
                .flags = AST.FunctionFlags.Setter,
                .params = @constCast(&[_]AST.Node.Index{AST.Node.at(3)}),
                .body = AST.Node.at(5),
                .return_type = AST.Node.at(4),
            } });
            try t.expectTokenAt(markers[0], node.?);
        }
    });
}

test "should return syntax error if open paren is missing when parsing setter" {
    const text =
        \\set foo): void {}
        \\>      ^
    ;

    try TestParser.runAny(text, parseMethodSetter, struct {
        pub fn expect(t: TestParser, nodeOrError: ParserError!?AST.Node.Index, comptime markers: MarkerList(text)) !void {
            try t.expectSyntaxErrorAt(nodeOrError, diagnostics.ARG_expected, .{"("}, markers[0]);
        }
    });
}

test "should return syntax error if open bracket is missing when parsing setter" {
    const text =
        \\set foo(a: number): void
        \\>                       ^
    ;

    try TestParser.runAny(text, parseMethodSetter, struct {
        pub fn expect(t: TestParser, nodeOrError: ParserError!?AST.Node.Index, comptime markers: MarkerList(text)) !void {
            try t.expectSyntaxErrorAt(nodeOrError, diagnostics.ARG_expected, .{"{"}, markers[0]);
        }
    });
}

test "should parse method with 'get' as name" {
    const text =
        \\ get(): void {}
        \\>^
    ;

    try TestParser.run(text, parseMethodGetter, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, comptime markers: MarkerList(text)) !void {
            try t.expectAST(node, .{ .object_method = .{
                .flags = AST.FunctionFlags.None,
                .name = AST.Node.at(1),
                .params = &.{},
                .body = AST.Node.at(3),
                .return_type = AST.Node.at(2),
            } });
            try t.expectTokenAt(markers[0], node.?);
        }
    });
}

test "should parse method with 'set' as name" {
    const text =
        \\ set(a: number): void {}
        \\>^
    ;

    try TestParser.run(text, parseMethodSetter, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, comptime markers: MarkerList(text)) !void {
            try t.expectAST(node, .{ .object_method = .{
                .flags = AST.FunctionFlags.None,
                .name = AST.Node.at(1),
                .params = @constCast(&[_]AST.Node.Index{AST.Node.at(3)}),
                .body = AST.Node.at(5),
                .return_type = AST.Node.at(4),
            } });
            try t.expectTokenAt(markers[0], node.?);
        }
    });
}

test "should return null if its not arrow function with 1 arg" {
    const text = "a = b";

    try TestParser.run(text, parseArrowFunction, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectAST(node, null);
        }
    });
}

test "should return null if its not async arrow function with 1 arg" {
    const text = "async a = b";

    try TestParser.run(text, parseAsyncArrowFunction, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectAST(node, null);
        }
    });
}

test "should return null if its not arrow function with no args" {
    const text = "() = b";

    try TestParser.run(text, parseArrowFunction, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectAST(node, null);
        }
    });
}

test "should return null if its not async arrow function with no args" {
    const text = "async () = b";

    try TestParser.run(text, parseAsyncArrowFunction, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectAST(node, null);
        }
    });
}

test "should parse arrow function" {
    const text =
        \\ a => b
        \\>^
    ;

    try TestParser.run(text, parseArrowFunction, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, comptime markers: MarkerList(text)) !void {
            try t.expectAST(node, .{
                .arrow_function = .{
                    .type = .arrow,
                    .params = @constCast(&[_]AST.Node.Index{AST.Node.at(1)}),
                    .body = AST.Node.at(2),
                    .return_type = AST.Node.Empty,
                },
            });
            try t.expectTokenAt(markers[0], node.?);
        }
    });
}

test "should parse async arrow function" {
    const text =
        \\ async a => b
        \\>^
    ;

    try TestParser.run(text, parseAsyncArrowFunction, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, comptime markers: MarkerList(text)) !void {
            try t.expectAST(node, .{
                .arrow_function = .{
                    .type = .async_arrow,
                    .params = @constCast(&[_]AST.Node.Index{AST.Node.at(1)}),
                    .body = AST.Node.at(2),
                    .return_type = AST.Node.Empty,
                },
            });
            try t.expectTokenAt(markers[0], node.?);
        }
    });
}

test "should parse arrow function without args" {
    const text =
        \\ () => {}
        \\>^
    ;

    try TestParser.run(text, parseArrowFunction, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, comptime markers: MarkerList(text)) !void {
            try t.expectAST(node, .{
                .arrow_function = .{
                    .type = .arrow,
                    .params = &.{},
                    .body = AST.Node.at(1),
                    .return_type = AST.Node.Empty,
                },
            });
            try t.expectTokenAt(markers[0], node.?);
        }
    });
}

test "should parse async arrow function without args" {
    const text =
        \\ async () => {}
        \\>^
    ;

    try TestParser.run(text, parseAsyncArrowFunction, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, comptime markers: MarkerList(text)) !void {
            try t.expectAST(node, .{
                .arrow_function = .{
                    .type = .async_arrow,
                    .params = &.{},
                    .body = AST.Node.at(1),
                    .return_type = AST.Node.Empty,
                },
            });
            try t.expectTokenAt(markers[0], node.?);
        }
    });
}

test "should parse arrow function with args" {
    const text =
        \\ (a: number, b): string => {}
        \\>^
    ;

    try TestParser.run(text, parseArrowFunction, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, comptime markers: MarkerList(text)) !void {
            try t.expectAST(node, .{ .arrow_function = .{
                .type = .arrow,
                .params = @constCast(&[_]AST.Node.Index{ AST.Node.at(2), AST.Node.at(3) }),
                .body = AST.Node.at(5),
                .return_type = AST.Node.at(4),
            } });
            try t.expectTokenAt(markers[0], node.?);
        }
    });
}
