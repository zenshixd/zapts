const std = @import("std");
const path = std.fs.path;

const compile = @import("../compile.zig").compile;

const expect = std.testing.expect;
const expectEqualStrings = std.testing.expectEqualStrings;

const JS_OUTPUT_START = "//// [";

fn parseExpects(allocator: std.mem.Allocator, case_file: []const u8) !std.StringHashMap([]const u8) {
    const expect_file_name = try std.mem.replaceOwned(u8, allocator, case_file, ".ts", ".js");
    defer allocator.free(expect_file_name);

    const filename = try path.join(allocator, &[_][]const u8{
        "src",
        "tests",
        "compiler",
        "expected",
        expect_file_name,
    });
    defer allocator.free(filename);

    const file = try std.fs.cwd().openFile(filename, .{ .mode = .read_only });
    defer file.close();

    var expects_map = std.StringHashMap([]const u8).init(allocator);

    var line_buffer: [1024]u8 = undefined;
    var output_content: std.ArrayList(u8) = std.ArrayList(u8).init(allocator);
    var output_name: ?[]const u8 = null;
    while (try file.reader().readUntilDelimiterOrEof(&line_buffer, '\n')) |line| {
        if (std.mem.startsWith(u8, line, JS_OUTPUT_START)) {
            if (output_name) |name| {
                try expects_map.put(name, try output_content.toOwnedSlice());

                output_name = null;
            }

            const output_name_end = std.mem.indexOfScalar(u8, line, ']') orelse @panic("Missing ']' in output name");

            output_name = try allocator.dupe(u8, line[JS_OUTPUT_START.len..output_name_end]);
            continue;
        }

        if (output_name != null) {
            try output_content.appendSlice(line);
            try output_content.append('\n');
        }
    }

    if (output_name) |name| {
        try expects_map.put(name, try output_content.toOwnedSlice());
    }

    return expects_map;
}

pub fn runTest(allocator: std.mem.Allocator, case_file: []const u8) !void {
    std.testing.log_level = .debug;
    const filename = try path.join(allocator, &[_][]const u8{
        "src",
        "tests",
        "compiler",
        "cases",
        case_file,
    });
    defer allocator.free(filename);

    const result = try compile(allocator, filename);
    defer allocator.free(result.output);
    defer allocator.free(result.file_name);

    var expects_map = try parseExpects(allocator, case_file);
    defer {
        var it = expects_map.iterator();
        while (it.next()) |entry| {
            allocator.free(entry.key_ptr.*);
            allocator.free(entry.value_ptr.*);
        }
        expects_map.deinit();
    }

    const resultFilename = path.basename(result.file_name);
    const expected_output = expects_map.get(resultFilename);
    try expect(expected_output != null);
    try expectEqualStrings(expected_output.?, result.output);
}

pub fn getTestCases(allocator: std.mem.Allocator) ![]const []const u8 {
    var dir = try std.fs.cwd().openDir("src/tests/compiler/cases", .{
        .iterate = true,
    });
    defer dir.close();

    var cases = std.ArrayList([]const u8).init(allocator);
    defer cases.deinit();

    var it = dir.iterate();
    while (try it.next()) |entry| {
        if (std.mem.endsWith(u8, entry.name, ".ts")) {}
        try cases.append(try allocator.dupe(u8, entry.name));
    }
    return try cases.toOwnedSlice();
}
