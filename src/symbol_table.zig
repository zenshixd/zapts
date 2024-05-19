const std = @import("std");

pub const SymbolLiteralType = struct {
    type: SymbolPrimitiveType,
    value: []const u8,
};

pub const SymbolPrimitiveType = enum {
    any,
    unknown,
    number,
    bigint,
    string,
    boolean,
    null,
    undefined,
    symbol,
    never,
    object,
    void,
};

pub const SymbolEnumSetType = struct {
    name: []const u8,
    values: std.StringHashMap(*SymbolLiteralType),
};

pub const SymbolArrayType = struct {
    type: *SymbolType,
};

pub const SymbolTypesList = struct {
    types: std.ArrayList(*SymbolType),
};

pub const SymbolFunctionType = struct {
    name: []const u8,
    parameters: std.ArrayList(*Symbol),
    return_type: *SymbolType,
};

pub const SymbolObjectType = struct {
    name: []const u8,
    fields: std.ArrayList(*Symbol),
};
pub const SymbolType = union(enum) {
    literal: SymbolLiteralType,
    primitive: SymbolPrimitiveType,
    enum_set: SymbolEnumSetType,
    array: SymbolArrayType,
    tuple: SymbolTypesList,
    union_type: SymbolTypesList,
    function: SymbolFunctionType,
    object: SymbolObjectType,
};

pub const Symbol = struct {
    type: SymbolType,
    value: []const u8,
};

pub const SymbolTable = std.ArrayList(Symbol);
