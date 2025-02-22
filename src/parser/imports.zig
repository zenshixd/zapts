const std = @import("std");
const Parser = @import("../parser.zig");
const ParserError = Parser.ParserError;
const AST = @import("../ast.zig");
const Token = @import("../consts.zig").Token;
const TokenType = @import("../consts.zig").TokenType;
const StringId = @import("../string_interner.zig").StringId;
const diagnostics = @import("../diagnostics.zig");
const snap = @import("../tests/snapshots.zig").snap;

const parseAbstractClassStatement = @import("classes.zig").parseAbstractClassStatement;
const parseClassStatement = @import("classes.zig").parseClassStatement;
const parseDeclaration = @import("statements.zig").parseDeclaration;
const parseAssignment = @import("binary.zig").parseAssignment;
const parseFunctionStatement = @import("functions.zig").parseFunctionStatement;
const parseAsyncFunctionStatement = @import("functions.zig").parseAsyncFunctionStatement;
const parseIdentifier = @import("primary.zig").parseIdentifier;
const parseKeywordAsIdentifier = @import("primary.zig").parseKeywordAsIdentifier;

const TestParser = @import("../tests/test_parser.zig");
const Marker = TestParser.Marker;

const assert = std.debug.assert;
const expectEqual = std.testing.expectEqual;
const expectEqualStrings = std.testing.expectEqualStrings;
const expectEqualDeep = std.testing.expectEqualDeep;
const expectError = std.testing.expectError;

pub fn parseImportStatement(self: *Parser) ParserError!?AST.Node.Index {
    const main_token = self.cur_token;
    if (!self.match(TokenType.Import)) {
        return null;
    }
    if (self.consumeOrNull(TokenType.StringConstant)) |path| {
        return self.addNode(main_token, .{
            .import = .{ .simple = self.internStr(path) },
        });
    }

    const bindings = try parseImportClause(self);
    defer bindings.deinit();

    const path_token = try parseFromClause(self) orelse return self.fail(diagnostics.ARG_expected, .{"from"});

    return self.addNode(main_token, AST.Node{
        .import = .{
            .full = .{
                .bindings = bindings.items,
                .path = self.internStr(path_token),
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
    const identifier = self.consumeOrNull(TokenType.Identifier) orelse
        parseKeywordAsIdentifier(self) orelse
        return null;

    return self.addNode(identifier, .{ .import_binding = .{ .default = self.internStr(identifier) } });
}

fn parseImportNamespaceBinding(self: *Parser) !?AST.Node.Index {
    const main_token = self.cur_token;
    if (!self.match(TokenType.Star)) {
        return null;
    }

    _ = try self.consume(TokenType.As, diagnostics.ARG_expected, .{"as"});
    const identifier = try self.consume(TokenType.Identifier, diagnostics.identifier_expected, .{});

    return self.addNode(main_token, .{ .import_binding = .{ .namespace = self.internStr(identifier) } });
}

fn parseImportNamedBindings(self: *Parser) !?AST.Node.Index {
    const main_token = self.cur_token;
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
                Token.Empty;

            const binding_decl = self.addNode(identifier, AST.Node{
                .binding_decl = .{
                    .name = self.internStr(identifier),
                    .alias = self.internStr(alias),
                },
            });
            named_bindings.append(binding_decl) catch unreachable;
        }

        if (self.match(TokenType.CloseCurlyBrace)) {
            break;
        }
        _ = try self.consume(TokenType.Comma, diagnostics.ARG_expected, .{","});
    }

    return self.addNode(main_token, .{ .import_binding = .{
        .named = named_bindings.items,
    } });
}

pub fn parseExportStatement(self: *Parser) ParserError!?AST.Node.Index {
    const main_token = self.cur_token;
    if (!self.match(TokenType.Export)) {
        return null;
    }

    if (try parseExportFromClause(self, main_token)) |export_node| {
        return export_node;
    }

    if (try parseDefaultExport(self)) |default_export_node| {
        return self.addNode(main_token, .{ .@"export" = .{ .default = default_export_node } });
    }

    const node = try parseDeclaration(self) orelse
        try parseClassStatement(self) orelse
        try parseAbstractClassStatement(self) orelse
        return self.fail(diagnostics.declaration_or_statement_expected, .{});

    return self.addNode(main_token, .{ .@"export" = .{
        .node = node,
    } });
}

fn parseExportFromClause(self: *Parser, main_token: Token.Index) ParserError!?AST.Node.Index {
    if (self.match(TokenType.Star)) {
        var namespace: Token.Index = Token.Empty;

        if (self.match(TokenType.As)) {
            namespace = try self.consume(TokenType.Identifier, diagnostics.identifier_expected, .{});
        }

        const path_token = try parseFromClause(self) orelse return self.fail(diagnostics.ARG_expected, .{"from"});
        return self.addNode(main_token, AST.Node{ .@"export" = .{
            .from_all = .{
                .alias = self.internStr(namespace),
                .path = self.internStr(path_token),
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
                Token.Empty;

            const binding_decl = self.addNode(identifier, AST.Node{
                .binding_decl = .{
                    .name = self.internStr(identifier),
                    .alias = self.internStr(alias),
                },
            });
            exports.append(binding_decl) catch unreachable;

            if (self.match(TokenType.CloseCurlyBrace)) {
                break;
            }
            _ = try self.consume(TokenType.Comma, diagnostics.ARG_expected, .{","});
        }

        const path = try parseFromClause(self);
        return self.addNode(main_token, AST.Node{
            .@"export" = .{
                .from = .{
                    .bindings = exports.items,
                    .path = self.internStr(path orelse Token.Empty),
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

    const t, const node, _ = try TestParser.run(text, parseImportStatement);
    defer t.deinit();

    try t.expectAST(node, null);
}

test "should parse simple import statement" {
    const text =
        \\ import 'bar'
        \\>^
    ;

    const t, const node, const markers = try TestParser.run(text, parseImportStatement);
    defer t.deinit();

    try t.expectASTSnapshot(node, snap(@src(),
        \\ast.Node{
        \\    .import = ast.Node.Import{
        \\        .simple = string_interner.StringId(1),
        \\    },
        \\}
    ));
    try t.expectTokenAt(markers[0], node.?);
}

test "should parse default import statement" {
    const text =
        \\ import Foo from 'bar'
        \\>^      ^
    ;

    const t, const node, const markers = try TestParser.run(text, parseImportStatement);
    defer t.deinit();

    try t.expectASTSnapshot(node, snap(@src(),
        \\ast.Node{
        \\    .import = ast.Node.Import{
        \\        .full = ast.Node.ImportFull{
        \\            .bindings = [_]ast.Node.Index{
        \\                ast.Node.Index(0)
        \\            },
        \\            .path = string_interner.StringId(2),
        \\        },
        \\    },
        \\}
    ));
    try t.expectTokenAt(markers[0], node.?);

    const full_import = t.parser.getNode(node.?).import.full;
    try t.expectASTSnapshot(full_import.bindings[0], snap(@src(),
        \\ast.Node{
        \\    .import_binding = ast.Node.ImportBinding{
        \\        .default = string_interner.StringId(1),
        \\    },
        \\}
    ));
    try t.expectTokenAt(markers[1], full_import.bindings[0]);
}

test "should parse namespace import statement" {
    const text =
        \\ import * as Foo from 'bar'
        \\>^      ^
    ;

    const t, const node, const markers = try TestParser.run(text, parseImportStatement);
    defer t.deinit();

    try t.expectASTSnapshot(node, snap(@src(),
        \\ast.Node{
        \\    .import = ast.Node.Import{
        \\        .full = ast.Node.ImportFull{
        \\            .bindings = [_]ast.Node.Index{
        \\                ast.Node.Index(0)
        \\            },
        \\            .path = string_interner.StringId(2),
        \\        },
        \\    },
        \\}
    ));
    try t.expectTokenAt(markers[0], node.?);

    const full_import = t.parser.getNode(node.?).import.full;
    try t.expectASTSnapshot(full_import.bindings[0], snap(@src(),
        \\ast.Node{
        \\    .import_binding = ast.Node.ImportBinding{
        \\        .namespace = string_interner.StringId(1),
        \\    },
        \\}
    ));
    try t.expectTokenAt(markers[1], full_import.bindings[0]);
}

test "should return error if \"as\" is missing" {
    const text =
        \\import * foo from 'bar'
        \\>        ^
    ;

    const t, const nodeOrError, const markers = try TestParser.runCatch(text, parseImportStatement);
    defer t.deinit();

    try t.expectSyntaxErrorAt(nodeOrError, diagnostics.ARG_expected, .{"as"}, markers[0]);
}

test "should parse named import statement" {
    const text =
        \\ import { foo, bar } from 'bar'
        \\>^      ^ ^    ^
    ;

    const t, const node, const markers = try TestParser.run(text, parseImportStatement);
    defer t.deinit();

    try t.expectASTSnapshot(node, snap(@src(),
        \\ast.Node{
        \\    .import = ast.Node.Import{
        \\        .full = ast.Node.ImportFull{
        \\            .bindings = [_]ast.Node.Index{
        \\                ast.Node.Index(2)
        \\            },
        \\            .path = string_interner.StringId(3),
        \\        },
        \\    },
        \\}
    ));
    try t.expectTokenAt(markers[0], node.?);

    const full_import = t.parser.getNode(node.?).import.full;
    try t.expectASTSnapshot(full_import.bindings[0], snap(@src(),
        \\ast.Node{
        \\    .import_binding = ast.Node.ImportBinding{
        \\        .named = [_]ast.Node.Index{
        \\            ast.Node.Index(0), 
        \\            ast.Node.Index(1)
        \\        },
        \\    },
        \\}
    ));
    try t.expectTokenAt(markers[1], full_import.bindings[0]);

    const named_bindings = t.parser.getNode(full_import.bindings[0]).import_binding.named;
    try t.expectASTSnapshot(named_bindings[0], snap(@src(),
        \\ast.Node{
        \\    .binding_decl = ast.Node.BindingDecl{
        \\        .name = string_interner.StringId(1),
        \\        .alias = string_interner.StringId.none,
        \\    },
        \\}
    ));
    try t.expectTokenAt(markers[2], named_bindings[0]);

    try t.expectASTSnapshot(named_bindings[1], snap(@src(),
        \\ast.Node{
        \\    .binding_decl = ast.Node.BindingDecl{
        \\        .name = string_interner.StringId(2),
        \\        .alias = string_interner.StringId.none,
        \\    },
        \\}
    ));
    try t.expectTokenAt(markers[3], named_bindings[1]);
}

test "should parse named bindings with aliases in import statement" {
    const text =
        \\ import { foo as bar, baz as qux } from 'bar'
        \\>^      ^ ^           ^
    ;

    const t, const node, const markers = try TestParser.run(text, parseImportStatement);
    defer t.deinit();

    try t.expectASTSnapshot(node, snap(@src(),
        \\ast.Node{
        \\    .import = ast.Node.Import{
        \\        .full = ast.Node.ImportFull{
        \\            .bindings = [_]ast.Node.Index{
        \\                ast.Node.Index(2)
        \\            },
        \\            .path = string_interner.StringId(5),
        \\        },
        \\    },
        \\}
    ));
    try t.expectTokenAt(markers[0], node.?);

    const full_import = t.parser.getNode(node.?).import.full;
    try t.expectASTSnapshot(full_import.bindings[0], snap(@src(),
        \\ast.Node{
        \\    .import_binding = ast.Node.ImportBinding{
        \\        .named = [_]ast.Node.Index{
        \\            ast.Node.Index(0), 
        \\            ast.Node.Index(1)
        \\        },
        \\    },
        \\}
    ));
    try t.expectTokenAt(markers[1], full_import.bindings[0]);

    const named_bindings = t.parser.getNode(full_import.bindings[0]).import_binding.named;
    try t.expectASTSnapshot(named_bindings[0], snap(@src(),
        \\ast.Node{
        \\    .binding_decl = ast.Node.BindingDecl{
        \\        .name = string_interner.StringId(1),
        \\        .alias = string_interner.StringId(2),
        \\    },
        \\}
    ));
    try t.expectTokenAt(markers[2], named_bindings[0]);

    try t.expectASTSnapshot(named_bindings[1], snap(@src(),
        \\ast.Node{
        \\    .binding_decl = ast.Node.BindingDecl{
        \\        .name = string_interner.StringId(3),
        \\        .alias = string_interner.StringId(4),
        \\    },
        \\}
    ));
    try t.expectTokenAt(markers[3], named_bindings[1]);
}

test "should return syntax error if alias in import binding is not a string" {
    const text =
        \\import { foo as 123 } from 'bar'
        \\>               ^
    ;

    const t, const nodeOrError, const markers = try TestParser.runCatch(text, parseImportStatement);
    defer t.deinit();

    try t.expectSyntaxErrorAt(nodeOrError, diagnostics.identifier_expected, .{}, markers[0]);
}

test "should return error if comma is missing" {
    const text =
        \\import {foo bar} from 'bar'
        \\>           ^
    ;

    const t, const nodeOrError, const markers = try TestParser.runCatch(text, parseImportStatement);
    defer t.deinit();

    try t.expectSyntaxErrorAt(nodeOrError, diagnostics.ARG_expected, .{","}, markers[0]);
}

test "should return error if its not binding" {
    const text =
        \\import + from 'bar'
        \\>      ^
    ;

    const t, const nodeOrError, const markers = try TestParser.runCatch(text, parseImportStatement);
    defer t.deinit();

    try t.expectSyntaxErrorAt(nodeOrError, diagnostics.declaration_or_statement_expected, .{}, markers[0]);
}

test "should parse default import and namespace binding" {
    const text =
        \\ import foo, * as bar from 'bar'
        \\>^      ^    ^
    ;

    const t, const node, const markers = try TestParser.run(text, parseImportStatement);
    defer t.deinit();

    try t.expectASTSnapshot(node, snap(@src(),
        \\ast.Node{
        \\    .import = ast.Node.Import{
        \\        .full = ast.Node.ImportFull{
        \\            .bindings = [_]ast.Node.Index{
        \\                ast.Node.Index(0), 
        \\                ast.Node.Index(1)
        \\            },
        \\            .path = string_interner.StringId(3),
        \\        },
        \\    },
        \\}
    ));
    try t.expectTokenAt(markers[0], node.?);

    const full_import = t.parser.getNode(node.?).import.full;
    try t.expectASTSnapshot(full_import.bindings[0], snap(@src(),
        \\ast.Node{
        \\    .import_binding = ast.Node.ImportBinding{
        \\        .default = string_interner.StringId(1),
        \\    },
        \\}
    ));
    try t.expectTokenAt(markers[1], full_import.bindings[0]);

    try t.expectASTSnapshot(full_import.bindings[1], snap(@src(),
        \\ast.Node{
        \\    .import_binding = ast.Node.ImportBinding{
        \\        .namespace = string_interner.StringId(2),
        \\    },
        \\}
    ));
    try t.expectTokenAt(markers[2], full_import.bindings[1]);
}

test "should parse default import and named binding" {
    const text =
        \\ import foo, { bar } from 'bar'
        \\>^      ^    ^
    ;

    const t, const node, const markers = try TestParser.run(text, parseImportStatement);
    defer t.deinit();

    try t.expectASTSnapshot(node, snap(@src(),
        \\ast.Node{
        \\    .import = ast.Node.Import{
        \\        .full = ast.Node.ImportFull{
        \\            .bindings = [_]ast.Node.Index{
        \\                ast.Node.Index(0), 
        \\                ast.Node.Index(2)
        \\            },
        \\            .path = string_interner.StringId(3),
        \\        },
        \\    },
        \\}
    ));
    try t.expectTokenAt(markers[0], node.?);

    const full_import = t.parser.getNode(node.?).import.full;
    try t.expectASTSnapshot(full_import.bindings[0], snap(@src(),
        \\ast.Node{
        \\    .import_binding = ast.Node.ImportBinding{
        \\        .default = string_interner.StringId(1),
        \\    },
        \\}
    ));
    try t.expectTokenAt(markers[1], full_import.bindings[0]);

    try t.expectASTSnapshot(full_import.bindings[0], snap(@src(),
        \\ast.Node{
        \\    .import_binding = ast.Node.ImportBinding{
        \\        .default = string_interner.StringId(1),
        \\    },
        \\}
    ));
    try t.expectTokenAt(markers[1], full_import.bindings[0]);

    try t.expectASTSnapshot(full_import.bindings[1], snap(@src(),
        \\ast.Node{
        \\    .import_binding = ast.Node.ImportBinding{
        \\        .named = [_]ast.Node.Index{
        \\            ast.Node.Index(1)
        \\        },
        \\    },
        \\}
    ));
    try t.expectTokenAt(markers[2], full_import.bindings[1]);
}

test "should return error if second binding list is not valid binding" {
    const text =
        \\import foo, + from 'bar'
        \\>           ^
    ;

    const t, const nodeOrError, const markers = try TestParser.runCatch(text, parseImportStatement);
    defer t.deinit();

    try t.expectSyntaxErrorAt(nodeOrError, diagnostics.ARG_expected, .{"{"}, markers[0]);
}

test "should return error if path is missing" {
    const text =
        \\ import foo
        \\>          ^
    ;

    const t, const nodeOrError, const markers = try TestParser.runCatch(text, parseImportStatement);
    defer t.deinit();

    try t.expectSyntaxErrorAt(nodeOrError, diagnostics.ARG_expected, .{"from"}, markers[0]);
}

test "should return error if path is not a string" {
    const text =
        \\import foo from 123
        \\>               ^
    ;

    const t, const nodeOrError, const markers = try TestParser.runCatch(text, parseImportStatement);
    defer t.deinit();

    try t.expectSyntaxErrorAt(nodeOrError, diagnostics.string_literal_expected, .{}, markers[0]);
}

test "should return null if its not export statement" {
    const text = "identifier";

    const t, const node, _ = try TestParser.run(text, parseExportStatement);
    defer t.deinit();

    try t.expectAST(node, null);
}

test "should parse export statement with named bindings" {
    const text =
        \\ export { foo, bar } from './foo';
        \\>^        ^    ^
    ;

    const t, const node, const markers = try TestParser.run(text, parseExportStatement);
    defer t.deinit();

    try t.expectASTSnapshot(node, snap(@src(),
        \\ast.Node{
        \\    .export = ast.Node.Export{
        \\        .from = ast.Node.ExportFromPath{
        \\            .bindings = [_]ast.Node.Index{
        \\                ast.Node.Index(0), 
        \\                ast.Node.Index(1)
        \\            },
        \\            .path = string_interner.StringId(3),
        \\        },
        \\    },
        \\}
    ));
    try t.expectTokenAt(markers[0], node.?);

    const export_from = t.parser.getNode(node.?).@"export";
    try t.expectASTSnapshot(export_from.from.bindings[0], snap(@src(),
        \\ast.Node{
        \\    .binding_decl = ast.Node.BindingDecl{
        \\        .name = string_interner.StringId(1),
        \\        .alias = string_interner.StringId.none,
        \\    },
        \\}
    ));
    try t.expectTokenAt(markers[1], export_from.from.bindings[0]);

    try t.expectASTSnapshot(export_from.from.bindings[1], snap(@src(),
        \\ast.Node{
        \\    .binding_decl = ast.Node.BindingDecl{
        \\        .name = string_interner.StringId(2),
        \\        .alias = string_interner.StringId.none,
        \\    },
        \\}
    ));
    try t.expectTokenAt(markers[2], export_from.from.bindings[1]);
}

test "should parse export statement with aliased bindings" {
    const text =
        \\ export { foo as bar, baz as qux } from './foo';
        \\>^        ^           ^
    ;

    const t, const node, const markers = try TestParser.run(text, parseExportStatement);
    defer t.deinit();

    try t.expectASTSnapshot(node, snap(@src(),
        \\ast.Node{
        \\    .export = ast.Node.Export{
        \\        .from = ast.Node.ExportFromPath{
        \\            .bindings = [_]ast.Node.Index{
        \\                ast.Node.Index(0), 
        \\                ast.Node.Index(1)
        \\            },
        \\            .path = string_interner.StringId(5),
        \\        },
        \\    },
        \\}
    ));
    try t.expectTokenAt(markers[0], node.?);

    const export_from = t.parser.getNode(node.?).@"export".from;
    try t.expectASTSnapshot(export_from.bindings[0], snap(@src(),
        \\ast.Node{
        \\    .binding_decl = ast.Node.BindingDecl{
        \\        .name = string_interner.StringId(1),
        \\        .alias = string_interner.StringId(2),
        \\    },
        \\}
    ));
    try t.expectTokenAt(markers[1], export_from.bindings[0]);

    try t.expectASTSnapshot(export_from.bindings[1], snap(@src(),
        \\ast.Node{
        \\    .binding_decl = ast.Node.BindingDecl{
        \\        .name = string_interner.StringId(3),
        \\        .alias = string_interner.StringId(4),
        \\    },
        \\}
    ));
    try t.expectTokenAt(markers[2], export_from.bindings[1]);
}

test "should return syntax error if path is not a string" {
    const text =
        \\export { foo, bar } from 123
        \\>                        ^
    ;

    const t, const nodeOrError, const markers = try TestParser.runCatch(text, parseExportStatement);
    defer t.deinit();

    try t.expectSyntaxErrorAt(nodeOrError, diagnostics.string_literal_expected, .{}, markers[0]);
}

test "should parse export statement without path" {
    const tests = [_][:0]const u8{
        \\ export { foo, bar };
        \\>^        ^    ^
        ,
        \\ export { foo, bar, }
        \\>^        ^    ^
    };

    inline for (tests) |test_case| {
        const t, const node, const markers = try TestParser.run(test_case, parseExportStatement);
        defer t.deinit();

        try t.expectASTSnapshot(node, snap(@src(),
            \\ast.Node{
            \\    .export = ast.Node.Export{
            \\        .from = ast.Node.ExportFromPath{
            \\            .bindings = [_]ast.Node.Index{
            \\                ast.Node.Index(0), 
            \\                ast.Node.Index(1)
            \\            },
            \\            .path = string_interner.StringId.none,
            \\        },
            \\    },
            \\}
        ));
        try t.expectTokenAt(markers[0], node.?);
    }
}

test "should return syntax error if comma is missing" {
    const text =
        \\export { foo bar } from './foo'
        \\>            ^
    ;

    const t, const nodeOrError, const markers = try TestParser.runCatch(text, parseExportStatement);
    defer t.deinit();

    try t.expectSyntaxErrorAt(nodeOrError, diagnostics.ARG_expected, .{","}, markers[0]);
}

test "should return syntax error if binding is not identifier" {
    const text =
        \\export { 123 }
        \\>        ^
    ;

    const t, const nodeOrError, const markers = try TestParser.runCatch(text, parseExportStatement);
    defer t.deinit();

    try t.expectSyntaxErrorAt(nodeOrError, diagnostics.identifier_expected, .{}, markers[0]);
}

test "should parse from all export statement" {
    const text =
        \\ export * from './foo'
        \\>^
    ;

    const t, const node, const markers = try TestParser.run(text, parseExportStatement);
    defer t.deinit();

    try t.expectASTSnapshot(node, snap(@src(),
        \\ast.Node{
        \\    .export = ast.Node.Export{
        \\        .from_all = ast.Node.ExportAll{
        \\            .alias = string_interner.StringId.none,
        \\            .path = string_interner.StringId(1),
        \\        },
        \\    },
        \\}
    ));
    try t.expectTokenAt(markers[0], node.?);
}

test "should return syntax error if from clause is missing" {
    const text =
        \\export * as alias
        \\>                ^
    ;

    const t, const nodeOrError, const markers = try TestParser.runCatch(text, parseExportStatement);
    defer t.deinit();

    try t.expectSyntaxErrorAt(nodeOrError, diagnostics.ARG_expected, .{"from"}, markers[0]);
}

test "should return syntax error for from all clause if path is not a string" {
    const text =
        \\export * as alias from 123
        \\>                      ^
    ;

    const t, const nodeOrError, const markers = try TestParser.runCatch(text, parseExportStatement);
    defer t.deinit();

    try t.expectSyntaxErrorAt(nodeOrError, diagnostics.string_literal_expected, .{}, markers[0]);
}

test "should parse from all export statement with alias" {
    const text =
        \\ export * as alias from './foo'
        \\>^
    ;

    const t, const node, const markers = try TestParser.run(text, parseExportStatement);
    defer t.deinit();

    try t.expectASTSnapshot(node, snap(@src(),
        \\ast.Node{
        \\    .export = ast.Node.Export{
        \\        .from_all = ast.Node.ExportAll{
        \\            .alias = string_interner.StringId(1),
        \\            .path = string_interner.StringId(2),
        \\        },
        \\    },
        \\}
    ));
    try t.expectTokenAt(markers[0], node.?);
}

test "should return syntax error if alias is not a string" {
    const text =
        \\export * as 123 from './foo'
        \\>           ^
    ;

    const t, const nodeOrError, const markers = try TestParser.runCatch(text, parseExportStatement);
    defer t.deinit();

    try t.expectSyntaxErrorAt(nodeOrError, diagnostics.identifier_expected, .{}, markers[0]);
}

test "should parse export statement with default bindings" {
    const text =
        \\ export default identifier
        \\>^
    ;

    const t, const node, const markers = try TestParser.run(text, parseExportStatement);
    defer t.deinit();

    try t.expectASTSnapshot(node, snap(@src(),
        \\ast.Node{
        \\    .export = ast.Node.Export{
        \\        .default = ast.Node.Index(0),
        \\    },
        \\}
    ));
    try t.expectTokenAt(markers[0], node.?);
}

test "should parse export node statement" {
    const tests = .{
        .{
            "export class Foo {}",
            snap(@src(),
                \\ast.Node{
                \\    .export = ast.Node.Export{
                \\        .node = ast.Node.Index(0),
                \\    },
                \\}
            ),
        },
        .{
            "export abstract class Foo {}",
            snap(@src(),
                \\ast.Node{
                \\    .export = ast.Node.Export{
                \\        .node = ast.Node.Index(0),
                \\    },
                \\}
            ),
        },
        .{
            "export const foo = 1;",
            snap(@src(),
                \\ast.Node{
                \\    .export = ast.Node.Export{
                \\        .node = ast.Node.Index(2),
                \\    },
                \\}
            ),
        },
        .{
            "export function foo() {}",
            snap(@src(),
                \\ast.Node{
                \\    .export = ast.Node.Export{
                \\        .node = ast.Node.Index(1),
                \\    },
                \\}
            ),
        },
        .{
            "export async function foo() {}",
            snap(@src(),
                \\ast.Node{
                \\    .export = ast.Node.Export{
                \\        .node = ast.Node.Index(1),
                \\    },
                \\}
            ),
        },
    };

    inline for (tests) |test_case| {
        const t, const node, _ = try TestParser.run(test_case[0], parseExportStatement);
        defer t.deinit();

        try t.expectASTSnapshot(node, test_case[1]);
    }
}

test "should return syntax error if export statement is not a statement" {
    const text =
        \\export 123
        \\>      ^
    ;

    const t, const nodeOrError, const markers = try TestParser.runCatch(text, parseExportStatement);
    defer t.deinit();

    try t.expectSyntaxErrorAt(nodeOrError, diagnostics.declaration_or_statement_expected, .{}, markers[0]);
}
