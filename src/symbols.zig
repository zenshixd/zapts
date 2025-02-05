const std = @import("std");
const Token = @import("consts.zig").Token;

const AST = @import("ast.zig");

pub const Symbol = struct {
    type: Type,
    source: AST.Node.Index,
    declaration: Symbol.Index,

    pub const Type = enum {
        number_literal,
        bigint_literal,
        string_literal,
        boolean_literal,
        number,
        bigint,
        string,
        boolean,
        regex,
        null,
        undefined,
        unknown,
        any,
        never,
        object,
        array,
        tuple,
        function,

        other_type,
    };

    pub const None = Index.at(0);

    pub const Index = enum(u32) {
        _,

        pub inline fn int(self: Index) u32 {
            return @intFromEnum(self);
        }
    };

    pub fn at(index: u32) Index {
        return @enumFromInt(index);
    }
};
