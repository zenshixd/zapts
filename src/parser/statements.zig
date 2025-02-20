const std = @import("std");
const Parser = @import("../parser.zig");
const ParserError = @import("../parser.zig").ParserError;
const AST = @import("../ast.zig");
const Token = @import("../consts.zig").Token;
const TokenType = @import("../consts.zig").TokenType;
const StringId = @import("../string_interner.zig").StringId;
const diagnostics = @import("../diagnostics.zig");
const snap = @import("../tests/snapshots.zig").snap;
const expectEqual = std.testing.expectEqual;

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

const TestParser = @import("../tests/test_parser.zig");
const Marker = TestParser.Marker;
const MarkerList = TestParser.MarkerList;

pub fn parseStatement(self: *Parser) ParserError!?AST.Node.Index {
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

pub fn expectStatement(self: *Parser) ParserError!AST.Node.Index {
    return try parseStatement(self) orelse self.fail(diagnostics.statement_expected, .{});
}

pub fn parseBlock(self: *Parser) ParserError!?AST.Node.Index {
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

pub fn parseDeclaration(self: *Parser) ParserError!?AST.Node.Index {
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
                .name = self.internStr(identifier),
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

fn parseReturnStatement(self: *Parser) ParserError!?AST.Node.Index {
    const main_token = self.cur_token;
    if (!self.match(TokenType.Return)) {
        return null;
    }

    if (self.peekMatch(TokenType.Semicolon)) {
        return self.addNode(main_token, .{ .@"return" = AST.Node.Empty });
    }

    return self.addNode(main_token, AST.Node{ .@"return" = try expectExpression(self) });
}

fn parseEmptyStatement(self: *Parser) ParserError!?AST.Node.Index {
    if (!self.match(TokenType.Semicolon)) {
        return null;
    }

    return AST.Node.Empty;
}

fn parseIfStatement(self: *Parser) ParserError!?AST.Node.Index {
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
            snap(@src(),
                \\ast.Node{
                \\    .block = [_]ast.Node.Index{},
                \\}
            ),
        },
        .{
            \\ class A {}
            \\>^
            ,
            snap(@src(),
                \\ast.Node{
                \\    .class = ast.Node.ClassDeclaration{
                \\        .abstract = false,
                \\        .name = string_interner.StringId(1),
                \\        .super_class = ast.Node.Index.empty,
                \\        .implements = [_]string_interner.StringId{},
                \\        .body = [_]ast.Node.Index{},
                \\    },
                \\}
            ),
        },
        .{
            \\ import 'a';
            \\>^
            ,
            snap(@src(),
                \\ast.Node{
                \\    .import = ast.Node.Import{
                \\        .simple = string_interner.StringId(1),
                \\    },
                \\}
            ),
        },
        .{
            \\ export default a;
            \\>^
            ,
            snap(@src(),
                \\ast.Node{
                \\    .export = ast.Node.Export{
                \\        .default = ast.Node.Index(0),
                \\    },
                \\}
            ),
        },
        .{
            \\ if (a) {}
            \\>^
            ,
            snap(@src(),
                \\ast.Node{
                \\    .if = ast.Node.If{
                \\        .expr = ast.Node.Index(0),
                \\        .body = ast.Node.Index(1),
                \\        .else = ast.Node.Index.empty,
                \\    },
                \\}
            ),
        },
        .{
            \\ while (a) {}
            \\>^
            ,
            snap(@src(),
                \\ast.Node{
                \\    .while = ast.Node.While{
                \\        .cond = ast.Node.Index(0),
                \\        .body = ast.Node.Index(1),
                \\    },
                \\}
            ),
        },
        .{
            \\ return;
            \\>^
            ,
            snap(@src(),
                \\ast.Node{
                \\    .return = ast.Node.Index.empty,
                \\}
            ),
        },
        .{
            \\ a;
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
    };

    inline for (tests) |test_case| {
        try TestParser.runSnapshot(test_case[0], parseStatement, test_case[1]);
    }
}

test "should parse empty statement" {
    const text = ";";

    try TestParser.run(text, parseEmptyStatement, struct {
        pub fn expect(_: TestParser, node: ?AST.Node.Index, _: MarkerList(text)) !void {
            try expectEqual(AST.Node.Empty, node);
        }
    });
}

test "should parse block" {
    const text = "{ a; b; c; }";

    try TestParser.run(text, parseBlock, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectASTSnapshot(node, snap(@src(),
                \\ast.Node{
                \\    .block = [_]ast.Node.Index{
                \\        ast.Node.Index(0), 
                \\        ast.Node.Index(1), 
                \\        ast.Node.Index(2)
                \\    },
                \\}
            ));
        }
    });
}

test "should return syntax error if closing bracket for block is missing" {
    const text =
        \\{a;
        \\>  ^
    ;

    try TestParser.runAny(text, parseBlock, struct {
        pub fn expect(t: TestParser, nodeOrError: ParserError!?AST.Node.Index, comptime markers: MarkerList(text)) !void {
            try t.expectSyntaxErrorAt(nodeOrError, diagnostics.ARG_expected, .{"}"}, markers[0]);
        }
    });
}

test "should parse declarations" {
    const tests = .{
        .{
            "var a;",
            snap(@src(),
                \\ast.Node{
                \\    .declaration = ast.Node.Declaration{
                \\        .kind = ast.Node.DeclarationKind.var,
                \\        .list = [_]ast.Node.Index{
                \\            ast.Node.Index(0)
                \\        },
                \\    },
                \\}
            ),
        },
        .{
            "let a;",
            snap(@src(),
                \\ast.Node{
                \\    .declaration = ast.Node.Declaration{
                \\        .kind = ast.Node.DeclarationKind.let,
                \\        .list = [_]ast.Node.Index{
                \\            ast.Node.Index(0)
                \\        },
                \\    },
                \\}
            ),
        },
        .{
            "const a;",
            snap(@src(),
                \\ast.Node{
                \\    .declaration = ast.Node.Declaration{
                \\        .kind = ast.Node.DeclarationKind.const,
                \\        .list = [_]ast.Node.Index{
                \\            ast.Node.Index(0)
                \\        },
                \\    },
                \\}
            ),
        },
        .{
            "const a = 1;",
            snap(@src(),
                \\ast.Node{
                \\    .declaration = ast.Node.Declaration{
                \\        .kind = ast.Node.DeclarationKind.const,
                \\        .list = [_]ast.Node.Index{
                \\            ast.Node.Index(1)
                \\        },
                \\    },
                \\}
            ),
        },
        .{
            "const a = 1, b = 2;",
            snap(@src(),
                \\ast.Node{
                \\    .declaration = ast.Node.Declaration{
                \\        .kind = ast.Node.DeclarationKind.const,
                \\        .list = [_]ast.Node.Index{
                \\            ast.Node.Index(1), 
                \\            ast.Node.Index(3)
                \\        },
                \\    },
                \\}
            ),
        },
        .{
            "const a: number = 1;",
            snap(@src(),
                \\ast.Node{
                \\    .declaration = ast.Node.Declaration{
                \\        .kind = ast.Node.DeclarationKind.const,
                \\        .list = [_]ast.Node.Index{
                \\            ast.Node.Index(2)
                \\        },
                \\    },
                \\}
            ),
        },
    };

    inline for (tests) |test_case| {
        try TestParser.runSnapshot(test_case[0], parseDeclaration, test_case[1]);
    }
}

test "should parse empty return statement" {
    const text =
        \\ return;
        \\>^
    ;

    try TestParser.run(text, parseReturnStatement, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, comptime markers: MarkerList(text)) !void {
            try t.expectASTSnapshot(node, snap(@src(),
                \\ast.Node{
                \\    .return = ast.Node.Index.empty,
                \\}
            ));
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
            try t.expectASTSnapshot(node, snap(@src(),
                \\ast.Node{
                \\    .return = ast.Node.Index(0),
                \\}
            ));
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
            try t.expectASTSnapshot(node, snap(@src(),
                \\ast.Node{
                \\    .if = ast.Node.If{
                \\        .expr = ast.Node.Index(0),
                \\        .body = ast.Node.Index(1),
                \\        .else = ast.Node.Index.empty,
                \\    },
                \\}
            ));
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
            try t.expectASTSnapshot(node, snap(@src(),
                \\ast.Node{
                \\    .if = ast.Node.If{
                \\        .expr = ast.Node.Index(0),
                \\        .body = ast.Node.Index(1),
                \\        .else = ast.Node.Index(2),
                \\    },
                \\}
            ));
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
        pub fn expect(t: TestParser, nodeOrError: ParserError!?AST.Node.Index, comptime markers: MarkerList(text)) !void {
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
        pub fn expect(t: TestParser, nodeOrError: ParserError!?AST.Node.Index, comptime markers: MarkerList(text)) !void {
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
        pub fn expect(t: TestParser, nodeOrError: ParserError!?AST.Node.Index, comptime markers: MarkerList(text)) !void {
            try t.expectSyntaxErrorAt(nodeOrError, diagnostics.statement_expected, .{}, markers[0]);
        }
    });
}
