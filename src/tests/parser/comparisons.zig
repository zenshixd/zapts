const std = @import("std");
const Parser = @import("../../parser.zig");
const Token = @import("../../consts.zig").Token;
const TokenType = @import("../../consts.zig").TokenType;
const valued = @import("../helpers.zig").valued;
const simple = @import("../helpers.zig").simple;

const ASTNode = Parser.ASTNode;
const ASTBinaryNode = Parser.ASTBinaryNode;
const ASTNodeTag = Parser.ASTNodeTag;

const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
const expectEqualStrings = std.testing.expectEqualStrings;
const expectEqualDeep = std.testing.expectEqualDeep;

test "should parse comparisons" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var tokens = [_]Token{
        valued(TokenType.NumberConstant, "1"),
        simple(TokenType.EqualEqual),
        valued(TokenType.NumberConstant, "2"),
        simple(TokenType.Semicolon),
        simple(TokenType.Eof),
    };
    var parser = Parser.init(allocator, &tokens);

    const nodes = try parser.parse();

    try expect(nodes.items.len == 1);
    try expectEqualDeep(&ASTNode{ .tag = .eq, .data = .{
        .binary = ASTBinaryNode{
            .left = @constCast(&ASTNode{
                .tag = .number,
                .data = .{
                    .literal = "1",
                },
            }),
            .right = @constCast(&ASTNode{
                .tag = .number,
                .data = .{
                    .literal = "2",
                },
            }),
        },
    } }, nodes.items[0]);
}

test "should parse complex comparisons" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var tokens = [_]Token{
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

    var parser = Parser.init(allocator, &tokens);

    const nodes = try parser.parse();

    const node = nodes.items[0];
    try expect(nodes.items.len == 1);
    try expectEqual(ASTNodeTag.@"or", node.tag);

    try expectEqualDeep(&ASTNode{ .tag = .lt, .data = .{
        .binary = ASTBinaryNode{
            .left = @constCast(&ASTNode{
                .tag = .number,
                .data = .{
                    .literal = "1",
                },
            }),
            .right = @constCast(&ASTNode{
                .tag = .number,
                .data = .{
                    .literal = "2",
                },
            }),
        },
    } }, node.data.binary.left);

    const rightNode = node.data.binary.right;
    try expectEqual(ASTNodeTag.@"and", rightNode.tag);
    try expectEqualDeep(&ASTNode{
        .tag = .number,
        .data = .{
            .literal = "3",
        },
    }, rightNode.data.binary.left);
    try expectEqualDeep(&ASTNode{ .tag = .eq, .data = .{
        .binary = ASTBinaryNode{
            .left = @constCast(&ASTNode{
                .tag = .number,
                .data = .{
                    .literal = "4",
                },
            }),
            .right = @constCast(&ASTNode{
                .tag = .number,
                .data = .{
                    .literal = "5",
                },
            }),
        },
    } }, rightNode.data.binary.right);
}
