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

test "should parse function call" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    const allocator = arena.allocator();
    defer arena.deinit();

    var tokens = [_]Token{
        valued(TokenType.Identifier, "foo"),
        simple(TokenType.OpenParen),
        valued(TokenType.Identifier, "bar"),
        simple(TokenType.Plus),
        valued(TokenType.Identifier, "baz"),
        simple(TokenType.CloseParen),
        simple(TokenType.Semicolon),
        simple(TokenType.Eof),
    };

    var parser = Parser.init(allocator, &tokens);

    const nodes = try parser.parse();

    try expect(nodes.len == 1);
    try expectEqualDeep(&ASTNode{
        .tag = .call_expr,
        .data = .{
            .nodes = @constCast(&[_]*ASTNode{
                @constCast(&ASTNode{
                    .tag = .identifier,
                    .data = .{ .literal = "foo" },
                }),
                @constCast(&ASTNode{
                    .tag = .plus_expr,
                    .data = .{
                        .binary = ASTBinaryNode{
                            .left = @constCast(&ASTNode{
                                .tag = .identifier,
                                .data = .{ .literal = "bar" },
                            }),
                            .right = @constCast(&ASTNode{
                                .tag = .identifier,
                                .data = .{ .literal = "baz" },
                            }),
                        },
                    },
                }),
            }),
        },
    }, nodes[0]);
}

test "function call with multiple arguments" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const allocator = arena.allocator();
    var tokens = [_]Token{
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

    var parser = Parser.init(allocator, &tokens);

    const nodes = try parser.parse();

    try expect(nodes.len == 1);
    try expectEqualDeep(&ASTNode{
        .tag = .call_expr,
        .data = .{
            .nodes = @constCast(&[_]*ASTNode{
                @constCast(&ASTNode{
                    .tag = .identifier,
                    .data = .{ .literal = "foo" },
                }),
                @constCast(&ASTNode{
                    .tag = .plus_expr,
                    .data = .{
                        .binary = ASTBinaryNode{
                            .left = @constCast(&ASTNode{
                                .tag = .identifier,
                                .data = .{ .literal = "bar" },
                            }),
                            .right = @constCast(&ASTNode{
                                .tag = .identifier,
                                .data = .{ .literal = "baz" },
                            }),
                        },
                    },
                }),
                @constCast(&ASTNode{
                    .tag = .identifier,
                    .data = .{ .literal = "qux" },
                }),
            }),
        },
    }, nodes[0]);
}

test "should call a function through a property access" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    const allocator = arena.allocator();
    defer arena.deinit();

    var tokens = [_]Token{
        valued(TokenType.Identifier, "foo"),
        simple(TokenType.Dot),
        valued(TokenType.Identifier, "bar"),
        simple(TokenType.OpenParen),
        simple(TokenType.CloseParen),
        simple(TokenType.Semicolon),
        simple(TokenType.Eof),
    };

    var parser = Parser.init(allocator, &tokens);

    const nodes = try parser.parse();

    try expect(nodes.len == 1);
    try expectEqualDeep(&ASTNode{
        .tag = .call_expr,
        .data = .{
            .nodes = @constCast(&[_]*ASTNode{
                @constCast(&ASTNode{
                    .tag = .property_access,
                    .data = .{
                        .binary = ASTBinaryNode{
                            .left = @constCast(&ASTNode{
                                .tag = .identifier,
                                .data = .{ .literal = "foo" },
                            }),
                            .right = @constCast(&ASTNode{
                                .tag = .identifier,
                                .data = .{ .literal = "bar" },
                            }),
                        },
                    },
                }),
            }),
        },
    }, nodes[0]);
}

test "should call a function through a index access" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    const allocator = arena.allocator();
    defer arena.deinit();

    var tokens = [_]Token{
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

    var parser = Parser.init(allocator, &tokens);

    const nodes = try parser.parse();

    try expect(nodes.len == 1);
    try expectEqualDeep(&ASTNode{
        .tag = .call_expr,
        .data = .{
            .nodes = @constCast(&[_]*ASTNode{
                @constCast(&ASTNode{
                    .tag = .index_access,
                    .data = .{
                        .binary = ASTBinaryNode{
                            .left = @constCast(&ASTNode{
                                .tag = .property_access,
                                .data = .{
                                    .binary = ASTBinaryNode{
                                        .left = @constCast(&ASTNode{
                                            .tag = .identifier,
                                            .data = .{ .literal = "foo" },
                                        }),
                                        .right = @constCast(&ASTNode{
                                            .tag = .identifier,
                                            .data = .{ .literal = "bar" },
                                        }),
                                    },
                                },
                            }),
                            .right = @constCast(&ASTNode{
                                .tag = .number,
                                .data = .{
                                    .literal = "1",
                                },
                            }),
                        },
                    },
                }),
            }),
        },
    }, nodes[0]);
}
