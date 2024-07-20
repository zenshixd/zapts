const std = @import("std");
const Symbol = @import("symbols.zig").Symbol;
const ATTNode = @import("att.zig").ATTNode;

pub const ASTNodeTag = enum {
    // data: import
    import,

    // data: export
    @"export",

    // data: nodes
    var_decl,
    // data: nodes
    const_decl,
    // data: nodes
    let_decl,

    // data: node
    abstract_class_decl,
    // data: nodes
    class_decl,

    // data: nodes
    @"if",
    // data: nodes
    @"else",

    // data: nodes
    @"switch",
    // data: nodes
    case,
    // data: node
    default,
    // data: none
    @"break",
    // data: none
    @"continue",

    // data: nodes
    @"for",
    // data: nodes
    for_classic,
    // data: nodes
    for_in,
    // data: nodes
    for_of,
    // data: none,node
    @"return",

    // data: nodes
    @"while",
    // data: nodes
    do_while,

    // data: nodes
    block,

    // data: nodes
    assignment,

    // data: function
    async_func_decl,
    func_decl,
    async_generator_func_decl,
    generator_func_decl,

    // data: binary
    async_arrow_function,
    arrow_function,

    // data: nodes
    call_expr,
    // data: nodes
    new_expr,
    // data: node
    grouping,
    // data: nodes
    comma,
    // data: binary
    ternary,
    // data: binary
    ternary_then,
    // data: nodes
    lt,
    // data: nodes
    gt,
    // data: nodes
    lte,
    // data: nodes
    gte,
    // data: nodes
    eq,
    // data: nodes
    eqq,
    // data: nodes
    neq,
    // data: nodes
    neqq,
    // data: nodes
    @"and",
    // data: nodes
    @"or",
    // data: nodes
    plus_expr,
    // data: nodes
    minus_expr,
    // data: nodes
    // data: nodes
    multiply_expr,
    // data: nodes
    exp_expr,
    // data: nodes
    div_expr,
    // data: nodes
    modulo_expr,
    // data: nodes
    bitwise_and,
    // data: nodes
    bitwise_or,
    // data: nodes
    bitwise_xor,
    // data: nodes
    bitwise_shift_left,
    // data: nodes
    bitwise_shift_right,
    // data: nodes
    bitwise_unsigned_right_shift,
    // data: nodes
    plus_assign,
    // data: nodes
    minus_assign,
    // data: nodes
    multiply_assign,
    // data: nodes
    modulo_assign,
    // data: nodes
    div_assign,
    // data: nodes
    exp_assign,
    // data: nodes
    and_assign,
    // data: nodes
    or_assign,
    // data: nodes
    bitwise_and_assign,
    // data: nodes
    bitwise_or_assign,
    // data: nodes
    bitwise_xor_assign,
    // data: nodes
    bitwise_shift_left_assign,
    // data: nodes
    bitwise_shift_right_assign,
    // data: nodes
    bitwise_unsigned_right_shift_assign,
    // data: nodes
    instanceof,
    // data: nodes
    in,
    // data: node
    plus,
    // data: node
    plusplus_pre,
    // data: node
    plusplus_post,
    // data: node
    minus,
    // data: node
    minusminus_pre,
    // data: node
    minusminus_post,
    // data: node
    not,
    // data: node
    bitwise_negate,
    // data: node
    spread,
    // data: node
    typeof,
    // data: node
    void,
    // data: node
    delete,

    // data: nodes
    object_literal,
    // data: nodes
    object_literal_field,
    // data: node
    object_literal_field_shorthand,
    // data: function
    object_method,
    // data: function
    object_async_method,
    // data: function
    object_generator_method,
    // data: function
    object_async_generator_method,
    // data: binary
    object_getter,
    // data: nodes
    object_setter,
    // data: nodes
    property_access,
    // data: nodes
    optional_property_access,
    // data: nodes
    array_literal,
    // data: nodes
    index_access,

    // data: symbol
    type_decl,
    // data: symbol
    interface_decl,
    // data: node
    declare,

    // data: literal
    this,
    true,
    false,
    null,
    undefined,
    number,
    bigint,
    string,
    identifier,
    computed_identifier,
    private_identifier,
    none,
    unknown,
};

pub const ASTNode = struct {
    tag: ASTNodeTag,
    data: Data = .{ .none = {} },

    pub const Binary = struct {
        left: ASTNode,
        right: ASTNode,
    };

    pub const Import = union(enum) {
        simple: []const u8,
        full: ImportFull,
        full_as_type: ImportFull,
    };
    pub const ImportFull = struct {
        bindings: []ImportBinding,
        path: []const u8,
    };

    pub const ImportBinding = union(enum) {
        named: []NamedBinding,
        default: []const u8,
        namespace: []const u8,
    };

    pub const Export = union(enum) {
        all: ExportAll,
        from: ExportFrom,
        default: ASTNode,
        node: ASTNode,
    };

    pub const ExportFrom = struct {
        bindings: []NamedBinding,
        path: ?[]const u8,
    };

    pub const ExportAll = struct {
        alias: ?[]const u8,
        path: []const u8,
    };

    pub const NamedBinding = struct {
        name: []const u8,
        alias: ?[]const u8,
    };

    pub const Function = struct {
        name: ?ASTNode,
        params: []ASTNode,
        body: ASTNode,
    };

    pub const Class = struct {
        name: ?[]const u8,
        super_class: ?ASTNode,
        implements: ?[]ASTNode,
        body: []ClassField,
    };

    pub const ClassField = struct {
        node: ASTNode,
        flags: std.EnumSet(ClassFieldFlag),
    };

    pub const ClassFieldFlag = enum {
        static,
        public,
        protected,
        private,
        abstract,
        readonly,
    };

    pub const Data = union(enum) {
        function: *Function,
        import: *Import,
        @"export": *Export,
        class: *Class,
        symbol: *Symbol,
        literal: []const u8,
        node: *ASTNode,
        binary: *Binary,
        nodes: []ASTNode,
        none: void,
    };

    fn repeatTab(writer: anytype, level: usize) !void {
        for (0..level) |_| {
            try writer.writeAll("\t");
        }
    }

    pub fn format(self: *const ASTNode, comptime _: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        const level = options.width orelse 1;
        try writer.writeAll("ASTNode(.");
        try writer.writeAll(@tagName(self.tag));
        //try writer.writeAll(", .type = ");
        //try writer.writeAll(@tagName(self.data_type.*));
        try writer.writeAll(", .");
        try writer.writeAll(@tagName(self.data));
        switch (self.data) {
            .nodes => |nodes| {
                try writer.writeAll(" = [\n");
                for (nodes) |node| {
                    try repeatTab(writer, level);
                    try writer.writeAll(".node = ");
                    try node.format("", .{ .width = level + 1 }, writer);
                    try writer.writeAll(",\n");
                }
                try repeatTab(writer, level - 1);
                try writer.writeAll("]");
            },
            .binary => |binary| {
                try writer.writeAll(" = {\n");
                try repeatTab(writer, level);
                try writer.writeAll(".left = ");
                try binary.left.format("", .{ .width = level + 1 }, writer);
                try writer.writeAll(",\n");
                try repeatTab(writer, level);
                try writer.writeAll(".right = ");
                try binary.right.format("", .{ .width = level + 1 }, writer);
                try writer.writeAll("\n");
                try repeatTab(writer, level - 1);
                try writer.writeAll("}");
            },
            .node => |node| {
                try writer.writeAll(" = {\n");
                try repeatTab(writer, level);
                try node.format("", .{ .width = level + 1 }, writer);
                try writer.writeAll("\n");
                try repeatTab(writer, level - 1);
                try writer.writeAll("}");
            },
            .literal => |literal| {
                try writer.writeAll(" = ");
                try writer.writeAll(literal);
            },
            .symbol => |symbol| {
                try writer.writeAll(" = ");
                try writer.writeAll(symbol.name);
            },
            .none => {
                try writer.writeAll(" = none");
            },
        }
        try writer.writeAll(")");
    }
};

pub fn main() void {
    std.debug.print("ASTNode: {d}\n", .{@sizeOf(ASTNode)});
    std.debug.print("ASTNode.Data: {d}\n", .{@sizeOf(ASTNode.Data)});
    std.debug.print("ASTNode.Binary: {d}\n", .{@sizeOf(ASTNode.Binary)});
    std.debug.print("ASTNode.Import: {d}\n", .{@sizeOf(ASTNode.Import)});
    std.debug.print("ASTNode.Function: {d}\n", .{@sizeOf(ASTNode.Function)});
}
