const std = @import("std");
const assert = std.debug.assert;
const StringId = @import("string_interner.zig").StringId;

const TypeMap = @This();

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
        if (!std.mem.eql(u8, @tagName(ty.kind), @tagName(Type.at(i)))) {
            @compileError(std.fmt.comptimePrint("PREFILL_TYPES is out of sync with the enum, expected {s} at index {}, but found {s}", .{ @tagName(ty.kind), i, @tagName(Type.at(i)) }));
        }
    }
}

pub const Type = struct {
    kind: Kind,
    data: Data = .none,

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

        pub fn format(self: Index, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
            try writer.print("Type.Index({})", .{self.int()});
        }
    };

    pub inline fn at(index: u32) Index {
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

        pub fn format(self: Kind, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
            try writer.print("Type.Kind.{s}", .{@tagName(self)});
        }
    };

    pub const Data = union(enum) {
        none: void,
        literal: StringId,
    };

    pub fn format(self: Type, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        if (self.kind != .other_type) {
            try writer.print("{s}", .{@tagName(self.kind)});
        } else {
            try writer.print("{}", .{self.data.literal});
        }
    }
};

types: std.ArrayListUnmanaged(Type) = .empty,

pub fn getType(self: TypeMap, index: Type.Index) Type {
    if (index.int() < PREFILL_TYPES.len) {
        return PREFILL_TYPES[index.int()];
    }

    return self.types.items[index.int() - PREFILL_TYPES.len];
}

pub fn addType(self: *TypeMap, gpa: std.mem.Allocator, ty: Type) !Type.Index {
    const index = Type.at(@intCast(self.types.items.len));
    try self.types.append(gpa, ty);
    return index;
}

pub fn deinit(self: *TypeMap, gpa: std.mem.Allocator) void {
    self.types.deinit(gpa);
}
