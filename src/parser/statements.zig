const std = @import("std");
const Parser = @import("../parser.zig");
const AST = @import("../ast.zig");
const Token = @import("../consts.zig").Token;
const TokenType = @import("../consts.zig").TokenType;
const CompilationError = @import("../consts.zig").CompilationError;
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
const expectAssignment = @import("binary.zig").expectAssignment;
const parseExpression = @import("expressions.zig").parseExpression;
const expectExpression = @import("expressions.zig").expectExpression;
const parseOptionalDataType = @import("types.zig").parseOptionalDataType;

const TestParser = @import("../test_parser.zig");
const MarkerList = @import("../test_parser.zig").MarkerList;
const Marker = @import("../test_parser.zig").Marker;

pub fn parseStatement(self: *Parser) CompilationError!?AST.Node.Index {
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
        try parseExpression(self) orelse
        return null;

    if (self.needsSemicolon(node)) {
        _ = try self.consume(TokenType.Semicolon, diagnostics.ARG_expected, .{";"});
    }
    return node;
}

pub fn expectStatement(self: *Parser) CompilationError!AST.Node.Index {
    return try parseStatement(self) orelse self.fail(diagnostics.statement_expected, .{});
}

pub fn parseBlock(self: *Parser) CompilationError!?AST.Node.Index {
    const main_token = self.cur_token;
    if (!self.match(TokenType.OpenCurlyBrace)) {
        return null;
    }

    var statements = std.ArrayList(AST.Node.Index).init(self.gpa);
    defer statements.deinit();

    while (true) {
        if (self.peekMatch(TokenType.Eof)) {
            return self.fail(diagnostics.ARG_expected, .{"}"});
        }

        if (self.match(TokenType.CloseCurlyBrace)) {
            break;
        }

        try statements.append(try expectStatement(self));

        while (self.match(TokenType.NewLine)) {}

        if (self.match(TokenType.CloseCurlyBrace)) {
            break;
        }
    }

    return self.addNode(main_token, AST.Node{ .block = statements.items });
}

pub fn parseDeclaration(self: *Parser) CompilationError!?AST.Node.Index {
    const main_token = self.cur_token;
    const kind: AST.Node.DeclarationKind = if (self.match(TokenType.Var))
        .@"var"
    else if (self.match(TokenType.Let))
        .let
    else if (self.match(TokenType.Const))
        .@"const"
    else
        return try parseFunctionStatement(self) orelse try parseAsyncFunctionStatement(self);

    var nodes = std.ArrayList(AST.Node.Index).init(self.gpa);
    defer nodes.deinit();

    while (true) {
        const binding_main_token = self.cur_token;
        const identifier = try self.consume(TokenType.Identifier, diagnostics.identifier_expected, .{});
        const identifier_data_type = try parseOptionalDataType(self);
        var value: AST.Node.Index = AST.Node.Empty;

        if (self.match(TokenType.Equal)) {
            value = try expectAssignment(self);
        }

        try nodes.append(self.addNode(binding_main_token, AST.Node{
            .decl_binding = .{
                .name = identifier,
                .decl_type = identifier_data_type,
                .value = value,
            },
        }));
        if (!self.match(TokenType.Comma)) {
            break;
        }
    }

    return self.addNode(main_token, AST.Node{
        .declaration = .{
            .kind = kind,
            .list = nodes.items,
        },
    });
}

fn parseReturnStatement(self: *Parser) CompilationError!?AST.Node.Index {
    const main_token = self.cur_token;
    if (!self.match(TokenType.Return)) {
        return null;
    }

    if (self.peekMatch(TokenType.Semicolon)) {
        return self.addNode(main_token, .{ .@"return" = AST.Node.Empty });
    }

    return self.addNode(main_token, AST.Node{ .@"return" = try expectExpression(self) });
}

fn parseEmptyStatement(self: *Parser) CompilationError!?AST.Node.Index {
    if (!self.match(TokenType.Semicolon)) {
        return null;
    }

    return AST.Node.Empty;
}

fn parseIfStatement(self: *Parser) CompilationError!?AST.Node.Index {
    const main_token = self.cur_token;
    if (!self.match(TokenType.If)) {
        return null;
    }

    _ = try self.consume(TokenType.OpenParen, diagnostics.ARG_expected, .{"("});
    const cond = try expectExpression(self);
    _ = try self.consume(TokenType.CloseParen, diagnostics.ARG_expected, .{")"});
    const then = try expectStatement(self);

    const else_node = if (self.match(TokenType.Else)) try expectStatement(self) else AST.Node.Empty;

    return self.addNode(main_token, AST.Node{ .@"if" = AST.Node.If{
        .expr = cond,
        .body = then,
        .@"else" = else_node,
    } });
}

test "should parse statements" {
    const tests = .{
        .{
            \\ {}
            \\>^
            ,
            AST.Node{ .block = &.{} },
        },
        .{
            \\ class A {}
            \\>^
            ,
            AST.Node{ .class = .{
                .abstract = false,
                .name = Token.at(1),
                .super_class = AST.Node.Empty,
                .implements = &.{},
                .body = &.{},
            } },
        },
        .{
            \\ import 'a';
            \\>^
            ,
            AST.Node{ .import = .{ .simple = Token.at(1) } },
        },
        .{
            \\ export default a;
            \\>^
            ,
            AST.Node{ .@"export" = AST.Node.Export{ .default = AST.Node.at(1) } },
        },
        .{
            ";",
            AST.Node{ .root = &.{} },
        },
        .{
            \\ if (a) {}
            \\>^
            ,
            AST.Node{ .@"if" = AST.Node.If{ .expr = AST.Node.at(1), .body = AST.Node.at(2), .@"else" = AST.Node.Empty } },
        },
        .{
            \\ while (a) {}
            \\>^
            ,
            AST.Node{ .@"while" = AST.Node.While{ .cond = AST.Node.at(1), .body = AST.Node.at(2) } },
        },
        .{
            \\ return;
            \\>^
            ,
            AST.Node{ .@"return" = AST.Node.Empty },
        },
        .{
            \\ a;
            \\>^
            ,
            AST.Node{ .simple_value = .{ .kind = .identifier } },
        },
    };

    inline for (tests) |test_case| {
        try TestParser.run(test_case[0], parseStatement, struct {
            pub fn expect(t: TestParser, node: ?AST.Node.Index, comptime markers: MarkerList(test_case[0])) !void {
                try t.expectAST(node, test_case[1]);

                if (markers.len > 0) {
                    try t.expectTokenAt(markers[0], node.?);
                }
            }
        });
    }
}

test "should parse block" {
    const text = "{ a; b; c; }";

    try TestParser.run(text, parseBlock, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectAST(node, AST.Node{ .block = @constCast(&[_]AST.Node.Index{ AST.Node.at(1), AST.Node.at(2), AST.Node.at(3) }) });
        }
    });
}

test "should return syntax error if closing bracket for block is missing" {
    const text =
        \\{a;
        \\>  ^
    ;

    try TestParser.runAny(text, parseBlock, struct {
        pub fn expect(t: TestParser, nodeOrError: CompilationError!?AST.Node.Index, comptime markers: MarkerList(text)) !void {
            try t.expectSyntaxErrorAt(nodeOrError, diagnostics.ARG_expected, .{"}"}, markers[0]);
        }
    });
}

test "should parse declarations" {
    const tests = .{
        .{
            "var a;",
            &[_]AST.Raw{
                AST.Raw{ .tag = .decl_binding, .main_token = Token.at(1), .data = .{ .lhs = 1, .rhs = 0 } },
                AST.Raw{ .tag = .var_decl, .main_token = Token.at(0), .data = .{ .lhs = 2, .rhs = 3 } },
            },
        },
        .{
            "let a;",
            &[_]AST.Raw{
                AST.Raw{ .tag = .decl_binding, .main_token = Token.at(1), .data = .{ .lhs = 1, .rhs = 0 } },
                AST.Raw{ .tag = .let_decl, .main_token = Token.at(0), .data = .{ .lhs = 2, .rhs = 3 } },
            },
        },
        .{
            "const a;",
            &[_]AST.Raw{
                AST.Raw{ .tag = .decl_binding, .main_token = Token.at(1), .data = .{ .lhs = 1, .rhs = 0 } },
                AST.Raw{ .tag = .const_decl, .main_token = Token.at(0), .data = .{ .lhs = 2, .rhs = 3 } },
            },
        },
        .{
            "const a = 1;",
            &[_]AST.Raw{
                AST.Raw{ .tag = .simple_value, .main_token = Token.at(3), .data = .{ .lhs = 3, .rhs = 0 } },
                AST.Raw{ .tag = .decl_binding, .main_token = Token.at(1), .data = .{ .lhs = 1, .rhs = 0 } },
                AST.Raw{ .tag = .const_decl, .main_token = Token.at(0), .data = .{ .lhs = 2, .rhs = 3 } },
            },
        },
        .{
            "const a = 1, b = 2;",
            &[_]AST.Raw{
                AST.Raw{ .tag = .simple_value, .main_token = Token.at(3), .data = .{ .lhs = 3, .rhs = 0 } },
                AST.Raw{ .tag = .decl_binding, .main_token = Token.at(1), .data = .{ .lhs = 1, .rhs = 0 } },
                AST.Raw{ .tag = .simple_value, .main_token = Token.at(7), .data = .{ .lhs = 3, .rhs = 0 } },
                AST.Raw{ .tag = .decl_binding, .main_token = Token.at(5), .data = .{ .lhs = 5, .rhs = 2 } },
                AST.Raw{ .tag = .const_decl, .main_token = Token.at(0), .data = .{ .lhs = 4, .rhs = 6 } },
            },
        },
        .{
            "const a: number = 1;",
            &[_]AST.Raw{
                AST.Raw{ .tag = .simple_type, .main_token = Token.at(3), .data = .{ .lhs = 3, .rhs = 0 } },
                AST.Raw{ .tag = .simple_value, .main_token = Token.at(5), .data = .{ .lhs = 3, .rhs = 0 } },
                AST.Raw{ .tag = .decl_binding, .main_token = Token.at(1), .data = .{ .lhs = 1, .rhs = 0 } },
                AST.Raw{ .tag = .const_decl, .main_token = Token.at(0), .data = .{ .lhs = 2, .rhs = 3 } },
            },
        },
    };

    inline for (tests) |test_case| {
        try TestParser.run(test_case[0], parseDeclaration, struct {
            pub fn expect(t: TestParser, _: ?AST.Node.Index, _: MarkerList(test_case[0])) !void {
                try t.expectNodesToEqual(test_case[1]);
            }
        });
    }
}

test "should parse empty return statement" {
    const text =
        \\ return;
        \\>^
    ;

    try TestParser.run(text, parseReturnStatement, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, comptime markers: MarkerList(text)) !void {
            try t.expectAST(node, AST.Node{ .@"return" = AST.Node.Empty });
            try t.expectTokenAt(markers[0], node.?);
        }
    });
}

test "should parse return statement" {
    const text =
        \\ return a;
        \\>^
    ;

    try TestParser.run(text, parseReturnStatement, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, comptime markers: MarkerList(text)) !void {
            try t.expectAST(node, AST.Node{ .@"return" = AST.Node.at(1) });
            try t.expectTokenAt(markers[0], node.?);
        }
    });
}

test "should parse if statement" {
    const text =
        \\ if (a) {}
        \\>^
    ;

    try TestParser.run(text, parseIfStatement, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, comptime markers: MarkerList(text)) !void {
            try t.expectAST(node, AST.Node{ .@"if" = AST.Node.If{
                .expr = AST.Node.at(1),
                .body = AST.Node.at(2),
                .@"else" = AST.Node.Empty,
            } });
            try t.expectTokenAt(markers[0], node.?);
        }
    });
}

test "should parse if statement with else" {
    const text =
        \\ if (a) {} else {}
        \\>^
    ;

    try TestParser.run(text, parseIfStatement, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, comptime markers: MarkerList(text)) !void {
            try t.expectAST(node, AST.Node{ .@"if" = AST.Node.If{
                .expr = AST.Node.at(1),
                .body = AST.Node.at(2),
                .@"else" = AST.Node.at(3),
            } });
            try t.expectTokenAt(markers[0], node.?);
        }
    });
}

test "should return syntax error if open paren is missing" {
    const text =
        \\if a) {} else
        \\>  ^
    ;

    try TestParser.runAny(text, parseIfStatement, struct {
        pub fn expect(t: TestParser, nodeOrError: CompilationError!?AST.Node.Index, comptime markers: MarkerList(text)) !void {
            try t.expectSyntaxErrorAt(nodeOrError, diagnostics.ARG_expected, .{"("}, markers[0]);
        }
    });
}

test "should return syntax error if close paren is missing" {
    const text =
        \\if (a {}
        \\>     ^
    ;

    try TestParser.runAny(text, parseIfStatement, struct {
        pub fn expect(t: TestParser, nodeOrError: CompilationError!?AST.Node.Index, comptime markers: MarkerList(text)) !void {
            try t.expectSyntaxErrorAt(nodeOrError, diagnostics.ARG_expected, .{")"}, markers[0]);
        }
    });
}

test "should return syntax error if body is missing" {
    const text =
        \\if (a)
        \\>     ^
    ;

    try TestParser.runAny(text, parseIfStatement, struct {
        pub fn expect(t: TestParser, nodeOrError: CompilationError!?AST.Node.Index, comptime markers: MarkerList(text)) !void {
            try t.expectSyntaxErrorAt(nodeOrError, diagnostics.statement_expected, .{}, markers[0]);
        }
    });
}
