const std = @import("std");
const assert = std.debug.assert;

const AST = @import("ast.zig");
const Token = @import("consts.zig").Token;
const Parser = @import("parser.zig");
const Reporter = @import("reporter.zig");
const diagnostics = @import("diagnostics.zig");
const StringId = @import("string_interner.zig").StringId;
const Symbol = @import("symbols.zig").Symbol;
const Type = @import("types.zig").Type;

const Sema = @This();

pub const SemaError = error{ SemanticError, OutOfMemory, NoSpaceLeft, UnknownNode };

parser: *Parser,
reporter: *Reporter,

gpa: std.mem.Allocator,
declarations: std.AutoHashMapUnmanaged(StringId, Symbol) = .empty,

pub fn deinit(self: *Sema) void {
    self.declarations.deinit(self.gpa);
}

pub fn report(self: *Sema, node_idx: AST.Node.Index, comptime error_msg: diagnostics.DiagnosticMessage, args: anytype) void {
    const token = self.parser.getRawNode(node_idx).main_token;
    self.reporter.put(error_msg, args, token);
}

pub fn getType(self: Sema, index: Type.Index) Type {
    return self.parser.getType(index);
}

pub fn addType(self: *Sema, kind: Type.Kind, data: Type.Data) !Type.Index {
    return try self.parser.addType(.{
        .kind = kind,
        .data = data,
    });
}

pub fn getNodeType(self: Sema, index: AST.Node.Index) Type.Index {
    return self.parser.getRawNode(index).ty;
}

pub fn setNodeType(self: *Sema, index: AST.Node.Index, ty: Type.Index) void {
    self.parser.ast.nodes.items[index.int()].ty = ty;
}

pub fn getDeclaration(self: Sema, name: StringId) ?Symbol {
    return self.declarations.get(name);
}

pub fn addDeclaration(self: *Sema, name: StringId, symbol: Symbol) void {
    self.declarations.put(self.gpa, name, symbol) catch unreachable;
}

pub fn analyze(self: *Sema, root_idx: AST.Node.Index) SemaError!void {
    const node = self.parser.getNode(root_idx);

    for (node.root) |child_node_idx| {
        try self.analyzeNode(child_node_idx);
    }
}

pub fn analyzeNode(self: *Sema, node_idx: AST.Node.Index) SemaError!void {
    if (node_idx == AST.Node.Empty) {
        return;
    }

    const node = self.parser.getNode(node_idx);

    switch (node) {
        .root => |root| {
            for (root) |child_node_idx| {
                try self.analyzeNode(child_node_idx);
            }
        },
        .declaration => |decl| {
            for (decl.list) |child_node_idx| {
                const child_node = self.parser.getNode(child_node_idx);

                try self.analyzeNode(child_node.decl_binding.decl_type);
                try self.analyzeNode(child_node.decl_binding.value);

                const binding_type = if (child_node.decl_binding.decl_type != AST.Node.Empty)
                    self.getNodeType(child_node.decl_binding.decl_type)
                else
                    self.getNodeType(child_node.decl_binding.value);

                self.setNodeType(child_node_idx, binding_type);
                self.addDeclaration(child_node.decl_binding.name, .{
                    .kind = .value,
                    .ty = binding_type,
                });
            }
        },
        .assignment => |assignment| {
            try self.analyzeNode(assignment.left);
            try self.analyzeNode(assignment.right);

            assert(self.getNodeType(assignment.left) != .none);
            assert(self.getNodeType(assignment.right) != .none);

            if (self.getNodeType(assignment.left) != self.getNodeType(assignment.right)) {
                const lty = self.getType(self.getNodeType(assignment.left));
                const rty = self.getType(self.getNodeType(assignment.right));
                self.report(node_idx, diagnostics.type_ARG_is_not_assignable_to_type_ARG, .{ lty, rty });
            }
        },
        .simple_value => |val| {
            switch (val.kind) {
                .number, .number_literal => self.setNodeType(node_idx, .number),
                .bigint, .bigint_literal => self.setNodeType(node_idx, .bigint),
                .string, .string_literal => self.setNodeType(node_idx, .string),
                .boolean, .true, .false => self.setNodeType(node_idx, .boolean),
                .regex => self.setNodeType(node_idx, .regex),
                .null => self.setNodeType(node_idx, .null),
                .undefined, .void => self.setNodeType(node_idx, .undefined),
                .unknown => self.setNodeType(node_idx, .unknown),
                .never => self.setNodeType(node_idx, .never),
                .this => self.report(node_idx, diagnostics.ARG_expected, .{"not implemented"}),
                .any => self.setNodeType(node_idx, .any),
                .private_identifier, .identifier => {
                    if (self.getDeclaration(val.id)) |decl| {
                        self.setNodeType(node_idx, decl.ty);
                    } else {
                        self.report(node_idx, diagnostics.cannot_find_name_ARG, .{self.parser.lookupStr(val.id)});
                        self.setNodeType(node_idx, .any);
                    }
                },
            }
        },
        .simple_type => |simple_type| {
            switch (simple_type.kind) {
                .number => self.setNodeType(node_idx, .number),
                .bigint => self.setNodeType(node_idx, .bigint),
                .string => self.setNodeType(node_idx, .string),
                .number_literal => {
                    const ty_idx = try self.addType(.number_literal, .{ .literal = simple_type.id });
                    self.setNodeType(node_idx, ty_idx);
                },
                .bigint_literal => {
                    const ty_idx = try self.addType(.bigint_literal, .{ .literal = simple_type.id });
                    self.setNodeType(node_idx, ty_idx);
                },
                .string_literal => {
                    const ty_idx = try self.addType(.string_literal, .{ .literal = simple_type.id });
                    self.setNodeType(node_idx, ty_idx);
                },
                .boolean => self.setNodeType(node_idx, .boolean),
                .true => self.setNodeType(node_idx, .true),
                .false => self.setNodeType(node_idx, .false),
                .regex => self.setNodeType(node_idx, .regex),
                .null => self.setNodeType(node_idx, .null),
                .undefined, .void => self.setNodeType(node_idx, .undefined),
                .unknown => self.setNodeType(node_idx, .unknown),
                .never => self.setNodeType(node_idx, .never),
                .this => self.report(node_idx, diagnostics.ARG_expected, .{"not implemented"}),
                .any => self.setNodeType(node_idx, .any),
                .private_identifier, .identifier => {
                    if (self.getDeclaration(simple_type.id)) |decl| {
                        self.setNodeType(node_idx, decl.ty);
                    } else {
                        self.report(node_idx, diagnostics.cannot_find_name_ARG, .{self.parser.lookupStr(simple_type.id)});
                        self.setNodeType(node_idx, .any);
                    }
                },
            }
        },
        else => return try self.unknownNode(node_idx),
    }
}

fn unknownNode(self: *Sema, node_idx: AST.Node.Index) SemaError!void {
    const node = self.parser.getNode(node_idx);
    std.debug.print("Unknown node {s}", .{@tagName(node)});
    return error.UnknownNode;
}

test "analyze" {
    var reporter = Reporter.init(std.testing.allocator);
    defer reporter.deinit();

    const text =
        \\const a: number = b;
        \\const x = a;
        \\const y: string;
        \\a;
    ;
    var parser = Parser.init(std.testing.allocator, text, &reporter);
    defer parser.deinit();

    var sema = Sema{
        .gpa = std.testing.allocator,
        .parser = &parser,
        .reporter = &reporter,
    };
    defer sema.deinit();

    const root_idx = try parser.parse();
    try sema.analyze(root_idx);

    reporter.print(parser.tokens.items);
}
