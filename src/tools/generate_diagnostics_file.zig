const std = @import("std");
const json = std.json;

const diagnosticMessages = @embedFile("./diagnosticMessages.json");

const DiagnosticMessage = struct {
    slug: []const u8,
    message: []const u8,
    category: []const u8,
    code: []const u8,
    elided_in_compatability_pyramid: bool,
};
const DiagnosticMessages = std.DoublyLinkedList(DiagnosticMessage);
const DiagnosticMessagesNode = DiagnosticMessages.Node;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    var message_names = std.StringHashMap(bool).init(allocator);
    defer message_names.deinit();

    std.log.info("CWD: {s}", .{try std.fs.cwd().realpathAlloc(allocator, ".")});
    const output_file = try std.fs.cwd().createFile("src/diagnostics.zig", std.fs.File.CreateFlags{
        .truncate = true,
    });
    defer output_file.close();

    var scanner = json.Scanner.initCompleteInput(allocator, diagnosticMessages);
    defer scanner.deinit();

    var messages = DiagnosticMessages{};

    _ = try scanner.next();

    while (true) {
        const token = try scanner.nextAlloc(allocator, .alloc_always);

        if (token == .end_of_document or token == .object_end) {
            break;
        }

        var msg = DiagnosticMessage{
            .slug = try strToSlug(allocator, &message_names, token.allocated_string),
            .message = token.allocated_string,
            .category = "",
            .code = "",
            .elided_in_compatability_pyramid = false,
        };
        // object begin
        _ = try scanner.next();
        while (true) {
            const key_token = try scanner.nextAlloc(allocator, .alloc_always);
            if (key_token == .object_end) {
                break;
            }
            const value_token = try scanner.nextAlloc(allocator, .alloc_always);

            if (std.mem.eql(u8, key_token.allocated_string, "category")) {
                msg.category = value_token.allocated_string;
            } else if (std.mem.eql(u8, key_token.allocated_string, "code")) {
                msg.code = value_token.allocated_number;
            } else if (std.mem.eql(u8, key_token.allocated_string, "elidedInCompatabilityPyramid")) {
                msg.elided_in_compatability_pyramid = value_token == .true;
            }
        }

        var node = try allocator.create(DiagnosticMessagesNode);
        node.data = msg;
        messages.append(node);
    }

    try output_file.writeAll(
        \\const std = @import("std");
        \\
        \\pub const DiagnosticMessage = struct {
        \\    message: []const u8,
        \\    category: []const u8,
        \\    code: []const u8,
        \\};
        \\
    );

    while (messages.popFirst()) |message| {
        std.log.info("{s}: {s}", .{ message.data.slug, message.data.message });
        var buffer: [512]u8 = undefined;
        const fmt =
            \\pub const {s} = DiagnosticMessage{{
            \\    .message = "{s}",
            \\    .category = "{s}",
            \\    .code = "{s}",
            \\}};
            \\
        ;
        const new_size = try escapeString(message.data.message, buffer[0..]);
        try std.fmt.format(output_file.writer(), fmt, .{
            message.data.slug,
            buffer[0..new_size],
            message.data.category,
            message.data.code,
        });
    }
}

fn strToSlug(allocator: std.mem.Allocator, message_names: *std.StringHashMap(bool), str: []const u8) ![]const u8 {
    var output = std.ArrayList(u8).init(allocator);
    defer output.deinit();

    var arg_started_at: ?usize = null;
    for (str) |c| {
        if (arg_started_at != null and c == '}') {
            output.items.len = arg_started_at.?;
            arg_started_at = null;
            try output.appendSlice("ARG");
        }

        if (c == '{') {
            arg_started_at = output.items.len;
        }

        if (std.ascii.isAlphanumeric(c)) {
            try output.append(std.ascii.toLower(c));
        } else {
            if (output.items.len > 0 and output.items[output.items.len - 1] != '_') {
                try output.append('_');
            }
        }
    }

    if (output.items.len > 0 and output.items[output.items.len - 1] == '_') {
        _ = output.pop();
    }

    if (message_names.get(output.items) != null or std.zig.Token.getKeyword(output.items) != null or std.zig.isPrimitive(output.items)) {
        var index: usize = 1;
        const old_size = output.items.len;
        try output.writer().print("_{d}", .{index});

        while (message_names.get(output.items)) |_| {
            output.items.len = old_size;
            index += 1;
            try output.writer().print("_{d}", .{index});
        }
    }

    try message_names.put(output.items, true);

    return try output.toOwnedSlice();
}

fn escapeString(input: []const u8, output: []u8) !usize {
    var buf: [32]u8 = undefined;
    var slide: usize = 0;
    var i: usize = 0;
    while (slide < input.len) {
        if (input[slide] == '"') {
            @memcpy(output[i..][0..2], "\\\"");
            i += 2;
            slide += 1;
        } else if (input[slide] == '\\') {
            @memcpy(output[i..][0..2], "\\\\");
            i += 2;
            slide += 1;
        } else if (input[slide] == '{') {
            if (input.len > slide + 2 and input[slide + 2] == '}') {
                const ret = try std.fmt.bufPrint(&buf, "{{{c}s}}", .{input[slide + 1]});
                @memcpy(output[i..][0..ret.len], ret);
                i += 4;
                slide += 3;
            } else {
                @memcpy(output[i..][0..2], "{{");
                i += 2;
                slide += 1;
            }
        } else {
            output[i] = input[slide];
            i += 1;
            slide += 1;
        }
    }

    return i;
}
