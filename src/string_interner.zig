const std = @import("std");
const assert = std.debug.assert;
const Reporter = @import("reporter.zig");

const expectEqual = std.testing.expectEqual;
const expectEqualStrings = std.testing.expectEqualStrings;

const StringInterner = @This();

pub const StringId = enum(u32) {
    empty = std.math.maxInt(u32) - 1,
    none = std.math.maxInt(u32),
    _,

    pub inline fn at(index: u32) StringId {
        return @enumFromInt(index);
    }
};

const StringLocation = struct {
    pos: u32,
    len: u32,
};

string_bytes: std.ArrayListUnmanaged(u8) = .empty,
string_table: std.ArrayListUnmanaged(StringLocation) = .empty,

pub fn deinit(self: *StringInterner, gpa: std.mem.Allocator) void {
    self.string_bytes.deinit(gpa);
    self.string_table.deinit(gpa);
}

pub fn lookup(self: *StringInterner, id: StringId) ?[]const u8 {
    if (id == StringId.empty) {
        return "";
    }

    if (@intFromEnum(id) >= self.string_table.items.len) {
        return null;
    }

    const loc = self.string_table.items[@intFromEnum(id)];
    return self.string_bytes.items[loc.pos..][0..loc.len];
}

pub fn search(self: *StringInterner, str: []const u8) ?StringId {
    if (str.len == 0) {
        return StringId.empty;
    }

    for (0..self.string_table.items.len) |i| {
        const str2 = self.lookup(@enumFromInt(i)) orelse break;

        if (std.mem.eql(u8, str, str2)) {
            return @enumFromInt(i);
        }
    }

    return null;
}

pub fn intern(self: *StringInterner, gpa: std.mem.Allocator, str: []const u8) StringId {
    if (str.len == 0) {
        return StringId.empty;
    }

    const result = self.search(str);
    if (result) |id| {
        return id;
    }

    const id = self.string_table.items.len;
    const pos = self.string_bytes.items.len;
    assert(pos < @intFromEnum(StringId.empty));
    self.string_bytes.appendSlice(gpa, str) catch unreachable;
    self.string_table.append(gpa, .{
        .pos = @intCast(pos),
        .len = @intCast(str.len),
    }) catch unreachable;
    return @enumFromInt(id);
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

    try expectEqual(0, @intFromEnum(id1));
    try expectEqual(1, @intFromEnum(id2));
    try expectEqual(2, @intFromEnum(id3));
    try expectEqual(@intFromEnum(StringId.empty), @intFromEnum(id4));

    try expectEqualStrings("", str_interner.lookup(StringId.empty) orelse return error.TestExpectedEqual);
    try expectEqualStrings("abc1", str_interner.lookup(id1) orelse return error.TestExpectedEqual);
    try expectEqualStrings("abc2", str_interner.lookup(id2) orelse return error.TestExpectedEqual);
    try expectEqualStrings("abc3", str_interner.lookup(id3) orelse return error.TestExpectedEqual);
    try expectEqual(null, str_interner.lookup(@enumFromInt(99999)));

    const id1_copy = str_interner.intern(gpa, "abc1");
    const id2_copy = str_interner.intern(gpa, "abc2");
    const id3_copy = str_interner.intern(gpa, "abc3");

    try expectEqual(id1, id1_copy);
    try expectEqual(id2, id2_copy);
    try expectEqual(id3, id3_copy);
}
