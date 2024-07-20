const std = @import("std");
const ArrayList = std.ArrayList;

const Lexer = @import("lexer.zig");
const Closure = @import("closure.zig").Closure;
const Symbol = @import("symbols.zig").Symbol;
const ASTNode = @import("ast.zig").ASTNode;
const ASTNodeTag = @import("ast.zig").ASTNodeTag;
const ATTNode = @import("att.zig").ATTNode;

const diagnostics = @import("diagnostics.zig");

const consts = @import("consts.zig");
const Token = consts.Token;
const TokenType = consts.TokenType;
const TokenList = Lexer.TokenList;
const TokenListNode = Lexer.TokenListNode;

pub const ParserError = error{ SyntaxError, OutOfMemory, NoSpaceLeft, Overflow };

const Self = @This();

arena: std.heap.ArenaAllocator,
closure: Closure,
tokens: TokenList,
current_token: *TokenListNode,
errors: std.ArrayList([]const u8),

fn create(self: *Self, T: type, default_value: T) !*T {
    const item = try self.arena.allocator().create(T);
    item.* = default_value;
    return item;
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

pub fn parse(self: *Self) ParserError![]ASTNode {
    var nodes = std.ArrayList(ASTNode).init(self.arena.allocator());

    while (!self.match(TokenType.Eof)) {
        if (self.match(TokenType.NewLine) or self.match(TokenType.LineComment) or self.match(TokenType.MultilineComment)) {
            continue;
        }

        const node = try self.parseStatement();
        try nodes.append(node);
    }

    return nodes.items;
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

fn parseStatement(self: *Self) ParserError!ASTNode {
    const node = try self.parseBlock() orelse
        try self.parseDeclaration() orelse
        try self.parseClassStatement(null) orelse
        try self.parseAbstractClassStatement() orelse
        try self.parseImportStatement() orelse
        try self.parseExportStatement() orelse
        try self.parseEmptyStatement() orelse
        try self.parseIfStatement() orelse
        try self.parseBreakableStatement() orelse
        try self.parseReturnStatement() orelse
        try self.parseTypeDeclaration() orelse
        try self.parseInterfaceDeclaration() orelse
        try self.parseDeclareStatement() orelse
        try self.parseExpression();

    if (needsSemicolon(node)) {
        _ = try self.consume(TokenType.Semicolon, diagnostics.ARG_expected, .{";"});
    }
    return node;
}

fn parseImportStatement(self: *Self) ParserError!?ASTNode {
    if (!self.match(TokenType.Import)) {
        return null;
    }
    if (self.consumeOrNull(TokenType.StringConstant)) |path| {
        return .{
            .tag = .import,
            .data = .{
                .import = try self.create(ASTNode.Import, .{ .simple = path.value.? }),
            },
        };
    }

    const bindings = try self.parseImportClause();

    const path_token = try self.parseFromClause() orelse return self.fail(diagnostics.ARG_expected, .{"from"});

    return .{
        .tag = .import,
        .data = .{
            .import = try self.create(ASTNode.Import, .{
                .full = .{
                    .bindings = bindings,
                    .path = path_token.value.?,
                },
            }),
        },
    };
}

fn parseImportClause(self: *Self) ParserError![]ASTNode.ImportBinding {
    var bindings = std.ArrayList(ASTNode.ImportBinding).init(self.arena.allocator());

    try bindings.append(
        try self.parseImportDefaultBinding() orelse
            try self.parseImportNamespaceBinding() orelse
            try self.parseImportNamedBindings() orelse
            return self.fail(diagnostics.declaration_or_statement_expected, .{}),
    );

    if (bindings.items[0] == .default) {
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

fn parseImportDefaultBinding(self: *Self) !?ASTNode.ImportBinding {
    if (self.consumeOrNull(TokenType.Identifier)) |identifier| {
        return .{ .default = identifier.value.? };
    }

    return null;
}

fn parseImportNamespaceBinding(self: *Self) !?ASTNode.ImportBinding {
    if (!self.match(TokenType.Star)) {
        return null;
    }

    _ = try self.consume(TokenType.As, diagnostics.ARG_expected, .{"as"});
    const identifier = try self.consume(TokenType.Identifier, diagnostics.identifier_expected, .{});

    return .{ .namespace = identifier.value.? };
}

fn parseImportNamedBindings(self: *Self) !?ASTNode.ImportBinding {
    if (!self.match(TokenType.OpenCurlyBrace)) {
        return null;
    }

    var named_bindings = std.ArrayList(ASTNode.NamedBinding).init(self.arena.allocator());
    while (true) {
        if (self.consumeOrNull(TokenType.Identifier)) |identifier| {
            try named_bindings.append(.{
                .name = identifier.value.?,
                .alias = null,
            });
        }

        if (self.match(TokenType.CloseCurlyBrace)) {
            break;
        }
        _ = try self.consume(TokenType.Comma, diagnostics.ARG_expected, .{","});
    }

    return .{ .named = named_bindings.items };
}

fn parseExportStatement(self: *Self) ParserError!?ASTNode {
    if (!self.match(TokenType.Export)) {
        return null;
    }

    if (try self.parseExportFromClause()) |export_node| {
        return export_node;
    }

    const node = try self.parseDeclaration() orelse
        try self.parseClassStatement(null) orelse
        try self.parseAbstractClassStatement() orelse
        try self.parseDefaultExport() orelse
        return self.fail(diagnostics.declaration_or_statement_expected, .{});

    return .{
        .tag = .@"export",
        .data = .{
            .@"export" = try self.create(ASTNode.Export, .{
                .node = node,
            }),
        },
    };
}

fn parseExportFromClause(self: *Self) ParserError!?ASTNode {
    if (self.match(TokenType.Star)) {
        var namespace: ?[]const u8 = null;

        if (self.match(TokenType.As)) {
            const identifier = try self.consume(TokenType.Identifier, diagnostics.identifier_expected, .{});
            namespace = identifier.value.?;
        }

        const path_token = try self.parseFromClause() orelse return self.fail(diagnostics.ARG_expected, .{"from"});
        return .{
            .tag = .@"export",
            .data = .{
                .@"export" = try self.create(ASTNode.Export, .{ .all = .{
                    .alias = namespace,
                    .path = path_token.value.?,
                } }),
            },
        };
    }

    if (self.match(TokenType.OpenCurlyBrace)) {
        var exports = std.ArrayList(ASTNode.NamedBinding).init(self.arena.allocator());
        var has_comma = true;
        while (true) {
            if (self.match(TokenType.CloseCurlyBrace)) {
                break;
            }
            if (!has_comma) {
                try self.emitError(diagnostics.ARG_expected, .{","});
            }
            const identifier = try self.consume(TokenType.Identifier, diagnostics.identifier_expected, .{});
            var alias: ?[]const u8 = null;
            if (self.match(TokenType.As)) {
                const alias_token = try self.consume(TokenType.Identifier, diagnostics.identifier_expected, .{});
                alias = alias_token.value.?;
            }
            has_comma = self.consumeOrNull(TokenType.Comma) != null;
            try exports.append(.{
                .name = identifier.value.?,
                .alias = alias,
            });
        }
        const path_token = try self.parseFromClause();
        const path = if (path_token) |tok| tok.value.? else null;
        return .{
            .tag = .@"export",
            .data = .{
                .@"export" = try self.create(ASTNode.Export, .{
                    .from = .{
                        .bindings = exports.items,
                        .path = path,
                    },
                }),
            },
        };
    }

    return null;
}

fn parseDefaultExport(self: *Self) ParserError!?ASTNode {
    if (!self.match(TokenType.Default)) {
        return null;
    }

    return try self.parseFunctionStatement(null) orelse
        try self.parseAsyncFunctionStatement() orelse
        try self.parseAssignment();
}

fn parseFromClause(self: *Self) ParserError!?Token {
    if (!self.match(TokenType.From)) {
        return null;
    }
    return try self.consume(TokenType.StringConstant, diagnostics.string_literal_expected, .{});
}

fn parseAbstractClassStatement(self: *Self) ParserError!?ASTNode {
    if (!self.match(TokenType.Abstract)) {
        return null;
    }

    return try self.parseClassStatement(.abstract_class_decl) orelse {
        self.rewind();
        return null;
    };
}

fn parseClassStatement(self: *Self, tag: ?ASTNodeTag) ParserError!?ASTNode {
    if (!self.match(TokenType.Class)) {
        return null;
    }

    const name = self.consumeOrNull(TokenType.Identifier);
    var super_class: ?ASTNode = null;
    if (self.match(TokenType.Extends)) {
        const sp_token = try self.parseCallableExpression() orelse return self.fail(diagnostics.identifier_expected, .{});
        super_class = .{
            .tag = .identifier,
            .data = .{ .literal = sp_token.data.literal },
        };
    }

    var implements_list: ?[]ASTNode = null;
    if (self.match(TokenType.Implements)) {
        implements_list = try self.parseInterfaceList();
    }
    var body = std.ArrayList(ASTNode.ClassField).init(self.arena.allocator());

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
    return .{
        .tag = tag orelse .class_decl,
        .data = .{ .class = try self.create(ASTNode.Class, .{
            .name = if (name) |n| n.value.? else null,
            .super_class = super_class,
            .implements = implements_list,
            .body = body.items,
        }) },
    };
}

fn parseInterfaceList(self: *Self) ParserError![]ASTNode {
    var list = std.ArrayList(ASTNode).init(self.arena.allocator());

    while (true) {
        const identifier = self.consumeOrNull(TokenType.Identifier) orelse try self.parseKeywordAsIdentifier() orelse return self.fail(diagnostics.identifier_expected, .{});
        try list.append(.{
            .tag = .identifier,
            .data = .{
                .literal = identifier.value.?,
            },
        });
        if (!self.match(TokenType.Comma)) {
            break;
        }
    }
    return list.items;
}

fn parseClassStaticMember(self: *Self) ParserError!ASTNode.ClassField {
    if (self.match(TokenType.Static)) {
        if (self.match(TokenType.OpenCurlyBrace)) {
            var block = std.ArrayList(ASTNode).init(self.arena.allocator());
            while (true) {
                if (self.match(TokenType.CloseCurlyBrace)) {
                    break;
                }
                const field = try self.parseClassMember();
                try block.append(field.node);
            }
            var flags = std.EnumSet(ASTNode.ClassFieldFlag){};
            flags.setPresent(.static, true);
            return .{
                .node = .{
                    .tag = .block,
                    .data = .{ .nodes = block.items },
                },
                .flags = flags,
            };
        }

        var field = try self.parseClassMember();
        field.flags.setPresent(.static, true);
        return field;
    }
    return try self.parseClassMember();
}

fn parseClassMember(self: *Self) ParserError!ASTNode.ClassField {
    var flags = std.EnumSet(ASTNode.ClassFieldFlag){};
    if (self.match(TokenType.Abstract)) {
        flags.setPresent(.abstract, true);
    }

    if (self.match(TokenType.Readonly)) {
        flags.setPresent(.readonly, true);
    }

    if (self.match(TokenType.Public)) {
        flags.setPresent(.public, true);
    }

    if (self.match(TokenType.Protected)) {
        flags.setPresent(.protected, true);
    }

    if (self.match(TokenType.Private)) {
        flags.setPresent(.private, true);
    }

    const node = try self.parseMethodGetter() orelse
        try self.parseMethodSetter() orelse
        try self.parseMethodGenerator(null) orelse
        try self.parseAsyncGeneratorMethod() orelse
        try self.parseMethod(null) orelse
        return self.fail(diagnostics.identifier_expected, .{});

    return .{
        .node = node,
        .flags = flags,
    };
}

fn parseAsyncGeneratorMethod(self: *Self) ParserError!?ASTNode {
    if (!self.match(TokenType.Async)) {
        return null;
    }

    return try self.parseMethodGenerator(.object_async_generator_method) orelse
        try self.parseMethod(.object_async_method);
}

fn parseMethodGenerator(self: *Self, tag: ?ASTNodeTag) ParserError!?ASTNode {
    if (!self.match(TokenType.Star)) {
        return null;
    }

    return try self.parseMethod(tag orelse .object_generator_method);
}

fn parseMethod(self: *Self, tag: ?ASTNodeTag) ParserError!?ASTNode {
    const elem_name = try self.parseObjectElementName() orelse return null;

    if (self.match(TokenType.OpenParen)) {
        const args = try self.parseFunctionArguments() orelse return self.fail(diagnostics.ARG_expected, .{"("});
        const body = try self.parseBlock() orelse return self.fail(diagnostics.ARG_expected, .{"{"});
        return .{
            .tag = tag orelse .object_method,
            .data = .{
                .function = try self.create(ASTNode.Function, .{
                    .name = elem_name,
                    .params = args,
                    .body = body,
                }),
            },
        };
    }

    return try self.parseClassMemberAssignment(elem_name);
}

fn parseClassMemberAssignment(self: *Self, elem_name: ASTNode) ParserError!ASTNode {
    _ = try self.parseOptionalDataType(.{ .tag = .any });
    var node = elem_name;
    if (self.match(TokenType.Equal)) {
        node = ASTNode{
            .tag = .assignment,
            .data = .{
                .binary = try self.create(ASTNode.Binary, .{
                    .left = elem_name,
                    .right = try self.parseAssignment(),
                }),
            },
        };
    }

    _ = try self.consume(TokenType.Semicolon, diagnostics.ARG_expected, .{";"});
    return node;
}

fn parseMethodGetter(self: *Self) ParserError!?ASTNode {
    if (!self.match(TokenType.Get)) {
        return null;
    }
    const elem_name = try self.parseObjectElementName() orelse {
        self.rewind();
        return try self.parseMethod(null);
    };

    _ = try self.consume(TokenType.OpenParen, diagnostics.ARG_expected, .{"("});
    const args = try self.parseFunctionArguments() orelse return self.fail(diagnostics.identifier_expected, .{});
    _ = try self.parseOptionalDataType(.{ .tag = .any });
    const body = try self.parseBlock() orelse return self.fail(diagnostics.ARG_expected, .{"{"});

    return .{
        .tag = .object_getter,
        .data = .{
            .function = try self.create(ASTNode.Function, .{
                .name = elem_name,
                .params = args,
                .body = body,
            }),
        },
    };
}

fn parseMethodSetter(self: *Self) ParserError!?ASTNode {
    if (!self.match(TokenType.Set)) {
        return null;
    }
    const elem_name = try self.parseObjectElementName() orelse {
        self.rewind();
        return try self.parseMethod(null);
    };

    _ = try self.consume(TokenType.OpenParen, diagnostics.ARG_expected, .{"("});
    const args = try self.parseFunctionArguments() orelse return self.fail(diagnostics.identifier_expected, .{});
    _ = try self.parseOptionalDataType(.{ .tag = .any });
    const body = try self.parseBlock() orelse return self.fail(diagnostics.ARG_expected, .{"{"});

    return .{
        .tag = .object_setter,
        .data = .{
            .function = try self.create(ASTNode.Function, .{
                .name = elem_name,
                .params = args,
                .body = body,
            }),
        },
    };
}

fn parseObjectElementName(self: *Self) ParserError!?ASTNode {
    switch (self.token().type) {
        .Identifier => {
            const name = self.advance();
            return .{ .tag = .identifier, .data = .{ .literal = name.value.? } };
        },
        .StringConstant => {
            const name = self.advance();
            return .{ .tag = .string, .data = .{ .literal = name.value.? } };
        },
        .NumberConstant => {
            const name = self.advance();
            return .{ .tag = .number, .data = .{ .literal = name.value.? } };
        },
        .BigIntConstant => {
            const name = self.advance();
            return .{ .tag = .bigint, .data = .{ .literal = name.value.? } };
        },
        .OpenSquareBracket => {
            _ = self.advance();
            const node = try self.parseAssignment();
            _ = try self.consume(TokenType.CloseSquareBracket, diagnostics.ARG_expected, .{"]"});
            return .{ .tag = .computed_identifier, .data = .{ .node = try self.create(ASTNode, node) } };
        },
        .Hash => {
            _ = self.advance();
            const name = try self.consume(TokenType.Identifier, diagnostics.identifier_expected, .{});
            return .{ .tag = .private_identifier, .data = .{ .literal = name.value.? } };
        },
        else => {
            return null;
        },
    }
}

fn parseAsyncFunctionStatement(self: *Self) ParserError!?ASTNode {
    if (!self.match(TokenType.Async)) {
        return null;
    }

    return try self.parseFunctionStatement(.async_func_decl);
}

fn parseFunctionStatement(self: *Self, tag: ?ASTNodeTag) ParserError!?ASTNode {
    if (!self.match(TokenType.Function)) {
        return null;
    }

    var func_name: ?ASTNode = null;
    if (self.consumeOrNull(TokenType.Identifier)) |identifier| {
        func_name = .{
            .tag = .identifier,
            .data = .{ .literal = identifier.value.? },
        };
    }
    _ = try self.consume(TokenType.OpenParen, diagnostics.ARG_expected, .{"("});

    const args = try self.parseFunctionArguments() orelse return self.fail(diagnostics.ARG_expected, .{"("});
    _ = try self.parseOptionalDataType(.{ .tag = .any });
    const body = try self.parseBlock() orelse return self.fail(diagnostics.ARG_expected, .{"{"});

    return .{
        .tag = tag orelse .func_decl,
        .data = .{ .function = try self.create(ASTNode.Function, .{
            .name = func_name,
            .params = args,
            .body = body,
        }) },
    };
}

fn parseFunctionArguments(self: *Self) ParserError!?[]ASTNode {
    var args = std.ArrayList(ASTNode).init(self.arena.allocator());
    var has_comma = true;
    while (true) {
        if (self.match(TokenType.CloseParen)) {
            break;
        }

        if (self.consumeOrNull(TokenType.Identifier)) |identifier| {
            if (!has_comma) {
                try self.emitError(diagnostics.ARG_expected, .{","});
            }
            _ = try self.parseOptionalDataType(.{ .tag = .any });
            try args.append(.{
                .tag = .identifier,
                .data = .{ .literal = identifier.value.? },
            });
        } else {
            return null;
        }

        has_comma = self.match(TokenType.Comma);
    }
    return args.items;
}

fn parseBlock(self: *Self) ParserError!?ASTNode {
    if (!self.match(TokenType.OpenCurlyBrace)) {
        return null;
    }

    self.closure.new_closure();
    var statements = std.ArrayList(ASTNode).init(self.arena.allocator());

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

    self.closure.close_closure();

    return .{
        .tag = .block,
        .data = .{ .nodes = statements.items },
    };
}

fn parseDeclaration(self: *Self) ParserError!?ASTNode {
    const tag: ASTNodeTag = switch (self.token().type) {
        .Var => .var_decl,
        .Let => .let_decl,
        .Const => .const_decl,
        else => return try self.parseFunctionStatement(null) orelse try self.parseAsyncFunctionStatement(),
    };
    _ = self.advance();

    var nodes = std.ArrayList(ASTNode).init(self.arena.allocator());

    while (true) {
        const identifier = try self.parseIdentifier() orelse return error.SyntaxError;

        const identifier_data_type = try self.parseOptionalDataType(.{ .tag = .none });
        if (self.match(TokenType.Equal)) {
            const right = try self.parseAssignment();
            try nodes.append(.{
                .tag = .assignment,
                .data = .{
                    .binary = try self.create(ASTNode.Binary, .{
                        .left = identifier,
                        .right = right,
                    }),
                },
            });
        } else {
            try nodes.append(identifier);
        }

        _ = try self.closure.addSymbol(identifier.data.literal, .{
            .name = identifier.data.literal,
            .kind = .declaration,
            .type = identifier_data_type,
        });

        if (!self.match(TokenType.Comma)) {
            break;
        }
    }

    return .{
        .tag = tag,
        .data = .{ .nodes = nodes.items },
    };
}

fn parseDeclareStatement(self: *Self) ParserError!?ASTNode {
    if (!self.match(TokenType.Declare)) {
        return null;
    }

    const node = try self.parseDeclaration() orelse return error.SyntaxError;
    return .{
        .tag = .declare,
        .data = .{ .node = try self.create(ASTNode, node) },
    };
}

fn parseTypeDeclaration(self: *Self) ParserError!?ASTNode {
    if (!self.match(TokenType.Type)) {
        return null;
    }

    const identifier = self.consumeOrNull(TokenType.Identifier) orelse
        try self.parseKeywordAsIdentifier() orelse
        return error.SyntaxError;

    _ = try self.consume(TokenType.Equal, diagnostics.ARG_expected, .{"="});

    const identifier_data_type = try self.parseSymbolType();

    const symbol = try self.closure.addSymbol(identifier.value.?, .{
        .name = identifier.value.?,
        .kind = .declaration,
        .type = identifier_data_type,
    });
    return .{
        .tag = .type_decl,
        .data = .{ .symbol = symbol },
    };
}

fn parseInterfaceDeclaration(self: *Self) ParserError!?ASTNode {
    if (!self.match(TokenType.Interface)) {
        return null;
    }

    const identifier = self.consumeOrNull(TokenType.Identifier) orelse try self.parseKeywordAsIdentifier() orelse return error.SyntaxError;
    _ = try self.consume(TokenType.OpenCurlyBrace, diagnostics.ARG_expected, .{"{"});

    var list = std.ArrayList(ATTNode.Record).init(self.arena.allocator());
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
            return error.SyntaxError;
        try list.append(node);
        has_comma = self.match(TokenType.Comma) or self.match(TokenType.Semicolon);
    }
    const interface_type = .{ .tag = .object, .data = .{ .object = list.items } };
    const symbol = try self.closure.addSymbol(identifier.value.?, .{
        .name = identifier.value.?,
        .kind = .declaration,
        .type = interface_type,
    });

    return .{
        .tag = .interface_decl,
        .data = .{ .symbol = symbol },
    };
}

fn parseReturnStatement(self: *Self) ParserError!?ASTNode {
    if (!self.match(TokenType.Return)) {
        return null;
    }

    if (self.match(TokenType.Semicolon)) {
        return .{ .tag = .@"return" };
    }

    return .{
        .tag = .@"return",
        .data = .{ .node = try self.create(ASTNode, try self.parseExpression()) },
    };
}

fn parseEmptyStatement(self: *Self) ParserError!?ASTNode {
    if (!self.match(TokenType.Semicolon)) {
        return null;
    }

    return .{ .tag = .none };
}

fn parseIfStatement(self: *Self) ParserError!?ASTNode {
    if (!self.match(TokenType.If)) {
        return null;
    }

    _ = try self.consume(TokenType.OpenParen, diagnostics.ARG_expected, .{"("});
    const left = try self.parseExpression();
    _ = try self.consume(TokenType.CloseParen, diagnostics.ARG_expected, .{")"});

    const node = .{
        .tag = .@"if",
        .data = .{
            .binary = try self.create(ASTNode.Binary, .{
                .left = left,
                .right = try self.parseStatement(),
            }),
        },
    };

    if (!self.match(TokenType.Else)) {
        return node;
    }

    const else_node = try self.parseStatement();

    return .{
        .tag = .@"else",
        .data = .{
            .binary = try self.create(ASTNode.Binary, .{
                .left = node,
                .right = else_node,
            }),
        },
    };
}

fn parseBreakableStatement(self: *Self) ParserError!?ASTNode {
    return try parseDoWhileStatement(self) orelse try parseWhileStatement(self) orelse try parseForStatement(self);
}

fn parseDoWhileStatement(self: *Self) ParserError!?ASTNode {
    if (!self.match(TokenType.Do)) {
        return null;
    }

    const node = try self.parseStatement();
    _ = try self.consume(TokenType.While, diagnostics.ARG_expected, .{"while"});
    _ = try self.consume(TokenType.OpenParen, diagnostics.ARG_expected, .{"("});
    const condition = try self.parseExpression();
    _ = try self.consume(TokenType.CloseParen, diagnostics.ARG_expected, .{")"});
    _ = try self.consume(TokenType.Semicolon, diagnostics.ARG_expected, .{";"});

    return .{
        .tag = .do_while,
        .data = .{
            .binary = try self.create(ASTNode.Binary, .{
                .left = condition,
                .right = node,
            }),
        },
    };
}

fn parseWhileStatement(self: *Self) ParserError!?ASTNode {
    if (!self.match(TokenType.While)) {
        return null;
    }

    _ = try self.consume(TokenType.OpenParen, diagnostics.ARG_expected, .{"("});
    const condition = try self.parseExpression();
    _ = try self.consume(TokenType.CloseParen, diagnostics.ARG_expected, .{")"});

    return .{
        .tag = .@"while",
        .data = .{
            .binary = try self.create(ASTNode.Binary, .{
                .left = condition,
                .right = try self.parseStatement(),
            }),
        },
    };
}

fn parseForStatement(self: *Self) ParserError!?ASTNode {
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

    return .{
        .tag = .@"for",
        .data = .{
            .binary = try self.create(ASTNode.Binary, .{
                .left = for_inner.?,
                .right = try self.parseStatement(),
            }),
        },
    };
}

fn parseForClassicStatement(self: *Self, init_node: ASTNode) ParserError!?ASTNode {
    if (!self.match(TokenType.Semicolon)) {
        return null;
    }

    var nodes = std.ArrayList(ASTNode).init(self.arena.allocator());

    try nodes.append(init_node);
    try nodes.append(try self.parseExpression());
    _ = try self.consume(TokenType.Semicolon, diagnostics.ARG_expected, .{";"});
    try nodes.append(try self.parseExpression());
    _ = try self.consume(TokenType.CloseParen, diagnostics.ARG_expected, .{")"});

    return .{
        .tag = .for_classic,
        .data = .{ .nodes = nodes.items },
    };
}

fn parseForInStatement(self: *Self, init_node: ASTNode) ParserError!?ASTNode {
    if (!self.match(TokenType.In)) {
        return null;
    }

    const right = try self.parseExpression();
    _ = try self.consume(TokenType.CloseParen, diagnostics.ARG_expected, .{")"});

    return .{
        .tag = .for_in,
        .data = .{
            .binary = try self.create(ASTNode.Binary, .{
                .left = init_node,
                .right = right,
            }),
        },
    };
}

fn parseForOfStatement(self: *Self, init_node: ASTNode) ParserError!?ASTNode {
    if (!self.match(TokenType.Of)) {
        return null;
    }

    const right = try self.parseExpression();
    _ = try self.consume(TokenType.CloseParen, diagnostics.ARG_expected, .{")"});

    return .{
        .tag = .for_of,
        .data = .{
            .binary = try self.create(ASTNode.Binary, .{
                .left = init_node,
                .right = right,
            }),
        },
    };
}

fn parseForInitExpression(self: *Self) ParserError!ASTNode {
    if (self.match(TokenType.Semicolon)) {
        return .{ .tag = .none, .data = .{ .none = {} } };
    }

    return try self.parseDeclaration() orelse try self.parseExpression();
}

fn parseExpression(self: *Self) ParserError!ASTNode {
    var node = try self.parseAssignment();
    while (self.match(TokenType.Comma)) {
        const new_node = .{
            .tag = .comma,
            .data = .{
                .binary = try self.create(ASTNode.Binary, .{
                    .left = node,
                    .right = try self.parseAssignment(),
                }),
            },
        };

        node = new_node;
    }

    return node;
}

fn parseAssignment(self: *Self) ParserError!ASTNode {
    var casting_type: ?ATTNode = null;
    if (self.match(TokenType.LessThan)) {
        casting_type = try self.parseSymbolType();
        _ = try self.consume(TokenType.GreaterThan, diagnostics.ARG_expected, .{">"});
    }
    const node = try self.parseAsyncArrowFunction() orelse try self.parseArrowFunction() orelse try self.parseConditionalExpression();

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

    return .{
        .tag = tag,
        .data = .{
            .binary = try self.create(ASTNode.Binary, .{
                .left = node,
                .right = try self.parseAssignment(),
            }),
        },
    };
}

fn parseConditionalExpression(self: *Self) ParserError!ASTNode {
    var node = try self.parseShortCircuitExpression();

    if (self.match(TokenType.QuestionMark)) {
        const true_expr = try self.parseAssignment();
        _ = try self.consume(TokenType.Colon, diagnostics.ARG_expected, .{":"});
        const false_expr = try self.parseAssignment();
        const ternary_then = .{
            .tag = .ternary_then,
            .data = .{
                .binary = try self.create(ASTNode.Binary, .{
                    .left = true_expr,
                    .right = false_expr,
                }),
            },
        };
        const new_node = .{
            .tag = .ternary,
            .data = .{
                .binary = try self.create(ASTNode.Binary, .{
                    .left = node,
                    .right = ternary_then,
                }),
            },
        };

        node = new_node;
    }

    return node;
}

fn parseAsyncArrowFunction(self: *Self) ParserError!?ASTNode {
    if (!self.match(TokenType.Async)) {
        return null;
    }

    return try self.parseArrowFunctionWith1Arg(.async_arrow_function) orelse try self.parseArrowFunctionWithParenthesis(.async_arrow_function);
}

fn parseArrowFunction(self: *Self) ParserError!?ASTNode {
    return try self.parseArrowFunctionWith1Arg(.arrow_function) orelse try self.parseArrowFunctionWithParenthesis(.arrow_function);
}

fn parseArrowFunctionWith1Arg(self: *Self, tag: ASTNodeTag) ParserError!?ASTNode {
    const arg = try self.parseIdentifier() orelse return null;
    if (!self.match(TokenType.Arrow)) {
        self.rewind();
        return null;
    }
    var args = try self.arena.allocator().alloc(ASTNode, 1);
    args[0] = arg;
    const body = try self.parseConciseBody();
    return .{
        .tag = tag,
        .data = .{
            .function = try self.create(ASTNode.Function, .{
                .name = null,
                .params = args,
                .body = body,
            }),
        },
    };
}

fn parseArrowFunctionWithParenthesis(self: *Self, tag: ASTNodeTag) ParserError!?ASTNode {
    const cp = self.current_token;
    if (!self.match(TokenType.OpenParen)) {
        return null;
    }

    const args = try self.parseFunctionArguments() orelse {
        self.current_token = cp;
        return null;
    };
    _ = try self.parseOptionalDataType(.{ .tag = .any });
    if (!self.match(TokenType.Arrow)) {
        self.current_token = cp;
        return null;
    }

    const body = try self.parseConciseBody();
    return .{
        .tag = tag,
        .data = .{
            .function = try self.create(ASTNode.Function, .{
                .name = null,
                .params = args,
                .body = body,
            }),
        },
    };
}

fn parseConciseBody(self: *Self) ParserError!ASTNode {
    return try self.parseBlock() orelse
        try self.parseAssignment();
}

fn parseShortCircuitExpression(self: *Self) ParserError!ASTNode {
    return try self.parseLogicalOr();
}

fn parseLogicalOr(self: *Self) ParserError!ASTNode {
    var node = try self.parseLogicalAnd();

    while (self.match(TokenType.BarBar)) {
        const new_node = .{
            .tag = .@"or",
            .data = .{
                .binary = try self.create(ASTNode.Binary, .{
                    .left = node,
                    .right = try self.parseLogicalAnd(),
                }),
            },
        };

        node = new_node;
    }

    return node;
}

fn parseLogicalAnd(self: *Self) ParserError!ASTNode {
    var node = try self.parseBitwiseOr();
    while (self.match(TokenType.AmpersandAmpersand)) {
        const new_node = .{
            .tag = .@"and",
            .data = .{
                .binary = try self.create(ASTNode.Binary, .{
                    .left = node,
                    .right = try self.parseBitwiseOr(),
                }),
            },
        };

        node = new_node;
    }

    return node;
}

fn parseBitwiseOr(self: *Self) ParserError!ASTNode {
    var node = try self.parseBitwiseXor();

    while (self.match(TokenType.Bar)) {
        const right = try self.parseBitwiseXor();
        const new_node = .{
            .tag = .bitwise_or,
            .data = .{
                .binary = try self.create(ASTNode.Binary, .{
                    .left = node,
                    .right = right,
                }),
            },
        };

        node = new_node;
    }

    return node;
}

fn parseBitwiseXor(self: *Self) ParserError!ASTNode {
    var node = try self.parseBitwiseAnd();

    while (self.match(TokenType.Caret)) {
        const right = try self.parseBitwiseAnd();
        const new_node = .{
            .tag = .bitwise_xor,
            .data = .{
                .binary = try self.create(ASTNode.Binary, .{
                    .left = node,
                    .right = right,
                }),
            },
        };

        node = new_node;
    }

    return node;
}

fn parseBitwiseAnd(self: *Self) ParserError!ASTNode {
    var node = try self.parseEquality();

    while (self.match(TokenType.Ampersand)) {
        const right = try self.parseEquality();
        const new_node = .{
            .tag = .bitwise_and,
            .data = .{
                .binary = try self.create(ASTNode.Binary, .{
                    .left = node,
                    .right = right,
                }),
            },
        };

        node = new_node;
    }

    return node;
}

fn parseEquality(self: *Self) ParserError!ASTNode {
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
        const new_node = .{
            .tag = tag,
            .data = .{
                .binary = try self.create(ASTNode.Binary, .{
                    .left = node,
                    .right = try self.parseRelational(),
                }),
            },
        };

        node = new_node;
    }

    return node;
}

fn parseRelational(self: *Self) ParserError!ASTNode {
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
        const new_node = .{
            .tag = tag,
            .data = .{
                .binary = try self.create(ASTNode.Binary, .{
                    .left = node,
                    .right = try self.parseShift(),
                }),
            },
        };

        node = new_node;
    }

    return node;
}

fn parseShift(self: *Self) ParserError!ASTNode {
    var node = try self.parseAdditive();

    while (true) {
        const tag: ASTNodeTag = switch (self.token().type) {
            .GreaterThanGreaterThan => .bitwise_shift_right,
            .GreaterThanGreaterThanGreaterThan => .bitwise_unsigned_right_shift,
            .LessThanLessThan => .bitwise_shift_left,
            else => break,
        };
        _ = self.advance();
        const new_node = .{
            .tag = tag,
            .data = .{
                .binary = try self.create(ASTNode.Binary, .{
                    .left = node,
                    .right = try self.parseAdditive(),
                }),
            },
        };

        node = new_node;
    }

    return node;
}

fn parseAdditive(self: *Self) ParserError!ASTNode {
    var node = try self.parseMultiplicative();

    while (true) {
        const tag: ASTNodeTag = switch (self.token().type) {
            .Plus => .plus_expr,
            .Minus => .minus_expr,
            else => break,
        };
        _ = self.advance();
        const new_node = .{
            .tag = tag,
            .data = .{
                .binary = try self.create(ASTNode.Binary, .{
                    .left = node,
                    .right = try self.parseMultiplicative(),
                }),
            },
        };

        node = new_node;
    }

    return node;
}

fn parseMultiplicative(self: *Self) ParserError!ASTNode {
    var node = try self.parseExponentiation();

    while (true) {
        const tag: ASTNodeTag = switch (self.token().type) {
            .Star => .multiply_expr,
            .Slash => .div_expr,
            .Percent => .modulo_expr,
            else => break,
        };
        _ = self.advance();
        const new_node = .{
            .tag = tag,
            .data = .{
                .binary = try self.create(ASTNode.Binary, .{
                    .left = node,
                    .right = try self.parseExponentiation(),
                }),
            },
        };

        node = new_node;
    }

    return node;
}

fn parseExponentiation(self: *Self) ParserError!ASTNode {
    var node = try self.parseUnary();

    while (self.match(TokenType.StarStar)) {
        const new_node = .{
            .tag = .exp_expr,
            .data = .{
                .binary = try self.create(ASTNode.Binary, .{
                    .left = node,
                    .right = try self.parseUnary(),
                }),
            },
        };

        node = new_node;
    }
    return node;
}

fn parseUnary(self: *Self) ParserError!ASTNode {
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
        return .{
            .tag = tag,
            .data = .{ .node = try self.create(ASTNode, try self.parseUnary()) },
        };
    }
}

fn parseUpdateExpression(self: *Self) ParserError!ASTNode {
    if (self.match(TokenType.PlusPlus)) {
        return .{
            .tag = .plusplus_pre,
            .data = .{ .node = try self.create(ASTNode, try self.parseUnary()) },
        };
    } else if (self.match(TokenType.MinusMinus)) {
        return .{
            .tag = .minusminus_pre,
            .data = .{ .node = try self.create(ASTNode, try self.parseUnary()) },
        };
    }

    const node = try self.parseLeftHandSideExpression();

    if (self.match(TokenType.PlusPlus)) {
        return .{
            .data = .{ .node = try self.create(ASTNode, node) },
            .tag = .plusplus_post,
        };
    } else if (self.match(TokenType.MinusMinus)) {
        return .{
            .data = .{ .node = try self.create(ASTNode, node) },
            .tag = .minusminus_post,
        };
    }

    return node;
}

fn parseLeftHandSideExpression(self: *Self) ParserError!ASTNode {
    return try self.parseCallableExpression() orelse return error.SyntaxError;
}

fn parseNewExpression(self: *Self) ParserError!?ASTNode {
    if (!self.match(TokenType.New)) {
        return null;
    }

    const node = try self.parseCallableExpression();
    if (node == null) {
        self.rewind();
        return null;
    }

    return .{
        .tag = .new_expr,
        .data = .{ .node = try self.create(ASTNode, node.?) },
    };
}

fn parseMemberExpression(self: *Self) ParserError!?ASTNode {
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

fn parseCallableExpression(self: *Self) ParserError!?ASTNode {
    var node = try self.parseMemberExpression() orelse return null;

    while (self.match(TokenType.OpenParen)) {
        var nodes = std.ArrayList(ASTNode).init(self.arena.allocator());
        try nodes.append(node);

        while (true) {
            if (self.match(TokenType.CloseParen)) {
                break;
            }

            if (self.match(TokenType.Comma)) {
                try self.emitError(diagnostics.argument_expression_expected, .{});
                return error.SyntaxError;
            }

            try nodes.append(try self.parseAssignment());

            if (!self.match(TokenType.CloseParen)) {
                _ = try self.consume(TokenType.Comma, diagnostics.ARG_expected, .{","});
            } else {
                break;
            }
        }

        node = .{
            .data = .{ .nodes = nodes.items },
            .tag = .call_expr,
        };
    }

    return node;
}

fn parseIndexAccess(self: *Self, expr: ASTNode) ParserError!?ASTNode {
    if (!self.match(TokenType.OpenSquareBracket)) {
        return null;
    }
    const node = .{
        .tag = .index_access,
        .data = .{
            .binary = try self.create(ASTNode.Binary, .{
                .left = expr,
                .right = try self.parseExpression(),
            }),
        },
    };

    _ = try self.consume(TokenType.CloseSquareBracket, diagnostics.ARG_expected, .{"]"});

    return node;
}

fn parsePropertyAccess(self: *Self, expr: ASTNode) ParserError!?ASTNode {
    if (!self.match(TokenType.Dot)) {
        return null;
    }

    const identifier = try self.parseIdentifier() orelse return error.SyntaxError;
    return .{
        .tag = .property_access,
        .data = .{
            .binary = try self.create(ASTNode.Binary, .{
                .left = expr,
                .right = identifier,
            }),
        },
    };
}

fn parsePrimaryExpression(self: *Self) ParserError!?ASTNode {
    return try self.parseThis() orelse
        try self.parseIdentifier() orelse
        try self.parseLiteral() orelse
        try self.parseArrayLiteral() orelse
        try self.parseObjectLiteral() orelse
        try self.parseFunctionStatement(null) orelse
        try self.parseAsyncFunctionStatement() orelse
        // try self.parseClassExpression() orelse
        // try self.parseGeneratorExpression() orelse
        try self.parseGroupingExpression();
}

fn parseThis(self: *Self) ParserError!?ASTNode {
    if (self.match(TokenType.This)) {
        return .{ .tag = .this, .data = .{ .none = {} } };
    }

    return null;
}

fn parseIdentifier(self: *Self) ParserError!?ASTNode {
    if (self.consumeOrNull(TokenType.Identifier)) |identifier| {
        return .{ .tag = .identifier, .data = .{ .literal = identifier.value.? } };
    }

    if (consts.isAllowedIdentifier(self.token().type)) {
        const identifier = self.advance();
        return .{ .tag = .identifier, .data = .{ .literal = identifier.value.? } };
    }

    return null;
}

fn parseLiteral(self: *Self) ParserError!?ASTNode {
    if (self.match(TokenType.Null)) {
        return .{ .tag = .null, .data = .{ .none = {} } };
    } else if (self.match(TokenType.Undefined)) {
        return .{ .tag = .undefined, .data = .{ .none = {} } };
    } else if (self.match(TokenType.True)) {
        return .{ .tag = .true, .data = .{ .none = {} } };
    } else if (self.match(TokenType.False)) {
        return .{ .tag = .false, .data = .{ .none = {} } };
    } else if (self.consumeOrNull(TokenType.NumberConstant)) |number| {
        return .{ .tag = .number, .data = .{ .literal = number.value.? } };
    } else if (self.consumeOrNull(TokenType.BigIntConstant)) |bigint| {
        return .{ .tag = .bigint, .data = .{ .literal = bigint.value.? } };
    } else if (self.consumeOrNull(TokenType.StringConstant)) |string| {
        return .{ .tag = .string, .data = .{ .literal = string.value.? } };
    }

    return null;
}

fn parseArrayLiteral(self: *Self) ParserError!?ASTNode {
    if (!self.match(TokenType.OpenSquareBracket)) {
        return null;
    }

    var values = std.ArrayList(ASTNode).init(self.arena.allocator());

    while (true) {
        while (self.match(TokenType.Comma)) {
            try values.append(.{ .tag = .none, .data = .{ .none = {} } });
        }

        if (self.match(TokenType.CloseSquareBracket)) {
            break;
        }

        try values.append(try self.parseAssignment());
        const comma: ?Token = self.consumeOrNull(TokenType.Comma);

        if (self.match(TokenType.CloseSquareBracket)) {
            break;
        } else if (comma == null) {
            try self.emitError(diagnostics.ARG_expected, .{","});
            return error.SyntaxError;
        }
    }

    return .{
        .tag = .array_literal,
        .data = .{ .nodes = values.items },
    };
}

fn parseObjectLiteral(self: *Self) ParserError!?ASTNode {
    if (!self.match(TokenType.OpenCurlyBrace)) {
        return null;
    }
    var nodes = std.ArrayList(ASTNode).init(self.arena.allocator());

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
            try nodes.append(n);
        }

        if (self.match(TokenType.CloseCurlyBrace)) {
            break;
        } else {
            if (node == null) {
                if (self.peekMatch(TokenType.Comma)) {
                    try self.emitError(diagnostics.property_assignment_expected, .{});
                } else {
                    try self.emitError(diagnostics.unexpected_token, .{});
                }
                return error.SyntaxError;
            } else if (node != null and !self.peekMatch(TokenType.Comma)) {
                try self.emitError(diagnostics.ARG_expected, .{","});
            }

            has_comma = self.match(TokenType.Comma);
        }
    }

    return .{
        .tag = .object_literal,
        .data = .{ .nodes = nodes.items },
    };
}

fn parseObjectField(self: *Self) ParserError!?ASTNode {
    const identifier = try self.parseObjectElementName();

    if (identifier == null) {
        return null;
    }

    if (self.match(TokenType.Colon)) {
        return .{
            .tag = .object_literal_field,
            .data = .{
                .binary = try self.create(ASTNode.Binary, .{
                    .left = identifier.?,
                    .right = try self.parseAssignment(),
                }),
            },
        };
    } else if (self.peekMatch(TokenType.Comma) or self.peekMatch(TokenType.CloseCurlyBrace)) {
        return .{
            .tag = .object_literal_field_shorthand,
            .data = .{ .node = try self.create(ASTNode, identifier.?) },
        };
    }

    return null;
}

fn parseGroupingExpression(self: *Self) ParserError!?ASTNode {
    if (self.match(TokenType.OpenParen)) {
        const node = .{
            .tag = .grouping,
            .data = .{ .node = try self.create(ASTNode, try self.parseExpression()) },
        };
        _ = try self.consume(TokenType.CloseParen, diagnostics.ARG_expected, .{")"});
        return node;
    }

    return null;
}

fn parseOptionalDataType(self: *Self, default: ATTNode) ParserError!ATTNode {
    if (self.match(TokenType.Colon)) {
        return try self.parseSymbolType();
    }

    return default;
}

fn parseSymbolType(self: *Self) ParserError!ATTNode {
    return try self.parseSymbolUnionType() orelse
        return self.fail(diagnostics.type_expected, .{});
}

fn parseSymbolUnionType(self: *Self) ParserError!?ATTNode {
    var node = try self.parseSymbolIntersectionType() orelse return null;

    if (self.match(TokenType.Bar)) {
        const new_node = .{
            .tag = .@"union",
            .data = .{
                .binary = try self.create(ATTNode.Binary, .{
                    .left = node,
                    .right = try self.parseSymbolUnionType() orelse return self.fail(diagnostics.type_expected, .{}),
                }),
            },
        };
        node = new_node;
    }

    return node;
}

fn parseSymbolIntersectionType(self: *Self) ParserError!?ATTNode {
    var node = try self.parseSymbolTypeUnary() orelse return null;

    if (self.match(TokenType.Ampersand)) {
        const new_node = .{
            .tag = .intersection,
            .data = .{
                .binary = try self.create(ATTNode.Binary, .{
                    .left = node,
                    .right = try self.parseSymbolIntersectionType() orelse return self.fail(diagnostics.type_expected, .{}),
                }),
            },
        };

        node = new_node;
    }

    return node;
}

fn parseSymbolTypeUnary(self: *Self) ParserError!?ATTNode {
    if (self.match(TokenType.Typeof)) {
        return .{
            .tag = .typeof,
            .data = .{ .node = try self.create(ATTNode, try self.parseSymbolType()) },
        };
    } else if (self.match(TokenType.Keyof)) {
        return .{
            .tag = .keyof,
            .data = .{ .node = try self.create(ATTNode, try self.parseSymbolType()) },
        };
    }

    return try self.parseSymbolArrayType();
}

fn parseSymbolArrayType(self: *Self) ParserError!?ATTNode {
    const node = try self.parsePrimarySymbolType() orelse return null;

    if (self.match(TokenType.OpenSquareBracket)) {
        if (self.match(TokenType.CloseSquareBracket)) {
            return .{ .tag = .array, .data = .{ .node = try self.create(ATTNode, node) } };
        } else {
            return self.fail(diagnostics.unexpected_token, .{});
        }
    }

    return node;
}

fn parsePrimarySymbolType(self: *Self) ParserError!?ATTNode {
    return try self.parseObjectType() orelse
        try self.parseTupleType() orelse
        try self.parsePrimitiveType() orelse
        try self.parseGenericType();
}

fn parseObjectType(self: *Self) ParserError!?ATTNode {
    if (!self.match(TokenType.OpenCurlyBrace)) {
        return null;
    }

    var list = std.ArrayList(ATTNode.Record).init(self.arena.allocator());

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

    return .{ .tag = .object, .data = .{ .object = list.items } };
}

fn parseObjectPropertyType(self: *Self) ParserError!?ATTNode.Record {
    const cp = self.current_token;
    const identifier = self.consumeOrNull(TokenType.Identifier) orelse try self.parseKeywordAsIdentifier() orelse {
        self.current_token = cp;
        return null;
    };

    var right: ATTNode = undefined;

    if (self.match(TokenType.Colon)) {
        right = try self.parseSymbolType();
    } else {
        right = .{ .tag = .any };
    }

    return .{
        .name = identifier.value.?,
        .type = right,
    };
}

fn parseObjectMethodType(self: *Self) ParserError!?ATTNode.Record {
    const cp = self.current_token;
    const identifier = self.consumeOrNull(TokenType.Identifier) orelse
        try self.parseKeywordAsIdentifier() orelse
        self.consumeOrNull(TokenType.New) orelse {
        self.current_token = cp;
        return null;
    };

    if (!self.match(TokenType.OpenParen)) {
        self.current_token = cp;
        return null;
    }
    const list = try self.parseFunctionArgumentsType();
    const return_type = try self.parseOptionalDataType(.{ .tag = .any });
    return .{
        .name = identifier.value.?,
        .type = .{
            .tag = .function,
            .data = .{ .function = try self.create(ATTNode.Function, .{
                .params = list,
                .return_type = return_type,
            }) },
        },
    };
}

fn parseFunctionArgumentsType(self: *Self) ParserError![]ATTNode.Record {
    var args = std.ArrayList(ATTNode.Record).init(self.arena.allocator());
    var has_comma = true;
    while (true) {
        if (self.match(TokenType.CloseParen)) {
            break;
        }

        if (self.consumeOrNull(TokenType.Identifier)) |identifier| {
            if (!has_comma) {
                try self.emitError(diagnostics.ARG_expected, .{","});
            }
            const arg_type = try self.parseOptionalDataType(.{ .tag = .any });
            try args.append(.{
                .name = identifier.value.?,
                .type = arg_type,
            });
        } else {
            return self.fail(diagnostics.identifier_expected, .{});
        }

        has_comma = self.match(TokenType.Comma);
    }
    return args.items;
}

fn parseTupleType(self: *Self) ParserError!?ATTNode {
    if (!self.match(TokenType.OpenSquareBracket)) {
        return null;
    }

    var list = std.ArrayList(ATTNode).init(self.arena.allocator());
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
    return .{ .tag = .tuple, .data = .{ .list = list.items } };
}

const primitive_types = .{
    .{ TokenType.NumberConstant, .{ .tag = .number } },
    .{ TokenType.BigIntConstant, .{ .tag = .bigint } },
    .{ TokenType.StringConstant, .{ .tag = .string } },
    .{ TokenType.True, .{ .tag = .boolean } },
    .{ TokenType.False, .{ .tag = .boolean } },
    .{ TokenType.Null, .{ .tag = .null } },
    .{ TokenType.Undefined, .{ .tag = .undefined } },
    .{ TokenType.Void, .{ .tag = .void } },
    .{ TokenType.Any, .{ .tag = .any } },
    .{ TokenType.Unknown, .{ .tag = .unknown } },
};

fn parsePrimitiveType(self: *Self) ParserError!?ATTNode {
    inline for (primitive_types) |primitive_type| {
        if (self.match(primitive_type[0])) {
            return primitive_type[1];
        }
    }

    return null;
}
fn parseGenericType(self: *Self) ParserError!?ATTNode {
    var node = try self.parseTypeIdentifier() orelse return null;

    if (self.match(TokenType.LessThan)) {
        var params = std.ArrayList(ATTNode).init(self.arena.allocator());

        while (true) {
            try params.append(try self.parseSymbolType());

            if (!self.match(TokenType.Comma)) {
                break;
            }
        }

        _ = try self.consume(TokenType.GreaterThan, diagnostics.ARG_expected, .{">"});

        node = .{
            .data = .{ .list = params.items },
            .tag = .generic,
        };
    }

    return node;
}

fn parseTypeIdentifier(self: *Self) ParserError!?ATTNode {
    const identifier = self.consumeOrNull(TokenType.Identifier) orelse try self.parseKeywordAsIdentifier() orelse return null;

    const value = identifier.value.?;
    if (std.mem.eql(u8, value, "number")) {
        return .{ .tag = .number };
    } else if (std.mem.eql(u8, value, "bigint")) {
        return .{ .tag = .bigint };
    } else if (std.mem.eql(u8, value, "string")) {
        return .{ .tag = .string };
    } else if (std.mem.eql(u8, value, "boolean")) {
        return .{ .tag = .boolean };
    }

    return .{ .tag = .identifier, .data = .{ .literal = identifier.value.? } };
}

fn parseKeywordAsIdentifier(self: *Self) ParserError!?Token {
    if (consts.isAllowedIdentifier(self.token().type)) {
        return self.advance();
    }
    return null;
}

pub fn needsSemicolon(node: ASTNode) bool {
    var tag = node.tag;
    if (tag == .@"export" and (node.data.@"export".* == .node or node.data.@"export".* == .default)) {
        tag = node.data.@"export".node.tag;
    }

    return switch (tag) {
        .block,
        .func_decl,
        .async_func_decl,
        .@"for",
        .@"while",
        .do_while,
        .@"if",
        .@"else",
        .class_decl,
        .abstract_class_decl,
        .interface_decl,
        .object_async_generator_method,
        .object_generator_method,
        .object_async_method,
        .object_method,
        .object_getter,
        .object_setter,
        => false,
        else => true,
    };
}
