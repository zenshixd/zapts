const std = @import("std");
const ArrayList = std.ArrayList;

const Lexer = @import("lexer.zig");
const Closure = @import("closure.zig").Closure;
const Symbol = @import("symbols.zig").Symbol;
const TypeSymbol = @import("symbols.zig").TypeSymbol;
const ReferenceSymbol = @import("symbols.zig").ReferenceSymbol;

const consts = @import("consts.zig");
const Token = consts.Token;
const TokenType = consts.TokenType;

pub const ParserError = error{ SyntaxError, OutOfMemory, NoSpaceLeft };

pub const ASTNodeTag = enum {
    // data: nodes
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
    // data: literal
    import_path,

    // data: nodes
    var_decl,
    // data: nodes
    const_decl,
    // data: nodes
    let_decl,

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
    // data: literal
    func_decl_argument,

    // data: nodes
    call_expr,
    // data: node
    grouping,
    // data: nodes
    comma,
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
    // data: nodes
    property_access,
    // data: nodes
    optional_property_access,
    // data: nodes
    array_literal,
    // data: nodes
    index_access,

    // data: literal
    true,
    false,
    null,
    undefined,
    number,
    bigint,
    string,
    identifier,
    none,
};

pub const ASTNodeData = union(enum) {
    literal: []const u8,
    node: *ASTNode,
    nodes: []*ASTNode,
    none: void,
};

pub const ASTNode = struct {
    tag: ASTNodeTag,
    data_type: TypeSymbol,
    data: ASTNodeData,

    fn repeatTab(writer: anytype, level: usize) !void {
        for (0..level) |_| {
            try writer.writeAll("\t");
        }
    }

    pub fn format(self: *ASTNode, comptime _: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        // std.debug.print("fmt debug: {s} {any}", .{ fmt, options });
        const level = options.width orelse 1;
        try writer.writeAll("ASTNode(.");
        try writer.writeAll(@tagName(self.tag));
        try writer.writeAll(", .type = ");
        try writer.writeAll(@tagName(self.data_type));
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

allocator: std.mem.Allocator,
closure: *Closure,
tokens: []Token,
index: usize = 0,
errors: std.ArrayList([]const u8),

pub fn init(allocator: std.mem.Allocator, buffer: []const u8) !Self {
    const closure = try allocator.create(Closure);
    closure.* = Closure.init(allocator);

    var lexer = Lexer.init(allocator, buffer);
    const tokens = try lexer.nextAll();

    return Self{
        .tokens = tokens,
        .allocator = allocator,
        .closure = closure,
        .errors = ArrayList([]const u8).init(allocator),
    };
}

pub fn parse(self: *Self) ParserError![]*ASTNode {
    var nodes = ArrayList(*ASTNode).init(self.allocator);
    defer nodes.deinit();

    while (!self.match(TokenType.Eof)) {
        if (self.match(TokenType.NewLine) or self.match(TokenType.LineComment) or self.match(TokenType.MultilineComment)) {
            continue;
        }

        const node = try self.parseStatement();
        try nodes.append(node);
    }

    return try nodes.toOwnedSlice();
}

fn createNode(self: *Self, tag: ASTNodeTag, data: ASTNodeData) !*ASTNode {
    const node = try self.allocator.create(ASTNode);
    node.* = .{
        .tag = tag,
        .data_type = self.getNodeType(tag, data),
        .data = data,
    };
    return node;
}

fn createTypedNode(self: *Self, tag: ASTNodeTag, data_type: TypeSymbol, data: ASTNodeData) !*ASTNode {
    const node = try self.allocator.create(ASTNode);
    node.* = .{
        .tag = tag,
        .data_type = data_type,
        .data = data,
    };
    return node;
}

fn token(self: Self) Token {
    return self.tokens[self.index];
}

fn advance(self: *Self) Token {
    const t = self.token();
    self.index += 1;
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
    return self.index < self.tokens.len and self.token().type == token_type;
}

fn consume(self: *Self, token_type: TokenType, comptime error_msg: []const u8) ParserError!Token {
    if (self.token().type == token_type) {
        return self.advance();
    }

    try self.emitError(error_msg, .{});
    try self.emitError("Current token: {}", .{self.token()});
    return error.SyntaxError;
}

fn consumeOrNull(self: *Self, token_type: TokenType) ?Token {
    if (self.token().type == token_type) {
        return self.advance();
    }

    return null;
}

fn rewind(self: *Self) void {
    self.index -= 1;
}

fn getNodeType(self: *Self, tag: ASTNodeTag, data: ASTNodeData) TypeSymbol {
    return switch (tag) {
        .import => .{ .none = {} },
        .import_named_bindings => .{ .none = {} },
        .import_binding_named => .{ .unknown = {} },
        .import_type_binding_named => .{ .unknown = {} },
        .import_binding_default => .{ .unknown = {} },
        .import_type_binding_default => .{ .unknown = {} },
        .import_binding_namespace => .{ .unknown = {} },
        .import_type_binding_namespace => .{ .unknown = {} },
        .import_path => .{ .none = {} },
        .var_decl => .{ .none = {} },
        .const_decl => .{ .none = {} },
        .let_decl => .{ .none = {} },
        .async_func_decl => .{ .none = {} },
        .func_decl => .{ .none = {} },
        .func_decl_name => .{ .unknown = {} },
        .func_decl_argument => .{ .any = {} },
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
        .call_expr => .{ .unknown = {} },
        .comma => .{ .unknown = {} },
        .true => .{ .true = {} },
        .false => .{ .false = {} },
        .null => .{ .null = {} },
        .undefined => .{ .undefined = {} },
        .number => .{ .number = {} },
        .bigint => .{ .bigint = {} },
        .string => .{ .string = {} },
        .identifier => .{ .any = {} },
        .none => .{ .none = {} },
        .grouping => self.getNodeType(data.node.tag, data.node.data),
        .assignment => self.getNodeType(data.nodes[1].tag, data.nodes[1].data),
        .plus_assign => self.getNodeType(data.nodes[1].tag, data.nodes[1].data),
        .minus_assign => self.getNodeType(data.nodes[1].tag, data.nodes[1].data),
        .multiply_assign => self.getNodeType(data.nodes[1].tag, data.nodes[1].data),
        .div_assign => self.getNodeType(data.nodes[1].tag, data.nodes[1].data),
        .modulo_assign => self.getNodeType(data.nodes[1].tag, data.nodes[1].data),
        .exp_assign => self.getNodeType(data.nodes[1].tag, data.nodes[1].data),
        .and_assign => self.getNodeType(data.nodes[1].tag, data.nodes[1].data),
        .or_assign => self.getNodeType(data.nodes[1].tag, data.nodes[1].data),
        .bitwise_and_assign => self.getNodeType(data.nodes[1].tag, data.nodes[1].data),
        .bitwise_or_assign => self.getNodeType(data.nodes[1].tag, data.nodes[1].data),
        .bitwise_xor_assign => self.getNodeType(data.nodes[1].tag, data.nodes[1].data),
        .bitwise_shift_left_assign => self.getNodeType(data.nodes[1].tag, data.nodes[1].data),
        .bitwise_shift_right_assign => self.getNodeType(data.nodes[1].tag, data.nodes[1].data),
        .bitwise_unsigned_right_shift_assign => self.getNodeType(data.nodes[1].tag, data.nodes[1].data),
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
        .spread => self.getNodeType(data.node.tag, data.node.data),
        .typeof => .{ .string = {} },
        .void => .{ .none = {} },
        .delete => .{ .boolean = {} },
        .object_literal => .{ .unknown = {} },
        .object_literal_field => .{ .none = {} },
        .object_literal_field_shorthand => .{ .none = {} },
        .property_access => self.getNodeType(data.nodes[1].tag, data.nodes[1].data),
        .optional_property_access => self.getNodeType(data.nodes[1].tag, data.nodes[1].data),
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
    };
}

fn emitError(self: *Self, comptime error_msg: []const u8, args: anytype) !void {
    try self.errors.append(try std.fmt.allocPrint(self.allocator, error_msg, args));
}

fn parseStatement(self: *Self) ParserError!*ASTNode {
    while (self.match(TokenType.NewLine)) {}

    // zig fmt: off
    const node = try self.parseBlock()
        orelse try self.parseDeclaration()
        orelse try self.parseImportStatement()
        orelse try self.parseEmptyStatement()
        orelse try self.parseIfStatement()
        orelse try self.parseBreakableStatement()
        orelse try self.parseExpression();
    // zig fmt: on

    if (needsSemicolon(node)) {
        _ = try self.consume(TokenType.Semicolon, "Expected ';'");
    }
    return node;
}

fn parseImportStatement(self: *Self) ParserError!?*ASTNode {
    if (!self.match(TokenType.Import)) {
        return null;
    }
    var nodes = ArrayList(*ASTNode).init(self.allocator);
    defer nodes.deinit();

    if (self.consumeOrNull(TokenType.StringConstant)) |path| {
        try nodes.append(try self.createNode(
            .import_path,
            .{ .literal = path.value.? },
        ));

        return try self.createNode(
            .import,
            .{ .nodes = try nodes.toOwnedSlice() },
        );
    }

    const default_as_type = self.match(TokenType.Type);

    if (self.consumeOrNull(TokenType.Identifier)) |identifier| {
        const tag: ASTNodeTag = if (default_as_type or self.match(TokenType.Type)) .import_type_binding_default else .import_binding_default;
        try nodes.append(try self.createNode(
            tag,
            .{ .literal = identifier.value.? },
        ));
    }

    if (nodes.items.len > 0 and !self.match(TokenType.Comma)) {
        try self.emitError("Expected ','", .{});
    }

    if (self.match(TokenType.Star)) {
        _ = try self.consume(TokenType.As, "Expected 'as' after '*'");
        const identifier = try self.consume(TokenType.Identifier, "Expected identifier");

        const tag: ASTNodeTag = if (default_as_type) .import_type_binding_namespace else .import_binding_namespace;
        try nodes.append(try self.createNode(
            tag,
            .{ .literal = identifier.value.? },
        ));
    } else if (self.match(TokenType.OpenCurlyBrace)) {
        var named_bindings = ArrayList(*ASTNode).init(self.allocator);
        defer named_bindings.deinit();

        while (true) {
            const as_type = default_as_type or self.match(TokenType.Type);

            if (self.consumeOrNull(TokenType.Identifier)) |identifier| {
                try named_bindings.append(try self.createNode(
                    if (as_type) .import_type_binding_named else .import_binding_named,
                    .{ .literal = identifier.value.? },
                ));
            }

            if (self.match(TokenType.CloseCurlyBrace)) {
                break;
            }
            _ = try self.consume(TokenType.Comma, "Expected ','");
        }

        try nodes.append(try self.createNode(
            .import_named_bindings,
            .{ .nodes = try named_bindings.toOwnedSlice() },
        ));
    } else {
        try self.emitError("Import binding or specifier expected", .{});
    }

    _ = try self.consume(TokenType.From, "Expected 'from'");
    const path_token = try self.consume(TokenType.StringConstant, "Expected string constant");

    // for (nodes.items) |node| {
    //     _ = try self.closure.addSymbol(node.data.literal, .{
    //         .declaration = .{
    //             .type = .{
    //                 .unknown = {},
    //             },
    //             .name = node.data.literal,
    //         },
    //     });
    // }

    try nodes.append(try self.createNode(
        .import_path,
        .{ .literal = path_token.value.? },
    ));

    return try self.createNode(
        .import,
        .{ .nodes = try nodes.toOwnedSlice() },
    );
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
    var nodes = ArrayList(*ASTNode).init(self.allocator);
    defer nodes.deinit();

    if (self.consumeOrNull(TokenType.Identifier)) |identifier| {
        name = identifier.value.?;
    }

    try nodes.append(try self.createNode(
        .func_decl_name,
        .{ .literal = name },
    ));

    _ = try self.consume(TokenType.OpenParen, "Expected '('");

    while (true) {
        if (self.consumeOrNull(TokenType.Identifier)) |identifier| {
            try nodes.append(try self.createNode(
                .func_decl_argument,
                .{ .literal = identifier.value.? },
            ));
        }

        if (self.match(TokenType.CloseParen)) {
            break;
        }

        _ = try self.consume(TokenType.Comma, "Expected ','");
    }

    const tag: ASTNodeTag = if (is_async) .async_func_decl else .func_decl;

    if (try self.parseBlock()) |block| {
        try nodes.append(block);
    } else {
        try self.emitError("'{{' or ';' expected", .{});
    }
    return try self.createNode(
        tag,
        .{ .nodes = try nodes.toOwnedSlice() },
    );
}

fn parseBlock(self: *Self) ParserError!?*ASTNode {
    if (!self.match(TokenType.OpenCurlyBrace)) {
        return null;
    }

    // every block spawns new closure
    self.closure = try self.closure.spawn();
    var statements = ArrayList(*ASTNode).init(self.allocator);
    defer statements.deinit();

    while (true) {
        if (self.match(TokenType.Eof)) {
            try self.emitError("Expected '}}'", .{});
            return error.SyntaxError;
        }

        if (self.match(TokenType.CloseCurlyBrace)) {
            break;
        }

        const statement = try self.parseStatement();
        try statements.append(statement);

        while (self.match(TokenType.NewLine)) {}

        if (self.match(TokenType.CloseCurlyBrace)) {
            break;
        }
    }

    self.closure = self.closure.parent.?;

    return self.createNode(
        .block,
        .{ .nodes = try statements.toOwnedSlice() },
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

    var nodes = ArrayList(*ASTNode).init(self.allocator);
    defer nodes.deinit();

    while (true) {
        const identifier = try self.consume(TokenType.Identifier, "Expected identifier");

        var identifier_data_type: TypeSymbol = .{ .none = {} };
        if (self.match(TokenType.Colon)) {
            identifier_data_type = try self.parseDataType();
        }

        var node = try self.createTypedNode(
            .identifier,
            identifier_data_type,
            .{ .literal = identifier.value.? },
        );
        if (self.match(TokenType.Equal)) {
            const right = try self.parseAssignment();
            node = try self.createTypedNode(
                .assignment,
                switch (identifier_data_type) {
                    .none => right.data_type,
                    else => identifier_data_type,
                },
                .{
                    .nodes = try self.allocator.dupe(*ASTNode, &[_]*ASTNode{
                        node,
                        right,
                    }),
                },
            );
        }

        try nodes.append(node);
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
        .{ .nodes = try nodes.toOwnedSlice() },
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

    _ = try self.consume(TokenType.OpenParen, "Expected '('");
    const left = try self.parseExpression();
    _ = try self.consume(TokenType.CloseParen, "Expected ')'");

    const node = try self.createNode(
        .@"if",
        .{
            .nodes = try self.allocator.dupe(*ASTNode, &[_]*ASTNode{
                left,
                try self.parseStatement(),
            }),
        },
    );

    if (!self.match(TokenType.Else)) {
        return node;
    }

    const else_node = try self.parseStatement();

    return try self.createNode(
        .@"else",
        .{
            .nodes = try self.allocator.dupe(*ASTNode, &[_]*ASTNode{
                node,
                else_node,
            }),
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
    _ = try self.consume(TokenType.While, "Expected 'while'");
    _ = try self.consume(TokenType.OpenParen, "Expected '('");
    const condition = try self.parseExpression();
    _ = try self.consume(TokenType.CloseParen, "Expected ')'");

    return try self.createNode(
        .do_while,
        .{
            .nodes = try self.allocator.dupe(*ASTNode, &[_]*ASTNode{
                condition,
                node,
            }),
        },
    );
}

fn parseWhileStatement(self: *Self) ParserError!?*ASTNode {
    if (!self.match(TokenType.While)) {
        return null;
    }

    _ = try self.consume(TokenType.OpenParen, "Expected '('");
    const condition = try self.parseExpression();
    _ = try self.consume(TokenType.CloseParen, "Expected ')'");

    return try self.createNode(
        .@"while",
        .{
            .nodes = try self.allocator.dupe(*ASTNode, &[_]*ASTNode{
                condition,
                try self.parseStatement(),
            }),
        },
    );
}

fn parseForStatement(self: *Self) ParserError!?*ASTNode {
    if (!self.match(TokenType.For)) {
        return null;
    }

    _ = try self.consume(TokenType.OpenParen, "Expected '('");
    const init_node = try self.parseForInitExpression();

    const for_inner = try self.parseForClassicStatement(init_node) orelse try self.parseForInStatement(init_node) orelse try self.parseForOfStatement(init_node);

    if (for_inner == null) {
        try self.emitError("'in' or ; expected", .{});
        return error.SyntaxError;
    }

    return self.createNode(
        .@"for",
        .{
            .nodes = try self.allocator.dupe(*ASTNode, &[_]*ASTNode{
                for_inner.?,
                try self.parseStatement(),
            }),
        },
    );
}

fn parseForClassicStatement(self: *Self, init_node: *ASTNode) ParserError!?*ASTNode {
    if (!self.match(TokenType.Semicolon)) {
        return null;
    }

    var nodes = ArrayList(*ASTNode).init(self.allocator);
    defer nodes.deinit();

    try nodes.append(init_node);
    try nodes.append(try self.parseExpression());
    _ = try self.consume(TokenType.Semicolon, "Expected ';'");
    try nodes.append(try self.parseExpression());
    _ = try self.consume(TokenType.CloseParen, "Expected ')'");

    return try self.createNode(
        .for_classic,
        .{ .nodes = try nodes.toOwnedSlice() },
    );
}

fn parseForInStatement(self: *Self, init_node: *ASTNode) ParserError!?*ASTNode {
    if (!self.match(TokenType.In)) {
        return null;
    }

    const right = try self.parseExpression();
    _ = try self.consume(TokenType.CloseParen, "Expected ')'");

    return self.createNode(
        .for_in,
        .{
            .nodes = try self.allocator.dupe(*ASTNode, &[_]*ASTNode{
                init_node,
                right,
            }),
        },
    );
}

fn parseForOfStatement(self: *Self, init_node: *ASTNode) ParserError!?*ASTNode {
    if (!self.match(TokenType.Of)) {
        return null;
    }

    const right = try self.parseExpression();
    _ = try self.consume(TokenType.CloseParen, "Expected ')'");

    return self.createNode(
        .for_of,
        .{
            .nodes = try self.allocator.dupe(*ASTNode, &[_]*ASTNode{
                init_node,
                right,
            }),
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
                .nodes = try self.allocator.dupe(*ASTNode, &[_]*ASTNode{
                    node,
                    try self.parseAssignment(),
                }),
            },
        );
    }

    return node;
}

fn parseAssignment(self: *Self) ParserError!*ASTNode {
    var node = try self.parseLogicalOr();

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
            .nodes = try self.allocator.dupe(*ASTNode, &[_]*ASTNode{
                node,
                try self.parseAssignment(),
            }),
        },
    );

    return node;
}

fn parseLogicalOr(self: *Self) ParserError!*ASTNode {
    var node = try self.parseLogicalAnd();

    while (self.match(TokenType.BarBar)) {
        node = try self.createNode(
            .@"or",
            .{
                .nodes = try self.allocator.dupe(*ASTNode, &[_]*ASTNode{
                    node,
                    try self.parseLogicalAnd(),
                }),
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
                .nodes = try self.allocator.dupe(*ASTNode, &[_]*ASTNode{
                    node,
                    try self.parseBitwiseOr(),
                }),
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
                .nodes = try self.allocator.dupe(*ASTNode, &[_]*ASTNode{
                    node,
                    right,
                }),
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
                .nodes = try self.allocator.dupe(*ASTNode, &[_]*ASTNode{
                    node,
                    right,
                }),
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
                .nodes = try self.allocator.dupe(*ASTNode, &[_]*ASTNode{
                    node,
                    right,
                }),
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
                .nodes = try self.allocator.dupe(*ASTNode, &[_]*ASTNode{
                    node,
                    try self.parseRelational(),
                }),
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
                .nodes = try self.allocator.dupe(*ASTNode, &[_]*ASTNode{
                    node,
                    try self.parseShift(),
                }),
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
                .nodes = try self.allocator.dupe(*ASTNode, &[_]*ASTNode{
                    node,
                    try self.parseAdditive(),
                }),
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
                .nodes = try self.allocator.dupe(*ASTNode, &[_]*ASTNode{
                    node,
                    try self.parseMultiplicative(),
                }),
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
                .nodes = try self.allocator.dupe(*ASTNode, &[_]*ASTNode{
                    node,
                    try self.parseExponentiation(),
                }),
            },
        );
    }

    return node;
}

fn parseExponentiation(self: *Self) ParserError!*ASTNode {
    var node = try self.parseUnary();

    while (self.match(TokenType.StarStar)) {
        const right = try self.parseUnary();
        node = try self.createNode(
            .exp_expr,
            .{
                .nodes = try self.allocator.dupe(*ASTNode, &[_]*ASTNode{
                    node,
                    right,
                }),
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
            .{ .node = try self.parseCallableExpression() },
        );
    } else if (self.match(TokenType.MinusMinus)) {
        return try self.createNode(
            .minusminus_pre,
            .{ .node = try self.parseCallableExpression() },
        );
    }

    var node = try self.parseCallableExpression();

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

fn parseCallableExpression(self: *Self) ParserError!*ASTNode {
    var node = try self.parseIndexAccess();

    while (self.match(TokenType.OpenParen)) {
        var nodes = ArrayList(*ASTNode).init(self.allocator);
        defer nodes.deinit();

        try nodes.append(node);

        while (true) {
            if (self.match(TokenType.CloseParen)) {
                break;
            }

            if (self.match(TokenType.Comma)) {
                try self.emitError("Argument expression expected", .{});
                return error.SyntaxError;
            }

            try nodes.append(try self.parseAssignment());

            if (!self.match(TokenType.CloseParen)) {
                _ = try self.consume(TokenType.Comma, "Expected ','");
            } else {
                break;
            }
        }

        node = try self.createNode(
            .call_expr,
            .{ .nodes = try nodes.toOwnedSlice() },
        );
    }

    return node;
}

fn parseIndexAccess(self: *Self) ParserError!*ASTNode {
    var node = try self.parseArrayLiteral();

    while (self.match(TokenType.OpenSquareBracket)) {
        node = try self.createNode(
            .index_access,
            .{
                .nodes = try self.allocator.dupe(*ASTNode, &[_]*ASTNode{
                    node,
                    try self.parseExpression(),
                }),
            },
        );

        _ = try self.consume(TokenType.CloseSquareBracket, "Expected ']'");
    }

    return node;
}

fn parseArrayLiteral(self: *Self) ParserError!*ASTNode {
    if (!self.match(TokenType.OpenSquareBracket)) {
        return self.parsePropertyAccess();
    }

    var values = ArrayList(*ASTNode).init(self.allocator);

    while (true) {
        while (self.match(TokenType.Comma)) {
            try values.append(try self.createNode(
                .none,
                .{ .none = {} },
            ));
        }

        if (self.match(TokenType.CloseSquareBracket)) {
            break;
        }

        try values.append(try self.parseAssignment());
        const comma: ?Token = self.consumeOrNull(TokenType.Comma);

        if (self.match(TokenType.CloseSquareBracket)) {
            break;
        } else if (comma == null) {
            try self.emitError("Expected ','", .{});
            return error.SyntaxError;
        }
    }

    return try self.createNode(
        .array_literal,
        .{ .nodes = try values.toOwnedSlice() },
    );
}

fn parsePropertyAccess(self: *Self) ParserError!*ASTNode {
    var node = try self.parseObjectLiteral();

    while (true) {
        const tag: ASTNodeTag = switch (self.token().type) {
            .Dot => .property_access,
            .QuestionMarkDot => .optional_property_access,
            else => break,
        };
        _ = self.advance();
        node = try self.createNode(
            tag,
            .{ .nodes = try self.allocator.dupe(*ASTNode, &[_]*ASTNode{
                node,
                try self.parseLiteral(),
            }) },
        );
    }
    return node;
}

fn parseObjectLiteral(self: *Self) ParserError!*ASTNode {
    if (!self.match(TokenType.OpenCurlyBrace)) {
        return self.parseLiteral();
    }
    var nodes = ArrayList(*ASTNode).init(self.allocator);
    defer nodes.deinit();

    while (true) {
        while (self.match(TokenType.NewLine)) {}

        const identifier = try self.parseLiteral();

        var comma: ?Token = null;
        if (self.match(TokenType.Colon)) {
            try nodes.append(try self.createNode(.object_literal_field, .{
                .nodes = try self.allocator.dupe(*ASTNode, &[_]*ASTNode{
                    identifier,
                    try self.parseAssignment(),
                }),
            }));
            comma = self.consumeOrNull(TokenType.Comma);
        } else {
            try self.emitError("Expected ':'", .{});
            return error.SyntaxError;
        }

        while (self.match(TokenType.NewLine)) {}

        if (self.match(TokenType.CloseCurlyBrace)) {
            break;
        } else if (comma == null) {
            try self.emitError("Expected ','", .{});
            return error.SyntaxError;
        }
    }

    return try self.createNode(
        .object_literal,
        .{ .nodes = try nodes.toOwnedSlice() },
    );
}

fn parseLiteral(self: *Self) ParserError!*ASTNode {
    while (true) {
        if (self.match(TokenType.True)) {
            return try self.createNode(.true, .{ .none = {} });
        } else if (self.match(TokenType.False)) {
            return try self.createNode(.false, .{ .none = {} });
        } else if (self.match(TokenType.Null)) {
            return try self.createNode(.null, .{ .none = {} });
        } else if (self.match(TokenType.Undefined)) {
            return try self.createNode(.undefined, .{ .none = {} });
        } else if (self.consumeOrNull(TokenType.NumberConstant)) |number| {
            return try self.createNode(.number, .{ .literal = number.value.? });
        } else if (self.consumeOrNull(TokenType.BigIntConstant)) |bigint| {
            return try self.createNode(.bigint, .{ .literal = bigint.value.? });
        } else if (self.consumeOrNull(TokenType.StringConstant)) |string| {
            return try self.createNode(.string, .{ .literal = string.value.? });
        } else if (self.consumeOrNull(TokenType.Identifier)) |identifier| {
            return try self.createNode(.identifier, .{ .literal = identifier.value.? });
        } else {
            break;
        }
    }

    if (self.match(TokenType.OpenParen)) {
        const node = try self.createNode(
            .grouping,
            .{ .node = try self.parseExpression() },
        );
        _ = try self.consume(TokenType.CloseParen, "Expected ')'");
        return node;
    }

    try self.emitError("Unexpected token {}", .{self.token()});
    return error.SyntaxError;
}

fn parseDataType(self: *Self) !TypeSymbol {
    if (self.match(TokenType.NumberConstant)) {
        return .{ .number = {} };
    } else if (self.match(TokenType.BigIntConstant)) {
        return .{ .bigint = {} };
    } else if (self.match(TokenType.StringConstant)) {
        return .{ .string = {} };
    } else if (self.match(TokenType.True) or self.match(TokenType.False)) {
        return .{ .boolean = {} };
    } else if (self.match(TokenType.Null)) {
        return .{ .null = {} };
    } else if (self.match(TokenType.Undefined)) {
        return .{ .undefined = {} };
    } else if (self.match(TokenType.Void)) {
        return .{ .void = {} };
    } else if (self.match(TokenType.Any)) {
        return .{ .any = {} };
    } else if (self.match(TokenType.Unknown)) {
        return .{ .unknown = {} };
    } else if (self.consumeOrNull(TokenType.Identifier)) |identifier| {
        const value = identifier.value.?;
        if (std.mem.eql(u8, value, "number")) {
            return .{ .number = {} };
        } else if (std.mem.eql(u8, value, "bigint")) {
            return .{ .bigint = {} };
        } else if (std.mem.eql(u8, value, "string")) {
            return .{ .string = {} };
        } else if (std.mem.eql(u8, value, "boolean")) {
            return .{ .boolean = {} };
        }
        return self.parseIdentifierType(identifier);
    }

    try self.emitError("Unexpected token {any}", .{self.token()});
    return error.SyntaxError;
}

fn parseIdentifierType(self: *Self, identifier: Token) ParserError!TypeSymbol {
    const referenceSymbol = self.closure.getSymbol(identifier.value.?);

    var refTypeSymbol: *TypeSymbol = undefined;

    if (referenceSymbol == null) {
        try self.emitError("Unknown type {s}", .{identifier.value.?});
        refTypeSymbol = try self.allocator.create(TypeSymbol);
        refTypeSymbol.* = .{ .any = {} };
    } else if (referenceSymbol.?.* != .type) {
        try self.emitError("{s} is not a type", .{identifier.value.?});
        refTypeSymbol = try self.allocator.create(TypeSymbol);
        refTypeSymbol.* = .{ .any = {} };
    } else {
        refTypeSymbol = &referenceSymbol.?.type;
    }

    var typeSymbol = TypeSymbol{
        .reference = ReferenceSymbol{
            .data_type = refTypeSymbol,
            .params = null,
        },
    };
    if (self.match(TokenType.LessThan)) {
        var params = ArrayList(TypeSymbol).init(self.allocator);
        defer params.deinit();

        while (true) {
            const param = try self.parseDataType();
            try params.append(param);

            if (!self.match(TokenType.Comma)) {
                break;
            }
        }

        _ = try self.consume(TokenType.GreaterThan, "Expected '>'");
        typeSymbol.reference.params = try params.toOwnedSlice();
    }
    return typeSymbol;
}

pub fn needsSemicolon(node: *ASTNode) bool {
    return switch (node.tag) {
        .block, .func_decl, .async_func_decl, .@"for", .@"while", .do_while, .@"if", .@"else" => false,
        else => true,
    };
}
