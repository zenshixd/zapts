const std = @import("std");

pub const String = struct {
    length: u64,

    buffer: []u8,
    allocator: std.mem.Allocator,
    capacity: u64,

    pub fn new(allocator: std.mem.Allocator, capacity: u64) !String {
        return String{
            .length = 0,
            .buffer = try allocator.alloc(u8, capacity),
            .allocator = allocator,
            .capacity = capacity,
        };
    }

    pub fn deinit(self: String) void {
        self.allocator.free(self.buffer);
    }

    pub fn value(self: String) []const u8 {
        return self.buffer[0..self.length];
    }

    pub fn append(self: *String, char: u8) !void {
        try self.ensure_capacity(1);
        self.buffer[self.length] = char;
        self.length += 1;
    }

    pub fn append_many(self: *String, new_str: []const u8) !void {
        try self.ensure_capacity(new_str.len);
        std.mem.copyForwards(u8, self.buffer[self.length..], new_str);
        self.length += new_str.len;
    }

    fn ensure_capacity(self: *String, new_len: u64) !void {
        if (self.length + new_len > self.buffer.len) {
            self.buffer = try self.allocator.realloc(self.buffer, self.length + new_len + self.capacity);
        }
    }

    pub fn at(self: String, index: i64) ?u8 {
        if (self.length == 0 or (index > 0 and self.length <= index) or (index < 0 and self.length < -index)) {
            return null;
        }

        if (index < 0) {
            const offset: usize = @as(usize, @intCast(-index));
            std.debug.print("test: {d} {d}\n", .{ self.length, offset });
            return self.buffer[self.length - offset];
        }

        return self.buffer[@as(usize, @intCast(index))];
    }
};

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