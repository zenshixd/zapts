const std = @import("std");
const assert = std.debug.assert;
const expectEqual = std.testing.expectEqual;
const expectEqualStrings = std.testing.expectEqualStrings;
const expectError = std.testing.expectError;

const ArrayList = std.ArrayList;

const Lexer = @import("lexer.zig");
const AST = @import("ast.zig");

const parseImportStatement = @import("parser/imports.zig").parseImportStatement;
const parseExportStatement = @import("parser/imports.zig").parseExportStatement;
const parseAssignment = @import("parser/binary.zig").parseAssignment;
const parseBreakableStatement = @import("parser/loops.zig").parseBreakableStatement;
const parseBinaryExpression = @import("parser/binary.zig").parseBinaryExpression;
const parsePrimaryExpression = @import("parser/primary.zig").parsePrimaryExpression;
const parseKeywordAsIdentifier = @import("parser/primary.zig").parseKeywordAsIdentifier;
const parseIdentifier = @import("parser/primary.zig").parseIdentifier;
const parseLiteral = @import("parser/primary.zig").parseLiteral;
const parseArrayLiteral = @import("parser/primary.zig").parseArrayLiteral;
const parseObjectLiteral = @import("parser/primary.zig").parseObjectLiteral;

const diagnostics = @import("diagnostics.zig");

const consts = @import("consts.zig");
const Token = consts.Token;
const TokenType = consts.TokenType;

pub const ParserError = error{ SyntaxError, OutOfMemory, NoSpaceLeft, Overflow };

const Self = @This();

gpa: std.mem.Allocator,
lexer: Lexer,
arena: std.heap.ArenaAllocator,
cur_token: Token.Index,
pool: AST.Pool,
errors: std.ArrayList([]const u8),

pub fn init(gpa: std.mem.Allocator, buffer: []const u8) !Self {
    var lexer = Lexer.init(gpa, buffer);
    try lexer.tokenize();

    return Self{
        .cur_token = 0,
        .gpa = gpa,
        .arena = std.heap.ArenaAllocator.init(gpa),
        .lexer = lexer,
        .pool = AST.Pool.init(gpa),
        .errors = std.ArrayList([]const u8).init(gpa),
    };
}

pub fn deinit(self: *Self) void {
    self.arena.deinit();
    self.errors.deinit();
    self.pool.deinit();
    self.lexer.deinit();
}

pub fn parse(self: *Self) ParserError!AST.Node.Index {
    var nodes = std.ArrayList(AST.Node.Index).init(self.arena.allocator());
    defer nodes.deinit();

    while (!self.match(TokenType.Eof)) {
        if (self.match(TokenType.NewLine) or self.match(TokenType.LineComment) or self.match(TokenType.MultilineComment)) {
            continue;
        }

        try nodes.append(try self.parseStatement());
    }

    const subrange = try self.pool.listToSubrange(nodes.items);

    assert(self.pool.nodes.items[0].tag == .root);
    self.pool.nodes.items[0].data = .{ .lhs = subrange.start, .rhs = subrange.end };
    return 0;
}

pub fn token(self: Self) Token {
    return self.lexer.getToken(self.cur_token);
}

pub fn advance(self: *Self) Token.Index {
    //std.debug.print("advancing from {}\n", .{self.lexer.getToken(self.cur_token)});
    if (self.cur_token + 1 < self.lexer.tokens().len) {
        self.cur_token += 1;
    }
    return self.cur_token;
}

pub fn match(self: *Self, token_type: TokenType) bool {
    if (self.peekMatch(token_type)) {
        _ = self.advance();
        return true;
    }
    return false;
}

pub fn peekMatch(self: Self, token_type: TokenType) bool {
    return self.token().type == token_type;
}

pub fn peekMatchMany(self: Self, comptime token_types: anytype) bool {
    inline for (token_types, 0..) |tok_type, i| {
        if (self.lexer.getToken(self.cur_token + i).type != tok_type) {
            return false;
        }
    }
    return true;
}

pub fn consume(self: *Self, token_type: TokenType, comptime error_msg: diagnostics.DiagnosticMessage, args: anytype) ParserError!Token.Index {
    if (self.consumeOrNull(token_type)) |tok| {
        return tok;
    }

    return self.fail(error_msg, args);
}

pub fn consumeOrNull(self: *Self, token_type: TokenType) ?Token.Index {
    if (self.token().type == token_type) {
        const tok = self.cur_token;
        _ = self.advance();
        return tok;
    }

    return null;
}

pub fn rewind(self: *Self) void {
    if (self.cur_token - 1 >= 0) {
        self.cur_token -= 1;
    }
}

pub fn fail(self: *Self, comptime error_msg: diagnostics.DiagnosticMessage, args: anytype) ParserError {
    try self.emitError(error_msg, args);
    return ParserError.SyntaxError;
}

pub fn emitError(self: *Self, comptime error_msg: diagnostics.DiagnosticMessage, args: anytype) ParserError!void {
    // std.debug.print("TS" ++ error_msg.code ++ ": " ++ error_msg.message ++ "\n", args);
    // std.debug.print("Token {}\n", .{self.token()});
    try self.errors.append(
        try std.fmt.allocPrint(
            self.arena.allocator(),
            "TS" ++ error_msg.code ++ ": " ++ error_msg.message,
            args,
        ),
    );
    try self.errors.append(try std.fmt.allocPrint(self.arena.allocator(), "Token: {}", .{self.token()}));
}

pub fn parseStatement(self: *Self) ParserError!AST.Node.Index {
    const node = try self.parseBlock() orelse
        try self.parseDeclaration() orelse
        try self.parseClassStatement(false) orelse
        try self.parseAbstractClassStatement() orelse
        try parseImportStatement(self) orelse
        try parseExportStatement(self) orelse
        try self.parseEmptyStatement() orelse
        try self.parseIfStatement() orelse
        try parseBreakableStatement(self) orelse
        try self.parseReturnStatement() orelse
        //try self.parseTypeDeclaration() orelse
        //try self.parseInterfaceDeclaration() orelse
        try self.parseExpression();

    if (needsSemicolon(self.pool, node)) {
        _ = try self.consume(TokenType.Semicolon, diagnostics.ARG_expected, .{";"});
    }
    return node;
}

pub fn parseAbstractClassStatement(self: *Self) ParserError!?AST.Node.Index {
    if (!self.match(TokenType.Abstract)) {
        return null;
    }

    return try self.parseClassStatement(true) orelse {
        self.rewind();
        return null;
    };
}

pub fn parseClassStatement(self: *Self, is_abstract: bool) ParserError!?AST.Node.Index {
    if (!self.match(TokenType.Class)) {
        return null;
    }

    const name = self.consumeOrNull(TokenType.Identifier);
    var super_class: AST.Node.Index = AST.Node.Empty;
    if (self.match(TokenType.Extends)) {
        super_class = try self.parseCallableExpression() orelse return self.fail(diagnostics.identifier_expected, .{});
    }

    var implements_list: ?[]AST.Node.Index = null;
    if (self.match(TokenType.Implements)) {
        implements_list = try self.parseInterfaceList();
    }
    var body = std.ArrayList(AST.Node.Index).init(self.arena.allocator());
    defer body.deinit();

    _ = try self.consume(TokenType.OpenCurlyBrace, diagnostics.ARG_expected, .{"{"});
    while (true) {
        if (self.match(TokenType.CloseCurlyBrace)) {
            break;
        }

        if (self.match(TokenType.Semicolon)) {
            continue;
        }

        try body.append(try self.parseClassStaticMember());
    }
    return try self.pool.addNode(self.cur_token, AST.Node{ .class = .{
        .abstract = is_abstract,
        .name = name orelse AST.Node.Empty,
        .super_class = super_class,
        .implements = implements_list orelse &[_]AST.Node.Index{},
        .body = body.items,
    } });
}

fn parseInterfaceList(self: *Self) ParserError![]AST.Node.Index {
    var list = std.ArrayList(AST.Node.Index).init(self.arena.allocator());

    while (true) {
        if (!self.match(TokenType.Identifier) and !try parseKeywordAsIdentifier(self)) {
            return self.fail(diagnostics.identifier_expected, .{});
        }
        try list.append(try self.pool.addNode(self.cur_token - 1, AST.Node{
            .simple_value = .{ .kind = .identifier },
        }));
        if (!self.match(TokenType.Comma)) {
            break;
        }
    }
    return list.toOwnedSlice();
}

fn parseClassStaticMember(self: *Self) ParserError!AST.Node.Index {
    if (self.match(TokenType.Static)) {
        if (self.match(TokenType.OpenCurlyBrace)) {
            var block = std.ArrayList(AST.Node.Index).init(self.arena.allocator());
            defer block.deinit();

            while (true) {
                if (self.match(TokenType.CloseCurlyBrace)) {
                    break;
                }
                const field = try self.parseClassMember();
                try block.append(field);
            }

            return try self.pool.addNode(self.cur_token, AST.Node{
                .class_static_block = block.items,
            });
        }

        return try self.pool.addNode(self.cur_token, AST.Node{ .class_member = .{
            .flags = AST.ClassMemberFlags.static,
            .node = try self.parseClassMember(),
        } });
    }
    return try self.parseClassMember();
}

fn parseClassMember(self: *Self) ParserError!AST.Node.Index {
    var flags: u8 = 0;
    if (self.match(TokenType.Abstract)) {
        flags |= AST.ClassMemberFlags.abstract;
    }

    if (self.match(TokenType.Readonly)) {
        flags |= AST.ClassMemberFlags.readonly;
    }

    if (self.match(TokenType.Public)) {
        flags |= AST.ClassMemberFlags.public;
    }

    if (self.match(TokenType.Protected)) {
        flags |= AST.ClassMemberFlags.protected;
    }

    if (self.match(TokenType.Private)) {
        flags |= AST.ClassMemberFlags.private;
    }

    const node = try self.parseMethodGetter() orelse
        try self.parseMethodSetter() orelse
        try self.parseMethodGenerator(AST.FunctionFlags.None) orelse
        try self.parseMethodAsyncGenerator() orelse
        try self.parseMethod(AST.FunctionFlags.None) orelse
        try self.parseClassField() orelse
        return self.fail(diagnostics.identifier_expected, .{});

    return try self.pool.addNode(self.cur_token, AST.Node{
        .class_member = .{
            .flags = @intCast(flags),
            .node = node,
        },
    });
}

pub fn parseMethodAsyncGenerator(self: *Self) ParserError!?AST.Node.Index {
    if (!self.match(TokenType.Async)) {
        return null;
    }

    return try self.parseMethodGenerator(AST.FunctionFlags.Async) orelse
        try self.parseMethod(AST.FunctionFlags.Async);
}

pub fn parseMethodGenerator(self: *Self, flags: u2) ParserError!?AST.Node.Index {
    if (!self.match(TokenType.Star)) {
        return null;
    }

    return try self.parseMethod(flags | AST.FunctionFlags.Generator);
}

pub fn parseMethod(self: *Self, flags: u4) ParserError!?AST.Node.Index {
    const cur_token = self.cur_token;
    const elem_name = try self.parseObjectElementName() orelse return null;

    if (!self.match(TokenType.OpenParen)) {
        self.cur_token = cur_token;
        return null;
    }

    const args = try self.parseFunctionArguments() orelse return self.fail(diagnostics.ARG_expected, .{"("});
    const return_type = try self.parseOptionalDataType();
    const body = try self.parseBlock() orelse return self.fail(diagnostics.ARG_expected, .{"{"});
    return try self.pool.addNode(cur_token, AST.Node{ .object_method = .{
        .flags = flags,
        .name = elem_name,
        .params = args,
        .body = body,
        .return_type = return_type,
    } });
}

pub fn parseClassField(self: *Self) ParserError!?AST.Node.Index {
    const elem_name = try self.parseObjectElementName() orelse return null;
    const decl_type = try self.parseOptionalDataType();

    var value: AST.Node.Index = AST.Node.Empty;
    if (self.match(TokenType.Equal)) {
        value = try parseAssignment(self);
    }

    _ = try self.consume(TokenType.Semicolon, diagnostics.ARG_expected, .{";"});
    return try self.pool.addNode(self.cur_token, AST.Node{ .class_field = .{
        .name = elem_name,
        .decl_type = decl_type,
        .value = value,
    } });
}

pub fn parseMethodGetter(self: *Self) ParserError!?AST.Node.Index {
    if (!self.match(TokenType.Get)) {
        return null;
    }
    const elem_name = try self.parseObjectElementName() orelse {
        self.rewind();
        return try self.parseMethod(AST.FunctionFlags.None);
    };

    _ = try self.consume(TokenType.OpenParen, diagnostics.ARG_expected, .{"("});
    const args = try self.parseFunctionArguments() orelse return self.fail(diagnostics.identifier_expected, .{});
    const return_type = try self.parseOptionalDataType();
    const body = try self.parseBlock() orelse return self.fail(diagnostics.ARG_expected, .{"{"});

    return try self.pool.addNode(self.cur_token, AST.Node{ .object_method = .{
        .flags = AST.FunctionFlags.Getter,
        .name = elem_name,
        .params = args,
        .body = body,
        .return_type = return_type,
    } });
}

pub fn parseMethodSetter(self: *Self) ParserError!?AST.Node.Index {
    if (!self.match(TokenType.Set)) {
        return null;
    }
    const elem_name = try self.parseObjectElementName() orelse {
        self.rewind();
        return try self.parseMethod(AST.FunctionFlags.None);
    };

    _ = try self.consume(TokenType.OpenParen, diagnostics.ARG_expected, .{"("});
    const args = try self.parseFunctionArguments() orelse return self.fail(diagnostics.identifier_expected, .{});
    const return_type = try self.parseOptionalDataType();
    const body = try self.parseBlock() orelse return self.fail(diagnostics.ARG_expected, .{"{"});

    return try self.pool.addNode(self.cur_token, AST.Node{ .object_method = .{
        .flags = AST.FunctionFlags.Setter,
        .name = elem_name,
        .params = args,
        .body = body,
        .return_type = return_type,
    } });
}

pub fn parseObjectElementName(self: *Self) ParserError!?AST.Node.Index {
    switch (self.token().type) {
        .Identifier => {
            _ = self.advance();
            return try self.pool.addNode(self.cur_token - 1, AST.Node{ .simple_value = .{ .kind = .identifier } });
        },
        .StringConstant => {
            _ = self.advance();
            return try self.pool.addNode(self.cur_token - 1, AST.Node{ .simple_value = .{ .kind = .string } });
        },
        .NumberConstant => {
            _ = self.advance();
            return try self.pool.addNode(self.cur_token - 1, AST.Node{ .simple_value = .{ .kind = .number } });
        },
        .BigIntConstant => {
            _ = self.advance();
            return try self.pool.addNode(self.cur_token - 1, AST.Node{ .simple_value = .{ .kind = .bigint } });
        },
        .OpenSquareBracket => {
            _ = self.advance();
            const node = try parseAssignment(self);
            _ = try self.consume(TokenType.CloseSquareBracket, diagnostics.ARG_expected, .{"]"});
            return try self.pool.addNode(self.cur_token, AST.Node{ .computed_identifier = node });
        },
        .Hash => {
            _ = self.advance();
            _ = try self.consume(TokenType.Identifier, diagnostics.identifier_expected, .{});
            return try self.pool.addNode(self.cur_token - 1, AST.Node{ .simple_value = .{ .kind = .private_identifier } });
        },
        else => {
            return null;
        },
    }
}

pub fn parseAsyncFunctionStatement(self: *Self) ParserError!?AST.Node.Index {
    if (!self.match(TokenType.Async)) {
        return null;
    }

    return try self.parseFunctionStatement(AST.FunctionFlags.Async);
}

pub fn parseFunctionStatement(self: *Self, flags: u4) ParserError!?AST.Node.Index {
    if (!self.match(TokenType.Function)) {
        return null;
    }

    var fn_flags = flags;
    if (self.match(TokenType.Star)) {
        fn_flags |= AST.FunctionFlags.Generator;
    }

    const func_name: AST.Node.Index = self.consumeOrNull(TokenType.Identifier) orelse AST.Node.Empty;

    _ = try self.consume(TokenType.OpenParen, diagnostics.ARG_expected, .{"("});

    const args = try self.parseFunctionArguments() orelse return self.fail(diagnostics.ARG_expected, .{"("});
    const return_type = try self.parseOptionalDataType();
    const body = try self.parseBlock() orelse return self.fail(diagnostics.ARG_expected, .{"{"});

    return try self.pool.addNode(self.cur_token, AST.Node{ .function_decl = .{
        .flags = fn_flags,
        .name = func_name,
        .params = args,
        .body = body,
        .return_type = return_type,
    } });
}

pub fn parseFunctionArguments(self: *Self) ParserError!?[]AST.Node.Index {
    var args = std.ArrayList(AST.Node.Index).init(self.arena.allocator());
    var has_comma = true;
    while (true) {
        if (self.match(TokenType.CloseParen)) {
            break;
        }

        if (self.consumeOrNull(TokenType.Identifier)) |identifier| {
            if (!has_comma) {
                try self.emitError(diagnostics.ARG_expected, .{","});
            }
            const param_type = try self.parseOptionalDataType();
            try args.append(try self.pool.addNode(identifier, AST.Node{ .function_param = .{
                .type = param_type,
                .node = identifier,
            } }));
        } else {
            return null;
        }

        has_comma = self.match(TokenType.Comma);
    }
    return try args.toOwnedSlice();
}

pub fn parseBlock(self: *Self) ParserError!?AST.Node.Index {
    if (!self.match(TokenType.OpenCurlyBrace)) {
        return null;
    }

    var statements = std.ArrayList(AST.Node.Index).init(self.arena.allocator());
    defer statements.deinit();

    while (true) {
        if (self.match(TokenType.Eof)) {
            try self.emitError(diagnostics.ARG_expected, .{"}"});
            return error.SyntaxError;
        }

        if (self.match(TokenType.CloseCurlyBrace)) {
            break;
        }

        try statements.append(try self.parseStatement());

        while (self.match(TokenType.NewLine)) {}

        if (self.match(TokenType.CloseCurlyBrace)) {
            break;
        }
    }

    return try self.pool.addNode(self.cur_token, AST.Node{ .block = statements.items });
}

pub fn parseDeclaration(self: *Self) ParserError!?AST.Node.Index {
    const kind: AST.Node.DeclarationKind = switch (self.token().type) {
        .Var => .@"var",
        .Let => .let,
        .Const => .@"const",
        else => return try self.parseFunctionStatement(AST.FunctionFlags.None) orelse try self.parseAsyncFunctionStatement(),
    };
    _ = self.advance();

    var nodes = std.ArrayList(AST.Node.Index).init(self.arena.allocator());
    defer nodes.deinit();

    while (true) {
        const identifier = try self.consume(TokenType.Identifier, diagnostics.identifier_expected, .{});
        const identifier_data_type = try self.parseOptionalDataType();
        var value: AST.Node.Index = AST.Node.Empty;

        if (self.match(TokenType.Equal)) {
            value = try parseAssignment(self);
        }

        try nodes.append(try self.pool.addNode(self.cur_token, AST.Node{ .decl_binding = .{
            .name = identifier,
            .decl_type = identifier_data_type,
            .value = value,
        } }));
        if (!self.match(TokenType.Comma)) {
            break;
        }
    }

    return try self.pool.addNode(self.cur_token, AST.Node{ .declaration = .{
        .kind = kind,
        .list = nodes.items,
    } });
}

fn parseTypeDeclaration(self: *Self) ParserError!?AST.Node.Index {
    if (!self.match(TokenType.Type)) {
        return null;
    }

    const identifier = self.consumeOrNull(TokenType.Identifier) orelse
        try self.parseKeywordAsIdentifier() orelse
        return self.fail(diagnostics.identifier_expected, .{});

    _ = try self.consume(TokenType.Equal, diagnostics.ARG_expected, .{"="});

    const identifier_data_type = try self.parseSymbolType();

    return try self.pool.addNode(self.cur_token, AST.Node{ .type_decl = .{
        .left = identifier,
        .right = identifier_data_type,
    } });
}

fn parseInterfaceDeclaration(self: *Self) ParserError!?AST.Node.Index {
    if (!self.match(TokenType.Interface)) {
        return null;
    }

    const identifier = self.consumeOrNull(TokenType.Identifier) orelse try self.parseKeywordAsIdentifier() orelse return self.fail(diagnostics.identifier_expected, .{});
    _ = try self.consume(TokenType.OpenCurlyBrace, diagnostics.ARG_expected, .{"{"});

    var list = std.ArrayList(AST.Node.Index).init(self.arena.allocator());
    defer list.deinit();

    var has_comma = true;
    while (true) {
        if (self.match(TokenType.CloseCurlyBrace)) {
            break;
        }
        if (!has_comma) {
            try self.emitError(diagnostics.ARG_expected, .{";"});
        }
        const node = try self.parseObjectMethodType() orelse
            try self.parseObjectPropertyType() orelse
            return self.fail(diagnostics.property_or_signature_expected, .{});

        try list.append(node);
        has_comma = self.match(TokenType.Comma) or self.match(TokenType.Semicolon);
    }
    return try self.pool.addNode(self.cur_token, AST.Node{ .interface_decl = .{
        .name = identifier,
        .extends = &[_]AST.Node.Index{},
        .body = list.items,
    } });
}

fn parseReturnStatement(self: *Self) ParserError!?AST.Node.Index {
    if (!self.match(TokenType.Return)) {
        return null;
    }

    if (self.match(TokenType.Semicolon)) {
        return try self.pool.addNode(self.cur_token, .{ .@"return" = AST.Node.Empty });
    }

    return try self.pool.addNode(self.cur_token, AST.Node{ .@"return" = try self.parseExpression() });
}

fn parseEmptyStatement(self: *Self) ParserError!?AST.Node.Index {
    if (!self.match(TokenType.Semicolon)) {
        return null;
    }

    return AST.Node.Empty;
}

fn parseIfStatement(self: *Self) ParserError!?AST.Node.Index {
    if (!self.match(TokenType.If)) {
        return null;
    }

    _ = try self.consume(TokenType.OpenParen, diagnostics.ARG_expected, .{"("});
    const cond = try self.parseExpression();
    _ = try self.consume(TokenType.CloseParen, diagnostics.ARG_expected, .{")"});
    const then = try self.parseStatement();

    const else_node = if (self.match(TokenType.Else)) try self.parseStatement() else AST.Node.Empty;

    return try self.pool.addNode(self.cur_token, AST.Node{ .@"if" = AST.Node.If{
        .expr = cond,
        .body = then,
        .@"else" = else_node,
    } });
}

pub fn parseExpression(self: *Self) ParserError!AST.Node.Index {
    var node = try parseAssignment(self);
    while (self.match(TokenType.Comma)) {
        const new_node = try self.pool.addNode(self.cur_token, AST.Node{
            .comma = .{
                .left = node,
                .right = try parseAssignment(self),
            },
        });

        node = new_node;
    }

    return node;
}

pub fn parseConditionalExpression(self: *Self) ParserError!AST.Node.Index {
    var node = try self.parseShortCircuitExpression();

    if (self.match(TokenType.QuestionMark)) {
        const true_expr = try parseAssignment(self);
        _ = try self.consume(TokenType.Colon, diagnostics.ARG_expected, .{":"});
        const false_expr = try parseAssignment(self);
        const new_node = try self.pool.addNode(self.cur_token, AST.Node{ .ternary_expr = .{
            .expr = node,
            .body = true_expr,
            .@"else" = false_expr,
        } });

        node = new_node;
    }

    return node;
}

pub fn parseAsyncArrowFunction(self: *Self) ParserError!?AST.Node.Index {
    if (!self.match(TokenType.Async)) {
        return null;
    }

    return try self.parseArrowFunctionWith1Arg(.async_arrow) orelse try self.parseArrowFunctionWithParenthesis(.async_arrow);
}

pub fn parseArrowFunction(self: *Self) ParserError!?AST.Node.Index {
    return try self.parseArrowFunctionWith1Arg(.arrow) orelse try self.parseArrowFunctionWithParenthesis(.arrow);
}

fn parseArrowFunctionWith1Arg(self: *Self, arrow_type: anytype) ParserError!?AST.Node.Index {
    const arg = try parseIdentifier(self) orelse return null;
    if (!self.match(TokenType.Arrow)) {
        self.rewind();
        return null;
    }
    var args = try std.ArrayList(AST.Node.Index).initCapacity(self.arena.allocator(), 1);
    defer args.deinit();

    args.appendAssumeCapacity(arg);

    const body = try self.parseConciseBody();
    return try self.pool.addNode(self.cur_token, AST.Node{ .arrow_function = .{
        .type = arrow_type,
        .params = args.items,
        .body = body,
        .return_type = 0,
    } });
}

fn parseArrowFunctionWithParenthesis(self: *Self, arrow_type: anytype) ParserError!?AST.Node.Index {
    const cp = self.cur_token;
    if (!self.match(TokenType.OpenParen)) {
        return null;
    }

    const args = try self.parseFunctionArguments() orelse {
        self.cur_token = cp;
        return null;
    };
    const return_type = try self.parseOptionalDataType();
    if (!self.match(TokenType.Arrow)) {
        self.cur_token = cp;
        return null;
    }

    const body = try self.parseConciseBody();
    return try self.pool.addNode(self.cur_token, AST.Node{ .arrow_function = .{
        .type = arrow_type,
        .params = args,
        .body = body,
        .return_type = return_type,
    } });
}

fn parseConciseBody(self: *Self) ParserError!AST.Node.Index {
    return try self.parseBlock() orelse
        try parseAssignment(self);
}

fn parseShortCircuitExpression(self: *Self) ParserError!AST.Node.Index {
    return try parseBinaryExpression(self, 0);
}
const unary_operators = .{
    .{ .token = TokenType.Minus, .tag = "minus" },
    .{ .token = TokenType.Plus, .tag = "plus" },
    .{ .token = TokenType.ExclamationMark, .tag = "not" },
    .{ .token = TokenType.Tilde, .tag = "bitwise_negate" },
    .{ .token = TokenType.Typeof, .tag = "typeof" },
    .{ .token = TokenType.Void, .tag = "void" },
    .{ .token = TokenType.Delete, .tag = "delete" },
};
pub fn parseUnary(self: *Self) ParserError!AST.Node.Index {
    inline for (unary_operators) |unary_operator| {
        if (self.match(unary_operator.token)) {
            return try self.pool.addNode(self.cur_token, @unionInit(AST.Node, unary_operator.tag, try self.parseUnary()));
        }
    }

    return self.parseUpdateExpression();
}

fn parseUpdateExpression(self: *Self) ParserError!AST.Node.Index {
    if (self.match(TokenType.PlusPlus)) {
        return try self.pool.addNode(self.cur_token, AST.Node{
            .plusplus_pre = try self.parseUnary(),
        });
    } else if (self.match(TokenType.MinusMinus)) {
        return try self.pool.addNode(self.cur_token, AST.Node{
            .minusminus_pre = try self.parseUnary(),
        });
    }

    const node = try self.parseLeftHandSideExpression();

    if (self.match(TokenType.PlusPlus)) {
        return try self.pool.addNode(self.cur_token, AST.Node{
            .plusplus_post = node,
        });
    } else if (self.match(TokenType.MinusMinus)) {
        return try self.pool.addNode(self.cur_token, AST.Node{
            .minusminus_post = node,
        });
    }

    return node;
}

fn parseLeftHandSideExpression(self: *Self) ParserError!AST.Node.Index {
    return try self.parseCallableExpression() orelse return self.fail(diagnostics.identifier_expected, .{});
}

fn parseNewExpression(self: *Self) ParserError!?AST.Node.Index {
    if (!self.match(TokenType.New)) {
        return null;
    }

    const maybe_node = try self.parseCallableExpression();
    if (maybe_node) |node| {
        return try self.pool.addNode(self.cur_token, AST.Node{
            .new_expr = node,
        });
    }

    self.rewind();
    return null;
}

fn parseMemberExpression(self: *Self) ParserError!?AST.Node.Index {
    var node = try self.parseNewExpression() orelse
        try parsePrimaryExpression(self) orelse
        return null;

    while (true) {
        const new_node = try self.parsePropertyAccess(node) orelse
            try self.parseIndexAccess(node) orelse break;

        node = new_node;
    }

    return node;
}

fn parseCallableExpression(self: *Self) ParserError!?AST.Node.Index {
    var node = try self.parseMemberExpression() orelse return null;

    while (self.match(TokenType.OpenParen)) {
        var nodes = std.ArrayList(AST.Node.Index).init(self.arena.allocator());
        defer nodes.deinit();

        while (true) {
            if (self.match(TokenType.CloseParen)) {
                break;
            }

            if (self.match(TokenType.Comma)) {
                return self.fail(diagnostics.argument_expression_expected, .{});
            }

            try nodes.append(try parseAssignment(self));

            if (!self.match(TokenType.CloseParen)) {
                _ = try self.consume(TokenType.Comma, diagnostics.ARG_expected, .{","});
            } else {
                break;
            }
        }

        const new_node = try self.pool.addNode(self.cur_token, AST.Node{
            .call_expr = .{
                .node = node,
                .params = nodes.items,
            },
        });
        node = new_node;
    }

    return node;
}

fn parseIndexAccess(self: *Self, expr: AST.Node.Index) ParserError!?AST.Node.Index {
    if (!self.match(TokenType.OpenSquareBracket)) {
        return null;
    }
    const node = try self.pool.addNode(self.cur_token, AST.Node{
        .index_access = .{
            .left = expr,
            .right = try self.parseExpression(),
        },
    });

    _ = try self.consume(TokenType.CloseSquareBracket, diagnostics.ARG_expected, .{"]"});

    return node;
}

fn parsePropertyAccess(self: *Self, expr: AST.Node.Index) ParserError!?AST.Node.Index {
    if (!self.match(TokenType.Dot)) {
        return null;
    }

    const identifier = try self.parseIdentifier() orelse return self.fail(diagnostics.identifier_expected, .{});

    return try self.pool.addNode(self.cur_token, AST.Node{
        .property_access = .{
            .left = expr,
            .right = identifier,
        },
    });
}

fn parseOptionalDataType(self: *Self) ParserError!AST.Node.Index {
    if (self.match(TokenType.Colon)) {
        return try self.parseSymbolType();
    }

    return AST.Node.Empty;
}

pub fn parseSymbolType(self: *Self) ParserError!AST.Node.Index {
    return try self.parseSymbolUnionType() orelse
        return self.fail(diagnostics.type_expected, .{});
}

fn parseSymbolUnionType(self: *Self) ParserError!?AST.Node.Index {
    var node = try self.parseSymbolIntersectionType() orelse return null;

    if (self.match(TokenType.Bar)) {
        const new_node = try self.pool.addNode(self.cur_token, AST.Node{
            .type_union = .{
                .left = node,
                .right = try self.parseSymbolUnionType() orelse return self.fail(diagnostics.type_expected, .{}),
            },
        });

        node = new_node;
    }

    return node;
}

fn parseSymbolIntersectionType(self: *Self) ParserError!?AST.Node.Index {
    var node = try self.parseSymbolTypeUnary() orelse return null;

    if (self.match(TokenType.Ampersand)) {
        const new_node = try self.pool.addNode(self.cur_token, AST.Node{
            .type_intersection = .{
                .left = node,
                .right = try self.parseSymbolIntersectionType() orelse return self.fail(diagnostics.type_expected, .{}),
            },
        });

        node = new_node;
    }

    return node;
}

fn parseSymbolTypeUnary(self: *Self) ParserError!?AST.Node.Index {
    if (self.match(TokenType.Typeof)) {
        return try self.pool.addNode(self.cur_token, AST.Node{
            .typeof = try self.parseSymbolType(),
        });
    } else if (self.match(TokenType.Keyof)) {
        return try self.pool.addNode(self.cur_token, AST.Node{
            .keyof = try self.parseSymbolType(),
        });
    }

    return try self.parseSymbolArrayType();
}

fn parseSymbolArrayType(self: *Self) ParserError!?AST.Node.Index {
    const node = try self.parsePrimarySymbolType() orelse return null;

    if (self.match(TokenType.OpenSquareBracket)) {
        if (self.match(TokenType.CloseSquareBracket)) {
            return try self.pool.addNode(self.cur_token, AST.Node{ .array_type = node });
        }
        return self.fail(diagnostics.unexpected_token, .{});
    }

    return node;
}

fn parsePrimarySymbolType(self: *Self) ParserError!?AST.Node.Index {
    return try self.parseObjectType() orelse
        try self.parseTupleType() orelse
        try self.parsePrimitiveType() orelse
        try self.parseGenericType();
}

fn parseObjectType(self: *Self) ParserError!?AST.Node.Index {
    if (!self.match(TokenType.OpenCurlyBrace)) {
        return null;
    }

    var list = std.ArrayList(AST.Node.Index).init(self.arena.allocator());
    defer list.deinit();

    var has_comma = true;
    while (true) {
        if (self.match(TokenType.CloseCurlyBrace)) {
            break;
        }

        if (!has_comma) {
            try self.emitError(diagnostics.ARG_expected, .{";"});
        }

        const record = try self.parseObjectMethodType() orelse
            try self.parseObjectPropertyType() orelse
            return self.fail(diagnostics.identifier_expected, .{});
        try list.append(record);

        has_comma = self.match(TokenType.Comma) or self.match(TokenType.Semicolon);
    }

    return try self.pool.addNode(self.cur_token, AST.Node{ .object_type = list.items });
}

fn parseObjectPropertyType(self: *Self) ParserError!?AST.Node.Index {
    const identifier = self.consumeOrNull(TokenType.Identifier) orelse return null;

    var right: AST.Node.Index = AST.Node.Empty;

    if (self.match(TokenType.Colon)) {
        right = try self.parseSymbolType();
    }

    return try self.pool.addNode(self.cur_token, AST.Node{
        .object_type_field = .{
            .name = identifier,
            .type = right,
        },
    });
}

fn parseObjectMethodType(self: *Self) ParserError!?AST.Node.Index {
    const cp = self.cur_token;
    const identifier = try self.parseIdentifier() orelse {
        self.cur_token = cp;
        return null;
    };

    if (!self.match(TokenType.OpenParen)) {
        self.cur_token = cp;
        return null;
    }
    const list = try self.parseFunctionArgumentsType();
    const return_type = try self.parseOptionalDataType();

    return try self.pool.addNode(self.cur_token, AST.Node{ .function_type = .{
        .name = identifier,
        .params = list,
        .return_type = return_type,
    } });
}

fn parseFunctionArgumentsType(self: *Self) ParserError![]AST.Node.Index {
    var args = std.ArrayList(AST.Node.Index).init(self.arena.allocator());
    var has_comma = true;
    while (true) {
        if (self.match(TokenType.CloseParen)) {
            break;
        }

        if (self.consumeOrNull(TokenType.Identifier)) |identifier| {
            if (!has_comma) {
                return self.fail(diagnostics.ARG_expected, .{","});
            }
            const arg_type = try self.parseOptionalDataType();
            try args.append(try self.pool.addNode(identifier, AST.Node{ .function_param = .{
                .node = identifier,
                .type = arg_type,
            } }));
        } else {
            return self.fail(diagnostics.identifier_expected, .{});
        }

        has_comma = self.match(TokenType.Comma);
    }
    return try args.toOwnedSlice();
}

fn parseTupleType(self: *Self) ParserError!?AST.Node.Index {
    if (!self.match(TokenType.OpenSquareBracket)) {
        return null;
    }

    var list = std.ArrayList(AST.Node.Index).init(self.arena.allocator());
    defer list.deinit();

    while (true) {
        if (list.items.len > 0) {
            _ = try self.consume(TokenType.Comma, diagnostics.ARG_expected, .{","});
        }
        if (self.match(TokenType.CloseSquareBracket)) {
            break;
        }
        const node = try self.parseSymbolType();
        try list.append(node);
    }

    return try self.pool.addNode(self.cur_token, AST.Node{ .tuple_type = list.items });
}

const primitive_types = .{
    .{ TokenType.NumberConstant, .number },
    .{ TokenType.BigIntConstant, .bigint },
    .{ TokenType.StringConstant, .string },
    .{ TokenType.True, .true },
    .{ TokenType.False, .false },
    .{ TokenType.Null, .null },
    .{ TokenType.Undefined, .undefined },
    .{ TokenType.Void, .void },
    .{ TokenType.Any, .any },
    .{ TokenType.Unknown, .unknown },
};

fn parsePrimitiveType(self: *Self) ParserError!?AST.Node.Index {
    inline for (primitive_types) |primitive_type| {
        if (self.match(primitive_type[0])) {
            return try self.pool.addNode(self.cur_token - 1, AST.Node{ .simple_type = .{ .kind = primitive_type[1] } });
        }
    }

    return null;
}
fn parseGenericType(self: *Self) ParserError!?AST.Node.Index {
    var node = try self.parseTypeIdentifier() orelse return null;

    if (self.match(TokenType.LessThan)) {
        var params = std.ArrayList(AST.Node.Index).init(self.arena.allocator());
        defer params.deinit();

        while (true) {
            try params.append(try self.parseSymbolType());

            if (!self.match(TokenType.Comma)) {
                break;
            }
        }

        _ = try self.consume(TokenType.GreaterThan, diagnostics.ARG_expected, .{">"});

        node = try self.pool.addNode(self.cur_token, AST.Node{ .generic_type = .{
            .name = node,
            .params = params.items,
        } });
    }

    return node;
}

fn parseTypeIdentifier(self: *Self) ParserError!?AST.Node.Index {
    const identifier = self.consumeOrNull(TokenType.Identifier) orelse return null;

    const type_map = .{
        .{ "number", .number },
        .{ "bigint", .bigint },
        .{ "string", .string },
        .{ "boolean", .boolean },
    };

    const value = self.lexer.getTokenValue(identifier).?;
    inline for (type_map) |type_item| {
        if (std.mem.eql(u8, type_item[0], value)) {
            return try self.pool.addNode(identifier, AST.Node{ .simple_type = .{ .kind = type_item[1] } });
        }
    }

    return try self.pool.addNode(identifier, AST.Node{ .simple_type = .{ .kind = .identifier } });
}

pub fn needsSemicolon(pool: AST.Pool, node: AST.Node.Index) bool {
    const nodeRaw = pool.getRawNode(node);
    var tag = nodeRaw.tag;
    if (tag == .export_node or tag == .export_default) {
        tag = pool.getRawNode(nodeRaw.data.lhs).tag;
    }

    return switch (tag) {
        .block,
        .func_decl,
        .@"for",
        .for_in,
        .for_of,
        .@"while",
        .do_while,
        .@"if",
        .class_decl,
        .class_method,
        .interface_decl,
        .object_method,
        => false,
        else => true,
    };
}

pub fn expectAST(fn_ptr: fn (parser: *Self) ParserError!AST.Node.Index, expected: AST.Node, text: []const u8) !void {
    var parser = try Self.init(std.testing.allocator, text);
    defer parser.deinit();

    const node = try fn_ptr(&parser);
    try std.testing.expectEqualDeep(expected, parser.pool.getNode(node));
}

pub fn expectMaybeAST(fn_ptr: fn (parser: *Self) ParserError!?AST.Node.Index, expected: ?AST.Node, text: []const u8) !void {
    var parser = try Self.init(std.testing.allocator, text);
    defer parser.deinit();

    const node = try fn_ptr(&parser);
    if (expected) |expected_node| {
        try std.testing.expectEqualDeep(expected_node, parser.pool.getNode(node.?));
    } else {
        try expectEqual(null, node);
    }
}

pub fn expectASTAndToken(fn_ptr: fn (parser: *Self) ParserError!?AST.Node.Index, expected: ?AST.Node, tok_type: TokenType, token_value: ?[]const u8, text: []const u8) !void {
    var parser = try Self.init(std.testing.allocator, text);
    defer parser.deinit();

    const maybe_node = try fn_ptr(&parser);
    if (expected) |expected_node| {
        if (maybe_node) |node| {
            try std.testing.expectEqualDeep(expected_node, parser.pool.getNode(node));
            try parser.expectToken(tok_type, node);
            try parser.expectTokenValue(token_value, node);
        } else if (expected != null) {
            std.debug.print("expected {any}, got null\n", .{expected});
            return error.TestExpectedEqual;
        }
    } else {
        try expectEqual(null, maybe_node);
    }
}

pub fn expectSyntaxError(
    fn_ptr: fn (parser: *Self) ParserError!?AST.Node.Index,
    comptime text: []const u8,
    comptime expected_error: diagnostics.DiagnosticMessage,
    args: anytype,
) !void {
    var parser = try Self.init(std.testing.allocator, text);
    defer parser.deinit();

    const nodeOrError = fn_ptr(&parser);

    try expectError(ParserError.SyntaxError, nodeOrError);
    var buffer: [512]u8 = undefined;
    const expected_string = try std.fmt.bufPrint(&buffer, "TS" ++ expected_error.code ++ ": " ++ expected_error.message, args);
    try expectEqualStrings(expected_string, parser.errors.items[0]);
}

pub fn expectToken(self: *Self, tok_type: TokenType, node: AST.Node.Index) !void {
    const raw = self.pool.getRawNode(node);
    try expectEqual(tok_type, self.lexer.getToken(raw.main_token).type);
}

pub fn expectTokenValue(self: *Self, expected_value: ?[]const u8, node: AST.Node.Index) !void {
    const raw = self.pool.getRawNode(node);
    if (expected_value) |expected| {
        if (self.lexer.getTokenValue(raw.main_token)) |value| {
            try expectEqualStrings(expected, value);
        } else {
            return error.TestExpectedEqual;
        }
    } else {
        if (self.lexer.getTokenValue(raw.main_token)) |value| {
            std.debug.print("expected null, got {s}\n", .{value});
            return error.TestExpectedEqual;
        }
    }
}

pub fn expectSimpleMethod(parser: Self, node_idx: AST.Node.Index, expected_flags: anytype, expected_name: []const u8) !void {
    const node = parser.pool.getNode(node_idx);
    try expectEqual(expected_flags, node.object_method.flags);

    const name_node = parser.pool.getRawNode(node.object_method.name);
    const name_token = parser.lexer.getTokenValue(name_node.main_token);
    try expectEqualStrings(expected_name, name_token.?);
}

pub fn expectTSError(parser: Self, comptime expected_error: diagnostics.DiagnosticMessage, comptime args: anytype) !void {
    var buffer: [512]u8 = undefined;
    const expected_string = try std.fmt.bufPrint(&buffer, "TS" ++ expected_error.code ++ ": " ++ expected_error.message, args);
    try expectEqualStrings(expected_string, parser.errors.items[0]);
}

test {
    _ = @import("parser/primary.zig");
    _ = @import("parser/binary.zig");
    _ = @import("parser/loops.zig");
    _ = @import("parser/imports.zig");
}
