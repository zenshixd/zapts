const std = @import("std");
const ArrayList = std.ArrayList;

const Lexer = @import("lexer.zig");
const AST = @import("ast.zig");

const diagnostics = @import("diagnostics.zig");

const consts = @import("consts.zig");
const Token = consts.Token;
const TokenType = consts.TokenType;

pub const ParserError = error{ SyntaxError, OutOfMemory, NoSpaceLeft, Overflow };

const Self = @This();

gpa: std.mem.Allocator,
arena: std.heap.ArenaAllocator,
tokens: std.ArrayList(Token),
cur_token: Token.Index,
pool: AST.Pool,
errors: std.ArrayList([]const u8),

pub fn init(gpa: std.mem.Allocator, buffer: []const u8) !Self {
    var lexer = Lexer.init(gpa, buffer);
    const tokens = try lexer.nextAll();

    return Self{
        .tokens = tokens,
        .cur_token = 0,
        .gpa = gpa,
        .arena = std.heap.ArenaAllocator.init(gpa),
        .pool = AST.Pool.init(gpa),
        .errors = std.ArrayList([]const u8).init(gpa),
    };
}

pub fn deinit(self: *Self) void {
    self.arena.deinit();
    self.pool.deinit();
}

pub fn parse(self: *Self) ParserError!AST.Node.Index {
    var nodes = std.ArrayList(AST.Node.Index).init(self.arena.allocator());

    while (!self.match(TokenType.Eof)) {
        if (self.match(TokenType.NewLine) or self.match(TokenType.LineComment) or self.match(TokenType.MultilineComment)) {
            continue;
        }

        try nodes.append(try self.parseStatement());
    }

    const subrange = try self.pool.listToSubrange(nodes.items);

    var root_node = self.pool.nodes.items[0];
    root_node.data = .{ .lhs = subrange.start, .rhs = subrange.end };
    return 0;
}

fn token(self: Self) Token {
    return self.tokens.items[self.cur_token];
}

fn advance(self: *Self) Token.Index {
    // std.debug.print("advancing from {}\n", .{t});
    if (self.cur_token + 1 < self.tokens.items.len) {
        self.cur_token += 1;
    }
    return self.cur_token;
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

fn consume(self: *Self, token_type: TokenType, comptime error_msg: diagnostics.DiagnosticMessage, args: anytype) ParserError!Token.Index {
    if (self.token().type == token_type) {
        return self.advance();
    }

    try self.emitError(error_msg, args);
    // try self.emitError("Current token: {}", .{self.token()});
    return error.SyntaxError;
}

fn consumeOrNull(self: *Self, token_type: TokenType) ?Token.Index {
    if (self.token().type == token_type) {
        return self.advance();
    }

    return null;
}

fn rewind(self: *Self) void {
    if (self.cur_token - 1 >= 0) {
        self.cur_token -= 1;
    }
}

fn fail(self: *Self, comptime error_msg: diagnostics.DiagnosticMessage, args: anytype) ParserError {
    try self.emitError(error_msg, args);
    return ParserError.SyntaxError;
}

fn emitError(self: *Self, comptime error_msg: diagnostics.DiagnosticMessage, args: anytype) ParserError!void {
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

fn parseStatement(self: *Self) ParserError!AST.Node.Index {
    const node = try self.parseBlock() orelse
        try self.parseDeclaration() orelse
        try self.parseClassStatement(false) orelse
        try self.parseAbstractClassStatement() orelse
        try self.parseImportStatement() orelse
        try self.parseExportStatement() orelse
        try self.parseEmptyStatement() orelse
        try self.parseIfStatement() orelse
        try self.parseBreakableStatement() orelse
        try self.parseReturnStatement() orelse
        //try self.parseTypeDeclaration() orelse
        //try self.parseInterfaceDeclaration() orelse
        try self.parseExpression();

    if (needsSemicolon(&self.pool, node)) {
        _ = try self.consume(TokenType.Semicolon, diagnostics.ARG_expected, .{";"});
    }
    return node;
}

fn parseImportStatement(self: *Self) ParserError!?AST.Node.Index {
    if (!self.match(TokenType.Import)) {
        return null;
    }
    if (self.consumeOrNull(TokenType.StringConstant)) |path| {
        return try self.pool.addNode(self.cur_token, .{
            .import = .{ .simple = path },
        });
    }

    const bindings = try self.parseImportClause();

    const path_token = try self.parseFromClause() orelse return self.fail(diagnostics.ARG_expected, .{"from"});

    return try self.pool.addNode(self.cur_token, AST.Node{
        .import = .{
            .full = .{
                .bindings = bindings,
                .path = path_token,
            },
        },
    });
}

fn parseImportClause(self: *Self) ParserError![]AST.Node.Index {
    var bindings = std.ArrayList(AST.Node.Index).init(self.arena.allocator());

    try bindings.append(
        try self.parseImportDefaultBinding() orelse
            try self.parseImportNamespaceBinding() orelse
            try self.parseImportNamedBindings() orelse
            return self.fail(diagnostics.declaration_or_statement_expected, .{}),
    );

    if (self.pool.getNode(bindings.items[0]).import_binding == .default) {
        if (self.match(TokenType.Comma)) {
            try bindings.append(
                try self.parseImportNamespaceBinding() orelse
                    try self.parseImportNamedBindings() orelse
                    return self.fail(diagnostics.ARG_expected, .{"{"}),
            );
        } else if (!self.peekMatch(TokenType.From)) {
            return self.fail(diagnostics.ARG_expected, .{"from"});
        }
    }

    return bindings.items;
}

fn parseImportDefaultBinding(self: *Self) !?AST.Node.Index {
    if (self.consumeOrNull(TokenType.Identifier)) |identifier| {
        return try self.pool.addNode(self.cur_token, .{ .import_binding = .{ .default = identifier } });
    }

    return null;
}

fn parseImportNamespaceBinding(self: *Self) !?AST.Node.Index {
    if (!self.match(TokenType.Star)) {
        return null;
    }

    _ = try self.consume(TokenType.As, diagnostics.ARG_expected, .{"as"});
    const identifier = try self.consume(TokenType.Identifier, diagnostics.identifier_expected, .{});

    return try self.pool.addNode(self.cur_token, .{ .import_binding = .{ .namespace = identifier } });
}

fn parseImportNamedBindings(self: *Self) !?AST.Node.Index {
    if (!self.match(TokenType.OpenCurlyBrace)) {
        return null;
    }

    var named_bindings = std.ArrayList(AST.Node.Index).init(self.arena.allocator());
    while (true) {
        if (self.consumeOrNull(TokenType.Identifier)) |identifier| {
            try named_bindings.append(identifier);
        }

        if (self.match(TokenType.CloseCurlyBrace)) {
            break;
        }
        _ = try self.consume(TokenType.Comma, diagnostics.ARG_expected, .{","});
    }

    return try self.pool.addNode(self.cur_token, .{ .import_binding = .{ .named = named_bindings.items } });
}

fn parseExportStatement(self: *Self) ParserError!?AST.Node.Index {
    if (!self.match(TokenType.Export)) {
        return null;
    }

    if (try self.parseExportFromClause()) |export_node| {
        return export_node;
    }

    const node = try self.parseDeclaration() orelse
        try self.parseClassStatement(false) orelse
        try self.parseAbstractClassStatement() orelse
        try self.parseDefaultExport() orelse
        return self.fail(diagnostics.declaration_or_statement_expected, .{});

    return try self.pool.addNode(self.cur_token, .{ .@"export" = .{
        .node = node,
    } });
}

fn parseExportFromClause(self: *Self) ParserError!?AST.Node.Index {
    if (self.match(TokenType.Star)) {
        var namespace: Token.Index = 0;

        if (self.match(TokenType.As)) {
            const identifier = try self.consume(TokenType.Identifier, diagnostics.identifier_expected, .{});
            namespace = identifier;
        }

        const path_token = try self.parseFromClause() orelse return self.fail(diagnostics.ARG_expected, .{"from"});
        return try self.pool.addNode(self.cur_token, AST.Node{ .@"export" = .{
            .from_all = .{
                .alias = namespace,
                .path = path_token,
            },
        } });
    }

    if (self.match(TokenType.OpenCurlyBrace)) {
        var exports = std.ArrayList(AST.Node.Index).init(self.arena.allocator());
        var has_comma = true;
        while (true) {
            if (self.match(TokenType.CloseCurlyBrace)) {
                break;
            }
            if (!has_comma) {
                try self.emitError(diagnostics.ARG_expected, .{","});
            }
            const identifier = try self.consume(TokenType.Identifier, diagnostics.identifier_expected, .{});
            var alias: Token.Index = 0;
            if (self.match(TokenType.As)) {
                alias = try self.consume(TokenType.Identifier, diagnostics.identifier_expected, .{});
            }
            has_comma = self.consumeOrNull(TokenType.Comma) != null;
            try exports.append(identifier);
        }
        const path = try self.parseFromClause();
        return try self.pool.addNode(self.cur_token, AST.Node{
            .@"export" = .{
                .from = .{
                    .bindings = exports.items,
                    .path = path orelse AST.Node.Empty,
                },
            },
        });
    }

    return null;
}

fn parseDefaultExport(self: *Self) ParserError!?AST.Node.Index {
    if (!self.match(TokenType.Default)) {
        return null;
    }

    return try self.parseFunctionStatement(AST.FunctionFlags.None) orelse
        try self.parseAsyncFunctionStatement() orelse
        try self.parseAssignment();
}

fn parseFromClause(self: *Self) ParserError!?Token.Index {
    if (!self.match(TokenType.From)) {
        return null;
    }
    return try self.consume(TokenType.StringConstant, diagnostics.string_literal_expected, .{});
}

fn parseAbstractClassStatement(self: *Self) ParserError!?AST.Node.Index {
    if (!self.match(TokenType.Abstract)) {
        return null;
    }

    return try self.parseClassStatement(true) orelse {
        self.rewind();
        return null;
    };
}

fn parseClassStatement(self: *Self, is_abstract: bool) ParserError!?AST.Node.Index {
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
        if (!self.match(TokenType.Identifier) and try self.parseKeywordAsIdentifier() == null) {
            return self.fail(diagnostics.identifier_expected, .{});
        }
        try list.append(try self.pool.addNode(self.cur_token - 1, AST.Node{
            .simple_value = .{ .kind = .identifier },
        }));
        if (!self.match(TokenType.Comma)) {
            break;
        }
    }
    return list.items;
}

fn parseClassStaticMember(self: *Self) ParserError!AST.Node.Index {
    if (self.match(TokenType.Static)) {
        if (self.match(TokenType.OpenCurlyBrace)) {
            var block = std.ArrayList(AST.Node.Index).init(self.arena.allocator());
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
        try self.parseAsyncGeneratorMethod() orelse
        try self.parseMethod(AST.FunctionFlags.None) orelse
        return self.fail(diagnostics.identifier_expected, .{});

    return try self.pool.addNode(self.cur_token, AST.Node{
        .class_member = .{
            .flags = @intCast(flags),
            .node = node,
        },
    });
}

fn parseAsyncGeneratorMethod(self: *Self) ParserError!?AST.Node.Index {
    if (!self.match(TokenType.Async)) {
        return null;
    }

    return try self.parseMethodGenerator(AST.FunctionFlags.Async) orelse
        try self.parseMethod(AST.FunctionFlags.Async);
}

fn parseMethodGenerator(self: *Self, flags: u2) ParserError!?AST.Node.Index {
    if (!self.match(TokenType.Star)) {
        return null;
    }

    return try self.parseMethod(flags | AST.FunctionFlags.Generator);
}

fn parseMethod(self: *Self, flags: u4) ParserError!?AST.Node.Index {
    const elem_name = try self.parseObjectElementName() orelse return null;

    if (self.match(TokenType.OpenParen)) {
        const args = try self.parseFunctionArguments() orelse return self.fail(diagnostics.ARG_expected, .{"("});
        const return_type = try self.parseOptionalDataType();
        const body = try self.parseBlock() orelse return self.fail(diagnostics.ARG_expected, .{"{"});
        return try self.pool.addNode(self.cur_token, AST.Node{ .object_method = .{
            .flags = flags,
            .name = elem_name,
            .params = args,
            .body = body,
            .return_type = return_type,
        } });
    }

    return try self.parseClassField(elem_name);
}

fn parseClassField(self: *Self, elem_name: AST.Node.Index) ParserError!AST.Node.Index {
    const decl_type = try self.parseOptionalDataType();
    var value: AST.Node.Index = AST.Node.Empty;
    if (self.match(TokenType.Equal)) {
        value = try self.parseAssignment();
    }

    _ = try self.consume(TokenType.Semicolon, diagnostics.ARG_expected, .{";"});
    return try self.pool.addNode(self.cur_token, AST.Node{ .class_field = .{
        .name = elem_name,
        .decl_type = decl_type,
        .value = value,
    } });
}

fn parseMethodGetter(self: *Self) ParserError!?AST.Node.Index {
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

fn parseMethodSetter(self: *Self) ParserError!?AST.Node.Index {
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

fn parseObjectElementName(self: *Self) ParserError!?AST.Node.Index {
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
            const node = try self.parseAssignment();
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

fn parseAsyncFunctionStatement(self: *Self) ParserError!?AST.Node.Index {
    if (!self.match(TokenType.Async)) {
        return null;
    }

    return try self.parseFunctionStatement(AST.FunctionFlags.Async);
}

fn parseFunctionStatement(self: *Self, flags: u2) ParserError!?AST.Node.Index {
    if (!self.match(TokenType.Function)) {
        return null;
    }

    var func_name: AST.Node.Index = AST.Node.Empty;
    if (self.consumeOrNull(TokenType.Identifier)) |identifier| {
        func_name = identifier;
    }
    _ = try self.consume(TokenType.OpenParen, diagnostics.ARG_expected, .{"("});

    const args = try self.parseFunctionArguments() orelse return self.fail(diagnostics.ARG_expected, .{"("});
    const return_type = try self.parseOptionalDataType();
    const body = try self.parseBlock() orelse return self.fail(diagnostics.ARG_expected, .{"{"});

    return try self.pool.addNode(self.cur_token, AST.Node{ .function_decl = .{
        .flags = flags,
        .name = func_name,
        .params = args,
        .body = body,
        .return_type = return_type,
    } });
}

fn parseFunctionArguments(self: *Self) ParserError!?[]AST.Node.Index {
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
    return args.items;
}

fn parseBlock(self: *Self) ParserError!?AST.Node.Index {
    if (!self.match(TokenType.OpenCurlyBrace)) {
        return null;
    }

    var statements = std.ArrayList(AST.Node.Index).init(self.arena.allocator());

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

fn parseDeclaration(self: *Self) ParserError!?AST.Node.Index {
    const kind: AST.Node.DeclarationKind = switch (self.token().type) {
        .Var => .@"var",
        .Let => .let,
        .Const => .@"const",
        else => return try self.parseFunctionStatement(AST.FunctionFlags.None) orelse try self.parseAsyncFunctionStatement(),
    };
    _ = self.advance();

    var nodes = std.ArrayList(AST.Node.Index).init(self.arena.allocator());

    while (true) {
        const identifier = try self.parseIdentifier() orelse return self.fail(diagnostics.identifier_expected, .{});
        const identifier_data_type = try self.parseOptionalDataType();
        var value: AST.Node.Index = AST.Node.Empty;

        if (self.match(TokenType.Equal)) {
            value = try self.parseAssignment();
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

fn parseBreakableStatement(self: *Self) ParserError!?AST.Node.Index {
    return try parseDoWhileStatement(self) orelse try parseWhileStatement(self) orelse try parseForStatement(self);
}

fn parseDoWhileStatement(self: *Self) ParserError!?AST.Node.Index {
    if (!self.match(TokenType.Do)) {
        return null;
    }

    const node = try self.parseStatement();
    _ = try self.consume(TokenType.While, diagnostics.ARG_expected, .{"while"});
    _ = try self.consume(TokenType.OpenParen, diagnostics.ARG_expected, .{"("});
    const condition = try self.parseExpression();
    _ = try self.consume(TokenType.CloseParen, diagnostics.ARG_expected, .{")"});
    _ = try self.consume(TokenType.Semicolon, diagnostics.ARG_expected, .{";"});

    return try self.pool.addNode(self.cur_token, AST.Node{ .do_while = .{
        .cond = condition,
        .body = node,
    } });
}

fn parseWhileStatement(self: *Self) ParserError!?AST.Node.Index {
    if (!self.match(TokenType.While)) {
        return null;
    }

    _ = try self.consume(TokenType.OpenParen, diagnostics.ARG_expected, .{"("});
    const condition = try self.parseExpression();
    _ = try self.consume(TokenType.CloseParen, diagnostics.ARG_expected, .{")"});

    return try self.pool.addNode(self.cur_token, AST.Node{ .@"while" = .{
        .cond = condition,
        .body = try self.parseStatement(),
    } });
}

fn parseForStatement(self: *Self) ParserError!?AST.Node.Index {
    if (!self.match(TokenType.For)) {
        return null;
    }

    _ = try self.consume(TokenType.OpenParen, diagnostics.ARG_expected, .{"("});

    const for_inner = try self.parseForClassicStatement() orelse
        try self.parseForInStatement() orelse
        try self.parseForOfStatement();

    if (for_inner == null) {
        try self.emitError(diagnostics.ARG_expected, .{","});
        return error.SyntaxError;
    }

    return for_inner;
}

fn parseForClassicStatement(self: *Self) ParserError!?AST.Node.Index {
    const cp = self.cur_token;
    const init_node = try self.parseDeclaration() orelse try self.parseExpression();
    if (!self.match(TokenType.Semicolon)) {
        // TODO: there is no cleanup of created AST nodes - need to figure out how to do it
        self.cur_token = cp;
        return null;
    }
    const cond_node = try self.parseExpression();
    _ = try self.consume(TokenType.Semicolon, diagnostics.ARG_expected, .{";"});
    const post_node = try self.parseExpression();
    _ = try self.consume(TokenType.CloseParen, diagnostics.ARG_expected, .{")"});

    return try self.pool.addNode(self.cur_token, AST.Node{ .@"for" = .{ .classic = .{
        .init = init_node,
        .cond = cond_node,
        .post = post_node,
        .body = try self.parseStatement(),
    } } });
}

fn parseForInStatement(self: *Self) ParserError!?AST.Node.Index {
    const cp = self.cur_token;
    const init_node = try self.parseDeclaration() orelse try self.parseExpression();
    if (!self.match(TokenType.In)) {
        // TODO: there is no cleanup of created AST nodes - need to figure out how to do it
        self.cur_token = cp;
        return null;
    }
    const right = try self.parseExpression();
    _ = try self.consume(TokenType.CloseParen, diagnostics.ARG_expected, .{")"});

    return try self.pool.addNode(self.cur_token, AST.Node{ .@"for" = .{ .in = .{
        .left = init_node,
        .right = right,
        .body = try self.parseStatement(),
    } } });
}

fn parseForOfStatement(self: *Self) ParserError!?AST.Node.Index {
    const cp = self.cur_token;

    const init_node = try self.parseDeclaration() orelse try self.parseExpression();
    if (!self.match(TokenType.Of)) {
        self.cur_token = cp;
        return null;
    }
    const right = try self.parseExpression();
    _ = try self.consume(TokenType.CloseParen, diagnostics.ARG_expected, .{")"});

    return try self.pool.addNode(self.cur_token, AST.Node{ .@"for" = .{ .of = .{
        .left = init_node,
        .right = right,
        .body = try self.parseStatement(),
    } } });
}

fn parseExpression(self: *Self) ParserError!AST.Node.Index {
    var node = try self.parseAssignment();
    while (self.match(TokenType.Comma)) {
        const new_node = try self.pool.addNode(self.cur_token, AST.Node{
            .comma = .{
                .left = node,
                .right = try self.parseAssignment(),
            },
        });

        node = new_node;
    }

    return node;
}

const assignment_map = .{
    .{ .Equal, "assignment" },
    .{ .PlusEqual, "plus_assign" },
    .{ .MinusEqual, "minus_assign" },
    .{ .StarEqual, "multiply_assign" },
    .{ .StarStarEqual, "exp_assign" },
    .{ .SlashEqual, "div_assign" },
    .{ .PercentEqual, "modulo_assign" },
    .{ .AmpersandEqual, "bitwise_and_assign" },
    .{ .BarEqual, "bitwise_or_assign" },
    .{ .CaretEqual, "bitwise_xor_assign" },
    .{ .BarBarEqual, "or_assign" },
    .{ .AmpersandAmpersandEqual, "and_assign" },
    .{ .GreaterThanGreaterThanEqual, "bitwise_shift_right_assign" },
    .{ .GreaterThanGreaterThanGreaterThanEqual, "bitwise_unsigned_right_shift_assign" },
    .{ .LessThanLessThanEqual, "bitwise_shift_left_assign" },
};
fn parseAssignment(self: *Self) ParserError!AST.Node.Index {
    var casting_type: ?AST.Node.Index = null;
    if (self.match(TokenType.LessThan)) {
        casting_type = try self.parseSymbolType();
        _ = try self.consume(TokenType.GreaterThan, diagnostics.ARG_expected, .{">"});
    }
    const node = try self.parseAsyncArrowFunction() orelse try self.parseArrowFunction() orelse try self.parseConditionalExpression();

    inline for (assignment_map) |assignment| {
        if (self.match(assignment[0])) {
            const tag = assignment[1];
            return try self.pool.addNode(self.cur_token, @unionInit(AST.Node, tag, .{
                .left = node,
                .right = try self.parseAssignment(),
            }));
        }
    }

    return node;
}

fn parseConditionalExpression(self: *Self) ParserError!AST.Node.Index {
    var node = try self.parseShortCircuitExpression();

    if (self.match(TokenType.QuestionMark)) {
        const true_expr = try self.parseAssignment();
        _ = try self.consume(TokenType.Colon, diagnostics.ARG_expected, .{":"});
        const false_expr = try self.parseAssignment();
        const new_node = try self.pool.addNode(self.cur_token, AST.Node{ .ternary_expr = .{
            .expr = node,
            .body = true_expr,
            .@"else" = false_expr,
        } });

        node = new_node;
    }

    return node;
}

fn parseAsyncArrowFunction(self: *Self) ParserError!?AST.Node.Index {
    if (!self.match(TokenType.Async)) {
        return null;
    }

    return try self.parseArrowFunctionWith1Arg(.async_arrow) orelse try self.parseArrowFunctionWithParenthesis(.async_arrow);
}

fn parseArrowFunction(self: *Self) ParserError!?AST.Node.Index {
    return try self.parseArrowFunctionWith1Arg(.arrow) orelse try self.parseArrowFunctionWithParenthesis(.arrow);
}

fn parseArrowFunctionWith1Arg(self: *Self, arrow_type: anytype) ParserError!?AST.Node.Index {
    const arg = try self.parseIdentifier() orelse return null;
    if (!self.match(TokenType.Arrow)) {
        self.rewind();
        return null;
    }
    var args = try std.ArrayList(AST.Node.Index).initCapacity(self.arena.allocator(), 1);
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
        try self.parseAssignment();
}

fn parseShortCircuitExpression(self: *Self) ParserError!AST.Node.Index {
    return try self.parseBinaryExpression(0);
}

const binary_operators = .{
    .{ .token = TokenType.BarBar, .tag = "or" },
    .{ .token = TokenType.AmpersandAmpersand, .tag = "and" },
    .{ .token = TokenType.Bar, .tag = "bitwise_or" },
    .{ .token = TokenType.Caret, .tag = "bitwise_xor" },
    .{ .token = TokenType.Ampersand, .tag = "bitwise_and" },
    .{ .token = TokenType.EqualEqual, .tag = "eq" },
    .{ .token = TokenType.ExclamationMarkEqual, .tag = "neq" },
    .{ .token = TokenType.EqualEqualEqual, .tag = "eqq" },
    .{ .token = TokenType.ExclamationMarkEqualEqual, .tag = "neqq" },
    .{ .token = TokenType.LessThan, .tag = "lt" },
    .{ .token = TokenType.GreaterThan, .tag = "gt" },
    .{ .token = TokenType.LessThanEqual, .tag = "lte" },
    .{ .token = TokenType.GreaterThanEqual, .tag = "gte" },
    .{ .token = TokenType.Instanceof, .tag = "instanceof" },
    .{ .token = TokenType.In, .tag = "in" },
    .{ .token = TokenType.LessThanLessThan, .tag = "bitwise_shift_left" },
    .{ .token = TokenType.GreaterThanGreaterThan, .tag = "bitwise_shift_right" },
    .{ .token = TokenType.GreaterThanGreaterThanGreaterThan, .tag = "bitwise_unsigned_right_shift" },
    .{ .token = TokenType.Plus, .tag = "plus_expr" },
    .{ .token = TokenType.Minus, .tag = "minus_expr" },
    .{ .token = TokenType.Star, .tag = "multiply_expr" },
    .{ .token = TokenType.Slash, .tag = "div_expr" },
    .{ .token = TokenType.Percent, .tag = "modulo_expr" },
    .{ .token = TokenType.StarStar, .tag = "exp_expr" },
};

fn parseBinaryExpression(self: *Self, operator_index: comptime_int) ParserError!AST.Node.Index {
    var node = if (operator_index + 1 < binary_operators.len) try self.parseBinaryExpression(operator_index + 1) else try self.parseUnary();
    while (self.match(binary_operators[operator_index].token)) {
        const new_node = try self.pool.addNode(self.cur_token, @unionInit(AST.Node, binary_operators[operator_index].tag, .{
            .left = node,
            .right = if (operator_index + 1 < binary_operators.len) try self.parseBinaryExpression(operator_index + 1) else try self.parseUnary(),
        }));
        node = new_node;
    }
    return node;
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
fn parseUnary(self: *Self) ParserError!AST.Node.Index {
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
        try self.parsePrimaryExpression() orelse
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

        while (true) {
            if (self.match(TokenType.CloseParen)) {
                break;
            }

            if (self.match(TokenType.Comma)) {
                return self.fail(diagnostics.argument_expression_expected, .{});
            }

            try nodes.append(try self.parseAssignment());

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

fn parsePrimaryExpression(self: *Self) ParserError!?AST.Node.Index {
    return try self.parseThis() orelse
        try self.parseIdentifier() orelse
        try self.parseLiteral() orelse
        try self.parseArrayLiteral() orelse
        try self.parseObjectLiteral() orelse
        try self.parseFunctionStatement(AST.FunctionFlags.None) orelse
        try self.parseAsyncFunctionStatement() orelse
        // try self.parseClassExpression() orelse
        // try self.parseGeneratorExpression() orelse
        try self.parseGroupingExpression();
}

fn parseThis(self: *Self) ParserError!?AST.Node.Index {
    if (self.match(TokenType.This)) {
        return try self.pool.addNode(self.cur_token - 1, AST.Node{ .simple_value = .{ .kind = .this } });
    }

    return null;
}

fn parseIdentifier(self: *Self) ParserError!?AST.Node.Index {
    if (self.match(TokenType.Identifier) or try self.parseKeywordAsIdentifier() != null) {
        return try self.pool.addNode(self.cur_token - 1, AST.Node{ .simple_value = .{ .kind = .identifier } });
    }

    return null;
}

const literal_map = .{
    .{ TokenType.Null, .null },
    .{ TokenType.Undefined, .undefined },
    .{ TokenType.True, .true },
    .{ TokenType.False, .false },
    .{ TokenType.NumberConstant, .number },
    .{ TokenType.BigIntConstant, .bigint },
    .{ TokenType.StringConstant, .string },
};

fn parseLiteral(self: *Self) ParserError!?AST.Node.Index {
    inline for (literal_map) |literal| {
        if (self.match(literal[0])) {
            return try self.pool.addNode(self.cur_token - 1, AST.Node{ .simple_value = .{ .kind = literal[1] } });
        }
    }

    return null;
}

fn parseArrayLiteral(self: *Self) ParserError!?AST.Node.Index {
    if (!self.match(TokenType.OpenSquareBracket)) {
        return null;
    }

    var values = std.ArrayList(AST.Node.Index).init(self.arena.allocator());

    while (true) {
        while (self.match(TokenType.Comma)) {
            try values.append(AST.Node.Empty);
        }

        if (self.match(TokenType.CloseSquareBracket)) {
            break;
        }

        try values.append(try self.parseAssignment());
        const comma = self.consumeOrNull(TokenType.Comma);

        if (self.match(TokenType.CloseSquareBracket)) {
            break;
        } else if (comma == null) {
            return self.fail(diagnostics.ARG_expected, .{","});
        }
    }

    return try self.pool.addNode(self.cur_token, AST.Node{
        .array_literal = values.items,
    });
}

fn parseObjectLiteral(self: *Self) ParserError!?AST.Node.Index {
    if (!self.match(TokenType.OpenCurlyBrace)) {
        return null;
    }
    var nodes = std.ArrayList(AST.Node.Index).init(self.arena.allocator());

    var has_comma = true;
    while (true) {
        if (!has_comma) {
            return self.fail(diagnostics.ARG_expected, .{","});
        }

        const node = try self.parseMethodGetter() orelse
            try self.parseMethodSetter() orelse
            try self.parseAsyncGeneratorMethod() orelse
            try self.parseObjectField();

        if (node) |n| {
            try nodes.append(n);
        }

        if (self.match(TokenType.CloseCurlyBrace)) {
            break;
        } else {
            if (node == null) {
                if (self.peekMatch(TokenType.Comma)) {
                    return self.fail(diagnostics.property_assignment_expected, .{});
                }
                return self.fail(diagnostics.unexpected_token, .{});
            }

            if (node != null and !self.peekMatch(TokenType.Comma)) {
                return self.fail(diagnostics.ARG_expected, .{","});
            }

            has_comma = self.match(TokenType.Comma);
        }
    }

    return try self.pool.addNode(self.cur_token, AST.Node{
        .object_literal = nodes.items,
    });
}

fn parseObjectField(self: *Self) ParserError!?AST.Node.Index {
    const identifier = try self.parseObjectElementName();

    if (identifier == null) {
        return null;
    }

    if (self.match(TokenType.Colon)) {
        return try self.pool.addNode(self.cur_token, AST.Node{
            .object_literal_field = .{
                .left = identifier.?,
                .right = try self.parseAssignment(),
            },
        });
    } else if (self.peekMatch(TokenType.Comma) or self.peekMatch(TokenType.CloseCurlyBrace)) {
        _ = self.advance();
        return try self.pool.addNode(self.cur_token, AST.Node{
            .object_literal_field_shorthand = identifier.?,
        });
    }

    return null;
}

fn parseGroupingExpression(self: *Self) ParserError!?AST.Node.Index {
    if (self.match(TokenType.OpenParen)) {
        const node = try self.pool.addNode(self.cur_token, AST.Node{
            .grouping = try self.parseExpression(),
        });

        _ = try self.consume(TokenType.CloseParen, diagnostics.ARG_expected, .{")"});
        return node;
    }

    return null;
}

fn parseOptionalDataType(self: *Self) ParserError!AST.Node.Index {
    if (self.match(TokenType.Colon)) {
        return try self.parseSymbolType();
    }

    return AST.Node.Empty;
}

fn parseSymbolType(self: *Self) ParserError!AST.Node.Index {
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
    return args.items;
}

fn parseTupleType(self: *Self) ParserError!?AST.Node.Index {
    if (!self.match(TokenType.OpenSquareBracket)) {
        return null;
    }

    var list = std.ArrayList(AST.Node.Index).init(self.arena.allocator());
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
    const identifier = self.consumeOrNull(TokenType.Identifier) orelse try self.parseKeywordAsIdentifier() orelse return null;

    const type_map = .{
        .{ "number", .number },
        .{ "bigint", .bigint },
        .{ "string", .string },
        .{ "boolean", .boolean },
    };

    const value = self.tokens.items[identifier].value.?;
    inline for (type_map) |type_item| {
        if (std.mem.eql(u8, type_item[0], value)) {
            return try self.pool.addNode(identifier, AST.Node{ .simple_type = .{ .kind = type_item[1] } });
        }
    }

    return try self.pool.addNode(identifier, AST.Node{ .simple_type = .{ .kind = .identifier } });
}

fn parseKeywordAsIdentifier(self: *Self) ParserError!?Token.Index {
    if (consts.isAllowedIdentifier(self.token().type)) {
        return self.advance();
    }
    return null;
}

pub fn needsSemicolon(pool: *AST.Pool, node: AST.Node.Index) bool {
    const nodeRaw = pool.getRawNode(node);
    var tag = nodeRaw.tag;
    if (tag == .export_node or tag == .export_default) {
        tag = pool.getRawNode(nodeRaw.data.lhs).tag;
    }

    return switch (tag) {
        .block,
        .func_decl,
        .@"for",
        .@"while",
        .do_while,
        .@"if",
        .class_decl,
        .interface_decl,
        .object_method,
        => false,
        else => true,
    };
}
