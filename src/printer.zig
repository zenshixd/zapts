const std = @import("std");
const builtin = @import("builtin");
const AST = @import("ast.zig");
const Token = @import("consts.zig").Token;
const newline = @import("consts.zig").newline;

const Lexer = @import("lexer.zig");
const Parser = @import("parser.zig");
const needsSemicolon = Parser.needsSemicolon;

const assert = std.debug.assert;

pub const OutputFiles = struct {
    filename: []const u8,
    buffer: []const u8,
};

const Printer = @This();

const WorkerItem = union(enum) {
    node: AST.Node.Index,
    token: Token.Index,
    text: []const u8,
    indent_up: void,
    indent_down: void,
    indent: void,

    pub fn format(self: WorkerItem, comptime _: []const u8, _: anytype, writer: anytype) !void {
        try writer.writeAll("WorkerItem{");
        switch (self) {
            .text => {
                try writer.writeAll("text: ");
                try writer.writeAll(self.text);
            },
            .token => {
                try writer.writeAll("token: ");
                try std.fmt.format(writer, "{d}", .{self.token});
            },
            .node => {
                try writer.writeAll("node: ");
                try std.fmt.format(writer, "{d}", .{self.node});
            },
            .indent => try writer.writeAll("indent"),
            .indent_up => try writer.writeAll("indent_up"),
            .indent_down => try writer.writeAll("indent_down"),
        }
        try writer.writeAll("}\n");
    }
};

const WorkerQueue = struct {
    const Self = @This();
    const WorkerQueueList = std.DoublyLinkedList(WorkerItem);

    list: WorkerQueueList = .{},
    allocator: std.mem.Allocator,

    pub fn append(self: *Self, item: WorkerItem) !void {
        self.list.append(try self.createNode(item));
    }

    pub fn prepend(self: *Self, item: WorkerItem) !void {
        self.list.prepend(try self.createNode(item));
    }

    pub fn popFirst(self: *Self) ?*WorkerQueueList.Node {
        return self.list.popFirst();
    }

    pub fn prependMany(self: *Self, other: *Self) void {
        if (other.list.len == 0) {
            return;
        }

        const current_first = self.list.first;
        self.list.first = other.list.first;
        if (self.list.last == null) {
            self.list.last = other.list.last;
        } else {
            other.list.last.?.next = current_first;
        }
        self.list.len += other.list.len;

        other.list.first = null;
        other.list.last = null;
        other.list.len = 0;
    }

    fn createNode(self: *Self, item: WorkerItem) !*WorkerQueueList.Node {
        const node = try self.allocator.create(WorkerQueueList.Node);
        node.data = item;
        node.next = null;
        node.prev = null;
        return node;
    }
};

gpa: std.mem.Allocator,
arena: std.heap.ArenaAllocator,
filename: []const u8,
buffer: [:0]const u8,
tokens: []const Token,
output: std.ArrayList(u8),
queue: WorkerQueue,
local_queue: WorkerQueue,
indent: usize = 0,

pub fn init(allocator: std.mem.Allocator, filename: []const u8, buffer: [:0]const u8, parser: *Parser) Printer {
    return .{
        .filename = filename,
        .buffer = buffer,
        .gpa = allocator,
        .arena = std.heap.ArenaAllocator.init(allocator),
        .tokens = parser.tokens,
        .pool = parser.pool,
        .output = std.ArrayList(u8).init(allocator),
        .queue = .{ .allocator = allocator },
        .local_queue = .{ .allocator = allocator },
    };
}

pub fn deinit(self: *Printer) void {
    self.arena.deinit();
    self.output.deinit();
}

pub fn print(self: *Printer) !OutputFiles {
    const root_stmts = self.pool.getNode(0);
    for (root_stmts.root) |stmt| {
        try self.queue.append(.{ .node = stmt });
        if (needsSemicolon(self.pool, stmt)) {
            try self.queue.append(.{ .text = ";" });
        }
        try self.queue.append(.{ .text = newline });
    }

    while (self.queue.popFirst()) |item| {
        try self.processWorkerItem(item.data);
    }

    return OutputFiles{
        .filename = try getOutputFile(self.gpa, self.filename),
        .buffer = self.output.items,
    };
}

fn processWorkerItem(self: *Printer, item: WorkerItem) !void {
    switch (item) {
        .text => |text| try self.output.appendSlice(text),
        .token => |token| try self.output.appendSlice(self.getTokenValue(token)),
        .node => |node| try self.printNode(node),
        .indent_up => self.indent += 1,
        .indent_down => self.indent -= 1,
        .indent => {
            for (0..self.indent) |_| {
                try self.output.appendSlice("    ");
            }
        },
    }
}

inline fn getTokenValue(self: *Printer, token: Token.Index) []const u8 {
    return self.tokens[token].literal(self.buffer);
}

inline fn queueText(self: *Printer, text: []const u8) !void {
    try self.local_queue.append(.{ .text = text });
}

inline fn queueNode(self: *Printer, node: AST.Node.Index) !void {
    try self.local_queue.append(.{ .node = node });
}

inline fn queueToken(self: *Printer, token: Token.Index) !void {
    try self.local_queue.append(.{ .token = token });
}

fn printNode(self: *Printer, node: AST.Node.Index) anyerror!void {
    const full_node = self.pool.getNode(node);
    switch (full_node) {
        .root => {
            unreachable;
        },
        .import => |import| {
            try self.queueText("import ");
            switch (import) {
                .simple => |simple| {
                    try self.queueToken(simple);
                },
                .full => |full| {
                    try self.queueNode(full.bindings[0]);
                    if (full.bindings.len > 1) {
                        try self.queueText(", ");
                        try self.queueNode(full.bindings[1]);
                    }
                    try self.queueText(" from ");
                    try self.queueToken(full.path);
                },
            }
        },
        .import_binding => |binding| {
            switch (binding) {
                .named => |named| {
                    try self.queueText("{");
                    if (named.len > 0) {
                        try self.queueToken(named[0]);
                        for (1..named.len) |i| {
                            try self.queueText(", ");
                            try self.queueToken(named[i]);
                        }
                    }
                    try self.queueText("}");
                },
                .namespace => |namespace| {
                    try self.queueText("* as ");
                    try self.queueToken(namespace);
                },
                .default => |default| {
                    try self.queueToken(default);
                },
            }
        },

        .@"export" => |export_data| {
            try self.queueText("export ");

            switch (export_data) {
                .from_all => |all| {
                    try self.queueText("*");
                    if (all.alias != Token.Empty) {
                        try self.queueText(" as ");
                        try self.queueToken(all.alias);
                    }
                    try self.queueText(" from ");
                    try self.queueToken(all.path);
                },
                .from => |from| {
                    try self.queueText("{");
                    if (from.bindings.len > 0) {
                        try self.queueToken(from.bindings[0]);
                        for (1..from.bindings.len) |i| {
                            try self.queueText(", ");
                            try self.queueToken(from.bindings[i]);
                        }
                    }
                    try self.queueText("}");

                    if (from.path != Token.Empty) {
                        try self.queueText(" from ");
                        try self.queueToken(from.path);
                    }
                },
                .named => |named| {
                    try self.queueText("{");
                    if (named.len > 0) {
                        try self.queueNode(named[0]);
                        for (1..named.len) |i| {
                            try self.queueText(", ");
                            try self.queueNode(named[i]);
                        }
                    }
                    try self.queueText("}");
                },
                .default => |default| {
                    try self.queueText("default ");
                    try self.queueNode(default);
                },
                .node => |export_node| {
                    try self.queueNode(export_node);
                },
            }
        },
        .declaration => |decl| {
            try self.local_queue.append(.{ .indent = {} });
            try self.printDecls(decl.kind.name(), decl.list);
        },
        .decl_binding => |decl| {
            try self.queueToken(decl.name);
            if (decl.value != AST.Node.Empty) {
                try self.queueText(" = ");
                try self.queueNode(decl.value);
            }
        },

        .function_decl, .function_expr => |func_decl| {
            if (func_decl.flags & AST.FunctionFlags.Async != 0) {
                try self.queueText("async ");
            }

            if (func_decl.flags & AST.FunctionFlags.Generator != 0) {
                try self.queueText("function* ");
            } else {
                try self.queueText("function ");
            }

            if (func_decl.name != Token.Empty) {
                try self.queueToken(func_decl.name);
                try self.queueText(" ");
            }
            try self.queueText("(");
            if (func_decl.params.len > 0) {
                try self.queueNode(func_decl.params[0]);
                for (1..func_decl.params.len) |i| {
                    try self.queueText(", ");
                    try self.queueNode(func_decl.params[i]);
                }
            }
            try self.queueText(") ");
            try self.queueNode(func_decl.body);
        },
        .arrow_function => |arrow_func| {
            if (arrow_func.type == .async_arrow) {
                try self.queueText("async ");
            }

            if (arrow_func.params.len == 0) {
                try self.queueText("()");
            } else if (arrow_func.params.len == 1) {
                try self.queueNode(arrow_func.params[0]);
            } else if (arrow_func.params.len > 1) {
                try self.queueText("(");
                try self.queueNode(arrow_func.params[0]);
                for (1..arrow_func.params.len) |i| {
                    try self.queueText(", ");
                    try self.queueNode(arrow_func.params[i]);
                }
                try self.queueText(")");
            }
            try self.queueText(" => ");
            try self.queueNode(arrow_func.body);
        },
        .function_param => |param| {
            try self.queueToken(param.node);
        },

        .class => |class_decl| {
            try self.queueText("class ");
            if (class_decl.name != Token.Empty) {
                try self.queueToken(class_decl.name);
                try self.queueText(" ");
            }
            if (class_decl.super_class != Token.Empty) {
                try self.queueText("extends ");
                try self.queueNode(class_decl.super_class);
                try self.queueText(" ");
            }

            try self.queueText("{" ++ newline);
            try self.local_queue.append(.{ .indent_up = {} });
            for (0..class_decl.body.len) |i| {
                const field = class_decl.body[i];
                try self.local_queue.append(.{ .indent = {} });
                try self.queueNode(field);
                if (needsSemicolon(self.pool, field)) {
                    try self.queueText(";");
                }
                try self.queueText(newline);
            }
            try self.local_queue.append(.{ .indent_down = {} });
            try self.queueText("}");
        },

        .class_static_block => |static_block| {
            try self.queueText("static {");
            if (static_block.len == 0) {
                try self.queueText("}");
                return;
            }

            try self.queueText(newline);
            try self.local_queue.append(.{ .indent_up = {} });
            for (0..static_block.len) |i| {
                try self.local_queue.append(.{ .indent = {} });
                try self.queueNode(static_block[i]);
                if (needsSemicolon(self.pool, static_block[i])) {
                    try self.queueText(";");
                }
                try self.queueText(newline);
            }
            try self.local_queue.append(.{ .indent_down = {} });
            try self.queueText("}");
        },

        .class_member => |member| {
            if (member.flags & AST.ClassMemberFlags.static != 0) {
                try self.queueText("static ");
            }
            try self.queueNode(member.node);
        },
        .class_field => |field| {
            try self.queueNode(field.name);
            if (field.value != AST.Node.Empty) {
                try self.queueText(" = ");
                try self.queueNode(field.value);
            }
        },
        .class_method, .object_method => |method| {
            if (method.flags & AST.FunctionFlags.Async != 0) {
                try self.queueText("async ");
            }
            if (method.flags & AST.FunctionFlags.Generator != 0) {
                try self.queueText("*");
            }
            if (method.flags & AST.FunctionFlags.Getter != 0) {
                try self.queueText("get ");
            } else if (method.flags & AST.FunctionFlags.Setter != 0) {
                try self.queueText("set ");
            }

            try self.queueNode(method.name);
            try self.queueText("(");
            if (method.params.len > 0) {
                try self.queueNode(method.params[0]);
                for (method.params[1..]) |param| {
                    try self.queueText(", ");
                    try self.queueNode(param);
                }
            }
            try self.queueText(") ");
            try self.queueNode(method.body);
        },

        .ternary_expr => |if_node| {
            try self.queueNode(if_node.expr);
            try self.queueText(" ? ");
            try self.queueNode(if_node.body);
            try self.queueText(" : ");
            assert(if_node.@"else" != AST.Node.Empty);
            try self.queueNode(if_node.@"else");
        },
        .@"if" => |if_node| {
            try self.queueText("if (");
            try self.queueNode(if_node.expr);
            try self.queueText(") ");
            try self.queueNode(if_node.body);
            if (if_node.@"else" != AST.Node.Empty) {
                try self.queueText(newline ++ "else ");
                try self.queueNode(if_node.@"else");
            }
        },

        .@"switch" => |switch_node| {
            try self.queueText("switch (");
            try self.queueNode(switch_node.expr);
            try self.queueText(") {");
            try self.local_queue.append(.{ .indent_up = {} });

            for (switch_node.cases) |case| {
                try self.queueText(newline);
                try self.queueNode(case);
            }

            try self.local_queue.append(.{ .indent_down = {} });
            try self.queueText("}");
        },
        .case => |case_node| {
            switch (case_node) {
                .default => |default| {
                    try self.queueText("default: {\n");
                    try self.local_queue.append(.{ .indent_up = {} });
                    for (default) |stmt| {
                        try self.printStatementNL(stmt);
                    }
                    try self.local_queue.append(.{ .indent_down = {} });
                    try self.queueText("}");
                },
                .case => |case| {
                    try self.queueText("case ");
                    try self.queueNode(case.expr);
                    try self.queueText(": {" ++ newline);
                    try self.local_queue.append(.{ .indent_up = {} });
                    for (case.body) |stmt| {
                        try self.printStatementNL(stmt);
                    }
                    try self.local_queue.append(.{ .indent_down = {} });
                    try self.queueText("}");
                },
            }
        },
        .@"break" => {
            try self.queueText("break");
        },
        .@"continue" => {
            try self.queueText("continue");
        },
        .@"for" => |for_node| {
            try self.queueText("for (");
            const body = switch (for_node) {
                .classic => |classic| blk: {
                    try self.queueNode(classic.init);
                    try self.queueText("; ");
                    try self.queueNode(classic.cond);
                    try self.queueText("; ");
                    try self.queueNode(classic.post);
                    break :blk classic.body;
                },
                .in => |in| blk: {
                    try self.queueNode(in.left);
                    try self.queueText(" in ");
                    try self.queueNode(in.right);
                    break :blk in.body;
                },
                .of => |of| blk: {
                    try self.queueNode(of.left);
                    try self.queueText(" of ");
                    try self.queueNode(of.right);
                    break :blk of.body;
                },
            };
            try self.queueText(") ");
            try self.queueNode(body);
        },

        .@"return" => |ret_node| {
            try self.queueText("return");

            if (ret_node != AST.Node.Empty) {
                try self.queueText(" ");
                try self.queueNode(ret_node);
            }
        },

        .@"while" => |while_node| {
            try self.queueText("while (");
            try self.queueNode(while_node.cond);
            try self.queueText(") ");
            try self.queueNode(while_node.body);
        },
        .do_while => |while_node| {
            try self.queueText("do ");
            try self.queueNode(while_node.body);
            if (self.pool.getNode(while_node.body) != .block) {
                try self.queueText(";");
            }
            try self.queueText(" while (");
            try self.queueNode(while_node.cond);
            try self.queueText(");");
        },

        .block => |block| {
            try self.queueText("{");
            try self.local_queue.append(.{ .indent_up = {} });
            if (block.len > 0) {
                try self.queueText(newline);
                try self.printStatementNL(block[0]);
                for (block[1..]) |stmt| {
                    try self.printStatementNL(stmt);
                }
            }
            try self.local_queue.append(.{ .indent_down = {} });
            try self.local_queue.append(.{ .indent = {} });
            try self.queueText("}");
        },

        .new_expr => |new_expr| {
            try self.queueText("new ");
            try self.queueNode(new_expr);
        },
        .call_expr => |call_expr| {
            try self.queueNode(call_expr.node);
            try self.queueText("(");
            if (call_expr.params.len > 0) {
                try self.queueNode(call_expr.params[0]);
                for (call_expr.params[1..]) |param| {
                    try self.queueText(", ");
                    try self.queueNode(param);
                }
            }
            try self.queueText(")");
        },

        .comma,
        .assignment,
        .lt,
        .gt,
        .lte,
        .gte,
        .eq,
        .eqq,
        .neq,
        .neqq,
        .@"and",
        .@"or",
        .plus_expr,
        .minus_expr,
        .multiply_expr,
        .exp_expr,
        .div_expr,
        .modulo_expr,
        .bitwise_and,
        .bitwise_or,
        .bitwise_xor,
        .bitwise_shift_left,
        .bitwise_shift_right,
        .bitwise_unsigned_right_shift,
        .plus_assign,
        .minus_assign,
        .multiply_assign,
        .modulo_assign,
        .div_assign,
        .exp_assign,
        .and_assign,
        .or_assign,
        .bitwise_and_assign,
        .bitwise_or_assign,
        .bitwise_xor_assign,
        .bitwise_shift_left_assign,
        .bitwise_shift_right_assign,
        .bitwise_unsigned_right_shift_assign,
        .instanceof,
        .in,
        .object_literal_field,
        .property_access,
        .optional_property_access,
        => |binary| {
            try self.queueNode(binary.left);
            try self.queueText(printBinaryOperator(full_node));
            try self.queueNode(binary.right);
        },

        .simple_value => |simple| {
            const token = self.pool.getRawNode(node).main_token;
            switch (simple.kind) {
                .this => try self.queueText("this"),
                .true => try self.queueText("true"),
                .false => try self.queueText("false"),
                .null => try self.queueText("null"),
                .undefined => try self.queueText("undefined"),
                .identifier => try self.queueToken(token),
                .private_identifier => {
                    try self.queueText("#");
                    try self.queueToken(token);
                },
                .number, .bigint, .string => try self.queueToken(token),
                else => unreachable,
            }
        },

        .computed_identifier => |ident| {
            try self.queueText("[");
            try self.queueNode(ident);
            try self.queueText("]");
        },

        .grouping => |grouping| {
            try self.queueText("(");
            try self.queueNode(grouping);
            try self.queueText(")");
        },
        .plusplus_pre => |unary| {
            try self.queueText("++");
            try self.queueNode(unary);
        },
        .plusplus_post => |unary| {
            try self.queueNode(unary);
            try self.queueText("++");
        },
        .minusminus_pre => |unary| {
            try self.queueText("--");
            try self.queueNode(unary);
        },
        .minusminus_post => |unary| {
            try self.queueNode(unary);
            try self.queueText("--");
        },
        .not => |unary| {
            try self.queueText("!");
            try self.queueNode(unary);
        },
        .bitwise_negate => |unary| {
            try self.queueText("~");
            try self.queueNode(unary);
        },
        .minus => |unary| {
            try self.queueText("-");
            try self.queueNode(unary);
        },
        .plus => |unary| {
            try self.queueText("+");
            try self.queueNode(unary);
        },
        .spread => |unary| {
            try self.queueText("...");
            try self.queueNode(unary);
        },
        .typeof => |unary| {
            try self.queueText("typeof ");
            try self.queueNode(unary);
        },
        .delete => |unary| {
            try self.queueText("delete ");
            try self.queueNode(unary);
        },
        .void => |unary| {
            try self.queueText("void ");
            try self.queueNode(unary);
        },
        .object_literal => |literal| {
            try self.queueText("{");
            try self.local_queue.append(.{ .indent_up = {} });
            if (literal.len > 0) {
                try self.queueText(newline);
                try self.local_queue.append(.{ .indent = {} });
                try self.queueNode(literal[0]);
                for (1..literal.len) |i| {
                    try self.queueText(",");
                    try self.queueText(newline);
                    try self.local_queue.append(.{ .indent = {} });
                    try self.queueNode(literal[i]);
                }
                try self.queueText(newline);
            }
            try self.local_queue.append(.{ .indent_down = {} });
            try self.queueText("}");
        },
        .object_literal_field_shorthand => |unary| {
            try self.queueToken(unary);
        },
        .array_literal => |literal| {
            try self.queueText("[");
            if (literal.len > 0) {
                try self.queueNode(literal[0]);
                for (1..literal.len) |i| {
                    try self.queueText(", ");
                    try self.queueNode(literal[i]);
                }
            }
            try self.queueText("]");
        },
        .index_access => |binary| {
            try self.queueNode(binary.left);
            try self.queueText("[");
            try self.queueNode(binary.right);
            try self.queueText("]");
        },

        .simple_type,
        .keyof,
        .type_decl,
        .interface_decl,
        .type_intersection,
        .type_union,
        .generic_type,
        .array_type,
        .tuple_type,
        .function_type,
        .object_type,
        .object_type_field,
        => {},
    }

    self.queue.prependMany(&self.local_queue);
}

fn printStatement(self: *Printer, node: AST.Node.Index) !void {
    try self.local_queue.append(.{ .indent = {} });
    try self.queueNode(node);
    if (needsSemicolon(self.pool, node)) {
        try self.queueText(";");
    }
}

fn printStatementNL(self: *Printer, node: AST.Node.Index) !void {
    try self.printStatement(node);
    try self.queueText(newline);
}

fn printDecls(self: *Printer, keyword: []const u8, bindings: []AST.Node.Index) !void {
    try self.queueText(keyword);
    try self.queueText(" ");
    assert(bindings.len > 0);
    try self.queueNode(bindings[0]);
    for (bindings[1..]) |binding| {
        try self.queueText(", ");
        try self.queueNode(binding);
    }
}

fn printBinaryOperator(node: AST.Node) []const u8 {
    return switch (node) {
        .comma => ",",
        .assignment => "=",
        .lt => "<",
        .gt => ">",
        .lte => "<=",
        .gte => ">=",
        .eq => "==",
        .eqq => "===",
        .neq => "!=",
        .neqq => "!==",
        .@"and" => "&&",
        .@"or" => "||",
        .plus_expr => "+",
        .minus_expr => "-",
        .multiply_expr => "*",
        .exp_expr => "**",
        .div_expr => "/",
        .modulo_expr => "%",
        .bitwise_and => "&",
        .bitwise_or => "|",
        .bitwise_xor => "^",
        .bitwise_shift_left => "<<",
        .bitwise_shift_right => ">>",
        .bitwise_unsigned_right_shift => ">>>",
        .plus_assign => "+=",
        .minus_assign => "-=",
        .multiply_assign => "*=",
        .modulo_assign => "%=",
        .div_assign => "/=",
        .exp_assign => "**=",
        .and_assign => "&=",
        .or_assign => "|=",
        .bitwise_and_assign => "&=",
        .bitwise_or_assign => "|=",
        .bitwise_xor_assign => "^=",
        .bitwise_shift_left_assign => "<<=",
        .bitwise_shift_right_assign => ">>=",
        .bitwise_unsigned_right_shift_assign => ">>>=",
        .instanceof => "instanceof",
        .in => "in",
        .object_literal_field => ":",
        .property_access => ".",
        .optional_property_access => "?.",
        else => unreachable,
    };
}

pub fn getOutputFile(allocator: std.mem.Allocator, filename: []const u8) ![]const u8 {
    if (!std.mem.endsWith(u8, filename, ".ts")) {
        return allocator.dupe(u8, filename);
    }

    const extPos = std.mem.lastIndexOf(u8, filename, ".ts") orelse return filename;
    const buffer = try allocator.alloc(
        u8,
        std.mem.replacementSize(u8, filename, ".ts", ".js"),
    );
    @memcpy(buffer.ptr, filename[0..extPos]);
    @memcpy(buffer.ptr + extPos, ".js");
    return buffer;
}

test "getOutputFile" {
    const allocator = std.testing.allocator;
    const output_filename = try getOutputFile(allocator, "test.ts");
    defer allocator.free(output_filename);

    try std.testing.expectEqualStrings("test.js", output_filename);
}
