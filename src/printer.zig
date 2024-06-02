const std = @import("std");
const builtin = @import("builtin");
const ASTNode = @import("parser.zig").ASTNode;
const ASTNodeTag = @import("parser.zig").ASTNodeTag;
const needsSemicolon = @import("parser.zig").needsSemicolon;

const new_line_char = if (builtin.target.os.tag == .windows) "\r\n" else "\n";

pub fn print(allocator: std.mem.Allocator, statements: []*ASTNode) ![]const u8 {
    var output = try std.ArrayList(u8).initCapacity(allocator, 1024);
    defer output.deinit();

    for (statements) |statement| {
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
                try local_queue.append(.{
                    .text = "import ",
                });
                switch (node.data.nodes.len) {
                    0 => {},
                    1 => try local_queue.append(.{ .node = node.data.nodes[0] }),
                    else => {
                        const nodes = node.data.nodes;
                        try local_queue.append(.{ .node = nodes[0] });
                        for (nodes[1..]) |import_node| {
                            if (import_node.tag == .import_path) {
                                try local_queue.append(.{ .text = " from " });
                                try local_queue.append(.{ .node = import_node });
                                break;
                            }

                            try local_queue.append(.{ .text = ", " });
                            try local_queue.append(.{ .node = import_node });
                        }
                    },
                }
            },
            .import_named_bindings => {
                try local_queue.append(.{ .text = "{" });
                try local_queue.append(.{ .node = node.data.nodes[0] });
                for (node.data.nodes[1..]) |import_node| {
                    try local_queue.append(.{ .text = ", " });
                    try local_queue.append(.{ .node = import_node });
                }
                try local_queue.append(.{ .text = "}" });
            },
            .import_binding_named, .import_binding_default => {
                try local_queue.append(.{ .text = node.data.literal });
            },
            .import_binding_namespace => {
                try local_queue.append(.{ .text = "* as " });
                try local_queue.append(.{ .text = node.data.literal });
            },
            .import_type_binding_default, .import_type_binding_named, .import_type_binding_namespace => {},
            .import_path => {
                try local_queue.append(.{ .text = node.data.literal });
            },
            .var_decl => {
                try local_queue.append(.{ .text = "var " });
                try local_queue.append(.{ .node = node.data.nodes[0] });
                for (node.data.nodes[1..]) |decl_node| {
                    try local_queue.append(.{ .text = ", " });
                    try local_queue.append(.{ .node = decl_node });
                }
            },
            .const_decl => {
                try local_queue.append(.{ .text = "const " });
                try local_queue.append(.{ .node = node.data.nodes[0] });

                for (node.data.nodes[1..]) |decl_node| {
                    try local_queue.append(.{ .text = ", " });
                    try local_queue.append(.{ .node = decl_node });
                }
            },
            .let_decl => {
                try local_queue.append(.{ .text = "let " });
                try local_queue.append(.{ .node = node.data.nodes[0] });

                for (node.data.nodes[1..]) |decl_node| {
                    try local_queue.append(.{ .text = ", " });
                    try local_queue.append(.{ .node = decl_node });
                }
            },
            .async_func_decl => {
                try local_queue.append(.{ .text = "async function " });
                try local_queue.append(.{ .node = node.data.nodes[0] });
                try local_queue.append(.{ .text = "(" });
                if (node.data.nodes.len > 2) {
                    try local_queue.append(.{ .node = node.data.nodes[1] });
                    for (node.data.nodes[2 .. node.data.nodes.len - 1]) |arg| {
                        try local_queue.append(.{ .text = ", " });
                        try local_queue.append(.{ .node = arg });
                    }
                }
                try local_queue.append(.{ .text = ") " });
                try local_queue.append(.{ .node = node.data.nodes[node.data.nodes.len - 1] });
            },
            .func_decl => {
                try local_queue.append(.{ .text = "function " });
                try local_queue.append(.{ .node = node.data.nodes[0] });
                try local_queue.append(.{ .text = "(" });
                if (node.data.nodes.len > 2) {
                    try local_queue.append(.{ .node = node.data.nodes[1] });
                    for (node.data.nodes[2 .. node.data.nodes.len - 1]) |arg| {
                        try local_queue.append(.{ .text = ", " });
                        try local_queue.append(.{ .node = arg });
                    }
                }
                try local_queue.append(.{ .text = ") " });
                try local_queue.append(.{ .node = node.data.nodes[node.data.nodes.len - 1] });
            },
            .func_decl_name, .func_decl_argument => {
                try local_queue.append(.{ .text = node.data.literal });
            },
            .@"if" => {
                try local_queue.append(.{ .text = "if (" });
                try local_queue.append(.{ .node = node.data.nodes[0] });
                try local_queue.append(.{ .text = ")" });
                const right = node.data.nodes[1];
                if (right.tag == .block) {
                    try local_queue.append(.{ .text = " " });
                    try local_queue.append(.{ .node = right });
                } else {
                    try local_queue.append(.{ .text = new_line_char });
                    try printStatement(&local_queue, right, indent);
                }
            },
            .@"else" => {
                const left = node.data.nodes[0];
                if (left.data.nodes[1].tag == .block) {
                    try local_queue.append(.{ .node = left });
                    try local_queue.append(.{ .text = " else" });
                } else {
                    try local_queue.append(.{ .node = left });
                    try local_queue.append(.{ .text = new_line_char });
                    try local_queue.append(.{ .text = "else" });
                }

                const right = node.data.nodes[1];
                if (right.tag == .block or right.tag == .@"if" or right.tag == .@"else") {
                    try local_queue.append(.{ .text = " " });
                    try local_queue.append(.{ .node = right });
                } else {
                    try local_queue.append(.{ .text = new_line_char });
                    try printStatement(&local_queue, right, indent);
                }
            },
            .@"switch" => {
                try local_queue.append(.{ .text = "switch (" });
                try local_queue.append(.{ .node = node.data.nodes[0] });
                try local_queue.append(.{ .text = ") " });
                try local_queue.append(.{ .node = node.data.nodes[1] });
            },
            .case => {
                try local_queue.append(.{ .text = "case " });
                try local_queue.append(.{ .node = node.data.nodes[0] });
                try local_queue.append(.{ .text = ": " });

                for (node.data.nodes[1..]) |stmt| {
                    try printStatement(&local_queue, stmt, indent + 1);
                    try local_queue.append(.{ .text = new_line_char });
                }
            },
            .default => {
                try local_queue.append(.{ .text = "default: " });
                for (node.data.nodes[0..]) |stmt| {
                    try printStatement(&local_queue, stmt, indent + 1);
                    try local_queue.append(.{ .text = new_line_char });
                }
            },
            .@"break" => {
                try local_queue.append(.{ .text = "break" });
            },
            .@"continue" => {
                try local_queue.append(.{ .text = "continue" });
            },
            .@"for" => {
                try local_queue.append(.{ .text = "for (" });
                try local_queue.append(.{ .node = node.data.nodes[0] });
                try local_queue.append(.{ .text = ") " });
                try local_queue.append(.{ .node = node.data.nodes[1] });
            },
            .for_classic => {
                try local_queue.append(.{ .node = node.data.nodes[0] });
                try local_queue.append(.{ .text = "; " });
                try local_queue.append(.{ .node = node.data.nodes[1] });
                try local_queue.append(.{ .text = "; " });
                try local_queue.append(.{ .node = node.data.nodes[2] });
            },
            .for_in => {
                try local_queue.append(.{ .node = node.data.nodes[0] });
                try local_queue.append(.{ .text = " in " });
                try local_queue.append(.{ .node = node.data.nodes[1] });
            },
            .for_of => {
                try local_queue.append(.{ .node = node.data.nodes[0] });
                try local_queue.append(.{ .text = " of " });
                try local_queue.append(.{ .node = node.data.nodes[1] });
            },
            .@"while" => {
                try local_queue.append(.{ .text = "while (" });
                try local_queue.append(.{ .node = node.data.nodes[0] });
                try local_queue.append(.{ .text = ") " });
                try local_queue.append(.{ .node = node.data.nodes[1] });
            },
            .do_while => {
                try local_queue.append(.{ .text = "do " });
                try local_queue.append(.{ .node = node.data.nodes[1] });
                if (node.data.nodes[1].tag != .block) {
                    try local_queue.append(.{ .text = ";" });
                }
                try local_queue.append(.{ .text = " while (" });
                try local_queue.append(.{ .node = node.data.nodes[0] });
                try local_queue.append(.{ .text = ");" });
            },
            .block => {
                try local_queue.append(.{ .text = "{" });
                if (node.data.nodes.len > 0) {
                    try local_queue.append(.{ .text = new_line_char });
                    try printStatementNL(&local_queue, node.data.nodes[0], indent);
                    for (node.data.nodes[1..]) |stmt| {
                        try printStatementNL(&local_queue, stmt, indent);
                    }
                }
                try local_queue.append(.{ .text = "}" });
            },
            .call_expr => {
                try local_queue.append(.{ .node = node.data.nodes[0] });
                try local_queue.append(.{ .text = "(" });
                if (node.data.nodes.len > 1) {
                    try local_queue.append(.{ .node = node.data.nodes[1] });
                    for (node.data.nodes[2..]) |arg| {
                        try local_queue.append(.{ .text = ", " });
                        try local_queue.append(.{ .node = arg });
                    }
                }
                try local_queue.append(.{ .text = ")" });
            },
            .comma => {
                try local_queue.append(.{ .node = node.data.nodes[0] });
                try local_queue.append(.{ .text = ", " });
                try local_queue.append(.{ .node = node.data.nodes[1] });
            },
            .true => {
                try local_queue.append(.{ .text = "true" });
            },
            .false => {
                try local_queue.append(.{ .text = "false" });
            },
            .null => {
                try local_queue.append(.{ .text = "null" });
            },
            .undefined => {
                try local_queue.append(.{ .text = "undefined" });
            },
            .number, .bigint, .identifier, .string => {
                try local_queue.append(.{ .text = node.data.literal });
            },
            .none => {},
            .grouping => {
                try local_queue.append(.{ .text = "(" });
                try local_queue.append(.{ .node = node.data.node });
                try local_queue.append(.{ .text = ")" });
            },
            .assignment => {
                try local_queue.append(.{ .node = node.data.nodes[0] });
                try local_queue.append(.{ .text = " = " });
                try local_queue.append(.{ .node = node.data.nodes[1] });
            },
            .plus_assign => {
                try local_queue.append(.{ .node = node.data.nodes[0] });
                try local_queue.append(.{ .text = " += " });
                try local_queue.append(.{ .node = node.data.nodes[1] });
            },
            .minus_assign => {
                try local_queue.append(.{ .node = node.data.nodes[0] });
                try local_queue.append(.{ .text = " -= " });
                try local_queue.append(.{ .node = node.data.nodes[1] });
            },
            .multiply_assign => {
                try local_queue.append(.{ .node = node.data.nodes[0] });
                try local_queue.append(.{ .text = " *= " });
                try local_queue.append(.{ .node = node.data.nodes[1] });
            },
            .div_assign => {
                try local_queue.append(.{ .node = node.data.nodes[0] });
                try local_queue.append(.{ .text = " /= " });
                try local_queue.append(.{ .node = node.data.nodes[1] });
            },
            .modulo_assign => {
                try local_queue.append(.{ .node = node.data.nodes[0] });
                try local_queue.append(.{ .text = " %= " });
                try local_queue.append(.{ .node = node.data.nodes[1] });
            },
            .exp_assign => {
                try local_queue.append(.{ .node = node.data.nodes[0] });
                try local_queue.append(.{ .text = " **= " });
                try local_queue.append(.{ .node = node.data.nodes[1] });
            },
            .and_assign => {
                try local_queue.append(.{ .node = node.data.nodes[0] });
                try local_queue.append(.{ .text = " &= " });
                try local_queue.append(.{ .node = node.data.nodes[1] });
            },
            .or_assign => {
                try local_queue.append(.{ .node = node.data.nodes[0] });
                try local_queue.append(.{ .text = " |= " });
                try local_queue.append(.{ .node = node.data.nodes[1] });
            },
            .bitwise_and_assign => {
                try local_queue.append(.{ .node = node.data.nodes[0] });
                try local_queue.append(.{ .text = " &= " });
                try local_queue.append(.{ .node = node.data.nodes[1] });
            },
            .bitwise_or_assign => {
                try local_queue.append(.{ .node = node.data.nodes[0] });
                try local_queue.append(.{ .text = " |= " });
                try local_queue.append(.{ .node = node.data.nodes[1] });
            },
            .bitwise_xor_assign => {
                try local_queue.append(.{ .node = node.data.nodes[0] });
                try local_queue.append(.{ .text = " ^= " });
                try local_queue.append(.{ .node = node.data.nodes[1] });
            },
            .bitwise_shift_left_assign => {
                try local_queue.append(.{ .node = node.data.nodes[0] });
                try local_queue.append(.{ .text = " <<= " });
                try local_queue.append(.{ .node = node.data.nodes[1] });
            },
            .bitwise_shift_right_assign => {
                try local_queue.append(.{ .node = node.data.nodes[0] });
                try local_queue.append(.{ .text = " >>= " });
                try local_queue.append(.{ .node = node.data.nodes[1] });
            },
            .bitwise_unsigned_right_shift_assign => {
                try local_queue.append(.{ .node = node.data.nodes[0] });
                try local_queue.append(.{ .text = " >>>= " });
                try local_queue.append(.{ .node = node.data.nodes[1] });
            },
            .plusplus_pre => {
                try local_queue.append(.{ .text = "++" });
                try local_queue.append(.{ .node = node.data.node });
            },
            .plusplus_post => {
                try local_queue.append(.{ .node = node.data.node });
                try local_queue.append(.{ .text = "++" });
            },
            .minusminus_pre => {
                try local_queue.append(.{ .text = "--" });
                try local_queue.append(.{ .node = node.data.node });
            },
            .minusminus_post => {
                try local_queue.append(.{ .node = node.data.node });
                try local_queue.append(.{ .text = "--" });
            },
            .not => {
                try local_queue.append(.{ .text = "!" });
                try local_queue.append(.{ .node = node.data.node });
            },
            .bitwise_negate => {
                try local_queue.append(.{ .text = "~" });
                try local_queue.append(.{ .node = node.data.node });
            },
            .minus => {
                try local_queue.append(.{ .text = "-" });
                try local_queue.append(.{ .node = node.data.node });
            },
            .minus_expr => {
                try local_queue.append(.{ .node = node.data.nodes[0] });
                try local_queue.append(.{ .text = " - " });
                try local_queue.append(.{ .node = node.data.nodes[1] });
            },
            .plus => {
                try local_queue.append(.{ .text = "+" });
                try local_queue.append(.{ .node = node.data.node });
            },
            .plus_expr => {
                try local_queue.append(.{ .node = node.data.nodes[0] });
                try local_queue.append(.{ .text = " + " });
                try local_queue.append(.{ .node = node.data.nodes[1] });
            },
            .multiply_expr => {
                try local_queue.append(.{ .node = node.data.nodes[0] });
                try local_queue.append(.{ .text = " * " });
                try local_queue.append(.{ .node = node.data.nodes[1] });
            },
            .exp_expr => {
                try local_queue.append(.{ .node = node.data.nodes[0] });
                try local_queue.append(.{ .text = " ** " });
                try local_queue.append(.{ .node = node.data.nodes[1] });
            },
            .div_expr => {
                try local_queue.append(.{ .node = node.data.nodes[0] });
                try local_queue.append(.{ .text = " / " });
                try local_queue.append(.{ .node = node.data.nodes[1] });
            },
            .modulo_expr => {
                try local_queue.append(.{ .node = node.data.nodes[0] });
                try local_queue.append(.{ .text = " % " });
                try local_queue.append(.{ .node = node.data.nodes[1] });
            },
            .bitwise_and => {
                try local_queue.append(.{ .node = node.data.nodes[0] });
                try local_queue.append(.{ .text = " & " });
                try local_queue.append(.{ .node = node.data.nodes[1] });
            },
            .bitwise_or => {
                try local_queue.append(.{ .node = node.data.nodes[0] });
                try local_queue.append(.{ .text = " | " });
                try local_queue.append(.{ .node = node.data.nodes[1] });
            },
            .bitwise_xor => {
                try local_queue.append(.{ .node = node.data.nodes[0] });
                try local_queue.append(.{ .text = " ^ " });
                try local_queue.append(.{ .node = node.data.nodes[1] });
            },
            .bitwise_shift_left => {
                try local_queue.append(.{ .node = node.data.nodes[0] });
                try local_queue.append(.{ .text = " << " });
                try local_queue.append(.{ .node = node.data.nodes[1] });
            },
            .bitwise_shift_right => {
                try local_queue.append(.{ .node = node.data.nodes[0] });
                try local_queue.append(.{ .text = " >> " });
                try local_queue.append(.{ .node = node.data.nodes[1] });
            },
            .bitwise_unsigned_right_shift => {
                try local_queue.append(.{ .node = node.data.nodes[0] });
                try local_queue.append(.{ .text = " >>> " });
                try local_queue.append(.{ .node = node.data.nodes[1] });
            },
            .instanceof => {
                try local_queue.append(.{ .node = node.data.nodes[0] });
                try local_queue.append(.{ .text = " instanceof " });
                try local_queue.append(.{ .node = node.data.nodes[1] });
            },
            .in => {
                try local_queue.append(.{ .node = node.data.nodes[0] });
                try local_queue.append(.{ .text = " in " });
                try local_queue.append(.{ .node = node.data.nodes[1] });
            },
            .spread => {
                try local_queue.append(.{ .text = "..." });
                try local_queue.append(.{ .node = node.data.node });
            },
            .typeof => {
                try local_queue.append(.{ .text = "typeof " });
                try local_queue.append(.{ .node = node.data.node });
            },
            .delete => {
                try local_queue.append(.{ .text = "delete " });
                try local_queue.append(.{ .node = node.data.node });
            },
            .void => {
                try local_queue.append(.{ .text = "void " });
                try local_queue.append(.{ .node = node.data.node });
            },
            .object_literal => {
                try local_queue.append(.{ .text = "{" });
                if (node.data.nodes.len > 0) {
                    try local_queue.append(.{ .text = new_line_char });
                    try printIndent(&local_queue, indent);
                    try local_queue.append(.{ .node = node.data.nodes[0] });
                    for (node.data.nodes[1..]) |decl_node| {
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
                try local_queue.append(.{ .node = node.data.nodes[0] });
                try local_queue.append(.{ .text = ": " });
                try local_queue.append(.{ .node = node.data.nodes[1] });
            },
            .object_literal_field_shorthand => {
                try local_queue.append(.{ .node = node.data.node });
            },
            .property_access => {
                try local_queue.append(.{ .node = node.data.nodes[0] });
                try local_queue.append(.{ .text = "." });
                try local_queue.append(.{ .node = node.data.nodes[1] });
            },
            .optional_property_access => {
                try local_queue.append(.{ .node = node.data.nodes[0] });
                try local_queue.append(.{ .text = "?." });
                try local_queue.append(.{ .node = node.data.nodes[1] });
            },
            .array_literal => {
                try local_queue.append(.{ .text = "[" });
                if (node.data.nodes.len > 0) {
                    try local_queue.append(.{ .node = node.data.nodes[0] });
                    for (node.data.nodes[1..]) |decl_node| {
                        try local_queue.append(.{ .text = ", " });
                        try local_queue.append(.{ .node = decl_node });
                    }
                }
                try local_queue.append(.{ .text = "]" });
            },
            .index_access => {
                try local_queue.append(.{ .node = node.data.nodes[0] });
                try local_queue.append(.{ .text = "[" });
                try local_queue.append(.{ .node = node.data.nodes[1] });
                try local_queue.append(.{ .text = "]" });
            },
            .eq => {
                try local_queue.append(.{ .node = node.data.nodes[0] });
                try local_queue.append(.{ .text = " == " });
                try local_queue.append(.{ .node = node.data.nodes[1] });
            },
            .eqq => {
                try local_queue.append(.{ .node = node.data.nodes[0] });
                try local_queue.append(.{ .text = " === " });
                try local_queue.append(.{ .node = node.data.nodes[1] });
            },
            .neq => {
                try local_queue.append(.{ .node = node.data.nodes[0] });
                try local_queue.append(.{ .text = " != " });
                try local_queue.append(.{ .node = node.data.nodes[1] });
            },
            .neqq => {
                try local_queue.append(.{ .node = node.data.nodes[0] });
                try local_queue.append(.{ .text = " !== " });
                try local_queue.append(.{ .node = node.data.nodes[1] });
            },
            .@"and" => {
                try local_queue.append(.{ .node = node.data.nodes[0] });
                try local_queue.append(.{ .text = " && " });
                try local_queue.append(.{ .node = node.data.nodes[1] });
            },
            .@"or" => {
                try local_queue.append(.{ .node = node.data.nodes[0] });
                try local_queue.append(.{ .text = " || " });
                try local_queue.append(.{ .node = node.data.nodes[1] });
            },
            .gt => {
                try local_queue.append(.{ .node = node.data.nodes[0] });
                try local_queue.append(.{ .text = " > " });
                try local_queue.append(.{ .node = node.data.nodes[1] });
            },
            .gte => {
                try local_queue.append(.{ .node = node.data.nodes[0] });
                try local_queue.append(.{ .text = " >= " });
                try local_queue.append(.{ .node = node.data.nodes[1] });
            },
            .lt => {
                try local_queue.append(.{ .node = node.data.nodes[0] });
                try local_queue.append(.{ .text = " < " });
                try local_queue.append(.{ .node = node.data.nodes[1] });
            },
            .lte => {
                try local_queue.append(.{ .node = node.data.nodes[0] });
                try local_queue.append(.{ .text = " <= " });
                try local_queue.append(.{ .node = node.data.nodes[1] });
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

// test {
//     var left = ASTNode{
//         .tag = .number,
//         .data_type = .{ .any = {} },
//         .data = .{ .literal = "1" },
//     };
//     var right = ASTNode{
//         .tag = .number,
//         .data_type = .{ .any = {} },
//         .data = .{ .literal = "2" },
//     };
//     var node = ASTNode{
//         .tag = .plus_expr,
//         .data_type = .{ .any = {} },
//         .data = .{
//             .nodes = @constCast(&[_]*ASTNode{
//                 &left,
//                 &right,
//             }),
//         },
//     };
//
//     var queue = WorkerQueue{
//         .allocator = std.heap.page_allocator,
//     };
//     try queue.prepend(.{ .node = &node });
//
//     var output = std.ArrayList(u8).init(std.heap.page_allocator);
//     defer output.deinit();
//
//     while (queue.popFirst()) |item| {
//         var local_queue = WorkerQueue{
//             .allocator = std.heap.page_allocator,
//         };
//
//         if (item.data == .text) {
//             try output.appendSlice(item.data.text);
//             continue;
//         }
//
//         switch (item.data.node.tag) {
//             .plus_expr => {
//                 try local_queue.append(.{ .node = item.data.node.data.nodes[0] });
//                 try local_queue.append(.{ .text = " + " });
//                 try local_queue.append(.{ .node = item.data.node.data.nodes[1] });
//             },
//             .number => {
//                 try local_queue.append(.{ .text = item.data.node.data.literal });
//             },
//             else => {
//                 try local_queue.append(.{ .text = "Unknown node type" });
//             },
//         }
//
//         queue.prependMany(&local_queue);
//     }
//
//     std.debug.print("\n\noutput: {s}\n", .{output.items});
// }
