const std = @import("std");
const Token = @import("consts.zig").Token;
const Parser = @import("parser.zig");
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

    // lhs: identifier, rhs: alias or empty
    binding_decl,

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
    coalesce,
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
    coalesce_assign,
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

    // LCOV_EXCL_START
    pub fn format(self: Raw, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        try std.fmt.format(writer, "AST.Raw{{.tag = .{s}, .main_token = {d}, .data.lhs = {d}, .data.rhs = {d}}}", .{
            @tagName(self.tag),
            self.main_token,
            self.data.lhs,
            self.data.rhs,
        });
    }
    // LCOV_EXCL_STOP
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

    pub const ArrowFunction = struct {
        params_start: Node.Index,
        params_end: Node.Index,
        body: Node.Index,
        return_type: Node.Index,
    };

    pub const Function = struct {
        flags: Node.Index,
        params_start: Node.Index,
        params_end: Node.Index,
        body: Node.Index,
        return_type: Node.Index,
    };

    pub const FunctionType = struct {
        generic_params_start: Node.Index,
        generic_params_end: Node.Index,
        params_start: Node.Index,
        params_end: Node.Index,
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
    binding_decl: BindingDecl,
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
    coalesce: Binary,
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
    coalesce_assign: Binary,
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

    pub const BindingDecl = struct {
        name: Token.Index,
        alias: Node.Index,
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
        generic_params: []Node.Index,
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

pub fn addNode(self: *Parser, main_token: Token.Index, key: Node) Node.Index {
    switch (key) {
        .root => |root| {
            const subrange = listToSubrange(self, root);
            return addRawNode(self, .{
                .tag = .root,
                .main_token = main_token,
                .data = .{ .lhs = subrange.start, .rhs = subrange.end },
            });
        },
        .binding_decl => |binding_decl| {
            return addRawNode(self, .{
                .tag = .binding_decl,
                .main_token = main_token,
                .data = .{ .lhs = binding_decl.name, .rhs = binding_decl.alias },
            });
        },
        .import => |import| {
            switch (import) {
                .simple => |simple| {
                    return addRawNode(self, .{
                        .tag = .import,
                        .main_token = main_token,
                        .data = .{ .rhs = simple },
                    });
                },
                .full => |full| {
                    const span = listToSubrange(self, full.bindings);
                    return addRawNode(self, .{
                        .tag = .import,
                        .main_token = main_token,
                        .data = .{
                            .lhs = addExtra(self, span),
                            .rhs = full.path,
                        },
                    });
                },
            }
        },
        .import_binding => |import_binding| {
            switch (import_binding) {
                .named => |named| {
                    const span = listToSubrange(self, named);
                    return addRawNode(self, .{
                        .tag = .import_binding_named,
                        .main_token = main_token,
                        .data = .{
                            .lhs = span.start,
                            .rhs = span.end,
                        },
                    });
                },
                .default => |default| {
                    return addRawNode(self, .{
                        .tag = .import_binding_default,
                        .main_token = main_token,
                        .data = .{ .lhs = default },
                    });
                },
                .namespace => |namespace| {
                    return addRawNode(self, .{
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
                    const span = listToSubrange(self, named);
                    return addRawNode(self, .{
                        .tag = .export_named,
                        .main_token = main_token,
                        .data = .{
                            .lhs = span.start,
                            .rhs = span.end,
                        },
                    });
                },
                .from => |from| {
                    const span = listToSubrange(self, from.bindings);
                    return addRawNode(self, .{
                        .tag = .export_from,
                        .main_token = main_token,
                        .data = .{
                            .lhs = addExtra(self, span),
                            .rhs = from.path,
                        },
                    });
                },
                .from_all => |from| {
                    return addRawNode(self, .{
                        .tag = .export_from_all,
                        .main_token = main_token,
                        .data = .{
                            .lhs = from.alias,
                            .rhs = from.path,
                        },
                    });
                },
                .default => |default| {
                    return addRawNode(self, .{
                        .tag = .export_default,
                        .main_token = main_token,
                        .data = .{ .lhs = default },
                    });
                },
                .node => |node| {
                    return addRawNode(self, .{
                        .tag = .export_node,
                        .main_token = main_token,
                        .data = .{ .lhs = node },
                    });
                },
            }
        },
        .class => |class| {
            const implements_span = listToSubrange(self, class.implements);
            const subrange = listToSubrange(self, class.body);
            return addRawNode(self, .{
                .tag = if (class.abstract) .abstract_class_decl else .class_decl,
                .main_token = main_token,
                .data = .{
                    .lhs = class.name,
                    .rhs = addExtra(self, Extra.ClassDeclaration{
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
            const subrange = listToSubrange(self, static_block);
            return addRawNode(self, .{
                .tag = .class_static_block,
                .main_token = main_token,
                .data = .{
                    .lhs = subrange.start,
                    .rhs = subrange.end,
                },
            });
        },
        .class_member => |member| {
            return addRawNode(self, .{
                .tag = .class_member,
                .main_token = main_token,
                .data = .{
                    .lhs = member.flags,
                    .rhs = member.node,
                },
            });
        },
        .class_field => |field| {
            const binding = addExtra(self, Extra.Declaration{
                .decl_type = field.decl_type,
                .value = field.value,
            });
            return addRawNode(self, .{
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
            const subrange = listToSubrange(self, declaration.list);
            return addRawNode(self, .{
                .tag = tag,
                .main_token = main_token,
                .data = .{
                    .lhs = subrange.start,
                    .rhs = subrange.end,
                },
            });
        },
        .decl_binding => |declaration| {
            return addRawNode(self, .{
                .tag = .decl_binding,
                .main_token = main_token,
                .data = .{
                    .lhs = declaration.name,
                    .rhs = addExtra(self, Extra.Declaration{
                        .decl_type = declaration.decl_type,
                        .value = declaration.value,
                    }),
                },
            });
        },
        .@"if", .ternary_expr => |if_node| {
            return addRawNode(self, .{
                .tag = if (key == .@"if") .@"if" else .ternary,
                .main_token = main_token,
                .data = .{
                    .lhs = addExtra(self, Extra.If{
                        .expr = if_node.expr,
                        .body = if_node.body,
                    }),
                    .rhs = if_node.@"else",
                },
            });
        },
        .@"switch" => |switch_node| {
            const cases = listToSubrange(self, switch_node.cases);
            return addRawNode(self, .{
                .tag = .@"switch",
                .main_token = main_token,
                .data = .{
                    .lhs = switch_node.expr,
                    .rhs = addExtra(self, cases),
                },
            });
        },
        .case => |case_key| {
            switch (case_key) {
                .default => |default_node| {
                    const stmts = listToSubrange(self, default_node);
                    return addRawNode(self, .{
                        .tag = .default,
                        .main_token = main_token,
                        .data = .{
                            .lhs = stmts.start,
                            .rhs = stmts.end,
                        },
                    });
                },
                .case => |case_node| {
                    const stmts = listToSubrange(self, case_node.body);
                    return addRawNode(self, .{
                        .tag = .case,
                        .main_token = main_token,
                        .data = .{
                            .lhs = case_node.expr,
                            .rhs = addExtra(self, stmts),
                        },
                    });
                },
            }
        },
        .@"for" => |for_node| {
            switch (for_node) {
                .classic => |classic| {
                    return addRawNode(self, .{
                        .tag = .@"for",
                        .main_token = main_token,
                        .data = .{
                            .lhs = addExtra(self, Extra.ForThree{
                                .init = classic.init,
                                .cond = classic.cond,
                                .post = classic.post,
                            }),
                            .rhs = classic.body,
                        },
                    });
                },
                .in => |in| {
                    return addRawNode(self, .{
                        .tag = .for_in,
                        .main_token = main_token,
                        .data = .{
                            .lhs = addExtra(self, Extra.ForTwo{
                                .left = in.left,
                                .right = in.right,
                            }),
                            .rhs = in.body,
                        },
                    });
                },
                .of => |of| {
                    return addRawNode(self, .{
                        .tag = .for_of,
                        .main_token = main_token,
                        .data = .{
                            .lhs = addExtra(self, Extra.ForTwo{
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
            return addRawNode(self, .{
                .tag = if (key == .@"while") .@"while" else .do_while,
                .main_token = main_token,
                .data = .{
                    .lhs = while_node.cond,
                    .rhs = while_node.body,
                },
            });
        },
        .block, .array_literal, .object_literal => |nodes| {
            const subrange = listToSubrange(self, nodes);
            return addRawNode(self, .{
                .tag = switch (key) {
                    .block => .block,
                    .array_literal => .array_literal,
                    .object_literal => .object_literal,
                    else => unreachable, // LCOV_EXCL_LINE
                },
                .main_token = main_token,
                .data = .{ .lhs = subrange.start, .rhs = subrange.end },
            });
        },
        .function_param => |param| {
            return addRawNode(self, .{
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
                else => unreachable, // LCOV_EXCL_LINE
            };
            const subrange = listToSubrange(self, func_decl.params);
            return addRawNode(self, .{
                .tag = tag,
                .main_token = main_token,
                .data = .{
                    .lhs = func_decl.name,
                    .rhs = addExtra(self, Extra.Function{
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
            const subrange = listToSubrange(self, arrow_func.params);
            return addRawNode(self, .{
                .tag = if (arrow_func.type == .async_arrow) .async_arrow_function else .arrow_function,
                .main_token = main_token,
                .data = .{
                    .lhs = addExtra(self, Extra.ArrowFunction{
                        .params_start = subrange.start,
                        .params_end = subrange.end,
                        .return_type = arrow_func.return_type,
                        .body = arrow_func.body,
                    }),
                    .rhs = arrow_func.body,
                },
            });
        },
        .call_expr => |expr| {
            const subrange = listToSubrange(self, expr.params);
            return addRawNode(self, .{
                .tag = .call_expr,
                .main_token = main_token,
                .data = .{
                    .lhs = expr.node,
                    .rhs = addExtra(self, subrange),
                },
            });
        },
        .object_type, .tuple_type => |obj_type| {
            const subrange = listToSubrange(self, obj_type);
            return addRawNode(self, .{
                .tag = if (key == .object_type) .object_type else .tuple_type,
                .main_token = main_token,
                .data = .{
                    .lhs = subrange.start,
                    .rhs = subrange.end,
                },
            });
        },
        .function_type => |func_type| {
            const generic_params_subrange = listToSubrange(self, func_type.generic_params);
            const params_subrange = listToSubrange(self, func_type.params);
            const extra = addExtra(self, Extra.FunctionType{
                .generic_params_start = generic_params_subrange.start,
                .generic_params_end = generic_params_subrange.end,
                .params_start = params_subrange.start,
                .params_end = params_subrange.end,
            });
            return addRawNode(self, .{
                .tag = .function_type,
                .main_token = main_token,
                .data = .{
                    .lhs = extra,
                    .rhs = func_type.return_type,
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
        .coalesce,
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
        .coalesce_assign,
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
                .coalesce => .coalesce,
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
                .coalesce_assign => .coalesce_assign,
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
                else => unreachable, // LCOV_EXCL_LINE
            };
            return addRawNode(self, .{
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
                else => unreachable, // LCOV_EXCL_LINE
            };
            return addRawNode(self, .{
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
                else => unreachable, // LCOV_EXCL_LINE
            };
            return addRawNode(self, .{
                .tag = tag,
                .main_token = main_token,
                .data = .{},
            });
        },
        .simple_value, .simple_type => |simple_value| {
            return addRawNode(self, .{
                .tag = if (key == .simple_value) .simple_value else .simple_type,
                .main_token = main_token,
                .data = .{ .lhs = @intFromEnum(simple_value.kind) },
            });
        },
        .object_type_field => |obj_field_type| {
            return addRawNode(self, .{
                .tag = .object_type_field,
                .main_token = main_token,
                .data = .{ .lhs = obj_field_type.name, .rhs = obj_field_type.type },
            });
        },
        .generic_type => |generic_type| {
            const span = listToSubrange(self, generic_type.params);
            return addRawNode(self, .{
                .tag = .generic_type,
                .main_token = main_token,
                .data = .{
                    .lhs = generic_type.name,
                    .rhs = addExtra(self, span),
                },
            });
        },
        .interface_decl => |interface_decl| {
            const extends_span = listToSubrange(self, interface_decl.extends);
            const body_span = listToSubrange(self, interface_decl.body);
            return addRawNode(self, .{
                .tag = .interface_decl,
                .main_token = main_token,
                .data = .{
                    .lhs = interface_decl.name,
                    .rhs = addExtra(self, Extra.Interface{
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

pub fn getNode(self: Parser, index: Node.Index) Node {
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

            const subrange = getExtra(self, Extra.Subrange, node.data.lhs);
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
        .binding_decl => {
            return .{
                .binding_decl = .{
                    .name = node.data.lhs,
                    .alias = node.data.rhs,
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
            const span = getExtra(self, Extra.Subrange, node.data.lhs);
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
            const class = getExtra(self, Extra.ClassDeclaration, node.data.rhs);
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
            const field = getExtra(self, Extra.Declaration, node.data.rhs);
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
                        else => unreachable, // LCOV_EXCL_LINE
                    },
                    .list = self.extra.items[node.data.lhs..node.data.rhs],
                },
            };
        },
        .decl_binding => {
            const extra = getExtra(self, Extra.Declaration, node.data.rhs);
            return .{
                .decl_binding = .{
                    .name = node.data.lhs,
                    .decl_type = extra.decl_type,
                    .value = extra.value,
                },
            };
        },
        .@"if", .ternary => {
            const if_extra = getExtra(self, Extra.If, node.data.lhs);
            const data = .{
                .expr = if_extra.expr,
                .body = if_extra.body,
                .@"else" = node.data.rhs,
            };
            return switch (node.tag) {
                .@"if" => .{ .@"if" = data },
                .ternary => .{ .ternary_expr = data },
                else => unreachable, // LCOV_EXCL_LINE
            };
        },
        .@"switch" => {
            const subrange = getExtra(self, Extra.Subrange, node.data.rhs);
            return .{
                .@"switch" = .{
                    .expr = node.data.lhs,
                    .cases = self.extra.items[subrange.start..subrange.end],
                },
            };
        },
        .case => {
            const expr = node.data.lhs;
            const subrange = getExtra(self, Extra.Subrange, node.data.rhs);
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
            const for_extra = getExtra(self, Extra.ForThree, node.data.lhs);
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
            const for_extra = getExtra(self, Extra.ForTwo, node.data.lhs);
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
            const for_extra = getExtra(self, Extra.ForTwo, node.data.lhs);
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
            const extra = getExtra(self, Extra.Function, node.data.rhs);
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
                else => unreachable, // LCOV_EXCL_LINE
            };
        },
        .async_arrow_function, .arrow_function => {
            const extra = getExtra(self, Extra.ArrowFunction, node.data.lhs);
            return Node{
                .arrow_function = .{
                    .type = switch (node.tag) {
                        .async_arrow_function => .async_arrow,
                        .arrow_function => .arrow,
                        else => unreachable, // LCOV_EXCL_LINE
                    },
                    .params = self.extra.items[extra.params_start..extra.params_end],
                    .body = node.data.rhs,
                    .return_type = extra.return_type,
                },
            };
        },
        .call_expr => {
            const extra = getExtra(self, Extra.Subrange, node.data.rhs);
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
                else => unreachable, // LCOV_EXCL_LINE
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
        .coalesce,
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
        .coalesce_assign,
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
                .coalesce => .{ .coalesce = data },
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
                .coalesce_assign => .{ .coalesce_assign = data },
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
                else => unreachable, // LCOV_EXCL_LINE
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
                else => unreachable, // LCOV_EXCL_LINE
            };
        },

        .@"break",
        .@"continue",
        => {
            return switch (node.tag) {
                .@"break" => .{ .@"break" = {} },
                .@"continue" => .{ .@"continue" = {} },
                else => unreachable, // LCOV_EXCL_LINE
            };
        },

        .simple_type, .simple_value => {
            const data = Node.SimpleValue{
                .kind = @enumFromInt(node.data.lhs),
            };
            return switch (node.tag) {
                .simple_type => .{ .simple_type = data },
                .simple_value => .{ .simple_value = data },
                else => unreachable, // LCOV_EXCL_LINE
            };
        },

        .function_type => {
            const extra = getExtra(self, Extra.FunctionType, node.data.lhs);
            return .{ .function_type = .{
                .generic_params = self.extra.items[extra.generic_params_start..extra.generic_params_end],
                .params = self.extra.items[extra.params_start..extra.params_end],
                .return_type = node.data.rhs,
            } };
        },

        .object_type, .tuple_type => {
            return switch (node.tag) {
                .object_type => .{ .object_type = self.extra.items[node.data.lhs..node.data.rhs] },
                .tuple_type => .{ .tuple_type = self.extra.items[node.data.lhs..node.data.rhs] },
                else => unreachable, // LCOV_EXCL_LINE
            };
        },

        .object_type_field => {
            return .{ .object_type_field = .{
                .name = node.data.lhs,
                .type = node.data.rhs,
            } };
        },

        .generic_type => {
            const span = getExtra(self, Extra.Subrange, node.data.rhs);
            return .{ .generic_type = .{
                .name = node.data.lhs,
                .params = self.extra.items[span.start..span.end],
            } };
        },

        .interface_decl => {
            const interface = getExtra(self, Extra.Interface, node.data.rhs);
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

pub fn getRawNode(self: Parser, index: Node.Index) Raw {
    return self.nodes.items[index];
}

pub fn addRawNode(self: *Parser, node: Raw) Node.Index {
    const index = self.nodes.items.len;
    self.nodes.append(node) catch @panic("Out of memory");
    return @intCast(index);
}

pub fn getExtra(self: Parser, ty: type, index: Node.Index) ty {
    const fields = std.meta.fields(ty);
    var result: [fields.len]Node.Index = undefined;
    @memcpy(&result, self.extra.items[index .. index + fields.len]);
    return @as(*ty, @ptrCast(&result)).*;
}

pub fn addExtra(self: *Parser, extra: anytype) Node.Index {
    const fields = std.meta.fields(@TypeOf(extra));
    self.extra.ensureUnusedCapacity(fields.len) catch @panic("Out of memory");
    const result = self.extra.items.len;
    inline for (fields) |field| {
        comptime assert(field.type == Node.Index);
        self.extra.appendAssumeCapacity(@field(extra, field.name));
    }
    return @intCast(result);
}

pub fn listToSubrange(self: *Parser, list: []Node.Index) Extra.Subrange {
    self.extra.appendSlice(list) catch @panic("Out of memory");
    return .{
        .start = @intCast(self.extra.items.len - list.len),
        .end = @intCast(self.extra.items.len),
    };
}

fn expectRawNode(expected_raw: Raw, node: Node) !void {
    var parser = Parser.init(std.testing.allocator, "1");
    defer parser.deinit();

    const node_idx = addNode(&parser, 0, node);

    try expectEqualDeep(expected_raw, getRawNode(parser, node_idx));
    try expectEqualDeep(node, getNode(parser, node_idx));
}

test "Pool root" {
    var stmts = [_]Node.Index{ 1, 2, 3 };
    try expectRawNode(Raw{
        .tag = .root,
        .main_token = 0,
        .data = .{ .lhs = 0, .rhs = @intCast(stmts.len) },
    }, Node{ .root = &stmts });
}

test "Pool imports" {
    const name_node = 1;
    const alias_node = 2;
    const path_node_index = 4;
    const identifier_token = 2;
    var named_bindings = [_]Node.Index{identifier_token};
    var import_bindings = [_]Node.Index{ 1, 2, 3 };

    const tests = .{
        .{
            Node{ .import_binding = .{ .named = &named_bindings } },
            Raw{ .tag = .import_binding_named, .main_token = 0, .data = .{ .lhs = 0, .rhs = named_bindings.len } },
        },
        .{
            Node{ .import_binding = .{ .default = identifier_token } },
            Raw{ .tag = .import_binding_default, .main_token = 0, .data = .{ .lhs = identifier_token, .rhs = Node.Empty } },
        },
        .{
            Node{ .import_binding = .{ .namespace = identifier_token } },
            Raw{ .tag = .import_binding_namespace, .main_token = 0, .data = .{ .lhs = identifier_token, .rhs = Node.Empty } },
        },
        .{
            Node{ .import = .{ .simple = path_node_index } },
            Raw{ .tag = .import, .main_token = 0, .data = .{ .lhs = Node.Empty, .rhs = path_node_index } },
        },
        .{
            Node{ .import = .{ .full = .{ .bindings = &import_bindings, .path = path_node_index } } },
            Raw{ .tag = .import, .main_token = 0, .data = .{ .lhs = import_bindings.len, .rhs = path_node_index } },
        },
        .{
            Node{ .binding_decl = .{ .name = name_node, .alias = alias_node } },
            Raw{ .tag = .binding_decl, .main_token = 0, .data = .{ .lhs = name_node, .rhs = alias_node } },
        },
    };

    inline for (tests) |test_case| {
        try expectRawNode(test_case[1], test_case[0]);
    }
}

test "Pool exports" {
    const node_index = 3;
    const path_index = 4;
    const alias_index = 5;
    var bindings = [_]Node.Index{ 1, 2 };

    const tests = .{
        .{
            Node{ .@"export" = .{ .named = &bindings } },
            Raw{ .tag = .export_named, .main_token = 0, .data = .{ .lhs = 0, .rhs = bindings.len } },
        },
        .{
            Node{ .@"export" = .{ .from = .{ .bindings = &bindings, .path = path_index } } },
            Raw{ .tag = .export_from, .main_token = 0, .data = .{ .lhs = bindings.len, .rhs = path_index } },
        },
        .{
            Node{ .@"export" = .{ .from_all = .{ .alias = alias_index, .path = path_index } } },
            Raw{ .tag = .export_from_all, .main_token = 0, .data = .{ .lhs = alias_index, .rhs = path_index } },
        },
        .{
            Node{ .@"export" = .{ .default = node_index } },
            Raw{ .tag = .export_default, .main_token = 0, .data = .{ .lhs = node_index, .rhs = 0 } },
        },
        .{
            Node{ .@"export" = .{ .node = node_index } },
            Raw{ .tag = .export_node, .main_token = 0, .data = .{ .lhs = node_index, .rhs = 0 } },
        },
    };

    inline for (tests) |test_case| {
        try expectRawNode(test_case[1], test_case[0]);
    }
}

test "Pool class declaration" {
    const name_node = 1;
    const super_class_node = 2;
    var implements = [_]Node.Index{3};
    var body = [_]Node.Index{4};

    const tests = .{
        .{
            Node{ .class = Node.ClassDeclaration{ .abstract = false, .name = name_node, .super_class = super_class_node, .implements = &implements, .body = &body } },
            .class_decl,
        },
        .{
            Node{ .class = Node.ClassDeclaration{ .abstract = true, .name = name_node, .super_class = super_class_node, .implements = &implements, .body = &body } },
            .abstract_class_decl,
        },
    };

    inline for (tests) |test_case| {
        try expectRawNode(Raw{
            .tag = test_case[1],
            .main_token = 0,
            .data = .{ .lhs = name_node, .rhs = @intCast(implements.len + body.len) },
        }, test_case[0]);
    }
}

test "Pool class members" {
    const flags = ClassMemberFlags.abstract | ClassMemberFlags.public | ClassMemberFlags.readonly;
    const name_node = 1;
    const decl_type_node = 2;
    const value_node = 3;
    const class_field_node = 4;
    var class_static_nodes = [_]Node.Index{class_field_node};

    const tests = .{
        .{
            Node{ .class_field = .{ .name = name_node, .decl_type = decl_type_node, .value = value_node } },
            Raw{ .tag = .class_field, .main_token = 0, .data = .{ .lhs = name_node, .rhs = 0 } },
        },
        .{
            Node{ .class_member = .{ .flags = @intCast(flags), .node = class_field_node } },
            Raw{ .tag = .class_member, .main_token = 0, .data = .{ .lhs = flags, .rhs = class_field_node } },
        },
        .{
            Node{ .class_static_block = &class_static_nodes },
            Raw{ .tag = .class_static_block, .main_token = 0, .data = .{ .lhs = 0, .rhs = @intCast(class_static_nodes.len) } },
        },
    };

    inline for (tests) |test_case| {
        try expectRawNode(test_case[1], test_case[0]);
    }
}

test "Pool declarations" {
    const name_node = 1;
    const decl_type_node = 2;
    const value_node = 3;
    var binding_list = [_]Node.Index{4};

    const tests = .{
        .{
            Node{ .decl_binding = .{ .name = name_node, .decl_type = decl_type_node, .value = value_node } },
            Raw{ .tag = .decl_binding, .main_token = 0, .data = .{ .lhs = name_node, .rhs = 0 } },
        },
        .{
            Node{ .declaration = .{ .kind = .@"var", .list = &binding_list } },
            Raw{ .tag = .var_decl, .main_token = 0, .data = .{ .lhs = 0, .rhs = @intCast(binding_list.len) } },
        },
        .{
            Node{ .declaration = .{ .kind = .@"const", .list = &binding_list } },
            Raw{ .tag = .const_decl, .main_token = 0, .data = .{ .lhs = 0, .rhs = @intCast(binding_list.len) } },
        },
        .{
            Node{ .declaration = .{ .kind = .let, .list = &binding_list } },
            Raw{ .tag = .let_decl, .main_token = 0, .data = .{ .lhs = 0, .rhs = @intCast(binding_list.len) } },
        },
    };

    inline for (tests) |test_case| {
        try expectRawNode(test_case[1], test_case[0]);
    }
}

test "Pool ifs" {
    const expr_node = 1;
    const body_node = 2;
    const else_node = 3;

    try expectRawNode(Raw{
        .tag = .@"if",
        .main_token = 0,
        .data = .{
            .lhs = 0,
            .rhs = else_node,
        },
    }, Node{ .@"if" = .{ .expr = expr_node, .body = body_node, .@"else" = else_node } });
}

test "Pool switches" {
    const case_expr_node = 1;
    var case_body_node = [_]u32{2};
    var switch_cases = [_]Node.Index{ 3, 4 };

    const tests = .{
        .{
            Node{ .case = .{ .case = .{ .expr = case_expr_node, .body = &case_body_node } } },
            Raw{ .tag = .case, .main_token = 0, .data = .{ .lhs = case_expr_node, .rhs = case_body_node.len } },
        },
        .{
            Node{ .case = .{ .default = &case_body_node } },
            Raw{ .tag = .default, .main_token = 0, .data = .{ .lhs = 0, .rhs = @intCast(case_body_node.len) } },
        },
        .{
            Node{ .@"switch" = .{ .expr = case_expr_node, .cases = &switch_cases } },
            Raw{ .tag = .@"switch", .main_token = 0, .data = .{ .lhs = case_expr_node, .rhs = @intCast(switch_cases.len) } },
        },
    };

    inline for (tests) |test_case| {
        try expectRawNode(test_case[1], test_case[0]);
    }
}

test "Pool for loops" {
    const init_node = 1;
    const cond_node = 2;
    const post_node = 3;
    const body_node = 4;

    const tests = .{
        .{
            Node{ .@"for" = .{
                .classic = .{
                    .init = init_node,
                    .cond = cond_node,
                    .post = post_node,
                    .body = body_node,
                },
            } },
            Raw{ .tag = .@"for", .main_token = 0, .data = .{ .lhs = 0, .rhs = body_node } },
        },
        .{
            Node{ .@"for" = .{
                .in = .{
                    .left = init_node,
                    .right = cond_node,
                    .body = body_node,
                },
            } },
            Raw{ .tag = .for_in, .main_token = 0, .data = .{ .lhs = 0, .rhs = body_node } },
        },
        .{
            Node{ .@"for" = .{
                .of = .{
                    .left = init_node,
                    .right = cond_node,
                    .body = body_node,
                },
            } },
            Raw{ .tag = .for_of, .main_token = 0, .data = .{ .lhs = 0, .rhs = body_node } },
        },
        .{
            Node{ .@"while" = .{ .cond = cond_node, .body = body_node } },
            Raw{ .tag = .@"while", .main_token = 0, .data = .{ .lhs = cond_node, .rhs = body_node } },
        },
        .{
            Node{ .do_while = .{ .cond = cond_node, .body = body_node } },
            Raw{ .tag = .do_while, .main_token = 0, .data = .{ .lhs = cond_node, .rhs = body_node } },
        },
    };

    inline for (tests) |test_case| {
        try expectRawNode(test_case[1], test_case[0]);
    }
}

test "Pool blocks" {
    var stmts = [_]Node.Index{ 1, 2 };

    const test_cases = .{
        .{ Node{ .block = &stmts }, .block },
        .{ Node{ .array_literal = &stmts }, .array_literal },
        .{ Node{ .object_literal = &stmts }, .object_literal },
    };

    inline for (test_cases) |test_case| {
        try expectRawNode(Raw{
            .tag = test_case[1],
            .main_token = 0,
            .data = .{ .lhs = 0, .rhs = @intCast(stmts.len) },
        }, test_case[0]);
    }
}

test "Pool function expressions" {
    const param_name_node = 1;
    const param_type_node = 2;
    var params = [_]Node.Index{3};

    const name_node = 3;
    const body_node = 4;
    const return_type = 5;
    const async_func_data = .{ .flags = FunctionFlags.Async, .name = name_node, .params = &params, .body = body_node, .return_type = return_type };

    const tests = .{
        .{
            Node{ .function_param = .{ .node = param_name_node, .type = param_type_node } },
            Raw{ .tag = .function_param, .main_token = 0, .data = .{ .lhs = param_name_node, .rhs = param_type_node } },
        },
        .{
            Node{ .function_decl = async_func_data },
            Raw{ .tag = .func_decl, .main_token = 0, .data = .{ .lhs = name_node, .rhs = @intCast(params.len) } },
        },
        .{
            Node{ .function_expr = async_func_data },
            Raw{ .tag = .func_expr, .main_token = 0, .data = .{ .lhs = name_node, .rhs = @intCast(params.len) } },
        },
        .{
            Node{ .class_method = async_func_data },
            Raw{ .tag = .class_method, .main_token = 0, .data = .{ .lhs = name_node, .rhs = @intCast(params.len) } },
        },
        .{
            Node{ .object_method = async_func_data },
            Raw{ .tag = .object_method, .main_token = 0, .data = .{ .lhs = name_node, .rhs = @intCast(params.len) } },
        },
    };

    inline for (tests) |test_case| {
        try expectRawNode(test_case[1], test_case[0]);
    }
}

test "Pool arrow functions" {
    var params = [_]Node.Index{ 1, 2 };
    const body_node = 3;
    const return_type = 5;

    const tests = .{
        .{
            Node{ .arrow_function = .{ .type = .arrow, .params = &params, .body = body_node, .return_type = return_type } },
            Raw{ .tag = .arrow_function, .main_token = 0, .data = .{ .lhs = @intCast(params.len), .rhs = body_node } },
        },
        .{
            Node{ .arrow_function = .{ .type = .async_arrow, .params = &params, .body = body_node, .return_type = return_type } },
            Raw{ .tag = .async_arrow_function, .main_token = 0, .data = .{ .lhs = @intCast(params.len), .rhs = body_node } },
        },
    };
    inline for (tests) |test_case| {
        try expectRawNode(test_case[1], test_case[0]);
    }
}

test "Pool call expressions" {
    const main_node = 1;
    var params = [_]Node.Index{ 1, 2 };

    try expectRawNode(Raw{
        .tag = .call_expr,
        .main_token = 0,
        .data = .{ .lhs = main_node, .rhs = @intCast(params.len) },
    }, Node{ .call_expr = .{ .node = main_node, .params = &params } });
}

test "Pool binary" {
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
        .{ Node{ .coalesce = data }, .coalesce },
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
        .{ Node{ .coalesce_assign = data }, .coalesce_assign },
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

    inline for (tests) |test_case| {
        try expectRawNode(Raw{
            .tag = test_case[1],
            .main_token = 0,
            .data = .{
                .lhs = data.left,
                .rhs = data.right,
            },
        }, test_case[0]);
    }
}

test "Pool single node" {
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
        .{ Node{ .keyof = node }, .keyof },
        .{ Node{ .@"return" = node }, .@"return" },
    };

    inline for (tests) |test_case| {
        try expectRawNode(Raw{
            .tag = test_case[1],
            .main_token = 0,
            .data = .{ .lhs = node },
        }, test_case[0]);
    }
}

test "Pool empty" {
    const tests = .{
        .{ Node{ .@"break" = {} }, .@"break" },
        .{ Node{ .@"continue" = {} }, .@"continue" },
    };

    inline for (tests) |test_case| {
        try expectRawNode(Raw{
            .tag = test_case[1],
            .main_token = 0,
            .data = .{ .lhs = 0, .rhs = 0 },
        }, test_case[0]);
    }
}

test "Pool simple_value" {
    const data = Node.SimpleValue{
        .kind = .this,
    };
    const tests = .{
        .{ Node{ .simple_type = data }, .simple_type },
        .{ Node{ .simple_value = data }, .simple_value },
    };

    inline for (tests) |test_case| {
        try expectRawNode(Raw{
            .tag = test_case[1],
            .main_token = 0,
            .data = .{ .lhs = @intFromEnum(data.kind), .rhs = Node.Empty },
        }, test_case[0]);
    }
}

test "Pool object type" {
    const field_name = 1;
    const field_type = 2;
    var field_list = [_]Node.Index{ 3, 4 };

    const tests = .{
        .{
            Node{ .object_type_field = .{ .name = field_name, .type = field_type } },
            Raw{ .tag = .object_type_field, .main_token = 0, .data = .{ .lhs = field_name, .rhs = field_type } },
        },
        .{
            Node{ .object_type = &field_list },
            Raw{ .tag = .object_type, .main_token = 0, .data = .{ .lhs = 0, .rhs = @intCast(field_list.len) } },
        },
        .{
            Node{ .tuple_type = &field_list },
            Raw{ .tag = .tuple_type, .main_token = 0, .data = .{ .lhs = 0, .rhs = @intCast(field_list.len) } },
        },
    };

    inline for (tests) |test_case| {
        try expectRawNode(test_case[1], test_case[0]);
    }
}

test "Pool generic_type" {
    const name_node = 1;
    var params = [_]Node.Index{2};
    const data = Node.GenericType{
        .name = name_node,
        .params = &params,
    };
    const tests = .{
        .{ Node{ .generic_type = data }, .generic_type },
    };

    inline for (tests) |test_case| {
        try expectRawNode(Raw{
            .tag = test_case[1],
            .main_token = 0,
            .data = .{
                .lhs = name_node,
                .rhs = @intCast(params.len),
            },
        }, test_case[0]);
    }
}

test "Pool function_type" {
    var params = [_]Node.Index{2};
    var generic_params = [_]Node.Index{3};
    const return_type = 4;

    const tests = .{
        .{
            Node{ .function_type = .{ .generic_params = &generic_params, .params = &params, .return_type = return_type } },
            Raw{ .tag = .function_type, .main_token = 0, .data = .{ .lhs = generic_params.len + params.len, .rhs = return_type } },
        },
    };

    inline for (tests) |test_case| {
        try expectRawNode(test_case[1], test_case[0]);
    }
}

test "Pool interface_decl" {
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

    inline for (tests) |test_case| {
        try expectRawNode(Raw{
            .tag = test_case[1],
            .main_token = 0,
            .data = .{
                .lhs = name_node,
                .rhs = @intCast(extends.len + body.len),
            },
        }, test_case[0]);
    }
}
