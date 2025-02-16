const std = @import("std");
const assert = std.debug.assert;
const StringId = @import("string_interner.zig").StringId;

const Type = @This();

pub const Index = enum(u32) {
    any,
    number,
    bigint,
    string,
    boolean,
    true,
    false,
    regex,
    null,
    undefined,
    unknown,
    never,
    none = std.math.maxInt(u32),
    _,

    pub inline fn int(self: Index) u32 {
        return @intFromEnum(self);
    }
};

pub fn at(index: u32) Index {
    return @enumFromInt(index);
}

pub const Kind = enum {
    any,
    number,
    number_literal,
    bigint,
    bigint_literal,
    string,
    string_literal,
    boolean,
    true,
    false,
    null,
    undefined,
    unknown,
    never,
    regex,
    object,
    array,
    tuple,
    function,
    other_type,
};

pub const Data = union(enum) {
    none: void,
    literal: StringId,
};

const PREFILL_TYPES = [_]Type{
    .{ .kind = .any },
    .{ .kind = .number },
    .{ .kind = .bigint },
    .{ .kind = .string },
    .{ .kind = .boolean },
    .{ .kind = .true },
    .{ .kind = .false },
    .{ .kind = .regex },
    .{ .kind = .null },
    .{ .kind = .undefined },
    .{ .kind = .unknown },
    .{ .kind = .never },
};

comptime {
    for (PREFILL_TYPES, 0..) |ty, i| {
        if (!std.mem.eql(u8, @tagName(ty.kind), @tagName(at(i)))) {
            @compileError(std.fmt.comptimePrint("PREFILL_TYPES is out of sync with the enum, expected {s} at index {}, but found {s}", .{ @tagName(ty.kind), i, @tagName(at(i)) }));
        }
    }
}

kind: Kind,
data: Data = .none,

pub fn initArray(gpa: std.mem.Allocator) std.ArrayList(Type) {
    var arr = std.ArrayList(Type).init(gpa);
    arr.appendSlice(&PREFILL_TYPES) catch unreachable;
    return arr;
}

pub fn format(self: Type, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
    if (self.kind != .other_type) {
        try writer.print("{s}", .{@tagName(self.kind)});
    } else {
        try writer.print("{}", .{self.data.literal});
    }
}
