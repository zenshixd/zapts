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
            return self.buffer[self.length - offset];
        }

        return self.buffer[@as(usize, @intCast(index))];
    }
};
