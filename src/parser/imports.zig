const std = @import("std");
const Parser = @import("../parser.zig");
const AST = @import("../ast.zig");
const Token = @import("../consts.zig").Token;
const TokenType = @import("../consts.zig").TokenType;
const ParserError = Parser.ParserError;
const diagnostics = @import("../diagnostics.zig");

const parseAssignment = @import("binary.zig").parseAssignment;

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
        return self.pool.addNode(self.cur_token, .{
            .import = .{ .simple = path },
        });
    }

    const bindings = try parseImportClause(self);

    const path_token = try parseFromClause(self) orelse return self.fail(diagnostics.ARG_expected, .{"from"});

    return self.pool.addNode(self.cur_token, AST.Node{
        .import = .{
            .full = .{
                .bindings = bindings,
                .path = path_token,
            },
        },
    });
}

fn parseImportClause(self: *Parser) ParserError![]AST.Node.Index {
    var bindings = std.ArrayList(AST.Node.Index).init(self.arena.allocator());

    bindings.append(
        try parseImportDefaultBinding(self) orelse
            try parseImportNamespaceBinding(self) orelse
            try parseImportNamedBindings(self) orelse
            return self.fail(diagnostics.declaration_or_statement_expected, .{}),
    ) catch unreachable;

    if (self.pool.getNode(bindings.items[0]).import_binding == .default) {
        if (self.match(TokenType.Comma)) {
            bindings.append(
                try parseImportNamespaceBinding(self) orelse
                    try parseImportNamedBindings(self) orelse
                    return self.fail(diagnostics.ARG_expected, .{"{"}),
            ) catch unreachable;
        }
    }

    return bindings.toOwnedSlice() catch unreachable;
}

fn parseImportDefaultBinding(self: *Parser) !?AST.Node.Index {
    if (self.consumeOrNull(TokenType.Identifier)) |identifier| {
        return self.pool.addNode(self.cur_token, .{ .import_binding = .{ .default = identifier } });
    }

    return null;
}

fn parseImportNamespaceBinding(self: *Parser) !?AST.Node.Index {
    if (!self.match(TokenType.Star)) {
        return null;
    }

    _ = try self.consume(TokenType.As, diagnostics.ARG_expected, .{"as"});
    const identifier = try self.consume(TokenType.Identifier, diagnostics.identifier_expected, .{});

    return self.pool.addNode(self.cur_token, .{ .import_binding = .{ .namespace = identifier } });
}

fn parseImportNamedBindings(self: *Parser) !?AST.Node.Index {
    if (!self.match(TokenType.OpenCurlyBrace)) {
        return null;
    }

    var named_bindings = std.ArrayList(AST.Node.Index).init(self.arena.allocator());

    while (true) {
        if (self.consumeOrNull(TokenType.Identifier)) |identifier| {
            named_bindings.append(identifier) catch unreachable;
        }

        if (self.match(TokenType.CloseCurlyBrace)) {
            break;
        }
        _ = try self.consume(TokenType.Comma, diagnostics.ARG_expected, .{","});
    }

    return self.pool.addNode(self.cur_token, .{ .import_binding = .{
        .named = named_bindings.toOwnedSlice() catch unreachable,
    } });
}

pub fn parseExportStatement(self: *Parser) ParserError!?AST.Node.Index {
    if (!self.match(TokenType.Export)) {
        return null;
    }

    if (try parseExportFromClause(self)) |export_node| {
        return export_node;
    }

    const node = try self.parseDeclaration() orelse
        try self.parseClassStatement(false) orelse
        try self.parseAbstractClassStatement() orelse
        try parseDefaultExport(self) orelse
        return self.fail(diagnostics.declaration_or_statement_expected, .{});

    return self.pool.addNode(self.cur_token, .{ .@"export" = .{
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
        return self.pool.addNode(self.cur_token, AST.Node{ .@"export" = .{
            .from_all = .{
                .alias = namespace,
                .path = path_token,
            },
        } });
    }

    if (self.match(TokenType.OpenCurlyBrace)) {
        var exports = std.ArrayList(AST.Node.Index).init(self.arena.allocator());

        while (!self.match(TokenType.CloseCurlyBrace)) {
            const identifier = try self.consume(TokenType.Identifier, diagnostics.identifier_expected, .{});
            var alias: Token.Index = 0;
            if (self.match(TokenType.As)) {
                alias = try self.consume(TokenType.Identifier, diagnostics.identifier_expected, .{});
            }

            exports.append(identifier) catch unreachable;

            if (self.match(TokenType.CloseCurlyBrace)) {
                break;
            }
            _ = try self.consume(TokenType.Comma, diagnostics.ARG_expected, .{","});
        }

        const path = try parseFromClause(self);
        return self.pool.addNode(self.cur_token, AST.Node{
            .@"export" = .{
                .from = .{
                    .bindings = exports.toOwnedSlice() catch unreachable,
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

    return try self.parseFunctionStatement(AST.FunctionFlags.None) orelse
        try self.parseAsyncFunctionStatement() orelse
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
    var parser = try Parser.init(std.testing.allocator, text);
    defer parser.deinit();

    const node = try parseImportStatement(&parser);

    const full_import = .{
        .bindings = @constCast(&[_]AST.Node.Index{1}),
        .path = 3,
    };
    try expectEqualDeep(AST.Node{ .import = .{ .full = full_import } }, parser.pool.getNode(node.?));
    try expectEqualDeep(AST.Node{ .import_binding = .{ .default = 1 } }, parser.pool.getNode(full_import.bindings[0]));
}

test "should parse namespace import statement" {
    const text = "import * as Foo from 'bar'";
    var parser = try Parser.init(std.testing.allocator, text);
    defer parser.deinit();

    const node = try parseImportStatement(&parser);

    const full_import = .{
        .bindings = @constCast(&[_]AST.Node.Index{1}),
        .path = 5,
    };
    try expectEqualDeep(AST.Node{ .import = .{ .full = full_import } }, parser.pool.getNode(node.?));
    try expectEqualDeep(AST.Node{ .import_binding = .{ .namespace = 3 } }, parser.pool.getNode(full_import.bindings[0]));
}

test "should return error if \"as\" is missing" {
    const text = "import * foo from 'bar'";

    try expectSyntaxError(parseImportStatement, text, diagnostics.ARG_expected, .{"as"});
}

test "should parse named import statement" {
    const text = "import { foo, bar } from 'bar'";
    var parser = try Parser.init(std.testing.allocator, text);
    defer parser.deinit();

    const node = try parseImportStatement(&parser);

    const full_import = .{
        .bindings = @constCast(&[_]AST.Node.Index{1}),
        .path = 7,
    };
    try expectEqualDeep(AST.Node{ .import = .{ .full = full_import } }, parser.pool.getNode(node.?));
    try expectEqualDeep(AST.Node{ .import_binding = .{ .named = @constCast(&[_]AST.Node.Index{ 2, 4 }) } }, parser.pool.getNode(full_import.bindings[0]));
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

    try expectMaybeAST(parseImportStatement, AST.Node{ .import = .{ .full = .{
        .bindings = @constCast(&[_]AST.Node.Index{ 1, 2 }),
        .path = 7,
    } } }, text);
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
