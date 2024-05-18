const std = @import("std");
const Parser = @import("../../parser.zig");
const Token = @import("../../consts.zig").Token;
const TokenType = @import("../../consts.zig").TokenType;
const valued = @import("../helpers.zig").valued;
const simple = @import("../helpers.zig").simple;

const ASTNode = Parser.ASTNode;
const ASTCallableExpressionNode = Parser.ASTCallableExpressionNode;
const ASTLiteralNode = Parser.ASTLiteralNode;
const ASTBinaryExpressionNode = Parser.ASTBinaryExpressionNode;

const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
const expectEqualStrings = std.testing.expectEqualStrings;
const expectEqualDeep = std.testing.expectEqualDeep;

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

    var expectedArgs = std.ArrayList(*ASTNode).init(allocator);
    try expectedArgs.append(@constCast(&ASTNode{
        .binary = ASTBinaryExpressionNode{
            .left = @constCast(&ASTNode{
                .literal = ASTLiteralNode{
                    .value = Token{ .type = TokenType.Identifier, .value = "bar" },
                },
            }),
            .operator = TokenType.Plus,
            .right = @constCast(&ASTNode{
                .literal = ASTLiteralNode{
                    .value = Token{ .type = TokenType.Identifier, .value = "baz" },
                },
            }),
        },
    }));

    try expect(nodes.items.len == 1);
    try expectEqualDeep(&ASTNode{
        .callable_expression = ASTCallableExpressionNode{
            .left = @constCast(&ASTNode{
                .literal = ASTLiteralNode{
                    .value = Token{ .type = TokenType.Identifier, .value = "foo" },
                },
            }),
            .arguments = expectedArgs,
        },
    }, nodes.items[0]);
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

    var expectedArgs = std.ArrayList(*ASTNode).init(allocator);
    try expectedArgs.append(@constCast(&ASTNode{
        .binary = ASTBinaryExpressionNode{
            .left = @constCast(&ASTNode{
                .literal = ASTLiteralNode{
                    .value = Token{ .type = TokenType.Identifier, .value = "bar" },
                },
            }),
            .operator = TokenType.Plus,
            .right = @constCast(&ASTNode{
                .literal = ASTLiteralNode{
                    .value = Token{ .type = TokenType.Identifier, .value = "baz" },
                },
            }),
        },
    }));
    try expectedArgs.append(@constCast(&ASTNode{
        .literal = ASTLiteralNode{
            .value = Token{ .type = TokenType.Identifier, .value = "qux" },
        },
    }));
    try expect(nodes.items.len == 1);
    try expectEqualDeep(&ASTNode{
        .callable_expression = ASTCallableExpressionNode{
            .left = @constCast(&ASTNode{
                .literal = ASTLiteralNode{
                    .value = Token{ .type = TokenType.Identifier, .value = "foo" },
                },
            }),
            .arguments = expectedArgs,
        },
    }, nodes.items[0]);
}

test "should call a function through a property access" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    const allocator = arena.allocator();
    defer arena.deinit();

    var arr = [_]Token{
        valued(TokenType.Identifier, "foo"),
        simple(TokenType.Dot),
        valued(TokenType.Identifier, "bar"),
        simple(TokenType.OpenParen),
        simple(TokenType.CloseParen),
        simple(TokenType.Semicolon),
        simple(TokenType.Eof),
    };
    const tokens = std.ArrayList(Token).fromOwnedSlice(allocator, &arr);

    var parser = Parser.init(allocator, tokens);

    const nodes = try parser.parse();

    const expectedArgs = std.ArrayList(*ASTNode).init(allocator);

    try expect(nodes.items.len == 1);
    try expectEqualDeep(&ASTNode{
        .callable_expression = ASTCallableExpressionNode{
            .left = @constCast(&ASTNode{
                .binary = ASTBinaryExpressionNode{
                    .left = @constCast(&ASTNode{
                        .literal = ASTLiteralNode{
                            .value = Token{ .type = TokenType.Identifier, .value = "foo" },
                        },
                    }),
                    .operator = TokenType.Dot,
                    .right = @constCast(&ASTNode{
                        .literal = ASTLiteralNode{
                            .value = Token{ .type = TokenType.Identifier, .value = "bar" },
                        },
                    }),
                },
            }),
            .arguments = expectedArgs,
        },
    }, nodes.items[0]);
}

test "should call a function through a index access" {
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
        simple(TokenType.OpenParen),
        simple(TokenType.CloseParen),
        simple(TokenType.Semicolon),
        simple(TokenType.Eof),
    };
    const tokens = std.ArrayList(Token).fromOwnedSlice(allocator, &arr);

    var parser = Parser.init(allocator, tokens);

    const nodes = try parser.parse();

    const expectedArgs = std.ArrayList(*ASTNode).init(allocator);

    try expect(nodes.items.len == 1);
    try expectEqualDeep(&ASTNode{
        .callable_expression = ASTCallableExpressionNode{
            .left = @constCast(&ASTNode{
                .binary = ASTBinaryExpressionNode{
                    .left = @constCast(&ASTNode{
                        .binary = ASTBinaryExpressionNode{
                            .left = @constCast(&ASTNode{
                                .literal = ASTLiteralNode{
                                    .value = Token{ .type = TokenType.Identifier, .value = "foo" },
                                },
                            }),
                            .operator = TokenType.Dot,
                            .right = @constCast(&ASTNode{
                                .literal = ASTLiteralNode{
                                    .value = Token{ .type = TokenType.Identifier, .value = "bar" },
                                },
                            }),
                        },
                    }),
                    .operator = TokenType.OpenSquareBracket,
                    .right = @constCast(&ASTNode{
                        .literal = ASTLiteralNode{ .value = Token{ .type = TokenType.NumberConstant, .value = "1" } },
                    }),
                },
            }),
            .arguments = expectedArgs,
        },
    }, nodes.items[0]);
}
