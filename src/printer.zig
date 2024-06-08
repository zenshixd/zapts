const std = @import("std");
const builtin = @import("builtin");
const ASTNode = @import("parser.zig").ASTNode;
const ASTNodeList = @import("parser.zig").ASTNodeList;
const ASTNodeTag = @import("parser.zig").ASTNodeTag;
const needsSemicolon = @import("parser.zig").needsSemicolon;

const new_line_char = if (builtin.target.os.tag == .windows) "\r\n" else "\n";

pub fn print(allocator: std.mem.Allocator, statements: *ASTNodeList) ![]const u8 {
    var output = try std.ArrayList(u8).initCapacity(allocator, 1024);
    defer output.deinit();

    while (statements.popFirst()) |statement| {
        try printNode(allocator, output.writer(), statement, 1);
        if (needsSemicolon(statement)) {
            try output.appendSlice(";");
        }
        try output.appendSlice(new_line_char);
    }

    return output.toOwnedSlice();
}

const WorkerItem = union(enum) {
    node: *ASTNode,
    text: []const u8,

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
        }
        try writer.writeAll("}");
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

fn printNode(allocator: std.mem.Allocator, writer: anytype, first_node: *ASTNode, indent: usize) anyerror!void {
    var queue = WorkerQueue{
        .allocator = allocator,
    };
    try queue.prepend(.{ .node = first_node });

    while (queue.popFirst()) |item| {
        defer allocator.destroy(item);
        if (item.data == .text) {
            try writer.writeAll(item.data.text);
            continue;
        }

        var local_queue = WorkerQueue{
            .allocator = allocator,
        };
        const node = item.data.node;
        switch (node.tag) {
            .import => {
                try writer.writeAll("import ");
                try local_queue.append(.{ .node = node.data.binary.left });
                try local_queue.append(.{ .node = node.data.binary.right });
            },
            .import_binding_comma => {
                try local_queue.append(.{ .node = node.data.binary.left });
                try local_queue.append(.{ .text = ", " });
                try local_queue.append(.{ .node = node.data.binary.right });
            },
            .import_named_bindings => {
                try writer.writeAll("{");
                try local_queue.append(.{ .node = node.data.nodes.popFirst().? });
                while (node.data.nodes.popFirst()) |import_node| {
                    try local_queue.append(.{ .text = ", " });
                    try local_queue.append(.{ .node = import_node });
                }
                try local_queue.append(.{ .text = "}" });
            },
            .import_binding_named, .import_binding_default => {
                try writer.writeAll(node.data.literal);
            },
            .import_binding_namespace => {
                try writer.print("* as {s}", .{node.data.literal});
            },
            .import_type_binding_default, .import_type_binding_named, .import_type_binding_namespace => {},
            .import_from_path => {
                try writer.print(" from {s}", .{node.data.literal});
            },
            .import_path => {
                try writer.writeAll(node.data.literal);
            },
            .var_decl => {
                try printDecls("var ", &local_queue, node);
            },
            .const_decl => {
                try printDecls("const ", &local_queue, node);
            },
            .let_decl => {
                try printDecls("let ", &local_queue, node);
            },
            .async_func_decl => {
                try writer.writeAll("async function ");
                try local_queue.append(.{ .node = node.data.nodes.popFirst().? });
                try local_queue.append(.{ .text = "(" });
                if (node.data.nodes.len > 2) {
                    try local_queue.append(.{ .node = node.data.nodes.popFirst().? });
                    while (node.data.nodes.len > 0) {
                        const arg = node.data.nodes.popFirst().?;
                        try local_queue.append(.{ .text = ", " });
                        try local_queue.append(.{ .node = arg });
                    }
                }
                try local_queue.append(.{ .text = ") " });
                try local_queue.append(.{ .node = node.data.nodes.popFirst().? });
            },
            .func_decl => {
                try writer.writeAll("function ");
                try local_queue.append(.{ .node = node.data.nodes.popFirst().? });
                try local_queue.append(.{ .text = "(" });
                if (node.data.nodes.len > 2) {
                    try local_queue.append(.{ .node = node.data.nodes.popFirst().? });
                    while (node.data.nodes.len > 0) {
                        const arg = node.data.nodes.popFirst().?;
                        try local_queue.append(.{ .text = ", " });
                        try local_queue.append(.{ .node = arg });
                    }
                }
                try local_queue.append(.{ .text = ") " });
                try local_queue.append(.{ .node = node.data.nodes.popFirst().? });
            },
            .func_decl_name, .func_decl_argument => {
                try writer.writeAll(node.data.literal);
            },
            .@"if" => {
                try writer.writeAll("if (");
                try local_queue.append(.{ .node = node.data.binary.left });
                try local_queue.append(.{ .text = ")" });
                const right = node.data.binary.right;
                if (right.tag == .block) {
                    try local_queue.append(.{ .text = " " });
                    try local_queue.append(.{ .node = right });
                } else {
                    try local_queue.append(.{ .text = new_line_char });
                    try printStatement(&local_queue, right, indent);
                }
            },
            .@"else" => {
                const ifNode = node.data.binary.left;
                if (ifNode.data.binary.right.tag == .block) {
                    try local_queue.append(.{ .node = ifNode });
                    try local_queue.append(.{ .text = " else" });
                } else {
                    try local_queue.append(.{ .node = ifNode });
                    try local_queue.append(.{ .text = new_line_char });
                    try local_queue.append(.{ .text = "else" });
                }

                const right = node.data.binary.right;
                if (right.tag == .block or right.tag == .@"if" or right.tag == .@"else") {
                    try local_queue.append(.{ .text = " " });
                    try local_queue.append(.{ .node = right });
                } else {
                    try local_queue.append(.{ .text = new_line_char });
                    try printStatement(&local_queue, right, indent);
                }
            },
            .@"switch" => {
                try writer.writeAll("switch (");
                try local_queue.append(.{ .node = node.data.binary.left });
                try local_queue.append(.{ .text = ") " });
                try local_queue.append(.{ .node = node.data.binary.right });
            },
            .case => {
                try writer.writeAll("case ");
                try local_queue.append(.{ .node = node.data.nodes.popFirst().? });
                try local_queue.append(.{ .text = ": " });

                while (node.data.nodes.popFirst()) |stmt| {
                    try printStatement(&local_queue, stmt, indent + 1);
                    try local_queue.append(.{ .text = new_line_char });
                }
            },
            .default => {
                try writer.writeAll("default: ");
                while (node.data.nodes.popFirst()) |stmt| {
                    try printStatement(&local_queue, stmt, indent + 1);
                    try local_queue.append(.{ .text = new_line_char });
                }
            },
            .@"break" => {
                try writer.writeAll("break");
            },
            .@"continue" => {
                try writer.writeAll("continue");
            },
            .@"for" => {
                try writer.writeAll("for (");
                try local_queue.append(.{ .node = node.data.binary.left });
                try local_queue.append(.{ .text = ") " });
                try local_queue.append(.{ .node = node.data.binary.right });
            },
            .for_classic => {
                try local_queue.append(.{ .node = node.data.nodes.popFirst().? });
                try local_queue.append(.{ .text = "; " });
                try local_queue.append(.{ .node = node.data.nodes.popFirst().? });
                try local_queue.append(.{ .text = "; " });
                try local_queue.append(.{ .node = node.data.nodes.popFirst().? });
            },
            .for_in => {
                try local_queue.append(.{ .node = node.data.binary.left });
                try local_queue.append(.{ .text = " in " });
                try local_queue.append(.{ .node = node.data.binary.right });
            },
            .for_of => {
                try local_queue.append(.{ .node = node.data.binary.left });
                try local_queue.append(.{ .text = " of " });
                try local_queue.append(.{ .node = node.data.binary.right });
            },
            .@"while" => {
                try writer.writeAll("while (");
                try local_queue.append(.{ .node = node.data.binary.left });
                try local_queue.append(.{ .text = ") " });
                try local_queue.append(.{ .node = node.data.binary.right });
            },
            .do_while => {
                try writer.writeAll("do ");
                try local_queue.append(.{ .node = node.data.binary.right });
                if (node.data.binary.right.tag != .block) {
                    try local_queue.append(.{ .text = ";" });
                }
                try local_queue.append(.{ .text = " while (" });
                try local_queue.append(.{ .node = node.data.binary.left });
                try local_queue.append(.{ .text = ");" });
            },
            .block => {
                try writer.writeAll("{");
                if (node.data.nodes.len > 0) {
                    try writer.writeAll(new_line_char);
                    try printStatementNL(&local_queue, node.data.nodes.popFirst().?, indent);
                    while (node.data.nodes.popFirst()) |stmt| {
                        try printStatementNL(&local_queue, stmt, indent);
                    }
                }
                try local_queue.append(.{ .text = "}" });
            },
            .call_expr => {
                try local_queue.append(.{ .node = node.data.nodes.popFirst().? });
                try local_queue.append(.{ .text = "(" });
                if (node.data.nodes.len > 0) {
                    try local_queue.append(.{ .node = node.data.nodes.popFirst().? });
                    while (node.data.nodes.popFirst()) |arg| {
                        try local_queue.append(.{ .text = ", " });
                        try local_queue.append(.{ .node = arg });
                    }
                }
                try local_queue.append(.{ .text = ")" });
            },
            .comma => {
                try local_queue.append(.{ .node = node.data.binary.left });
                try local_queue.append(.{ .text = ", " });
                try local_queue.append(.{ .node = node.data.binary.right });
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
            .none => {},
            .grouping => {
                try writer.writeAll("(");
                try local_queue.append(.{ .node = node.data.node });
                try local_queue.append(.{ .text = ")" });
            },
            .assignment => {
                try local_queue.append(.{ .node = node.data.binary.left });
                try local_queue.append(.{ .text = " = " });
                try local_queue.append(.{ .node = node.data.binary.right });
            },
            .plus_assign => {
                try local_queue.append(.{ .node = node.data.binary.left });
                try local_queue.append(.{ .text = " += " });
                try local_queue.append(.{ .node = node.data.binary.right });
            },
            .minus_assign => {
                try local_queue.append(.{ .node = node.data.binary.left });
                try local_queue.append(.{ .text = " -= " });
                try local_queue.append(.{ .node = node.data.binary.right });
            },
            .multiply_assign => {
                try local_queue.append(.{ .node = node.data.binary.left });
                try local_queue.append(.{ .text = " *= " });
                try local_queue.append(.{ .node = node.data.binary.right });
            },
            .div_assign => {
                try local_queue.append(.{ .node = node.data.binary.left });
                try local_queue.append(.{ .text = " /= " });
                try local_queue.append(.{ .node = node.data.binary.right });
            },
            .modulo_assign => {
                try local_queue.append(.{ .node = node.data.binary.left });
                try local_queue.append(.{ .text = " %= " });
                try local_queue.append(.{ .node = node.data.binary.right });
            },
            .exp_assign => {
                try local_queue.append(.{ .node = node.data.binary.left });
                try local_queue.append(.{ .text = " **= " });
                try local_queue.append(.{ .node = node.data.binary.right });
            },
            .and_assign => {
                try local_queue.append(.{ .node = node.data.binary.left });
                try local_queue.append(.{ .text = " &= " });
                try local_queue.append(.{ .node = node.data.binary.right });
            },
            .or_assign => {
                try local_queue.append(.{ .node = node.data.binary.left });
                try local_queue.append(.{ .text = " |= " });
                try local_queue.append(.{ .node = node.data.binary.right });
            },
            .bitwise_and_assign => {
                try local_queue.append(.{ .node = node.data.binary.left });
                try local_queue.append(.{ .text = " &= " });
                try local_queue.append(.{ .node = node.data.binary.right });
            },
            .bitwise_or_assign => {
                try local_queue.append(.{ .node = node.data.binary.left });
                try local_queue.append(.{ .text = " |= " });
                try local_queue.append(.{ .node = node.data.binary.right });
            },
            .bitwise_xor_assign => {
                try local_queue.append(.{ .node = node.data.binary.left });
                try local_queue.append(.{ .text = " ^= " });
                try local_queue.append(.{ .node = node.data.binary.right });
            },
            .bitwise_shift_left_assign => {
                try local_queue.append(.{ .node = node.data.binary.left });
                try local_queue.append(.{ .text = " <<= " });
                try local_queue.append(.{ .node = node.data.binary.right });
            },
            .bitwise_shift_right_assign => {
                try local_queue.append(.{ .node = node.data.binary.left });
                try local_queue.append(.{ .text = " >>= " });
                try local_queue.append(.{ .node = node.data.binary.right });
            },
            .bitwise_unsigned_right_shift_assign => {
                try local_queue.append(.{ .node = node.data.binary.left });
                try local_queue.append(.{ .text = " >>>= " });
                try local_queue.append(.{ .node = node.data.binary.right });
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
                try local_queue.append(.{ .node = node.data.binary.left });
                try local_queue.append(.{ .text = " - " });
                try local_queue.append(.{ .node = node.data.binary.right });
            },
            .plus => {
                try writer.writeAll("+");
                try local_queue.append(.{ .node = node.data.node });
            },
            .plus_expr => {
                try local_queue.append(.{ .node = node.data.binary.left });
                try local_queue.append(.{ .text = " + " });
                try local_queue.append(.{ .node = node.data.binary.right });
            },
            .multiply_expr => {
                try local_queue.append(.{ .node = node.data.binary.left });
                try local_queue.append(.{ .text = " * " });
                try local_queue.append(.{ .node = node.data.binary.right });
            },
            .exp_expr => {
                try local_queue.append(.{ .node = node.data.binary.left });
                try local_queue.append(.{ .text = " ** " });
                try local_queue.append(.{ .node = node.data.binary.right });
            },
            .div_expr => {
                try local_queue.append(.{ .node = node.data.binary.left });
                try local_queue.append(.{ .text = " / " });
                try local_queue.append(.{ .node = node.data.binary.right });
            },
            .modulo_expr => {
                try local_queue.append(.{ .node = node.data.binary.left });
                try local_queue.append(.{ .text = " % " });
                try local_queue.append(.{ .node = node.data.binary.right });
            },
            .bitwise_and => {
                try local_queue.append(.{ .node = node.data.binary.left });
                try local_queue.append(.{ .text = " & " });
                try local_queue.append(.{ .node = node.data.binary.right });
            },
            .bitwise_or => {
                try local_queue.append(.{ .node = node.data.binary.left });
                try local_queue.append(.{ .text = " | " });
                try local_queue.append(.{ .node = node.data.binary.right });
            },
            .bitwise_xor => {
                try local_queue.append(.{ .node = node.data.binary.left });
                try local_queue.append(.{ .text = " ^ " });
                try local_queue.append(.{ .node = node.data.binary.right });
            },
            .bitwise_shift_left => {
                try local_queue.append(.{ .node = node.data.binary.left });
                try local_queue.append(.{ .text = " << " });
                try local_queue.append(.{ .node = node.data.binary.right });
            },
            .bitwise_shift_right => {
                try local_queue.append(.{ .node = node.data.binary.left });
                try local_queue.append(.{ .text = " >> " });
                try local_queue.append(.{ .node = node.data.binary.right });
            },
            .bitwise_unsigned_right_shift => {
                try local_queue.append(.{ .node = node.data.binary.left });
                try local_queue.append(.{ .text = " >>> " });
                try local_queue.append(.{ .node = node.data.binary.right });
            },
            .instanceof => {
                try local_queue.append(.{ .node = node.data.binary.left });
                try local_queue.append(.{ .text = " instanceof " });
                try local_queue.append(.{ .node = node.data.binary.right });
            },
            .in => {
                try local_queue.append(.{ .node = node.data.binary.left });
                try local_queue.append(.{ .text = " in " });
                try local_queue.append(.{ .node = node.data.binary.right });
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
                if (node.data.nodes.len > 0) {
                    try local_queue.append(.{ .text = new_line_char });
                    try printIndent(&local_queue, indent);
                    try local_queue.append(.{ .node = node.data.nodes.popFirst().? });
                    while (node.data.nodes.popFirst()) |decl_node| {
                        try local_queue.append(.{ .text = "," });
                        try local_queue.append(.{ .text = new_line_char });
                        try printIndent(&local_queue, indent);
                        try local_queue.append(.{ .node = decl_node });
                    }
                    try local_queue.append(.{ .text = new_line_char });
                    try printIndent(&local_queue, indent - 1);
                }
                try local_queue.append(.{ .text = "}" });
            },
            .object_literal_field => {
                try local_queue.append(.{ .node = node.data.binary.left });
                try local_queue.append(.{ .text = ": " });
                try local_queue.append(.{ .node = node.data.binary.right });
            },
            .object_literal_field_shorthand => {
                try local_queue.append(.{ .node = node.data.node });
            },
            .property_access => {
                try local_queue.append(.{ .node = node.data.binary.left });
                try local_queue.append(.{ .text = "." });
                try local_queue.append(.{ .node = node.data.binary.right });
            },
            .optional_property_access => {
                try local_queue.append(.{ .node = node.data.binary.left });
                try local_queue.append(.{ .text = "?." });
                try local_queue.append(.{ .node = node.data.binary.right });
            },
            .array_literal => {
                try writer.writeAll("[");
                if (node.data.nodes.len > 0) {
                    try local_queue.append(.{ .node = node.data.nodes.popFirst().? });
                    while (node.data.nodes.popFirst()) |decl_node| {
                        try local_queue.append(.{ .text = ", " });
                        try local_queue.append(.{ .node = decl_node });
                    }
                }
                try local_queue.append(.{ .text = "]" });
            },
            .index_access => {
                try local_queue.append(.{ .node = node.data.binary.left });
                try local_queue.append(.{ .text = "[" });
                try local_queue.append(.{ .node = node.data.binary.right });
                try local_queue.append(.{ .text = "]" });
            },
            .eq => {
                try local_queue.append(.{ .node = node.data.binary.left });
                try local_queue.append(.{ .text = " == " });
                try local_queue.append(.{ .node = node.data.binary.right });
            },
            .eqq => {
                try local_queue.append(.{ .node = node.data.binary.left });
                try local_queue.append(.{ .text = " === " });
                try local_queue.append(.{ .node = node.data.binary.right });
            },
            .neq => {
                try local_queue.append(.{ .node = node.data.binary.left });
                try local_queue.append(.{ .text = " != " });
                try local_queue.append(.{ .node = node.data.binary.right });
            },
            .neqq => {
                try local_queue.append(.{ .node = node.data.binary.left });
                try local_queue.append(.{ .text = " !== " });
                try local_queue.append(.{ .node = node.data.binary.right });
            },
            .@"and" => {
                try local_queue.append(.{ .node = node.data.binary.left });
                try local_queue.append(.{ .text = " && " });
                try local_queue.append(.{ .node = node.data.binary.right });
            },
            .@"or" => {
                try local_queue.append(.{ .node = node.data.binary.left });
                try local_queue.append(.{ .text = " || " });
                try local_queue.append(.{ .node = node.data.binary.right });
            },
            .gt => {
                try local_queue.append(.{ .node = node.data.binary.left });
                try local_queue.append(.{ .text = " > " });
                try local_queue.append(.{ .node = node.data.binary.right });
            },
            .gte => {
                try local_queue.append(.{ .node = node.data.binary.left });
                try local_queue.append(.{ .text = " >= " });
                try local_queue.append(.{ .node = node.data.binary.right });
            },
            .lt => {
                try local_queue.append(.{ .node = node.data.binary.left });
                try local_queue.append(.{ .text = " < " });
                try local_queue.append(.{ .node = node.data.binary.right });
            },
            .lte => {
                try local_queue.append(.{ .node = node.data.binary.left });
                try local_queue.append(.{ .text = " <= " });
                try local_queue.append(.{ .node = node.data.binary.right });
            },
        }

        queue.prependMany(&local_queue);
    }
}

fn printStatement(local_queue: *WorkerQueue, node: *ASTNode, indent: usize) !void {
    try printIndent(local_queue, indent);
    try local_queue.append(.{ .node = node });
    if (needsSemicolon(node)) {
        try local_queue.append(.{ .text = ";" });
    }
}

fn printStatementNL(local_queue: *WorkerQueue, node: *ASTNode, indent: usize) !void {
    try printStatement(local_queue, node, indent);
    try local_queue.append(.{ .text = new_line_char });
}

fn printIndent(local_queue: *WorkerQueue, indent: usize) !void {
    for (0..indent) |_| {
        try local_queue.append(.{ .text = "    " });
    }
}

fn printDecls(keyword: []const u8, local_queue: *WorkerQueue, node: *ASTNode) !void {
    try local_queue.append(.{ .text = keyword });
    try local_queue.append(.{ .node = node.data.nodes.popFirst().? });
    while (node.data.nodes.popFirst()) |decl_node| {
        try local_queue.append(.{ .text = ", " });
        try local_queue.append(.{ .node = decl_node });
    }
}
