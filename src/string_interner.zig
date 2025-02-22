const std = @import("std");
const Reporter = @import("reporter.zig");

const expectEqual = std.testing.expectEqual;
const expectEqualStrings = std.testing.expectEqualStrings;

const StringInterner = @This();

pub const StringId = enum(u32) {
    empty,
    none = std.math.maxInt(u32),
    _,

    pub inline fn at(index: u32) StringId {
        return @enumFromInt(index);
    }

    pub inline fn int(self: StringId) u32 {
        return @intFromEnum(self);
    }
};

strings: std.StringHashMapUnmanaged(StringId) = .{},
next_id: StringId = @enumFromInt(@intFromEnum(StringId.empty) + 1),

pub fn deinit(self: *StringInterner, gpa: std.mem.Allocator) void {
    self.strings.deinit(gpa);
}

pub fn lookup(self: *StringInterner, id: StringId) ?[]const u8 {
    if (id == StringId.empty) {
        return "";
    }

    var it = self.strings.iterator();
    while (it.next()) |entry| {
        if (entry.value_ptr.* == id) {
            return entry.key_ptr.*;
        }
    }

    return null;
}

pub fn intern(self: *StringInterner, gpa: std.mem.Allocator, str: []const u8) StringId {
    if (str.len == 0) {
        return StringId.empty;
    }

    const result = self.strings.getOrPut(gpa, str) catch unreachable;
    if (result.found_existing) {
        return result.value_ptr.*;
    }

    defer self.next_id = @enumFromInt(@intFromEnum(self.next_id) + 1);
    result.value_ptr.* = self.next_id;
    return self.next_id;
}

pub fn toSlice(self: *StringInterner, gpa: std.mem.Allocator) []const []const u8 {
    var lookup_table = gpa.alloc([]const u8, self.strings.count() * std.mem.sizeOf(u32)) catch @panic("out of memory");
    var it = self.strings.iterator();
    lookup_table[0] = "";
    while (it.next()) |entry| {
        lookup_table[entry.value_ptr.*] = entry.key_ptr.*;
    }
    return lookup_table;
}

test "should intern string" {
    const gpa = std.testing.allocator;
    var str_interner = StringInterner{};
    defer str_interner.deinit(gpa);

    const id1 = str_interner.intern(gpa, "abc1");
    const id2 = str_interner.intern(gpa, "abc2");
    const id3 = str_interner.intern(gpa, "abc3");
    const id4 = str_interner.intern(gpa, "");

    try expectEqual(1, id1.int());
    try expectEqual(2, id2.int());
    try expectEqual(3, id3.int());
    try expectEqual(StringId.empty.int(), id4.int());

    try expectEqualStrings("", str_interner.lookup(StringId.empty) orelse return error.TestExpectedEqual);
    try expectEqualStrings("abc1", str_interner.lookup(id1) orelse return error.TestExpectedEqual);
    try expectEqualStrings("abc2", str_interner.lookup(id2) orelse return error.TestExpectedEqual);
    try expectEqualStrings("abc3", str_interner.lookup(id3) orelse return error.TestExpectedEqual);
    try expectEqual(null, str_interner.lookup(StringId.at(99999)));

    const id1_copy = str_interner.intern(gpa, "abc1");
    const id2_copy = str_interner.intern(gpa, "abc2");
    const id3_copy = str_interner.intern(gpa, "abc3");

    try expectEqual(id1, id1_copy);
    try expectEqual(id2, id2_copy);
    try expectEqual(id3, id3_copy);
}
