const std = @import("std");

const Parser = @import("../parser.zig");
const AST = @import("../ast.zig");
const Token = @import("../consts.zig").Token;
const TokenType = @import("../consts.zig").TokenType;
const ParserError = Parser.ParserError;
const diagnostics = @import("../diagnostics.zig");

const parseAssignment = @import("binary.zig").parseAssignment;
const parseKeywordAsIdentifier = @import("primary.zig").parseKeywordAsIdentifier;
const parseIdentifier = @import("primary.zig").parseIdentifier;
const parseOptionalDataType = @import("types.zig").parseOptionalDataType;
const parseBlock = @import("statements.zig").parseBlock;

const expectAST = @import("../parser.zig").expectAST;
const expectSyntaxError = @import("../parser.zig").expectSyntaxError;

pub fn parseMethodAsyncGenerator(self: *Parser) ParserError!?AST.Node.Index {
    if (!self.match(TokenType.Async)) {
        return null;
    }

    return try parseMethodGeneratorExtra(self, AST.FunctionFlags.Async) orelse
        try parseMethodExtra(self, AST.FunctionFlags.Async);
}

pub fn parseMethodGenerator(self: *Parser) ParserError!?AST.Node.Index {
    return try parseMethodGeneratorExtra(self, AST.FunctionFlags.None);
}

pub fn parseMethodGeneratorExtra(self: *Parser, flags: u2) ParserError!?AST.Node.Index {
    if (!self.match(TokenType.Star)) {
        return null;
    }

    return try parseMethodExtra(self, flags | AST.FunctionFlags.Generator);
}

pub fn parseMethod(self: *Parser) ParserError!?AST.Node.Index {
    return try parseMethodExtra(self, AST.FunctionFlags.None);
}

pub fn parseMethodExtra(self: *Parser, flags: u4) ParserError!?AST.Node.Index {
    const cur_token = self.cur_token;
    const elem_name = try parseObjectElementName(self) orelse return null;

    if (!self.match(TokenType.OpenParen)) {
        self.cur_token = cur_token;
        return null;
    }

    const args = try parseFunctionArguments(self);
    defer args.deinit();

    const return_type = try parseOptionalDataType(self);
    const body = try parseBlock(self) orelse return self.fail(diagnostics.ARG_expected, .{"{"});

    return self.addNode(cur_token, AST.Node{ .object_method = .{
        .flags = flags,
        .name = elem_name,
        .params = args.items,
        .body = body,
        .return_type = return_type,
    } });
}

pub fn parseMethodGetter(self: *Parser) ParserError!?AST.Node.Index {
    if (!self.match(TokenType.Get)) {
        return null;
    }
    const elem_name = try parseObjectElementName(self) orelse {
        self.rewind();
        return try parseMethod(self);
    };

    _ = try self.consume(TokenType.OpenParen, diagnostics.ARG_expected, .{"("});
    const args = try parseFunctionArguments(self);
    defer args.deinit();

    const return_type = try parseOptionalDataType(self);
    const body = try parseBlock(self) orelse return self.fail(diagnostics.ARG_expected, .{"{"});

    return self.addNode(self.cur_token, AST.Node{ .object_method = .{
        .flags = AST.FunctionFlags.Getter,
        .name = elem_name,
        .params = args.items,
        .body = body,
        .return_type = return_type,
    } });
}

pub fn parseMethodSetter(self: *Parser) ParserError!?AST.Node.Index {
    if (!self.match(TokenType.Set)) {
        return null;
    }
    const elem_name = try parseObjectElementName(self) orelse {
        self.rewind();
        return try parseMethod(self);
    };

    _ = try self.consume(TokenType.OpenParen, diagnostics.ARG_expected, .{"("});
    const args = try parseFunctionArguments(self);
    defer args.deinit();

    const return_type = try parseOptionalDataType(self);
    const body = try parseBlock(self) orelse return self.fail(diagnostics.ARG_expected, .{"{"});

    return self.addNode(self.cur_token, AST.Node{ .object_method = .{
        .flags = AST.FunctionFlags.Setter,
        .name = elem_name,
        .params = args.items,
        .body = body,
        .return_type = return_type,
    } });
}

pub fn parseObjectElementName(self: *Parser) ParserError!?AST.Node.Index {
    switch (self.token().type) {
        .Identifier, .PrivateIdentifier => {
            _ = self.advance();
            return self.addNode(self.cur_token - 1, AST.Node{ .simple_value = .{ .kind = .identifier } });
        },
        .StringConstant => {
            _ = self.advance();
            return self.addNode(self.cur_token - 1, AST.Node{ .simple_value = .{ .kind = .string } });
        },
        .NumberConstant => {
            _ = self.advance();
            return self.addNode(self.cur_token - 1, AST.Node{ .simple_value = .{ .kind = .number } });
        },
        .BigIntConstant => {
            _ = self.advance();
            return self.addNode(self.cur_token - 1, AST.Node{ .simple_value = .{ .kind = .bigint } });
        },
        .OpenSquareBracket => {
            _ = self.advance();
            const node = try parseAssignment(self);
            _ = try self.consume(TokenType.CloseSquareBracket, diagnostics.ARG_expected, .{"]"});
            return self.addNode(self.cur_token, AST.Node{ .computed_identifier = node });
        },
        else => {
            if (try parseKeywordAsIdentifier(self)) {
                return self.addNode(self.cur_token - 1, AST.Node{ .simple_value = .{ .kind = .identifier } });
            }
            return null;
        },
    }
}

pub fn parseAsyncFunctionStatement(self: *Parser) ParserError!?AST.Node.Index {
    if (!self.match(TokenType.Async)) {
        return null;
    }

    return try parseFunctionStatementExtra(self, AST.FunctionFlags.Async) orelse self.fail(diagnostics.unexpected_keyword_or_identifier, .{});
}

pub fn parseFunctionStatement(self: *Parser) ParserError!?AST.Node.Index {
    return try parseFunctionStatementExtra(self, AST.FunctionFlags.None);
}

pub fn parseFunctionStatementExtra(self: *Parser, flags: u4) ParserError!?AST.Node.Index {
    if (!self.match(TokenType.Function)) {
        return null;
    }

    var fn_flags = flags;
    if (self.match(TokenType.Star)) {
        fn_flags |= AST.FunctionFlags.Generator;
    }

    const func_name: AST.Node.Index = self.consumeOrNull(TokenType.Identifier) orelse AST.Node.Empty;

    _ = try self.consume(TokenType.OpenParen, diagnostics.ARG_expected, .{"("});

    const args = try parseFunctionArguments(self);
    defer args.deinit();

    const return_type = try parseOptionalDataType(self);
    const body = try parseBlock(self) orelse return self.fail(diagnostics.ARG_expected, .{"{"});

    return self.addNode(self.cur_token, AST.Node{ .function_decl = .{
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
        const param_type = try parseOptionalDataType(self);
        try args.append(self.addNode(identifier, AST.Node{
            .function_param = .{
                .node = identifier,
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

    return try parseArrowFunctionWith1Arg(self, .async_arrow) orelse try parseArrowFunctionWithParenthesis(self, .async_arrow);
}

pub fn parseArrowFunction(self: *Parser) ParserError!?AST.Node.Index {
    return try parseArrowFunctionWith1Arg(self, .arrow) orelse try parseArrowFunctionWithParenthesis(self, .arrow);
}

fn parseArrowFunctionWith1Arg(self: *Parser, arrow_type: anytype) ParserError!?AST.Node.Index {
    const arg = try parseIdentifier(self) orelse return null;
    if (!self.match(TokenType.Arrow)) {
        self.rewind();
        return null;
    }

    var args = std.ArrayList(AST.Node.Index).initCapacity(self.gpa, 1) catch unreachable;
    defer args.deinit();

    args.appendAssumeCapacity(arg);

    const body = try parseConciseBody(self);
    return self.addNode(self.cur_token, AST.Node{ .arrow_function = .{
        .type = arrow_type,
        .params = args.items,
        .body = body,
        .return_type = 0,
    } });
}

fn parseArrowFunctionWithParenthesis(self: *Parser, arrow_type: anytype) ParserError!?AST.Node.Index {
    const cp = self.cur_token;
    if (!self.match(TokenType.OpenParen)) {
        return null;
    }

    const args = try parseFunctionArguments(self);
    defer args.deinit();

    const return_type = try parseOptionalDataType(self);
    if (!self.match(TokenType.Arrow)) {
        self.cur_token = cp;
        return null;
    }

    const body = try parseConciseBody(self);
    return self.addNode(self.cur_token, AST.Node{ .arrow_function = .{
        .type = arrow_type,
        .params = args.items,
        .body = body,
        .return_type = return_type,
    } });
}

fn parseConciseBody(self: *Parser) ParserError!AST.Node.Index {
    return try parseBlock(self) orelse
        try parseAssignment(self);
}

test "should return null if its not function statement" {
    const text = "identifier";

    var parser, const node = try Parser.once(text, parseFunctionStatement);
    defer parser.deinit();

    try parser.expectAST(node, null);
}

test "should parse function statement" {
    const text = "function(a: number, b, c: string) {}";

    var parser, const node = try Parser.once(text, parseFunctionStatement);
    defer parser.deinit();

    const function_decl = AST.Node.FunctionDeclaration{
        .name = 0,
        .flags = AST.FunctionFlags.None,
        .params = @constCast(&[_]AST.Node.Index{ 2, 3, 5 }),
        .body = 6,
        .return_type = 0,
    };
    try parser.expectAST(node, .{ .function_decl = function_decl });
    try parser.expectAST(function_decl.params[0], AST.Node{
        .function_param = AST.Node.FunctionParam{ .node = 2, .type = 1 },
    });
    try parser.expectAST(function_decl.params[1], AST.Node{
        .function_param = AST.Node.FunctionParam{ .node = 6, .type = 0 },
    });
    try parser.expectAST(function_decl.params[2], AST.Node{
        .function_param = AST.Node.FunctionParam{ .node = 8, .type = 4 },
    });
}

test "should parse function statement with name" {
    const text = "function foo(a: number, b, c: string): void {}";

    var parser, const node = try Parser.once(text, parseFunctionStatement);
    defer parser.deinit();

    try parser.expectAST(node, .{
        .function_decl = .{
            .name = 1,
            .flags = AST.FunctionFlags.None,
            .params = @constCast(&[_]AST.Node.Index{ 2, 3, 5 }),
            .body = 7,
            .return_type = 6,
        },
    });
}

test "should allow trailing comma in function params" {
    const text = "function(a: number, b: number,): void {}";

    var parser, const node = try Parser.once(text, parseFunctionStatement);
    defer parser.deinit();

    try parser.expectAST(node, .{
        .function_decl = .{
            .name = 0,
            .flags = AST.FunctionFlags.None,
            .params = @constCast(&[_]AST.Node.Index{ 2, 4 }),
            .body = 6,
            .return_type = 5,
        },
    });
}

test "should return null if its not async function statement" {
    const text = "function(): void {}";

    var parser, const node = try Parser.once(text, parseAsyncFunctionStatement);
    defer parser.deinit();

    try parser.expectAST(node, null);
}

test "should parse async function statement" {
    const text = "async function(): void {}";

    var parser, const node = try Parser.once(text, parseAsyncFunctionStatement);
    defer parser.deinit();

    try parser.expectAST(node, .{
        .function_decl = .{
            .name = 0,
            .flags = AST.FunctionFlags.Async,
            .params = @constCast(&[_]AST.Node.Index{}),
            .body = 2,
            .return_type = 1,
        },
    });
}

test "should return syntax error if async keyword is not followed by function" {
    const text = "async foo(): void {}";

    var parser, const nodeOrError = try Parser.onceAny(text, parseAsyncFunctionStatement);
    defer parser.deinit();

    try parser.expectSyntaxError(nodeOrError, diagnostics.unexpected_keyword_or_identifier, .{});
}

test "should parse generator function statement" {
    const text = "function*(): void {}";

    var parser, const node = try Parser.once(text, parseFunctionStatement);
    defer parser.deinit();

    try parser.expectAST(node, .{
        .function_decl = .{
            .name = 0,
            .flags = AST.FunctionFlags.Generator,
            .params = @constCast(&[_]AST.Node.Index{}),
            .body = 2,
            .return_type = 1,
        },
    });
}

test "should parse async generator function statement" {
    const text = "async function*(): void {}";

    var parser, const node = try Parser.once(text, parseAsyncFunctionStatement);
    defer parser.deinit();

    try parser.expectAST(node, .{
        .function_decl = .{
            .name = 0,
            .flags = AST.FunctionFlags.Async | AST.FunctionFlags.Generator,
            .params = @constCast(&[_]AST.Node.Index{}),
            .body = 2,
            .return_type = 1,
        },
    });
}

test "should return syntax error if open paren is missing" {
    const text = "function foo): void {}";

    var parser, const nodeOrError = try Parser.onceAny(text, parseFunctionStatement);
    defer parser.deinit();

    try parser.expectSyntaxError(nodeOrError, diagnostics.ARG_expected, .{"("});
}

test "should return syntax error if close paren is missing" {
    const text = "function foo(: void {}";

    var parser, const nodeOrError = try Parser.onceAny(text, parseFunctionStatement);
    defer parser.deinit();

    try parser.expectSyntaxError(nodeOrError, diagnostics.identifier_expected, .{});
}

test "should return syntax error if block is missing" {
    const text = "function foo(): void";

    var parser, const nodeOrError = try Parser.onceAny(text, parseFunctionStatement);
    defer parser.deinit();

    try parser.expectSyntaxError(nodeOrError, diagnostics.ARG_expected, .{"{"});
}

test "should return null if its not a method" {
    const text = "foo";

    var parser, const node = try Parser.once(text, parseMethod);
    defer parser.deinit();

    try parser.expectAST(node, null);
}

test "should parse method" {
    const text = "foo(a: number, b,): void {}";

    var parser, const node = try Parser.once(text, parseMethod);
    defer parser.deinit();

    try parser.expectAST(node, .{
        .object_method = .{
            .name = 1,
            .params = @constCast(&[_]AST.Node.Index{ 3, 4 }),
            .body = 6,
            .return_type = 5,
            .flags = AST.FunctionFlags.None,
        },
    });
}

test "should return syntax error if open bracket is missing" {
    const text = "foo(): void";

    var parser, const nodeOrError = try Parser.onceAny(text, parseMethod);
    defer parser.deinit();

    try parser.expectSyntaxError(nodeOrError, diagnostics.ARG_expected, .{"{"});
}

test "should return null if its not async method" {
    const text = "foo(): void {}";

    var parser, const node = try Parser.once(text, parseMethodAsyncGenerator);
    defer parser.deinit();

    try parser.expectAST(node, null);
}

test "should parse async method" {
    const text = "async foo(): void {}";

    var parser, const node = try Parser.once(text, parseMethodAsyncGenerator);
    defer parser.deinit();

    try parser.expectAST(node, .{
        .object_method = .{
            .name = 1,
            .flags = AST.FunctionFlags.Async,
            .params = @constCast(&[_]AST.Node.Index{}),
            .body = 3,
            .return_type = 2,
        },
    });
}

test "should return null if its not generator method" {
    const text = "foo(): void {}";

    var parser, const node = try Parser.once(text, parseMethodGenerator);
    defer parser.deinit();

    try parser.expectAST(node, null);
}

test "should parse generator method" {
    const text = "*foo(): void {}";

    var parser, const node = try Parser.once(text, parseMethodGenerator);
    defer parser.deinit();

    try parser.expectAST(node, .{
        .object_method = .{
            .name = 1,
            .flags = AST.FunctionFlags.Generator,
            .params = @constCast(&[_]AST.Node.Index{}),
            .body = 3,
            .return_type = 2,
        },
    });
}

test "should parse async generator method" {
    const text = "async *foo(): void {}";

    var parser, const node = try Parser.once(text, parseMethodAsyncGenerator);
    defer parser.deinit();

    try parser.expectAST(node, .{
        .object_method = .{
            .name = 1,
            .flags = AST.FunctionFlags.Async | AST.FunctionFlags.Generator,
            .params = @constCast(&[_]AST.Node.Index{}),
            .body = 3,
            .return_type = 2,
        },
    });
}

test "should parse number, string, bigint and expresions as method names" {
    const tests = .{
        .{
            "123() {}",
            AST.Node{ .object_method = .{
                .flags = 0,
                .name = 1,
                .params = @constCast(&[_]AST.Node.Index{}),
                .body = 2,
                .return_type = 0,
            } },
        },
        .{
            "123n() {}",
            AST.Node{ .object_method = .{
                .flags = 0,
                .name = 1,
                .params = @constCast(&[_]AST.Node.Index{}),
                .body = 2,
                .return_type = 0,
            } },
        },
        .{
            "\"foo\"() {}",
            AST.Node{ .object_method = .{
                .flags = 0,
                .name = 1,
                .params = @constCast(&[_]AST.Node.Index{}),
                .body = 2,
                .return_type = 0,
            } },
        },
        .{
            "#foo() {}",
            AST.Node{ .object_method = .{
                .flags = 0,
                .name = 1,
                .params = @constCast(&[_]AST.Node.Index{}),
                .body = 2,
                .return_type = 0,
            } },
        },
        .{
            "[a + b]() {}",
            AST.Node{ .object_method = .{
                .flags = 0,
                .name = 5,
                .params = @constCast(&[_]AST.Node.Index{}),
                .body = 6,
                .return_type = 0,
            } },
        },
    };

    inline for (tests) |test_case| {
        var parser, const node = try Parser.once(test_case[0], parseMethod);
        defer parser.deinit();

        try parser.expectAST(node, test_case[1]);
    }
}

test "should return null if its not getter method" {
    const text = "foo(): void {}";

    var parser, const node = try Parser.once(text, parseMethodGetter);
    defer parser.deinit();

    try parser.expectAST(node, null);
}

test "should parse getter method" {
    const text = "get foo(): void {}";

    var parser, const node = try Parser.once(text, parseMethodGetter);
    defer parser.deinit();

    try parser.expectAST(node, .{ .object_method = .{
        .flags = AST.FunctionFlags.Getter,
        .name = 1,
        .params = @constCast(&[_]AST.Node.Index{}),
        .body = 3,
        .return_type = 2,
    } });
}

test "should return syntax error if open bracket is missing when parsing getter" {
    const text = "get foo(): void";

    var parser, const nodeOrError = try Parser.onceAny(text, parseMethodGetter);
    defer parser.deinit();

    try parser.expectSyntaxError(nodeOrError, diagnostics.ARG_expected, .{"{"});
}

test "should return syntax error if open paren is missing when parsing getter" {
    const text = "get foo): void {}";

    var parser, const nodeOrError = try Parser.onceAny(text, parseMethodGetter);
    defer parser.deinit();

    try parser.expectSyntaxError(nodeOrError, diagnostics.ARG_expected, .{"("});
}

test "should return null if its not setter method" {
    const text = "foo(): void {}";

    var parser, const node = try Parser.once(text, parseMethodSetter);
    defer parser.deinit();

    try parser.expectAST(node, null);
}

test "should parse setter method" {
    const text = "set foo(a: number): void {}";

    var parser, const node = try Parser.once(text, parseMethodSetter);
    defer parser.deinit();

    try parser.expectAST(node, .{ .object_method = .{
        .name = 1,
        .flags = AST.FunctionFlags.Setter,
        .params = @constCast(&[_]AST.Node.Index{3}),
        .body = 5,
        .return_type = 4,
    } });
}

test "should return syntax error if open paren is missing when parsing setter" {
    const text = "set foo): void {}";

    var parser, const nodeOrError = try Parser.onceAny(text, parseMethodSetter);
    defer parser.deinit();

    try parser.expectSyntaxError(nodeOrError, diagnostics.ARG_expected, .{"("});
}

test "should return syntax error if open bracket is missing when parsing setter" {
    const text = "set foo(a: number): void";

    var parser, const nodeOrError = try Parser.onceAny(text, parseMethodSetter);
    defer parser.deinit();

    try parser.expectSyntaxError(nodeOrError, diagnostics.ARG_expected, .{"{"});
}

test "should parse method with 'get' as name" {
    const text = "get(): void {}";

    var parser, const node = try Parser.once(text, parseMethodGetter);
    defer parser.deinit();

    try parser.expectAST(node, .{ .object_method = .{
        .flags = AST.FunctionFlags.None,
        .name = 1,
        .params = @constCast(&[_]AST.Node.Index{}),
        .body = 3,
        .return_type = 2,
    } });
}

test "should parse method with 'set' as name" {
    const text = "set(a: number): void {}";

    var parser, const node = try Parser.once(text, parseMethodSetter);
    defer parser.deinit();

    try parser.expectAST(node, .{ .object_method = .{
        .flags = AST.FunctionFlags.None,
        .name = 1,
        .params = @constCast(&[_]AST.Node.Index{3}),
        .body = 5,
        .return_type = 4,
    } });
}

test "should return null if its not arrow function with 1 arg" {
    const text = "a = b";

    var parser, const node = try Parser.once(text, parseArrowFunction);
    defer parser.deinit();

    try parser.expectAST(node, null);
}

test "should return null if its not async arrow function with 1 arg" {
    const text = "async a = b";

    var parser, const node = try Parser.once(text, parseAsyncArrowFunction);
    defer parser.deinit();

    try parser.expectAST(node, null);
}

test "should return null if its not arrow function with no args" {
    const text = "() = b";

    var parser, const node = try Parser.once(text, parseArrowFunction);
    defer parser.deinit();

    try parser.expectAST(node, null);
}

test "should return null if its not async arrow function with no args" {
    const text = "async () = b";

    var parser, const node = try Parser.once(text, parseAsyncArrowFunction);
    defer parser.deinit();

    try parser.expectAST(node, null);
}

test "should parse arrow function" {
    const text = "a => b";

    var parser, const node = try Parser.once(text, parseArrowFunction);
    defer parser.deinit();

    try parser.expectAST(node, .{
        .arrow_function = .{
            .type = .arrow,
            .params = @constCast(&[_]AST.Node.Index{1}),
            .body = 3,
            .return_type = 0,
        },
    });
}

test "should parse async arrow function" {
    const text = "async a => b";

    var parser, const node = try Parser.once(text, parseAsyncArrowFunction);
    defer parser.deinit();

    try parser.expectAST(node, .{
        .arrow_function = .{
            .type = .async_arrow,
            .params = @constCast(&[_]AST.Node.Index{1}),
            .body = 3,
            .return_type = 0,
        },
    });
}

test "should parse arrow function without args" {
    const text = "() => {}";

    var parser, const node = try Parser.once(text, parseArrowFunction);
    defer parser.deinit();

    try parser.expectAST(node, .{
        .arrow_function = .{
            .type = .arrow,
            .params = &[_]AST.Node.Index{},
            .body = 1,
            .return_type = 0,
        },
    });
}

test "should parse async arrow function without args" {
    const text = "async () => {}";

    var parser, const node = try Parser.once(text, parseAsyncArrowFunction);
    defer parser.deinit();

    try parser.expectAST(node, .{
        .arrow_function = .{
            .type = .async_arrow,
            .params = &[_]AST.Node.Index{},
            .body = 1,
            .return_type = 0,
        },
    });
}

test "should parse arrow function with args" {
    const text = "(a: number, b): string => {}";

    var parser, const node = try Parser.once(text, parseArrowFunction);
    defer parser.deinit();

    try parser.expectAST(node, .{ .arrow_function = .{
        .type = .arrow,
        .params = @constCast(&[_]AST.Node.Index{ 2, 3 }),
        .body = 5,
        .return_type = 4,
    } });
}
