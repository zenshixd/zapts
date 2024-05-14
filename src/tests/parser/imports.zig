const std = @import("std");
const Parser = @import("../../parser.zig");
const Token = @import("../../consts.zig").Token;
const TokenType = @import("../../consts.zig").TokenType;
const valued = @import("../helpers.zig").valued;
const simple = @import("../helpers.zig").simple;

const ASTNode = Parser.ASTNode;
const ASTImportStatementNode = Parser.ASTImportStatementNode;

const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
const expectEqualStrings = std.testing.expectEqualStrings;
const expectEqualDeep = std.testing.expectEqualDeep;

// IMPORTS START
test "should parse star import statements" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var arr = [_]Token{
        simple(TokenType.Import),
        simple(TokenType.Star),
        simple(TokenType.As),
        valued(TokenType.Identifier, "fs"),
        simple(TokenType.From),
        valued(TokenType.StringConstant, "node:fs"),
        simple(TokenType.Semicolon),
        simple(TokenType.Eof),
    };
    var tokens = std.ArrayList(Token).fromOwnedSlice(allocator, &arr);
    defer tokens.deinit();

    var parser = Parser.init(allocator, tokens);

    const nodes = try parser.parse();

    var expectedSymbols = std.ArrayList([]const u8).init(allocator);
    try expectedSymbols.append("fs");
    try expect(nodes.items.len == 1);
    try expectEqualDeep(&ASTNode{
        .import_statement = ASTImportStatementNode{
            .only_type = false,
            .symbols = expectedSymbols,
            .type = .star_import,
            .path = "node:fs",
        },
    }, nodes.items[0]);
}

test "should parse named import statements" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var arr = [_]Token{
        simple(TokenType.Import),
        simple(TokenType.OpenCurlyBrace),
        valued(TokenType.Identifier, "readFile"),
        simple(TokenType.CloseCurlyBrace),
        simple(TokenType.From),
        valued(TokenType.StringConstant, "node:fs"),
        simple(TokenType.Semicolon),
        simple(TokenType.Eof),
    };
    var tokens = std.ArrayList(Token).fromOwnedSlice(allocator, &arr);
    defer tokens.deinit();

    var parser = Parser.init(allocator, tokens);

    const nodes = try parser.parse();

    var expectedSymbols = std.ArrayList([]const u8).init(allocator);
    try expectedSymbols.append("readFile");
    try expect(nodes.items.len == 1);
    try expectEqualDeep(&ASTNode{
        .import_statement = ASTImportStatementNode{
            .only_type = false,
            .symbols = expectedSymbols,
            .type = .named_import,
            .path = "node:fs",
        },
    }, nodes.items[0]);
}

test "should parse named import statements with multiple symbols" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var arr = [_]Token{
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
    var tokens = std.ArrayList(Token).fromOwnedSlice(allocator, &arr);
    defer tokens.deinit();

    var parser = Parser.init(allocator, tokens);

    const nodes = try parser.parse();

    var expectedSymbols = std.ArrayList([]const u8).init(allocator);
    try expectedSymbols.append("readFile");
    try expectedSymbols.append("writeFile");
    try expect(nodes.items.len == 1);
    try expectEqualDeep(&ASTNode{
        .import_statement = ASTImportStatementNode{
            .only_type = false,
            .symbols = expectedSymbols,
            .type = .named_import,
            .path = "node:fs",
        },
    }, nodes.items[0]);
}

test "should parse named import statements with no symbols" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var arr = [_]Token{
        simple(TokenType.Import),
        simple(TokenType.OpenCurlyBrace),
        simple(TokenType.CloseCurlyBrace),
        simple(TokenType.From),
        valued(TokenType.StringConstant, "node:fs"),
        simple(TokenType.Semicolon),
        simple(TokenType.Eof),
    };
    var tokens = std.ArrayList(Token).fromOwnedSlice(allocator, &arr);
    defer tokens.deinit();

    var parser = Parser.init(allocator, tokens);

    const nodes = try parser.parse();

    try expect(nodes.items.len == 1);
    try expectEqualDeep(&ASTNode{
        .import_statement = ASTImportStatementNode{
            .only_type = false,
            .symbols = std.ArrayList([]const u8).init(allocator),
            .type = .named_import,
            .path = "node:fs",
        },
    }, nodes.items[0]);
}

test "should parse basic imports" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var arr = [_]Token{
        simple(TokenType.Import),
        valued(TokenType.StringConstant, "node:fs"),
        simple(TokenType.Semicolon),
        simple(TokenType.Eof),
    };
    var tokens = std.ArrayList(Token).fromOwnedSlice(allocator, &arr);
    defer tokens.deinit();

    var parser = Parser.init(allocator, tokens);

    const nodes = try parser.parse();

    try expect(nodes.items.len == 1);
    try expectEqualDeep(&ASTNode{
        .import_statement = ASTImportStatementNode{
            .only_type = false,
            .symbols = std.ArrayList([]const u8).init(allocator),
            .type = .basic,
            .path = "node:fs",
        },
    }, nodes.items[0]);
}

test "should parse default imports" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var arr = [_]Token{
        simple(TokenType.Import),
        valued(TokenType.Identifier, "fs"),
        simple(TokenType.From),
        valued(TokenType.StringConstant, "node:fs"),
        simple(TokenType.Semicolon),
        simple(TokenType.Eof),
    };
    var tokens = std.ArrayList(Token).fromOwnedSlice(allocator, &arr);
    defer tokens.deinit();

    var parser = Parser.init(allocator, tokens);

    const nodes = try parser.parse();

    var expectedSymbols = std.ArrayList([]const u8).init(allocator);
    try expectedSymbols.append("fs");

    try expect(nodes.items.len == 1);
    try expectEqualDeep(&ASTNode{
        .import_statement = ASTImportStatementNode{
            .only_type = false,
            .symbols = expectedSymbols,
            .type = .default_import,
            .path = "node:fs",
        },
    }, nodes.items[0]);
}
// IMPORTS END
