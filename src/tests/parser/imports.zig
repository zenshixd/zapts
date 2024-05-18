const std = @import("std");
const Parser = @import("../../parser.zig");
const Token = @import("../../consts.zig").Token;
const TokenType = @import("../../consts.zig").TokenType;
const valued = @import("../helpers.zig").valued;
const simple = @import("../helpers.zig").simple;

const ASTNode = Parser.ASTNode;
const ASTImportNode = Parser.ASTImportNode;
const ASTImportBinding = Parser.ASTImportBinding;

const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
const expectEqualStrings = std.testing.expectEqualStrings;
const expectEqualDeep = std.testing.expectEqualDeep;

test "should parse star import statements" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var tokens = [_]Token{
        simple(TokenType.Import),
        simple(TokenType.Star),
        simple(TokenType.As),
        valued(TokenType.Identifier, "fs"),
        simple(TokenType.From),
        valued(TokenType.StringConstant, "node:fs"),
        simple(TokenType.Semicolon),
        simple(TokenType.Eof),
    };

    var parser = Parser.init(allocator, &tokens);

    const nodes = try parser.parse();

    var expectedSymbols = std.ArrayList(ASTImportBinding).init(allocator);
    try expectedSymbols.append(ASTImportBinding{
        .as_namespace = true,
        .as_type = false,
        .default = false,
        .name = "fs",
    });

    try expect(nodes.items.len == 1);
    try expectEqualDeep(&ASTNode{
        .tag = .import,
        .data = .{
            .import = ASTImportNode{
                .symbols = try expectedSymbols.toOwnedSlice(),
                .path = "node:fs",
            },
        },
    }, nodes.items[0]);
}

test "should parse named import statements" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var tokens = [_]Token{
        simple(TokenType.Import),
        simple(TokenType.OpenCurlyBrace),
        valued(TokenType.Identifier, "readFile"),
        simple(TokenType.CloseCurlyBrace),
        simple(TokenType.From),
        valued(TokenType.StringConstant, "node:fs"),
        simple(TokenType.Semicolon),
        simple(TokenType.Eof),
    };

    var parser = Parser.init(allocator, &tokens);

    const nodes = try parser.parse();

    var expectedSymbols = std.ArrayList(ASTImportBinding).init(allocator);
    try expectedSymbols.append(ASTImportBinding{
        .as_namespace = false,
        .as_type = false,
        .default = false,
        .name = "readFile",
    });

    try expect(nodes.items.len == 1);
    try expectEqualDeep(&ASTNode{
        .tag = .import,
        .data = .{
            .import = ASTImportNode{
                .symbols = try expectedSymbols.toOwnedSlice(),
                .path = "node:fs",
            },
        },
    }, nodes.items[0]);
}

test "should parse named import statements with multiple symbols" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var tokens = [_]Token{
        simple(TokenType.Import),
        simple(TokenType.OpenCurlyBrace),
        valued(TokenType.Identifier, "readFile"),
        simple(TokenType.Comma),
        valued(TokenType.Identifier, "writeFile"),
        simple(TokenType.CloseCurlyBrace),
        simple(TokenType.From),
        valued(TokenType.StringConstant, "node:fs"),
        simple(TokenType.Semicolon),
        simple(TokenType.Eof),
    };

    var parser = Parser.init(allocator, &tokens);

    const nodes = try parser.parse();

    var expectedSymbols = std.ArrayList(ASTImportBinding).init(allocator);
    try expectedSymbols.append(ASTImportBinding{
        .as_namespace = false,
        .as_type = false,
        .default = false,
        .name = "readFile",
    });
    try expectedSymbols.append(ASTImportBinding{
        .as_namespace = false,
        .as_type = false,
        .default = false,
        .name = "writeFile",
    });

    try expect(nodes.items.len == 1);
    try expectEqualDeep(&ASTNode{
        .tag = .import,
        .data = .{
            .import = ASTImportNode{
                .symbols = try expectedSymbols.toOwnedSlice(),
                .path = "node:fs",
            },
        },
    }, nodes.items[0]);
}

test "should parse named import statements with no symbols" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var tokens = [_]Token{
        simple(TokenType.Import),
        simple(TokenType.OpenCurlyBrace),
        simple(TokenType.CloseCurlyBrace),
        simple(TokenType.From),
        valued(TokenType.StringConstant, "node:fs"),
        simple(TokenType.Semicolon),
        simple(TokenType.Eof),
    };

    var parser = Parser.init(allocator, &tokens);

    const nodes = try parser.parse();

    var expectedSymbols = std.ArrayList(ASTImportBinding).init(allocator);
    try expect(nodes.items.len == 1);
    try expectEqualDeep(&ASTNode{
        .tag = .import,
        .data = .{
            .import = ASTImportNode{
                .symbols = try expectedSymbols.toOwnedSlice(),
                .path = "node:fs",
            },
        },
    }, nodes.items[0]);
}

test "should parse basic imports" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var tokens = [_]Token{
        simple(TokenType.Import),
        valued(TokenType.StringConstant, "node:fs"),
        simple(TokenType.Semicolon),
        simple(TokenType.Eof),
    };

    var parser = Parser.init(allocator, &tokens);

    const nodes = try parser.parse();

    try expect(nodes.items.len == 1);
    try expectEqualDeep(&ASTNode{
        .tag = .simple_import,
        .data = .{ .literal = "node:fs" },
    }, nodes.items[0]);
}

test "should parse default imports" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var tokens = [_]Token{
        simple(TokenType.Import),
        valued(TokenType.Identifier, "fs"),
        simple(TokenType.From),
        valued(TokenType.StringConstant, "node:fs"),
        simple(TokenType.Semicolon),
        simple(TokenType.Eof),
    };

    var parser = Parser.init(allocator, &tokens);

    const nodes = try parser.parse();

    var expectedSymbols = std.ArrayList(ASTImportBinding).init(allocator);
    try expectedSymbols.append(ASTImportBinding{
        .as_namespace = false,
        .as_type = false,
        .default = true,
        .name = "fs",
    });

    try expect(nodes.items.len == 1);
    try expectEqualDeep(&ASTNode{
        .tag = .import,
        .data = .{
            .import = ASTImportNode{
                .symbols = try expectedSymbols.toOwnedSlice(),
                .path = "node:fs",
            },
        },
    }, nodes.items[0]);
}
