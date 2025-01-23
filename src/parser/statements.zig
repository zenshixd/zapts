const std = @import("std");
const Parser = @import("../parser.zig");
const AST = @import("../ast.zig");
const Token = @import("../consts.zig").Token;
const TokenType = @import("../consts.zig").TokenType;
const ParserError = Parser.ParserError;
const diagnostics = @import("../diagnostics.zig");

const needsSemicolon = Parser.needsSemicolon;

const parseImportStatement = @import("imports.zig").parseImportStatement;
const parseExportStatement = @import("imports.zig").parseExportStatement;
const parseClassStatement = @import("classes.zig").parseClassStatement;
const parseAbstractClassStatement = @import("classes.zig").parseAbstractClassStatement;
const parseFunctionStatement = @import("functions.zig").parseFunctionStatement;
const parseAsyncFunctionStatement = @import("functions.zig").parseAsyncFunctionStatement;
const parseBreakableStatement = @import("loops.zig").parseBreakableStatement;
const parseAssignment = @import("binary.zig").parseAssignment;
const parseExpression = @import("expressions.zig").parseExpression;
const parseOptionalDataType = @import("types.zig").parseOptionalDataType;

const expectAST = Parser.expectAST;
const expectSyntaxError = Parser.expectSyntaxError;

pub fn parseStatement(self: *Parser) ParserError!AST.Node.Index {
    const node = try parseBlock(self) orelse
        try parseDeclaration(self) orelse
        try parseClassStatement(self) orelse
        try parseAbstractClassStatement(self) orelse
        try parseImportStatement(self) orelse
        try parseExportStatement(self) orelse
        try parseEmptyStatement(self) orelse
        try parseIfStatement(self) orelse
        try parseBreakableStatement(self) orelse
        try parseReturnStatement(self) orelse
        //try self.parseTypeDeclaration() orelse
        //try self.parseInterfaceDeclaration() orelse
        try parseExpression(self);

    if (self.needsSemicolon(node)) {
        _ = try self.consume(TokenType.Semicolon, diagnostics.ARG_expected, .{";"});
    }
    return node;
}

pub fn parseBlock(self: *Parser) ParserError!?AST.Node.Index {
    if (!self.match(TokenType.OpenCurlyBrace)) {
        return null;
    }

    var statements = std.ArrayList(AST.Node.Index).init(self.gpa);
    defer statements.deinit();

    while (true) {
        if (self.match(TokenType.Eof)) {
            return self.fail(diagnostics.ARG_expected, .{"}"});
        }

        if (self.match(TokenType.CloseCurlyBrace)) {
            break;
        }

        try statements.append(try parseStatement(self));

        while (self.match(TokenType.NewLine)) {}

        if (self.match(TokenType.CloseCurlyBrace)) {
            break;
        }
    }

    return self.addNode(self.cur_token, AST.Node{ .block = statements.items });
}

pub fn parseDeclaration(self: *Parser) ParserError!?AST.Node.Index {
    const kind: AST.Node.DeclarationKind = switch (self.token().type) {
        .Var => .@"var",
        .Let => .let,
        .Const => .@"const",
        else => return try parseFunctionStatement(self) orelse try parseAsyncFunctionStatement(self),
    };
    _ = self.advance();

    var nodes = std.ArrayList(AST.Node.Index).init(self.gpa);
    defer nodes.deinit();

    while (true) {
        const identifier = try self.consume(TokenType.Identifier, diagnostics.identifier_expected, .{});
        const identifier_data_type = try parseOptionalDataType(self);
        var value: AST.Node.Index = AST.Node.Empty;

        if (self.match(TokenType.Equal)) {
            value = try parseAssignment(self);
        }

        try nodes.append(self.addNode(self.cur_token, AST.Node{ .decl_binding = .{
            .name = identifier,
            .decl_type = identifier_data_type,
            .value = value,
        } }));
        if (!self.match(TokenType.Comma)) {
            break;
        }
    }

    return self.addNode(self.cur_token, AST.Node{ .declaration = .{
        .kind = kind,
        .list = nodes.items,
    } });
}

fn parseReturnStatement(self: *Parser) ParserError!?AST.Node.Index {
    if (!self.match(TokenType.Return)) {
        return null;
    }

    if (self.peekMatch(TokenType.Semicolon)) {
        return self.addNode(self.cur_token, .{ .@"return" = AST.Node.Empty });
    }

    return self.addNode(self.cur_token, AST.Node{ .@"return" = try parseExpression(self) });
}

fn parseEmptyStatement(self: *Parser) ParserError!?AST.Node.Index {
    if (!self.match(TokenType.Semicolon)) {
        return null;
    }

    return AST.Node.Empty;
}

fn parseIfStatement(self: *Parser) ParserError!?AST.Node.Index {
    if (!self.match(TokenType.If)) {
        return null;
    }

    _ = try self.consume(TokenType.OpenParen, diagnostics.ARG_expected, .{"("});
    const cond = try parseExpression(self);
    _ = try self.consume(TokenType.CloseParen, diagnostics.ARG_expected, .{")"});
    const then = try parseStatement(self);

    const else_node = if (self.match(TokenType.Else)) try parseStatement(self) else AST.Node.Empty;

    return self.addNode(self.cur_token, AST.Node{ .@"if" = AST.Node.If{
        .expr = cond,
        .body = then,
        .@"else" = else_node,
    } });
}

test "should parse statements" {
    const tests = .{
        .{
            "{}", AST.Node{ .block = &.{} },
        },
        .{
            "class A {}",
            AST.Node{ .class = .{ .abstract = false, .name = 1, .super_class = AST.Node.Empty, .implements = &.{}, .body = &.{} } },
        },
        .{
            "import 'a';",
            AST.Node{ .import = .{ .simple = 1 } },
        },
        .{
            "export default a;",
            AST.Node{ .@"export" = .{ .default = 2 } },
        },
        .{
            ";",
            AST.Node{ .root = &.{} },
        },
        .{
            "if (a) {}",
            AST.Node{ .@"if" = AST.Node.If{ .expr = 2, .body = 3, .@"else" = AST.Node.Empty } },
        },
        .{
            "while (a) {}",
            AST.Node{ .@"while" = .{ .cond = 2, .body = 3 } },
        },
        .{
            "return;",
            AST.Node{ .@"return" = AST.Node.Empty },
        },
        .{
            "a;",
            AST.Node{ .simple_value = .{ .kind = .identifier } },
        },
    };

    inline for (tests) |test_case| {
        var parser, const node = try Parser.once(test_case[0], parseStatement);
        defer parser.deinit();

        try parser.expectAST(node, test_case[1]);
    }
}

test "should parse block" {
    const text = "{ a; b; c; }";

    var parser, const node = try Parser.once(text, parseBlock);
    defer parser.deinit();

    try parser.expectAST(node, AST.Node{ .block = @constCast(&[_]AST.Node.Index{ 2, 4, 6 }) });
}

test "should return syntax error if block is missing" {
    const text = "{a; ";

    var parser, const node = try Parser.onceAny(text, parseBlock);
    defer parser.deinit();

    try parser.expectSyntaxError(node, diagnostics.ARG_expected, .{"}"});
}

test "should parse declarations" {
    const tests = .{
        .{
            "var a;",
            &[_]AST.Raw{
                AST.Raw{ .tag = .decl_binding, .main_token = 2, .data = .{ .lhs = 1, .rhs = 0 } },
                AST.Raw{ .tag = .var_decl, .main_token = 2, .data = .{ .lhs = 2, .rhs = 3 } },
            },
        },
        .{
            "let a;",
            &[_]AST.Raw{
                AST.Raw{ .tag = .decl_binding, .main_token = 2, .data = .{ .lhs = 1, .rhs = 0 } },
                AST.Raw{ .tag = .let_decl, .main_token = 2, .data = .{ .lhs = 2, .rhs = 3 } },
            },
        },
        .{
            "const a;",
            &[_]AST.Raw{
                AST.Raw{ .tag = .decl_binding, .main_token = 2, .data = .{ .lhs = 1, .rhs = 0 } },
                AST.Raw{ .tag = .const_decl, .main_token = 2, .data = .{ .lhs = 2, .rhs = 3 } },
            },
        },
        .{
            "const a = 1;",
            &[_]AST.Raw{
                AST.Raw{ .tag = .simple_value, .main_token = 3, .data = .{ .lhs = 3, .rhs = 0 } },
                AST.Raw{ .tag = .decl_binding, .main_token = 4, .data = .{ .lhs = 1, .rhs = 0 } },
                AST.Raw{ .tag = .const_decl, .main_token = 4, .data = .{ .lhs = 2, .rhs = 3 } },
            },
        },
        .{
            "const a = 1, b = 2;",
            &[_]AST.Raw{
                AST.Raw{ .tag = .simple_value, .main_token = 3, .data = .{ .lhs = 3, .rhs = 0 } },
                AST.Raw{ .tag = .decl_binding, .main_token = 4, .data = .{ .lhs = 1, .rhs = 0 } },
                AST.Raw{ .tag = .simple_value, .main_token = 7, .data = .{ .lhs = 3, .rhs = 0 } },
                AST.Raw{ .tag = .decl_binding, .main_token = 8, .data = .{ .lhs = 5, .rhs = 2 } },
                AST.Raw{ .tag = .const_decl, .main_token = 8, .data = .{ .lhs = 4, .rhs = 6 } },
            },
        },
        .{
            "const a: number = 1;",
            &[_]AST.Raw{
                AST.Raw{ .tag = .simple_type, .main_token = 3, .data = .{ .lhs = 3, .rhs = 0 } },
                AST.Raw{ .tag = .simple_value, .main_token = 5, .data = .{ .lhs = 3, .rhs = 0 } },
                AST.Raw{ .tag = .decl_binding, .main_token = 6, .data = .{ .lhs = 1, .rhs = 0 } },
                AST.Raw{ .tag = .const_decl, .main_token = 6, .data = .{ .lhs = 2, .rhs = 3 } },
            },
        },
    };

    inline for (tests) |test_case| {
        var parser, _ = try Parser.once(test_case[0], parseDeclaration);
        defer parser.deinit();

        try parser.expectNodesToEqual(test_case[1]);
    }
}

test "should parse empty return statement" {
    const text = "return;";

    var parser, const node = try Parser.once(text, parseReturnStatement);
    defer parser.deinit();

    try parser.expectAST(node, AST.Node{ .@"return" = AST.Node.Empty });
}

test "should parse return statement" {
    const text = "return a;";

    var parser, const node = try Parser.once(text, parseReturnStatement);
    defer parser.deinit();

    try parser.expectAST(node, AST.Node{ .@"return" = 2 });
}

test "should parse if statement" {
    const text = "if (a) {}";

    var parser, const node = try Parser.once(text, parseIfStatement);
    defer parser.deinit();

    try parser.expectAST(node, AST.Node{ .@"if" = AST.Node.If{ .expr = 2, .body = 3, .@"else" = AST.Node.Empty } });
}

test "should parse if statement with else" {
    const text = "if (a) {} else {}";

    var parser, const node = try Parser.once(text, parseIfStatement);
    defer parser.deinit();

    try parser.expectAST(node, AST.Node{ .@"if" = AST.Node.If{ .expr = 2, .body = 3, .@"else" = 4 } });
}

test "should return syntax error if open paren is missing" {
    const text = "if a) {} else";

    var parser, const node = try Parser.onceAny(text, parseIfStatement);
    defer parser.deinit();

    try parser.expectSyntaxError(node, diagnostics.ARG_expected, .{"("});
}

test "should return syntax error if close paren is missing" {
    const text = "if (a {}";

    var parser, const node = try Parser.onceAny(text, parseIfStatement);
    defer parser.deinit();

    try parser.expectSyntaxError(node, diagnostics.ARG_expected, .{")"});
}

test "should return syntax error if body is missing" {
    const text = "if (a)";

    var parser, const node = try Parser.onceAny(text, parseIfStatement);
    defer parser.deinit();

    try parser.expectSyntaxError(node, diagnostics.identifier_expected, .{});
}
