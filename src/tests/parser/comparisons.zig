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
    try expectEqualDeep(&ASTNode{
        .binary = ASTBinaryExpressionNode{
            .left = @constCast(&ASTNode{
                .literal = ASTLiteralNode{
                    .value = Token{ .type = TokenType.NumberConstant, .value = "1" },
                },
            }),
            .operator = TokenType.EqualEqual,
            .right = @constCast(&ASTNode{
                .literal = ASTLiteralNode{
                    .value = Token{ .type = TokenType.NumberConstant, .value = "2" },
                },
            }),
        },
    }, nodes.items[0]);
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

    const node = nodes.items[0];
    try expect(nodes.items.len == 1);
    try expect(node.* == .binary);

    const leftNode = node.binary.left;
    try expect(leftNode.* == .binary);
    try expect(leftNode.binary.left.* == .binary);
    try expectEqual(TokenType.BarBar, leftNode.binary.operator);

    const leftLeftNode = leftNode.binary.left;
    try expect(leftLeftNode.binary.left.* == .literal);
    try expectEqualDeep(Token{ .type = TokenType.NumberConstant, .value = "1" }, leftLeftNode.binary.left.literal.value);

    try expectEqual(TokenType.LessThan, leftLeftNode.binary.operator);

    try expect(leftLeftNode.binary.right.* == .literal);
    try expectEqualDeep(Token{ .type = TokenType.NumberConstant, .value = "2" }, leftLeftNode.binary.right.literal.value);

    try expect(leftNode.binary.right.* == .literal);
    try expectEqualDeep(Token{ .type = TokenType.NumberConstant, .value = "3" }, leftNode.binary.right.literal.value);

    try expectEqual(TokenType.AmpersandAmpersand, node.binary.operator);

    const rightNode = node.binary.right;
    try expect(rightNode.* == .binary);
    try expectEqual(TokenType.EqualEqual, rightNode.binary.operator);

    try expect(rightNode.binary.left.* == .literal);
    try expectEqualDeep(Token{ .type = TokenType.NumberConstant, .value = "4" }, rightNode.binary.left.literal.value);

    try expect(rightNode.binary.right.* == .literal);
    try expectEqualDeep(Token{ .type = TokenType.NumberConstant, .value = "5" }, rightNode.binary.right.literal.value);
}
