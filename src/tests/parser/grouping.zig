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
const ASTBinaryNode = Parser.ASTBinaryNode;

test "should parse grouping" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    const allocator = arena.allocator();
    defer arena.deinit();

    var tokens = [_]Token{
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

    var parser = Parser.init(allocator, &tokens);

    const nodes = try parser.parse();

    try expectEqual(1, nodes.len);
    try expectEqualDeep(&ASTNode{
        .tag = .minus_expr,
        .data = .{
            .binary = ASTBinaryNode{
                .left = @constCast(&ASTNode{ .tag = .number, .data = .{ .literal = "1" } }),
                .right = @constCast(&ASTNode{
                    .tag = .grouping,
                    .data = .{ .node = @constCast(&ASTNode{
                        .tag = .plus_expr,
                        .data = .{
                            .binary = ASTBinaryNode{
                                .left = @constCast(&ASTNode{ .tag = .number, .data = .{ .literal = "2" } }),
                                .right = @constCast(&ASTNode{ .tag = .number, .data = .{ .literal = "3" } }),
                            },
                        },
                    }) },
                }),
            },
        },
    }, nodes[0]);
}
