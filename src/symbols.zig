const std = @import("std");
const Token = @import("consts.zig").Token;
const StringId = @import("string_interner.zig").StringId;
const Type = @import("types.zig").Type;

const AST = @import("ast.zig");

pub const Symbol = struct {
    kind: Kind,
    ty: Type.Index,

    pub const None = Index.none;

    pub const Kind = enum {
        value,
        type,
    };

    pub const Index = enum(u32) {
        none = std.math.maxInt(u32),
        _,

        pub inline fn int(self: Index) u32 {
            return @intFromEnum(self);
        }
    };

    pub fn at(index: anytype) Index {
        return @enumFromInt(index);
    }
};
