const std = @import("std");
const Parser = @import("../../parser.zig");
const Token = @import("../../consts.zig").Token;
const TokenType = @import("../../consts.zig").TokenType;
const valued = @import("../helpers.zig").valued;
const simple = @import("../helpers.zig").simple;

const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
const expectEqualStrings = std.testing.expectEqualStrings;
const expectEqualDeep = std.testing.expectEqualDeep;

const ASTNode = Parser.ASTNode;
const ASTExpressionNode = Parser.ASTExpressionNode;
const ASTBinaryExpressionNode = Parser.ASTBinaryExpressionNode;
const ASTLiteralNode = Parser.ASTLiteralNode;

test "should parse grouping" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    const allocator = arena.allocator();
    defer arena.deinit();

    var arr = [_]Token{
        valued(TokenType.NumberConstant, "1"),
        simple(TokenType.Minus),
        simple(TokenType.OpenParen),
        valued(TokenType.NumberConstant, "2"),
        simple(TokenType.Plus),
        valued(TokenType.NumberConstant, "3"),
        simple(TokenType.CloseParen),
        simple(TokenType.Semicolon),
        simple(TokenType.Eof),
    };
    const tokens = std.ArrayList(Token).fromOwnedSlice(allocator, &arr);

    var parser = Parser.init(allocator, tokens);

    const nodes = try parser.parse();

    try expectEqual(1, nodes.items.len);
    try expectEqualDeep(&ASTNode{ .binary = ASTBinaryExpressionNode{
        .left = @constCast(&ASTNode{
            .literal = ASTLiteralNode{
                .value = Token{
                    .type = TokenType.NumberConstant,
                    .value = "1",
                },
            },
        }),
        .operator = TokenType.Minus,
        .right = @constCast(&ASTNode{ .expression = @constCast(&ASTNode{ .binary = ASTBinaryExpressionNode{
            .left = @constCast(&ASTNode{
                .literal = ASTLiteralNode{
                    .value = Token{
                        .type = TokenType.NumberConstant,
                        .value = "2",
                    },
                },
            }),
            .operator = TokenType.Plus,
            .right = @constCast(&ASTNode{
                .literal = ASTLiteralNode{
                    .value = Token{
                        .type = TokenType.NumberConstant,
                        .value = "3",
                    },
                },
            }),
        } }) }),
    } }, nodes.items[0]);
}
