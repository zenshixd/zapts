const std = @import("std");
const Parser = @import("parser.zig");
const Token = @import("consts.zig").Token;
const TokenType = @import("consts.zig").TokenType;

const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
const expectEqualStrings = std.testing.expectEqualStrings;
const expectEqualDeep = std.testing.expectEqualDeep;

fn simple(token_type: TokenType) Token {
    return Token{
        .type = token_type,
        .value = null,
    };
}

fn valued(token_type: TokenType, value: []const u8) Token {
    return Token{
        .type = token_type,
        .value = value,
    };
}

// ADDITION/MULTIPLICATION START
test "parses a addition expression" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var arr = [_]Token{
        valued(TokenType.NumberConstant, "1"),
        simple(TokenType.Plus),
        valued(TokenType.NumberConstant, "2"),
        simple(TokenType.Semicolon),
        simple(TokenType.Eof),
    };
    var tokens = std.ArrayList(Token).fromOwnedSlice(allocator, &arr);
    defer tokens.deinit();

    var parser = Parser.init(allocator, tokens);

    const nodes = try parser.parse();

    try expect(nodes.items.len == 1);
    try expect(nodes.items[0].* == .binary);
    try expectEqualDeep(Token{ .type = TokenType.NumberConstant, .value = "1" }, nodes.items[0].binary.left.literal.value);
    try expectEqual(TokenType.Plus, nodes.items[0].binary.operator);
    try expectEqualDeep(Token{ .type = TokenType.NumberConstant, .value = "2" }, nodes.items[0].binary.right.literal.value);
}

test "parses a substraction expression" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var arr = [_]Token{
        valued(TokenType.NumberConstant, "1"),
        simple(TokenType.Minus),
        valued(TokenType.NumberConstant, "2"),
        simple(TokenType.Semicolon),
        simple(TokenType.Eof),
    };
    var tokens = std.ArrayList(Token).fromOwnedSlice(allocator, &arr);
    defer tokens.deinit();

    var parser = Parser.init(allocator, tokens);

    const nodes = try parser.parse();

    try expect(nodes.items.len == 1);
    try expect(nodes.items[0].* == .binary);
    try expectEqualDeep(Token{ .type = TokenType.NumberConstant, .value = "1" }, nodes.items[0].binary.left.literal.value);
    try expectEqual(TokenType.Minus, nodes.items[0].binary.operator);
    try expectEqualDeep(Token{ .type = TokenType.NumberConstant, .value = "2" }, nodes.items[0].binary.right.literal.value);
}

test "parses an expression with multiple operators" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var arr = [_]Token{
        valued(TokenType.NumberConstant, "1"),
        simple(TokenType.Minus),
        valued(TokenType.NumberConstant, "2"),
        simple(TokenType.Plus),
        valued(TokenType.NumberConstant, "3"),
        simple(TokenType.Semicolon),
        simple(TokenType.Eof),
    };
    var tokens = std.ArrayList(Token).fromOwnedSlice(allocator, &arr);
    defer tokens.deinit();

    var parser = Parser.init(allocator, tokens);

    const nodes = try parser.parse();

    try expect(nodes.items.len == 1);
    try expect(nodes.items[0].* == .binary);
    try expect(nodes.items[0].binary.left.* == .binary);

    const leftNode = nodes.items[0].binary.left.binary;
    try expectEqualDeep(Token{ .type = TokenType.NumberConstant, .value = "1" }, leftNode.left.literal.value);
    try expectEqual(TokenType.Minus, leftNode.operator);
    try expectEqualDeep(Token{ .type = TokenType.NumberConstant, .value = "2" }, leftNode.right.literal.value);
    try expectEqual(TokenType.Plus, nodes.items[0].binary.operator);
    try expectEqualDeep(Token{ .type = TokenType.NumberConstant, .value = "3" }, nodes.items[0].binary.right.literal.value);
}

test "parses an expression with multiple types of operators" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var tokens = std.ArrayList(Token).init(allocator);
    defer tokens.deinit();

    try tokens.appendSlice(&[_]Token{
        valued(TokenType.NumberConstant, "1"),
        simple(TokenType.Minus),
        valued(TokenType.NumberConstant, "2"),
        simple(TokenType.Star),
        valued(TokenType.NumberConstant, "3"),
        simple(TokenType.Semicolon),
        simple(TokenType.Eof),
    });

    var parser = Parser.init(allocator, tokens);

    const nodes = try parser.parse();

    try expect(nodes.items.len == 1);
    try expect(nodes.items[0].* == .binary);
    try expect(nodes.items[0].binary.left.* == .literal);
    try expect(nodes.items[0].binary.right.* == .binary);

    try expectEqualDeep(Token{ .type = TokenType.NumberConstant, .value = "1" }, nodes.items[0].binary.left.literal.value);
    try expectEqual(TokenType.Minus, nodes.items[0].binary.operator);

    const rightNode = nodes.items[0].binary.right;
    try expectEqualDeep(Token{ .type = TokenType.NumberConstant, .value = "2" }, rightNode.binary.left.literal.value);
    try expectEqual(TokenType.Star, rightNode.binary.operator);
    try expectEqualDeep(Token{ .type = TokenType.NumberConstant, .value = "3" }, rightNode.binary.right.literal.value);
}
// ADDITION/MULTIPLICATION END

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

    try expect(nodes.items.len == 1);
    try expect(nodes.items[0].* == .import_statement);

    try expectEqual(false, nodes.items[0].import_statement.only_type);
    try expectEqualStrings("fs", nodes.items[0].import_statement.symbols.items[0]);
    try expectEqual(.star_import, nodes.items[0].import_statement.type);
    try expectEqualStrings("node:fs", nodes.items[0].import_statement.path);
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

    try expect(nodes.items.len == 1);
    try expect(nodes.items[0].* == .import_statement);

    try expectEqual(false, nodes.items[0].import_statement.only_type);
    try expectEqualStrings("readFile", nodes.items[0].import_statement.symbols.items[0]);
    try expectEqual(.named_import, nodes.items[0].import_statement.type);
    try expectEqualStrings("node:fs", nodes.items[0].import_statement.path);
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

    try expect(nodes.items.len == 1);
    try expect(nodes.items[0].* == .import_statement);

    try expectEqual(false, nodes.items[0].import_statement.only_type);
    try expectEqualStrings("readFile", nodes.items[0].import_statement.symbols.items[0]);
    try expectEqualStrings("writeFile", nodes.items[0].import_statement.symbols.items[1]);
    try expectEqual(.named_import, nodes.items[0].import_statement.type);
    try expectEqualStrings("node:fs", nodes.items[0].import_statement.path);
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
    try expect(nodes.items[0].* == .import_statement);

    try expectEqual(false, nodes.items[0].import_statement.only_type);
    try expectEqual(0, nodes.items[0].import_statement.symbols.items.len);
    try expectEqual(.named_import, nodes.items[0].import_statement.type);
    try expectEqualStrings("node:fs", nodes.items[0].import_statement.path);
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
    try expect(nodes.items[0].* == .import_statement);

    try expectEqual(false, nodes.items[0].import_statement.only_type);
    try expectEqual(0, nodes.items[0].import_statement.symbols.items.len);
    try expectEqual(.basic, nodes.items[0].import_statement.type);
    try expectEqualStrings("node:fs", nodes.items[0].import_statement.path);
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

    try expect(nodes.items.len == 1);
    try expect(nodes.items[0].* == .import_statement);

    try expectEqual(false, nodes.items[0].import_statement.only_type);
    try expectEqual(1, nodes.items[0].import_statement.symbols.items.len);
    try expectEqualStrings("fs", nodes.items[0].import_statement.symbols.items[0]);
    try expectEqual(.default_import, nodes.items[0].import_statement.type);
    try expectEqualStrings("node:fs", nodes.items[0].import_statement.path);
}
// IMPORTS END

// COMPARISONS START
test "should parse comparisons" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var arr = [_]Token{
        valued(TokenType.NumberConstant, "1"),
        simple(TokenType.EqualEqual),
        valued(TokenType.NumberConstant, "2"),
        simple(TokenType.Semicolon),
        simple(TokenType.Eof),
    };
    var tokens = std.ArrayList(Token).fromOwnedSlice(allocator, &arr);
    defer tokens.deinit();

    var parser = Parser.init(allocator, tokens);

    const nodes = try parser.parse();

    try expect(nodes.items.len == 1);
    try expect(nodes.items[0].* == .binary);
    try expectEqualDeep(Token{ .type = TokenType.NumberConstant, .value = "1" }, nodes.items[0].binary.left.literal.value);
    try expectEqual(TokenType.EqualEqual, nodes.items[0].binary.operator);
    try expectEqualDeep(Token{ .type = TokenType.NumberConstant, .value = "2" }, nodes.items[0].binary.right.literal.value);
}

test "should parse complex comparisons" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var arr = [_]Token{
        valued(TokenType.NumberConstant, "1"),
        simple(TokenType.LessThan),
        valued(TokenType.NumberConstant, "2"),
        simple(TokenType.BarBar),
        valued(TokenType.NumberConstant, "3"),
        simple(TokenType.AmpersandAmpersand),
        valued(TokenType.NumberConstant, "4"),
        simple(TokenType.EqualEqual),
        valued(TokenType.NumberConstant, "5"),
        simple(TokenType.Semicolon),
        simple(TokenType.Eof),
    };
    var tokens = std.ArrayList(Token).fromOwnedSlice(allocator, &arr);
    defer tokens.deinit();

    var parser = Parser.init(allocator, tokens);

    const nodes = try parser.parse();

    try expect(nodes.items.len == 1);
    try expect(nodes.items[0].* == .binary);

    try expect(nodes.items[0].binary.left.* == .binary);
    try expectEqual(TokenType.AmpersandAmpersand, nodes.items[0].binary.operator);
    try expect(nodes.items[0].binary.right.* == .binary);

    const leftNode = nodes.items[0].binary.left.binary;
    const leftLeftNode = leftNode.left.binary;
    try expect(leftLeftNode.left.* == .literal);
    try expectEqualDeep(Token{ .type = TokenType.NumberConstant, .value = "1" }, leftLeftNode.left.literal.value);
    try expect(leftLeftNode.operator == TokenType.LessThan);
    try expect(leftLeftNode.right.* == .literal);
    try expectEqualDeep(Token{ .type = TokenType.NumberConstant, .value = "2" }, leftLeftNode.right.literal.value);

    try expect(leftNode.left.* == .binary);
    try expectEqual(TokenType.BarBar, leftNode.operator);
    try expect(leftNode.right.* == .literal);
    try expectEqualDeep(Token{ .type = TokenType.NumberConstant, .value = "3" }, leftNode.right.literal.value);

    const rightNode = nodes.items[0].binary.right.binary;
    try expect(rightNode.left.* == .literal);
    try expectEqualDeep(Token{ .type = TokenType.NumberConstant, .value = "4" }, rightNode.left.literal.value);
    try expect(rightNode.operator == TokenType.EqualEqual);
    try expect(rightNode.right.* == .literal);
    try expectEqualDeep(Token{ .type = TokenType.NumberConstant, .value = "5" }, rightNode.right.literal.value);
}
// COMPARISONS END

// PROPERTY ACCESS START
test "should parse property access" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    const allocator = arena.allocator();
    defer arena.deinit();

    var arr = [_]Token{
        valued(TokenType.Identifier, "foo"),
        simple(TokenType.Dot),
        valued(TokenType.Identifier, "bar"),
        simple(TokenType.Semicolon),
        simple(TokenType.Eof),
    };
    const tokens = std.ArrayList(Token).fromOwnedSlice(allocator, &arr);

    var parser = Parser.init(allocator, tokens);

    const nodes = try parser.parse();

    try expect(nodes.items.len == 1);
    try expect(nodes.items[0].* == .binary);

    try expectEqualDeep(Token{ .type = TokenType.Identifier, .value = "foo" }, nodes.items[0].binary.left.literal.value);
    try expectEqual(TokenType.Dot, nodes.items[0].binary.operator);
    try expectEqualDeep(Token{ .type = TokenType.Identifier, .value = "bar" }, nodes.items[0].binary.right.literal.value);
}
// PROPERTY ACCESS END

// FUNCTION CALL START
test "should parse function call" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    const allocator = arena.allocator();
    defer arena.deinit();

    var arr = [_]Token{
        valued(TokenType.Identifier, "foo"),
        simple(TokenType.OpenParen),
        valued(TokenType.Identifier, "bar"),
        simple(TokenType.Plus),
        valued(TokenType.Identifier, "baz"),
        simple(TokenType.CloseParen),
        simple(TokenType.Semicolon),
        simple(TokenType.Eof),
    };
    const tokens = std.ArrayList(Token).fromOwnedSlice(allocator, &arr);

    var parser = Parser.init(allocator, tokens);

    const nodes = try parser.parse();

    try expect(nodes.items.len == 1);
    try expect(nodes.items[0].* == .callable_expression);

    const expr = nodes.items[0].callable_expression;
    try expectEqualDeep(Token{ .type = TokenType.Identifier, .value = "foo" }, expr.left.literal.value);

    try expect(expr.arguments.items[0].* == .binary);
    const argsExpr = expr.arguments.items[0].binary;

    try expectEqualDeep(Token{ .type = TokenType.Identifier, .value = "bar" }, argsExpr.left.literal.value);
    try expectEqual(TokenType.Plus, argsExpr.operator);
    try expectEqualDeep(Token{ .type = TokenType.Identifier, .value = "baz" }, argsExpr.right.literal.value);
}

test "function call with multiple arguments" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const allocator = arena.allocator();
    var arr = [_]Token{
        valued(TokenType.Identifier, "foo"),
        simple(TokenType.OpenParen),
        valued(TokenType.Identifier, "bar"),
        simple(TokenType.Plus),
        valued(TokenType.Identifier, "baz"),
        simple(TokenType.Comma),
        valued(TokenType.Identifier, "qux"),
        simple(TokenType.CloseParen),
        simple(TokenType.Semicolon),
        simple(TokenType.Eof),
    };
    const tokens = std.ArrayList(Token).fromOwnedSlice(allocator, &arr);

    var parser = Parser.init(allocator, tokens);

    const nodes = try parser.parse();

    try expect(nodes.items.len == 1);
    try expect(nodes.items[0].* == .callable_expression);

    const expr = nodes.items[0].callable_expression;
    try expectEqualDeep(Token{ .type = TokenType.Identifier, .value = "foo" }, expr.left.literal.value);

    try expect(expr.arguments.items.len == 2);

    const firstArg = expr.arguments.items[0];
    try expect(firstArg.* == .binary);
    try expectEqualDeep(Token{ .type = TokenType.Identifier, .value = "bar" }, firstArg.binary.left.literal.value);
    try expectEqual(TokenType.Plus, firstArg.binary.operator);
    try expectEqualDeep(Token{ .type = TokenType.Identifier, .value = "baz" }, firstArg.binary.right.literal.value);

    const secondArg = expr.arguments.items[1];
    try expectEqualDeep(Token{ .type = TokenType.Identifier, .value = "qux" }, secondArg.literal.value);
}
// FUNCTION CALL END
