const std = @import("std");
const Parser = @import("../../parser.zig");
const Token = @import("../../consts.zig").Token;
const TokenType = @import("../../consts.zig").TokenType;
const valued = @import("../helpers.zig").valued;
const simple = @import("../helpers.zig").simple;

const ASTNode = Parser.ASTNode;
const ASTBinaryNode = Parser.ASTBinaryNode;

const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
const expectEqualStrings = std.testing.expectEqualStrings;
const expectEqualDeep = std.testing.expectEqualDeep;

test "parses a addition expression" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var tokens = [_]Token{
        valued(TokenType.NumberConstant, "1"),
        simple(TokenType.Plus),
        valued(TokenType.NumberConstant, "2"),
        simple(TokenType.Semicolon),
        simple(TokenType.Eof),
    };

    var parser = try Parser.init(allocator, &tokens);

    const nodes = try parser.parse();

    try expect(nodes.len == 1);
    try expectEqualDeep(&ASTNode{
        .tag = .plus_expr,
        .data_type = .{ .number = {} },
        .data = .{
            .binary = ASTBinaryNode{
                .left = @constCast(&ASTNode{
                    .tag = .number,
                    .data_type = .{ .number = {} },
                    .data = .{
                        .literal = "1",
                    },
                }),
                .right = @constCast(&ASTNode{
                    .tag = .number,
                    .data_type = .{ .number = {} },
                    .data = .{
                        .literal = "2",
                    },
                }),
            },
        },
    }, nodes[0]);
}

test "parses a substraction expression" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var tokens = [_]Token{
        valued(TokenType.NumberConstant, "1"),
        simple(TokenType.Minus),
        valued(TokenType.NumberConstant, "2"),
        simple(TokenType.Semicolon),
        simple(TokenType.Eof),
    };
    var parser = try Parser.init(allocator, &tokens);

    const nodes = try parser.parse();

    try expect(nodes.len == 1);
    try expectEqualDeep(&ASTNode{
        .tag = .minus_expr,
        .data_type = .{ .number = {} },
        .data = .{
            .binary = ASTBinaryNode{
                .left = @constCast(&ASTNode{
                    .tag = .number,
                    .data_type = .{ .number = {} },
                    .data = .{
                        .literal = "1",
                    },
                }),
                .right = @constCast(&ASTNode{
                    .tag = .number,
                    .data_type = .{ .number = {} },
                    .data = .{
                        .literal = "2",
                    },
                }),
            },
        },
    }, nodes[0]);
}

test "parses a multiplication expression" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var tokens = [_]Token{
        valued(TokenType.NumberConstant, "1"),
        simple(TokenType.Star),
        valued(TokenType.NumberConstant, "2"),
        simple(TokenType.Semicolon),
        simple(TokenType.Eof),
    };

    var parser = try Parser.init(allocator, &tokens);

    const nodes = try parser.parse();

    try expect(nodes.len == 1);
    try expectEqualDeep(&ASTNode{
        .tag = .multiply_expr,
        .data_type = .{ .number = {} },
        .data = .{
            .binary = ASTBinaryNode{
                .left = @constCast(&ASTNode{
                    .tag = .number,
                    .data_type = .{ .number = {} },
                    .data = .{
                        .literal = "1",
                    },
                }),
                .right = @constCast(&ASTNode{
                    .tag = .number,
                    .data_type = .{ .number = {} },
                    .data = .{
                        .literal = "2",
                    },
                }),
            },
        },
    }, nodes[0]);
}

test "parses an expression with multiple operators" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var tokens = [_]Token{
        valued(TokenType.NumberConstant, "1"),
        simple(TokenType.Minus),
        valued(TokenType.NumberConstant, "2"),
        simple(TokenType.Plus),
        valued(TokenType.NumberConstant, "3"),
        simple(TokenType.Semicolon),
        simple(TokenType.Eof),
    };

    var parser = try Parser.init(allocator, &tokens);

    const nodes = try parser.parse();

    try expect(nodes.len == 1);
    try expectEqualDeep(&ASTNode{
        .tag = .plus_expr,
        .data_type = .{ .number = {} },
        .data = .{ .binary = ASTBinaryNode{
            .left = @constCast(&ASTNode{
                .tag = .minus_expr,
                .data_type = .{ .number = {} },
                .data = .{ .binary = ASTBinaryNode{
                    .left = @constCast(&ASTNode{
                        .tag = .number,
                        .data_type = .{ .number = {} },
                        .data = .{ .literal = "1" },
                    }),
                    .right = @constCast(&ASTNode{
                        .tag = .number,
                        .data_type = .{ .number = {} },
                        .data = .{ .literal = "2" },
                    }),
                } },
            }),
            .right = @constCast(&ASTNode{
                .tag = .number,
                .data_type = .{ .number = {} },
                .data = .{ .literal = "3" },
            }),
        } },
    }, nodes[0]);
}

test "parses an expression with multiple types of operators" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var tokens = [_]Token{
        valued(TokenType.NumberConstant, "1"),
        simple(TokenType.Minus),
        valued(TokenType.NumberConstant, "2"),
        simple(TokenType.Star),
        valued(TokenType.NumberConstant, "3"),
        simple(TokenType.Semicolon),
        simple(TokenType.Eof),
    };

    var parser = try Parser.init(allocator, &tokens);

    const nodes = try parser.parse();

    try expect(nodes.len == 1);
    try expectEqualDeep(&ASTNode{
        .tag = .minus_expr,
        .data_type = .{ .number = {} },
        .data = .{ .binary = ASTBinaryNode{
            .left = @constCast(&ASTNode{
                .tag = .number,
                .data_type = .{ .number = {} },
                .data = .{ .literal = "1" },
            }),
            .right = @constCast(&ASTNode{
                .tag = .multiply_expr,
                .data_type = .{ .number = {} },
                .data = .{ .binary = ASTBinaryNode{
                    .left = @constCast(&ASTNode{
                        .tag = .number,
                        .data_type = .{ .number = {} },
                        .data = .{ .literal = "2" },
                    }),
                    .right = @constCast(&ASTNode{
                        .tag = .number,
                        .data_type = .{ .number = {} },
                        .data = .{ .literal = "3" },
                    }),
                } },
            }),
        } },
    }, nodes[0]);
}
