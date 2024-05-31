const std = @import("std");
const builtin = @import("builtin");
const io = std.io;
const Lexer = @import("./lexer.zig");
const Parser = @import("./parser.zig");
const compile = @import("./compile.zig").compile;
const CompileResult = @import("./compile.zig").CompileResult;
const JdzGlobalAllocator = @import("jdz_allocator").JdzGlobalAllocator;
const Client = std.http.Client;

const MAX_FILE_SIZE = 1024 * 1024 * 1024;
const REF_TESTS_DIR = ".reftests";
const TS_VERSION = "5.4.5";

var log_err_count: usize = 0;

const compile_tests_path = "compiler" ++ std.fs.path.sep_str;
const conformance_tests_path = "conformance" ++ std.fs.path.sep_str;

pub fn main() void {
    std.debug.attachSegfaultHandler();

    const allocator = std.heap.c_allocator;

    const args = std.process.argsAlloc(allocator) catch @panic("Cannot get args. OOM?");
    defer std.process.argsFree(allocator, args);

    const case_file_filter = if (args.len > 1) args[1] else null;
    const cases_list = getRefTestCases(allocator, case_file_filter) catch @panic("Failed to get reference test files");
    defer {
        for (cases_list) |case| {
            allocator.free(case);
        }
        allocator.free(cases_list);
    }

    var ok_count: usize = 0;
    var skip_count: usize = 0;
    _ = &skip_count;
    var fail_count: usize = 0;
    var progress = std.Progress{
        .dont_print_on_dumb = true,
    };
    const root_node = progress.start("Test", cases_list.len);
    const have_tty = progress.terminal != null and
        (progress.supports_ansi_escape_codes or progress.is_windows_terminal);

    const leaks: usize = 0;
    for (cases_list, 0..) |case, i| {
        std.testing.log_level = .warn;

        var test_node = root_node.start(case, 0);
        test_node.activate();
        progress.refresh();
        if (!have_tty) {
            std.debug.print("{d}/{d} {s}... ", .{ i + 1, cases_list.len, case });
        }
        if (runRefTest(allocator, case)) |_| {
            ok_count += 1;
            test_node.end();
            if (!have_tty) std.debug.print("OK\n", .{});
        } else |err| switch (err) {
            // error.SkipZigTest => {
            //     skip_count += 1;
            //     progress.log("SKIP\n", .{});
            //     test_node.end();
            // },
            else => {
                fail_count += 1;
                progress.log("FAIL ({s})\n", .{@errorName(err)});
                // if (@errorReturnTrace()) |trace| {
                //     std.debug.dumpStackTrace(trace.*);
                // }
                test_node.end();
            },
        }
    }
    root_node.end();
    if (ok_count == cases_list.len) {
        std.debug.print("All {d} tests passed.\n", .{ok_count});
    } else {
        std.debug.print("{d} passed; {d} skipped; {d} failed.\n", .{ ok_count, skip_count, fail_count });
    }
    if (log_err_count != 0) {
        std.debug.print("{d} errors were logged.\n", .{log_err_count});
    }
    if (leaks != 0) {
        std.debug.print("{d} tests leaked memory.\n", .{leaks});
    }
    if (leaks != 0 or log_err_count != 0 or fail_count != 0) {
        std.process.exit(1);
    }
}

fn initRefTestsDir(allocator: std.mem.Allocator) !void {
    var client = Client{
        .allocator = allocator,
    };
    defer client.deinit();

    var arr = std.ArrayList(u8).init(allocator);
    defer arr.deinit();

    var tarArr = std.ArrayList(u8).init(allocator);
    defer tarArr.deinit();

    const url = try std.fmt.allocPrint(allocator, "https://github.com/microsoft/TypeScript/archive/refs/tags/v{s}.tar.gz", .{TS_VERSION});
    defer allocator.free(url);

    std.debug.print("Downloading repository {s} ...\n", .{url});
    const res = try client.fetch(.{
        .method = .GET,
        .response_storage = .{ .dynamic = &arr },
        .max_append_size = 100 * 1024 * 1024 * 1024,
        .location = .{
            .url = url,
        },
    });

    std.debug.print("Status: {}. Unpacking tests to {s}/ directory ...\n", .{ res.status, REF_TESTS_DIR });
    var fb = std.io.fixedBufferStream(arr.items);
    try std.compress.gzip.decompress(fb.reader(), tarArr.writer());

    fb = std.io.fixedBufferStream(tarArr.items);

    var file_name: [std.fs.MAX_PATH_BYTES]u8 = undefined;
    var link_name: [std.fs.MAX_PATH_BYTES]u8 = undefined;
    var iter = std.tar.iterator(fb.reader(), .{ .file_name_buffer = &file_name, .link_name_buffer = &link_name });

    const first_file = try iter.next();
    const bytes_to_skip = first_file.?.name.len;
    var output_dir = try std.fs.cwd().openDir(REF_TESTS_DIR, .{});
    defer output_dir.close();

    var tests_count: u32 = 0;
    while (try iter.next()) |entry| {
        const real_path = entry.name[bytes_to_skip..];
        if (std.mem.startsWith(u8, real_path, "tests/")) {
            switch (entry.kind) {
                .file => {
                    const file = try output_dir.createFile(real_path, .{});
                    const buffer = try entry.reader().readAllAlloc(allocator, MAX_FILE_SIZE);
                    defer allocator.free(buffer);
                    try file.writeAll(buffer);
                    tests_count += 1;
                },
                .directory => {
                    try output_dir.makePath(real_path);
                },
                else => {},
            }
        }
    }

    std.debug.print("Files extracted: {d}\n", .{tests_count});
}

pub fn getRefTestCases(allocator: std.mem.Allocator, filter: ?[]const u8) ![][]const u8 {
    std.fs.cwd().access(REF_TESTS_DIR, .{}) catch |err| {
        if (err == error.FileNotFound) {
            std.debug.print("Creating {s} directory ...\n", .{REF_TESTS_DIR});
            try std.fs.cwd().makePath(REF_TESTS_DIR);
            try initRefTestsDir(allocator);
        } else {
            return err;
        }
    };

    var result = std.ArrayList([]const u8).init(allocator);
    defer result.deinit();

    const cases_dir_path = try std.fmt.allocPrint(allocator, "{s}/tests/cases", .{REF_TESTS_DIR});
    defer allocator.free(cases_dir_path);

    var cases_dir = try std.fs.cwd().openDir(cases_dir_path, .{
        .iterate = true,
    });
    defer cases_dir.close();

    var walker = try cases_dir.walk(allocator);
    defer walker.deinit();

    while (try walker.next()) |entry| {
        if (entry.kind == .file) {
            const is_compiler_test = std.mem.startsWith(u8, entry.path, compile_tests_path);
            const is_conformance_test = std.mem.startsWith(u8, entry.path, conformance_tests_path);
            const is_filter_match = if (filter) |filter_str| std.mem.startsWith(u8, filter_str, entry.path) else true;

            if (is_filter_match and (is_compiler_test or is_conformance_test)) {
                try result.append(try allocator.dupe(u8, entry.path));
            }
        }
    }

    return result.toOwnedSlice();
}

pub fn runRefTest(allocator: std.mem.Allocator, case_file: []const u8) !void {
    const full_case_filepath = try std.fmt.allocPrint(allocator, "{s}/tests/cases/{s}", .{ REF_TESTS_DIR, case_file });
    defer allocator.free(full_case_filepath);

    const result = try compile(allocator, full_case_filepath);
    defer allocator.free(result.file_name);
    defer allocator.free(result.output);

    try checkCompileOutput(allocator, result);
}

fn checkCompileOutput(allocator: std.mem.Allocator, compile_result: CompileResult) !void {
    const file_path = try std.fmt.allocPrint(
        allocator,
        "{s}/tests/baselines/reference/{s}",
        .{ REF_TESTS_DIR, std.fs.path.basename(compile_result.file_name) },
    );
    defer allocator.free(file_path);

    const file = std.fs.cwd().openFile(file_path, .{}) catch |err| {
        std.log.info("Reference output file not found: {s}", .{file_path});
        return err;
    };
    defer file.close();

    var content = std.ArrayList(u8).init(allocator);
    defer content.deinit();

    try content.ensureTotalCapacity(MAX_FILE_SIZE);

    const js_output_start = try std.fmt.allocPrint(allocator, "//// [{s}]", .{std.fs.path.basename(compile_result.file_name)});
    defer allocator.free(js_output_start);

    var expected_output_started = false;
    var line_buffer: [1024]u8 = undefined;
    while (try file.reader().readUntilDelimiterOrEof(&line_buffer, '\n')) |line| {
        if (std.mem.startsWith(u8, line, js_output_start)) {
            expected_output_started = true;
            continue;
        }

        if (expected_output_started) {
            try content.appendSlice(line);
            try content.append('\n');
        }
    }

    const expected = try content.toOwnedSlice();
    defer allocator.free(expected);

    try std.testing.expectEqualStrings(expected, compile_result.output);
}

test {
    try runRefTest("compiler/anyPlusAny1.ts");
}
