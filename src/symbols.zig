const std = @import("std");

pub const TypeList = std.DoublyLinkedList(TypeSymbolData);
pub const TypeSymbol = TypeList.Node;

pub const TypeSymbolData = union(enum) {
    none: void,
    void: void,
    any: void,
    unknown: void,
    undefined: void,
    null: void,
    true: void,
    false: void,
    boolean: void,
    string: void,
    number: void,
    bigint: void,
    literal: LiteralSymbol,
    reference: ReferenceSymbol,
    object: TypeList,
    array: *TypeSymbol,
    tuple: TypeList,
    function: FunctionTypeSymbol,
    typeof: *Symbol,
    keyof: *Symbol,
    @"union": TypeList,
    intersection: TypeList,
};

pub const ReferenceSymbol = struct {
    data_type: *TypeSymbol,
    params: ?TypeList,
};

pub const DeclarationSymbol = struct {
    type: *TypeSymbol,
    name: []const u8,
};

pub const LiteralSymbol = struct {
    type: *TypeSymbol,
    value: []const u8,
};

pub const FunctionTypeSymbol = struct {
    args: TypeList,
    return_type: *TypeSymbol,
};

pub const Symbol = union(enum) {
    type: TypeSymbol,
    declaration: DeclarationSymbol,
    literal: LiteralSymbol,
};

pub const SymbolKey = struct {
    closure: u8,
    name: []const u8,
};

const SymbolMapContext = struct {
    pub fn hash(self: @This(), s: SymbolKey) u64 {
        _ = self;
        return std.hash.Wyhash.hash(s.closure, s.name);
    }
    pub fn eql(self: @This(), a: SymbolKey, b: SymbolKey) bool {
        _ = self;
        return a.closure == b.closure and std.mem.eql(u8, a.name, b.name);
    }
};

pub const SymbolTable = std.HashMap(SymbolKey, *Symbol, SymbolMapContext, std.hash_map.default_max_load_percentage);
