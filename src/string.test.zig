const std = @import("std");
const String = @import("string.zig").String;

test "should append a char" {
    var str = try String.new(std.testing.allocator, 100);
    defer str.deinit();

    try str.append('a');
    try std.testing.expectEqualStrings("a", str.value());
}

test "should append many chars" {
    var str = try String.new(std.testing.allocator, 100);
    defer str.deinit();

    try str.append_many("hello");
    try std.testing.expectEqualStrings("hello", str.value());
}

test "should return char at index" {
    var str = try String.new(std.testing.allocator, 100);
    defer str.deinit();

    try str.append_many("hello");
    try std.testing.expectEqual('h', str.at(0));
    try std.testing.expectEqual('e', str.at(1));
    try std.testing.expectEqual('l', str.at(2));
    try std.testing.expectEqual('l', str.at(3));
    try std.testing.expectEqual('o', str.at(4));
    try std.testing.expectEqual(null, str.at(5));

    try std.testing.expectEqual('o', str.at(-1));
    try std.testing.expectEqual('l', str.at(-2));
    try std.testing.expectEqual('l', str.at(-3));
    try std.testing.expectEqual('e', str.at(-4));
    try std.testing.expectEqual('h', str.at(-5));
    try std.testing.expectEqual(null, str.at(-6));
}
