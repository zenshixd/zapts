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

    var parser = Parser.init(allocator, &tokens);

    const nodes = try parser.parse();

    try expect(nodes.items.len == 1);
    try expectEqualDeep(&ASTNode{
        .tag = .property_access,
        .data = .{ .binary = ASTBinaryNode{
            .left = @constCast(&ASTNode{ .tag = .identifier, .data = .{ .literal = "foo" } }),
            .right = @constCast(&ASTNode{ .tag = .identifier, .data = .{ .literal = "bar" } }),
        } },
    }, nodes.items[0]);
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

    var parser = Parser.init(allocator, &tokens);

    const nodes = try parser.parse();

    try expect(nodes.items.len == 1);
    try expectEqualDeep(&ASTNode{
        .tag = .optional_property_access,
        .data = .{ .binary = ASTBinaryNode{
            .left = @constCast(&ASTNode{ .tag = .identifier, .data = .{ .literal = "foo" } }),
            .right = @constCast(&ASTNode{ .tag = .identifier, .data = .{ .literal = "bar" } }),
        } },
    }, nodes.items[0]);
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

    var parser = Parser.init(allocator, &tokens);

    const nodes = try parser.parse();

    try expect(nodes.items.len == 1);
    try expectEqualDeep(&ASTNode{
        .tag = .index_access,
        .data = .{ .binary = ASTBinaryNode{
            .left = @constCast(&ASTNode{
                .tag = .property_access,
                .data = .{ .binary = ASTBinaryNode{
                    .left = @constCast(&ASTNode{ .tag = .identifier, .data = .{ .literal = "foo" } }),
                    .right = @constCast(&ASTNode{ .tag = .identifier, .data = .{ .literal = "bar" } }),
                } },
            }),
            .right = @constCast(&ASTNode{ .tag = .number, .data = .{ .literal = "1" } }),
        } },
    }, nodes.items[0]);
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

    var parser = Parser.init(allocator, &tokens);

    const nodes = try parser.parse();

    try expect(nodes.items.len == 1);
    try expectEqualDeep(&ASTNode{
        .tag = .index_access,
        .data = .{ .binary = ASTBinaryNode{
            .left = @constCast(&ASTNode{
                .tag = .identifier,
                .data = .{ .literal = "foo" },
            }),
            .right = @constCast(&ASTNode{
                .tag = .plus_expr,
                .data = .{ .binary = ASTBinaryNode{
                    .left = @constCast(&ASTNode{ .tag = .number, .data = .{ .literal = "1" } }),
                    .right = @constCast(&ASTNode{ .tag = .number, .data = .{ .literal = "2" } }),
                } },
            }),
        } },
    }, nodes.items[0]);
}
