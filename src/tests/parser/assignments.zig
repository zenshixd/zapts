const std = @import("std");
const Token = @import("../../consts.zig").Token;
const TokenType = @import("../../consts.zig").TokenType;
const Parser = @import("../../parser.zig");

const simple = @import("../helpers.zig").simple;
const valued = @import("../helpers.zig").valued;

const ASTNode = Parser.ASTNode;
const ASTBinaryNode = Parser.ASTBinaryNode;

const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
const expectEqualDeep = std.testing.expectEqualDeep;

fn parse(allocator: std.mem.Allocator, tokens: []Token) ![]*Parser.ASTNode {
    var parser = try Parser.init(allocator, tokens);
    return parser.parse();
}

test "should parse assignment" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var tokens = [_]Token{
        valued(TokenType.Identifier, "a"),
        simple(TokenType.Equal),
        valued(TokenType.NumberConstant, "1"),
        simple(TokenType.Semicolon),
        simple(TokenType.Eof),
    };

    const nodes = try parse(allocator, &tokens);

    try expectEqualDeep(&ASTNode{
        .tag = .assignment,
        .data_type = .{ .number = {} },
        .data = .{
            .binary = ASTBinaryNode{
                .left = @constCast(&ASTNode{
                    .tag = .identifier,
                    .data_type = .{ .any = {} },
                    .data = .{ .literal = "a" },
                }),
                .right = @constCast(&ASTNode{
                    .tag = .number,
                    .data_type = .{ .number = {} },
                    .data = .{ .literal = "1" },
                }),
            },
        },
    }, nodes[0]);
}

test "should parse cascade assignments" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var tokens = [_]Token{
        valued(TokenType.Identifier, "a"),
        simple(TokenType.Equal),
        valued(TokenType.Identifier, "b"),
        simple(TokenType.Equal),
        valued(TokenType.NumberConstant, "1"),
        simple(TokenType.Semicolon),
        simple(TokenType.Eof),
    };

    const nodes = try parse(allocator, &tokens);

    try expectEqualDeep(&ASTNode{
        .tag = .assignment,
        .data_type = .{ .number = {} },
        .data = .{
            .binary = ASTBinaryNode{
                .left = @constCast(&ASTNode{
                    .tag = .identifier,
                    .data_type = .{ .any = {} },
                    .data = .{ .literal = "a" },
                }),
                .right = @constCast(&ASTNode{
                    .tag = .assignment,
                    .data_type = .{ .number = {} },
                    .data = .{
                        .binary = ASTBinaryNode{
                            .left = @constCast(&ASTNode{
                                .tag = .identifier,
                                .data_type = .{ .any = {} },
                                .data = .{ .literal = "b" },
                            }),
                            .right = @constCast(&ASTNode{
                                .tag = .number,
                                .data_type = .{ .number = {} },
                                .data = .{ .literal = "1" },
                            }),
                        },
                    },
                }),
            },
        },
    }, nodes[0]);
}
