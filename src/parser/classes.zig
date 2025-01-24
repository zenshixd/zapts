const std = @import("std");
const Parser = @import("../parser.zig");
const AST = @import("../ast.zig");
const Token = @import("../consts.zig").Token;
const TokenType = @import("../consts.zig").TokenType;
const ParserError = Parser.ParserError;
const diagnostics = @import("../diagnostics.zig");

const parseAssignment = @import("binary.zig").parseAssignment;
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

pub fn parseAbstractClassStatement(self: *Parser) ParserError!?AST.Node.Index {
    if (!self.match(TokenType.Abstract)) {
        return null;
    }

    return try parseClassStatementExtra(self, self.cur_token - 1, true) orelse return self.fail(diagnostics.declaration_or_statement_expected, .{});
}

pub fn parseClassStatement(self: *Parser) ParserError!?AST.Node.Index {
    return try parseClassStatementExtra(self, self.cur_token, false);
}

pub fn parseClassStatementExtra(self: *Parser, main_token: Token.Index, is_abstract: bool) ParserError!?AST.Node.Index {
    if (!self.match(TokenType.Class)) {
        return null;
    }

    const name = self.consumeOrNull(TokenType.Identifier) orelse AST.Node.Empty;
    var super_class: AST.Node.Index = AST.Node.Empty;
    if (self.match(TokenType.Extends)) {
        super_class = try parseCallableExpression(self) orelse return self.fail(diagnostics.identifier_expected, .{});
    }

    var implements_list: ?std.ArrayList(AST.Node.Index) = null;
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
        .implements = if (implements_list) |list| list.items else &[_]AST.Node.Index{},
        .body = body.items,
    } });
}

pub fn parseInterfaceList(self: *Parser) ParserError!std.ArrayList(AST.Node.Index) {
    var list = std.ArrayList(AST.Node.Index).init(self.gpa);
    errdefer list.deinit();

    while (true) {
        if (!self.match(TokenType.Identifier) and !try parseKeywordAsIdentifier(self)) {
            return self.fail(diagnostics.identifier_expected, .{});
        }
        try list.append(self.addNode(self.cur_token - 1, AST.Node{
            .simple_value = .{ .kind = .identifier },
        }));
        if (!self.match(TokenType.Comma)) {
            break;
        }
    }
    return list;
}

pub fn parseClassStaticMember(self: *Parser) ParserError!AST.Node.Index {
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

            return self.addNode(self.cur_token, AST.Node{
                .class_static_block = block.items,
            });
        }

        return self.addNode(self.cur_token, AST.Node{ .class_member = .{
            .flags = AST.ClassMemberFlags.static,
            .node = try parseClassMember(self),
        } });
    }
    return try parseClassMember(self);
}

pub fn parseClassMember(self: *Parser) ParserError!AST.Node.Index {
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

    return self.addNode(self.cur_token, AST.Node{
        .class_member = .{
            .flags = @intCast(flags),
            .node = node,
        },
    });
}

pub fn parseClassField(self: *Parser) ParserError!?AST.Node.Index {
    const elem_name = try parseObjectElementName(self) orelse return null;
    const decl_type = try parseOptionalDataType(self);

    var value: AST.Node.Index = AST.Node.Empty;
    if (self.match(TokenType.Equal)) {
        value = try parseAssignment(self);
    }

    _ = try self.consume(TokenType.Semicolon, diagnostics.ARG_expected, .{";"});
    return self.addNode(self.cur_token, AST.Node{ .class_field = .{
        .name = elem_name,
        .decl_type = decl_type,
        .value = value,
    } });
}

test "shoud parse class declaration" {
    const text = "class Foo {}";

    try TestParser.run(text, parseClassStatement, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectAST(node, AST.Node{ .class = .{
                .abstract = false,
                .name = 1,
                .super_class = 0,
                .implements = &[_]AST.Node.Index{},
                .body = &[_]AST.Node.Index{},
            } });
        }
    });
}

test "should return syntax error if class name is not an identifier" {
    const text = "class 123 {}";

    try TestParser.runAny(text, parseClassStatement, struct {
        pub fn expect(t: TestParser, nodeOrError: ParserError!?AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectSyntaxError(nodeOrError, diagnostics.ARG_expected, .{"{"});
        }
    });
}

test "should return syntax error if open curly brace is missing" {
    const text = "class Foo";

    try TestParser.runAny(text, parseClassStatement, struct {
        pub fn expect(t: TestParser, nodeOrError: ParserError!?AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectSyntaxError(nodeOrError, diagnostics.ARG_expected, .{"{"});
        }
    });
}

test "should parse abstract class declaration" {
    const text = "abstract class Foo {}";

    try TestParser.run(text, parseAbstractClassStatement, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectAST(node, AST.Node{ .class = .{
                .abstract = true,
                .name = 2,
                .super_class = 0,
                .implements = &[_]AST.Node.Index{},
                .body = &[_]AST.Node.Index{},
            } });
        }
    });
}

test "should return syntax error if abstract keyword is not followed by class" {
    const text = "abstract Foo {}";

    try TestParser.runAny(text, parseAbstractClassStatement, struct {
        pub fn expect(t: TestParser, node: ParserError!?AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectSyntaxError(node, diagnostics.declaration_or_statement_expected, .{});
        }
    });
}

test "should parse class declaration with extends" {
    const text = "class Foo extends Bar {}";

    try TestParser.run(text, parseClassStatement, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectAST(node, AST.Node{ .class = .{
                .abstract = false,
                .name = 1,
                .super_class = 1,
                .implements = &[_]AST.Node.Index{},
                .body = &[_]AST.Node.Index{},
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
                .name = 1,
                .super_class = 0,
                .implements = @constCast(&[_]AST.Node.Index{ 1, 2 }),
                .body = &[_]AST.Node.Index{},
            } });
        }
    });
}

test "should return syntax error if interface name is not an identifier" {
    const text = "class Foo implements 123 {}";

    try TestParser.runAny(text, parseClassStatement, struct {
        pub fn expect(t: TestParser, node: ParserError!?AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectSyntaxError(node, diagnostics.identifier_expected, .{});
        }
    });
}

test "should parse class declaration without name" {
    const text = "class extends Bar implements Baz {}";

    try TestParser.run(text, parseClassStatement, struct {
        pub fn expect(t: TestParser, node: ?AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectAST(node, AST.Node{ .class = .{
                .abstract = false,
                .name = 0,
                .super_class = 1,
                .implements = @constCast(&[_]AST.Node.Index{2}),
                .body = &[_]AST.Node.Index{},
            } });
        }
    });
}

test "should parse class members" {
    const text =
        \\class Foo {
        \\    a: number = 1;
        \\}
    ;

    try TestParser.run(text, parseClassStatement, struct {
        pub fn expect(t: TestParser, _: ?AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectNodesToEqual(&[_]AST.Raw{
                AST.Raw{ .tag = .simple_value, .main_token = 3, .data = .{ .lhs = 1, .rhs = 0 } },
                AST.Raw{ .tag = .simple_value, .main_token = 3, .data = .{ .lhs = 1, .rhs = 0 } },
                AST.Raw{ .tag = .simple_type, .main_token = 5, .data = .{ .lhs = 3, .rhs = 0 } },
                AST.Raw{ .tag = .simple_value, .main_token = 7, .data = .{ .lhs = 3, .rhs = 0 } },
                AST.Raw{ .tag = .class_field, .main_token = 9, .data = .{ .lhs = 2, .rhs = 0 } },
                AST.Raw{ .tag = .class_member, .main_token = 9, .data = .{ .lhs = 0, .rhs = 5 } },
                AST.Raw{ .tag = .class_decl, .main_token = 0, .data = .{ .lhs = 1, .rhs = 3 } },
            });
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
        pub fn expect(t: TestParser, _: ?AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectNodesToEqual(&[_]AST.Raw{
                AST.Raw{ .tag = .simple_value, .main_token = 3, .data = .{ .lhs = 1, .rhs = 0 } },
                AST.Raw{ .tag = .simple_value, .main_token = 3, .data = .{ .lhs = 1, .rhs = 0 } },
                AST.Raw{ .tag = .simple_type, .main_token = 5, .data = .{ .lhs = 3, .rhs = 0 } },
                AST.Raw{ .tag = .simple_value, .main_token = 7, .data = .{ .lhs = 3, .rhs = 0 } },
                AST.Raw{ .tag = .class_field, .main_token = 9, .data = .{ .lhs = 2, .rhs = 0 } },
                AST.Raw{ .tag = .class_member, .main_token = 9, .data = .{ .lhs = 0, .rhs = 5 } },
                AST.Raw{ .tag = .class_decl, .main_token = 0, .data = .{ .lhs = 1, .rhs = 3 } },
            });
        }
    });
}

test "should parse static block" {
    const text =
        \\static {
        \\    a: number = 1;
        \\    b: number = 2;
        \\}
    ;

    try TestParser.run(text, parseClassStaticMember, struct {
        pub fn expect(t: TestParser, node: AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectAST(node, AST.Node{ .class_static_block = @constCast(&[_]AST.Node.Index{ 6, 12 }) });
        }
    });
}

test "should parse static field" {
    const text = "static a: number = 1;";

    try TestParser.run(text, parseClassStaticMember, struct {
        pub fn expect(t: TestParser, node: AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectAST(node, AST.Node{
                .class_member = .{
                    .flags = AST.ClassMemberFlags.static,
                    .node = 6,
                },
            });
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

    inline for (tests) |test_case| {
        try TestParser.run(test_case[0], parseClassMember, struct {
            pub fn expect(t: TestParser, node: AST.Node.Index, _: MarkerList(test_case[0])) !void {
                try t.expectAST(node, AST.Node{
                    .class_member = .{ .flags = test_case[1], .node = 3 },
                });
            }
        });
    }
}

test "should return syntax error if class field is not closed with semicolon" {
    const text = "a = 1";

    try TestParser.runAny(text, parseClassField, struct {
        pub fn expect(t: TestParser, nodeOrError: ParserError!?AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectSyntaxError(nodeOrError, diagnostics.ARG_expected, .{";"});
        }
    });
}

test "should parse class methods" {
    const tests = .{
        .{ "get a() {}", AST.Node{ .class_member = .{ .flags = 0, .node = 3 } } },
        .{ "set b() {}", AST.Node{ .class_member = .{ .flags = 0, .node = 3 } } },
        .{ "c() {}", AST.Node{ .class_member = .{ .flags = 0, .node = 3 } } },
        .{ "async d() {}", AST.Node{ .class_member = .{ .flags = 0, .node = 3 } } },
        .{ "*e() {}", AST.Node{ .class_member = .{ .flags = 0, .node = 3 } } },
        .{ "async *f() {}", AST.Node{ .class_member = .{ .flags = 0, .node = 3 } } },
    };

    inline for (tests) |test_case| {
        try TestParser.run(test_case[0], parseClassMember, struct {
            pub fn expect(t: TestParser, node: AST.Node.Index, _: MarkerList(test_case[0])) !void {
                try t.expectAST(node, test_case[1]);
            }
        });
    }
}

test "should return syntax error if there is no identifier" {
    const text = "+";

    try TestParser.runAny(text, parseClassMember, struct {
        pub fn expect(t: TestParser, node: ParserError!AST.Node.Index, _: MarkerList(text)) !void {
            try t.expectSyntaxError(node, diagnostics.identifier_expected, .{});
        }
    });
}
