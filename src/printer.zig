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
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();

    while (statements.popFirst()) |statement| {
        try printNode(arena.allocator(), output.writer(), statement);
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

fn printNode(allocator: std.mem.Allocator, writer: anytype, first_node: *ASTNode) anyerror!void {
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
            .@"export" => {
                try writer.writeAll("export ");
                try local_queue.append(.{ .node = node.data.node });
            },
            .export_from => {
                try local_queue.append(.{ .node = node.data.binary.left });

                if (node.data.binary.right.tag != .none) {
                    try local_queue.append(.{ .node = node.data.binary.right });
                }
            },
            .export_from_all => {
                try writer.writeAll("*");
            },
            .export_from_all_as => {
                try writer.writeAll("* as ");
                try writer.writeAll(node.data.literal);
            },
            .export_named => {
                try writer.writeAll("{ ");
                if (node.data.nodes.len > 0) {
                    try local_queue.append(.{ .node = node.data.nodes.popFirst().? });
                    while (node.data.nodes.popFirst()) |export_node| {
                        try local_queue.append(.{ .text = ", " });
                        try local_queue.append(.{ .node = export_node });
                    }
                }
                try local_queue.append(.{ .text = " }" });
            },
            .export_named_export, .export_named_alias => {
                try writer.writeAll(node.data.literal);
            },
            .export_named_export_as => {
                try local_queue.append(.{ .node = node.data.binary.left });
                try local_queue.append(.{ .text = " as " });
                try local_queue.append(.{ .node = node.data.binary.right });
            },
            .export_default => {
                try writer.writeAll("export default ");
                try local_queue.append(.{ .node = node.data.node });
            },
            .export_path => {
                try writer.writeAll(" from ");
                try writer.writeAll(node.data.literal);
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
            .async_func_statement, .func_statement => {
                try local_queue.append(.{ .indent = {} });
                if (node.tag == .async_func_statement) {
                    try local_queue.append(.{ .text = "async " });
                }
                try local_queue.append(.{ .text = "function " });
                try local_queue.append(.{ .node = node.data.nodes.popFirst().? });
                try local_queue.append(.{ .text = "(" });
                try local_queue.append(.{ .node = node.data.nodes.popFirst().? });
                try local_queue.append(.{ .text = ") " });
                try local_queue.append(.{ .node = node.data.nodes.popFirst().? });
            },
            .async_func_expr, .func_expr => {
                if (node.tag == .async_func_expr) {
                    try local_queue.append(.{ .text = "async " });
                }
                try local_queue.append(.{ .text = "function " });
                if (node.data.nodes.len >= 3) {
                    try local_queue.append(.{ .node = node.data.nodes.popFirst().? });
                }
                try local_queue.append(.{ .text = "(" });
                try local_queue.append(.{ .node = node.data.nodes.popFirst().? });
                try local_queue.append(.{ .text = ") " });
                try local_queue.append(.{ .node = node.data.nodes.popFirst().? });
            },
            .arrow_function, .async_arrow_function => {
                if (node.tag == .async_arrow_function) {
                    try writer.writeAll("async ");
                }
                if (node.data.binary.left.tag == .callable_arguments) {
                    try local_queue.append(.{ .text = "(" });
                    try local_queue.append(.{ .node = node.data.binary.left });
                    try local_queue.append(.{ .text = ")" });
                } else {
                    try local_queue.append(.{ .node = node.data.binary.left });
                }
                try local_queue.append(.{ .text = " => " });
                try local_queue.append(.{ .node = node.data.binary.right });
            },
            .callable_arguments => {
                if (node.data.nodes.len > 0) {
                    try local_queue.append(.{ .node = node.data.nodes.popFirst().? });
                    while (node.data.nodes.popFirst()) |arg| {
                        try local_queue.append(.{ .text = ", " });
                        try local_queue.append(.{ .node = arg });
                    }
                }
            },
            .function_name, .callable_argument => {
                try writer.writeAll(node.data.literal);
            },
            .abstract_class => {
                try local_queue.append(.{ .node = node.data.node });
            },
            .class_decl, .class_expr => {
                try local_queue.append(.{ .text = "class " });
                while (node.data.nodes.popFirst()) |inner| {
                    try local_queue.append(.{ .node = inner });
                }
            },
            .class_name => {
                try writer.writeAll(node.data.literal);
                try local_queue.append(.{ .text = " " });
            },
            .class_super => {
                try writer.writeAll("extends ");
                try local_queue.append(.{ .node = node.data.node });
                try local_queue.append(.{ .text = " " });
            },
            .class_body => {
                try writer.writeAll("{");
                try local_queue.append(.{ .indent_up = {} });
                if (node.data.nodes.len > 0) {
                    try local_queue.append(.{ .text = new_line_char });
                    while (node.data.nodes.popFirst()) |member| {
                        try local_queue.append(.{ .indent = {} });
                        try local_queue.append(.{ .node = member });
                        try local_queue.append(.{ .text = new_line_char });
                    }
                }
                try local_queue.append(.{ .indent_down = {} });
                try local_queue.append(.{ .text = new_line_char ++ "}" });
            },
            .class_field => {
                try local_queue.append(.{ .node = node.data.binary.left });
                if (node.data.binary.right.tag != .none) {
                    try local_queue.append(.{ .text = " = " });
                    try local_queue.append(.{ .node = node.data.binary.right });
                }
                try local_queue.append(.{ .text = ";" });
            },
            .class_static_member => {
                try writer.writeAll("static ");
                try local_queue.append(.{ .node = node.data.node });
            },
            .class_private_member => {
                try writer.writeAll("private ");
                try local_queue.append(.{ .node = node.data.node });
            },
            .class_protected_member => {
                try writer.writeAll("protected ");
                try local_queue.append(.{ .node = node.data.node });
            },
            .class_public_member => {
                try writer.writeAll("public ");
                try local_queue.append(.{ .node = node.data.node });
            },
            .class_static_block => {
                try writer.writeAll("static {");
                while (node.data.nodes.popFirst()) |stmt| {
                    try local_queue.append(.{ .node = stmt });
                }
                try local_queue.append(.{ .text = "}" });
            },
            .ternary => {
                try local_queue.append(.{ .node = node.data.binary.left });
                try local_queue.append(.{ .text = " ? " });
                try local_queue.append(.{ .node = node.data.binary.right });
            },
            .ternary_then => {
                try local_queue.append(.{ .node = node.data.binary.left });
                try local_queue.append(.{ .text = " : " });
                try local_queue.append(.{ .node = node.data.binary.right });
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
                    try local_queue.append(.{ .indent_up = {} });
                    try printStatement(&local_queue, right);
                    try local_queue.append(.{ .indent_down = {} });
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
                    try local_queue.append(.{ .indent_up = {} });
                    try printStatement(&local_queue, right);
                    try local_queue.append(.{ .indent_down = {} });
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
                try local_queue.append(.{ .text = ":" ++ new_line_char });

                try local_queue.append(.{ .indent_up = {} });
                while (node.data.nodes.popFirst()) |stmt| {
                    try printStatement(&local_queue, stmt);
                    try local_queue.append(.{ .text = new_line_char });
                }
                try local_queue.append(.{ .indent_down = {} });
            },
            .default => {
                try writer.writeAll("default: ");
                try local_queue.append(.{ .indent_up = {} });
                while (node.data.nodes.popFirst()) |stmt| {
                    try printStatement(&local_queue, stmt);
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
            .@"return" => {
                try writer.writeAll("return");
                if (node.data == .node) {
                    try local_queue.append(.{ .text = " " });
                    try local_queue.append(.{ .node = node.data.node });
                }
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
                try local_queue.append(.{ .indent_up = {} });
                if (node.data.nodes.len > 0) {
                    try writer.writeAll(new_line_char);
                    try printStatementNL(&local_queue, node.data.nodes.popFirst().?);
                    while (node.data.nodes.popFirst()) |stmt| {
                        try printStatementNL(&local_queue, stmt);
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
                try local_queue.append(.{ .indent_up = {} });
                if (node.data.nodes.len > 0) {
                    try local_queue.append(.{ .text = new_line_char });
                    try local_queue.append(.{ .indent = {} });
                    try local_queue.append(.{ .node = node.data.nodes.popFirst().? });
                    while (node.data.nodes.popFirst()) |decl_node| {
                        try local_queue.append(.{ .text = "," });
                        try local_queue.append(.{ .text = new_line_char });
                        try local_queue.append(.{ .indent = {} });
                        try local_queue.append(.{ .node = decl_node });
                    }
                    try local_queue.append(.{ .text = new_line_char });
                }
                try local_queue.append(.{ .indent_down = {} });
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
            .object_method => {
                try local_queue.append(.{ .node = node.data.nodes.popFirst().? });
                try local_queue.append(.{ .text = "(" });
                try local_queue.append(.{ .node = node.data.nodes.popFirst().? });
                try local_queue.append(.{ .text = ") " });
                try local_queue.append(.{ .node = node.data.nodes.popFirst().? });
            },
            .object_async_method => {
                try writer.writeAll("async ");
                try local_queue.append(.{ .node = node.data.node });
            },
            .object_generator_method => {
                try writer.writeAll("*");
                try local_queue.append(.{ .node = node.data.node });
            },
            .object_getter => {
                try writer.writeAll("get ");
                try local_queue.append(.{ .node = node.data.nodes.popFirst().? });
                try local_queue.append(.{ .text = "(" });
                try local_queue.append(.{ .node = node.data.nodes.popFirst().? });
                try local_queue.append(.{ .text = ") " });
                try local_queue.append(.{ .node = node.data.nodes.popFirst().? });
            },
            .object_setter => {
                try writer.writeAll("set ");
                try local_queue.append(.{ .node = node.data.nodes.popFirst().? });
                try local_queue.append(.{ .text = "(" });
                try local_queue.append(.{ .node = node.data.nodes.popFirst().? });
                try local_queue.append(.{ .text = ") " });
                try local_queue.append(.{ .node = node.data.nodes.popFirst().? });
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

fn printStatement(local_queue: *WorkerQueue, node: *ASTNode) !void {
    try local_queue.append(.{ .indent = {} });
    try local_queue.append(.{ .node = node });
    if (needsSemicolon(node)) {
        try local_queue.append(.{ .text = ";" });
    }
}

fn printStatementNL(local_queue: *WorkerQueue, node: *ASTNode) !void {
    try printStatement(local_queue, node);
    try local_queue.append(.{ .text = new_line_char });
}

fn printDecls(keyword: []const u8, local_queue: *WorkerQueue, node: *ASTNode) !void {
    try local_queue.append(.{ .text = keyword });
    try local_queue.append(.{ .node = node.data.nodes.popFirst().? });
    while (node.data.nodes.popFirst()) |decl_node| {
        try local_queue.append(.{ .text = ", " });
        try local_queue.append(.{ .node = decl_node });
    }
}
