const std = @import("std");
const Parser = @import("../parser.zig");
const AST = @import("../ast.zig");
const Token = @import("../consts.zig").Token;
const TokenType = @import("../consts.zig").TokenType;
const CompilationError = @import("../consts.zig").CompilationError;
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

const TestParser = @import("../test_parser.zig");
const MarkerList = @import("../test_parser.zig").MarkerList;
const Marker = @import("../test_parser.zig").Marker;

const expectEqualDeep = std.testing.expectEqualDeep;

pub fn parseAbstractClassStatement(self: *Parser) CompilationError!?AST.Node.Index {
    if (!self.match(TokenType.Abstract)) {
        return null;
    }

    return try parseClassStatementExtra(self, self.cur_token.dec(1), true) orelse return self.fail(diagnostics.declaration_or_statement_expected, .{});
}

pub fn parseClassStatement(self: *Parser) CompilationError!?AST.Node.Index {
    return try parseClassStatementExtra(self, self.cur_token, false);
}

pub fn parseClassStatementExtra(self: *Parser, main_token: Token.Index, is_abstract: bool) CompilationError!?AST.Node.Index {
    if (!self.match(TokenType.Class)) {
        return null;
    }

    const name = self.consumeOrNull(TokenType.Identifier) orelse Token.Empty;
    var super_class: AST.Node.Index = AST.Node.Empty;
    if (self.match(TokenType.Extends)) {
        super_class = try parseCallableExpression(self) orelse return self.fail(diagnostics.identifier_expected, .{});
    }

    var implements_list: ?std.ArrayList(Token.Index) = null;
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
        .implements = if (implements_list) |list| list.items else &[_]Token.Index{},
        .body = body.items,
    } });
}

pub fn parseInterfaceList(self: *Parser) CompilationError!std.ArrayList(Token.Index) {
    var list = std.ArrayList(Token.Index).init(self.gpa);
    errdefer list.deinit();

    while (true) {
        const identifier = self.consumeOrNull(TokenType.Identifier) orelse
            parseKeywordAsIdentifier(self) orelse
            return self.fail(diagnostics.identifier_expected, .{});

        try list.append(identifier);
        if (!self.match(TokenType.Comma)) {
            break;
        }
    }
    return list;
}

pub fn parseClassStaticMember(self: *Parser) CompilationError!AST.Node.Index {
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

pub fn parseClassMember(self: *Parser) CompilationError!AST.Node.Index {
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

pub fn parseClassField(self: *Parser) CompilationError!?AST.Node.Index {
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

    try TestParser.run(text, parseClassStatement, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, comptime markers: MarkerList(text)) !void {
            try t.expectAST(node, AST.Node{ .class = .{
                .abstract = false,
                .name = Token.at(1),
                .super_class = AST.Node.Empty,
                .implements = &[_]Token.Index{},
                .body = &.{},
            } });
            try t.expectTokenAt(markers[0], node.?);
        }
    });
}

test "should return syntax error if class name is not an identifier" {
    const text =
        \\ class 123 {}
        \\>      ^
    ;

    try TestParser.runAny(text, parseClassStatement, struct {
        pub fn expect(t: TestParser, nodeOrError: CompilationError!?AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectSyntaxError(nodeOrError, diagnostics.ARG_expected, .{"{"});
        }
    });
}

test "should return syntax error if open curly brace is missing" {
    const text =
        \\class Foo
        \\>        ^
    ;

    try TestParser.runAny(text, parseClassStatement, struct {
        pub fn expect(t: TestParser, nodeOrError: CompilationError!?AST.Node.Index, comptime markers: MarkerList(text)) !void {
            try t.expectSyntaxErrorAt(nodeOrError, diagnostics.ARG_expected, .{"{"}, markers[0]);
        }
    });
}

test "should parse abstract class declaration" {
    const text =
        \\ abstract class Foo {}
        \\>^
    ;

    try TestParser.run(text, parseAbstractClassStatement, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, comptime markers: MarkerList(text)) !void {
            try t.expectAST(node, AST.Node{ .class = .{
                .abstract = true,
                .name = Token.at(2),
                .super_class = AST.Node.Empty,
                .implements = &[_]Token.Index{},
                .body = &.{},
            } });
            try t.expectTokenAt(markers[0], node.?);
        }
    });
}

test "should return syntax error if abstract keyword is not followed by class" {
    const text =
        \\ abstract Foo {}
        \\>         ^
    ;

    try TestParser.runAny(text, parseAbstractClassStatement, struct {
        pub fn expect(t: TestParser, node: CompilationError!?AST.Node.Index, comptime markers: MarkerList(text)) !void {
            try t.expectSyntaxErrorAt(node, diagnostics.declaration_or_statement_expected, .{}, markers[0]);
        }
    });
}

test "should parse class declaration with extends" {
    const text = "class Foo extends Bar {}";

    try TestParser.run(text, parseClassStatement, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectAST(node, AST.Node{ .class = .{
                .abstract = false,
                .name = Token.at(1),
                .super_class = AST.Node.at(1),
                .implements = &[_]Token.Index{},
                .body = &.{},
            } });
        }
    });
}

test "should parse class declaration with implements" {
    const text = "class Foo implements Bar, Baz {}";

    try TestParser.run(text, parseClassStatement, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectAST(node, AST.Node{ .class = .{
                .abstract = false,
                .name = Token.at(1),
                .super_class = AST.Node.Empty,
                .implements = @constCast(&[_]Token.Index{ Token.at(3), Token.at(5) }),
                .body = &.{},
            } });
        }
    });
}

test "should return syntax error if interface name is not an identifier" {
    const text =
        \\class Foo implements 123 {}
        \\>                    ^
    ;

    try TestParser.runAny(text, parseClassStatement, struct {
        pub fn expect(t: TestParser, node: CompilationError!?AST.Node.Index, comptime markers: MarkerList(text)) !void {
            try t.expectSyntaxErrorAt(node, diagnostics.identifier_expected, .{}, markers[0]);
        }
    });
}

test "should parse class declaration without name" {
    const text = "class extends Bar implements Baz {}";

    try TestParser.run(text, parseClassStatement, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectAST(node, AST.Node{ .class = .{
                .abstract = false,
                .name = Token.Empty,
                .super_class = AST.Node.at(1),
                .implements = @constCast(&[_]Token.Index{Token.at(4)}),
                .body = &.{},
            } });
        }
    });
}

test "should parse class members" {
    const text =
        \\class Foo {
        \\    a: number = 1;
        \\>   ^
        \\}
    ;

    try TestParser.run(text, parseClassStatement, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, comptime markers: MarkerList(text)) !void {
            const class_decl = AST.Node{ .class = AST.Node.ClassDeclaration{
                .name = Token.at(1),
                .abstract = false,
                .implements = &.{},
                .super_class = AST.Node.Empty,
                .body = @constCast(&[_]AST.Node.Index{
                    AST.Node.at(6),
                }),
            } };
            try t.expectAST(node, class_decl);

            const class_member = AST.Node{ .class_member = AST.Node.ClassMember{
                .flags = 0,
                .node = AST.Node.at(5),
            } };
            try t.expectAST(class_decl.class.body[0], class_member);
            try t.expectTokenAt(markers[0], class_decl.class.body[0]);

            const class_field = AST.Node{ .class_field = AST.Node.ClassFieldBinding{
                .name = AST.Node.at(2),
                .decl_type = AST.Node.at(3),
                .value = AST.Node.at(4),
            } };
            try t.expectAST(class_member.class_member.node, class_field);
            try t.expectTokenAt(markers[0], class_member.class_member.node);
        }
    });
}

test "should skip semicolons when parsing class members" {
    const text =
        \\class Foo {
        \\    a: number = 1;
        \\    ;;;
        \\}
    ;

    try TestParser.run(text, parseClassStatement, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectAST(node, AST.Node{ .class = AST.Node.ClassDeclaration{
                .name = Token.at(1),
                .abstract = false,
                .implements = &.{},
                .super_class = AST.Node.Empty,
                .body = @constCast(&[_]AST.Node.Index{AST.Node.at(6)}),
            } });
        }
    });
}

test "should parse static block" {
    const text =
        \\ static {
        \\>^
        \\    a: number = 1;
        \\    b: number = 2;
        \\}
    ;

    try TestParser.run(text, parseClassStaticMember, struct {
        pub fn expect(t: TestParser, node: AST.Node.Index, comptime markers: MarkerList(text)) !void {
            try t.expectAST(node, AST.Node{
                .class_static_block = @constCast(&[_]AST.Node.Index{ AST.Node.at(6), AST.Node.at(12) }),
            });
            try t.expectTokenAt(markers[0], node);
        }
    });
}

test "should parse static field" {
    const text =
        \\ static a: number = 1;
        \\>^
    ;

    try TestParser.run(text, parseClassStaticMember, struct {
        pub fn expect(t: TestParser, node: AST.Node.Index, comptime markers: MarkerList(text)) !void {
            try t.expectAST(node, AST.Node{
                .class_member = .{
                    .flags = AST.ClassMemberFlags.static,
                    .node = AST.Node.at(6),
                },
            });
            try t.expectTokenAt(markers[0], node);
        }
    });
}

test "should parse class member with modifiers" {
    const tests = .{
        .{ "abstract a;", AST.ClassMemberFlags.abstract },
        .{ "readonly b;", AST.ClassMemberFlags.readonly },
        .{ "public c;", AST.ClassMemberFlags.public },
        .{ "protected d;", AST.ClassMemberFlags.protected },
        .{ "private e;", AST.ClassMemberFlags.private },
    };
    const marker = "^";

    inline for (tests) |test_case| {
        try TestParser.run(test_case[0], parseClassMember, struct {
            pub fn expect(t: TestParser, node: AST.Node.Index, _: MarkerList(test_case[0])) !void {
                try t.expectAST(node, AST.Node{
                    .class_member = .{ .flags = test_case[1], .node = AST.Node.at(3) },
                });
                try t.expectTokenAt(comptime Marker.fromText(marker), node);
            }
        });
    }
}

test "should return syntax error if class field is not closed with semicolon" {
    const text =
        \\a = 1
        \\>    ^
    ;

    try TestParser.runAny(text, parseClassField, struct {
        pub fn expect(t: TestParser, nodeOrError: CompilationError!?AST.Node.Index, comptime markers: MarkerList(text)) !void {
            try t.expectSyntaxErrorAt(nodeOrError, diagnostics.ARG_expected, .{";"}, markers[0]);
        }
    });
}

test "should parse class methods" {
    const tests = .{
        .{ "get a() {}", AST.Node{ .class_member = .{ .flags = 0, .node = AST.Node.at(3) } } },
        .{ "set b() {}", AST.Node{ .class_member = .{ .flags = 0, .node = AST.Node.at(3) } } },
        .{ "c() {}", AST.Node{ .class_member = .{ .flags = 0, .node = AST.Node.at(3) } } },
        .{ "async d() {}", AST.Node{ .class_member = .{ .flags = 0, .node = AST.Node.at(3) } } },
        .{ "*e() {}", AST.Node{ .class_member = .{ .flags = 0, .node = AST.Node.at(3) } } },
        .{ "async *f() {}", AST.Node{ .class_member = .{ .flags = 0, .node = AST.Node.at(3) } } },
    };

    inline for (tests) |test_case| {
        try TestParser.run(test_case[0], parseClassMember, struct {
            pub fn expect(t: TestParser, node: AST.Node.Index, _: anytype) !void {
                try t.expectAST(node, test_case[1]);
            }
        });
    }
}

test "should return syntax error if there is no identifier" {
    const text =
        \\ +
        \\>^
    ;

    try TestParser.runAny(text, parseClassMember, struct {
        pub fn expect(t: TestParser, node: CompilationError!AST.Node.Index, comptime markers: MarkerList(text)) !void {
            try t.expectSyntaxErrorAt(node, diagnostics.identifier_expected, .{}, markers[0]);
        }
    });
}
