const std = @import("std");
const Parser = @import("../parser.zig");
const AST = @import("../ast.zig");
const Token = @import("../consts.zig").Token;
const TokenType = @import("../consts.zig").TokenType;
const ParserError = Parser.ParserError;
const diagnostics = @import("../diagnostics.zig");

const parseAbstractClassStatement = @import("classes.zig").parseAbstractClassStatement;
const parseClassStatement = @import("classes.zig").parseClassStatement;
const parseDeclaration = @import("statements.zig").parseDeclaration;
const parseAssignment = @import("binary.zig").parseAssignment;
const parseFunctionStatement = @import("functions.zig").parseFunctionStatement;
const parseAsyncFunctionStatement = @import("functions.zig").parseAsyncFunctionStatement;

const assert = std.debug.assert;
const expectEqual = std.testing.expectEqual;
const expectEqualStrings = std.testing.expectEqualStrings;
const expectEqualDeep = std.testing.expectEqualDeep;
const expectError = std.testing.expectError;
const expectMaybeAST = Parser.expectMaybeAST;
const expectSyntaxError = Parser.expectSyntaxError;

pub fn parseImportStatement(self: *Parser) ParserError!?AST.Node.Index {
    if (!self.match(TokenType.Import)) {
        return null;
    }
    if (self.consumeOrNull(TokenType.StringConstant)) |path| {
        return self.addNode(self.cur_token, .{
            .import = .{ .simple = path },
        });
    }

    const bindings = try parseImportClause(self);
    defer bindings.deinit();

    const path_token = try parseFromClause(self) orelse return self.fail(diagnostics.ARG_expected, .{"from"});

    return self.addNode(self.cur_token, AST.Node{
        .import = .{
            .full = .{
                .bindings = bindings.items,
                .path = path_token,
            },
        },
    });
}

fn parseImportClause(self: *Parser) ParserError!std.ArrayList(AST.Node.Index) {
    var bindings = std.ArrayList(AST.Node.Index).init(self.gpa);
    errdefer bindings.deinit();

    bindings.append(
        try parseImportDefaultBinding(self) orelse
            try parseImportNamespaceBinding(self) orelse
            try parseImportNamedBindings(self) orelse
            return self.fail(diagnostics.declaration_or_statement_expected, .{}),
    ) catch unreachable; // LCOV_EXCL_LINE

    if (self.getNode(bindings.items[0]).import_binding == .default) {
        if (self.match(TokenType.Comma)) {
            bindings.append(
                try parseImportNamespaceBinding(self) orelse
                    try parseImportNamedBindings(self) orelse
                    return self.fail(diagnostics.ARG_expected, .{"{"}),
            ) catch unreachable;
        }
    }

    return bindings;
}

fn parseImportDefaultBinding(self: *Parser) !?AST.Node.Index {
    if (self.consumeOrNull(TokenType.Identifier)) |identifier| {
        return self.addNode(self.cur_token, .{ .import_binding = .{ .default = identifier } });
    }

    return null;
}

fn parseImportNamespaceBinding(self: *Parser) !?AST.Node.Index {
    if (!self.match(TokenType.Star)) {
        return null;
    }

    _ = try self.consume(TokenType.As, diagnostics.ARG_expected, .{"as"});
    const identifier = try self.consume(TokenType.Identifier, diagnostics.identifier_expected, .{});

    return self.addNode(self.cur_token, .{ .import_binding = .{ .namespace = identifier } });
}

fn parseImportNamedBindings(self: *Parser) !?AST.Node.Index {
    if (!self.match(TokenType.OpenCurlyBrace)) {
        return null;
    }

    var named_bindings = std.ArrayList(AST.Node.Index).init(self.gpa);
    defer named_bindings.deinit();

    while (true) {
        if (self.consumeOrNull(TokenType.Identifier)) |identifier| {
            const alias = if (self.match(TokenType.As))
                try self.consume(TokenType.Identifier, diagnostics.identifier_expected, .{})
            else
                AST.Node.Empty;
            const binding_decl = self.addNode(identifier, AST.Node{
                .binding_decl = .{
                    .name = identifier,
                    .alias = alias,
                },
            });
            named_bindings.append(binding_decl) catch unreachable;
        }

        if (self.match(TokenType.CloseCurlyBrace)) {
            break;
        }
        _ = try self.consume(TokenType.Comma, diagnostics.ARG_expected, .{","});
    }

    return self.addNode(self.cur_token, .{ .import_binding = .{
        .named = named_bindings.items,
    } });
}

pub fn parseExportStatement(self: *Parser) ParserError!?AST.Node.Index {
    if (!self.match(TokenType.Export)) {
        return null;
    }

    if (try parseExportFromClause(self)) |export_node| {
        return export_node;
    }

    if (try parseDefaultExport(self)) |default_export_node| {
        return self.addNode(self.cur_token, .{ .@"export" = .{ .default = default_export_node } });
    }

    const node = try parseDeclaration(self) orelse
        try parseClassStatement(self) orelse
        try parseAbstractClassStatement(self) orelse
        return self.fail(diagnostics.declaration_or_statement_expected, .{});

    return self.addNode(self.cur_token, .{ .@"export" = .{
        .node = node,
    } });
}

fn parseExportFromClause(self: *Parser) ParserError!?AST.Node.Index {
    if (self.match(TokenType.Star)) {
        var namespace: Token.Index = 0;

        if (self.match(TokenType.As)) {
            const identifier = try self.consume(TokenType.Identifier, diagnostics.identifier_expected, .{});
            namespace = identifier;
        }

        const path_token = try parseFromClause(self) orelse return self.fail(diagnostics.ARG_expected, .{"from"});
        return self.addNode(self.cur_token, AST.Node{ .@"export" = .{
            .from_all = .{
                .alias = namespace,
                .path = path_token,
            },
        } });
    }

    if (self.match(TokenType.OpenCurlyBrace)) {
        var exports = std.ArrayList(AST.Node.Index).init(self.gpa);
        defer exports.deinit();

        while (!self.match(TokenType.CloseCurlyBrace)) {
            const identifier = try self.consume(TokenType.Identifier, diagnostics.identifier_expected, .{});
            const alias: Token.Index = if (self.match(TokenType.As))
                try self.consume(TokenType.Identifier, diagnostics.identifier_expected, .{})
            else
                AST.Node.Empty;

            const binding_decl = self.addNode(identifier, AST.Node{
                .binding_decl = .{
                    .name = identifier,
                    .alias = alias,
                },
            });
            exports.append(binding_decl) catch unreachable;

            if (self.match(TokenType.CloseCurlyBrace)) {
                break;
            }
            _ = try self.consume(TokenType.Comma, diagnostics.ARG_expected, .{","});
        }

        const path = try parseFromClause(self);
        return self.addNode(self.cur_token, AST.Node{
            .@"export" = .{
                .from = .{
                    .bindings = exports.items,
                    .path = path orelse AST.Node.Empty,
                },
            },
        });
    }

    return null;
}

fn parseDefaultExport(self: *Parser) ParserError!?AST.Node.Index {
    if (!self.match(TokenType.Default)) {
        return null;
    }

    return try parseFunctionStatement(self) orelse
        try parseAsyncFunctionStatement(self) orelse
        try parseAssignment(self);
}

fn parseFromClause(self: *Parser) ParserError!?Token.Index {
    if (!self.match(TokenType.From)) {
        return null;
    }
    return try self.consume(TokenType.StringConstant, diagnostics.string_literal_expected, .{});
}

test "should return null if its not import statement" {
    const text = "identifier";

    try expectMaybeAST(parseImportStatement, null, text);
}

test "should parse simple import statement" {
    const text = "import 'bar'";

    try expectMaybeAST(parseImportStatement, AST.Node{ .import = .{ .simple = 1 } }, text);
}

test "should parse default import statement" {
    const text = "import Foo from 'bar'";
    var parser = Parser.init(std.testing.allocator, text);
    defer parser.deinit();

    const node = try parseImportStatement(&parser);

    const full_import = .{
        .bindings = @constCast(&[_]AST.Node.Index{1}),
        .path = 3,
    };
    try expectEqualDeep(AST.Node{ .import = .{ .full = full_import } }, parser.getNode(node.?));
    try expectEqualDeep(AST.Node{ .import_binding = .{ .default = 1 } }, parser.getNode(full_import.bindings[0]));
}

test "should parse namespace import statement" {
    const text = "import * as Foo from 'bar'";
    var parser = Parser.init(std.testing.allocator, text);
    defer parser.deinit();

    const node = try parseImportStatement(&parser);

    const full_import = .{
        .bindings = @constCast(&[_]AST.Node.Index{1}),
        .path = 5,
    };
    try expectEqualDeep(AST.Node{ .import = .{ .full = full_import } }, parser.getNode(node.?));
    try expectEqualDeep(AST.Node{ .import_binding = .{ .namespace = 3 } }, parser.getNode(full_import.bindings[0]));
}

test "should return error if \"as\" is missing" {
    const text = "import * foo from 'bar'";

    try expectSyntaxError(parseImportStatement, text, diagnostics.ARG_expected, .{"as"});
}

test "should parse named import statement" {
    const text = "import { foo, bar } from 'bar'";
    var parser = Parser.init(std.testing.allocator, text);
    defer parser.deinit();

    _ = try parseImportStatement(&parser);

    var expected_nodes = [_]AST.Raw{
        AST.Raw{ .tag = .binding_decl, .main_token = 2, .data = .{ .lhs = 2, .rhs = 0 } },
        AST.Raw{ .tag = .binding_decl, .main_token = 4, .data = .{ .lhs = 4, .rhs = 0 } },
        AST.Raw{ .tag = .import_binding_named, .main_token = 6, .data = .{ .lhs = 0, .rhs = 2 } },
        AST.Raw{ .tag = .import, .main_token = 8, .data = .{ .lhs = 3, .rhs = 7 } },
    };
    try parser.expectNodesToEqual(&expected_nodes);
}

test "should parse named bindings with aliases in import statement" {
    const text = "import { foo as bar, baz as qux } from 'bar'";
    var parser = Parser.init(std.testing.allocator, text);
    defer parser.deinit();

    _ = try parseImportStatement(&parser);

    var expected_nodes = [_]AST.Raw{
        AST.Raw{ .tag = .binding_decl, .main_token = 2, .data = .{ .lhs = 2, .rhs = 4 } },
        AST.Raw{ .tag = .binding_decl, .main_token = 6, .data = .{ .lhs = 6, .rhs = 8 } },
        AST.Raw{ .tag = .import_binding_named, .main_token = 10, .data = .{ .lhs = 0, .rhs = 2 } },
        AST.Raw{ .tag = .import, .main_token = 12, .data = .{ .lhs = 3, .rhs = 11 } },
    };
    try parser.expectNodesToEqual(&expected_nodes);
}

test "should return syntax error if alias in import binding is not a string" {
    const text = "import { foo as 123 } from 'bar'";

    try expectSyntaxError(parseImportStatement, text, diagnostics.identifier_expected, .{});
}

test "should return error if comma is missing" {
    const text = "import {foo bar} from 'bar'";

    try expectSyntaxError(parseImportStatement, text, diagnostics.ARG_expected, .{","});
}

test "should return error if its not binding" {
    const text = "import + from 'bar'";

    try expectSyntaxError(parseImportStatement, text, diagnostics.declaration_or_statement_expected, .{});
}

test "should parse default import and namespace binding" {
    const text = "import foo, * as bar from 'bar'";

    try expectMaybeAST(parseImportStatement, AST.Node{ .import = .{ .full = .{
        .bindings = @constCast(&[_]AST.Node.Index{ 1, 2 }),
        .path = 7,
    } } }, text);
}

test "should parse default import and named binding" {
    const text = "import foo, { bar } from 'bar'";
    var parser = Parser.init(std.testing.allocator, text);
    defer parser.deinit();

    _ = try parseImportStatement(&parser);

    var expected_nodes = [_]AST.Raw{
        AST.Raw{ .tag = .import_binding_default, .main_token = 2, .data = .{ .lhs = 1, .rhs = 0 } },
        AST.Raw{ .tag = .binding_decl, .main_token = 4, .data = .{ .lhs = 4, .rhs = 0 } },
        AST.Raw{ .tag = .import_binding_named, .main_token = 6, .data = .{ .lhs = 0, .rhs = 1 } },
        AST.Raw{ .tag = .import, .main_token = 8, .data = .{ .lhs = 3, .rhs = 7 } },
    };
    try parser.expectNodesToEqual(&expected_nodes);
}

test "should return error if second binding list is not valid binding" {
    const text = "import foo, + from 'bar'";

    try expectSyntaxError(parseImportStatement, text, diagnostics.ARG_expected, .{"{"});
}

test "should return error if path is missing" {
    const text = "import foo";

    try expectSyntaxError(parseImportStatement, text, diagnostics.ARG_expected, .{"from"});
}

test "should return error if path is not a string" {
    const text = "import foo from 123";

    try expectSyntaxError(parseImportStatement, text, diagnostics.string_literal_expected, .{});
}

test "should return null if its not export statement" {
    const text = "identifier";

    try expectMaybeAST(parseExportStatement, null, text);
}

test "should parse export statement with named bindings" {
    const text = "export { foo, bar } from './foo';";
    var parser = Parser.init(std.testing.allocator, text);
    defer parser.deinit();

    _ = try parseExportStatement(&parser);

    var expected_nodes = [_]AST.Raw{
        AST.Raw{ .tag = .binding_decl, .main_token = 2, .data = .{ .lhs = 2, .rhs = 0 } },
        AST.Raw{ .tag = .binding_decl, .main_token = 4, .data = .{ .lhs = 4, .rhs = 0 } },
        AST.Raw{ .tag = .export_from, .main_token = 8, .data = .{ .lhs = 2, .rhs = 7 } },
    };
    try parser.expectNodesToEqual(&expected_nodes);
}

test "should parse export statement with aliased bindings" {
    const text = "export { foo as bar, baz as qux } from './foo';";
    var parser = Parser.init(std.testing.allocator, text);
    defer parser.deinit();

    _ = try parseExportStatement(&parser);

    var expected_nodes = [_]AST.Raw{
        AST.Raw{ .tag = .binding_decl, .main_token = 2, .data = .{ .lhs = 2, .rhs = 4 } },
        AST.Raw{ .tag = .binding_decl, .main_token = 6, .data = .{ .lhs = 6, .rhs = 8 } },
        AST.Raw{ .tag = .export_from, .main_token = 12, .data = .{ .lhs = 2, .rhs = 11 } },
    };
    try parser.expectNodesToEqual(&expected_nodes);
}

test "should return syntax error if path is not a string" {
    const text = "export { foo, bar } from 123;";

    try expectSyntaxError(parseExportStatement, text, diagnostics.string_literal_expected, .{});
}

test "should parse export statement without path" {
    const tests = .{
        .{
            "export { foo, bar };",
            AST.Node{ .@"export" = .{
                .from = .{
                    .bindings = @constCast(&[_]AST.Node.Index{ 1, 2 }),
                    .path = 0,
                },
            } },
        },
        .{
            "export { foo, bar, }",
            AST.Node{ .@"export" = .{
                .from = .{
                    .bindings = @constCast(&[_]AST.Node.Index{ 1, 2 }),
                    .path = 0,
                },
            } },
        },
    };

    inline for (tests) |test_case| {
        try expectMaybeAST(parseExportStatement, test_case[1], test_case[0]);
    }
}

test "should return syntax error if comma is missing" {
    const text = "export { foo bar } from './foo';";

    try expectSyntaxError(parseExportStatement, text, diagnostics.ARG_expected, .{","});
}

test "should return syntax error if binding is not identifier" {
    const text = "export { 123 }";

    try expectSyntaxError(parseExportStatement, text, diagnostics.identifier_expected, .{});
}

test "should parse from all export statement" {
    const text = "export * from './foo';";

    try expectMaybeAST(parseExportStatement, AST.Node{ .@"export" = .{
        .from_all = .{
            .alias = 0,
            .path = 3,
        },
    } }, text);
}

test "should return syntax error if from clause is missing" {
    const text = "export * as alias";

    try expectSyntaxError(parseExportStatement, text, diagnostics.ARG_expected, .{"from"});
}

test "should return syntax error for from all clause if path is not a string" {
    const text = "export * as alias from 123";

    try expectSyntaxError(parseExportStatement, text, diagnostics.string_literal_expected, .{});
}

test "should parse from all export statement with alias" {
    const text = "export * as alias from './foo'";

    try expectMaybeAST(parseExportStatement, AST.Node{ .@"export" = .{
        .from_all = .{
            .alias = 3,
            .path = 5,
        },
    } }, text);
}

test "should return syntax error if alias is not a string" {
    const text = "export * as 123 from './foo'";

    try expectSyntaxError(parseExportStatement, text, diagnostics.identifier_expected, .{});
}

test "should parse export statement with default bindings" {
    const text = "export default identifier";

    try expectMaybeAST(parseExportStatement, AST.Node{
        .@"export" = .{ .default = 2 },
    }, text);
}

test "should parse export node statement" {
    const tests = .{
        .{
            "export class Foo {}",
            AST.Node{ .@"export" = .{ .node = 1 } },
        },
        .{
            "export abstract class Foo {}",
            AST.Node{ .@"export" = .{ .node = 1 } },
        },
        .{
            "export const foo = 1;",
            AST.Node{ .@"export" = .{ .node = 3 } },
        },
        .{
            "export function foo() {}",
            AST.Node{ .@"export" = .{ .node = 2 } },
        },
        .{
            "export async function foo() {}",
            AST.Node{ .@"export" = .{ .node = 2 } },
        },
    };

    inline for (tests) |test_case| {
        try expectMaybeAST(parseExportStatement, test_case[1], test_case[0]);
    }
}

test "should return syntax error if export statement is not a statement" {
    const text = "export 123";

    try expectSyntaxError(parseExportStatement, text, diagnostics.declaration_or_statement_expected, .{});
}
