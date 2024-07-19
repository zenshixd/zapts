const std = @import("std");
const ATTNode = @import("att.zig").ATTNode;

pub const Symbol = struct {
    name: []const u8,
    kind: Kind,
    type: ATTNode,

    pub const Kind = enum {
        literal,
        declaration,
        identifier,
        unknown,
    };
};

pub const SymbolKey = struct {
    block_index: u8,
    name: []const u8,
};

const SymbolMapContext = struct {
    pub fn hash(self: @This(), s: SymbolKey) u64 {
        _ = self;
        return std.hash.Wyhash.hash(s.block_index, s.name);
    }
    pub fn eql(self: @This(), a: SymbolKey, b: SymbolKey) bool {
        _ = self;
        return a.block_index == b.block_index and std.mem.eql(u8, a.name, b.name);
    }
};

pub const SymbolTable = std.HashMap(SymbolKey, *Symbol, SymbolMapContext, std.hash_map.default_max_load_percentage);
