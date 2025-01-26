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
const parseIdentifier = @import("primary.zig").parseIdentifier;

const TestParser = @import("../test_parser.zig");
const MarkerList = @import("../test_parser.zig").MarkerList;
const Marker = @import("../test_parser.zig").Marker;

const assert = std.debug.assert;
const expectEqual = std.testing.expectEqual;
const expectEqualStrings = std.testing.expectEqualStrings;
const expectEqualDeep = std.testing.expectEqualDeep;
const expectError = std.testing.expectError;

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
    if (try parseIdentifier(self)) |identifier| {
        return self.addNode(self.cur_token.dec(2), .{ .import_binding = .{ .default = identifier } });
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
                Token.Empty;
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
        var namespace: Token.Index = Token.Empty;

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
                Token.Empty;

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
                    .path = path orelse Token.Empty,
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

    try TestParser.run(text, parseImportStatement, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectAST(node, null);
        }
    });
}

test "should parse simple import statement" {
    const text = "import 'bar'";

    try TestParser.run(text, parseImportStatement, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectAST(node, AST.Node{ .import = .{ .simple = Token.at(1) } });
        }
    });
}

test "should parse default import statement" {
    const text = "import Foo from 'bar'";

    try TestParser.run(text, parseImportStatement, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, _: MarkerList(text)) !void {
            const full_import = AST.Node.ImportFull{
                .bindings = @constCast(&[_]AST.Node.Index{AST.Node.at(2)}),
                .path = Token.at(3),
            };
            try t.expectAST(node, AST.Node{
                .import = AST.Node.Import{ .full = full_import },
            });
            try t.expectAST(full_import.bindings[0], AST.Node{
                .import_binding = AST.Node.ImportBinding{
                    .default = AST.Node.at(1),
                },
            });
        }
    });
}

test "should parse namespace import statement" {
    const text = "import * as Foo from 'bar'";

    try TestParser.run(text, parseImportStatement, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, _: MarkerList(text)) !void {
            const full_import = AST.Node.ImportFull{
                .bindings = @constCast(&[_]AST.Node.Index{AST.Node.at(1)}),
                .path = Token.at(5),
            };
            try t.expectAST(node, AST.Node{
                .import = AST.Node.Import{ .full = full_import },
            });
            try t.expectAST(full_import.bindings[0], AST.Node{
                .import_binding = AST.Node.ImportBinding{
                    .namespace = Token.at(3),
                },
            });
        }
    });
}

test "should return error if \"as\" is missing" {
    const text = "import * foo from 'bar'";

    try TestParser.runAny(text, parseImportStatement, struct {
        pub fn expect(t: TestParser, nodeOrError: Parser.ParserError!?AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectSyntaxError(nodeOrError, diagnostics.ARG_expected, .{"as"});
        }
    });
}

test "should parse named import statement" {
    const text = "import { foo, bar } from 'bar'";

    try TestParser.run(text, parseImportStatement, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, _: MarkerList(text)) !void {
            const full_import = AST.Node.ImportFull{
                .bindings = @constCast(&[_]AST.Node.Index{AST.Node.at(3)}),
                .path = Token.at(7),
            };
            try t.expectAST(node, AST.Node{
                .import = AST.Node.Import{
                    .full = full_import,
                },
            });
            const binding = AST.Node.ImportBinding{
                .named = @constCast(&[_]AST.Node.Index{ AST.Node.at(1), AST.Node.at(2) }),
            };
            try t.expectAST(full_import.bindings[0], AST.Node{ .import_binding = binding });
            try t.expectAST(binding.named[0], AST.Node{
                .binding_decl = AST.Node.BindingDecl{
                    .alias = Token.Empty,
                    .name = Token.at(2),
                },
            });
            try t.expectAST(binding.named[1], AST.Node{
                .binding_decl = AST.Node.BindingDecl{
                    .alias = Token.Empty,
                    .name = Token.at(4),
                },
            });
        }
    });
}

test "should parse named bindings with aliases in import statement" {
    const text = "import { foo as bar, baz as qux } from 'bar'";

    try TestParser.run(text, parseImportStatement, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, _: MarkerList(text)) !void {
            const full_import = AST.Node.ImportFull{
                .bindings = @constCast(&[_]AST.Node.Index{AST.Node.at(3)}),
                .path = Token.at(11),
            };
            try t.expectAST(node, AST.Node{
                .import = AST.Node.Import{
                    .full = full_import,
                },
            });
            const binding = AST.Node.ImportBinding{
                .named = @constCast(&[_]AST.Node.Index{ AST.Node.at(1), AST.Node.at(2) }),
            };
            try t.expectAST(full_import.bindings[0], AST.Node{ .import_binding = binding });
            try t.expectAST(binding.named[0], AST.Node{
                .binding_decl = AST.Node.BindingDecl{
                    .alias = Token.at(4),
                    .name = Token.at(2),
                },
            });
            try t.expectAST(binding.named[1], AST.Node{
                .binding_decl = AST.Node.BindingDecl{
                    .alias = Token.at(8),
                    .name = Token.at(6),
                },
            });
        }
    });
}

test "should return syntax error if alias in import binding is not a string" {
    const text = "import { foo as 123 } from 'bar'";

    try TestParser.runAny(text, parseImportStatement, struct {
        pub fn expect(t: TestParser, nodeOrError: Parser.ParserError!?AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectSyntaxError(nodeOrError, diagnostics.identifier_expected, .{});
        }
    });
}

test "should return error if comma is missing" {
    const text = "import {foo bar} from 'bar'";

    try TestParser.runAny(text, parseImportStatement, struct {
        pub fn expect(t: TestParser, nodeOrError: Parser.ParserError!?AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectSyntaxError(nodeOrError, diagnostics.ARG_expected, .{","});
        }
    });
}

test "should return error if its not binding" {
    const text = "import + from 'bar'";

    try TestParser.runAny(text, parseImportStatement, struct {
        pub fn expect(t: TestParser, nodeOrError: Parser.ParserError!?AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectSyntaxError(nodeOrError, diagnostics.declaration_or_statement_expected, .{});
        }
    });
}

test "should parse default import and namespace binding" {
    const text = "import foo, * as bar from 'bar'";

    try TestParser.run(text, parseImportStatement, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, _: MarkerList(text)) !void {
            const full_import = AST.Node.ImportFull{
                .bindings = @constCast(&[_]AST.Node.Index{ AST.Node.at(2), AST.Node.at(3) }),
                .path = Token.at(7),
            };
            try t.expectAST(node, AST.Node{
                .import = AST.Node.Import{
                    .full = full_import,
                },
            });
            try t.expectAST(full_import.bindings[0], AST.Node{
                .import_binding = AST.Node.ImportBinding{
                    .default = AST.Node.at(1),
                },
            });
            try t.expectAST(full_import.bindings[1], AST.Node{
                .import_binding = AST.Node.ImportBinding{
                    .namespace = Token.at(5),
                },
            });
        }
    });
}

test "should parse default import and named binding" {
    const text = "import foo, { bar } from 'bar'";

    try TestParser.run(text, parseImportStatement, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, _: MarkerList(text)) !void {
            const full_import = AST.Node.ImportFull{
                .bindings = @constCast(&[_]AST.Node.Index{ AST.Node.at(2), AST.Node.at(4) }),
                .path = Token.at(7),
            };
            try t.expectAST(node, AST.Node{
                .import = AST.Node.Import{
                    .full = full_import,
                },
            });
            try t.expectAST(full_import.bindings[0], AST.Node{
                .import_binding = AST.Node.ImportBinding{
                    .default = AST.Node.at(1),
                },
            });
            try t.expectAST(full_import.bindings[1], AST.Node{
                .import_binding = AST.Node.ImportBinding{
                    .named = @constCast(&[_]AST.Node.Index{AST.Node.at(3)}),
                },
            });
        }
    });
}

test "should return error if second binding list is not valid binding" {
    const text = "import foo, + from 'bar'";

    try TestParser.runAny(text, parseImportStatement, struct {
        pub fn expect(t: TestParser, nodeOrError: Parser.ParserError!?AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectSyntaxError(nodeOrError, diagnostics.ARG_expected, .{"{"});
        }
    });
}

test "should return error if path is missing" {
    const text = "import foo";

    try TestParser.runAny(text, parseImportStatement, struct {
        pub fn expect(t: TestParser, nodeOrError: Parser.ParserError!?AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectSyntaxError(nodeOrError, diagnostics.ARG_expected, .{"from"});
        }
    });
}

test "should return error if path is not a string" {
    const text = "import foo from 123";

    try TestParser.runAny(text, parseImportStatement, struct {
        pub fn expect(t: TestParser, nodeOrError: Parser.ParserError!?AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectSyntaxError(nodeOrError, diagnostics.string_literal_expected, .{});
        }
    });
}

test "should return null if its not export statement" {
    const text = "identifier";

    try TestParser.run(text, parseExportStatement, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectAST(node, null);
        }
    });
}

test "should parse export statement with named bindings" {
    const text = "export { foo, bar } from './foo';";

    try TestParser.run(text, parseExportStatement, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, _: MarkerList(text)) !void {
            const export_from = AST.Node.Export{
                .from = .{
                    .bindings = @constCast(&[_]AST.Node.Index{ AST.Node.at(1), AST.Node.at(2) }),
                    .path = Token.at(7),
                },
            };
            try t.expectAST(node, AST.Node{ .@"export" = export_from });
            try t.expectAST(export_from.from.bindings[0], AST.Node{
                .binding_decl = AST.Node.BindingDecl{
                    .name = Token.at(2),
                    .alias = Token.Empty,
                },
            });
            try t.expectAST(export_from.from.bindings[1], AST.Node{
                .binding_decl = AST.Node.BindingDecl{
                    .name = Token.at(4),
                    .alias = Token.Empty,
                },
            });
        }
    });
}

test "should parse export statement with aliased bindings" {
    const text = "export { foo as bar, baz as qux } from './foo';";

    try TestParser.run(text, parseExportStatement, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, _: MarkerList(text)) !void {
            const export_from = AST.Node.Export{
                .from = .{
                    .bindings = @constCast(&[_]AST.Node.Index{ AST.Node.at(1), AST.Node.at(2) }),
                    .path = Token.at(11),
                },
            };
            try t.expectAST(node, AST.Node{ .@"export" = export_from });
            try t.expectAST(export_from.from.bindings[0], AST.Node{
                .binding_decl = AST.Node.BindingDecl{
                    .name = Token.at(2),
                    .alias = Token.at(4),
                },
            });
            try t.expectAST(export_from.from.bindings[1], AST.Node{
                .binding_decl = AST.Node.BindingDecl{
                    .name = Token.at(6),
                    .alias = Token.at(8),
                },
            });
        }
    });
}

test "should return syntax error if path is not a string" {
    const text = "export { foo, bar } from 123;";

    try TestParser.runAny(text, parseExportStatement, struct {
        pub fn expect(t: TestParser, nodeOrError: Parser.ParserError!?AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectSyntaxError(nodeOrError, diagnostics.string_literal_expected, .{});
        }
    });
}

test "should parse export statement without path" {
    const tests = .{
        .{
            "export { foo, bar };",
            AST.Node{ .@"export" = .{
                .from = .{
                    .bindings = @constCast(&[_]AST.Node.Index{ AST.Node.at(1), AST.Node.at(2) }),
                    .path = Token.Empty,
                },
            } },
        },
        .{
            "export { foo, bar, }",
            AST.Node{ .@"export" = .{
                .from = .{
                    .bindings = @constCast(&[_]AST.Node.Index{ AST.Node.at(1), AST.Node.at(2) }),
                    .path = Token.Empty,
                },
            } },
        },
    };

    inline for (tests) |test_case| {
        try TestParser.run(test_case[0], parseExportStatement, struct {
            pub fn expect(t: TestParser, node: ?AST.Node.Index, _: MarkerList(test_case[0])) !void {
                try t.expectAST(node, test_case[1]);
            }
        });
    }
}

test "should return syntax error if comma is missing" {
    const text = "export { foo bar } from './foo';";

    try TestParser.runAny(text, parseExportStatement, struct {
        pub fn expect(t: TestParser, nodeOrError: Parser.ParserError!?AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectSyntaxError(nodeOrError, diagnostics.ARG_expected, .{","});
        }
    });
}

test "should return syntax error if binding is not identifier" {
    const text = "export { 123 }";

    try TestParser.runAny(text, parseExportStatement, struct {
        pub fn expect(t: TestParser, nodeOrError: Parser.ParserError!?AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectSyntaxError(nodeOrError, diagnostics.identifier_expected, .{});
        }
    });
}

test "should parse from all export statement" {
    const text = "export * from './foo';";

    try TestParser.run(text, parseExportStatement, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectAST(node, AST.Node{ .@"export" = AST.Node.Export{
                .from_all = AST.Node.ExportAll{
                    .alias = Token.Empty,
                    .path = Token.at(3),
                },
            } });
        }
    });
}

test "should return syntax error if from clause is missing" {
    const text = "export * as alias";

    try TestParser.runAny(text, parseExportStatement, struct {
        pub fn expect(t: TestParser, nodeOrError: Parser.ParserError!?AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectSyntaxError(nodeOrError, diagnostics.ARG_expected, .{"from"});
        }
    });
}

test "should return syntax error for from all clause if path is not a string" {
    const text = "export * as alias from 123";

    try TestParser.runAny(text, parseExportStatement, struct {
        pub fn expect(t: TestParser, nodeOrError: Parser.ParserError!?AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectSyntaxError(nodeOrError, diagnostics.string_literal_expected, .{});
        }
    });
}

test "should parse from all export statement with alias" {
    const text = "export * as alias from './foo'";

    try TestParser.run(text, parseExportStatement, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectAST(node, AST.Node{ .@"export" = .{
                .from_all = AST.Node.ExportAll{
                    .alias = Token.at(3),
                    .path = Token.at(5),
                },
            } });
        }
    });
}

test "should return syntax error if alias is not a string" {
    const text = "export * as 123 from './foo'";

    try TestParser.runAny(text, parseExportStatement, struct {
        pub fn expect(t: TestParser, nodeOrError: Parser.ParserError!?AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectSyntaxError(nodeOrError, diagnostics.identifier_expected, .{});
        }
    });
}

test "should parse export statement with default bindings" {
    const text = "export default identifier";

    try TestParser.run(text, parseExportStatement, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectAST(node, AST.Node{
                .@"export" = AST.Node.Export{
                    .default = AST.Node.at(2),
                },
            });
        }
    });
}

test "should parse export node statement" {
    const tests = .{
        .{
            "export class Foo {}",
            AST.Node{ .@"export" = AST.Node.Export{ .node = AST.Node.at(1) } },
        },
        .{
            "export abstract class Foo {}",
            AST.Node{ .@"export" = AST.Node.Export{ .node = AST.Node.at(1) } },
        },
        .{
            "export const foo = 1;",
            AST.Node{ .@"export" = AST.Node.Export{ .node = AST.Node.at(3) } },
        },
        .{
            "export function foo() {}",
            AST.Node{ .@"export" = AST.Node.Export{ .node = AST.Node.at(2) } },
        },
        .{
            "export async function foo() {}",
            AST.Node{ .@"export" = AST.Node.Export{ .node = AST.Node.at(2) } },
        },
    };

    inline for (tests) |test_case| {
        try TestParser.run(test_case[0], parseExportStatement, struct {
            pub fn expect(t: TestParser, node: ?AST.Node.Index, _: MarkerList(test_case[0])) !void {
                try t.expectAST(node, test_case[1]);
            }
        });
    }
}

test "should return syntax error if export statement is not a statement" {
    const text = "export 123";

    try TestParser.runAny(text, parseExportStatement, struct {
        pub fn expect(t: TestParser, nodeOrError: Parser.ParserError!?AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectSyntaxError(nodeOrError, diagnostics.declaration_or_statement_expected, .{});
        }
    });
}
