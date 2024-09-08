const std = @import("std");
const Token = @import("consts.zig").Token;
const assert = std.debug.assert;
const expectEqual = std.testing.expectEqual;
const expectEqualDeep = std.testing.expectEqualDeep;
const expectEqualSlices = std.testing.expectEqualSlices;

pub const Tag = enum {
    root,
    // lhs: Extra.Subrange or empty, rhs: path
    import,
    // lhs: start, rhs: end
    import_binding_named,

    // lhs: identifier, rhs: empty
    import_binding_default,
    import_binding_namespace,

    // lhs: start, rhs: end
    export_named,
    // lhs: Extra.Subrange, rhs: path
    export_from,
    // lhs: alias, rhs: path
    export_from_all,
    // lhs: node, rhs: empty
    export_default,
    export_node,

    abstract_class_decl,
    class_decl,
    class_static_block,
    class_member,
    class_field,
    class_method,

    // lhs: Subrange.start, rhs: Subrange.end
    var_decl,
    const_decl,
    let_decl,
    decl_binding,

    // lhs: Extra.If, rhs: node or empty
    @"if",

    // lhs: expr, rhs: Extra.Subrange
    @"switch",
    // lhs: start, rhs: end
    // first item is expr, second is statements inside case
    case,
    default,

    // lhs: empty, rhs: empty
    @"break",
    @"continue",

    // lhs: Extra.ForThree, rhs: node
    @"for",
    // lhs: Extra.ForTwo, rhs: node
    for_in,
    // lhs: Extra.ForTwo, rhs: node
    for_of,

    // lhs: cond, rhs: body
    @"while",
    do_while,

    // lhs: node, rhs: type or empty
    function_param,

    func_decl,
    func_expr,
    arrow_function,
    async_arrow_function,

    call_expr,
    new_expr,

    // lhs: Node.Index, rhs: Empty
    @"return",
    // lhs: Subrange.start, rhs: Subrange.end
    block,
    // lhs: identifier, rhs: value
    assignment,
    // lhs: Node.Index, rhs: Node.Empty
    grouping,
    // lhs: Node.Index, rhs: Node.Index
    comma,
    // lhs: Extra.If, rhs: Node.Index
    ternary,
    lt,
    gt,
    lte,
    gte,
    eq,
    eqq,
    neq,
    neqq,
    @"and",
    @"or",
    plus_expr,
    minus_expr,
    multiply_expr,
    exp_expr,
    div_expr,
    modulo_expr,
    bitwise_and,
    bitwise_or,
    bitwise_xor,
    bitwise_shift_left,
    bitwise_shift_right,
    bitwise_unsigned_right_shift,
    plus_assign,
    minus_assign,
    multiply_assign,
    modulo_assign,
    div_assign,
    exp_assign,
    and_assign,
    or_assign,
    bitwise_and_assign,
    bitwise_or_assign,
    bitwise_xor_assign,
    bitwise_shift_left_assign,
    bitwise_shift_right_assign,
    bitwise_unsigned_right_shift_assign,

    instanceof,
    in,
    plus,
    plusplus_pre,
    plusplus_post,
    minus,
    minusminus_pre,
    minusminus_post,
    not,
    bitwise_negate,
    spread,
    keyof,
    typeof,
    void,
    delete,

    // lhs: Subrange.start, rhs: Subrange.end
    object_literal,
    object_literal_field,
    object_literal_field_shorthand,
    object_method,

    property_access,
    optional_property_access,

    array_literal,
    index_access,

    computed_identifier,

    simple_value,

    simple_type,
    array_type,
    tuple_type,
    function_type,
    object_type,
    object_type_field,
    generic_type,
    type_intersection,
    type_union,
    type_decl,
    interface_decl,
};

pub const Raw = struct {
    tag: Tag,
    main_token: Token.Index,
    data: Data = .{},

    pub const Data = struct {
        lhs: Node.Index = 0,
        rhs: Node.Index = 0,
    };

    fn repeatTab(writer: anytype, level: usize) !void {
        for (0..level) |_| {
            try writer.writeAll("\t");
        }
    }

    pub fn format(self: *const Raw, comptime _: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
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

pub const ClassMemberFlags = struct {
    pub const none = 0;
    pub const static = 1 << 0;
    pub const readonly = 1 << 1;
    pub const abstract = 1 << 2;
    pub const public = 1 << 3;
    pub const protected = 1 << 4;
    pub const private = 1 << 5;
};

pub const FunctionFlags = struct {
    pub const None = 0;
    pub const Async = 1 << 0;
    pub const Generator = 1 << 1;
    pub const Getter = 1 << 2;
    pub const Setter = 1 << 3;
};

pub const SimpleValueKind = enum(u8) {
    this,
    identifier,
    private_identifier,
    number,
    bigint,
    string,
    boolean,
    true,
    false,
    null,
    undefined,
    unknown,
    void,
    any,
};

pub const Extra = struct {
    pub const Subrange = struct {
        start: Node.Index,
        end: Node.Index,
    };

    pub const ExportFrom = struct {
        alias: Node.Index,
        bindings_start: Node.Index,
        bindings_end: Node.Index,
    };

    pub const ClassDeclaration = struct {
        super_class: Node.Index,
        implements_start: Node.Index,
        implements_end: Node.Index,
        body_start: Node.Index,
        body_end: Node.Index,
    };

    const Declaration = struct {
        decl_type: Node.Index,
        value: Node.Index,
    };

    pub const If = struct {
        expr: Node.Index,
        body: Node.Index,
    };

    pub const ForThree = struct {
        init: Node.Index,
        cond: Node.Index,
        post: Node.Index,
    };

    pub const ForTwo = struct {
        left: Node.Index,
        right: Node.Index,
    };

    pub const Function = struct {
        flags: Node.Index,
        params_start: Node.Index,
        params_end: Node.Index,
        body: Node.Index,
        return_type: Node.Index,
    };

    pub const FunctionType = struct {
        params_start: Node.Index,
        params_end: Node.Index,
        return_type: Node.Index,
    };

    pub const Interface = struct {
        extends_start: Node.Index,
        extends_end: Node.Index,
        body_start: Node.Index,
        body_end: Node.Index,
    };
};

pub const Node = union(enum) {
    root: []Node.Index,
    import: Import,
    import_binding: ImportBinding,
    @"export": Export,

    class: ClassDeclaration,
    class_static_block: []Node.Index,
    class_member: ClassMember,
    class_field: DeclarationBinding,
    class_method: FunctionDeclaration,

    declaration: Declaration,
    decl_binding: DeclarationBinding,

    @"if": If,
    ternary_expr: If,

    @"switch": Switch,
    case: Case,

    @"for": For,
    @"while": While,
    do_while: While,
    @"break": void,
    @"continue": void,

    block: []Node.Index,

    function_param: FunctionParam,
    function_decl: FunctionDeclaration,
    function_expr: FunctionDeclaration,

    arrow_function: ArrowFunction,

    call_expr: CallExpression,
    new_expr: Node.Index,

    assignment: Binary,
    comma: Binary,
    lt: Binary,
    gt: Binary,
    lte: Binary,
    gte: Binary,
    eq: Binary,
    eqq: Binary,
    neq: Binary,
    neqq: Binary,
    @"and": Binary,
    @"or": Binary,
    plus_expr: Binary,
    minus_expr: Binary,
    multiply_expr: Binary,
    exp_expr: Binary,
    div_expr: Binary,
    modulo_expr: Binary,
    bitwise_and: Binary,
    bitwise_or: Binary,
    bitwise_xor: Binary,
    bitwise_shift_left: Binary,
    bitwise_shift_right: Binary,
    bitwise_unsigned_right_shift: Binary,
    plus_assign: Binary,
    minus_assign: Binary,
    multiply_assign: Binary,
    modulo_assign: Binary,
    div_assign: Binary,
    exp_assign: Binary,
    and_assign: Binary,
    or_assign: Binary,
    bitwise_and_assign: Binary,
    bitwise_or_assign: Binary,
    bitwise_xor_assign: Binary,
    bitwise_shift_left_assign: Binary,
    bitwise_shift_right_assign: Binary,
    bitwise_unsigned_right_shift_assign: Binary,
    instanceof: Binary,
    in: Binary,
    property_access: Binary,

    array_literal: []Node.Index,
    optional_property_access: Binary,
    index_access: Binary,

    object_literal: []Node.Index,
    object_literal_field: Binary,
    object_literal_field_shorthand: Node.Index,
    object_method: FunctionDeclaration,

    @"return": Node.Index,
    grouping: Node.Index,
    plus: Node.Index,
    plusplus_pre: Node.Index,
    plusplus_post: Node.Index,
    minus: Node.Index,
    minusminus_pre: Node.Index,
    minusminus_post: Node.Index,
    not: Node.Index,
    bitwise_negate: Node.Index,
    spread: Node.Index,
    keyof: Node.Index,
    typeof: Node.Index,
    void: Node.Index,
    delete: Node.Index,

    computed_identifier: Node.Index,
    simple_value: SimpleValue,

    simple_type: SimpleValue,
    generic_type: GenericType,
    array_type: Node.Index,
    tuple_type: []Node.Index,
    function_type: FunctionType,
    object_type: []Node.Index,
    object_type_field: ObjectTypeField,

    type_intersection: Binary,
    type_union: Binary,

    type_decl: Binary,
    interface_decl: InterfaceDecl,

    pub const Empty = 0;
    pub const Index = u32;

    pub const Import = union(enum) {
        simple: Token.Index,
        full: struct {
            bindings: []Node.Index,
            path: Token.Index,
        },
    };

    pub const ImportBinding = union(enum) {
        named: []Node.Index,
        default: Node.Index,
        namespace: Node.Index,
    };

    pub const Export = union(enum) {
        from_all: ExportAll,
        from: struct {
            bindings: []Node.Index,
            path: Token.Index,
        },
        named: []Node.Index,
        default: Node.Index,
        node: Node.Index,
    };

    pub const ExportAll = struct {
        alias: Token.Index,
        path: Token.Index,
    };

    pub const ClassDeclaration = struct {
        abstract: bool,
        name: Token.Index,
        super_class: Node.Index,
        implements: []Token.Index,
        body: []Node.Index,
    };

    pub const ClassMember = struct {
        flags: u8,
        node: Node.Index,
    };

    pub const DeclarationKind = enum {
        @"var",
        @"const",
        let,

        pub fn name(self: DeclarationKind) []const u8 {
            return switch (self) {
                .@"var" => "var",
                .@"const" => "const",
                .let => "let",
            };
        }
    };

    pub const Declaration = struct {
        kind: DeclarationKind,
        list: []Node.Index,
    };

    pub const DeclarationBinding = struct {
        name: Token.Index,
        decl_type: Node.Index,
        value: Node.Index,
    };

    pub const If = struct {
        expr: Node.Index,
        body: Node.Index,
        @"else": Node.Index,
    };

    pub const Switch = struct {
        expr: Node.Index,
        cases: []Node.Index,
    };

    pub const Case = union(enum) {
        default: []Node.Index,
        case: struct {
            expr: Node.Index,
            body: []Node.Index,
        },
    };

    pub const For = union(enum) {
        classic: struct {
            init: Node.Index,
            cond: Node.Index,
            post: Node.Index,
            body: Node.Index,
        },
        in: struct {
            left: Node.Index,
            right: Node.Index,
            body: Node.Index,
        },
        of: struct {
            left: Node.Index,
            right: Node.Index,
            body: Node.Index,
        },
    };

    pub const While = struct {
        cond: Node.Index,
        body: Node.Index,
    };

    pub const Binary = struct {
        left: Node.Index,
        right: Node.Index,
    };

    pub const FunctionParam = struct {
        node: Token.Index,
        type: Node.Index,
    };

    pub const FunctionDeclaration = struct {
        flags: u4,
        name: Token.Index,
        params: []Node.Index,
        body: Node.Index,
        return_type: Node.Index,
    };

    pub const FunctionType = struct {
        name: Token.Index,
        params: []Node.Index,
        return_type: Node.Index,
    };

    pub const ArrowFunction = struct {
        type: enum {
            arrow,
            async_arrow,
        },
        params: []Node.Index,
        body: Node.Index,
        return_type: Node.Index,
    };

    pub const CallExpression = struct {
        node: Node.Index,
        params: []Node.Index,
    };

    pub const SimpleValue = struct {
        kind: SimpleValueKind,
    };

    pub const ObjectTypeField = struct {
        name: Node.Index,
        type: Node.Index,
    };

    pub const GenericType = struct {
        name: Token.Index,
        params: []Node.Index,
    };

    pub const InterfaceDecl = struct {
        name: Token.Index,
        extends: []Token.Index,
        body: []Node.Index,
    };
};

pub const Pool = struct {
    nodes: std.ArrayList(Raw),
    extra: std.ArrayList(Node.Index),

    pub fn init(gpa: std.mem.Allocator) Pool {
        var pool = .{
            .nodes = std.ArrayList(Raw).init(gpa),
            .extra = std.ArrayList(Node.Index).init(gpa),
        };

        pool.nodes.append(.{
            .tag = .root,
            .main_token = 0,
            .data = .{},
        }) catch @panic("couldnt init AST.Pool with root node. OOM?");

        return pool;
    }

    pub fn deinit(self: *Pool) void {
        self.nodes.deinit();
        self.extra.deinit();
    }

    pub fn addNode(self: *Pool, main_token: Token.Index, key: Node) !Node.Index {
        switch (key) {
            .root => |root| {
                const subrange = try self.listToSubrange(root);
                return try self.addRawNode(.{
                    .tag = .root,
                    .main_token = main_token,
                    .data = .{ .lhs = subrange.start, .rhs = subrange.end },
                });
            },
            .import => |import| {
                switch (import) {
                    .simple => |simple| {
                        return try self.addRawNode(.{
                            .tag = .import,
                            .main_token = main_token,
                            .data = .{ .rhs = simple },
                        });
                    },
                    .full => |full| {
                        const span = try self.listToSubrange(full.bindings);
                        return try self.addRawNode(.{
                            .tag = .import,
                            .main_token = main_token,
                            .data = .{
                                .lhs = try self.addExtra(span),
                                .rhs = full.path,
                            },
                        });
                    },
                }
            },
            .import_binding => |import_binding| {
                switch (import_binding) {
                    .named => |named| {
                        const span = try self.listToSubrange(named);
                        return try self.addRawNode(.{
                            .tag = .import_binding_named,
                            .main_token = main_token,
                            .data = .{
                                .lhs = span.start,
                                .rhs = span.end,
                            },
                        });
                    },
                    .default => |default| {
                        return try self.addRawNode(.{
                            .tag = .import_binding_default,
                            .main_token = main_token,
                            .data = .{ .lhs = default },
                        });
                    },
                    .namespace => |namespace| {
                        return try self.addRawNode(.{
                            .tag = .import_binding_namespace,
                            .main_token = main_token,
                            .data = .{ .lhs = namespace },
                        });
                    },
                }
            },
            .@"export" => |@"export"| {
                switch (@"export") {
                    .named => |named| {
                        const span = try self.listToSubrange(named);
                        return try self.addRawNode(.{
                            .tag = .export_named,
                            .main_token = main_token,
                            .data = .{
                                .lhs = span.start,
                                .rhs = span.end,
                            },
                        });
                    },
                    .from => |from| {
                        const span = try self.listToSubrange(from.bindings);
                        return try self.addRawNode(.{
                            .tag = .export_from,
                            .main_token = main_token,
                            .data = .{
                                .lhs = try self.addExtra(span),
                                .rhs = from.path,
                            },
                        });
                    },
                    .from_all => |from| {
                        return try self.addRawNode(.{
                            .tag = .export_from_all,
                            .main_token = main_token,
                            .data = .{
                                .lhs = from.alias,
                                .rhs = from.path,
                            },
                        });
                    },
                    .default => |default| {
                        return try self.addRawNode(.{
                            .tag = .export_default,
                            .main_token = main_token,
                            .data = .{ .lhs = default },
                        });
                    },
                    .node => |node| {
                        return try self.addRawNode(.{
                            .tag = .export_node,
                            .main_token = main_token,
                            .data = .{ .lhs = node },
                        });
                    },
                }
            },
            .class => |class| {
                const implements_span = try self.listToSubrange(class.implements);
                const subrange = try self.listToSubrange(class.body);
                return try self.addRawNode(.{
                    .tag = if (class.abstract) .abstract_class_decl else .class_decl,
                    .main_token = main_token,
                    .data = .{
                        .lhs = class.name,
                        .rhs = try self.addExtra(Extra.ClassDeclaration{
                            .super_class = class.super_class,
                            .implements_start = implements_span.start,
                            .implements_end = implements_span.end,
                            .body_start = subrange.start,
                            .body_end = subrange.end,
                        }),
                    },
                });
            },
            .class_static_block => |static_block| {
                const subrange = try self.listToSubrange(static_block);
                return try self.addRawNode(.{
                    .tag = .class_static_block,
                    .main_token = main_token,
                    .data = .{
                        .lhs = subrange.start,
                        .rhs = subrange.end,
                    },
                });
            },
            .class_member => |member| {
                return try self.addRawNode(.{
                    .tag = .class_member,
                    .main_token = main_token,
                    .data = .{
                        .lhs = member.flags,
                        .rhs = member.node,
                    },
                });
            },
            .class_field => |field| {
                const binding = try self.addExtra(Extra.Declaration{
                    .decl_type = field.decl_type,
                    .value = field.value,
                });
                return try self.addRawNode(.{
                    .tag = .class_field,
                    .main_token = main_token,
                    .data = .{
                        .lhs = field.name,
                        .rhs = binding,
                    },
                });
            },
            .declaration => |declaration| {
                const tag: Tag = switch (declaration.kind) {
                    .let => .let_decl,
                    .@"var" => .var_decl,
                    .@"const" => .const_decl,
                };
                const subrange = try self.listToSubrange(declaration.list);
                return try self.addRawNode(.{
                    .tag = tag,
                    .main_token = main_token,
                    .data = .{
                        .lhs = subrange.start,
                        .rhs = subrange.end,
                    },
                });
            },
            .decl_binding => |declaration| {
                return self.addRawNode(.{
                    .tag = .decl_binding,
                    .main_token = main_token,
                    .data = .{
                        .lhs = declaration.name,
                        .rhs = try self.addExtra(Extra.Declaration{
                            .decl_type = declaration.decl_type,
                            .value = declaration.value,
                        }),
                    },
                });
            },
            .@"if", .ternary_expr => |if_node| {
                return try self.addRawNode(.{
                    .tag = if (key == .@"if") .@"if" else .ternary,
                    .main_token = main_token,
                    .data = .{
                        .lhs = try self.addExtra(Extra.If{
                            .expr = if_node.expr,
                            .body = if_node.body,
                        }),
                        .rhs = if_node.@"else",
                    },
                });
            },
            .@"switch" => |switch_node| {
                const cases = try self.listToSubrange(switch_node.cases);
                return try self.addRawNode(.{
                    .tag = .@"switch",
                    .main_token = main_token,
                    .data = .{
                        .lhs = switch_node.expr,
                        .rhs = try self.addExtra(cases),
                    },
                });
            },
            .case => |case_key| {
                switch (case_key) {
                    .default => |default_node| {
                        const stmts = try self.listToSubrange(default_node);
                        return try self.addRawNode(.{
                            .tag = .default,
                            .main_token = main_token,
                            .data = .{
                                .lhs = stmts.start,
                                .rhs = stmts.end,
                            },
                        });
                    },
                    .case => |case_node| {
                        const stmts = try self.listToSubrange(case_node.body);
                        return try self.addRawNode(.{
                            .tag = .case,
                            .main_token = main_token,
                            .data = .{
                                .lhs = case_node.expr,
                                .rhs = try self.addExtra(stmts),
                            },
                        });
                    },
                }
            },
            .@"for" => |for_node| {
                switch (for_node) {
                    .classic => |classic| {
                        return try self.addRawNode(.{
                            .tag = .@"for",
                            .main_token = main_token,
                            .data = .{
                                .lhs = try self.addExtra(Extra.ForThree{
                                    .init = classic.init,
                                    .cond = classic.cond,
                                    .post = classic.post,
                                }),
                                .rhs = classic.body,
                            },
                        });
                    },
                    .in => |in| {
                        return try self.addRawNode(.{
                            .tag = .for_in,
                            .main_token = main_token,
                            .data = .{
                                .lhs = try self.addExtra(Extra.ForTwo{
                                    .left = in.left,
                                    .right = in.right,
                                }),
                                .rhs = in.body,
                            },
                        });
                    },
                    .of => |of| {
                        return try self.addRawNode(.{
                            .tag = .for_of,
                            .main_token = main_token,
                            .data = .{
                                .lhs = try self.addExtra(Extra.ForTwo{
                                    .left = of.left,
                                    .right = of.right,
                                }),
                                .rhs = of.body,
                            },
                        });
                    },
                }
            },
            .@"while", .do_while => |while_node| {
                return try self.addRawNode(.{
                    .tag = if (key == .@"while") .@"while" else .do_while,
                    .main_token = main_token,
                    .data = .{
                        .lhs = while_node.cond,
                        .rhs = while_node.body,
                    },
                });
            },
            .block, .array_literal, .object_literal => |nodes| {
                const subrange = try self.listToSubrange(nodes);
                return try self.addRawNode(.{
                    .tag = switch (key) {
                        .block => .block,
                        .array_literal => .array_literal,
                        .object_literal => .object_literal,
                        else => unreachable,
                    },
                    .main_token = main_token,
                    .data = .{ .lhs = subrange.start, .rhs = subrange.end },
                });
            },
            .function_param => |param| {
                return try self.addRawNode(.{
                    .tag = .function_param,
                    .main_token = main_token,
                    .data = .{ .lhs = param.node, .rhs = param.type },
                });
            },
            .function_decl, .function_expr, .class_method, .object_method => |func_decl| {
                const tag: Tag = switch (key) {
                    .function_decl => .func_decl,
                    .function_expr => .func_expr,
                    .class_method => .class_method,
                    .object_method => .object_method,
                    else => unreachable,
                };
                const subrange = try self.listToSubrange(func_decl.params);
                return try self.addRawNode(.{
                    .tag = tag,
                    .main_token = main_token,
                    .data = .{
                        .lhs = func_decl.name,
                        .rhs = try self.addExtra(Extra.Function{
                            .flags = func_decl.flags,
                            .params_start = subrange.start,
                            .params_end = subrange.end,
                            .body = func_decl.body,
                            .return_type = func_decl.return_type,
                        }),
                    },
                });
            },
            .arrow_function => |arrow_func| {
                const subrange = try self.listToSubrange(arrow_func.params);
                return try self.addRawNode(.{
                    .tag = if (arrow_func.type == .async_arrow) .async_arrow_function else .arrow_function,
                    .main_token = main_token,
                    .data = .{
                        .lhs = try self.addExtra(Extra.FunctionType{
                            .params_start = subrange.start,
                            .params_end = subrange.end,
                            .return_type = arrow_func.return_type,
                        }),
                        .rhs = arrow_func.body,
                    },
                });
            },
            .call_expr => |expr| {
                const subrange = try self.listToSubrange(expr.params);
                return try self.addRawNode(.{
                    .tag = .call_expr,
                    .main_token = main_token,
                    .data = .{
                        .lhs = expr.node,
                        .rhs = try self.addExtra(subrange),
                    },
                });
            },
            .object_type, .tuple_type => |obj_type| {
                const subrange = try self.listToSubrange(obj_type);
                return self.addRawNode(.{
                    .tag = if (key == .object_type) .object_type else .tuple_type,
                    .main_token = main_token,
                    .data = .{
                        .lhs = subrange.start,
                        .rhs = subrange.end,
                    },
                });
            },
            .function_type => |func_type| {
                const params_subrange = try self.listToSubrange(func_type.params);
                const extra = try self.addExtra(Extra.FunctionType{
                    .params_start = params_subrange.start,
                    .params_end = params_subrange.end,
                    .return_type = func_type.return_type,
                });
                return self.addRawNode(.{
                    .tag = .function_type,
                    .main_token = main_token,
                    .data = .{
                        .lhs = func_type.name,
                        .rhs = extra,
                    },
                });
            },

            .assignment,
            .comma,
            .lt,
            .gt,
            .lte,
            .gte,
            .eq,
            .eqq,
            .neq,
            .neqq,
            .@"and",
            .@"or",
            .plus_expr,
            .minus_expr,
            .multiply_expr,
            .exp_expr,
            .div_expr,
            .modulo_expr,
            .bitwise_and,
            .bitwise_or,
            .bitwise_xor,
            .bitwise_shift_left,
            .bitwise_shift_right,
            .bitwise_unsigned_right_shift,
            .plus_assign,
            .minus_assign,
            .multiply_assign,
            .modulo_assign,
            .div_assign,
            .exp_assign,
            .and_assign,
            .or_assign,
            .bitwise_and_assign,
            .bitwise_or_assign,
            .bitwise_xor_assign,
            .bitwise_shift_left_assign,
            .bitwise_shift_right_assign,
            .bitwise_unsigned_right_shift_assign,
            .instanceof,
            .in,
            .object_literal_field,
            .property_access,
            .optional_property_access,
            .index_access,
            .type_intersection,
            .type_union,
            .type_decl,
            => |binary| {
                const tag: Tag = switch (key) {
                    .assignment => .assignment,
                    .comma => .comma,
                    .lt => .lt,
                    .gt => .gt,
                    .lte => .lte,
                    .gte => .gte,
                    .eq => .eq,
                    .eqq => .eqq,
                    .neq => .neq,
                    .neqq => .neqq,
                    .@"and" => .@"and",
                    .@"or" => .@"or",
                    .plus_expr => .plus_expr,
                    .minus_expr => .minus_expr,
                    .multiply_expr => .multiply_expr,
                    .exp_expr => .exp_expr,
                    .div_expr => .div_expr,
                    .modulo_expr => .modulo_expr,
                    .bitwise_and => .bitwise_and,
                    .bitwise_or => .bitwise_or,
                    .bitwise_xor => .bitwise_xor,
                    .bitwise_shift_left => .bitwise_shift_left,
                    .bitwise_shift_right => .bitwise_shift_right,
                    .bitwise_unsigned_right_shift => .bitwise_unsigned_right_shift,
                    .plus_assign => .plus_assign,
                    .minus_assign => .minus_assign,
                    .multiply_assign => .multiply_assign,
                    .modulo_assign => .modulo_assign,
                    .div_assign => .div_assign,
                    .exp_assign => .exp_assign,
                    .and_assign => .and_assign,
                    .or_assign => .or_assign,
                    .bitwise_and_assign => .bitwise_and_assign,
                    .bitwise_or_assign => .bitwise_or_assign,
                    .bitwise_xor_assign => .bitwise_xor_assign,
                    .bitwise_shift_left_assign => .bitwise_shift_left_assign,
                    .bitwise_shift_right_assign => .bitwise_shift_right_assign,
                    .bitwise_unsigned_right_shift_assign => .bitwise_unsigned_right_shift_assign,
                    .instanceof => .instanceof,
                    .in => .in,
                    .object_literal_field => .object_literal_field,
                    .property_access => .property_access,
                    .optional_property_access => .optional_property_access,
                    .index_access => .index_access,
                    .type_intersection => .type_intersection,
                    .type_union => .type_union,
                    .type_decl => .type_decl,
                    else => unreachable,
                };
                return try self.addRawNode(.{
                    .tag = tag,
                    .main_token = main_token,
                    .data = .{
                        .lhs = binary.left,
                        .rhs = binary.right,
                    },
                });
            },

            .@"return",
            .new_expr,
            .grouping,
            .plus,
            .plusplus_pre,
            .plusplus_post,
            .minus,
            .minusminus_pre,
            .minusminus_post,
            .not,
            .bitwise_negate,
            .spread,
            .typeof,
            .keyof,
            .void,
            .delete,
            .computed_identifier,
            .object_literal_field_shorthand,
            .array_type,
            => |node| {
                const tag: Tag = switch (key) {
                    .@"return" => .@"return",
                    .new_expr => .new_expr,
                    .grouping => .grouping,
                    .plus => .plus,
                    .plusplus_pre => .plusplus_pre,
                    .plusplus_post => .plusplus_post,
                    .minus => .minus,
                    .minusminus_pre => .minusminus_pre,
                    .minusminus_post => .minusminus_post,
                    .not => .not,
                    .bitwise_negate => .bitwise_negate,
                    .spread => .spread,
                    .typeof => .typeof,
                    .keyof => .keyof,
                    .void => .void,
                    .delete => .delete,
                    .computed_identifier => .computed_identifier,
                    .object_literal_field_shorthand => .object_literal_field_shorthand,
                    .array_type => .array_type,
                    else => unreachable,
                };
                return try self.addRawNode(.{
                    .tag = tag,
                    .main_token = main_token,
                    .data = .{ .lhs = node },
                });
            },

            .@"break",
            .@"continue",
            => {
                const tag: Tag = switch (key) {
                    .@"break" => .@"break",
                    .@"continue" => .@"continue",
                    else => unreachable,
                };
                return try self.addRawNode(.{
                    .tag = tag,
                    .main_token = main_token,
                    .data = .{},
                });
            },
            .simple_value, .simple_type => |simple_value| {
                return self.addRawNode(.{
                    .tag = if (key == .simple_value) .simple_value else .simple_type,
                    .main_token = main_token,
                    .data = .{ .lhs = @intFromEnum(simple_value.kind) },
                });
            },
            .object_type_field => |obj_field_type| {
                return self.addRawNode(.{
                    .tag = .object_type_field,
                    .main_token = main_token,
                    .data = .{ .lhs = obj_field_type.name, .rhs = obj_field_type.type },
                });
            },
            .generic_type => |generic_type| {
                const span = try self.listToSubrange(generic_type.params);
                return self.addRawNode(.{
                    .tag = .generic_type,
                    .main_token = main_token,
                    .data = .{
                        .lhs = generic_type.name,
                        .rhs = try self.addExtra(span),
                    },
                });
            },
            .interface_decl => |interface_decl| {
                const extends_span = try self.listToSubrange(interface_decl.extends);
                const body_span = try self.listToSubrange(interface_decl.body);
                return self.addRawNode(.{
                    .tag = .interface_decl,
                    .main_token = main_token,
                    .data = .{
                        .lhs = interface_decl.name,
                        .rhs = try self.addExtra(Extra.Interface{
                            .extends_start = extends_span.start,
                            .extends_end = extends_span.end,
                            .body_start = body_span.start,
                            .body_end = body_span.end,
                        }),
                    },
                });
            },
        }
    }

    pub fn getNode(self: *Pool, index: Node.Index) Node {
        const node = self.nodes.items[index];

        switch (node.tag) {
            .root => {
                return .{
                    .root = self.extra.items[node.data.lhs..node.data.rhs],
                };
            },
            .import => {
                if (node.data.lhs == Node.Empty) {
                    return .{
                        .import = .{
                            .simple = node.data.rhs,
                        },
                    };
                }

                const subrange = self.getExtra(Extra.Subrange, node.data.lhs);
                return .{
                    .import = .{ .full = .{
                        .bindings = self.extra.items[subrange.start..subrange.end],
                        .path = node.data.rhs,
                    } },
                };
            },
            .import_binding_named => {
                return .{
                    .import_binding = .{
                        .named = self.extra.items[node.data.lhs..node.data.rhs],
                    },
                };
            },
            .import_binding_default => {
                return .{
                    .import_binding = .{
                        .default = node.data.lhs,
                    },
                };
            },
            .import_binding_namespace => {
                return .{
                    .import_binding = .{
                        .namespace = node.data.lhs,
                    },
                };
            },
            .export_named => {
                return .{
                    .@"export" = .{
                        .named = self.extra.items[node.data.lhs..node.data.rhs],
                    },
                };
            },
            .export_from => {
                const span = self.getExtra(Extra.Subrange, node.data.lhs);
                return .{
                    .@"export" = .{
                        .from = .{
                            .bindings = self.extra.items[span.start..span.end],
                            .path = node.data.rhs,
                        },
                    },
                };
            },
            .export_from_all => {
                return .{
                    .@"export" = .{
                        .from_all = .{
                            .alias = node.data.lhs,
                            .path = node.data.rhs,
                        },
                    },
                };
            },
            .export_default => {
                return .{
                    .@"export" = .{
                        .default = node.data.lhs,
                    },
                };
            },
            .export_node => {
                return .{
                    .@"export" = .{
                        .node = node.data.lhs,
                    },
                };
            },
            .abstract_class_decl, .class_decl => {
                const class = self.getExtra(Extra.ClassDeclaration, node.data.rhs);
                return .{
                    .class = .{
                        .abstract = node.tag == .abstract_class_decl,
                        .name = node.data.lhs,
                        .super_class = class.super_class,
                        .implements = self.extra.items[class.implements_start..class.implements_end],
                        .body = self.extra.items[class.body_start..class.body_end],
                    },
                };
            },
            .class_member => {
                return .{
                    .class_member = .{
                        .flags = @intCast(node.data.lhs),
                        .node = node.data.rhs,
                    },
                };
            },
            .class_field => {
                const field = self.getExtra(Extra.Declaration, node.data.rhs);
                return .{
                    .class_field = .{
                        .name = node.data.lhs,
                        .decl_type = field.decl_type,
                        .value = field.value,
                    },
                };
            },
            .var_decl, .const_decl, .let_decl => {
                return .{
                    .declaration = .{
                        .kind = switch (node.tag) {
                            .var_decl => .@"var",
                            .const_decl => .@"const",
                            .let_decl => .let,
                            else => unreachable,
                        },
                        .list = self.extra.items[node.data.lhs..node.data.rhs],
                    },
                };
            },
            .decl_binding => {
                const extra = self.getExtra(Extra.Declaration, node.data.rhs);
                return .{
                    .decl_binding = .{
                        .name = node.data.lhs,
                        .decl_type = extra.decl_type,
                        .value = extra.value,
                    },
                };
            },
            .@"if", .ternary => {
                const if_extra = self.getExtra(Extra.If, node.data.lhs);
                const data = .{
                    .expr = if_extra.expr,
                    .body = if_extra.body,
                    .@"else" = node.data.rhs,
                };
                return switch (node.tag) {
                    .@"if" => .{ .@"if" = data },
                    .ternary => .{ .ternary_expr = data },
                    else => unreachable,
                };
            },
            .@"switch" => {
                const subrange = self.getExtra(Extra.Subrange, node.data.rhs);
                return .{
                    .@"switch" = .{
                        .expr = node.data.lhs,
                        .cases = self.extra.items[subrange.start..subrange.end],
                    },
                };
            },
            .case => {
                const expr = node.data.lhs;
                const subrange = self.getExtra(Extra.Subrange, node.data.rhs);
                return .{
                    .case = .{
                        .case = .{
                            .expr = expr,
                            .body = self.extra.items[subrange.start..subrange.end],
                        },
                    },
                };
            },
            .default => {
                return .{
                    .case = .{
                        .default = self.extra.items[node.data.lhs..node.data.rhs],
                    },
                };
            },
            .@"for" => {
                const for_extra = self.getExtra(Extra.ForThree, node.data.lhs);
                return Node{
                    .@"for" = .{
                        .classic = .{
                            .init = for_extra.init,
                            .cond = for_extra.cond,
                            .post = for_extra.post,
                            .body = node.data.rhs,
                        },
                    },
                };
            },
            .for_in => {
                const for_extra = self.getExtra(Extra.ForTwo, node.data.lhs);
                return .{
                    .@"for" = .{
                        .in = .{
                            .left = for_extra.left,
                            .right = for_extra.right,
                            .body = node.data.rhs,
                        },
                    },
                };
            },
            .for_of => {
                const for_extra = self.getExtra(Extra.ForTwo, node.data.lhs);
                return .{
                    .@"for" = .{
                        .of = .{
                            .left = for_extra.left,
                            .right = for_extra.right,
                            .body = node.data.rhs,
                        },
                    },
                };
            },
            .@"while" => {
                return .{
                    .@"while" = .{
                        .cond = node.data.lhs,
                        .body = node.data.rhs,
                    },
                };
            },
            .do_while => {
                return .{
                    .do_while = .{
                        .cond = node.data.lhs,
                        .body = node.data.rhs,
                    },
                };
            },
            .function_param => {
                return .{
                    .function_param = .{
                        .node = node.data.lhs,
                        .type = node.data.rhs,
                    },
                };
            },
            .func_decl,
            .func_expr,
            .class_method,
            .object_method,
            => {
                const extra = self.getExtra(Extra.Function, node.data.rhs);
                const decl: Node.FunctionDeclaration = .{
                    .flags = @truncate(extra.flags),
                    .name = node.data.lhs,
                    .params = self.extra.items[extra.params_start..extra.params_end],
                    .body = extra.body,
                    .return_type = extra.return_type,
                };
                return switch (node.tag) {
                    .func_decl => .{ .function_decl = decl },
                    .func_expr => .{ .function_expr = decl },
                    .class_method => .{ .class_method = decl },
                    .object_method => .{ .object_method = decl },
                    else => unreachable,
                };
            },
            .async_arrow_function, .arrow_function => {
                const extra = self.getExtra(Extra.FunctionType, node.data.lhs);
                return Node{
                    .arrow_function = .{
                        .type = switch (node.tag) {
                            .async_arrow_function => .async_arrow,
                            .arrow_function => .arrow,
                            else => unreachable,
                        },
                        .params = self.extra.items[extra.params_start..extra.params_end],
                        .body = node.data.rhs,
                        .return_type = extra.return_type,
                    },
                };
            },
            .call_expr => {
                const extra = self.getExtra(Extra.Subrange, node.data.rhs);
                const data = .{
                    .node = node.data.lhs,
                    .params = self.extra.items[extra.start..extra.end],
                };
                return .{ .call_expr = data };
            },
            .block, .array_literal, .object_literal, .class_static_block => {
                const nodes = self.extra.items[node.data.lhs..node.data.rhs];
                return switch (node.tag) {
                    .block => .{ .block = nodes },
                    .array_literal => .{ .array_literal = nodes },
                    .object_literal => .{ .object_literal = nodes },
                    .class_static_block => .{ .class_static_block = nodes },
                    else => unreachable,
                };
            },
            .comma,
            .assignment,
            .lt,
            .gt,
            .lte,
            .gte,
            .eq,
            .eqq,
            .neq,
            .neqq,
            .@"and",
            .@"or",
            .plus_expr,
            .minus_expr,
            .multiply_expr,
            .exp_expr,
            .div_expr,
            .modulo_expr,
            .bitwise_and,
            .bitwise_or,
            .bitwise_xor,
            .bitwise_shift_left,
            .bitwise_shift_right,
            .bitwise_unsigned_right_shift,
            .plus_assign,
            .minus_assign,
            .multiply_assign,
            .modulo_assign,
            .div_assign,
            .exp_assign,
            .and_assign,
            .or_assign,
            .bitwise_and_assign,
            .bitwise_or_assign,
            .bitwise_xor_assign,
            .bitwise_shift_left_assign,
            .bitwise_shift_right_assign,
            .bitwise_unsigned_right_shift_assign,
            .instanceof,
            .in,
            .object_literal_field,
            .property_access,
            .optional_property_access,
            .index_access,
            .type_intersection,
            .type_union,
            .type_decl,
            => {
                const data = Node.Binary{
                    .left = node.data.lhs,
                    .right = node.data.rhs,
                };
                return switch (node.tag) {
                    .comma => .{ .comma = data },
                    .assignment => .{ .assignment = data },
                    .lt => .{ .lt = data },
                    .gt => .{ .gt = data },
                    .lte => .{ .lte = data },
                    .gte => .{ .gte = data },
                    .eq => .{ .eq = data },
                    .eqq => .{ .eqq = data },
                    .neq => .{ .neq = data },
                    .neqq => .{ .neqq = data },
                    .@"and" => .{ .@"and" = data },
                    .@"or" => .{ .@"or" = data },
                    .plus_expr => .{ .plus_expr = data },
                    .minus_expr => .{ .minus_expr = data },
                    .multiply_expr => .{ .multiply_expr = data },
                    .exp_expr => .{ .exp_expr = data },
                    .div_expr => .{ .div_expr = data },
                    .modulo_expr => .{ .modulo_expr = data },
                    .bitwise_and => .{ .bitwise_and = data },
                    .bitwise_or => .{ .bitwise_or = data },
                    .bitwise_xor => .{ .bitwise_xor = data },
                    .bitwise_shift_left => .{ .bitwise_shift_left = data },
                    .bitwise_shift_right => .{ .bitwise_shift_right = data },
                    .bitwise_unsigned_right_shift => .{ .bitwise_unsigned_right_shift = data },
                    .plus_assign => .{ .plus_assign = data },
                    .minus_assign => .{ .minus_assign = data },
                    .multiply_assign => .{ .multiply_assign = data },
                    .modulo_assign => .{ .modulo_assign = data },
                    .div_assign => .{ .div_assign = data },
                    .exp_assign => .{ .exp_assign = data },
                    .and_assign => .{ .and_assign = data },
                    .or_assign => .{ .or_assign = data },
                    .bitwise_and_assign => .{ .bitwise_and_assign = data },
                    .bitwise_or_assign => .{ .bitwise_or_assign = data },
                    .bitwise_xor_assign => .{ .bitwise_xor_assign = data },
                    .bitwise_shift_left_assign => .{ .bitwise_shift_left_assign = data },
                    .bitwise_shift_right_assign => .{ .bitwise_shift_right_assign = data },
                    .bitwise_unsigned_right_shift_assign => .{ .bitwise_unsigned_right_shift_assign = data },
                    .instanceof => .{ .instanceof = data },
                    .in => .{ .in = data },
                    .object_literal_field => .{ .object_literal_field = data },
                    .property_access => .{ .property_access = data },
                    .optional_property_access => .{ .optional_property_access = data },
                    .index_access => .{ .index_access = data },
                    .type_intersection => .{ .type_intersection = data },
                    .type_union => .{ .type_union = data },
                    .type_decl => .{ .type_decl = data },
                    else => unreachable,
                };
            },

            .@"return",
            .new_expr,
            .grouping,
            .plus,
            .plusplus_pre,
            .plusplus_post,
            .minus,
            .minusminus_pre,
            .minusminus_post,
            .not,
            .bitwise_negate,
            .spread,
            .typeof,
            .keyof,
            .void,
            .delete,
            .computed_identifier,
            .object_literal_field_shorthand,
            .array_type,
            => {
                return switch (node.tag) {
                    .@"return" => .{ .@"return" = node.data.lhs },
                    .new_expr => .{ .new_expr = node.data.lhs },
                    .grouping => .{ .grouping = node.data.lhs },
                    .plus => .{ .plus = node.data.lhs },
                    .plusplus_pre => .{ .plusplus_pre = node.data.lhs },
                    .plusplus_post => .{ .plusplus_post = node.data.lhs },
                    .minus => .{ .minus = node.data.lhs },
                    .minusminus_pre => .{ .minusminus_pre = node.data.lhs },
                    .minusminus_post => .{ .minusminus_post = node.data.lhs },
                    .not => .{ .not = node.data.lhs },
                    .bitwise_negate => .{ .bitwise_negate = node.data.lhs },
                    .spread => .{ .spread = node.data.lhs },
                    .typeof => .{ .typeof = node.data.lhs },
                    .keyof => .{ .keyof = node.data.lhs },
                    .void => .{ .void = node.data.lhs },
                    .delete => .{ .delete = node.data.lhs },
                    .computed_identifier => .{ .computed_identifier = node.data.lhs },
                    .object_literal_field_shorthand => .{ .object_literal_field_shorthand = node.data.lhs },
                    .array_type => .{ .array_type = node.data.lhs },
                    else => unreachable,
                };
            },

            .@"break",
            .@"continue",
            => {
                return switch (node.tag) {
                    .@"break" => .{ .@"break" = {} },
                    .@"continue" => .{ .@"continue" = {} },
                    else => unreachable,
                };
            },

            .simple_type, .simple_value => {
                const data = Node.SimpleValue{
                    .kind = @enumFromInt(node.data.lhs),
                };
                return switch (node.tag) {
                    .simple_type => .{ .simple_type = data },
                    .simple_value => .{ .simple_value = data },
                    else => unreachable,
                };
            },

            .function_type => {
                const extra = self.getExtra(Extra.FunctionType, node.data.rhs);
                return .{ .function_type = .{
                    .name = node.data.lhs,
                    .params = self.extra.items[extra.params_start..extra.params_end],
                    .return_type = extra.return_type,
                } };
            },

            .object_type, .tuple_type => {
                return switch (node.tag) {
                    .object_type => .{ .object_type = self.extra.items[node.data.lhs..node.data.rhs] },
                    .tuple_type => .{ .tuple_type = self.extra.items[node.data.lhs..node.data.rhs] },
                    else => unreachable,
                };
            },

            .object_type_field => {
                return .{ .object_type_field = .{
                    .name = node.data.lhs,
                    .type = node.data.rhs,
                } };
            },

            .generic_type => {
                const span = self.getExtra(Extra.Subrange, node.data.rhs);
                return .{ .generic_type = .{
                    .name = node.data.lhs,
                    .params = self.extra.items[span.start..span.end],
                } };
            },

            .interface_decl => {
                const interface = self.getExtra(Extra.Interface, node.data.rhs);
                return .{
                    .interface_decl = .{
                        .name = node.data.lhs,
                        .extends = self.extra.items[interface.extends_start..interface.extends_end],
                        .body = self.extra.items[interface.body_start..interface.body_end],
                    },
                };
            },
        }
    }

    pub fn getRawNode(self: *Pool, index: Node.Index) Raw {
        return self.nodes.items[index];
    }

    pub fn addRawNode(self: *Pool, node: Raw) !Node.Index {
        const index = self.nodes.items.len;
        try self.nodes.append(node);
        return @intCast(index);
    }

    pub fn getExtra(self: *Pool, ty: type, index: Node.Index) ty {
        const fields = std.meta.fields(ty);
        var result: [fields.len]Node.Index = undefined;
        @memcpy(&result, self.extra.items[index .. index + fields.len]);
        return @as(*ty, @ptrCast(&result)).*;
    }

    pub fn addExtra(self: *Pool, extra: anytype) !Node.Index {
        const fields = std.meta.fields(@TypeOf(extra));
        try self.extra.ensureUnusedCapacity(fields.len);
        const result = self.extra.items.len;
        inline for (fields) |field| {
            comptime assert(field.type == Node.Index);
            self.extra.appendAssumeCapacity(@field(extra, field.name));
        }
        return @intCast(result);
    }

    pub fn listToSubrange(self: *Pool, list: []Node.Index) !Extra.Subrange {
        try self.extra.appendSlice(list);
        return .{
            .start = @intCast(self.extra.items.len - list.len),
            .end = @intCast(self.extra.items.len),
        };
    }
};

pub fn main() void {
    var implements = [_]Node.Index{3};
    var body = [_]Node.Index{4};
    var class = Node{ .class = .{
        .abstract = false,
        .name = 1,
        .super_class = 2,
        .implements = &implements,
        .body = &body,
    } };
    var slice_ptr: []u8 = undefined;
    slice_ptr.ptr = @ptrCast(&class);
    slice_ptr.len = @sizeOf(Node);
    std.debug.print("Key: {d} {d}\n", .{ @sizeOf(Node), @sizeOf(Raw) });
    std.debug.print(".class: {d}\n", .{@intFromEnum(Node.class)});
    std.debug.print("typeInfo: {d}\n", .{slice_ptr});
}

test "Pool imports" {
    var pool = Pool.init(std.testing.allocator);
    defer pool.deinit();

    const path_node_index = 4;
    const identifier_token = 2;
    var named_bindings = [_]Node.Index{identifier_token};
    var import_bindings = [_]Node.Index{ 1, 2, 3 };

    const tests = .{
        .{
            Node{ .import_binding = .{ .named = &named_bindings } },
            .import_binding_named,
            .{ .lhs = 0, .rhs = named_bindings.len },
        },
        .{
            Node{ .import_binding = .{ .default = identifier_token } },
            .import_binding_default,
            .{ .lhs = identifier_token, .rhs = Node.Empty },
        },
        .{
            Node{ .import_binding = .{ .namespace = identifier_token } },
            .import_binding_namespace,
            .{ .lhs = identifier_token, .rhs = Node.Empty },
        },
        .{
            Node{ .import = .{ .simple = path_node_index } },
            .import,
            .{ .lhs = Node.Empty, .rhs = path_node_index },
        },
        .{
            Node{ .import = .{ .full = .{ .bindings = &import_bindings, .path = path_node_index } } },
            .import,
            .{ .lhs = 4, .rhs = path_node_index },
        },
    };

    inline for (tests, 1..) |test_case, expected_index| {
        const result_node = try pool.addNode(0, test_case[0]);
        try expectEqual(expected_index, result_node);
        try expectEqualDeep(test_case[0], pool.getNode(result_node));
        try expectEqual(Raw{
            .tag = test_case[1],
            .main_token = 0,
            .data = test_case[2],
        }, pool.getRawNode(result_node));
    }
}

test "Pool exports" {
    var pool = Pool.init(std.testing.allocator);
    defer pool.deinit();

    const named_exports_extra_start: u32 = @intCast(pool.extra.items.len);
    var named_bindings = [_]Node.Index{ 1, 2 };
    const named_exports_key = Node{ .@"export" = .{
        .named = named_bindings[0..],
    } };
    const named_exports = try pool.addNode(0, named_exports_key);

    try expectEqual(1, named_exports);
    try expectEqual(Raw{
        .tag = .export_named,
        .main_token = 0,
        .data = .{
            .lhs = named_exports_extra_start,
            .rhs = @intCast(named_exports_extra_start + named_bindings.len),
        },
    }, pool.nodes.items[named_exports]);
    try expectEqualDeep(named_exports_key, pool.getNode(named_exports));
    try expectEqual(2, pool.extra.items.len);
    try expectEqualSlices(u32, named_bindings[0..], pool.extra.items[named_exports_extra_start .. named_exports_extra_start + named_bindings.len]);

    const path_node_index = 4;
    const alias_node = 5;
    const from_exports_extra_start: u32 = @intCast(pool.extra.items.len);
    const from_exports_key = Node{ .@"export" = .{
        .from = .{
            .bindings = named_bindings[0..],
            .path = path_node_index,
        },
    } };
    const from_exports = try pool.addNode(0, from_exports_key);

    try expectEqual(2, from_exports);
    try expectEqual(Raw{
        .tag = .export_from,
        .main_token = 0,
        .data = .{
            .lhs = @intCast(from_exports_extra_start + named_bindings.len),
            .rhs = path_node_index,
        },
    }, pool.nodes.items[from_exports]);
    try expectEqualDeep(from_exports_key, pool.getNode(from_exports));
    try expectEqual(from_exports_extra_start + named_bindings.len + 2, pool.extra.items.len);
    const subrange_index: u32 = @intCast(from_exports_extra_start + named_bindings.len);
    try expectEqual(Extra.Subrange{
        .start = from_exports_extra_start,
        .end = subrange_index,
    }, pool.getExtra(Extra.Subrange, subrange_index));

    const from_exports_all_extra_start: u32 = @intCast(pool.extra.items.len);
    const from_exports_all_key = Node{ .@"export" = .{
        .from_all = .{
            .alias = alias_node,
            .path = path_node_index,
        },
    } };
    const from_exports_all = try pool.addNode(0, from_exports_all_key);

    try expectEqual(3, from_exports_all);
    try expectEqual(Raw{
        .tag = .export_from_all,
        .main_token = 0,
        .data = .{
            .lhs = alias_node,
            .rhs = path_node_index,
        },
    }, pool.nodes.items[from_exports_all]);
    try expectEqualDeep(from_exports_all_key, pool.getNode(from_exports_all));
    try expectEqual(from_exports_all_extra_start, pool.extra.items.len);

    const exported_node = 5;
    const export_node_key = Node{ .@"export" = .{
        .node = exported_node,
    } };
    const export_node = try pool.addNode(0, export_node_key);
    try expectEqual(4, export_node);
    try expectEqual(Raw{
        .tag = .export_node,
        .main_token = 0,
        .data = .{ .lhs = exported_node },
    }, pool.nodes.items[export_node]);
    try expectEqualDeep(export_node_key, pool.getNode(export_node));

    const export_default_node_key = Node{ .@"export" = .{
        .default = exported_node,
    } };
    const export_default_node = try pool.addNode(0, export_default_node_key);
    try expectEqual(5, export_default_node);
    try expectEqual(Raw{
        .tag = .export_default,
        .main_token = 0,
        .data = .{ .lhs = exported_node },
    }, pool.nodes.items[export_default_node]);
    try expectEqualDeep(export_default_node_key, pool.getNode(export_default_node));
}

test "Pool class declaration" {
    var pool = Pool.init(std.testing.allocator);
    defer pool.deinit();

    const name_node = 1;
    const super_class_node = 2;
    var implements = [_]Node.Index{3};
    var body = [_]Node.Index{4};

    const tests = .{
        .{
            Node{ .class = Node.ClassDeclaration{
                .abstract = false,
                .name = name_node,
                .super_class = super_class_node,
                .implements = &implements,
                .body = &body,
            } },
            .class_decl,
        },
        .{
            Node{ .class = Node.ClassDeclaration{
                .abstract = true,
                .name = name_node,
                .super_class = super_class_node,
                .implements = &implements,
                .body = &body,
            } },
            .abstract_class_decl,
        },
    };

    inline for (tests, 1..) |test_case, expected_index| {
        const start_extra_index: u32 = @intCast(pool.extra.items.len);
        const result_node = try pool.addNode(0, test_case[0]);
        try expectEqual(expected_index, result_node);
        try expectEqual(Raw{
            .tag = test_case[1],
            .main_token = 0,
            .data = .{
                .lhs = name_node,
                .rhs = @intCast(start_extra_index + implements.len + body.len),
            },
        }, pool.getRawNode(result_node));
        try expectEqualDeep(test_case[0], pool.getNode(result_node));
        try expectEqual(start_extra_index + implements.len + body.len + 5, pool.extra.items.len);
        try expectEqualSlices(
            u32,
            &[_]Node.Index{
                implements[0],
                body[0],
                super_class_node,
                start_extra_index,
                @intCast(start_extra_index + implements.len),
                @intCast(start_extra_index + implements.len),
                @intCast(start_extra_index + implements.len + body.len),
            },
            pool.extra.items[start_extra_index..],
        );
    }
}

test "Pool class members" {
    var pool = Pool.init(std.testing.allocator);
    defer pool.deinit();

    const flags = ClassMemberFlags.abstract | ClassMemberFlags.public | ClassMemberFlags.readonly;
    const name_node = 1;
    const decl_type_node = 2;
    const value_node = 3;

    var start_extra_index: u32 = @intCast(pool.extra.items.len);
    const class_field_key = Node{ .class_field = .{
        .name = name_node,
        .decl_type = decl_type_node,
        .value = value_node,
    } };

    const class_field_node = try pool.addNode(0, class_field_key);

    try expectEqual(1, class_field_node);
    try expectEqual(Raw{
        .tag = .class_field,
        .main_token = 0,
        .data = .{
            .lhs = name_node,
            .rhs = start_extra_index,
        },
    }, pool.getRawNode(class_field_node));
    try expectEqualDeep(class_field_key, pool.getNode(class_field_node));
    try expectEqual(start_extra_index + 2, pool.extra.items.len);
    try expectEqualSlices(u32, &[_]Node.Index{ decl_type_node, value_node }, pool.extra.items[start_extra_index..]);

    start_extra_index = @intCast(pool.extra.items.len);
    const class_member_key = Node{ .class_member = .{
        .flags = @intCast(flags),
        .node = class_field_node,
    } };

    const class_member_node = try pool.addNode(0, class_member_key);

    try expectEqual(2, class_member_node);
    try expectEqual(Raw{
        .tag = .class_member,
        .main_token = 0,
        .data = .{
            .lhs = flags,
            .rhs = class_field_node,
        },
    }, pool.getRawNode(class_member_node));
    try expectEqualDeep(class_member_key, pool.getNode(class_member_node));
    try expectEqual(start_extra_index, pool.extra.items.len);

    start_extra_index = @intCast(pool.extra.items.len);
    var class_static_block_nodes = [_]Node.Index{class_field_node};
    const class_static_block_key = Node{ .class_static_block = &class_static_block_nodes };
    const class_static_block_node = try pool.addNode(0, class_static_block_key);
    try expectEqual(3, class_static_block_node);
    try expectEqual(Raw{
        .tag = .class_static_block,
        .main_token = 0,
        .data = .{
            .lhs = start_extra_index,
            .rhs = @intCast(start_extra_index + 1),
        },
    }, pool.getRawNode(class_static_block_node));
    try expectEqualDeep(class_static_block_key, pool.getNode(class_static_block_node));
    try expectEqual(start_extra_index + class_static_block_nodes.len, pool.extra.items.len);
    try expectEqualSlices(u32, &[_]Node.Index{class_field_node}, pool.extra.items[start_extra_index..]);
}

test "Pool declarations" {
    var pool = Pool.init(std.testing.allocator);
    defer pool.deinit();

    const name_node = 1;
    const decl_type_node = 2;
    const value_node = 3;

    var start_extra_index: u32 = @intCast(pool.extra.items.len);
    const decl_binding_key = Node{ .decl_binding = .{
        .name = name_node,
        .decl_type = decl_type_node,
        .value = value_node,
    } };
    const decl_binding_node = try pool.addNode(0, decl_binding_key);

    try expectEqual(1, decl_binding_node);
    try expectEqual(Raw{
        .tag = .decl_binding,
        .main_token = 0,
        .data = .{
            .lhs = name_node,
            .rhs = start_extra_index,
        },
    }, pool.getRawNode(decl_binding_node));
    try expectEqualDeep(decl_binding_key, pool.getNode(decl_binding_node));
    try expectEqual(start_extra_index + 2, pool.extra.items.len);
    try expectEqualSlices(u32, &[_]Node.Index{ decl_type_node, value_node }, pool.extra.items[start_extra_index..]);

    var binding_list = [_]Node.Index{decl_binding_node};
    const tests = .{
        .{ .@"var", .var_decl },
        .{ .@"const", .const_decl },
        .{ .let, .let_decl },
    };

    inline for (tests, 2..) |test_case, expected_index| {
        start_extra_index = @intCast(pool.extra.items.len);
        const key = Node{ .declaration = .{
            .kind = test_case[0],
            .list = &binding_list,
        } };
        const result_node = try pool.addNode(0, key);
        try expectEqual(expected_index, result_node);
        try expectEqual(Raw{
            .tag = test_case[1],
            .main_token = 0,
            .data = .{
                .lhs = start_extra_index,
                .rhs = @intCast(start_extra_index + binding_list.len),
            },
        }, pool.getRawNode(result_node));
        try expectEqualDeep(key, pool.getNode(result_node));
        try expectEqual(start_extra_index + binding_list.len, pool.extra.items.len);
    }
}

test "Pool ifs" {
    var pool = Pool.init(std.testing.allocator);
    defer pool.deinit();

    const expr_node = 1;
    const body_node = 2;
    const else_node = 3;

    const start_extra_index: u32 = @intCast(pool.extra.items.len);
    const if_node_key = Node{ .@"if" = .{
        .expr = expr_node,
        .body = body_node,
        .@"else" = else_node,
    } };
    const if_node = try pool.addNode(0, if_node_key);
    try expectEqual(1, if_node);
    try expectEqual(Raw{
        .tag = .@"if",
        .main_token = 0,
        .data = .{
            .lhs = start_extra_index,
            .rhs = else_node,
        },
    }, pool.nodes.items[if_node]);
    try expectEqualDeep(if_node_key, pool.getNode(if_node));
}

test "Pool switches" {
    var pool = Pool.init(std.testing.allocator);
    defer pool.deinit();

    const case_expr_node = 1;
    var case_body_node = [_]u32{2};

    var start_extra_index: u32 = @intCast(pool.extra.items.len);
    const case_node_key = Node{ .case = .{
        .case = .{
            .expr = case_expr_node,
            .body = &case_body_node,
        },
    } };
    const case_node = try pool.addNode(0, case_node_key);
    try expectEqual(1, case_node);
    try expectEqual(Raw{
        .tag = .case,
        .main_token = 0,
        .data = .{
            .lhs = case_expr_node,
            .rhs = start_extra_index + 1,
        },
    }, pool.nodes.items[case_node]);
    try expectEqualDeep(case_node_key, pool.getNode(case_node));
    try expectEqual(start_extra_index + 3, pool.extra.items.len);
    try expectEqual(Extra.Subrange{
        .start = start_extra_index,
        .end = start_extra_index + 1,
    }, pool.getExtra(Extra.Subrange, start_extra_index + 1));

    start_extra_index = @intCast(pool.extra.items.len);
    const default_node_key = Node{ .case = .{
        .default = &case_body_node,
    } };
    const default_node = try pool.addNode(0, default_node_key);
    try expectEqual(2, default_node);
    try expectEqual(Raw{
        .tag = .default,
        .main_token = 0,
        .data = .{
            .lhs = start_extra_index,
            .rhs = start_extra_index + 1,
        },
    }, pool.nodes.items[default_node]);
    try expectEqualDeep(default_node_key, pool.getNode(default_node));
    try expectEqual(start_extra_index + 1, pool.extra.items.len);
    try expectEqualSlices(u32, &case_body_node, pool.extra.items[start_extra_index .. start_extra_index + 1]);

    start_extra_index = @intCast(pool.extra.items.len);
    var switch_cases = [_]Node.Index{ case_node, default_node };
    const switch_cases_len: u32 = @intCast(switch_cases.len);
    const switch_node_key = Node{ .@"switch" = .{
        .expr = case_expr_node,
        .cases = &switch_cases,
    } };
    const switch_node = try pool.addNode(0, switch_node_key);
    try expectEqual(3, switch_node);
    try expectEqual(Raw{
        .tag = .@"switch",
        .main_token = 0,
        .data = .{
            .lhs = case_expr_node,
            .rhs = start_extra_index + switch_cases_len,
        },
    }, pool.nodes.items[switch_node]);
    try expectEqualDeep(switch_node_key, pool.getNode(switch_node));
    try expectEqual(start_extra_index + switch_cases_len + 2, pool.extra.items.len);
    const switch_range = pool.getExtra(Extra.Subrange, start_extra_index + switch_cases_len);
    try expectEqual(Extra.Subrange{
        .start = start_extra_index,
        .end = start_extra_index + switch_cases_len,
    }, switch_range);
}

test "Pool for loops" {
    var pool = Pool.init(std.testing.allocator);
    defer pool.deinit();

    const init_node = 1;
    const cond_node = 2;
    const post_node = 3;
    const body_node = 4;

    var start_extra_index: u32 = @intCast(pool.extra.items.len);
    const for_node_key = Node{ .@"for" = .{
        .classic = .{
            .init = init_node,
            .cond = cond_node,
            .post = post_node,
            .body = body_node,
        },
    } };
    const for_node = try pool.addNode(0, for_node_key);
    try expectEqual(1, for_node);
    try expectEqual(Raw{
        .tag = .@"for",
        .main_token = 0,
        .data = .{
            .lhs = start_extra_index,
            .rhs = body_node,
        },
    }, pool.getRawNode(for_node));
    try expectEqualDeep(for_node_key, pool.getNode(for_node));
    try expectEqual(start_extra_index + 3, pool.extra.items.len);
    try expectEqual(Extra.ForThree{
        .init = init_node,
        .cond = cond_node,
        .post = post_node,
    }, pool.getExtra(Extra.ForThree, start_extra_index));

    start_extra_index = @intCast(pool.extra.items.len);
    const for_in_key = Node{ .@"for" = .{
        .in = .{
            .left = init_node,
            .right = cond_node,
            .body = body_node,
        },
    } };
    const for_in_node = try pool.addNode(0, for_in_key);
    try expectEqual(2, for_in_node);
    try expectEqual(Raw{
        .tag = .for_in,
        .main_token = 0,
        .data = .{
            .lhs = start_extra_index,
            .rhs = body_node,
        },
    }, pool.getRawNode(for_in_node));
    try expectEqualDeep(for_in_key, pool.getNode(for_in_node));
    try expectEqual(start_extra_index + 2, pool.extra.items.len);
    try expectEqual(Extra.ForTwo{
        .left = init_node,
        .right = cond_node,
    }, pool.getExtra(Extra.ForTwo, start_extra_index));

    start_extra_index = @intCast(pool.extra.items.len);
    const for_of_key = Node{ .@"for" = .{
        .of = .{
            .left = init_node,
            .right = cond_node,
            .body = body_node,
        },
    } };
    const for_of_node = try pool.addNode(0, for_of_key);
    try expectEqual(3, for_of_node);
    try expectEqual(Raw{
        .tag = .for_of,
        .main_token = 0,
        .data = .{
            .lhs = start_extra_index,
            .rhs = body_node,
        },
    }, pool.getRawNode(for_of_node));
    try expectEqualDeep(for_of_key, pool.getNode(for_of_node));
    try expectEqual(start_extra_index + 2, pool.extra.items.len);
    try expectEqual(Extra.ForTwo{
        .left = init_node,
        .right = cond_node,
    }, pool.getExtra(Extra.ForTwo, start_extra_index));
}

test "Pool while loops" {
    var pool = Pool.init(std.testing.allocator);
    defer pool.deinit();

    const cond_node = 1;
    const body_node = 2;

    const data = .{
        .cond = cond_node,
        .body = body_node,
    };
    const tests = .{
        .{ Node{ .@"while" = data }, .@"while" },
        .{ Node{ .do_while = data }, .do_while },
    };
    inline for (tests, 1..) |test_case, expected_index| {
        const while_node = try pool.addNode(0, test_case[0]);
        try expectEqual(expected_index, while_node);
        try expectEqual(Raw{
            .tag = test_case[1],
            .main_token = 0,
            .data = .{
                .lhs = cond_node,
                .rhs = body_node,
            },
        }, pool.getRawNode(while_node));
        try expectEqualDeep(test_case[0], pool.getNode(while_node));
        try expectEqual(0, pool.extra.items.len);
    }
}

test "Pool blocks" {
    var pool = Pool.init(std.testing.allocator);
    defer pool.deinit();

    var stmts = [_]Node.Index{ 1, 2 };

    const test_cases = .{
        .{ Node{ .block = &stmts }, .block },
        .{ Node{ .array_literal = &stmts }, .array_literal },
        .{ Node{ .object_literal = &stmts }, .object_literal },
    };

    inline for (test_cases, 1..) |test_case, expected_index| {
        const start_extra_index: u32 = @intCast(pool.extra.items.len);
        const block_node_node = try pool.addNode(0, test_case[0]);
        try expectEqual(expected_index, block_node_node);
        try expectEqual(Raw{
            .tag = test_case[1],
            .main_token = 0,
            .data = .{ .lhs = start_extra_index, .rhs = @intCast(start_extra_index + stmts.len) },
        }, pool.getRawNode(block_node_node));
        try expectEqualDeep(test_case[0], pool.getNode(block_node_node));
        try expectEqual(start_extra_index + stmts.len, pool.extra.items.len);
    }
}

test "Pool function expressions" {
    var pool = Pool.init(std.testing.allocator);
    defer pool.deinit();

    const param_name_node = 1;
    const param_type_node = 2;
    const func_param_key = Node{ .function_param = .{
        .node = param_name_node,
        .type = param_type_node,
    } };
    const func_param_node = try pool.addNode(0, func_param_key);

    try expectEqual(1, func_param_node);
    try expectEqual(Raw{
        .tag = .function_param,
        .main_token = 0,
        .data = .{
            .lhs = param_name_node,
            .rhs = param_type_node,
        },
    }, pool.getRawNode(func_param_node));
    try expectEqualDeep(func_param_key, pool.getNode(func_param_node));

    var params = [_]Node.Index{func_param_node};

    const name_node = 3;
    const body_node = 4;
    const return_type = 5;

    const async_func_data = .{ .flags = FunctionFlags.Async, .name = name_node, .params = &params, .body = body_node, .return_type = return_type };

    const tests = .{
        .{ Node{ .function_decl = async_func_data }, .func_decl },
        .{ Node{ .function_expr = async_func_data }, .func_expr },
        .{ Node{ .class_method = async_func_data }, .class_method },
        .{ Node{ .object_method = async_func_data }, .object_method },
    };
    inline for (tests, 2..) |test_case, expected_index| {
        const start_extra_index: u32 = @intCast(pool.extra.items.len);
        const result_node = try pool.addNode(0, test_case[0]);

        try expectEqual(expected_index, result_node);
        try expectEqual(Raw{
            .tag = test_case[1],
            .main_token = 0,
            .data = .{
                .lhs = name_node,
                .rhs = @intCast(start_extra_index + params.len),
            },
        }, pool.getRawNode(result_node));
        try expectEqualDeep(test_case[0], pool.getNode(result_node));
        try expectEqual(start_extra_index + params.len + 5, pool.extra.items.len);
        try expectEqualSlices(
            u32,
            &[_]Node.Index{ FunctionFlags.Async, params[0], start_extra_index, @intCast(start_extra_index + params.len), body_node, return_type },
            pool.extra.items[start_extra_index..],
        );
    }
}

test "Pool arrow functions" {
    var pool = Pool.init(std.testing.allocator);
    defer pool.deinit();

    var params = [_]Node.Index{ 1, 2 };
    const body_node = 3;
    const return_type = 5;

    const tests = .{
        .{ .type = .arrow, .tag = .arrow_function },
        .{ .type = .async_arrow, .tag = .async_arrow_function },
    };
    inline for (tests, 1..) |test_case, expected_index| {
        const start_extra_index: u32 = @intCast(pool.extra.items.len);
        const key = Node{ .arrow_function = .{
            .type = test_case.type,
            .params = &params,
            .body = body_node,
            .return_type = return_type,
        } };
        const result_node = try pool.addNode(0, key);
        try expectEqual(expected_index, result_node);
        try expectEqual(Raw{
            .tag = test_case.tag,
            .main_token = 0,
            .data = .{
                .lhs = @intCast(start_extra_index + params.len),
                .rhs = body_node,
            },
        }, pool.getRawNode(result_node));
        try expectEqualDeep(key, pool.getNode(result_node));
        try expectEqual(start_extra_index + params.len + 3, pool.extra.items.len);
        try expectEqualSlices(
            u32,
            &[_]Node.Index{ params[0], params[1], start_extra_index, @intCast(start_extra_index + params.len), return_type },
            pool.extra.items[start_extra_index..],
        );
    }
}

test "Pool call expressions" {
    var pool = Pool.init(std.testing.allocator);
    defer pool.deinit();

    const main_node = 1;
    var params = [_]Node.Index{ 1, 2 };

    const tests = .{
        .{
            Node{ .call_expr = .{ .node = main_node, .params = &params } },
            .call_expr,
        },
    };
    inline for (tests, 1..) |test_case, expected_index| {
        const start_extra_index: u32 = @intCast(pool.extra.items.len);
        const result_node = try pool.addNode(0, test_case[0]);
        try expectEqual(expected_index, result_node);
        try expectEqual(Raw{
            .tag = test_case[1],
            .main_token = 0,
            .data = .{
                .lhs = main_node,
                .rhs = @intCast(start_extra_index + params.len),
            },
        }, pool.getRawNode(result_node));
        try expectEqualDeep(test_case[0], pool.getNode(result_node));
        try expectEqual(start_extra_index + params.len + 2, pool.extra.items.len);
        try expectEqualSlices(
            u32,
            &[_]Node.Index{ params[0], params[1], start_extra_index, @intCast(start_extra_index + params.len) },
            pool.extra.items[start_extra_index..],
        );
    }
}

test "Pool binary" {
    var pool = Pool.init(std.testing.allocator);
    defer pool.deinit();

    const left_node = 1;
    const right_node = 2;

    const data = .{
        .left = left_node,
        .right = right_node,
    };
    const tests = .{
        .{ Node{ .comma = data }, .comma },
        .{ Node{ .assignment = data }, .assignment },
        .{ Node{ .lt = data }, .lt },
        .{ Node{ .gt = data }, .gt },
        .{ Node{ .lte = data }, .lte },
        .{ Node{ .gte = data }, .gte },
        .{ Node{ .eq = data }, .eq },
        .{ Node{ .eqq = data }, .eqq },
        .{ Node{ .neq = data }, .neq },
        .{ Node{ .neqq = data }, .neqq },
        .{ Node{ .@"and" = data }, .@"and" },
        .{ Node{ .@"or" = data }, .@"or" },
        .{ Node{ .plus_expr = data }, .plus_expr },
        .{ Node{ .minus_expr = data }, .minus_expr },
        .{ Node{ .multiply_expr = data }, .multiply_expr },
        .{ Node{ .exp_expr = data }, .exp_expr },
        .{ Node{ .div_expr = data }, .div_expr },
        .{ Node{ .modulo_expr = data }, .modulo_expr },
        .{ Node{ .bitwise_and = data }, .bitwise_and },
        .{ Node{ .bitwise_or = data }, .bitwise_or },
        .{ Node{ .bitwise_xor = data }, .bitwise_xor },
        .{ Node{ .bitwise_shift_left = data }, .bitwise_shift_left },
        .{ Node{ .bitwise_shift_right = data }, .bitwise_shift_right },
        .{ Node{ .bitwise_unsigned_right_shift = data }, .bitwise_unsigned_right_shift },
        .{ Node{ .plus_assign = data }, .plus_assign },
        .{ Node{ .minus_assign = data }, .minus_assign },
        .{ Node{ .multiply_assign = data }, .multiply_assign },
        .{ Node{ .modulo_assign = data }, .modulo_assign },
        .{ Node{ .div_assign = data }, .div_assign },
        .{ Node{ .exp_assign = data }, .exp_assign },
        .{ Node{ .and_assign = data }, .and_assign },
        .{ Node{ .or_assign = data }, .or_assign },
        .{ Node{ .bitwise_and_assign = data }, .bitwise_and_assign },
        .{ Node{ .bitwise_or_assign = data }, .bitwise_or_assign },
        .{ Node{ .bitwise_xor_assign = data }, .bitwise_xor_assign },
        .{ Node{ .bitwise_shift_left_assign = data }, .bitwise_shift_left_assign },
        .{ Node{ .bitwise_shift_right_assign = data }, .bitwise_shift_right_assign },
        .{ Node{ .bitwise_unsigned_right_shift_assign = data }, .bitwise_unsigned_right_shift_assign },
        .{ Node{ .instanceof = data }, .instanceof },
        .{ Node{ .in = data }, .in },
        .{ Node{ .object_literal_field = data }, .object_literal_field },
        .{ Node{ .property_access = data }, .property_access },
        .{ Node{ .optional_property_access = data }, .optional_property_access },
        .{ Node{ .index_access = data }, .index_access },
        .{ Node{ .type_decl = data }, .type_decl },
        .{ Node{ .type_intersection = data }, .type_intersection },
        .{ Node{ .type_union = data }, .type_union },
    };

    inline for (tests, 1..) |test_case, expected_index| {
        const result_node = try pool.addNode(0, test_case[0]);
        try expectEqual(expected_index, result_node);
        try expectEqual(Raw{
            .tag = test_case[1],
            .main_token = 0,
            .data = .{
                .lhs = data.left,
                .rhs = data.right,
            },
        }, pool.getRawNode(result_node));
        try expectEqualDeep(test_case[0], pool.getNode(result_node));
        try expectEqual(0, pool.extra.items.len);
    }
}

test "Pool single node" {
    var pool = Pool.init(std.testing.allocator);
    defer pool.deinit();

    const node = 1;

    const tests = .{
        .{ Node{ .grouping = node }, .grouping },
        .{ Node{ .plus = node }, .plus },
        .{ Node{ .plusplus_pre = node }, .plusplus_pre },
        .{ Node{ .plusplus_post = node }, .plusplus_post },
        .{ Node{ .minus = node }, .minus },
        .{ Node{ .minusminus_pre = node }, .minusminus_pre },
        .{ Node{ .minusminus_post = node }, .minusminus_post },
        .{ Node{ .not = node }, .not },
        .{ Node{ .new_expr = node }, .new_expr },
        .{ Node{ .bitwise_negate = node }, .bitwise_negate },
        .{ Node{ .spread = node }, .spread },
        .{ Node{ .typeof = node }, .typeof },
        .{ Node{ .void = node }, .void },
        .{ Node{ .delete = node }, .delete },
        .{ Node{ .computed_identifier = node }, .computed_identifier },
        .{ Node{ .object_literal_field_shorthand = node }, .object_literal_field_shorthand },
        .{ Node{ .array_type = node }, .array_type },
    };

    inline for (tests, 1..) |test_case, expected_index| {
        const result_node = try pool.addNode(0, test_case[0]);
        try expectEqual(expected_index, result_node);
        try expectEqual(Raw{
            .tag = test_case[1],
            .main_token = 0,
            .data = .{ .lhs = node },
        }, pool.getRawNode(result_node));
        try expectEqualDeep(test_case[0], pool.getNode(result_node));
        try expectEqual(0, pool.extra.items.len);
    }
}

test "Pool empty" {
    var pool = Pool.init(std.testing.allocator);
    defer pool.deinit();

    const tests = .{
        .{ Node{ .@"break" = {} }, .@"break" },
        .{ Node{ .@"continue" = {} }, .@"continue" },
    };

    inline for (tests, 1..) |test_case, expected_index| {
        const result_node = try pool.addNode(0, test_case[0]);
        try expectEqual(expected_index, result_node);
        try expectEqual(Raw{
            .tag = test_case[1],
            .main_token = 0,
            .data = .{ .lhs = 0, .rhs = 0 },
        }, pool.getRawNode(result_node));
        try expectEqualDeep(test_case[0], pool.getNode(result_node));
        try expectEqual(0, pool.extra.items.len);
    }
}

test "Pool simple_value" {
    var pool = Pool.init(std.testing.allocator);
    defer pool.deinit();

    const data = Node.SimpleValue{
        .kind = .this,
    };
    const tests = .{
        .{ Node{ .simple_type = data }, .simple_type },
        .{ Node{ .simple_value = data }, .simple_value },
    };

    inline for (tests, 1..) |test_case, expected_index| {
        const result_node = try pool.addNode(0, test_case[0]);
        try expectEqual(expected_index, result_node);
        try expectEqual(Raw{
            .tag = test_case[1],
            .main_token = 0,
            .data = .{ .lhs = @intFromEnum(data.kind), .rhs = Node.Empty },
        }, pool.getRawNode(result_node));
        try expectEqualDeep(test_case[0], pool.getNode(result_node));
        try expectEqual(0, pool.extra.items.len);
    }
}

test "Pool object type" {
    var pool = Pool.init(std.testing.allocator);
    defer pool.deinit();

    const field_name = 1;
    const field_type = 2;
    const obj_type_field = Node{ .object_type_field = .{
        .name = field_name,
        .type = field_type,
    } };
    const obj_type_field_node = try pool.addNode(0, obj_type_field);

    try expectEqual(1, obj_type_field_node);
    try expectEqual(Raw{
        .tag = .object_type_field,
        .main_token = 0,
        .data = .{ .lhs = field_name, .rhs = field_type },
    }, pool.getRawNode(obj_type_field_node));
    try expectEqualDeep(obj_type_field, pool.getNode(obj_type_field_node));

    var field_list = [_]Node.Index{obj_type_field_node};
    const obj_type = Node{
        .object_type = &field_list,
    };
    const obj_type_node = try pool.addNode(0, obj_type);

    try expectEqual(2, obj_type_node);
    try expectEqual(Raw{
        .tag = .object_type,
        .main_token = 0,
        .data = .{ .lhs = 0, .rhs = @intCast(pool.extra.items.len) },
    }, pool.getRawNode(obj_type_node));
    try expectEqualDeep(obj_type, pool.getNode(obj_type_node));
    try expectEqual(1, pool.extra.items.len);
    try expectEqualSlices(Node.Index, &[_]Node.Index{obj_type_field_node}, pool.extra.items[0..]);
}

test "Pool generic_type" {
    var pool = Pool.init(std.testing.allocator);
    defer pool.deinit();

    const name_node = 1;
    var params = [_]Node.Index{2};
    const data = Node.GenericType{
        .name = name_node,
        .params = &params,
    };
    const tests = .{
        .{ Node{ .generic_type = data }, .generic_type },
    };

    inline for (tests, 1..) |test_case, expected_index| {
        const start_extra_index: u32 = @intCast(pool.extra.items.len);
        const result_node = try pool.addNode(0, test_case[0]);
        try expectEqual(expected_index, result_node);
        try expectEqual(Raw{
            .tag = test_case[1],
            .main_token = 0,
            .data = .{
                .lhs = name_node,
                .rhs = @intCast(start_extra_index + params.len),
            },
        }, pool.getRawNode(result_node));
        try expectEqualDeep(test_case[0], pool.getNode(result_node));
        try expectEqual(params.len + 2, pool.extra.items.len);
        try expectEqualSlices(
            u32,
            &[_]Node.Index{ params[0], start_extra_index, @intCast(start_extra_index + params.len) },
            pool.extra.items[0..],
        );
    }
}

test "Pool interface_decl" {
    var pool = Pool.init(std.testing.allocator);
    defer pool.deinit();

    const name_node = 1;
    var extends = [_]Node.Index{2};
    var body = [_]Node.Index{3};
    const data = Node.InterfaceDecl{
        .name = name_node,
        .extends = &extends,
        .body = &body,
    };

    const tests = .{
        .{ Node{ .interface_decl = data }, .interface_decl },
    };

    inline for (tests, 1..) |test_case, expected_index| {
        const start_extra_index: u32 = @intCast(pool.extra.items.len);
        const result_node = try pool.addNode(0, test_case[0]);
        try expectEqual(expected_index, result_node);
        try expectEqual(Raw{
            .tag = test_case[1],
            .main_token = 0,
            .data = .{
                .lhs = name_node,
                .rhs = @intCast(start_extra_index + extends.len + body.len),
            },
        }, pool.getRawNode(result_node));
        try expectEqualDeep(test_case[0], pool.getNode(result_node));
        try expectEqual(extends.len + body.len + 4, pool.extra.items.len);
        try expectEqualSlices(
            u32,
            &[_]Node.Index{ extends[0], body[0], start_extra_index, @intCast(start_extra_index + extends.len), @intCast(start_extra_index + extends.len), @intCast(start_extra_index + extends.len + body.len) },
            pool.extra.items[0..],
        );
    }
}
