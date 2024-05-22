const std = @import("std");
const ArrayList = std.ArrayList;

const sym = @import("symbol_table.zig");
const SymbolTable = sym.SymbolTable;
const Symbol = sym.Symbol;

const consts = @import("consts.zig");
const Token = consts.Token;
const TokenType = consts.TokenType;

pub const ParserError = error{ SyntaxError, OutOfMemory, NoSpaceLeft };

pub const ASTBinaryNode = struct {
    left: *ASTNode,
    right: *ASTNode,
};

pub const ASTNoneNode = struct {};

pub const ASTNodeTag = enum {
    import,
    import_binding_named,
    import_type_binding_named,
    import_binding_default,
    import_type_binding_default,
    import_binding_namespace,
    import_type_binding_namespace,
    import_path,
    var_decl,
    const_decl,
    let_decl,
    block,
    assignment,
    async_func_decl,
    func_decl,
    func_decl_name,
    func_decl_argument,
    call_expr,
    grouping,
    comma,
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
    plusplus,
    minus,
    minusminus,
    not,
    bitwise_negate,
    spread,
    typeof,
    object_literal,
    object_literal_field,
    object_literal_field_shorthand,
    property_access,
    optional_property_access,
    array_literal,
    index_access,
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

pub const ASTNode = struct {
    tag: ASTNodeTag,
    data: union(enum) {
        literal: []const u8,
        node: *ASTNode,
        nodes: []*ASTNode,
        binary: ASTBinaryNode,
        none: ASTNoneNode,
    },

    pub fn new(allocator: std.mem.Allocator, value: ASTNode) !*ASTNode {
        const node = try allocator.create(ASTNode);
        node.* = value;
        return node;
    }

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
symbols: SymbolTable,
tokens: []Token,
index: usize = 0,
errors: std.ArrayList([]const u8),

pub fn init(allocator: std.mem.Allocator, tokens: []Token) Self {
    return Self{
        .tokens = tokens,
        .allocator = allocator,
        .symbols = SymbolTable.init(allocator),
        .errors = ArrayList([]const u8).init(allocator),
    };
}

pub fn token(self: Self) Token {
    return self.tokens[self.index];
}

pub fn advance(self: *Self) Token {
    const t = self.token();
    std.log.info("advance {}", .{t});
    self.index += 1;
    while (self.peekMatch(TokenType.LineComment) or self.peekMatch(TokenType.MultilineComment)) {
        self.index += 1;
    }
    return t;
}

pub fn match(self: *Self, token_type: TokenType) bool {
    if (self.peekMatch(token_type)) {
        _ = self.advance();
        return true;
    }
    return false;
}

pub fn peekMatch(self: Self, token_type: TokenType) bool {
    return self.index < self.tokens.len and self.token().type == token_type;
}

pub fn parse(self: *Self) ParserError![]*ASTNode {
    var nodes = ArrayList(*ASTNode).init(self.allocator);
    defer nodes.deinit();

    while (!self.match(TokenType.Eof)) {
        if (self.match(TokenType.NewLine) or self.match(TokenType.LineComment) or self.match(TokenType.MultilineComment)) {
            continue;
        }
        const node = try self.parseStatement();

        if (node.tag != .none) {
            try nodes.append(node);
        }
    }

    return try nodes.toOwnedSlice();
}

pub fn consume(self: *Self, token_type: TokenType, comptime error_msg: []const u8) ParserError!Token {
    if (self.token().type == token_type) {
        return self.advance();
    }

    try self.syntaxError(error_msg, .{});
    return error.SyntaxError;
}

pub fn consumeOrNull(self: *Self, token_type: TokenType) ?Token {
    if (self.token().type == token_type) {
        return self.advance();
    }

    return null;
}

pub fn syntaxError(self: *Self, comptime error_msg: []const u8, args: anytype) !void {
    try self.errors.append(try std.fmt.allocPrint(self.allocator, error_msg, args));
}

pub fn parseStatement(self: *Self) ParserError!*ASTNode {
    while (self.match(TokenType.NewLine)) {}

    if (self.match(TokenType.Semicolon)) {
        return ASTNode.new(self.allocator, .{ .tag = .none, .data = .{ .none = .{} } });
    }

    if (self.match(TokenType.Function)) {
        return try self.parseFunctionExpression(false);
    } else if (self.match(TokenType.Async) and self.match(TokenType.Function)) {
        return try self.parseFunctionExpression(true);
    } else if (self.match(TokenType.Import)) {
        return try self.parseImportStatement();
    } else if (self.peekMatch(TokenType.Var) or self.peekMatch(TokenType.Let) or self.peekMatch(TokenType.Const)) {
        return try self.parseDeclaration();
    }

    const node = try self.parseExpression();
    _ = try self.consume(TokenType.Semicolon, "Expected ';'");
    return node;
}

pub fn parseImportStatement(self: *Self) ParserError!*ASTNode {
    var nodes = ArrayList(*ASTNode).init(self.allocator);
    defer nodes.deinit();

    if (self.consumeOrNull(TokenType.StringConstant)) |path| {
        _ = try self.consume(TokenType.Semicolon, "Expected ';'");

        try nodes.append(try ASTNode.new(self.allocator, .{
            .tag = .import_path,
            .data = .{
                .literal = path.value.?,
            },
        }));

        return try ASTNode.new(self.allocator, .{
            .tag = .import,
            .data = .{
                .nodes = try nodes.toOwnedSlice(),
            },
        });
    }

    var parse_named_bindings = true;
    const default_as_type = self.match(TokenType.Type);
    if (self.consumeOrNull(TokenType.Identifier)) |identifier| {
        const tag: ASTNodeTag = if (default_as_type or self.match(TokenType.Type)) .import_type_binding_default else .import_binding_default;
        try nodes.append(try ASTNode.new(self.allocator, .{
            .tag = tag,
            .data = .{
                .literal = identifier.value.?,
            },
        }));
        if (!self.match(TokenType.Comma)) {
            parse_named_bindings = false;
        }
    }

    if (parse_named_bindings) {
        if (self.match(TokenType.OpenCurlyBrace)) {
            while (true) {
                if (self.match(TokenType.Semicolon) or self.match(TokenType.Eof)) {
                    try self.syntaxError("Unexpected end of statement", .{});
                    return error.SyntaxError;
                }

                const as_type = default_as_type or self.match(TokenType.Type);

                if (self.consumeOrNull(TokenType.Identifier)) |identifier| {
                    try nodes.append(try ASTNode.new(self.allocator, .{
                        .tag = if (as_type) .import_type_binding_named else .import_binding_named,
                        .data = .{
                            .literal = identifier.value.?,
                        },
                    }));
                }

                if (self.match(TokenType.CloseCurlyBrace)) {
                    break;
                }
                _ = try self.consume(TokenType.Comma, "Expected ','");
            }
        } else if (self.match(TokenType.Star)) {
            _ = try self.consume(TokenType.As, "Expected 'as' after '*'");
            const identifier = try self.consume(TokenType.Identifier, "Expected identifier");

            const tag: ASTNodeTag = if (default_as_type) .import_type_binding_namespace else .import_binding_namespace;
            try nodes.append(try ASTNode.new(self.allocator, .{
                .tag = tag,
                .data = .{
                    .literal = identifier.value.?,
                },
            }));
        } else {
            return error.SyntaxError;
        }
    }

    _ = try self.consume(TokenType.From, "Expected 'from'");
    const path_token = try self.consume(TokenType.StringConstant, "Expected string constant");
    _ = try self.consume(TokenType.Semicolon, "Expected ';'");

    try nodes.append(try ASTNode.new(self.allocator, .{
        .tag = .import_path,
        .data = .{
            .literal = path_token.value.?,
        },
    }));

    return try ASTNode.new(self.allocator, .{
        .tag = .import,
        .data = .{ .nodes = try nodes.toOwnedSlice() },
    });
}

pub fn parseFunctionExpression(self: *Self, is_async: bool) ParserError!*ASTNode {
    var name: []const u8 = "(anonymous)";
    var nodes = ArrayList(*ASTNode).init(self.allocator);
    defer nodes.deinit();

    if (self.consumeOrNull(TokenType.Identifier)) |identifier| {
        name = identifier.value.?;
    }

    try nodes.append(try ASTNode.new(self.allocator, .{
        .tag = .func_decl_name,
        .data = .{
            .literal = name,
        },
    }));

    _ = try self.consume(TokenType.OpenParen, "Expected '('");

    while (true) {
        if (self.match(TokenType.Semicolon) or self.match(TokenType.Eof)) {
            try self.syntaxError("Unexpected end of statement", .{});
            return error.SyntaxError;
        }

        if (self.consumeOrNull(TokenType.Identifier)) |identifier| {
            try nodes.append(try ASTNode.new(self.allocator, .{
                .tag = .func_decl_argument,
                .data = .{
                    .literal = identifier.value.?,
                },
            }));
        }

        if (self.match(TokenType.CloseParen)) {
            break;
        }

        _ = try self.consume(TokenType.Comma, "Expected ','");
    }

    _ = try self.consume(TokenType.OpenCurlyBrace, "Expected '{{'");

    const tag: ASTNodeTag = if (is_async) .async_func_decl else .func_decl;

    try nodes.append(try ASTNode.new(self.allocator, .{
        .tag = .block,
        .data = .{
            .nodes = try self.parseBlock(),
        },
    }));

    return try ASTNode.new(self.allocator, .{ .tag = tag, .data = .{ .nodes = try nodes.toOwnedSlice() } });
}

pub fn parseBlock(self: *Self) ParserError![]*ASTNode {
    std.log.info("parseBlock {}", .{self.token()});
    var statements = ArrayList(*ASTNode).init(self.allocator);
    defer statements.deinit();

    while (true) {
        if (self.match(TokenType.Eof)) {
            try self.syntaxError("Expected '}}'", .{});
            return error.SyntaxError;
        }

        if (self.match(TokenType.CloseCurlyBrace)) {
            break;
        }

        const statement = try self.parseStatement();

        if (statement.tag != .none) {
            try statements.append(statement);
        }

        while (self.match(TokenType.Semicolon) or self.match(TokenType.NewLine)) {}

        if (self.match(TokenType.CloseCurlyBrace)) {
            break;
        }
    }

    return statements.toOwnedSlice();
}

pub fn parseDeclaration(self: *Self) ParserError!*ASTNode {
    const tag: ASTNodeTag = switch (self.token().type) {
        .Var => .var_decl,
        .Let => .let_decl,
        .Const => .const_decl,
        else => unreachable,
    };
    _ = self.advance();

    var nodes = ArrayList(*ASTNode).init(self.allocator);
    defer nodes.deinit();

    while (true) {
        try nodes.append(try self.parseAssignment());

        if (!self.match(TokenType.Comma)) {
            break;
        }
    }

    return try ASTNode.new(self.allocator, .{
        .tag = tag,
        .data = .{
            .nodes = try nodes.toOwnedSlice(),
        },
    });
}

pub fn parseExpression(self: *Self) ParserError!*ASTNode {
    var node = try self.parseAssignment();
    while (self.match(TokenType.Comma)) {
        node = try ASTNode.new(self.allocator, .{ .tag = .comma, .data = .{ .binary = ASTBinaryNode{
            .left = node,
            .right = try self.parseAssignment(),
        } } });
    }

    return node;
}

pub fn parseAssignment(self: *Self) ParserError!*ASTNode {
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
        .GreaterThanGreaterThanEqual => .bitwise_shift_right,
        .GreaterThanGreaterThanGreaterThanEqual => .bitwise_unsigned_right_shift,
        .LessThanLessThanEqual => .bitwise_shift_left,
        else => return node,
    };
    _ = self.advance();
    node = try ASTNode.new(self.allocator, .{ .tag = tag, .data = .{ .binary = ASTBinaryNode{
        .left = node,
        .right = try self.parseAssignment(),
    } } });

    return node;
}

fn parseLogicalOr(self: *Self) ParserError!*ASTNode {
    var node = try self.parseLogicalAnd();

    while (self.match(TokenType.BarBar)) {
        node = try ASTNode.new(self.allocator, .{ .tag = .@"or", .data = .{ .binary = ASTBinaryNode{
            .left = node,
            .right = try self.parseLogicalAnd(),
        } } });
    }

    return node;
}

fn parseLogicalAnd(self: *Self) ParserError!*ASTNode {
    var node = try self.parseBitwiseOr();
    while (self.match(TokenType.AmpersandAmpersand)) {
        node = try ASTNode.new(self.allocator, .{ .tag = .@"and", .data = .{ .binary = ASTBinaryNode{
            .left = node,
            .right = try self.parseBitwiseOr(),
        } } });
    }

    return node;
}

fn parseBitwiseOr(self: *Self) ParserError!*ASTNode {
    var node = try self.parseBitwiseXor();

    while (self.match(TokenType.Bar)) {
        const right = try self.parseBitwiseXor();
        node = try ASTNode.new(self.allocator, .{ .tag = .bitwise_or, .data = .{ .binary = ASTBinaryNode{
            .left = node,
            .right = right,
        } } });
    }

    return node;
}

fn parseBitwiseXor(self: *Self) ParserError!*ASTNode {
    var node = try self.parseBitwiseAnd();

    while (self.match(TokenType.Caret)) {
        const right = try self.parseBitwiseAnd();
        node = try ASTNode.new(self.allocator, .{ .tag = .bitwise_xor, .data = .{ .binary = ASTBinaryNode{
            .left = node,
            .right = right,
        } } });
    }

    return node;
}

fn parseBitwiseAnd(self: *Self) ParserError!*ASTNode {
    var node = try self.parseEquality();

    while (self.match(TokenType.Ampersand)) {
        const right = try self.parseEquality();
        node = try ASTNode.new(self.allocator, .{ .tag = .bitwise_and, .data = .{ .binary = ASTBinaryNode{
            .left = node,
            .right = right,
        } } });
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
        node = try ASTNode.new(self.allocator, .{ .tag = tag, .data = .{ .binary = ASTBinaryNode{
            .left = node,
            .right = try self.parseRelational(),
        } } });
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
        node = try ASTNode.new(self.allocator, .{ .tag = tag, .data = .{ .binary = ASTBinaryNode{
            .left = node,
            .right = try self.parseShift(),
        } } });
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
        node = try ASTNode.new(self.allocator, .{ .tag = tag, .data = .{ .binary = ASTBinaryNode{
            .left = node,
            .right = try self.parseAdditive(),
        } } });
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
        node = try ASTNode.new(self.allocator, .{ .tag = tag, .data = .{ .binary = ASTBinaryNode{
            .left = node,
            .right = try self.parseMultiplicative(),
        } } });
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
        node = try ASTNode.new(self.allocator, .{ .tag = tag, .data = .{ .binary = ASTBinaryNode{
            .left = node,
            .right = try self.parseExponentiation(),
        } } });
    }

    return node;
}

fn parseExponentiation(self: *Self) ParserError!*ASTNode {
    var node = try self.parseUnary();

    while (self.match(TokenType.StarStar)) {
        const right = try self.parseUnary();
        node = try ASTNode.new(self.allocator, .{ .tag = .exp_expr, .data = .{ .binary = ASTBinaryNode{
            .left = node,
            .right = right,
        } } });
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
            .DotDotDot => .spread,
            .Typeof => .typeof,
            else => return try self.parseCallableExpression(),
        };
        _ = self.advance();
        return try ASTNode.new(self.allocator, .{ .tag = tag, .data = .{ .node = try self.parseCallableExpression() } });
    }
}

fn parseCallableExpression(self: *Self) ParserError!*ASTNode {
    var node = try self.parseIndexAccess();

    while (self.match(TokenType.OpenParen)) {
        var nodes = ArrayList(*ASTNode).init(self.allocator);
        defer nodes.deinit();

        try nodes.append(node);

        while (true) {
            if (self.match(TokenType.Semicolon) or self.match(TokenType.Eof)) {
                try self.syntaxError("Unexpected end of statement", .{});
                return error.SyntaxError;
            }

            if (self.match(TokenType.CloseParen)) {
                break;
            }

            if (self.match(TokenType.Comma)) {
                try self.syntaxError("Argument expression expected", .{});
                return error.SyntaxError;
            }

            try nodes.append(try self.parseAssignment());

            if (!self.match(TokenType.CloseParen)) {
                _ = try self.consume(TokenType.Comma, "Expected ','");
            } else {
                break;
            }
        }

        node = try ASTNode.new(self.allocator, .{ .tag = .call_expr, .data = .{ .nodes = try nodes.toOwnedSlice() } });
    }

    return node;
}

fn parseIndexAccess(self: *Self) ParserError!*ASTNode {
    var node = try self.parseArrayLiteral();

    while (self.match(TokenType.OpenSquareBracket)) {
        node = try ASTNode.new(self.allocator, .{ .tag = .index_access, .data = .{ .binary = ASTBinaryNode{
            .left = node,
            .right = try self.parseExpression(),
        } } });

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
        if (self.match(TokenType.Semicolon) or self.match(TokenType.Eof)) {
            try self.syntaxError("Unexpected end of array literal", .{});
            return error.SyntaxError;
        }

        while (self.match(TokenType.Comma)) {
            try values.append(try ASTNode.new(self.allocator, .{ .tag = .none, .data = .{ .none = .{} } }));
        }

        if (self.match(TokenType.CloseSquareBracket)) {
            break;
        }

        try values.append(try self.parseAssignment());
        const comma: ?Token = self.consumeOrNull(TokenType.Comma);

        if (self.match(TokenType.CloseSquareBracket)) {
            break;
        } else if (comma == null) {
            try self.syntaxError("Expected ','", .{});
            return error.SyntaxError;
        }
    }

    return try ASTNode.new(self.allocator, .{ .tag = .array_literal, .data = .{ .nodes = try values.toOwnedSlice() } });
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
        node = try ASTNode.new(self.allocator, .{ .tag = tag, .data = .{ .binary = ASTBinaryNode{
            .left = node,
            .right = try self.parseLiteral(),
        } } });
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
        if (self.match(TokenType.Semicolon) or self.match(TokenType.Eof)) {
            try self.syntaxError("Unexpected end of object literal", .{});
            return error.SyntaxError;
        }

        while (self.match(TokenType.NewLine)) {}

        const identifier = try self.parseLiteral();

        var comma: ?Token = null;
        if (self.match(TokenType.Colon)) {
            try nodes.append(try ASTNode.new(self.allocator, .{ .tag = .object_literal_field, .data = .{
                .binary = ASTBinaryNode{
                    .left = identifier,
                    .right = try self.parseAssignment(),
                },
            } }));
            comma = self.consumeOrNull(TokenType.Comma);
        } else {
            try self.syntaxError("Expected ':'", .{});
            return error.SyntaxError;
        }

        while (self.match(TokenType.NewLine)) {}

        std.log.info("{any}", .{comma});
        if (self.match(TokenType.CloseCurlyBrace)) {
            break;
        } else if (comma == null) {
            try self.syntaxError("Expected ','", .{});
            return error.SyntaxError;
        }
    }

    return try ASTNode.new(self.allocator, .{ .tag = .object_literal, .data = .{ .nodes = try nodes.toOwnedSlice() } });
}

fn parseLiteral(self: *Self) ParserError!*ASTNode {
    while (true) {
        if (self.match(TokenType.True)) {
            return try ASTNode.new(self.allocator, .{ .tag = .true, .data = .{ .none = .{} } });
        } else if (self.match(TokenType.False)) {
            return try ASTNode.new(self.allocator, .{ .tag = .false, .data = .{ .none = .{} } });
        } else if (self.match(TokenType.Null)) {
            return try ASTNode.new(self.allocator, .{ .tag = .null, .data = .{ .none = .{} } });
        } else if (self.match(TokenType.Undefined)) {
            return try ASTNode.new(self.allocator, .{ .tag = .undefined, .data = .{ .none = .{} } });
        } else if (self.consumeOrNull(TokenType.NumberConstant)) |number| {
            return try ASTNode.new(self.allocator, .{ .tag = .number, .data = .{ .literal = number.value.? } });
        } else if (self.consumeOrNull(TokenType.BigIntConstant)) |bigint| {
            return try ASTNode.new(self.allocator, .{ .tag = .bigint, .data = .{ .literal = bigint.value.? } });
        } else if (self.consumeOrNull(TokenType.StringConstant)) |string| {
            return try ASTNode.new(self.allocator, .{ .tag = .string, .data = .{ .literal = string.value.? } });
        } else if (self.consumeOrNull(TokenType.Identifier)) |identifier| {
            return try ASTNode.new(self.allocator, .{ .tag = .identifier, .data = .{ .literal = identifier.value.? } });
        } else {
            break;
        }
    }

    if (self.match(TokenType.OpenParen)) {
        const node = try ASTNode.new(self.allocator, .{ .tag = .grouping, .data = .{ .node = try self.parseExpression() } });
        _ = try self.consume(TokenType.CloseParen, "Expected ')'");
        return node;
    }

    try self.syntaxError("Unexpected token {}", .{self.token()});
    return error.SyntaxError;
}

test {
    _ = @import("tests/parser.zig");
}
