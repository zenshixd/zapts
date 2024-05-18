const std = @import("std");
const ArrayList = std.ArrayList;

const String = @import("string.zig").String;
const sym = @import("symbol_table.zig");
const SymbolTable = sym.SymbolTable;
const Symbol = sym.Symbol;

const consts = @import("consts.zig");
const Token = consts.Token;
const TokenType = consts.TokenType;

pub const ParserError = error{ SyntaxError, OutOfMemory };

pub const ASTImportBinding = struct {
    as_type: bool,
    as_namespace: bool,
    default: bool,
    name: []const u8,
};

pub const ASTImportNode = struct {
    symbols: []ASTImportBinding,
    path: []const u8,
};

pub const ASTFunctionExpressionNode = struct {
    name: []const u8,
    arguments: [][]const u8,
    body: []*ASTNode,
};

pub const ASTCallableExpressionNode = struct {
    left: *ASTNode,
    arguments: []*ASTNode,
};

pub const ASTObjectLiteralNode = struct {
    fields: []*ASTNode,
    values: []*ASTNode,
};

pub const ASTBinaryNode = struct {
    left: *ASTNode,
    right: *ASTNode,
};

pub const ASTNoneNode = struct {};

pub const ASTNodeTag = enum {
    simple_import,
    import,
    var_decl,
    const_decl,
    let_decl,
    block,
    assignment,
    async_func_decl,
    func_decl,
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
        import: ASTImportNode,
        function: ASTFunctionExpressionNode,
        callable: ASTCallableExpressionNode,
        object_literal: ASTObjectLiteralNode,
        none: ASTNoneNode,
    },

    pub fn new(allocator: std.mem.Allocator, value: ASTNode) !*ASTNode {
        const node = try allocator.create(ASTNode);
        node.* = value;
        return node;
    }
};

const Self = @This();

allocator: std.mem.Allocator,
symbols: SymbolTable,
tokens: []Token,
index: usize = 0,

pub fn init(allocator: std.mem.Allocator, tokens: []Token) Self {
    return Self{
        .tokens = tokens,
        .allocator = allocator,
        .symbols = SymbolTable.init(allocator),
    };
}

pub fn token(self: Self) Token {
    return self.tokens[self.index];
}

pub fn advance(self: *Self) Token {
    const t = self.token();
    std.log.info("advance {}", .{t});
    self.index += 1;
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

pub fn parse(self: *Self) ParserError!ArrayList(*ASTNode) {
    var nodes = ArrayList(*ASTNode).init(self.allocator);

    while (!self.match(TokenType.Eof)) {
        if (self.match(TokenType.NewLine)) {
            continue;
        }
        const node = try self.parseStatement();

        if (node.tag != .none) {
            try nodes.append(node);
        }
    }

    return nodes;
}

pub fn consume(self: *Self, token_type: TokenType, error_msg: []const u8) ParserError!Token {
    if (self.token().type == token_type) {
        return self.advance();
    }

    return try syntaxError(Token, error_msg);
}

pub fn consumeOrNull(self: *Self, token_type: TokenType) ?Token {
    if (self.token().type == token_type) {
        return self.advance();
    }

    return null;
}

pub fn syntaxError(return_type: type, error_msg: []const u8) ParserError!return_type {
    std.log.err("SyntaxError: {s}", .{error_msg});
    return error.SyntaxError;
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
    if (self.consumeOrNull(TokenType.StringConstant)) |path| {
        _ = try self.consume(TokenType.Semicolon, "Expected ';'");

        return try ASTNode.new(self.allocator, .{ .tag = .simple_import, .data = .{ .literal = path.value.? } });
    }

    var symbols = ArrayList(ASTImportBinding).init(self.allocator);
    defer symbols.deinit();

    const default_as_type = self.match(TokenType.Type);
    if (self.consumeOrNull(TokenType.Identifier)) |identifier| {
        const as_type = default_as_type or self.match(TokenType.Type);
        try symbols.append(ASTImportBinding{
            .as_type = as_type,
            .as_namespace = false,
            .default = true,
            .name = identifier.value.?,
        });

        if (self.match(TokenType.Comma)) {
            try self.parseImportBindings(default_as_type, &symbols);
        }
    } else {
        try self.parseImportBindings(default_as_type, &symbols);
    }

    _ = try self.consume(TokenType.From, "Expected 'from'");
    const path_token = try self.consume(TokenType.StringConstant, "Expected string constant");
    _ = try self.consume(TokenType.Semicolon, "Expected ';'");

    return try ASTNode.new(self.allocator, .{ .tag = .import, .data = .{ .import = ASTImportNode{
        .path = path_token.value.?,
        .symbols = try symbols.toOwnedSlice(),
    } } });
}

fn parseImportBindings(self: *Self, default_as_type: bool, symbols: *ArrayList(ASTImportBinding)) ParserError!void {
    if (self.match(TokenType.OpenCurlyBrace)) {
        while (true) {
            if (self.match(TokenType.Semicolon) or self.match(TokenType.Eof)) {
                return syntaxError(void, "Unexpected end of statement");
            }

            const as_type = default_as_type or self.match(TokenType.Type);

            if (self.consumeOrNull(TokenType.Identifier)) |identifier| {
                try symbols.append(ASTImportBinding{
                    .as_type = as_type,
                    .as_namespace = false,
                    .default = false,
                    .name = identifier.value.?,
                });
            }

            if (self.match(TokenType.CloseCurlyBrace)) {
                break;
            }
            _ = try self.consume(TokenType.Comma, "Expected ','");
        }
    } else if (self.match(TokenType.Star)) {
        _ = try self.consume(TokenType.As, "Expected 'as' after '*'");
        const identifier = try self.consume(TokenType.Identifier, "Expected identifier");
        try symbols.append(ASTImportBinding{
            .as_type = default_as_type,
            .as_namespace = true,
            .default = false,
            .name = identifier.value.?,
        });
    } else {
        return error.SyntaxError;
    }
}

pub fn parseFunctionExpression(self: *Self, is_async: bool) ParserError!*ASTNode {
    var name: []const u8 = "(anonymous)";
    var arguments = ArrayList([]const u8).init(self.allocator);
    defer arguments.deinit();

    if (self.consumeOrNull(TokenType.Identifier)) |identifier| {
        name = identifier.value.?;
    }

    _ = try self.consume(TokenType.OpenParen, "Expected '('");

    while (true) {
        if (self.match(TokenType.Semicolon) or self.match(TokenType.Eof)) {
            return syntaxError(*ASTNode, "Unexpected end of statement");
        }

        if (self.consumeOrNull(TokenType.Identifier)) |identifier| {
            try arguments.append(identifier.value.?);
        }

        if (self.match(TokenType.CloseParen)) {
            break;
        }

        _ = try self.consume(TokenType.Comma, "Expected ','");
    }

    _ = try self.consume(TokenType.OpenCurlyBrace, "Expected '{'");

    const tag: ASTNodeTag = if (is_async) .async_func_decl else .func_decl;

    return try ASTNode.new(self.allocator, .{ .tag = tag, .data = .{ .function = ASTFunctionExpressionNode{
        .name = name,
        .arguments = try arguments.toOwnedSlice(),
        .body = try self.parseBlock(),
    } } });
}

pub fn parseBlock(self: *Self) ParserError![]*ASTNode {
    std.log.info("parseBlock {}", .{self.token()});
    var statements = ArrayList(*ASTNode).init(self.allocator);
    defer statements.deinit();

    while (true) {
        if (self.match(TokenType.Eof)) {
            return syntaxError([]*ASTNode, "Expected '}'");
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

    return try ASTNode.new(self.allocator, .{ .tag = tag, .data = .{ .node = try self.parseAssignment() } });
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

    while (true) {
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
            else => break,
        };
        _ = self.advance();
        node = try ASTNode.new(self.allocator, .{ .tag = tag, .data = .{ .binary = ASTBinaryNode{
            .left = node,
            .right = try self.parseLogicalOr(),
        } } });
    }

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
        var arguments = ArrayList(*ASTNode).init(self.allocator);
        defer arguments.deinit();

        while (true) {
            if (self.match(TokenType.Semicolon) or self.match(TokenType.Eof)) {
                return syntaxError(*ASTNode, "Unexpected end of statement");
            }

            if (self.match(TokenType.CloseParen)) {
                break;
            }

            if (self.match(TokenType.Comma)) {
                return syntaxError(*ASTNode, "Argument expression expected");
            }

            try arguments.append(try self.parseAssignment());

            if (!self.match(TokenType.CloseParen)) {
                _ = try self.consume(TokenType.Comma, "Expected ','");
            } else {
                break;
            }
        }

        node = try ASTNode.new(self.allocator, .{ .tag = .call_expr, .data = .{ .callable = ASTCallableExpressionNode{
            .left = node,
            .arguments = try arguments.toOwnedSlice(),
        } } });
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
            return syntaxError(*ASTNode, "Unexpected end of array literal");
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
            return syntaxError(*ASTNode, "Expected ','");
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
    std.debug.print("parseObjectLiteral\n", .{});
    var fields = ArrayList(*ASTNode).init(self.allocator);
    var values = ArrayList(*ASTNode).init(self.allocator);
    defer fields.deinit();
    defer values.deinit();

    while (true) {
        if (self.match(TokenType.Semicolon) or self.match(TokenType.Eof)) {
            return syntaxError(*ASTNode, "Unexpected end of object literal");
        }

        while (self.match(TokenType.NewLine)) {}

        const identifier = try self.parseLiteral();

        var comma: ?Token = null;
        if (self.match(TokenType.Colon)) {
            try fields.append(identifier);
            try values.append(try self.parseAssignment());
            comma = self.consumeOrNull(TokenType.Comma);
        } else {
            return syntaxError(*ASTNode, "Expected ':'");
        }

        while (self.match(TokenType.NewLine)) {}

        std.log.info("{any}", .{comma});
        if (self.match(TokenType.CloseCurlyBrace)) {
            break;
        } else if (comma == null) {
            return syntaxError(*ASTNode, "Expected ','");
        }
    }

    return try ASTNode.new(self.allocator, .{ .tag = .object_literal, .data = .{ .object_literal = .{ .fields = try fields.toOwnedSlice(), .values = try values.toOwnedSlice() } } });
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

    const error_msg = try std.fmt.allocPrint(self.allocator, "Unexpected token {}", .{self.token()});
    return syntaxError(*ASTNode, error_msg);
}
