const std = @import("std");
const Lexer = @import("lexer.zig");
const Parser = @import("parser.zig");
const print = @import("printer.zig").print;

const fs = std.fs;
const ArrayList = std.ArrayList;

// 10 MB ?
pub const MAX_FILE_SIZE = 10 * 1024 * 1024;

pub const CompileResult = struct {
    file_name: []const u8,
    source: []const u8,
    output: []const u8,
};

pub fn compile(allocator: std.mem.Allocator, filename: []const u8) !CompileResult {
    fs.cwd().access(filename, .{ .mode = .read_only }) catch |err| {
        std.log.info("Access error {}!", .{err});
        return err;
    };

    var file = try fs.cwd().openFile(filename, .{ .mode = .read_only });
    defer file.close();

    const buffer = try file.readToEndAlloc(allocator, MAX_FILE_SIZE);

    return try compileBuffer(allocator, filename, buffer);
}

pub fn compileBuffer(allocator: std.mem.Allocator, filename: []const u8, buffer: []const u8) !CompileResult {
    var parser = try Parser.init(allocator, buffer);
    defer parser.deinit();

    const nodes = parser.parse() catch |err| {
        std.log.info("Parse error: {}", .{err});
        for (parser.errors.items) |parser_error| {
            std.log.info("Error: {s}", .{parser_error});
        }
        return err;
    };

    // var next = nodes.first;
    // while (next) |node| {
    //     std.debug.print("{}\n", .{node});
    //     next = node.next;
    // }

    for (parser.errors.items) |parser_error| {
        std.debug.print("Error: {s}\n", .{parser_error});
    }

    const output = try print(allocator, nodes);

    return .{
        .file_name = try getOutputFile(allocator, filename),
        .source = buffer,
        .output = output,
    };
}

fn getOutputFile(allocator: std.mem.Allocator, filename: []const u8) ![]const u8 {
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
