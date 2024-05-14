const std = @import("std");
const Parser = @import("../../parser.zig");
const Token = @import("../../consts.zig").Token;
const TokenType = @import("../../consts.zig").TokenType;
const valued = @import("../helpers.zig").valued;
const simple = @import("../helpers.zig").simple;

const ASTNode = Parser.ASTNode;
const ASTFunctionExpressionNode = Parser.ASTFunctionExpressionNode;
const ASTBlockNode = Parser.ASTBlockNode;

const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
const expectEqualStrings = std.testing.expectEqualStrings;
const expectEqualDeep = std.testing.expectEqualDeep;

test "should parse function expression" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    const allocator = arena.allocator();
    defer arena.deinit();

    var arr = [_]Token{
        simple(TokenType.Function),
        valued(TokenType.Identifier, "foo"),
        simple(TokenType.OpenParen),
        valued(TokenType.Identifier, "bar"),
        simple(TokenType.Comma),
        valued(TokenType.Identifier, "baz"),
        simple(TokenType.CloseParen),
        simple(TokenType.OpenCurlyBrace),
        simple(TokenType.CloseCurlyBrace),
        simple(TokenType.Eof),
    };
    const tokens = std.ArrayList(Token).fromOwnedSlice(allocator, &arr);

    var parser = Parser.init(allocator, tokens);

    const nodes = try parser.parse();

    var expectedArgs = std.ArrayList([]const u8).init(allocator);
    try expectedArgs.append("bar");
    try expectedArgs.append("baz");

    try expectEqual(1, nodes.items.len);
    try expectEqualDeep(&ASTNode{
        .function_expression = ASTFunctionExpressionNode{
            .is_async = false,
            .name = "foo",
            .arguments = expectedArgs,
            .body = @constCast(&ASTNode{
                .block = ASTBlockNode{
                    .statements = std.ArrayList(*ASTNode).init(allocator),
                },
            }),
        },
    }, nodes.items[0]);
}

test "should parse async function expression" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    const allocator = arena.allocator();
    defer arena.deinit();

    var arr = [_]Token{
        simple(TokenType.Async),
        simple(TokenType.Function),
        valued(TokenType.Identifier, "foo"),
        simple(TokenType.OpenParen),
        valued(TokenType.Identifier, "bar"),
        simple(TokenType.Comma),
        valued(TokenType.Identifier, "baz"),
        simple(TokenType.CloseParen),
        simple(TokenType.OpenCurlyBrace),
        simple(TokenType.CloseCurlyBrace),
        simple(TokenType.Eof),
    };
    const tokens = std.ArrayList(Token).fromOwnedSlice(allocator, &arr);
    defer tokens.deinit();

    var parser = Parser.init(allocator, tokens);

    const nodes = try parser.parse();

    var expectedArgs = std.ArrayList([]const u8).init(allocator);
    try expectedArgs.append("bar");
    try expectedArgs.append("baz");

    try expectEqual(1, nodes.items.len);
    try expectEqualDeep(&ASTNode{
        .function_expression = ASTFunctionExpressionNode{
            .is_async = true,
            .name = "foo",
            .arguments = expectedArgs,
            .body = @constCast(&ASTNode{
                .block = ASTBlockNode{
                    .statements = std.ArrayList(*ASTNode).init(allocator),
                },
            }),
        },
    }, nodes.items[0]);
}
