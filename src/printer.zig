const std = @import("std");
const builtin = @import("builtin");
const ASTNode = @import("ast.zig").ASTNode;
const ASTNodeTag = @import("ast.zig").ASTNodeTag;
const needsSemicolon = @import("parser.zig").needsSemicolon;

const new_line_char = if (builtin.target.os.tag == .windows) "\r\n" else "\n";

pub fn print(allocator: std.mem.Allocator, statements: []ASTNode) ![]const u8 {
    var output = try std.ArrayList(u8).initCapacity(allocator, 1024);
    defer output.deinit();
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();

    for (statements) |statement| {
        try printNode(arena.allocator(), output.writer(), &statement);
        if (needsSemicolon(statement)) {
            try output.appendSlice(";");
        }
        try output.appendSlice(new_line_char);
    }

    return output.toOwnedSlice();
}

const WorkerItem = union(enum) {
    node: *const ASTNode,
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
            .node => {
                try writer.writeAll("node: ");
                try self.node.format("", .{}, writer);
            },
            .indent_up => {
                try writer.writeAll("indent_up");
            },
            .indent_down => {
                try writer.writeAll("indent_down");
            },
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

fn printNode(allocator: std.mem.Allocator, writer: anytype, first_node: *const ASTNode) anyerror!void {
    var queue = WorkerQueue{
        .allocator = allocator,
    };
    try queue.prepend(.{ .node = first_node });
    var indent: usize = 0;

    while (queue.popFirst()) |item| {
        if (item.data == .text) {
            try writer.writeAll(item.data.text);
            continue;
        } else if (item.data == .indent_up) {
            indent += 1;
            continue;
        } else if (item.data == .indent_down) {
            indent -= 1;
            continue;
        } else if (item.data == .indent) {
            for (0..indent) |_| {
                try writer.writeAll("    ");
            }
            continue;
        }

        var local_queue = WorkerQueue{
            .allocator = allocator,
        };
        const node = item.data.node;
        switch (node.tag) {
            .import => {
                try writer.writeAll("import ");
                switch (node.data.import.*) {
                    .simple => |simple| {
                        try local_queue.append(.{ .text = simple });
                    },
                    .full => |full| {
                        try printImportBinding(&local_queue, full.bindings[0]);
                        if (full.bindings.len > 1) {
                            try local_queue.append(.{ .text = ", " });
                            try printImportBinding(&local_queue, full.bindings[1]);
                        }
                        try local_queue.append(.{ .text = " from " });
                        try local_queue.append(.{ .text = full.path });
                    },
                    else => {},
                }
            },
            .@"export" => {
                try writer.writeAll("export ");

                switch (node.data.@"export".*) {
                    .default => |default| {
                        try local_queue.append(.{ .text = "default " });
                        try local_queue.append(.{ .node = &default });
                    },
                    .node => |export_node| {
                        try local_queue.append(.{ .node = &export_node });
                    },
                    .all => |all| {
                        try local_queue.append(.{ .text = "*" });
                        if (all.alias) |alias| {
                            try local_queue.append(.{ .text = " as " });
                            try local_queue.append(.{ .text = alias });
                        }
                        try local_queue.append(.{ .text = " from " });
                        try local_queue.append(.{ .text = all.path });
                    },
                    .from => |from| {
                        try local_queue.append(.{ .text = "{" });
                        if (from.bindings.len > 0) {
                            try local_queue.append(.{ .text = from.bindings[0].name });
                            for (1..from.bindings.len) |i| {
                                try local_queue.append(.{ .text = ", " });
                                try local_queue.append(.{ .text = from.bindings[i].name });
                            }
                        }
                        try local_queue.append(.{ .text = "}" });

                        if (from.path) |path| {
                            try local_queue.append(.{ .text = " from " });
                            try local_queue.append(.{ .text = path });
                        }
                    },
                }
            },
            .var_decl => {
                try local_queue.append(.{ .indent = {} });
                try printDecls("var ", &local_queue, node);
            },
            .const_decl => {
                try local_queue.append(.{ .indent = {} });
                try printDecls("const ", &local_queue, node);
            },
            .let_decl => {
                try local_queue.append(.{ .indent = {} });
                try printDecls("let ", &local_queue, node);
            },
            .async_func_decl, .func_decl, .async_generator_func_decl, .generator_func_decl => {
                switch (node.tag) {
                    .async_func_decl => {
                        try local_queue.append(.{ .text = "async function " });
                    },
                    .async_generator_func_decl => {
                        try local_queue.append(.{ .text = "async function* " });
                    },
                    .generator_func_decl => {
                        try local_queue.append(.{ .text = "function* " });
                    },
                    .func_decl => {
                        try local_queue.append(.{ .text = "function " });
                    },
                    else => unreachable,
                }
                if (node.data.function.name) |name| {
                    try local_queue.append(.{ .node = &name });
                    try local_queue.append(.{ .text = " " });
                }
                try local_queue.append(.{ .text = "(" });
                if (node.data.function.params.len > 0) {
                    try local_queue.append(.{ .node = &node.data.function.params[0] });
                    for (1..node.data.function.params.len) |i| {
                        try local_queue.append(.{ .text = ", " });
                        try local_queue.append(.{ .node = &node.data.function.params[i] });
                    }
                }
                try local_queue.append(.{ .text = ") " });
                try local_queue.append(.{ .node = &node.data.function.body });
            },
            .arrow_function, .async_arrow_function => {
                if (node.tag == .async_arrow_function) {
                    try writer.writeAll("async ");
                }

                if (node.data.function.params.len == 1) {
                    try local_queue.append(.{ .node = &node.data.function.params[0] });
                } else if (node.data.function.params.len > 1) {
                    try local_queue.append(.{ .text = "(" });
                    try local_queue.append(.{ .node = &node.data.function.params[0] });
                    for (1..node.data.function.params.len) |i| {
                        try local_queue.append(.{ .text = ", " });
                        try local_queue.append(.{ .node = &node.data.function.params[i] });
                    }
                    try local_queue.append(.{ .text = ")" });
                }
                try local_queue.append(.{ .text = " => " });
                try local_queue.append(.{ .node = &node.data.function.body });
            },
            .abstract_class_decl, .class_decl => {
                try local_queue.append(.{ .text = "class " });
                if (node.data.class.name) |name| {
                    try local_queue.append(.{ .text = name });
                    try local_queue.append(.{ .text = " " });
                }
                if (node.data.class.super_class) |super_class| {
                    try local_queue.append(.{ .text = "extends " });
                    try local_queue.append(.{ .node = &super_class });
                    try local_queue.append(.{ .text = " " });
                }

                try local_queue.append(.{ .text = "{" ++ new_line_char });
                try local_queue.append(.{ .indent_up = {} });
                for (0..node.data.class.body.len) |i| {
                    try local_queue.append(.{ .indent = {} });
                    if (node.data.class.body[i].flags.contains(.static)) {
                        try local_queue.append(.{ .text = "static " });
                    }
                    try local_queue.append(.{ .node = &node.data.class.body[i].node });
                    if (needsSemicolon(node.data.class.body[i].node)) {
                        try local_queue.append(.{ .text = ";" });
                    }
                    try local_queue.append(.{ .text = new_line_char });
                }
                try local_queue.append(.{ .indent_down = {} });
                try local_queue.append(.{ .text = "}" });
            },
            .ternary => {
                try local_queue.append(.{ .node = &node.data.binary.left });
                try local_queue.append(.{ .text = " ? " });
                try local_queue.append(.{ .node = &node.data.binary.right });
            },
            .ternary_then => {
                try local_queue.append(.{ .node = &node.data.binary.left });
                try local_queue.append(.{ .text = " : " });
                try local_queue.append(.{ .node = &node.data.binary.right });
            },
            .@"if" => {
                try writer.writeAll("if (");
                try local_queue.append(.{ .node = &node.data.binary.left });
                try local_queue.append(.{ .text = ")" });
                const right = node.data.binary.right;
                if (right.tag == .block) {
                    try local_queue.append(.{ .text = " " });
                    try local_queue.append(.{ .node = &right });
                } else {
                    try local_queue.append(.{ .text = new_line_char });
                    try local_queue.append(.{ .indent_up = {} });
                    try printStatement(&local_queue, &right);
                    try local_queue.append(.{ .indent_down = {} });
                }
            },
            .@"else" => {
                const ifNode = node.data.binary.left;
                if (ifNode.data.binary.right.tag == .block) {
                    try local_queue.append(.{ .node = &ifNode });
                    try local_queue.append(.{ .text = " else" });
                } else {
                    try local_queue.append(.{ .node = &ifNode });
                    try local_queue.append(.{ .text = new_line_char });
                    try local_queue.append(.{ .text = "else" });
                }

                const right = node.data.binary.right;
                if (right.tag == .block or right.tag == .@"if" or right.tag == .@"else") {
                    try local_queue.append(.{ .text = " " });
                    try local_queue.append(.{ .node = &right });
                } else {
                    try local_queue.append(.{ .text = new_line_char });
                    try local_queue.append(.{ .indent_up = {} });
                    try printStatement(&local_queue, &right);
                    try local_queue.append(.{ .indent_down = {} });
                }
            },
            .@"switch" => {
                try writer.writeAll("switch (");
                try local_queue.append(.{ .node = &node.data.binary.left });
                try local_queue.append(.{ .text = ") " });
                try local_queue.append(.{ .node = &node.data.binary.right });
            },
            .case => {
                try writer.writeAll("case ");
                try local_queue.append(.{ .node = &node.data.nodes[0] });
                try local_queue.append(.{ .text = ":" ++ new_line_char });

                try local_queue.append(.{ .indent_up = {} });
                for (1..node.data.nodes.len) |i| {
                    try printStatement(&local_queue, &node.data.nodes[i]);
                    try local_queue.append(.{ .text = new_line_char });
                }
                try local_queue.append(.{ .indent_down = {} });
            },
            .default => {
                try writer.writeAll("default: ");
                try local_queue.append(.{ .indent_up = {} });
                for (node.data.nodes) |stmt| {
                    try printStatement(&local_queue, &stmt);
                    try local_queue.append(.{ .text = new_line_char });
                }
                try local_queue.append(.{ .indent_down = {} });
            },
            .@"break" => {
                try writer.writeAll("break");
            },
            .@"continue" => {
                try writer.writeAll("continue");
            },
            .@"for" => {
                try writer.writeAll("for (");
                try local_queue.append(.{ .node = &node.data.binary.left });
                try local_queue.append(.{ .text = ") " });
                try local_queue.append(.{ .node = &node.data.binary.right });
            },
            .for_classic => {
                try local_queue.append(.{ .node = &node.data.nodes[0] });
                try local_queue.append(.{ .text = "; " });
                try local_queue.append(.{ .node = &node.data.nodes[1] });
                try local_queue.append(.{ .text = "; " });
                try local_queue.append(.{ .node = &node.data.nodes[2] });
            },
            .for_in => {
                try local_queue.append(.{ .node = &node.data.binary.left });
                try local_queue.append(.{ .text = " in " });
                try local_queue.append(.{ .node = &node.data.binary.right });
            },
            .for_of => {
                try local_queue.append(.{ .node = &node.data.binary.left });
                try local_queue.append(.{ .text = " of " });
                try local_queue.append(.{ .node = &node.data.binary.right });
            },
            .@"return" => {
                try writer.writeAll("return");
                if (node.data == .node) {
                    try local_queue.append(.{ .text = " " });
                    try local_queue.append(.{ .node = node.data.node });
                }
            },
            .@"while" => {
                try writer.writeAll("while (");
                try local_queue.append(.{ .node = &node.data.binary.left });
                try local_queue.append(.{ .text = ") " });
                try local_queue.append(.{ .node = &node.data.binary.right });
            },
            .do_while => {
                try writer.writeAll("do ");
                try local_queue.append(.{ .node = &node.data.binary.right });
                if (node.data.binary.right.tag != .block) {
                    try local_queue.append(.{ .text = ";" });
                }
                try local_queue.append(.{ .text = " while (" });
                try local_queue.append(.{ .node = &node.data.binary.left });
                try local_queue.append(.{ .text = ");" });
            },
            .block => {
                try writer.writeAll("{");
                try local_queue.append(.{ .indent_up = {} });
                if (node.data.nodes.len > 0) {
                    try writer.writeAll(new_line_char);
                    try printStatementNL(&local_queue, &node.data.nodes[0]);
                    for (1..node.data.nodes.len) |i| {
                        try printStatementNL(&local_queue, &node.data.nodes[i]);
                    }
                }
                try local_queue.append(.{ .indent_down = {} });
                try local_queue.append(.{ .indent = {} });
                try local_queue.append(.{ .text = "}" });
            },
            .new_expr => {
                try local_queue.append(.{ .text = "new " });
                try local_queue.append(.{ .node = node.data.node });
            },
            .call_expr => {
                try local_queue.append(.{ .node = &node.data.nodes[0] });
                try local_queue.append(.{ .text = "(" });
                if (node.data.nodes.len > 1) {
                    try local_queue.append(.{ .node = &node.data.nodes[1] });
                    for (2..node.data.nodes.len) |i| {
                        try local_queue.append(.{ .text = ", " });
                        try local_queue.append(.{ .node = &node.data.nodes[i] });
                    }
                }
                try local_queue.append(.{ .text = ")" });
            },
            .comma => {
                try local_queue.append(.{ .node = &node.data.binary.left });
                try local_queue.append(.{ .text = ", " });
                try local_queue.append(.{ .node = &node.data.binary.right });
            },
            .this => {
                try writer.writeAll("this");
            },
            .true => {
                try writer.writeAll("true");
            },
            .false => {
                try writer.writeAll("false");
            },
            .null => {
                try writer.writeAll("null");
            },
            .undefined => {
                try writer.writeAll("undefined");
            },
            .number, .bigint, .identifier, .string => {
                try writer.writeAll(node.data.literal);
            },
            .computed_identifier => {
                try local_queue.append(.{ .text = "[" });
                try local_queue.append(.{ .node = node.data.node });
                try local_queue.append(.{ .text = "]" });
            },
            .private_identifier => {
                try writer.writeAll("#");
                try writer.writeAll(node.data.literal);
            },
            .none, .unknown => {},
            .grouping => {
                try writer.writeAll("(");
                try local_queue.append(.{ .node = node.data.node });
                try local_queue.append(.{ .text = ")" });
            },
            .assignment => {
                try local_queue.append(.{ .node = &node.data.binary.left });
                try local_queue.append(.{ .text = " = " });
                try local_queue.append(.{ .node = &node.data.binary.right });
            },
            .plus_assign => {
                try local_queue.append(.{ .node = &node.data.binary.left });
                try local_queue.append(.{ .text = " += " });
                try local_queue.append(.{ .node = &node.data.binary.right });
            },
            .minus_assign => {
                try local_queue.append(.{ .node = &node.data.binary.left });
                try local_queue.append(.{ .text = " -= " });
                try local_queue.append(.{ .node = &node.data.binary.right });
            },
            .multiply_assign => {
                try local_queue.append(.{ .node = &node.data.binary.left });
                try local_queue.append(.{ .text = " *= " });
                try local_queue.append(.{ .node = &node.data.binary.right });
            },
            .div_assign => {
                try local_queue.append(.{ .node = &node.data.binary.left });
                try local_queue.append(.{ .text = " /= " });
                try local_queue.append(.{ .node = &node.data.binary.right });
            },
            .modulo_assign => {
                try local_queue.append(.{ .node = &node.data.binary.left });
                try local_queue.append(.{ .text = " %= " });
                try local_queue.append(.{ .node = &node.data.binary.right });
            },
            .exp_assign => {
                try local_queue.append(.{ .node = &node.data.binary.left });
                try local_queue.append(.{ .text = " **= " });
                try local_queue.append(.{ .node = &node.data.binary.right });
            },
            .and_assign => {
                try local_queue.append(.{ .node = &node.data.binary.left });
                try local_queue.append(.{ .text = " &= " });
                try local_queue.append(.{ .node = &node.data.binary.right });
            },
            .or_assign => {
                try local_queue.append(.{ .node = &node.data.binary.left });
                try local_queue.append(.{ .text = " |= " });
                try local_queue.append(.{ .node = &node.data.binary.right });
            },
            .bitwise_and_assign => {
                try local_queue.append(.{ .node = &node.data.binary.left });
                try local_queue.append(.{ .text = " &= " });
                try local_queue.append(.{ .node = &node.data.binary.right });
            },
            .bitwise_or_assign => {
                try local_queue.append(.{ .node = &node.data.binary.left });
                try local_queue.append(.{ .text = " |= " });
                try local_queue.append(.{ .node = &node.data.binary.right });
            },
            .bitwise_xor_assign => {
                try local_queue.append(.{ .node = &node.data.binary.left });
                try local_queue.append(.{ .text = " ^= " });
                try local_queue.append(.{ .node = &node.data.binary.right });
            },
            .bitwise_shift_left_assign => {
                try local_queue.append(.{ .node = &node.data.binary.left });
                try local_queue.append(.{ .text = " <<= " });
                try local_queue.append(.{ .node = &node.data.binary.right });
            },
            .bitwise_shift_right_assign => {
                try local_queue.append(.{ .node = &node.data.binary.left });
                try local_queue.append(.{ .text = " >>= " });
                try local_queue.append(.{ .node = &node.data.binary.right });
            },
            .bitwise_unsigned_right_shift_assign => {
                try local_queue.append(.{ .node = &node.data.binary.left });
                try local_queue.append(.{ .text = " >>>= " });
                try local_queue.append(.{ .node = &node.data.binary.right });
            },
            .plusplus_pre => {
                try writer.writeAll("++");
                try local_queue.append(.{ .node = node.data.node });
            },
            .plusplus_post => {
                try local_queue.append(.{ .node = node.data.node });
                try local_queue.append(.{ .text = "++" });
            },
            .minusminus_pre => {
                try writer.writeAll("--");
                try local_queue.append(.{ .node = node.data.node });
            },
            .minusminus_post => {
                try local_queue.append(.{ .node = node.data.node });
                try local_queue.append(.{ .text = "--" });
            },
            .not => {
                try writer.writeAll("!");
                try local_queue.append(.{ .node = node.data.node });
            },
            .bitwise_negate => {
                try writer.writeAll("~");
                try local_queue.append(.{ .node = node.data.node });
            },
            .minus => {
                try writer.writeAll("-");
                try local_queue.append(.{ .node = node.data.node });
            },
            .minus_expr => {
                try local_queue.append(.{ .node = &node.data.binary.left });
                try local_queue.append(.{ .text = " - " });
                try local_queue.append(.{ .node = &node.data.binary.right });
            },
            .plus => {
                try writer.writeAll("+");
                try local_queue.append(.{ .node = node.data.node });
            },
            .plus_expr => {
                try local_queue.append(.{ .node = &node.data.binary.left });
                try local_queue.append(.{ .text = " + " });
                try local_queue.append(.{ .node = &node.data.binary.right });
            },
            .multiply_expr => {
                try local_queue.append(.{ .node = &node.data.binary.left });
                try local_queue.append(.{ .text = " * " });
                try local_queue.append(.{ .node = &node.data.binary.right });
            },
            .exp_expr => {
                try local_queue.append(.{ .node = &node.data.binary.left });
                try local_queue.append(.{ .text = " ** " });
                try local_queue.append(.{ .node = &node.data.binary.right });
            },
            .div_expr => {
                try local_queue.append(.{ .node = &node.data.binary.left });
                try local_queue.append(.{ .text = " / " });
                try local_queue.append(.{ .node = &node.data.binary.right });
            },
            .modulo_expr => {
                try local_queue.append(.{ .node = &node.data.binary.left });
                try local_queue.append(.{ .text = " % " });
                try local_queue.append(.{ .node = &node.data.binary.right });
            },
            .bitwise_and => {
                try local_queue.append(.{ .node = &node.data.binary.left });
                try local_queue.append(.{ .text = " & " });
                try local_queue.append(.{ .node = &node.data.binary.right });
            },
            .bitwise_or => {
                try local_queue.append(.{ .node = &node.data.binary.left });
                try local_queue.append(.{ .text = " | " });
                try local_queue.append(.{ .node = &node.data.binary.right });
            },
            .bitwise_xor => {
                try local_queue.append(.{ .node = &node.data.binary.left });
                try local_queue.append(.{ .text = " ^ " });
                try local_queue.append(.{ .node = &node.data.binary.right });
            },
            .bitwise_shift_left => {
                try local_queue.append(.{ .node = &node.data.binary.left });
                try local_queue.append(.{ .text = " << " });
                try local_queue.append(.{ .node = &node.data.binary.right });
            },
            .bitwise_shift_right => {
                try local_queue.append(.{ .node = &node.data.binary.left });
                try local_queue.append(.{ .text = " >> " });
                try local_queue.append(.{ .node = &node.data.binary.right });
            },
            .bitwise_unsigned_right_shift => {
                try local_queue.append(.{ .node = &node.data.binary.left });
                try local_queue.append(.{ .text = " >>> " });
                try local_queue.append(.{ .node = &node.data.binary.right });
            },
            .instanceof => {
                try local_queue.append(.{ .node = &node.data.binary.left });
                try local_queue.append(.{ .text = " instanceof " });
                try local_queue.append(.{ .node = &node.data.binary.right });
            },
            .in => {
                try local_queue.append(.{ .node = &node.data.binary.left });
                try local_queue.append(.{ .text = " in " });
                try local_queue.append(.{ .node = &node.data.binary.right });
            },
            .spread => {
                try writer.writeAll("...");
                try local_queue.append(.{ .node = node.data.node });
            },
            .typeof => {
                try writer.writeAll("typeof ");
                try local_queue.append(.{ .node = node.data.node });
            },
            .delete => {
                try writer.writeAll("delete ");
                try local_queue.append(.{ .node = node.data.node });
            },
            .void => {
                try writer.writeAll("void ");
                try local_queue.append(.{ .node = node.data.node });
            },
            .object_literal => {
                try writer.writeAll("{");
                try local_queue.append(.{ .indent_up = {} });
                if (node.data.nodes.len > 0) {
                    try local_queue.append(.{ .text = new_line_char });
                    try local_queue.append(.{ .indent = {} });
                    try local_queue.append(.{ .node = &node.data.nodes[0] });
                    for (1..node.data.nodes.len) |i| {
                        try local_queue.append(.{ .text = "," });
                        try local_queue.append(.{ .text = new_line_char });
                        try local_queue.append(.{ .indent = {} });
                        try local_queue.append(.{ .node = &node.data.nodes[i] });
                    }
                    try local_queue.append(.{ .text = new_line_char });
                }
                try local_queue.append(.{ .indent_down = {} });
                try local_queue.append(.{ .text = "}" });
            },
            .object_literal_field => {
                try local_queue.append(.{ .node = &node.data.binary.left });
                try local_queue.append(.{ .text = ": " });
                try local_queue.append(.{ .node = &node.data.binary.right });
            },
            .object_literal_field_shorthand => {
                try local_queue.append(.{ .node = node.data.node });
            },
            .object_method, .object_async_method, .object_generator_method, .object_async_generator_method => {
                switch (node.tag) {
                    .object_async_method => {
                        try writer.writeAll("async ");
                    },
                    .object_async_generator_method => {
                        try writer.writeAll("async *");
                    },
                    .object_generator_method => {
                        try writer.writeAll("*");
                    },
                    .object_method => {},
                    else => unreachable,
                }
                try local_queue.append(.{ .node = &node.data.function.name.? });
                try local_queue.append(.{ .text = "(" });
                if (node.data.function.params.len > 0) {
                    try local_queue.append(.{ .node = &node.data.function.params[0] });
                    for (1..node.data.function.params.len) |i| {
                        try local_queue.append(.{ .text = ", " });
                        try local_queue.append(.{ .node = &node.data.function.params[i] });
                    }
                }
                try local_queue.append(.{ .text = ") " });
                try local_queue.append(.{ .node = &node.data.function.body });
            },
            .object_getter => {
                try writer.writeAll("get ");
                try local_queue.append(.{ .node = &node.data.function.name.? });
                try local_queue.append(.{ .text = "(" });
                if (node.data.function.params.len > 0) {
                    try local_queue.append(.{ .node = &node.data.function.params[0] });
                    for (1..node.data.function.params.len) |i| {
                        try local_queue.append(.{ .text = ", " });
                        try local_queue.append(.{ .node = &node.data.function.params[i] });
                    }
                }
                try local_queue.append(.{ .text = ") " });
                try local_queue.append(.{ .node = &node.data.function.body });
            },
            .object_setter => {
                try writer.writeAll("set ");
                try local_queue.append(.{ .node = &node.data.function.name.? });
                try local_queue.append(.{ .text = "(" });
                try local_queue.append(.{ .node = &node.data.function.params[0] });
                try local_queue.append(.{ .text = ") " });
                try local_queue.append(.{ .node = &node.data.function.body });
            },
            .property_access => {
                try local_queue.append(.{ .node = &node.data.binary.left });
                try local_queue.append(.{ .text = "." });
                try local_queue.append(.{ .node = &node.data.binary.right });
            },
            .optional_property_access => {
                try local_queue.append(.{ .node = &node.data.binary.left });
                try local_queue.append(.{ .text = "?." });
                try local_queue.append(.{ .node = &node.data.binary.right });
            },
            .array_literal => {
                try writer.writeAll("[");
                if (node.data.nodes.len > 0) {
                    try local_queue.append(.{ .node = &node.data.nodes[0] });
                    for (1..node.data.nodes.len) |i| {
                        try local_queue.append(.{ .text = ", " });
                        try local_queue.append(.{ .node = &node.data.nodes[i] });
                    }
                }
                try local_queue.append(.{ .text = "]" });
            },
            .index_access => {
                try local_queue.append(.{ .node = &node.data.binary.left });
                try local_queue.append(.{ .text = "[" });
                try local_queue.append(.{ .node = &node.data.binary.right });
                try local_queue.append(.{ .text = "]" });
            },
            .eq => {
                try local_queue.append(.{ .node = &node.data.binary.left });
                try local_queue.append(.{ .text = " == " });
                try local_queue.append(.{ .node = &node.data.binary.right });
            },
            .eqq => {
                try local_queue.append(.{ .node = &node.data.binary.left });
                try local_queue.append(.{ .text = " === " });
                try local_queue.append(.{ .node = &node.data.binary.right });
            },
            .neq => {
                try local_queue.append(.{ .node = &node.data.binary.left });
                try local_queue.append(.{ .text = " != " });
                try local_queue.append(.{ .node = &node.data.binary.right });
            },
            .neqq => {
                try local_queue.append(.{ .node = &node.data.binary.left });
                try local_queue.append(.{ .text = " !== " });
                try local_queue.append(.{ .node = &node.data.binary.right });
            },
            .@"and" => {
                try local_queue.append(.{ .node = &node.data.binary.left });
                try local_queue.append(.{ .text = " && " });
                try local_queue.append(.{ .node = &node.data.binary.right });
            },
            .@"or" => {
                try local_queue.append(.{ .node = &node.data.binary.left });
                try local_queue.append(.{ .text = " || " });
                try local_queue.append(.{ .node = &node.data.binary.right });
            },
            .gt => {
                try local_queue.append(.{ .node = &node.data.binary.left });
                try local_queue.append(.{ .text = " > " });
                try local_queue.append(.{ .node = &node.data.binary.right });
            },
            .gte => {
                try local_queue.append(.{ .node = &node.data.binary.left });
                try local_queue.append(.{ .text = " >= " });
                try local_queue.append(.{ .node = &node.data.binary.right });
            },
            .lt => {
                try local_queue.append(.{ .node = &node.data.binary.left });
                try local_queue.append(.{ .text = " < " });
                try local_queue.append(.{ .node = &node.data.binary.right });
            },
            .lte => {
                try local_queue.append(.{ .node = &node.data.binary.left });
                try local_queue.append(.{ .text = " <= " });
                try local_queue.append(.{ .node = &node.data.binary.right });
            },
            .declare => {
                try local_queue.append(.{ .node = node.data.node });
            },
            .type_decl, .interface_decl => {},
        }

        queue.prependMany(&local_queue);
    }
}

fn printStatement(local_queue: *WorkerQueue, node: *const ASTNode) !void {
    try local_queue.append(.{ .indent = {} });
    try local_queue.append(.{ .node = node });
    if (needsSemicolon(node.*)) {
        try local_queue.append(.{ .text = ";" });
    }
}

fn printStatementNL(local_queue: *WorkerQueue, node: *const ASTNode) !void {
    try printStatement(local_queue, node);
    try local_queue.append(.{ .text = new_line_char });
}

fn printDecls(keyword: []const u8, local_queue: *WorkerQueue, node: *const ASTNode) !void {
    try local_queue.append(.{ .text = keyword });
    try local_queue.append(.{ .node = &node.data.nodes[0] });
    for (1..node.data.nodes.len) |i| {
        try local_queue.append(.{ .text = ", " });
        try local_queue.append(.{ .node = &node.data.nodes[i] });
    }
}

fn printImportBinding(local_queue: *WorkerQueue, binding: ASTNode.ImportBinding) !void {
    switch (binding) {
        .named => |named| {
            try local_queue.append(.{ .text = "{" });
            if (named.len > 0) {
                try local_queue.append(.{ .text = named[0].name });
                if (named[0].alias) |alias| {
                    try local_queue.append(.{ .text = " as " });
                    try local_queue.append(.{ .text = alias });
                }
                for (1..named.len) |i| {
                    try local_queue.append(.{ .text = ", " });
                    try local_queue.append(.{ .text = named[i].name });
                    if (named[i].alias) |alias| {
                        try local_queue.append(.{ .text = " as " });
                        try local_queue.append(.{ .text = alias });
                    }
                }
            }
            try local_queue.append(.{ .text = "}" });
        },
        .namespace => |namespace| {
            try local_queue.append(.{ .text = "* as " });
            try local_queue.append(.{ .text = namespace });
        },
        .default => |default| {
            try local_queue.append(.{ .text = default });
        },
    }
}
