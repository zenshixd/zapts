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
    try expectEqualDeep(&ASTNode{
        .binary = ASTBinaryExpressionNode{
            .left = @constCast(&ASTNode{ .literal = ASTLiteralNode{ .value = Token{
                .type = TokenType.NumberConstant,
                .value = "1",
            } } }),
            .operator = TokenType.Plus,
            .right = @constCast(&ASTNode{ .literal = ASTLiteralNode{ .value = Token{
                .type = TokenType.NumberConstant,
                .value = "2",
            } } }),
        },
    }, nodes.items[0]);
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
    try expectEqualDeep(&ASTNode{
        .binary = ASTBinaryExpressionNode{
            .left = @constCast(&ASTNode{ .literal = ASTLiteralNode{ .value = Token{
                .type = TokenType.NumberConstant,
                .value = "1",
            } } }),
            .operator = TokenType.Minus,
            .right = @constCast(&ASTNode{ .literal = ASTLiteralNode{ .value = Token{
                .type = TokenType.NumberConstant,
                .value = "2",
            } } }),
        },
    }, nodes.items[0]);
}

test "parses a multiplication expression" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var arr = [_]Token{
        valued(TokenType.NumberConstant, "1"),
        simple(TokenType.Star),
        valued(TokenType.NumberConstant, "2"),
        simple(TokenType.Semicolon),
        simple(TokenType.Eof),
    };
    var tokens = std.ArrayList(Token).fromOwnedSlice(allocator, &arr);
    defer tokens.deinit();

    var parser = Parser.init(allocator, tokens);

    const nodes = try parser.parse();

    try expect(nodes.items.len == 1);
    try expectEqualDeep(&ASTNode{
        .binary = ASTBinaryExpressionNode{
            .left = @constCast(&ASTNode{ .literal = ASTLiteralNode{ .value = Token{
                .type = TokenType.NumberConstant,
                .value = "1",
            } } }),
            .operator = TokenType.Star,
            .right = @constCast(&ASTNode{ .literal = ASTLiteralNode{ .value = Token{
                .type = TokenType.NumberConstant,
                .value = "2",
            } } }),
        },
    }, nodes.items[0]);
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
    try expectEqualDeep(&ASTNode{
        .binary = ASTBinaryExpressionNode{
            .left = @constCast(&ASTNode{ .binary = ASTBinaryExpressionNode{
                .left = @constCast(&ASTNode{ .literal = ASTLiteralNode{ .value = Token{
                    .type = TokenType.NumberConstant,
                    .value = "1",
                } } }),
                .operator = TokenType.Minus,
                .right = @constCast(&ASTNode{ .literal = ASTLiteralNode{ .value = Token{
                    .type = TokenType.NumberConstant,
                    .value = "2",
                } } }),
            } }),
            .operator = TokenType.Plus,
            .right = @constCast(&ASTNode{ .literal = ASTLiteralNode{ .value = Token{
                .type = TokenType.NumberConstant,
                .value = "3",
            } } }),
        },
    }, nodes.items[0]);
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
    try expectEqualDeep(&ASTNode{
        .binary = ASTBinaryExpressionNode{
            .left = @constCast(&ASTNode{ .literal = ASTLiteralNode{ .value = Token{
                .type = TokenType.NumberConstant,
                .value = "1",
            } } }),
            .operator = TokenType.Minus,
            .right = @constCast(&ASTNode{ .binary = ASTBinaryExpressionNode{
                .left = @constCast(&ASTNode{ .literal = ASTLiteralNode{ .value = Token{
                    .type = TokenType.NumberConstant,
                    .value = "2",
                } } }),
                .operator = TokenType.Star,
                .right = @constCast(&ASTNode{ .literal = ASTLiteralNode{ .value = Token{
                    .type = TokenType.NumberConstant,
                    .value = "3",
                } } }),
            } }),
        },
    }, nodes.items[0]);
}
