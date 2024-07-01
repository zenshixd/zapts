const std = @import("std");
const ArrayList = std.ArrayList;

const MemoryPool = @import("memory_pool.zig").MemoryPool;
const Lexer = @import("lexer.zig");
const Closure = @import("closure.zig").Closure;
const Symbol = @import("symbols.zig").Symbol;
const TypeSymbol = @import("symbols.zig").TypeSymbol;
const TypeList = @import("symbols.zig").TypeList;
const ReferenceSymbol = @import("symbols.zig").ReferenceSymbol;
const diagnostics = @import("diagnostics.zig");

const consts = @import("consts.zig");
const Token = consts.Token;
const TokenType = consts.TokenType;
const TokenList = Lexer.TokenList;
const TokenListNode = Lexer.TokenListNode;

pub const ParserError = error{ SyntaxError, OutOfMemory, NoSpaceLeft };

pub const ASTNodeTag = enum {
    // data: binary
    import,
    // data: literal
    import_binding_default,
    // data: literal
    import_type_binding_default,
    // data: literal
    import_binding_namespace,
    // data: literal
    import_type_binding_namespace,
    // data: nodes
    import_named_bindings,
    // data: literal
    import_binding_named,
    // data: literal
    import_type_binding_named,
    // data: binary
    import_binding_comma,
    // data: literal
    import_from_path,
    // data: literal
    import_path,

    // data: node
    @"export",
    // data: binary
    export_from,
    // data: none
    export_from_all,
    // data: literal
    export_from_all_as,
    // data: literal
    export_path,
    // data: nodes
    export_named,
    // data: literal
    export_named_export,
    // data: literal
    export_named_alias,
    // data: binary
    export_named_export_as,
    // data: node
    export_default,

    // data: nodes
    var_decl,
    // data: nodes
    const_decl,
    // data: nodes
    let_decl,

    // data: nodes
    class_decl,
    // data: nodes
    class_expr,
    // data: literal
    class_name,
    // data: node
    class_super,
    // data: nodes
    class_body,
    // data: binary
    class_field,
    // data: node
    class_static_member,
    // data: nodes
    class_static_block,

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

    // data: nodes
    @"while",
    // data: nodes
    do_while,

    // data: nodes
    block,

    // data: nodes
    assignment,

    // data: nodes
    async_func_decl,
    func_decl,
    // data: literal
    func_decl_name,

    // data: nodes
    callable_arguments,
    // data: literal
    callable_argument,

    // data: nodes
    call_expr,
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
    // data: binary
    object_method,
    // data: node
    object_async_method,
    // data: node
    object_generator_method,
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

pub const ASTNodeData = union(enum) {
    literal: []const u8,
    node: *ASTNode,
    binary: struct {
        left: *ASTNode,
        right: *ASTNode,
    },
    nodes: ASTNodeList,
    none: void,
};

pub const ASTNodeList = struct {
    first: ?*ASTNode = null,
    last: ?*ASTNode = null,
    len: usize = 0,

    pub fn popFirst(list: *ASTNodeList) ?*ASTNode {
        const first = list.first orelse return null;
        list.remove(first);
        return first;
    }

    pub fn prepend(list: *ASTNodeList, new_node: *ASTNode) void {
        if (list.first) |first| {
            // Insert before first.
            list.insertBefore(first, new_node);
        } else {
            // Empty list.
            list.first = new_node;
            list.last = new_node;
            new_node.prev = null;
            new_node.next = null;

            list.len = 1;
        }
    }

    pub fn append(list: *ASTNodeList, new_node: *ASTNode) void {
        if (list.last) |last| {
            // Insert after last.
            list.insertAfter(last, new_node);
        } else {
            // Empty list.
            list.prepend(new_node);
        }
    }

    pub fn insertBefore(list: *ASTNodeList, node: *ASTNode, new_node: *ASTNode) void {
        new_node.next = node;
        if (node.prev) |prev_node| {
            // Intermediate node.
            new_node.prev = prev_node;
            prev_node.next = new_node;
        } else {
            // First element of the list.
            new_node.prev = null;
            list.first = new_node;
        }
        node.prev = new_node;

        list.len += 1;
    }

    pub fn insertAfter(list: *ASTNodeList, node: *ASTNode, new_node: *ASTNode) void {
        new_node.prev = node;
        if (node.next) |next_node| {
            // Intermediate node.
            new_node.next = next_node;
            next_node.prev = new_node;
        } else {
            // Last element of the list.
            new_node.next = null;
            list.last = new_node;
        }
        node.next = new_node;

        list.len += 1;
    }

    pub fn remove(list: *ASTNodeList, node: *ASTNode) void {
        if (node.prev) |prev_node| {
            // Intermediate node.
            prev_node.next = node.next;
        } else {
            // First element of the list.
            list.first = node.next;
        }

        if (node.next) |next_node| {
            // Intermediate node.
            next_node.prev = node.prev;
        } else {
            // Last element of the list.
            list.last = node.prev;
        }

        list.len -= 1;
        std.debug.assert(list.len == 0 or (list.first != null and list.last != null));
    }
};

pub const ASTNode = struct {
    tag: ASTNodeTag,
    data_type: *TypeSymbol,
    data: ASTNodeData,

    prev: ?*ASTNode = null,
    next: ?*ASTNode = null,

    fn repeatTab(writer: anytype, level: usize) !void {
        for (0..level) |_| {
            try writer.writeAll("\t");
        }
    }

    pub fn format(self: *ASTNode, comptime _: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        const level = options.width orelse 1;
        try writer.writeAll("ASTNode(.");
        try writer.writeAll(@tagName(self.tag));
        try writer.writeAll(", .type = ");
        try writer.writeAll(@tagName(self.data_type.*));
        try writer.writeAll(", .");
        try writer.writeAll(@tagName(self.data));
        switch (self.data) {
            .nodes => |nodes| {
                var next = nodes.first;
                try writer.writeAll(" = [\n");
                while (next) |node| {
                    try repeatTab(writer, level);
                    try writer.writeAll(".node = ");
                    try node.format("", .{ .width = level + 1 }, writer);
                    try writer.writeAll(",\n");
                    next = node.next;
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
            .none => {
                try writer.writeAll(" = none");
            },
        }
        try writer.writeAll(")");
    }
};

const Self = @This();

arena: std.heap.ArenaAllocator,
closure: Closure,
tokens: TokenList,
current_token: *TokenListNode,
checkpoint: ?*TokenListNode = null,
errors: std.ArrayList([]const u8),

fn create(self: *Self, T: type, default_value: T) !*T {
    const item = try self.arena.allocator().create(T);
    item.* = default_value;
    return item;
}

fn createEmptyNode(self: *Self, comptime error_msg: diagnostics.DiagnosticMessage, args: anytype) !*ASTNode {
    try self.emitError(error_msg, args);
    return try self.createNode(.none, .{ .none = {} });
}

pub fn init(allocator: std.mem.Allocator, buffer: []const u8) !Self {
    var lexer = Lexer.init(allocator, buffer);
    const tokens = try lexer.nextAll();

    return Self{
        .tokens = tokens,
        .current_token = tokens.first.?,
        .arena = std.heap.ArenaAllocator.init(allocator),
        .closure = try Closure.init(allocator),
        .errors = ArrayList([]const u8).init(allocator),
    };
}

pub fn deinit(self: *Self) void {
    self.arena.deinit();
    self.closure.deinit();
    self.errors.deinit();
}

pub fn parse(self: *Self) ParserError!*ASTNodeList {
    var nodes = try self.arena.allocator().create(ASTNodeList);
    nodes.* = ASTNodeList{};

    while (!self.match(TokenType.Eof)) {
        if (self.match(TokenType.NewLine) or self.match(TokenType.LineComment) or self.match(TokenType.MultilineComment)) {
            continue;
        }

        const node = try self.parseStatement();
        nodes.append(node);
    }

    return nodes;
}

fn createNode(self: *Self, tag: ASTNodeTag, data: ASTNodeData) !*ASTNode {
    const node = try self.arena.allocator().create(ASTNode);
    node.* = .{
        .tag = tag,
        .data_type = try self.getNodeType(tag, data),
        .data = data,
    };
    return node;
}

fn createTypedNode(self: *Self, tag: ASTNodeTag, data_type: *TypeSymbol, data: ASTNodeData) !*ASTNode {
    const node = try self.arena.allocator().create(ASTNode);
    node.* = .{
        .tag = tag,
        .data_type = data_type,
        .data = data,
    };
    return node;
}

fn token(self: Self) Token {
    return self.current_token.data;
}

fn advance(self: *Self) Token {
    const t = self.token();
    // std.debug.print("advancing from {}\n", .{t});
    if (self.current_token.next) |next| {
        self.current_token = next;
    }
    return t;
}

fn match(self: *Self, token_type: TokenType) bool {
    if (self.peekMatch(token_type)) {
        _ = self.advance();
        return true;
    }
    return false;
}

fn peekMatch(self: Self, token_type: TokenType) bool {
    return self.token().type == token_type;
}

fn consume(self: *Self, token_type: TokenType, comptime error_msg: diagnostics.DiagnosticMessage, args: anytype) ParserError!Token {
    if (self.token().type == token_type) {
        return self.advance();
    }

    try self.emitError(error_msg, args);
    // try self.emitError("Current token: {}", .{self.token()});
    return error.SyntaxError;
}

fn consumeOrNull(self: *Self, token_type: TokenType) ?Token {
    if (self.token().type == token_type) {
        return self.advance();
    }

    return null;
}

fn rewind(self: *Self) void {
    if (self.current_token.prev) |prev| {
        self.current_token = prev;
    }
}

fn getNodeType(self: *Self, tag: ASTNodeTag, data: ASTNodeData) !*TypeSymbol {
    return self.create(TypeSymbol, switch (tag) {
        .import => .{ .none = {} },
        .import_binding_comma => .{ .none = {} },
        .import_named_bindings => .{ .none = {} },
        .import_binding_named => .{ .unknown = {} },
        .import_type_binding_named => .{ .unknown = {} },
        .import_binding_default => .{ .unknown = {} },
        .import_type_binding_default => .{ .unknown = {} },
        .import_binding_namespace => .{ .unknown = {} },
        .import_type_binding_namespace => .{ .unknown = {} },
        .import_from_path => .{ .none = {} },
        .import_path => .{ .none = {} },
        .@"export" => .{ .none = {} },
        .export_from => .{ .none = {} },
        .export_from_all => .{ .none = {} },
        .export_from_all_as => .{ .none = {} },
        .export_named => .{ .none = {} },
        .export_named_export => .{ .none = {} },
        .export_named_alias => .{ .none = {} },
        .export_named_export_as => .{ .none = {} },
        .export_default => .{ .none = {} },
        .export_path => .{ .none = {} },
        .var_decl => .{ .none = {} },
        .const_decl => .{ .none = {} },
        .let_decl => .{ .none = {} },
        .async_func_decl => .{ .any = {} },
        .func_decl => .{ .any = {} },
        .func_decl_name => .{ .none = {} },
        .callable_arguments => .{ .any = {} },
        .callable_argument => .{ .any = {} },
        .class_decl => .{ .none = {} },
        .class_expr => .{ .none = {} },
        .class_name => .{ .none = {} },
        .class_super => .{ .none = {} },
        .class_body => .{ .none = {} },
        .class_field => .{ .none = {} },
        .class_static_member => .{ .none = {} },
        .class_static_block => .{ .none = {} },
        .@"if" => .{ .none = {} },
        .@"else" => .{ .none = {} },
        .@"switch" => .{ .none = {} },
        .case => .{ .none = {} },
        .default => .{ .none = {} },
        .@"break" => .{ .none = {} },
        .@"continue" => .{ .none = {} },
        .@"for" => .{ .none = {} },
        .for_classic => .{ .none = {} },
        .for_in => .{ .none = {} },
        .for_of => .{ .none = {} },
        .@"while" => .{ .none = {} },
        .do_while => .{ .none = {} },
        .block => .{ .none = {} },
        .call_expr => .{ .any = {} },
        .comma => .{ .unknown = {} },
        .this => .{ .none = {} },
        .true => .{ .true = {} },
        .false => .{ .false = {} },
        .null => .{ .null = {} },
        .undefined => .{ .undefined = {} },
        .number => .{ .number = {} },
        .bigint => .{ .bigint = {} },
        .string => .{ .string = {} },
        .identifier => .{ .any = {} },
        .computed_identifier => .{ .any = {} },
        .private_identifier => .{ .any = {} },
        .none => .{ .none = {} },
        .unknown => .{ .none = {} },
        .ternary => .{ .none = {} },
        .ternary_then => .{ .none = {} },
        .grouping => return try self.getNodeType(data.node.tag, data.node.data),
        .assignment => return try self.getNodeType(data.binary.right.tag, data.binary.right.data),
        .plus_assign => return try self.getNodeType(data.binary.right.tag, data.binary.right.data),
        .minus_assign => return try self.getNodeType(data.binary.right.tag, data.binary.right.data),
        .multiply_assign => return try self.getNodeType(data.binary.right.tag, data.binary.right.data),
        .div_assign => return try self.getNodeType(data.binary.right.tag, data.binary.right.data),
        .modulo_assign => return try self.getNodeType(data.binary.right.tag, data.binary.right.data),
        .exp_assign => return try self.getNodeType(data.binary.right.tag, data.binary.right.data),
        .and_assign => return try self.getNodeType(data.binary.right.tag, data.binary.right.data),
        .or_assign => return try self.getNodeType(data.binary.right.tag, data.binary.right.data),
        .bitwise_and_assign => return try self.getNodeType(data.binary.right.tag, data.binary.right.data),
        .bitwise_or_assign => return try self.getNodeType(data.binary.right.tag, data.binary.right.data),
        .bitwise_xor_assign => return try self.getNodeType(data.binary.right.tag, data.binary.right.data),
        .bitwise_shift_left_assign => return try self.getNodeType(data.binary.right.tag, data.binary.right.data),
        .bitwise_shift_right_assign => return try self.getNodeType(data.binary.right.tag, data.binary.right.data),
        .bitwise_unsigned_right_shift_assign => return try self.getNodeType(data.binary.right.tag, data.binary.right.data),
        .plusplus_pre => .{ .number = {} },
        .plusplus_post => .{ .number = {} },
        .minusminus_pre => .{ .number = {} },
        .minusminus_post => .{ .number = {} },
        .not => .{ .boolean = {} },
        .bitwise_negate => .{ .number = {} },
        .minus => .{ .number = {} },
        .minus_expr => .{ .number = {} },
        .plus => .{ .number = {} },
        .plus_expr => .{ .number = {} },
        .multiply_expr => .{ .number = {} },
        .exp_expr => .{ .number = {} },
        .div_expr => .{ .number = {} },
        .modulo_expr => .{ .number = {} },
        .bitwise_and => .{ .number = {} },
        .bitwise_or => .{ .number = {} },
        .bitwise_xor => .{ .number = {} },
        .bitwise_shift_left => .{ .number = {} },
        .bitwise_shift_right => .{ .number = {} },
        .bitwise_unsigned_right_shift => .{ .number = {} },
        .instanceof => .{ .boolean = {} },
        .in => .{ .boolean = {} },
        .spread => return try self.getNodeType(data.node.tag, data.node.data),
        .typeof => .{ .string = {} },
        .void => .{ .none = {} },
        .delete => .{ .boolean = {} },
        .object_literal => .{ .unknown = {} },
        .object_literal_field => .{ .none = {} },
        .object_literal_field_shorthand => .{ .none = {} },
        .object_method => .{ .none = {} },
        .object_async_method => .{ .none = {} },
        .object_generator_method => .{ .none = {} },
        .object_getter => .{ .none = {} },
        .object_setter => .{ .none = {} },
        .property_access => return try self.getNodeType(data.binary.right.tag, data.binary.right.data),
        .optional_property_access => return try self.getNodeType(data.binary.right.tag, data.binary.right.data),
        .array_literal => .{ .unknown = {} },
        .index_access => .{ .unknown = {} },
        .eq => .{ .boolean = {} },
        .eqq => .{ .boolean = {} },
        .neq => .{ .boolean = {} },
        .neqq => .{ .boolean = {} },
        .@"and" => .{ .boolean = {} },
        .@"or" => .{ .boolean = {} },
        .gt => .{ .boolean = {} },
        .gte => .{ .boolean = {} },
        .lt => .{ .boolean = {} },
        .lte => .{ .boolean = {} },
    });
}

fn emitError(self: *Self, comptime error_msg: diagnostics.DiagnosticMessage, args: anytype) !void {
    std.debug.print("TS" ++ error_msg.code ++ ": " ++ error_msg.message ++ "\n", args);
    std.debug.print("Token {}\n", .{self.token()});
    try self.errors.append(
        try std.fmt.allocPrint(
            self.arena.allocator(),
            "TS" ++ error_msg.code ++ ": " ++ error_msg.message,
            args,
        ),
    );
    try self.errors.append(try std.fmt.allocPrint(self.arena.allocator(), "Token: {}", .{self.token()}));
}

fn parseStatement(self: *Self) ParserError!*ASTNode {
    while (self.match(TokenType.NewLine)) {}

    const node = try self.parseBlock() orelse
        try self.parseDeclaration() orelse
        try self.parseClassDecl() orelse
        try self.parseImportStatement() orelse
        try self.parseExportStatement() orelse
        try self.parseEmptyStatement() orelse
        try self.parseIfStatement() orelse
        try self.parseBreakableStatement() orelse
        try self.parseExpression();

    if (needsSemicolon(node)) {
        _ = try self.consume(TokenType.Semicolon, diagnostics.ARG_expected, .{";"});
    }
    return node;
}

fn parseImportStatement(self: *Self) ParserError!?*ASTNode {
    if (!self.match(TokenType.Import)) {
        return null;
    }
    if (self.consumeOrNull(TokenType.StringConstant)) |path| {
        return try self.createNode(
            .import,
            .{ .binary = .{
                .left = try self.createNode(.none, .{ .none = {} }),
                .right = try self.createNode(
                    .import_path,
                    .{ .literal = path.value.? },
                ),
            } },
        );
    }

    const bindings = try self.parseImportClause();

    const path_token = try self.parseFromClause();
    if (path_token == null) {
        try self.emitError(diagnostics.ARG_expected, .{"from"});
    }
    return try self.createNode(
        .import,
        .{ .binary = .{
            .left = bindings.?,
            .right = try self.createNode(
                .import_from_path,
                .{ .literal = if (path_token == null) "" else path_token.?.value.? },
            ),
        } },
    );
}

fn parseImportClause(self: *Self) !?*ASTNode {
    const default_as_type = self.match(TokenType.Type);

    // zig fmt: off
    var bindings: ?*ASTNode = try self.parseImportDefaultBinding(default_as_type)
        orelse try self.parseImportNamespaceBinding(default_as_type)
        orelse try self.parseImportNamedBindings(default_as_type);
    // zig fmt: on

    if (bindings == null) {
        try self.emitError(diagnostics.declaration_or_statement_expected, .{});
        return null;
    }

    if (bindings.?.tag == .import_binding_default) {
        if (self.match(TokenType.Comma)) {
            const additional_bindings = try self.parseImportNamespaceBinding(default_as_type) orelse try self.parseImportNamedBindings(default_as_type);

            if (additional_bindings == null) {
                try self.emitError(diagnostics.ARG_expected, .{"{"});
            } else {
                bindings = try self.createNode(
                    .import_binding_comma,
                    .{ .binary = .{
                        .left = bindings.?,
                        .right = additional_bindings.?,
                    } },
                );
            }
        } else if (!self.peekMatch(TokenType.From)) {
            try self.emitError(diagnostics.ARG_expected, .{"{"});
        }
    }

    return bindings;
}

fn parseImportDefaultBinding(self: *Self, default_as_type: bool) !?*ASTNode {
    if (self.consumeOrNull(TokenType.Identifier)) |identifier| {
        const tag: ASTNodeTag = if (default_as_type or self.match(TokenType.Type)) .import_type_binding_default else .import_binding_default;
        return try self.createNode(
            tag,
            .{ .literal = identifier.value.? },
        );
    }

    return null;
}

fn parseImportNamespaceBinding(self: *Self, default_as_type: bool) !?*ASTNode {
    if (!self.match(TokenType.Star)) {
        return null;
    }

    _ = try self.consume(TokenType.As, diagnostics.ARG_expected, .{"as"});
    const identifier = try self.consume(TokenType.Identifier, diagnostics.identifier_expected, .{});

    const tag: ASTNodeTag = if (default_as_type) .import_type_binding_namespace else .import_binding_namespace;
    return try self.createNode(
        tag,
        .{ .literal = identifier.value.? },
    );
}

fn parseImportNamedBindings(self: *Self, default_as_type: bool) !?*ASTNode {
    if (!self.match(TokenType.OpenCurlyBrace)) {
        return null;
    }

    var named_bindings = ASTNodeList{};

    while (true) {
        const as_type = default_as_type or self.match(TokenType.Type);

        if (self.consumeOrNull(TokenType.Identifier)) |identifier| {
            named_bindings.append(try self.createNode(
                if (as_type) .import_type_binding_named else .import_binding_named,
                .{ .literal = identifier.value.? },
            ));
        }

        if (self.match(TokenType.CloseCurlyBrace)) {
            break;
        }
        _ = try self.consume(TokenType.Comma, diagnostics.ARG_expected, .{","});
    }

    return try self.createNode(
        .import_named_bindings,
        .{ .nodes = named_bindings },
    );
}

fn parseExportStatement(self: *Self) ParserError!?*ASTNode {
    if (!self.match(TokenType.Export)) {
        return null;
    }

    const node = try self.parseExportFromClause() orelse
        try self.parseDeclaration() orelse
        try self.parseClassDecl() orelse
        try self.parseDefaultExport() orelse
        unreachable;

    return try self.createNode(
        .@"export",
        .{ .node = node },
    );
}

fn parseExportFromClause(self: *Self) ParserError!?*ASTNode {
    var node: *ASTNode = undefined;
    if (self.match(TokenType.Star)) {
        if (self.match(TokenType.As)) {
            const identifier = try self.consume(TokenType.Identifier, diagnostics.identifier_expected, .{});
            node = try self.createNode(
                .export_from_all_as,
                .{ .literal = identifier.value.? },
            );
        } else {
            node = try self.createNode(
                .export_from_all,
                .{ .none = {} },
            );
        }
    } else if (self.match(TokenType.OpenCurlyBrace)) {
        var exports = ASTNodeList{};
        var has_comma = true;
        while (true) {
            if (self.match(TokenType.CloseCurlyBrace)) {
                break;
            }
            if (!has_comma) {
                try self.emitError(diagnostics.ARG_expected, .{","});
            }
            const identifier = try self.consume(TokenType.Identifier, diagnostics.identifier_expected, .{});
            var named_export: *ASTNode = try self.createNode(
                .export_named_export,
                .{ .literal = identifier.value.? },
            );
            if (self.match(TokenType.As)) {
                const alias = try self.consume(TokenType.Identifier, diagnostics.identifier_expected, .{});
                named_export = try self.createNode(
                    .export_named_export_as,
                    .{ .binary = .{
                        .left = named_export,
                        .right = try self.createNode(
                            .export_named_alias,
                            .{ .literal = alias.value.? },
                        ),
                    } },
                );
            }
            has_comma = self.consumeOrNull(TokenType.Comma) != null;
            exports.append(named_export);
        }

        node = try self.createNode(
            .export_named,
            .{ .nodes = exports },
        );
    } else {
        return null;
    }

    const path_token = try self.parseFromClause();
    const right = try self.createNode(
        .export_path,
        if (path_token == null)
            .{ .none = {} }
        else
            .{ .literal = path_token.?.value.? },
    );
    return try self.createNode(.export_from, .{
        .binary = .{
            .left = node,
            .right = right,
        },
    });
}

fn parseDefaultExport(self: *Self) ParserError!?*ASTNode {
    if (!self.match(TokenType.Default)) {
        return null;
    }

    return try self.parseFunctionDecl() orelse try self.parseAssignment();
}

fn parseFromClause(self: *Self) ParserError!?Token {
    if (!self.match(TokenType.From)) {
        return null;
    }
    return try self.consume(TokenType.StringConstant, diagnostics.string_literal_expected, .{});
}

fn parseClassDecl(self: *Self) ParserError!?*ASTNode {
    if (!self.match(TokenType.Class)) {
        return null;
    }
    var nodes = ASTNodeList{};
    const name = try self.consume(TokenType.Identifier, diagnostics.identifier_expected, .{});
    nodes.append(try self.createNode(.class_name, .{ .literal = name.value.? }));
    if (self.match(TokenType.Extends)) {
        const super_class = try self.parseCallableExpression() orelse try self.createEmptyNode(diagnostics.expression_expected, .{});
        nodes.append(try self.createNode(.class_super, .{ .node = super_class }));
    }
    var body = ASTNodeList{};
    _ = try self.consume(TokenType.OpenCurlyBrace, diagnostics.ARG_expected, .{"{"});
    while (true) {
        if (self.match(TokenType.CloseCurlyBrace)) {
            break;
        }

        body.append(try self.parseClassMember());
    }
    nodes.append(try self.createNode(.class_body, .{ .nodes = body }));
    return try self.createNode(
        .class_decl,
        .{ .nodes = nodes },
    );
}

fn parseClassStaticMember(self: *Self) ParserError!*ASTNode {
    if (self.match(TokenType.Static)) {
        return try self.createNode(.class_static_member, .{ .node = try self.parseClassMember() });
    }
    return try self.parseClassMember();
}

fn parseClassMember(self: *Self) ParserError!*ASTNode {
    return try self.parseMethodGetter() orelse
        try self.parseMethodSetter() orelse
        try self.parseMethodGenerator() orelse
        try self.parseAsyncGeneratorMethod() orelse
        try self.parseMethod() orelse
        unreachable;
    // try self.parseClassMemberAssignment();
}

fn parseAsyncGeneratorMethod(self: *Self) ParserError!?*ASTNode {
    if (!self.match(TokenType.Async)) {
        return null;
    }

    return try self.createNode(.object_async_method, .{
        .node = try self.parseMethodGenerator() orelse
            try self.parseMethod() orelse
            unreachable,
    });
}

fn parseMethodGenerator(self: *Self) ParserError!?*ASTNode {
    if (!self.match(TokenType.Star)) {
        return null;
    }

    return try self.createNode(.object_generator_method, .{ .node = try self.parseMethod() orelse return null });
}

fn parseMethod(self: *Self) ParserError!?*ASTNode {
    const elem_name = try self.parseObjectElementName();
    if (elem_name == null) {
        return null;
    }

    if (self.match(TokenType.OpenParen)) {
        var nodes = ASTNodeList{};
        nodes.append(elem_name.?);
        nodes.append(try self.parseFunctionArguments());
        const return_type = try self.parseOptionalDataType(.{ .any = {} });
        var body = try self.parseBlock();
        if (body == null) {
            try self.emitError(diagnostics.ARG_expected, .{"{"});
            body = try self.createNode(.none, .{ .none = {} });
        }
        nodes.append(body.?);
        return try self.createTypedNode(.object_method, return_type, .{ .nodes = nodes });
    }

    return try self.parseClassMemberAssignment(elem_name.?);
}

fn parseClassMemberAssignment(self: *Self, elem_name: *ASTNode) ParserError!*ASTNode {
    const data_type = try self.parseOptionalDataType(.{ .any = {} });
    var right: *ASTNode = undefined;
    if (self.match(TokenType.Equal)) {
        right = try self.parseAssignment();
    } else {
        right = try self.createNode(.none, .{ .none = {} });
    }

    const node = try self.createTypedNode(
        .class_field,
        data_type,
        .{
            .binary = .{
                .left = elem_name,
                .right = right,
            },
        },
    );
    _ = try self.consume(TokenType.Semicolon, diagnostics.ARG_expected, .{";"});
    return node;
}

fn parseMethodGetter(self: *Self) ParserError!?*ASTNode {
    if (!self.match(TokenType.Get)) {
        return null;
    }
    const elem_name = try self.parseObjectElementName();

    if (elem_name == null) {
        self.rewind();
        return try self.parseMethod();
    }

    var nodes = ASTNodeList{};
    nodes.append(elem_name.?);
    _ = try self.consume(TokenType.OpenParen, diagnostics.ARG_expected, .{"("});
    nodes.append(try self.parseFunctionArguments());
    const return_type = try self.parseOptionalDataType(.{ .any = {} });
    var body = try self.parseBlock();
    if (body == null) {
        try self.emitError(diagnostics.ARG_expected, .{"{"});
        body = try self.createNode(.none, .{ .none = {} });
    }
    nodes.append(body.?);

    return try self.createTypedNode(
        .object_getter,
        return_type,
        .{ .nodes = nodes },
    );
}

fn parseMethodSetter(self: *Self) ParserError!?*ASTNode {
    if (!self.match(TokenType.Set)) {
        return null;
    }
    const elem_name = try self.parseObjectElementName();

    if (elem_name == null) {
        self.rewind();
        return try self.parseMethod();
    }

    var nodes = ASTNodeList{};
    nodes.append(elem_name.?);
    _ = try self.consume(TokenType.OpenParen, diagnostics.ARG_expected, .{"("});
    nodes.append(try self.parseFunctionArguments());
    const return_type = try self.parseOptionalDataType(.{ .any = {} });
    var body = try self.parseBlock();
    if (body == null) {
        try self.emitError(diagnostics.ARG_expected, .{"{"});
        body = try self.createNode(.none, .{ .none = {} });
    }
    nodes.append(body.?);

    return try self.createTypedNode(
        .object_setter,
        return_type,
        .{ .nodes = nodes },
    );
}

fn parseObjectElementName(self: *Self) ParserError!?*ASTNode {
    switch (self.token().type) {
        .Identifier => {
            const name = self.advance();
            return try self.createNode(.identifier, .{ .literal = name.value.? });
        },
        .StringConstant => {
            const name = self.advance();
            return try self.createNode(.string, .{ .literal = name.value.? });
        },
        .NumberConstant => {
            const name = self.advance();
            return try self.createNode(.number, .{ .literal = name.value.? });
        },
        .BigIntConstant => {
            const name = self.advance();
            return try self.createNode(.bigint, .{ .literal = name.value.? });
        },
        .OpenSquareBracket => {
            _ = self.advance();
            const node = try self.parseAssignment();
            _ = try self.consume(TokenType.CloseSquareBracket, diagnostics.ARG_expected, .{"]"});
            return self.createNode(.computed_identifier, .{ .node = node });
        },
        .Hash => {
            _ = self.advance();
            const name = try self.consume(TokenType.Identifier, diagnostics.identifier_expected, .{});
            return try self.createNode(.private_identifier, .{ .literal = name.value.? });
        },
        else => {
            return null;
        },
    }
}

fn parseFunctionDecl(self: *Self) ParserError!?*ASTNode {
    var is_async = false;
    if (self.match(TokenType.Async)) {
        is_async = true;
    }

    if (!self.match(TokenType.Function)) {
        if (is_async) {
            self.rewind();
        }
        return null;
    }
    var name: []const u8 = "(anonymous)";
    var nodes = ASTNodeList{};

    if (self.consumeOrNull(TokenType.Identifier)) |identifier| {
        name = identifier.value.?;
    }

    nodes.append(try self.createNode(
        .func_decl_name,
        .{ .literal = name },
    ));

    _ = try self.consume(TokenType.OpenParen, diagnostics.ARG_expected, .{"("});

    nodes.append(try self.parseFunctionArguments());

    const tag: ASTNodeTag = if (is_async) .async_func_decl else .func_decl;
    const return_type = try self.parseOptionalDataType(.{ .any = {} });

    if (try self.parseBlock()) |block| {
        nodes.append(block);
    } else {
        try self.emitError(diagnostics.ARG_expected, .{"{"});
    }
    return try self.createTypedNode(
        tag,
        return_type,
        .{ .nodes = nodes },
    );
}

fn parseFunctionArguments(self: *Self) ParserError!*ASTNode {
    var args = ASTNodeList{};
    var has_comma = true;
    while (true) {
        if (self.match(TokenType.CloseParen)) {
            break;
        }

        if (self.consumeOrNull(TokenType.Identifier)) |identifier| {
            if (!has_comma) {
                try self.emitError(diagnostics.ARG_expected, .{","});
            }
            const identifier_data_type: *TypeSymbol = try self.parseOptionalDataType(.{ .any = {} });
            args.append(try self.createTypedNode(
                .callable_argument,
                identifier_data_type,
                .{ .literal = identifier.value.? },
            ));
        } else {
            args.append(try self.createNode(.none, .{ .none = {} }));
        }

        has_comma = self.match(TokenType.Comma);
    }
    return try self.createNode(.callable_arguments, .{ .nodes = args });
}

fn parseBlock(self: *Self) ParserError!?*ASTNode {
    if (!self.match(TokenType.OpenCurlyBrace)) {
        return null;
    }

    self.closure.new_closure();
    var statements = ASTNodeList{};

    while (true) {
        if (self.match(TokenType.Eof)) {
            try self.emitError(diagnostics.ARG_expected, .{"}"});
            return error.SyntaxError;
        }

        if (self.match(TokenType.CloseCurlyBrace)) {
            break;
        }

        const statement = try self.parseStatement();
        statements.append(statement);

        while (self.match(TokenType.NewLine)) {}

        if (self.match(TokenType.CloseCurlyBrace)) {
            break;
        }
    }

    self.closure.close_closure();

    return self.createNode(
        .block,
        .{ .nodes = statements },
    );
}

fn parseDeclaration(self: *Self) ParserError!?*ASTNode {
    const tag: ASTNodeTag = switch (self.token().type) {
        .Var => .var_decl,
        .Let => .let_decl,
        .Const => .const_decl,
        .Async, .Function => return self.parseFunctionDecl(),
        else => return null,
    };
    _ = self.advance();

    var nodes = ASTNodeList{};

    while (true) {
        const identifier = try self.consume(TokenType.Identifier, diagnostics.identifier_expected, .{});

        const identifier_data_type = try self.parseOptionalDataType(.{ .none = {} });
        var node = try self.createTypedNode(
            .identifier,
            identifier_data_type,
            .{ .literal = identifier.value.? },
        );
        if (self.match(TokenType.Equal)) {
            const right = try self.parseAssignment();
            node = try self.createTypedNode(
                .assignment,
                switch (identifier_data_type.*) {
                    .none => right.data_type,
                    else => identifier_data_type,
                },
                .{
                    .binary = .{
                        .left = node,
                        .right = right,
                    },
                },
            );
        }

        nodes.append(node);
        _ = try self.closure.addSymbol(identifier.value.?, .{
            .declaration = .{
                .type = identifier_data_type,
                .name = identifier.value.?,
            },
        });

        if (!self.match(TokenType.Comma)) {
            break;
        }
    }

    return try self.createNode(
        tag,
        .{ .nodes = nodes },
    );
}

fn parseEmptyStatement(self: *Self) ParserError!?*ASTNode {
    if (!self.match(TokenType.Semicolon)) {
        return null;
    }

    return self.createNode(
        .none,
        .{ .none = {} },
    );
}

fn parseIfStatement(self: *Self) ParserError!?*ASTNode {
    if (!self.match(TokenType.If)) {
        return null;
    }

    _ = try self.consume(TokenType.OpenParen, diagnostics.ARG_expected, .{"("});
    const left = try self.parseExpression();
    _ = try self.consume(TokenType.CloseParen, diagnostics.ARG_expected, .{")"});

    const node = try self.createNode(
        .@"if",
        .{
            .binary = .{
                .left = left,
                .right = try self.parseStatement(),
            },
        },
    );

    if (!self.match(TokenType.Else)) {
        return node;
    }

    const else_node = try self.parseStatement();

    return try self.createNode(
        .@"else",
        .{
            .binary = .{
                .left = node,
                .right = else_node,
            },
        },
    );
}

fn parseBreakableStatement(self: *Self) ParserError!?*ASTNode {
    return try parseDoWhileStatement(self) orelse try parseWhileStatement(self) orelse try parseForStatement(self);
}

fn parseDoWhileStatement(self: *Self) ParserError!?*ASTNode {
    if (!self.match(TokenType.Do)) {
        return null;
    }

    const node = try self.parseStatement();
    _ = try self.consume(TokenType.While, diagnostics.ARG_expected, .{"while"});
    _ = try self.consume(TokenType.OpenParen, diagnostics.ARG_expected, .{"("});
    const condition = try self.parseExpression();
    _ = try self.consume(TokenType.CloseParen, diagnostics.ARG_expected, .{")"});
    _ = try self.consume(TokenType.Semicolon, diagnostics.ARG_expected, .{";"});

    return try self.createNode(
        .do_while,
        .{
            .binary = .{
                .left = condition,
                .right = node,
            },
        },
    );
}

fn parseWhileStatement(self: *Self) ParserError!?*ASTNode {
    if (!self.match(TokenType.While)) {
        return null;
    }

    _ = try self.consume(TokenType.OpenParen, diagnostics.ARG_expected, .{"("});
    const condition = try self.parseExpression();
    _ = try self.consume(TokenType.CloseParen, diagnostics.ARG_expected, .{")"});

    return try self.createNode(
        .@"while",
        .{
            .binary = .{
                .left = condition,
                .right = try self.parseStatement(),
            },
        },
    );
}

fn parseForStatement(self: *Self) ParserError!?*ASTNode {
    if (!self.match(TokenType.For)) {
        return null;
    }

    _ = try self.consume(TokenType.OpenParen, diagnostics.ARG_expected, .{"("});
    const init_node = try self.parseForInitExpression();

    const for_inner = try self.parseForClassicStatement(init_node) orelse try self.parseForInStatement(init_node) orelse try self.parseForOfStatement(init_node);

    if (for_inner == null) {
        try self.emitError(diagnostics.ARG_expected, .{","});
        return error.SyntaxError;
    }

    return self.createNode(
        .@"for",
        .{
            .binary = .{
                .left = for_inner.?,
                .right = try self.parseStatement(),
            },
        },
    );
}

fn parseForClassicStatement(self: *Self, init_node: *ASTNode) ParserError!?*ASTNode {
    if (!self.match(TokenType.Semicolon)) {
        return null;
    }

    var nodes = ASTNodeList{};

    nodes.append(init_node);
    nodes.append(try self.parseExpression());
    _ = try self.consume(TokenType.Semicolon, diagnostics.ARG_expected, .{";"});
    nodes.append(try self.parseExpression());
    _ = try self.consume(TokenType.CloseParen, diagnostics.ARG_expected, .{")"});

    return try self.createNode(
        .for_classic,
        .{ .nodes = nodes },
    );
}

fn parseForInStatement(self: *Self, init_node: *ASTNode) ParserError!?*ASTNode {
    if (!self.match(TokenType.In)) {
        return null;
    }

    const right = try self.parseExpression();
    _ = try self.consume(TokenType.CloseParen, diagnostics.ARG_expected, .{")"});

    return self.createNode(
        .for_in,
        .{
            .binary = .{
                .left = init_node,
                .right = right,
            },
        },
    );
}

fn parseForOfStatement(self: *Self, init_node: *ASTNode) ParserError!?*ASTNode {
    if (!self.match(TokenType.Of)) {
        return null;
    }

    const right = try self.parseExpression();
    _ = try self.consume(TokenType.CloseParen, diagnostics.ARG_expected, .{")"});

    return self.createNode(
        .for_of,
        .{
            .binary = .{
                .left = init_node,
                .right = right,
            },
        },
    );
}

fn parseForInitExpression(self: *Self) ParserError!*ASTNode {
    if (self.match(TokenType.Semicolon)) {
        return self.createNode(.none, .{ .none = {} });
    }

    return try self.parseDeclaration() orelse try self.parseExpression();
}

fn parseExpression(self: *Self) ParserError!*ASTNode {
    var node = try self.parseAssignment();
    while (self.match(TokenType.Comma)) {
        node = try self.createNode(
            .comma,
            .{
                .binary = .{
                    .left = node,
                    .right = try self.parseAssignment(),
                },
            },
        );
    }

    return node;
}

fn parseAssignment(self: *Self) ParserError!*ASTNode {
    var node = try self.parseConditionalExpression();

    const tag: ASTNodeTag = switch (self.token().type) {
        .Equal => .assignment,
        .PlusEqual => .plus_assign,
        .MinusEqual => .minus_assign,
        .StarEqual => .multiply_assign,
        .StarStarEqual => .exp_assign,
        .SlashEqual => .div_assign,
        .PercentEqual => .modulo_assign,
        .AmpersandEqual => .bitwise_and_assign,
        .BarEqual => .bitwise_or_assign,
        .CaretEqual => .bitwise_xor_assign,
        .BarBarEqual => .or_assign,
        .AmpersandAmpersandEqual => .and_assign,
        .GreaterThanGreaterThanEqual => .bitwise_shift_right_assign,
        .GreaterThanGreaterThanGreaterThanEqual => .bitwise_unsigned_right_shift_assign,
        .LessThanLessThanEqual => .bitwise_shift_left_assign,
        else => return node,
    };
    _ = self.advance();
    node = try self.createNode(
        tag,
        .{
            .binary = .{
                .left = node,
                .right = try self.parseAssignment(),
            },
        },
    );

    return node;
}

fn parseConditionalExpression(self: *Self) ParserError!*ASTNode {
    var node = try self.parseShortCircuitExpression();

    if (self.match(TokenType.QuestionMark)) {
        const true_expr = try self.parseAssignment();
        _ = try self.consume(TokenType.Colon, diagnostics.ARG_expected, .{":"});
        const false_expr = try self.parseAssignment();
        const ternary_then = try self.createNode(
            .ternary_then,
            .{
                .binary = .{
                    .left = true_expr,
                    .right = false_expr,
                },
            },
        );
        node = try self.createNode(
            .ternary,
            .{ .binary = .{
                .left = node,
                .right = ternary_then,
            } },
        );
    }

    return node;
}

fn parseShortCircuitExpression(self: *Self) ParserError!*ASTNode {
    return try self.parseLogicalOr();
}

fn parseLogicalOr(self: *Self) ParserError!*ASTNode {
    var node = try self.parseLogicalAnd();

    while (self.match(TokenType.BarBar)) {
        node = try self.createNode(
            .@"or",
            .{
                .binary = .{
                    .left = node,
                    .right = try self.parseLogicalAnd(),
                },
            },
        );
    }

    return node;
}

fn parseLogicalAnd(self: *Self) ParserError!*ASTNode {
    var node = try self.parseBitwiseOr();
    while (self.match(TokenType.AmpersandAmpersand)) {
        node = try self.createNode(
            .@"and",
            .{
                .binary = .{
                    .left = node,
                    .right = try self.parseBitwiseOr(),
                },
            },
        );
    }

    return node;
}

fn parseBitwiseOr(self: *Self) ParserError!*ASTNode {
    var node = try self.parseBitwiseXor();

    while (self.match(TokenType.Bar)) {
        const right = try self.parseBitwiseXor();
        node = try self.createNode(
            .bitwise_or,
            .{
                .binary = .{
                    .left = node,
                    .right = right,
                },
            },
        );
    }

    return node;
}

fn parseBitwiseXor(self: *Self) ParserError!*ASTNode {
    var node = try self.parseBitwiseAnd();

    while (self.match(TokenType.Caret)) {
        const right = try self.parseBitwiseAnd();
        node = try self.createNode(
            .bitwise_xor,
            .{
                .binary = .{
                    .left = node,
                    .right = right,
                },
            },
        );
    }

    return node;
}

fn parseBitwiseAnd(self: *Self) ParserError!*ASTNode {
    var node = try self.parseEquality();

    while (self.match(TokenType.Ampersand)) {
        const right = try self.parseEquality();
        node = try self.createNode(
            .bitwise_and,
            .{
                .binary = .{
                    .left = node,
                    .right = right,
                },
            },
        );
    }

    return node;
}

fn parseEquality(self: *Self) ParserError!*ASTNode {
    var node = try self.parseRelational();

    while (true) {
        const tag: ASTNodeTag = switch (self.token().type) {
            .EqualEqual => .eq,
            .EqualEqualEqual => .eqq,
            .ExclamationMarkEqual => .neq,
            .ExclamationMarkEqualEqual => .neqq,
            else => break,
        };
        _ = self.advance();
        node = try self.createNode(
            tag,
            .{
                .binary = .{
                    .left = node,
                    .right = try self.parseRelational(),
                },
            },
        );
    }

    return node;
}

fn parseRelational(self: *Self) ParserError!*ASTNode {
    var node = try self.parseShift();

    while (true) {
        const tag: ASTNodeTag = switch (self.token().type) {
            .GreaterThan => .gt,
            .GreaterThanEqual => .gte,
            .LessThan => .lt,
            .LessThanEqual => .lte,
            .Instanceof => .instanceof,
            .In => .in,
            else => break,
        };
        _ = self.advance();
        node = try self.createNode(
            tag,
            .{
                .binary = .{
                    .left = node,
                    .right = try self.parseShift(),
                },
            },
        );
    }

    return node;
}

fn parseShift(self: *Self) ParserError!*ASTNode {
    var node = try self.parseAdditive();

    while (true) {
        const tag: ASTNodeTag = switch (self.token().type) {
            .GreaterThanGreaterThan => .bitwise_shift_right,
            .GreaterThanGreaterThanGreaterThan => .bitwise_unsigned_right_shift,
            .LessThanLessThan => .bitwise_shift_left,
            else => break,
        };
        _ = self.advance();
        node = try self.createNode(
            tag,
            .{
                .binary = .{
                    .left = node,
                    .right = try self.parseAdditive(),
                },
            },
        );
    }

    return node;
}

fn parseAdditive(self: *Self) ParserError!*ASTNode {
    var node = try self.parseMultiplicative();

    while (true) {
        const tag: ASTNodeTag = switch (self.token().type) {
            .Plus => .plus_expr,
            .Minus => .minus_expr,
            else => break,
        };
        _ = self.advance();
        node = try self.createNode(
            tag,
            .{
                .binary = .{
                    .left = node,
                    .right = try self.parseMultiplicative(),
                },
            },
        );
    }

    return node;
}

fn parseMultiplicative(self: *Self) ParserError!*ASTNode {
    var node = try self.parseExponentiation();

    while (true) {
        const tag: ASTNodeTag = switch (self.token().type) {
            .Star => .multiply_expr,
            .Slash => .div_expr,
            .Percent => .modulo_expr,
            else => break,
        };
        _ = self.advance();
        node = try self.createNode(
            tag,
            .{
                .binary = .{
                    .left = node,
                    .right = try self.parseExponentiation(),
                },
            },
        );
    }

    return node;
}

fn parseExponentiation(self: *Self) ParserError!*ASTNode {
    var node = try self.parseUnary();

    while (self.match(TokenType.StarStar)) {
        node = try self.createNode(
            .exp_expr,
            .{
                .binary = .{
                    .left = node,
                    .right = try self.parseUnary(),
                },
            },
        );
    }
    return node;
}

fn parseUnary(self: *Self) ParserError!*ASTNode {
    while (true) {
        const tag: ASTNodeTag = switch (self.token().type) {
            .Minus => .minus,
            .Plus => .plus,
            .ExclamationMark => .not,
            .Tilde => .bitwise_negate,
            .Typeof => .typeof,
            .Void => .void,
            .Delete => .delete,
            else => return try self.parseUpdateExpression(),
        };
        _ = self.advance();
        return try self.createNode(
            tag,
            .{ .node = try self.parseUnary() },
        );
    }
}

fn parseUpdateExpression(self: *Self) ParserError!*ASTNode {
    if (self.match(TokenType.PlusPlus)) {
        return try self.createNode(
            .plusplus_pre,
            .{ .node = try self.parseUnary() },
        );
    } else if (self.match(TokenType.MinusMinus)) {
        return try self.createNode(
            .minusminus_pre,
            .{ .node = try self.parseUnary() },
        );
    }

    var node = try self.parseLeftHandSideExpression();

    if (self.match(TokenType.PlusPlus)) {
        node = try self.createNode(
            .plusplus_post,
            .{ .node = node },
        );
    } else if (self.match(TokenType.MinusMinus)) {
        node = try self.createNode(
            .minusminus_post,
            .{ .node = node },
        );
    }

    return node;
}

fn parseLeftHandSideExpression(self: *Self) ParserError!*ASTNode {
    return try self.parseCallableExpression() orelse try self.createEmptyNode(diagnostics.unexpected_token, .{});
}

fn parseNewExpression(self: *Self) ParserError!?*ASTNode {
    if (!self.match(TokenType.New)) {
        return self.parseMemberExpression();
    }

    const node = try self.createNode(
        .new,
        .{ .node = try self.parseCallableExpression() },
    );

    return node;
}

fn parseMemberExpression(self: *Self) ParserError!?*ASTNode {
    var node = try self.parsePrimaryExpression();

    if (node == null) {
        return null;
    }

    while (true) {
        const new_node = try self.parsePropertyAccess(node.?) orelse
            try self.parseIndexAccess(node.?);

        if (new_node) |n| {
            node = n;
        } else {
            break;
        }
    }

    return node;
}

fn parseCallableExpression(self: *Self) ParserError!?*ASTNode {
    var node = try self.parseMemberExpression();

    if (node == null) {
        return null;
    }

    while (self.match(TokenType.OpenParen)) {
        var nodes = ASTNodeList{};

        nodes.append(node.?);

        while (true) {
            if (self.match(TokenType.CloseParen)) {
                break;
            }

            if (self.match(TokenType.Comma)) {
                try self.emitError(diagnostics.argument_expression_expected, .{});
                return error.SyntaxError;
            }

            nodes.append(try self.parseAssignment());

            if (!self.match(TokenType.CloseParen)) {
                _ = try self.consume(TokenType.Comma, diagnostics.ARG_expected, .{","});
            } else {
                break;
            }
        }

        node = try self.createNode(
            .call_expr,
            .{ .nodes = nodes },
        );
    }

    return node;
}

fn parseIndexAccess(self: *Self, expr: *ASTNode) ParserError!?*ASTNode {
    if (!self.match(TokenType.OpenSquareBracket)) {
        return null;
    }

    const node = try self.createNode(
        .index_access,
        .{
            .binary = .{
                .left = expr,
                .right = try self.parseExpression(),
            },
        },
    );

    _ = try self.consume(TokenType.CloseSquareBracket, diagnostics.ARG_expected, .{"]"});

    return node;
}

fn parsePropertyAccess(self: *Self, expr: *ASTNode) ParserError!?*ASTNode {
    if (!self.match(TokenType.Dot)) {
        return null;
    }

    const identifier = try self.parseIdentifier() orelse try self.createEmptyNode(diagnostics.identifier_expected, .{});
    return try self.createNode(
        .property_access,
        .{ .binary = .{
            .left = expr,
            .right = identifier,
        } },
    );
}

fn parsePrimaryExpression(self: *Self) ParserError!?*ASTNode {
    return try self.parseThis() orelse
        try self.parseIdentifier() orelse
        try self.parseLiteral() orelse
        try self.parseArrayLiteral() orelse
        try self.parseObjectLiteral() orelse
        // try self.parseFunctionExpression() orelse
        // try self.parseClassExpression() orelse
        // try self.parseGeneratorExpression() orelse
        // try self.parseAsyncExpression() orelse
        try self.parseGroupingExpression();
}

fn parseThis(self: *Self) ParserError!?*ASTNode {
    if (self.match(TokenType.This)) {
        return try self.createNode(.this, .{ .none = {} });
    }

    return null;
}

fn parseIdentifier(self: *Self) ParserError!?*ASTNode {
    if (self.consumeOrNull(TokenType.Identifier)) |identifier| {
        return try self.createNode(.identifier, .{ .literal = identifier.value.? });
    }

    if (self.consumeOrNull(TokenType.Keyword)) |keyword| {
        return if (consts.isReservedWord(keyword.value.?)) null else try self.createNode(.identifier, .{ .literal = keyword.value.? });
    }

    return null;
}

fn parseLiteral(self: *Self) ParserError!?*ASTNode {
    if (self.match(TokenType.Null)) {
        return try self.createNode(.null, .{ .none = {} });
    } else if (self.match(TokenType.Undefined)) {
        return try self.createNode(.undefined, .{ .none = {} });
    } else if (self.match(TokenType.True)) {
        return try self.createNode(.true, .{ .none = {} });
    } else if (self.match(TokenType.False)) {
        return try self.createNode(.false, .{ .none = {} });
    } else if (self.consumeOrNull(TokenType.NumberConstant)) |number| {
        return try self.createNode(.number, .{ .literal = number.value.? });
    } else if (self.consumeOrNull(TokenType.BigIntConstant)) |bigint| {
        return try self.createNode(.bigint, .{ .literal = bigint.value.? });
    } else if (self.consumeOrNull(TokenType.StringConstant)) |string| {
        return try self.createNode(.string, .{ .literal = string.value.? });
    }

    return null;
}

fn parseArrayLiteral(self: *Self) ParserError!?*ASTNode {
    if (!self.match(TokenType.OpenSquareBracket)) {
        return null;
    }

    var values = ASTNodeList{};

    while (true) {
        while (self.match(TokenType.Comma)) {
            values.append(try self.createNode(
                .none,
                .{ .none = {} },
            ));
        }

        if (self.match(TokenType.CloseSquareBracket)) {
            break;
        }

        values.append(try self.parseAssignment());
        const comma: ?Token = self.consumeOrNull(TokenType.Comma);

        if (self.match(TokenType.CloseSquareBracket)) {
            break;
        } else if (comma == null) {
            try self.emitError(diagnostics.ARG_expected, .{","});
            return error.SyntaxError;
        }
    }

    return try self.createNode(
        .array_literal,
        .{ .nodes = values },
    );
}

fn parseObjectLiteral(self: *Self) ParserError!?*ASTNode {
    if (!self.match(TokenType.OpenCurlyBrace)) {
        return null;
    }
    var nodes = ASTNodeList{};

    var has_comma = true;
    while (true) {
        if (!has_comma) {
            try self.emitError(diagnostics.ARG_expected, .{","});
        }
        const node = try self.parseMethodGetter() orelse
            try self.parseMethodSetter() orelse
            try self.parseAsyncGeneratorMethod() orelse
            try self.parseObjectField();

        if (node) |n| {
            nodes.append(n);
        }

        if (self.match(TokenType.CloseCurlyBrace)) {
            break;
        } else {
            if (node == null and self.peekMatch(TokenType.Comma)) {
                try self.emitError(diagnostics.property_assignment_expected, .{});
            } else if (node != null and !self.peekMatch(TokenType.Comma)) {
                try self.emitError(diagnostics.ARG_expected, .{","});
            }

            has_comma = self.match(TokenType.Comma);
        }
    }

    return try self.createNode(
        .object_literal,
        .{ .nodes = nodes },
    );
}

fn parseObjectField(self: *Self) ParserError!?*ASTNode {
    const identifier = try self.parseObjectElementName();

    if (identifier == null) {
        return null;
    }

    if (self.match(TokenType.Colon)) {
        return try self.createNode(.object_literal_field, .{
            .binary = .{
                .left = identifier.?,
                .right = try self.parseAssignment(),
            },
        });
    } else if (self.peekMatch(TokenType.Comma) or self.peekMatch(TokenType.CloseCurlyBrace)) {
        return try self.createNode(.object_literal_field_shorthand, .{ .node = identifier.? });
    }

    return null;
}

fn parseGroupingExpression(self: *Self) ParserError!?*ASTNode {
    if (self.match(TokenType.OpenParen)) {
        const node = try self.createNode(
            .grouping,
            .{ .node = try self.parseExpression() },
        );
        _ = try self.consume(TokenType.CloseParen, diagnostics.ARG_expected, .{")"});
        return node;
    }

    return null;
}

fn parseOptionalDataType(self: *Self, default: TypeSymbol) ParserError!*TypeSymbol {
    if (self.match(TokenType.Colon)) {
        return try self.parseDataType();
    }

    return try self.create(TypeSymbol, default);
}

fn parseDataType(self: *Self) ParserError!*TypeSymbol {
    if (self.match(TokenType.NumberConstant)) {
        return try self.create(TypeSymbol, .{ .number = {} });
    } else if (self.match(TokenType.BigIntConstant)) {
        return try self.create(TypeSymbol, .{ .bigint = {} });
    } else if (self.match(TokenType.StringConstant)) {
        return try self.create(TypeSymbol, .{ .string = {} });
    } else if (self.match(TokenType.True) or self.match(TokenType.False)) {
        return try self.create(TypeSymbol, .{ .boolean = {} });
    } else if (self.match(TokenType.Null)) {
        return try self.create(TypeSymbol, .{ .null = {} });
    } else if (self.match(TokenType.Undefined)) {
        return try self.create(TypeSymbol, .{ .undefined = {} });
    } else if (self.match(TokenType.Void)) {
        return try self.create(TypeSymbol, .{ .void = {} });
    } else if (self.match(TokenType.Any)) {
        return try self.create(TypeSymbol, .{ .any = {} });
    } else if (self.match(TokenType.Unknown)) {
        return try self.create(TypeSymbol, .{ .unknown = {} });
    } else if (self.consumeOrNull(TokenType.Identifier)) |identifier| {
        const value = identifier.value.?;
        if (std.mem.eql(u8, value, "number")) {
            return try self.create(TypeSymbol, .{ .number = {} });
        } else if (std.mem.eql(u8, value, "bigint")) {
            return try self.create(TypeSymbol, .{ .bigint = {} });
        } else if (std.mem.eql(u8, value, "string")) {
            return try self.create(TypeSymbol, .{ .string = {} });
        } else if (std.mem.eql(u8, value, "boolean")) {
            return try self.create(TypeSymbol, .{ .boolean = {} });
        }
        return self.parseIdentifierType(identifier);
    }

    try self.emitError(diagnostics.unexpected_token, .{});
    return error.SyntaxError;
}

fn getReferenceSymbol(self: *Self, identifier: Token) ParserError!*TypeSymbol {
    const referenceSymbol = self.closure.getSymbol(identifier.value.?);

    if (referenceSymbol == null) {
        try self.emitError(diagnostics.cannot_find_parameter_ARG, .{identifier.value.?});
        return try self.create(TypeSymbol, .{ .any = {} });
    } else if (referenceSymbol.?.* != .type) {
        try self.emitError(diagnostics.ARG_refers_to_a_value_but_is_being_used_as_a_type_here_did_you_mean_typeof_ARG, .{referenceSymbol.?.literal.value});
        return try self.create(TypeSymbol, .{ .any = {} });
    }

    return &referenceSymbol.?.type;
}

fn parseIdentifierType(self: *Self, identifier: Token) ParserError!*TypeSymbol {
    const refTypeSymbol: *TypeSymbol = try self.getReferenceSymbol(identifier);

    var typeSymbol = try self.create(TypeSymbol, .{
        .reference = ReferenceSymbol{
            .data_type = refTypeSymbol,
            .params = null,
        },
    });
    if (self.match(TokenType.LessThan)) {
        var params = TypeList{};

        while (true) {
            const param = try self.parseDataType();
            params.append(try self.create(TypeList.Node, .{
                .data = param,
            }));

            if (!self.match(TokenType.Comma)) {
                break;
            }
        }

        _ = try self.consume(TokenType.GreaterThan, diagnostics.ARG_expected, .{">"});
        typeSymbol.reference.params = params;
    }
    return typeSymbol;
}

pub fn needsSemicolon(node: *ASTNode) bool {
    var tag = node.tag;
    if (tag == .@"export") {
        tag = node.data.node.tag;
    }

    return switch (tag) {
        .block, .func_decl, .async_func_decl, .@"for", .@"while", .do_while, .@"if", .@"else", .class_decl => false,
        else => true,
    };
}
