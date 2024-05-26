const std = @import("std");

pub const TypeSymbol = union(enum) {
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
    object: std.StringHashMap(TypeSymbol),
    tuple: []TypeSymbol,
    // Last one is always return type
    function: []TypeSymbol,
};

pub const ReferenceSymbol = struct {
    data_type: *TypeSymbol,
    params: ?[]TypeSymbol,
};

pub const DeclarationSymbol = struct {
    type: TypeSymbol,
    name: []const u8,
};

pub const LiteralSymbol = struct {
    type: *TypeSymbol,
    value: []const u8,
};

pub const Symbol = union(enum) {
    type: TypeSymbol,
    declaration: DeclarationSymbol,
    literal: LiteralSymbol,
};

pub const SymbolTable = std.StringHashMap(*Symbol);

pub const AnyTypeSymbol = TypeSymbol{ .any = {} };
pub const VoidTypeSymbol = TypeSymbol{ .void = {} };
pub const NumberTypeSymbol = TypeSymbol{ .number = {} };
pub const BigIntTypeSymbol = TypeSymbol{ .bigint = {} };
pub const StringTypeSymbol = TypeSymbol{ .string = {} };
pub const BooleanTypeSymbol = TypeSymbol{ .boolean = {} };
pub const NullTypeSymbol = TypeSymbol{ .null = {} };
pub const UndefinedTypeSymbol = TypeSymbol{ .undefined = {} };
pub const UnknownTypeSymbol = TypeSymbol{ .unknown = {} };
