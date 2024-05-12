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

pub const ImportType = enum { basic, star_import, named_import, default_import };

pub const ASTImportStatementNode = struct {
    only_type: bool,
    type: ImportType,
    symbols: ArrayList([]const u8),
    path: []const u8,
};

pub const ASTDeclarationNode = struct {
    type: TokenType,
    name: []const u8,
};

pub const ASTAssignmentNode = struct {
    left: *ASTNode,
    right: *ASTNode,
};

pub const ASTBlockNode = struct {
    statements: ArrayList(*ASTNode),
};

pub const ASTFunctionExpressionNode = struct {
    is_async: bool,
    name: []const u8,
    arguments: ArrayList([]const u8),
    body: *ASTNode,
};

pub const ASTCallableExpressionNode = struct {
    left: *ASTNode,
    arguments: ArrayList(*ASTNode),
};

pub const ASTLiteralNode = struct {
    value: Token,
};

pub const ASTUnaryExpressionNode = struct {
    operator: TokenType,
    right: *ASTNode,
};

pub const ASTBinaryExpressionNode = struct {
    left: *ASTNode,
    operator: TokenType,
    right: *ASTNode,
};

pub const ASTExpressionNode = struct {
    expression: *ASTNode,
};

pub const ASTNode = union(enum) {
    declaration: ASTDeclarationNode,
    import_statement: ASTImportStatementNode,
    block: ASTBlockNode,
    assignment: ASTAssignmentNode,
    function_expression: ASTFunctionExpressionNode,
    callable_expression: ASTCallableExpressionNode,
    expression: ASTExpressionNode,
    binary: ASTBinaryExpressionNode,
    unary: ASTUnaryExpressionNode,
    literal: ASTLiteralNode,

    pub fn init(allocator: std.mem.Allocator, value: ASTNode) !*ASTNode {
        const node = try allocator.create(ASTNode);
        node.* = value;
        return node;
    }
};

const Self = @This();

allocator: std.mem.Allocator,
symbols: SymbolTable,
tokens: ArrayList(Token),
index: usize = 0,

pub fn init(allocator: std.mem.Allocator, tokens: ArrayList(Token)) Self {
    return Self{
        .tokens = tokens,
        .allocator = allocator,
        .symbols = SymbolTable.init(allocator),
    };
}

pub fn token(self: Self) Token {
    return self.tokens.items[self.index];
}

pub fn advance(self: *Self) Token {
    const t = self.token();
    // std.debug.print("advance {}\n", .{t});
    self.index += 1;
    return t;
}

pub fn match(self: *Self, token_type: TokenType) bool {
    if (self.index < self.tokens.items.len and self.token().type == token_type) {
        _ = self.advance();
        return true;
    }
    return false;
}

pub fn peekMatch(self: Self, token_type: TokenType) bool {
    if (self.index < self.tokens.items.len and self.token().type == token_type) {
        return true;
    }
    return false;
}

pub fn parse(self: *Self) ParserError!ArrayList(*ASTNode) {
    var nodes = ArrayList(*ASTNode).init(self.allocator);

    while (!self.match(TokenType.Eof)) {
        if (self.match(TokenType.NewLine)) {
            continue;
        }
        const node = try self.parseStatement();
        try nodes.append(node);
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
    while (self.match(TokenType.Semicolon) or self.match(TokenType.NewLine)) {}

    if (self.match(TokenType.Import)) {
        return try self.parseImportStatement();
    } else if (self.peekMatch(TokenType.Var) or self.peekMatch(TokenType.Let) or self.peekMatch(TokenType.Const)) {
        return try self.parseDeclaration();
    } else if (self.match(TokenType.Function)) {
        return try self.parseFunctionExpression(false);
    } else if (self.match(TokenType.Async) and self.match(TokenType.Function)) {
        return try self.parseFunctionExpression(true);
    }

    const node = try self.parseExpression();
    _ = try self.consume(TokenType.Semicolon, "Expected ';'");
    return node;
}

pub fn parseImportStatement(self: *Self) ParserError!*ASTNode {
    var node = try ASTNode.init(self.allocator, .{ .import_statement = ASTImportStatementNode{
        .only_type = false,
        .type = ImportType.basic,
        .symbols = ArrayList([]const u8).init(self.allocator),
        .path = undefined,
    } });

    if (self.match(TokenType.Type)) {
        node.import_statement.only_type = true;
    }

    if (self.consumeOrNull(TokenType.Identifier)) |identifier| {
        node.import_statement.type = ImportType.default_import;
        try node.import_statement.symbols.append(identifier.value.?);
        _ = try self.consume(TokenType.From, "Expected from");
    } else if (self.consumeOrNull(TokenType.StringConstant)) |path| {
        node.import_statement.type = .basic;
        node.import_statement.path = path.value.?;
        _ = try self.consume(TokenType.Semicolon, "Expected ';'");

        return node;
    } else if (self.match(TokenType.OpenCurlyBrace)) {
        node.import_statement.type = ImportType.named_import;

        while (true) {
            if (self.match(TokenType.Semicolon) or self.match(TokenType.Eof)) {
                return syntaxError(*ASTNode, "Unexpected end of statement");
            }

            if (self.consumeOrNull(TokenType.Identifier)) |identifier| {
                try node.import_statement.symbols.append(identifier.value.?);
            }

            if (self.match(TokenType.CloseCurlyBrace)) {
                break;
            }

            _ = try self.consume(TokenType.Comma, "Expected ','");
        }

        _ = try self.consume(TokenType.From, "Expected 'from'");
    } else if (self.match(TokenType.Star)) {
        node.import_statement.type = ImportType.star_import;
        _ = try self.consume(TokenType.As, "Expected 'as' after '*'");
        const identifier = try self.consume(TokenType.Identifier, "Expected identifier");
        try node.import_statement.symbols.append(identifier.value.?);
        _ = try self.consume(TokenType.From, "Expected 'from'");
    } else {
        return error.SyntaxError;
    }

    const path_token = try self.consume(TokenType.StringConstant, "Expected string constant");
    node.import_statement.path = path_token.value.?;
    _ = try self.consume(TokenType.Semicolon, "Expected ';'");

    return node;
}

pub fn parseFunctionExpression(self: *Self, is_async: bool) ParserError!*ASTNode {
    var node = try ASTNode.init(self.allocator, .{ .function_expression = ASTFunctionExpressionNode{
        .is_async = is_async,
        .name = "(anonymous)",
        .arguments = ArrayList([]const u8).init(self.allocator),
        .body = undefined,
    } });

    if (self.consumeOrNull(TokenType.Identifier)) |identifier| {
        node.function_expression.name = identifier.value.?;
    }

    _ = try self.consume(TokenType.OpenParen, "Expected '('");

    while (true) {
        if (self.match(TokenType.Semicolon) or self.match(TokenType.Eof)) {
            return syntaxError(*ASTNode, "Unexpected end of statement");
        }

        if (self.consumeOrNull(TokenType.Identifier)) |identifier| {
            try node.function_expression.arguments.append(identifier.value.?);
        }

        if (self.match(TokenType.CloseParen)) {
            break;
        }

        _ = try self.consume(TokenType.Comma, "Expected ','");
    }

    _ = try self.consume(TokenType.OpenCurlyBrace, "Expected '{'");
    node.function_expression.body = try self.parseBlock();

    return node;
}

pub fn parseBlock(self: *Self) ParserError!*ASTNode {
    std.log.info("parseBlock {}", .{self.token()});
    var statements = ArrayList(*ASTNode).init(self.allocator);
    const node = try ASTNode.init(self.allocator, .{ .block = ASTBlockNode{
        .statements = statements,
    } });

    while (true) {
        if (self.match(TokenType.Eof)) {
            return syntaxError(*ASTNode, "Expected '}'");
        }

        try statements.append(try self.parseStatement());

        while (self.match(TokenType.Semicolon) or self.match(TokenType.NewLine)) {}

        if (self.match(TokenType.CloseCurlyBrace)) {
            break;
        }
    }

    return node;
}

pub fn parseDeclaration(self: *Self) ParserError!*ASTNode {
    var node = try ASTNode.init(self.allocator, .{ .declaration = ASTDeclarationNode{
        .type = undefined,
        .name = undefined,
    } });

    if (self.match(TokenType.Var)) {
        node.declaration.type = TokenType.Var;
    } else if (self.match(TokenType.Let)) {
        node.declaration.type = TokenType.Let;
    } else if (self.match(TokenType.Const)) {
        node.declaration.type = TokenType.Const;
    } else {
        unreachable;
    }

    const identifier = try self.consume(TokenType.Identifier, "Expected identifier");
    node.declaration.name = identifier.value.?;

    if (self.match(TokenType.Semicolon)) {
        return node;
    }

    _ = try self.consume(TokenType.Equal, "Expected '='");
    return try self.parseAssignment(node);
}

pub fn parseAssignment(self: *Self, left: *ASTNode) ParserError!*ASTNode {
    const node = try ASTNode.init(self.allocator, .{ .assignment = ASTAssignmentNode{
        .left = left,
        .right = try self.parseUnary(),
    } });

    _ = try self.consume(TokenType.Semicolon, "Expected ';'");
    return node;
}

pub fn parseExpression(self: *Self) ParserError!*ASTNode {
    return self.parseLogical();
}

pub fn parseLogical(self: *Self) ParserError!*ASTNode {
    var node = try self.parseComparison();
    // zig fmt: off
    while (self.peekMatch(TokenType.AmpersandAmpersand)
        or self.peekMatch(TokenType.BarBar)) {
    // zig fmt: on
        const operator = self.advance().type;
        const right = try self.parseComparison();
        node = try ASTNode.init(self.allocator, .{ .binary = ASTBinaryExpressionNode{
            .left = node,
            .operator = operator,
            .right = right,
        } });
    }

    return node;
}

pub fn parseComparison(self: *Self) ParserError!*ASTNode {
    var node = try self.parseTerm();
    // zig fmt: off
    while (self.peekMatch(TokenType.EqualEqual)
        or self.peekMatch(TokenType.EqualEqualEqual)
        or self.peekMatch(TokenType.ExclamationMarkEqual)
        or self.peekMatch(TokenType.ExclamationMarkEqualEqual)
        or self.peekMatch(TokenType.GreaterThan)
        or self.peekMatch(TokenType.GreaterThanEqual)
        or self.peekMatch(TokenType.LessThan)
        or self.peekMatch(TokenType.LessThanEqual)) {
    // zig fmt: on
        const operator = self.advance().type;
        const right = try self.parseTerm();
        node = try ASTNode.init(self.allocator, .{ .binary = ASTBinaryExpressionNode{
            .left = node,
            .operator = operator,
            .right = right,
        } });
    }

    return node;
}

fn parseTerm(self: *Self) ParserError!*ASTNode {
    var node = try self.parseFactor();
    // zig fmt: off
    while (self.peekMatch(TokenType.Plus)
        or self.peekMatch(TokenType.Minus)) {
    // zig fmt: on
        const operator = self.advance().type;
        const right = try self.parseFactor();
        node = try ASTNode.init(self.allocator, .{ .binary = ASTBinaryExpressionNode{
            .left = node,
            .operator = operator,
            .right = right,
        } });
    }

    return node;
}

fn parseFactor(self: *Self) ParserError!*ASTNode {
    var node = try self.parseExponentiation();

    // zig fmt: off
    while (self.peekMatch(TokenType.Star)
        or self.peekMatch(TokenType.StarStar)
        or self.peekMatch(TokenType.Slash)
        or self.peekMatch(TokenType.Percent)) {
    // zig fmt: on
        const operator = self.advance().type;
        const right = try self.parseExponentiation();
        node = try ASTNode.init(self.allocator, .{ .binary = ASTBinaryExpressionNode{
            .left = node,
            .operator = operator,
            .right = right,
        } });
    }

    return node;
}

fn parseExponentiation(self: *Self) ParserError!*ASTNode {
    var node = try self.parseUnary();
    // zig fmt: off
    while (self.peekMatch(TokenType.StarStar)) {
        // zig fmt: on
        const operator = self.advance().type;
        const right = try self.parseUnary();
        node = try ASTNode.init(self.allocator, .{ .binary = ASTBinaryExpressionNode{
            .left = node,
            .operator = operator,
            .right = right,
        } });
    }

    return node;
}

fn parseUnary(self: *Self) ParserError!*ASTNode {
    // zig fmt: off
    if (self.peekMatch(TokenType.Minus)
        or self.peekMatch(TokenType.Plus)
        or self.peekMatch(TokenType.ExclamationMark)
        or self.peekMatch(TokenType.Tilde)
        or self.peekMatch(TokenType.DotDotDot)) {
    // zig fmt: on
        return ASTNode.init(self.allocator, .{ .unary = ASTUnaryExpressionNode{
            .operator = self.advance().type,
            .right = try self.parseCallableExpression(),
        } });
    }

    return try self.parseCallableExpression();
}

fn parseCallableExpression(self: *Self) ParserError!*ASTNode {
    var node = try self.parsePropertyAccess();

    while (self.match(TokenType.OpenParen)) {
        node = try ASTNode.init(self.allocator, .{ .callable_expression = ASTCallableExpressionNode{
            .left = node,
            .arguments = ArrayList(*ASTNode).init(self.allocator),
        } });

        while (true) {
            if (self.match(TokenType.Semicolon) or self.match(TokenType.Eof)) {
                return syntaxError(*ASTNode, "Unexpected end of statement");
            }

            if (self.match(TokenType.CloseParen)) {
                break;
            }

            if (self.match(TokenType.Comma)) {
                continue;
            }

            try node.callable_expression.arguments.append(try self.parseExpression());

            if (!self.match(TokenType.CloseParen)) {
                _ = try self.consume(TokenType.Comma, "Expected ','");
            } else {
                break;
            }
        }
    }

    return node;
}

fn parsePropertyAccess(self: *Self) ParserError!*ASTNode {
    var node = try self.parseLiteral();

    while (self.match(TokenType.Dot)) {
        node = try ASTNode.init(self.allocator, .{ .binary = ASTBinaryExpressionNode{
            .left = node,
            .operator = TokenType.Dot,
            .right = try self.parseLiteral(),
        } });
    }

    return node;
}

fn parseLiteral(self: *Self) ParserError!*ASTNode {
    var node = try ASTNode.init(self.allocator, .{ .literal = ASTLiteralNode{
        .value = undefined,
    } });
    // zig fmt: off
    if (self.peekMatch(TokenType.True)
        or self.peekMatch(TokenType.False)
        or self.peekMatch(TokenType.Null)
        or self.peekMatch(TokenType.Undefined)
        or self.peekMatch(TokenType.NumberConstant)
        or self.peekMatch(TokenType.BigIntConstant)
        or self.peekMatch(TokenType.StringConstant)
        or self.peekMatch(TokenType.Identifier)) {
        node.literal.value = self.advance();
        return node;
    }
    // zig fmt: on

    // if (self.match(TokenType.OpenParen)) {
    //     node.expression = .{
    //         .expression = try self.expression(),
    //     };
    //     try self.consume(TokenType.CloseParen, "Expected ')'");
    //     return node;
    // }

    std.log.info("cannot parse token {}", .{self.token()});
    unreachable;
}
