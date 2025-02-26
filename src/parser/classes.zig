const std = @import("std");
const Parser = @import("../parser.zig");
const ParserError = @import("../parser.zig").ParserError;
const AST = @import("../ast.zig");
const Token = @import("../consts.zig").Token;
const TokenType = @import("../consts.zig").TokenType;
const StringId = @import("../string_interner.zig").StringId;
const diagnostics = @import("../diagnostics.zig");

const parseAssignment = @import("binary.zig").parseAssignment;
const expectAssignment = @import("binary.zig").expectAssignment;
const parseMethodGetter = @import("functions.zig").parseMethodGetter;
const parseMethodSetter = @import("functions.zig").parseMethodSetter;
const parseMethodGenerator = @import("functions.zig").parseMethodGenerator;
const parseMethodAsyncGenerator = @import("functions.zig").parseMethodAsyncGenerator;
const parseMethod = @import("functions.zig").parseMethod;
const parseObjectElementName = @import("functions.zig").parseObjectElementName;
const parseKeywordAsIdentifier = @import("primary.zig").parseKeywordAsIdentifier;
const parseOptionalDataType = @import("types.zig").parseOptionalDataType;
const parseCallableExpression = @import("expressions.zig").parseCallableExpression;

const snap = @import("../tests/snapshots.zig").snap;
const TestParser = @import("../tests/test_parser.zig");
const Marker = TestParser.Marker;

const expectEqualDeep = std.testing.expectEqualDeep;

pub fn parseAbstractClassStatement(self: *Parser) ParserError!?AST.Node.Index {
    if (!self.match(TokenType.Abstract)) {
        return null;
    }

    return try parseClassStatementExtra(self, self.cur_token.dec(1), true) orelse return self.fail(diagnostics.declaration_or_statement_expected, .{});
}

pub fn parseClassStatement(self: *Parser) ParserError!?AST.Node.Index {
    return try parseClassStatementExtra(self, self.cur_token, false);
}

pub fn parseClassStatementExtra(self: *Parser, main_token: Token.Index, is_abstract: bool) ParserError!?AST.Node.Index {
    if (!self.match(TokenType.Class)) {
        return null;
    }

    const name = self.internStr(self.consumeOrNull(TokenType.Identifier) orelse Token.Empty);
    var super_class: AST.Node.Index = AST.Node.Empty;
    if (self.match(TokenType.Extends)) {
        super_class = try parseCallableExpression(self) orelse return self.fail(diagnostics.identifier_expected, .{});
    }

    var implements_list: ?std.ArrayList(StringId) = null;
    if (self.match(TokenType.Implements)) {
        implements_list = try parseInterfaceList(self);
    }
    defer if (implements_list) |list| list.deinit();

    var body = std.ArrayList(AST.Node.Index).init(self.gpa);
    defer body.deinit();

    _ = try self.consume(TokenType.OpenCurlyBrace, diagnostics.ARG_expected, .{"{"});
    while (true) {
        if (self.match(TokenType.CloseCurlyBrace)) {
            break;
        }

        if (self.match(TokenType.Semicolon)) {
            continue;
        }

        try body.append(try parseClassStaticMember(self));
    }
    return self.addNode(main_token, AST.Node{ .class = .{
        .abstract = is_abstract,
        .name = name,
        .super_class = super_class,
        .implements = if (implements_list) |list| list.items else &[_]StringId{},
        .body = body.items,
    } });
}

pub fn parseInterfaceList(self: *Parser) ParserError!std.ArrayList(StringId) {
    var list = std.ArrayList(StringId).init(self.gpa);
    errdefer list.deinit();

    while (true) {
        const identifier = self.consumeOrNull(TokenType.Identifier) orelse
            parseKeywordAsIdentifier(self) orelse
            return self.fail(diagnostics.identifier_expected, .{});

        try list.append(self.internStr(identifier));
        if (!self.match(TokenType.Comma)) {
            break;
        }
    }
    return list;
}

pub fn parseClassStaticMember(self: *Parser) ParserError!AST.Node.Index {
    const main_token = self.cur_token;
    if (self.match(TokenType.Static)) {
        if (self.match(TokenType.OpenCurlyBrace)) {
            var block = std.ArrayList(AST.Node.Index).init(self.gpa);
            defer block.deinit();

            while (true) {
                if (self.match(TokenType.CloseCurlyBrace)) {
                    break;
                }
                const field = try parseClassMember(self);
                try block.append(field);
            }

            return self.addNode(main_token, AST.Node{
                .class_static_block = block.items,
            });
        }

        return self.addNode(main_token, AST.Node{ .class_member = .{
            .flags = AST.ClassMemberFlags.static,
            .node = try parseClassMember(self),
        } });
    }
    return try parseClassMember(self);
}

pub fn parseClassMember(self: *Parser) ParserError!AST.Node.Index {
    const main_token = self.cur_token;
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

    const node = try parseMethodGetter(self) orelse
        try parseMethodSetter(self) orelse
        try parseMethodGenerator(self) orelse
        try parseMethodAsyncGenerator(self) orelse
        try parseMethod(self) orelse
        try parseClassField(self) orelse
        return self.fail(diagnostics.identifier_expected, .{});

    return self.addNode(main_token, AST.Node{
        .class_member = .{
            .flags = @intCast(flags),
            .node = node,
        },
    });
}

pub fn parseClassField(self: *Parser) ParserError!?AST.Node.Index {
    const main_token = self.cur_token;
    const elem_name = try parseObjectElementName(self) orelse return null;
    const decl_type = try parseOptionalDataType(self);

    var value: AST.Node.Index = AST.Node.Empty;
    if (self.match(TokenType.Equal)) {
        value = try expectAssignment(self);
    }

    _ = try self.consume(TokenType.Semicolon, diagnostics.ARG_expected, .{";"});
    return self.addNode(main_token, AST.Node{ .class_field = .{
        .name = elem_name,
        .decl_type = decl_type,
        .value = value,
    } });
}

test "shoud parse class declaration" {
    const text =
        \\ class Foo {}
        \\>^
    ;

    const t, const node, const markers = try TestParser.run(text, parseClassStatement);
    defer t.deinit();

    try t.expectASTSnapshot(node, snap(@src(),
        \\ast.Node{
        \\    .class = ast.Node.ClassDeclaration{
        \\        .abstract = false,
        \\        .name = string_interner.StringId(1),
        \\        .super_class = ast.Node.Index.empty,
        \\        .implements = [_]string_interner.StringId{},
        \\        .body = [_]ast.Node.Index{},
        \\    },
        \\}
    ));
    try t.expectTokenAt(markers[0], node.?);
}

test "should return syntax error if class name is not an identifier" {
    const text =
        \\ class 123 {}
        \\>      ^
    ;

    const t, const nodeOrError, _ = try TestParser.runCatch(text, parseClassStatement);
    defer t.deinit();

    try t.expectSyntaxError(nodeOrError, diagnostics.ARG_expected, .{"{"});
}

test "should return syntax error if open curly brace is missing" {
    const text =
        \\class Foo
        \\>        ^
    ;

    const t, const nodeOrError, const markers = try TestParser.runCatch(text, parseClassStatement);
    defer t.deinit();

    try t.expectSyntaxErrorAt(nodeOrError, diagnostics.ARG_expected, .{"{"}, markers[0]);
}

test "should parse abstract class declaration" {
    const text =
        \\ abstract class Foo {}
        \\>^
    ;

    const t, const node, const markers = try TestParser.run(text, parseAbstractClassStatement);
    defer t.deinit();

    try t.expectASTSnapshot(node, snap(@src(),
        \\ast.Node{
        \\    .class = ast.Node.ClassDeclaration{
        \\        .abstract = true,
        \\        .name = string_interner.StringId(1),
        \\        .super_class = ast.Node.Index.empty,
        \\        .implements = [_]string_interner.StringId{},
        \\        .body = [_]ast.Node.Index{},
        \\    },
        \\}
    ));
    try t.expectTokenAt(markers[0], node.?);
}

test "should return syntax error if abstract keyword is not followed by class" {
    const text =
        \\ abstract Foo {}
        \\>         ^
    ;

    const t, const nodeOrError, const markers = try TestParser.runCatch(text, parseAbstractClassStatement);
    defer t.deinit();

    try t.expectSyntaxErrorAt(nodeOrError, diagnostics.declaration_or_statement_expected, .{}, markers[0]);
}

test "should parse class declaration with extends" {
    const text = "class Foo extends Bar {}";

    const t, const node, _ = try TestParser.run(text, parseClassStatement);
    defer t.deinit();

    try t.expectASTSnapshot(node, snap(@src(),
        \\ast.Node{
        \\    .class = ast.Node.ClassDeclaration{
        \\        .abstract = false,
        \\        .name = string_interner.StringId(1),
        \\        .super_class = ast.Node.Index(0),
        \\        .implements = [_]string_interner.StringId{},
        \\        .body = [_]ast.Node.Index{},
        \\    },
        \\}
    ));
}

test "should parse class declaration with implements" {
    const text = "class Foo implements Bar, Baz {}";

    const t, const node, _ = try TestParser.run(text, parseClassStatement);
    defer t.deinit();

    try t.expectASTSnapshot(node, snap(@src(),
        \\ast.Node{
        \\    .class = ast.Node.ClassDeclaration{
        \\        .abstract = false,
        \\        .name = string_interner.StringId(1),
        \\        .super_class = ast.Node.Index.empty,
        \\        .implements = [_]string_interner.StringId{
        \\            string_interner.StringId(2), 
        \\            string_interner.StringId(3)
        \\        },
        \\        .body = [_]ast.Node.Index{},
        \\    },
        \\}
    ));
}

test "should return syntax error if interface name is not an identifier" {
    const text =
        \\class Foo implements 123 {}
        \\>                    ^
    ;

    const t, const nodeOrError, const markers = try TestParser.runCatch(text, parseClassStatement);
    defer t.deinit();

    try t.expectSyntaxErrorAt(nodeOrError, diagnostics.identifier_expected, .{}, markers[0]);
}

test "should parse class declaration without name" {
    const text = "class extends Bar implements Baz {}";

    const t, const node, _ = try TestParser.run(text, parseClassStatement);
    defer t.deinit();

    try t.expectASTSnapshot(node, snap(@src(),
        \\ast.Node{
        \\    .class = ast.Node.ClassDeclaration{
        \\        .abstract = false,
        \\        .name = string_interner.StringId.none,
        \\        .super_class = ast.Node.Index(0),
        \\        .implements = [_]string_interner.StringId{
        \\            string_interner.StringId(2)
        \\        },
        \\        .body = [_]ast.Node.Index{},
        \\    },
        \\}
    ));
}

test "should parse class members" {
    const text =
        \\class Foo {
        \\    a: number = 1;
        \\>   ^
        \\}
    ;

    const t, const node, const markers = try TestParser.run(text, parseClassStatement);
    defer t.deinit();

    try t.expectASTSnapshot(node, snap(@src(),
        \\ast.Node{
        \\    .class = ast.Node.ClassDeclaration{
        \\        .abstract = false,
        \\        .name = string_interner.StringId(1),
        \\        .super_class = ast.Node.Index.empty,
        \\        .implements = [_]string_interner.StringId{},
        \\        .body = [_]ast.Node.Index{
        \\            ast.Node.Index(4)
        \\        },
        \\    },
        \\}
    ));

    const class_decl = t.parser.getNode(node.?);
    try t.expectASTSnapshot(class_decl.class.body[0], snap(@src(),
        \\ast.Node{
        \\    .class_member = ast.Node.ClassMember{
        \\        .flags = 0,
        \\        .node = ast.Node.Index(3),
        \\    },
        \\}
    ));
    try t.expectTokenAt(markers[0], class_decl.class.body[0]);

    const class_member = t.parser.getNode(class_decl.class.body[0]);
    try t.expectASTSnapshot(class_member.class_member.node, snap(@src(),
        \\ast.Node{
        \\    .class_field = ast.Node.ClassFieldBinding{
        \\        .name = ast.Node.Index(0),
        \\        .decl_type = ast.Node.Index(1),
        \\        .value = ast.Node.Index(2),
        \\    },
        \\}
    ));
    try t.expectTokenAt(markers[0], class_member.class_member.node);
}

test "should skip semicolons when parsing class members" {
    const text =
        \\class Foo {
        \\    a: number = 1;
        \\    ;;;
        \\}
    ;

    const t, const node, _ = try TestParser.run(text, parseClassStatement);
    defer t.deinit();

    try t.expectASTSnapshot(node, snap(@src(),
        \\ast.Node{
        \\    .class = ast.Node.ClassDeclaration{
        \\        .abstract = false,
        \\        .name = string_interner.StringId(1),
        \\        .super_class = ast.Node.Index.empty,
        \\        .implements = [_]string_interner.StringId{},
        \\        .body = [_]ast.Node.Index{
        \\            ast.Node.Index(4)
        \\        },
        \\    },
        \\}
    ));
}

test "should parse static block" {
    const text =
        \\ static {
        \\>^
        \\    a: number = 1;
        \\    b: number = 2;
        \\}
    ;

    const t, const node, const markers = try TestParser.run(text, parseClassStaticMember);
    defer t.deinit();

    try t.expectASTSnapshot(node, snap(@src(),
        \\ast.Node{
        \\    .class_static_block = [_]ast.Node.Index{
        \\        ast.Node.Index(4), 
        \\        ast.Node.Index(9)
        \\    },
        \\}
    ));
    try t.expectTokenAt(markers[0], node);
}

test "should parse static field" {
    const text =
        \\ static a: number = 1;
        \\>^
    ;

    const t, const node, const markers = try TestParser.run(text, parseClassStaticMember);
    defer t.deinit();

    try t.expectASTSnapshot(node, snap(@src(),
        \\ast.Node{
        \\    .class_member = ast.Node.ClassMember{
        \\        .flags = 1,
        \\        .node = ast.Node.Index(4),
        \\    },
        \\}
    ));
    try t.expectTokenAt(markers[0], node);
}

test "should parse class member with modifiers" {
    const tests = .{
        .{
            "abstract a;",
            snap(@src(),
                \\ast.Node{
                \\    .class_member = ast.Node.ClassMember{
                \\        .flags = 4,
                \\        .node = ast.Node.Index(1),
                \\    },
                \\}
            ),
        },
        .{
            "readonly b;",
            snap(@src(),
                \\ast.Node{
                \\    .class_member = ast.Node.ClassMember{
                \\        .flags = 2,
                \\        .node = ast.Node.Index(1),
                \\    },
                \\}
            ),
        },
        .{
            "public c;",
            snap(@src(),
                \\ast.Node{
                \\    .class_member = ast.Node.ClassMember{
                \\        .flags = 8,
                \\        .node = ast.Node.Index(1),
                \\    },
                \\}
            ),
        },
        .{
            "protected d;",
            snap(@src(),
                \\ast.Node{
                \\    .class_member = ast.Node.ClassMember{
                \\        .flags = 16,
                \\        .node = ast.Node.Index(1),
                \\    },
                \\}
            ),
        },
        .{
            "private e;",
            snap(@src(),
                \\ast.Node{
                \\    .class_member = ast.Node.ClassMember{
                \\        .flags = 32,
                \\        .node = ast.Node.Index(1),
                \\    },
                \\}
            ),
        },
    };
    const marker = "^";

    inline for (tests) |test_case| {
        const t, const node, _ = try TestParser.run(test_case[0], parseClassMember);
        defer t.deinit();

        try t.expectASTSnapshot(node, test_case[1]);
        try t.expectTokenAt(comptime Marker.fromText(marker), node);
    }
}

test "should return syntax error if class field is not closed with semicolon" {
    const text =
        \\a = 1
        \\>    ^
    ;

    const t, const nodeOrError, const markers = try TestParser.runCatch(text, parseClassField);
    defer t.deinit();

    try t.expectSyntaxErrorAt(nodeOrError, diagnostics.ARG_expected, .{";"}, markers[0]);
}

test "should parse class methods" {
    const tests = .{
        .{
            "get a() {}",
            snap(@src(),
                \\ast.Node{
                \\    .class_member = ast.Node.ClassMember{
                \\        .flags = 0,
                \\        .node = ast.Node.Index(2),
                \\    },
                \\}
            ),
        },
        .{
            "set b() {}",
            snap(@src(),
                \\ast.Node{
                \\    .class_member = ast.Node.ClassMember{
                \\        .flags = 0,
                \\        .node = ast.Node.Index(2),
                \\    },
                \\}
            ),
        },
        .{
            "c() {}",
            snap(@src(),
                \\ast.Node{
                \\    .class_member = ast.Node.ClassMember{
                \\        .flags = 0,
                \\        .node = ast.Node.Index(2),
                \\    },
                \\}
            ),
        },
        .{
            "async d() {}",
            snap(@src(),
                \\ast.Node{
                \\    .class_member = ast.Node.ClassMember{
                \\        .flags = 0,
                \\        .node = ast.Node.Index(2),
                \\    },
                \\}
            ),
        },
        .{
            "*e() {}",
            snap(@src(),
                \\ast.Node{
                \\    .class_member = ast.Node.ClassMember{
                \\        .flags = 0,
                \\        .node = ast.Node.Index(2),
                \\    },
                \\}
            ),
        },
        .{
            "async *f() {}",
            snap(@src(),
                \\ast.Node{
                \\    .class_member = ast.Node.ClassMember{
                \\        .flags = 0,
                \\        .node = ast.Node.Index(2),
                \\    },
                \\}
            ),
        },
    };

    inline for (tests) |test_case| {
        const t, const node, _ = try TestParser.run(test_case[0], parseClassMember);
        defer t.deinit();

        try t.expectASTSnapshot(node, test_case[1]);
    }
}

test "should return syntax error if there is no identifier" {
    const text =
        \\ +
        \\>^
    ;

    const t, const nodeOrError, const markers = try TestParser.runCatch(text, parseClassMember);
    defer t.deinit();

    try t.expectSyntaxErrorAt(nodeOrError, diagnostics.identifier_expected, .{}, markers[0]);
}
