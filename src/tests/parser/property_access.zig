const std = @import("std");
const Parser = @import("../../parser.zig");
const Token = @import("../../consts.zig").Token;
const TokenType = @import("../../consts.zig").TokenType;
const valued = @import("../helpers.zig").valued;
const simple = @import("../helpers.zig").simple;

const ASTNode = Parser.ASTNode;
const ASTBinaryExpressionNode = Parser.ASTBinaryExpressionNode;
const ASTLiteralNode = Parser.ASTLiteralNode;

const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
const expectEqualStrings = std.testing.expectEqualStrings;
const expectEqualDeep = std.testing.expectEqualDeep;

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
    try expectEqualDeep(&ASTNode{
        .binary = ASTBinaryExpressionNode{
            .left = @constCast(&ASTNode{ .literal = ASTLiteralNode{ .value = Token{
                .type = TokenType.Identifier,
                .value = "foo",
            } } }),
            .operator = TokenType.Dot,
            .right = @constCast(&ASTNode{ .literal = ASTLiteralNode{ .value = Token{
                .type = TokenType.Identifier,
                .value = "bar",
            } } }),
        },
    }, nodes.items[0]);
}

test "should parse property access with question mark" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    const allocator = arena.allocator();
    defer arena.deinit();

    var arr = [_]Token{
        valued(TokenType.Identifier, "foo"),
        simple(TokenType.QuestionMarkDot),
        valued(TokenType.Identifier, "bar"),
        simple(TokenType.Semicolon),
        simple(TokenType.Eof),
    };
    const tokens = std.ArrayList(Token).fromOwnedSlice(allocator, &arr);

    var parser = Parser.init(allocator, tokens);

    const nodes = try parser.parse();

    try expect(nodes.items.len == 1);
    try expectEqualDeep(&ASTNode{
        .binary = ASTBinaryExpressionNode{
            .left = @constCast(&ASTNode{ .literal = ASTLiteralNode{ .value = Token{
                .type = TokenType.Identifier,
                .value = "foo",
            } } }),
            .operator = TokenType.QuestionMarkDot,
            .right = @constCast(&ASTNode{ .literal = ASTLiteralNode{ .value = Token{
                .type = TokenType.Identifier,
                .value = "bar",
            } } }),
        },
    }, nodes.items[0]);
}

test "should parse property access with index access" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    const allocator = arena.allocator();
    defer arena.deinit();

    var arr = [_]Token{
        valued(TokenType.Identifier, "foo"),
        simple(TokenType.Dot),
        valued(TokenType.Identifier, "bar"),
        simple(TokenType.OpenSquareBracket),
        valued(TokenType.NumberConstant, "1"),
        simple(TokenType.CloseSquareBracket),
        simple(TokenType.Semicolon),
        simple(TokenType.Eof),
    };
    const tokens = std.ArrayList(Token).fromOwnedSlice(allocator, &arr);

    var parser = Parser.init(allocator, tokens);

    const nodes = try parser.parse();

    try expect(nodes.items.len == 1);
    try expectEqualDeep(&ASTNode{
        .binary = ASTBinaryExpressionNode{
            .left = @constCast(&ASTNode{ .binary = ASTBinaryExpressionNode{
                .left = @constCast(&ASTNode{ .literal = ASTLiteralNode{ .value = Token{
                    .type = TokenType.Identifier,
                    .value = "foo",
                } } }),
                .operator = TokenType.Dot,
                .right = @constCast(&ASTNode{ .literal = ASTLiteralNode{ .value = Token{
                    .type = TokenType.Identifier,
                    .value = "bar",
                } } }),
            } }),
            .operator = TokenType.OpenSquareBracket,
            .right = @constCast(&ASTNode{ .literal = ASTLiteralNode{ .value = Token{
                .type = TokenType.NumberConstant,
                .value = "1",
            } } }),
        },
    }, nodes.items[0]);
}

test "should parse expression in index access" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    const allocator = arena.allocator();
    defer arena.deinit();

    var arr = [_]Token{
        valued(TokenType.Identifier, "foo"),
        simple(TokenType.OpenSquareBracket),
        valued(TokenType.NumberConstant, "1"),
        simple(TokenType.Plus),
        valued(TokenType.NumberConstant, "2"),
        simple(TokenType.CloseSquareBracket),
        simple(TokenType.Semicolon),
        simple(TokenType.Eof),
    };
    const tokens = std.ArrayList(Token).fromOwnedSlice(allocator, &arr);

    var parser = Parser.init(allocator, tokens);

    const nodes = try parser.parse();

    try expect(nodes.items.len == 1);
    try expectEqualDeep(&ASTNode{
        .binary = ASTBinaryExpressionNode{
            .left = @constCast(&ASTNode{ .literal = ASTLiteralNode{ .value = Token{
                .type = TokenType.Identifier,
                .value = "foo",
            } } }),
            .operator = TokenType.OpenSquareBracket,
            .right = @constCast(&ASTNode{ .binary = ASTBinaryExpressionNode{
                .left = @constCast(&ASTNode{ .literal = ASTLiteralNode{ .value = Token{
                    .type = TokenType.NumberConstant,
                    .value = "1",
                } } }),
                .operator = TokenType.Plus,
                .right = @constCast(&ASTNode{ .literal = ASTLiteralNode{ .value = Token{
                    .type = TokenType.NumberConstant,
                    .value = "2",
                } } }),
            } }),
        },
    }, nodes.items[0]);
}
