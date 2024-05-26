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

test "should parse property access" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    const allocator = arena.allocator();
    defer arena.deinit();

    var tokens = [_]Token{
        valued(TokenType.Identifier, "foo"),
        simple(TokenType.Dot),
        valued(TokenType.Identifier, "bar"),
        simple(TokenType.Semicolon),
        simple(TokenType.Eof),
    };

    var parser = try Parser.init(allocator, &tokens);

    const nodes = try parser.parse();

    try expect(nodes.len == 1);
    try expectEqualDeep(&ASTNode{
        .tag = .property_access,
        .data_type = .{ .any = {} },
        .data = .{ .binary = ASTBinaryNode{
            .left = @constCast(&ASTNode{ .tag = .identifier, .data_type = .{ .any = {} }, .data = .{ .literal = "foo" } }),
            .right = @constCast(&ASTNode{ .tag = .identifier, .data_type = .{ .any = {} }, .data = .{ .literal = "bar" } }),
        } },
    }, nodes[0]);
}

test "should parse property access with question mark" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    const allocator = arena.allocator();
    defer arena.deinit();

    var tokens = [_]Token{
        valued(TokenType.Identifier, "foo"),
        simple(TokenType.QuestionMarkDot),
        valued(TokenType.Identifier, "bar"),
        simple(TokenType.Semicolon),
        simple(TokenType.Eof),
    };

    var parser = try Parser.init(allocator, &tokens);

    const nodes = try parser.parse();

    try expect(nodes.len == 1);
    try expectEqualDeep(&ASTNode{
        .tag = .optional_property_access,
        .data_type = .{ .any = {} },
        .data = .{ .binary = ASTBinaryNode{
            .left = @constCast(&ASTNode{ .tag = .identifier, .data_type = .{ .any = {} }, .data = .{ .literal = "foo" } }),
            .right = @constCast(&ASTNode{ .tag = .identifier, .data_type = .{ .any = {} }, .data = .{ .literal = "bar" } }),
        } },
    }, nodes[0]);
}

test "should parse property access with index access" {
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
        simple(TokenType.Semicolon),
        simple(TokenType.Eof),
    };

    var parser = try Parser.init(allocator, &tokens);

    const nodes = try parser.parse();

    try expect(nodes.len == 1);
    try expectEqualDeep(&ASTNode{
        .tag = .index_access,
        .data_type = .{ .unknown = {} },
        .data = .{ .binary = ASTBinaryNode{
            .left = @constCast(&ASTNode{
                .tag = .property_access,
                .data_type = .{ .any = {} },
                .data = .{ .binary = ASTBinaryNode{
                    .left = @constCast(&ASTNode{ .tag = .identifier, .data_type = .{ .any = {} }, .data = .{ .literal = "foo" } }),
                    .right = @constCast(&ASTNode{ .tag = .identifier, .data_type = .{ .any = {} }, .data = .{ .literal = "bar" } }),
                } },
            }),
            .right = @constCast(&ASTNode{ .tag = .number, .data_type = .{ .number = {} }, .data = .{ .literal = "1" } }),
        } },
    }, nodes[0]);
}

test "should parse expression in index access" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    const allocator = arena.allocator();
    defer arena.deinit();

    var tokens = [_]Token{
        valued(TokenType.Identifier, "foo"),
        simple(TokenType.OpenSquareBracket),
        valued(TokenType.NumberConstant, "1"),
        simple(TokenType.Plus),
        valued(TokenType.NumberConstant, "2"),
        simple(TokenType.CloseSquareBracket),
        simple(TokenType.Semicolon),
        simple(TokenType.Eof),
    };

    var parser = try Parser.init(allocator, &tokens);

    const nodes = try parser.parse();

    try expect(nodes.len == 1);
    try expectEqualDeep(&ASTNode{
        .tag = .index_access,
        .data_type = .{ .unknown = {} },
        .data = .{ .binary = ASTBinaryNode{
            .left = @constCast(&ASTNode{
                .tag = .identifier,
                .data_type = .{ .any = {} },
                .data = .{ .literal = "foo" },
            }),
            .right = @constCast(&ASTNode{
                .tag = .plus_expr,
                .data_type = .{ .number = {} },
                .data = .{ .binary = ASTBinaryNode{
                    .left = @constCast(&ASTNode{ .tag = .number, .data_type = .{ .number = {} }, .data = .{ .literal = "1" } }),
                    .right = @constCast(&ASTNode{ .tag = .number, .data_type = .{ .number = {} }, .data = .{ .literal = "2" } }),
                } },
            }),
        } },
    }, nodes[0]);
}
