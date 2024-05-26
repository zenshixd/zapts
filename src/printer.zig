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
        try printNode(output.writer(), statement, 1);
        if (needsSemicolon(statement)) {
            try output.appendSlice(";");
        }
        try output.appendSlice(new_line_char);
    }

    return output.toOwnedSlice();
}

fn printNode(writer: anytype, node: *ASTNode, indent: usize) !void {
    const tag: ASTNodeTag = node.tag;
    switch (tag) {
        .import => {
            try writer.writeAll("import ");
            switch (node.data.nodes.len) {
                0 => {},
                1 => try printNode(writer, node.data.nodes[0], indent),
                else => {
                    const nodes = node.data.nodes;
                    try printNode(writer, nodes[0], indent);
                    for (nodes[1..]) |import_node| {
                        if (import_node.tag == .import_path) {
                            try writer.writeAll(" from ");
                            try printNode(writer, import_node, indent);
                            break;
                        }

                        try writer.writeAll(", ");
                        try printNode(writer, import_node, indent);
                    }
                },
            }
        },
        .import_named_bindings => {
            try writer.writeAll("{");
            try printNode(writer, node.data.nodes[0], indent);
            for (node.data.nodes[1..]) |import_node| {
                try writer.writeAll(",");
                try printNode(writer, import_node, indent);
            }
            try writer.writeAll("}");
        },
        .import_binding_named, .import_binding_default => {
            try writer.writeAll(node.data.literal);
        },
        .import_binding_namespace => {
            try writer.writeAll("* as ");
            try writer.writeAll(node.data.literal);
        },
        .import_type_binding_default, .import_type_binding_named, .import_type_binding_namespace => {},
        .import_path => {
            try writer.writeAll(node.data.literal);
        },
        .var_decl => {
            try writer.writeAll("var ");
            try printNode(writer, node.data.nodes[0], indent);

            for (node.data.nodes[1..]) |decl_node| {
                try writer.writeAll(", ");
                try printNode(writer, decl_node, indent);
            }
        },
        .const_decl => {
            try writer.writeAll("const ");
            try printNode(writer, node.data.nodes[0], indent);

            for (node.data.nodes[1..]) |decl_node| {
                try writer.writeAll(", ");
                try printNode(writer, decl_node, indent);
            }
        },
        .let_decl => {
            try writer.writeAll("let ");
            try printNode(writer, node.data.nodes[0], indent);

            for (node.data.nodes[1..]) |decl_node| {
                try writer.writeAll(", ");
                try printNode(writer, decl_node, indent);
            }
        },
        .async_func_decl => {
            try writer.writeAll("async function ");
            try printNode(writer, node.data.nodes[0], indent);
            try writer.writeAll("(");
            if (node.data.nodes.len > 2) {
                try printNode(writer, node.data.nodes[1], indent);
                for (node.data.nodes[2 .. node.data.nodes.len - 1]) |arg| {
                    try writer.writeAll(",");
                    try printNode(writer, arg, indent);
                }
            }
            try writer.writeAll(") ");
            try printNode(writer, node.data.nodes[node.data.nodes.len - 1], indent);
        },
        .func_decl => {
            try writer.writeAll("function ");
            try printNode(writer, node.data.nodes[0], indent);
            try writer.writeAll("(");
            if (node.data.nodes.len > 2) {
                try printNode(writer, node.data.nodes[1], indent);
                for (node.data.nodes[2 .. node.data.nodes.len - 1]) |arg| {
                    try writer.writeAll(", ");
                    try printNode(writer, arg, indent);
                }
            }
            try writer.writeAll(") ");
            try printNode(writer, node.data.nodes[node.data.nodes.len - 1], indent);
        },
        .func_decl_name => {
            try writer.writeAll(node.data.literal);
        },
        .func_decl_argument => {
            try writer.writeAll(node.data.literal);
        },
        .block => {
            try writer.writeAll("{");
            if (node.data.nodes.len > 0) {
                try writeNewLine(writer);
                try printIndent(writer, indent);
                try printNode(writer, node.data.nodes[0], indent);
                if (needsSemicolon(node.data.nodes[0])) {
                    try writer.writeAll(";");
                }
                try writeNewLine(writer);
                for (node.data.nodes[1..]) |stmt| {
                    try printIndent(writer, indent);
                    try printNode(writer, stmt, indent + 1);
                    if (needsSemicolon(stmt)) {
                        try writer.writeAll(";");
                    }
                    try writeNewLine(writer);
                }
            }
            try writer.writeAll("}");
        },
        .call_expr => {
            try printNode(writer, node.data.nodes[0], indent);
            try writer.writeAll("(");
            if (node.data.nodes.len > 1) {
                try printNode(writer, node.data.nodes[1], indent);
                for (node.data.nodes[2..]) |arg| {
                    try writer.writeAll(", ");
                    try printNode(writer, arg, indent);
                }
            }
            try writer.writeAll(")");
        },
        .comma => {
            try printNode(writer, node.data.binary.left, indent);
            try writer.writeAll(", ");
            try printNode(writer, node.data.binary.right, indent);
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
            try printNode(writer, node.data.node, indent);
            try writer.writeAll(")");
        },
        .assignment => {
            try printNode(writer, node.data.binary.left, indent);
            try writer.writeAll(" = ");
            try printNode(writer, node.data.binary.right, indent);
        },
        .plus_assign => {
            try printNode(writer, node.data.binary.left, indent);
            try writer.writeAll(" += ");
            try printNode(writer, node.data.binary.right, indent);
        },
        .minus_assign => {
            try printNode(writer, node.data.binary.left, indent);
            try writer.writeAll(" -= ");
            try printNode(writer, node.data.binary.right, indent);
        },
        .multiply_assign => {
            try printNode(writer, node.data.binary.left, indent);
            try writer.writeAll(" *= ");
            try printNode(writer, node.data.binary.right, indent);
        },
        .div_assign => {
            try printNode(writer, node.data.binary.left, indent);
            try writer.writeAll(" /= ");
            try printNode(writer, node.data.binary.right, indent);
        },
        .modulo_assign => {
            try printNode(writer, node.data.binary.left, indent);
            try writer.writeAll(" %= ");
            try printNode(writer, node.data.binary.right, indent);
        },
        .exp_assign => {
            try printNode(writer, node.data.binary.left, indent);
            try writer.writeAll(" **= ");
            try printNode(writer, node.data.binary.right, indent);
        },
        .and_assign => {
            try printNode(writer, node.data.binary.left, indent);
            try writer.writeAll(" &= ");
            try printNode(writer, node.data.binary.right, indent);
        },
        .or_assign => {
            try printNode(writer, node.data.binary.left, indent);
            try writer.writeAll(" |= ");
            try printNode(writer, node.data.binary.right, indent);
        },
        .bitwise_and_assign => {
            try printNode(writer, node.data.binary.left, indent);
            try writer.writeAll(" &= ");
            try printNode(writer, node.data.binary.right, indent);
        },
        .bitwise_or_assign => {
            try printNode(writer, node.data.binary.left, indent);
            try writer.writeAll(" |= ");
            try printNode(writer, node.data.binary.right, indent);
        },
        .bitwise_xor_assign => {
            try printNode(writer, node.data.binary.left, indent);
            try writer.writeAll(" ^= ");
            try printNode(writer, node.data.binary.right, indent);
        },
        .bitwise_shift_left_assign => {
            try printNode(writer, node.data.binary.left, indent);
            try writer.writeAll(" <<= ");
            try printNode(writer, node.data.binary.right, indent);
        },
        .bitwise_shift_right_assign => {
            try printNode(writer, node.data.binary.left, indent);
            try writer.writeAll(" >>= ");
            try printNode(writer, node.data.binary.right, indent);
        },
        .bitwise_unsigned_right_shift_assign => {
            try printNode(writer, node.data.binary.left, indent);
            try writer.writeAll(" >>>= ");
            try printNode(writer, node.data.binary.right, indent);
        },
        .plusplus => {
            try printNode(writer, node.data.node, indent);
            try writer.writeAll("++");
        },
        .minusminus => {
            try printNode(writer, node.data.node, indent);
            try writer.writeAll("--");
        },
        .not => {
            try writer.writeAll("!");
            try printNode(writer, node.data.node, indent);
        },
        .bitwise_negate => {
            try writer.writeAll("~");
            try printNode(writer, node.data.node, indent);
        },
        .minus => {
            try writer.writeAll("-");
            try printNode(writer, node.data.node, indent);
        },
        .minus_expr => {
            try printNode(writer, node.data.binary.left, indent);
            try writer.writeAll(" - ");
            try printNode(writer, node.data.binary.right, indent);
        },
        .plus => {
            try writer.writeAll("+");
            try printNode(writer, node.data.node, indent);
        },
        .plus_expr => {
            try printNode(writer, node.data.binary.left, indent);
            try writer.writeAll(" + ");
            try printNode(writer, node.data.binary.right, indent);
        },
        .multiply_expr => {
            try printNode(writer, node.data.binary.left, indent);
            try writer.writeAll(" * ");
            try printNode(writer, node.data.binary.right, indent);
        },
        .exp_expr => {
            try printNode(writer, node.data.binary.left, indent);
            try writer.writeAll(" ** ");
            try printNode(writer, node.data.binary.right, indent);
        },
        .div_expr => {
            try printNode(writer, node.data.binary.left, indent);
            try writer.writeAll(" / ");
            try printNode(writer, node.data.binary.right, indent);
        },
        .modulo_expr => {
            try printNode(writer, node.data.binary.left, indent);
            try writer.writeAll(" % ");
            try printNode(writer, node.data.binary.right, indent);
        },
        .bitwise_and => {
            try printNode(writer, node.data.binary.left, indent);
            try writer.writeAll(" & ");
            try printNode(writer, node.data.binary.right, indent);
        },
        .bitwise_or => {
            try printNode(writer, node.data.binary.left, indent);
            try writer.writeAll(" | ");
            try printNode(writer, node.data.binary.right, indent);
        },
        .bitwise_xor => {
            try printNode(writer, node.data.binary.left, indent);
            try writer.writeAll(" ^ ");
            try printNode(writer, node.data.binary.right, indent);
        },
        .bitwise_shift_left => {
            try printNode(writer, node.data.binary.left, indent);
            try writer.writeAll(" << ");
            try printNode(writer, node.data.binary.right, indent);
        },
        .bitwise_shift_right => {
            try printNode(writer, node.data.binary.left, indent);
            try writer.writeAll(" >> ");
            try printNode(writer, node.data.binary.right, indent);
        },
        .bitwise_unsigned_right_shift => {
            try printNode(writer, node.data.binary.left, indent);
            try writer.writeAll(" >>> ");
            try printNode(writer, node.data.binary.right, indent);
        },
        .instanceof => {
            try printNode(writer, node.data.binary.left, indent);
            try writer.writeAll(" instanceof ");
            try printNode(writer, node.data.binary.right, indent);
        },
        .in => {
            try printNode(writer, node.data.binary.left, indent);
            try writer.writeAll(" in ");
            try printNode(writer, node.data.binary.right, indent);
        },
        .spread => {
            try writer.writeAll("...");
            try printNode(writer, node.data.node, indent);
        },
        .typeof => {
            try writer.writeAll("typeof ");
            try printNode(writer, node.data.node, indent);
        },
        .object_literal => {
            try writer.writeAll("{");
            try writeNewLine(writer);
            try printIndent(writer, indent);
            try printNode(writer, node.data.nodes[0], indent);
            for (node.data.nodes[1..]) |decl_node| {
                try writer.writeAll(",");
                try writeNewLine(writer);
                try printIndent(writer, indent);
                try printNode(writer, decl_node, indent);
            }
            try writeNewLine(writer);
            try printIndent(writer, indent - 1);
            try writer.writeAll("}");
        },
        .object_literal_field => {
            try printNode(writer, node.data.binary.left, indent);
            try writer.writeAll(": ");
            try printNode(writer, node.data.binary.right, indent);
        },
        .object_literal_field_shorthand => {
            try printNode(writer, node.data.node, indent);
        },
        .property_access => {
            try printNode(writer, node.data.binary.left, indent);
            try writer.writeAll(".");
            try printNode(writer, node.data.binary.right, indent);
        },
        .optional_property_access => {
            try printNode(writer, node.data.binary.left, indent);
            try writer.writeAll("?.");
            try printNode(writer, node.data.binary.right, indent);
        },
        .array_literal => {
            try writer.writeAll("[");
            if (node.data.nodes.len > 0) {
                try printNode(writer, node.data.nodes[0], indent);
                for (node.data.nodes[1..]) |decl_node| {
                    try writer.writeAll(", ");
                    try printNode(writer, decl_node, indent);
                }
            }
            try writer.writeAll("]");
        },
        .index_access => {
            try printNode(writer, node.data.binary.left, indent);
            try writer.writeAll("[");
            try printNode(writer, node.data.binary.right, indent);
            try writer.writeAll("]");
        },
        .eq => {
            try printNode(writer, node.data.binary.left, indent);
            try writer.writeAll(" == ");
            try printNode(writer, node.data.binary.right, indent);
        },
        .eqq => {
            try printNode(writer, node.data.binary.left, indent);
            try writer.writeAll(" === ");
            try printNode(writer, node.data.binary.right, indent);
        },
        .neq => {
            try printNode(writer, node.data.binary.left, indent);
            try writer.writeAll(" != ");
            try printNode(writer, node.data.binary.right, indent);
        },
        .neqq => {
            try printNode(writer, node.data.binary.left, indent);
            try writer.writeAll(" !== ");
            try printNode(writer, node.data.binary.right, indent);
        },
        .@"and" => {
            try printNode(writer, node.data.binary.left, indent);
            try writer.writeAll(" && ");
            try printNode(writer, node.data.binary.right, indent);
        },
        .@"or" => {
            try printNode(writer, node.data.binary.left, indent);
            try writer.writeAll(" || ");
            try printNode(writer, node.data.binary.right, indent);
        },
        .gt => {
            try printNode(writer, node.data.binary.left, indent);
            try writer.writeAll(" > ");
            try printNode(writer, node.data.binary.right, indent);
        },
        .gte => {
            try printNode(writer, node.data.binary.left, indent);
            try writer.writeAll(" >= ");
            try printNode(writer, node.data.binary.right, indent);
        },
        .lt => {
            try printNode(writer, node.data.binary.left, indent);
            try writer.writeAll(" < ");
            try printNode(writer, node.data.binary.right, indent);
        },
        .lte => {
            try printNode(writer, node.data.binary.left, indent);
            try writer.writeAll(" <= ");
            try printNode(writer, node.data.binary.right, indent);
        },
    }
}

fn printIndent(writer: anytype, indent: usize) !void {
    for (0..indent) |_| {
        try writer.writeAll("    ");
    }
}

fn writeNewLine(writer: anytype) !void {
    try writer.writeAll(new_line_char);
}
