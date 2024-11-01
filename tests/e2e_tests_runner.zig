const std = @import("std");
const assert = std.debug.assert;

const io = std.io;
const path = std.fs.path;
const Client = std.http.Client;
const builtin = @import("builtin");
const zapts = @import("zapts");
const HtmlReporter = @import("./html_reporter.zig");

const expect = std.testing.expect;
const expectEqualStrings = std.testing.expectEqualStrings;

const newline = "\n";
const REF_TESTS_DIR = ".reftests";
const TS_VERSION = "5.4.5";

var log_err_count: usize = 0;

pub fn main() !void {
    var timer = try std.time.Timer.start();

    const allocator = std.testing.allocator;
    defer _ = std.testing.allocator_instance.deinit();

    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();

    const options = try parseArgs(allocator);

    var ok_count: usize = 0;
    var skip_count: usize = 0;
    var fail_count: usize = 0;

    const root_dir = if (options.run_reftests) ".reftests" else "tests";
    const have_tty = std.io.getStdErr().isTty();
    const html_reporter = if (options.html) try HtmlReporter.init(allocator) else null;
    var test_runner = TestRunner{
        .have_tty = have_tty,
        .root_dir = root_dir,
        .update_baselines = options.update_baselines,
        .filter = options.filter,
        .html_reporter = html_reporter,
    };
    const cases = try test_runner.getTestCases(arena.allocator());

    const root_node = std.Progress.start(.{
        .root_name = "Test",
        .estimated_total_items = cases.len,
    });

    var leaks: usize = 0;
    for (cases, 0..) |case_file, i| {
        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        defer {
            if (gpa.deinit() == .leak) {
                leaks += 1;
            }
        }
        std.testing.log_level = .warn;

        var test_node = root_node.start(case_file.filename, 0);
        try test_runner.reportStart(i, cases, case_file);
        if (test_runner.runTest(gpa.allocator(), case_file.filename, case_file.expect_filename)) |result| {
            switch (result) {
                .success => {
                    ok_count += 1;
                    try test_runner.reportSuccess(i, cases, case_file);
                },
                .skip => {
                    skip_count += 1;
                    try test_runner.reportSkip(i, cases, case_file);
                },
                .not_equal => {
                    fail_count += 1;
                    // try test_runner.reportFail(i, cases, case_file, err, null);
                },
            }
        } else |err| {
            fail_count += 1;
            try test_runner.reportFail(i, cases, case_file, err, @errorReturnTrace());
        }
        test_node.end();
    }
    root_node.end();
    if (html_reporter) |reporter| {
        reporter.end();
    }

    const test_duration = timer.read() / std.time.ns_per_ms;
    if (ok_count == cases.len) {
        std.debug.print("All {d} tests passed, took {}ms\n", .{ ok_count, test_duration });
    } else {
        std.debug.print("{d} passed; {d} skipped; {d} failed, took {}ms\n", .{ ok_count, skip_count, fail_count, test_duration });
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

const TestRunnerArgs = struct {
    run_reftests: bool = false,
    update_baselines: bool = false,
    html: bool = false,
    filter: ?[]const u8 = null,
};

fn parseArgs(allocator: std.mem.Allocator) !TestRunnerArgs {
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    var result = TestRunnerArgs{};

    for (args, 0..) |arg, i| {
        if (std.mem.eql(u8, arg, "--reference")) {
            result.run_reftests = true;
        }

        if (std.mem.eql(u8, arg, "--update") or std.mem.eql(u8, arg, "-u")) {
            result.update_baselines = true;
        }

        if (std.mem.eql(u8, arg, "--filter")) {
            result.filter = try allocator.dupe(u8, args[i + 1]);
        }

        if (std.mem.eql(u8, arg, "--html")) {
            result.html = true;
        }
    }

    return result;
}

pub const CaseFile = struct {
    filename: []const u8,
    expect_filename: []const u8,
};

pub const TestResult = union(enum) {
    success: void,
    skip: void,
    not_equal: struct {
        expect: []const u8,
        actual: []const u8,
    },
};

pub const TestRunner = struct {
    root_dir: []const u8,
    update_baselines: bool,
    filter: ?[]const u8,
    have_tty: bool,
    html_reporter: ?HtmlReporter,

    fn runTest(self: *TestRunner, allocator: std.mem.Allocator, case_filepath: []const u8, expect_filepath: []const u8) !TestResult {
        var arena = std.heap.ArenaAllocator.init(allocator);
        defer arena.deinit();

        std.testing.log_level = .debug;

        var file = try std.fs.cwd().openFile(case_filepath, .{ .mode = .read_only });
        defer file.close();

        const buffer = try file.readToEndAlloc(arena.allocator(), zapts.MAX_FILE_SIZE);
        const result = try zapts.compileBuffer(arena.allocator(), path.basename(case_filepath), buffer);

        if (self.update_baselines) {
            try updateBaseline(arena.allocator(), case_filepath, expect_filepath, result);
        }

        const expect_files = try parseExpect(arena.allocator(), case_filepath, expect_filepath);
        // check if source is same
        try expectEqualStrings(expect_files.get(result.source_filename).?, std.mem.trimRight(u8, result.source_buffer, newline));

        for (result.outputFiles) |output_file| {
            const expected_output_file = expect_files.get(output_file.filename).?;
            try expectEqualStrings(expected_output_file, std.mem.trimRight(u8, output_file.buffer, newline));
        }
        return .success;
    }

    fn getTestCases(self: *TestRunner, allocator: std.mem.Allocator) ![]CaseFile {
        const cases_dir = try std.mem.join(allocator, "/", &[_][]const u8{ self.root_dir, "cases" });
        const expects_dir = try std.mem.join(allocator, "/", &[_][]const u8{ self.root_dir, "expects" });

        var dir = try std.fs.cwd().openDir(cases_dir, .{
            .iterate = true,
        });
        defer dir.close();

        var cases = std.ArrayList(CaseFile).init(allocator);

        var walker = try dir.walk(allocator);
        while (try walker.next()) |entry| {
            if (entry.kind != .file) {
                continue;
            }

            if (self.filter) |filter| {
                if (std.mem.indexOfPos(u8, entry.path, 0, filter) == null) {
                    continue;
                }
            }

            const expect_name = try std.mem.replaceOwned(u8, allocator, entry.path, ".ts", ".js");
            const casefile = CaseFile{
                .filename = try std.mem.join(allocator, "/", &[_][]const u8{ cases_dir, entry.path }),
                .expect_filename = try std.mem.join(allocator, "/", &[_][]const u8{ expects_dir, expect_name }),
            };
            try cases.append(casefile);
        }
        return cases.items;
    }

    pub fn parseExpect(allocator: std.mem.Allocator, case_filepath: []const u8, expect_filepath: []const u8) !std.StringHashMap([]const u8) {
        const expect_content = if (std.fs.cwd().openFile(expect_filepath, .{ .mode = .read_only })) |expect_file|
            try expect_file.readToEndAlloc(allocator, zapts.MAX_FILE_SIZE)
        else |err| switch (err) {
            error.FileNotFound => "",
            else => return err,
        };

        var lines_it = std.mem.splitSequence(u8, expect_content, newline);
        const expected_first_line = try std.fmt.allocPrint(allocator, "//// [{s}] ////", .{case_filepath});
        try expectEqualStrings(expected_first_line, lines_it.next().?);
        try expectEqualStrings("", lines_it.next().?);

        var files = std.StringHashMap([]const u8).init(allocator);

        var current_file: ?[]const u8 = null;
        var current_file_content = std.ArrayList(u8).init(allocator);

        while (lines_it.next()) |line| {
            if (std.mem.startsWith(u8, line, "////")) {
                // save previous file into files arr
                if (current_file) |cur_file| {
                    const trimmed_content = std.mem.trimRight(u8, try current_file_content.toOwnedSlice(), newline);
                    try files.put(cur_file, trimmed_content);
                }

                // parse file name
                const filename_start_idx = std.mem.indexOf(u8, line, "[") orelse unreachable;
                const filename_end_idx = std.mem.indexOf(u8, line, "]") orelse unreachable;
                current_file = line[filename_start_idx + 1 .. filename_end_idx];
            } else {
                try current_file_content.appendSlice(line);
                try current_file_content.appendSlice(newline);
            }
        }

        if (current_file) |cur_file| {
            const trimmed_content = std.mem.trimRight(u8, try current_file_content.toOwnedSlice(), newline);
            try files.put(cur_file, trimmed_content);
        }

        return files;
    }

    pub fn updateBaseline(allocator: std.mem.Allocator, case_filepath: []const u8, expect_filepath: []const u8, result: zapts.CompileResult) !void {
        var combined_result = std.ArrayList(u8).init(allocator);

        try std.fmt.format(combined_result.writer(), "//// [{s}] ////" ++ newline ++ newline, .{case_filepath});
        try std.fmt.format(combined_result.writer(), "//// [{s}]" ++ newline, .{result.source_filename});
        try combined_result.appendSlice(result.source_buffer);
        try combined_result.appendSlice(newline ++ newline);

        for (result.outputFiles, 0..) |output_file, i| {
            try std.fmt.format(combined_result.writer(), "//// [{s}]" ++ newline, .{output_file.filename});
            try combined_result.appendSlice(output_file.buffer);
            try combined_result.appendSlice(if (i < result.outputFiles.len - 1) newline ++ newline else newline);
        }

        try std.fs.cwd().writeFile(.{
            .sub_path = expect_filepath,
            .data = combined_result.items,
        });
    }

    pub fn reportStart(self: *TestRunner, test_num: usize, cases: []CaseFile, case_file: CaseFile) !void {
        if (self.html_reporter == null) {
            std.debug.print("{d}/{d} {s}... ", .{ test_num + 1, cases.len, case_file.filename });
        }
    }

    pub fn reportSuccess(self: *TestRunner, test_num: usize, cases: []CaseFile, case_file: CaseFile) !void {
        if (self.html_reporter) |reporter| {
            try reporter.reportSuccess(test_num, cases, case_file);
        } else {
            std.debug.print("OK\n", .{});
        }
    }

    pub fn reportSkip(self: *TestRunner, test_num: usize, cases: []CaseFile, case_file: CaseFile) !void {
        if (self.html_reporter) |reporter| {
            try reporter.reportSkip(test_num, cases, case_file);
        } else {
            std.debug.print("SKIP\n", .{});
        }
    }

    pub fn reportFail(self: *TestRunner, test_num: usize, cases: []CaseFile, case_file: CaseFile, err: anyerror, trace: ?*std.builtin.StackTrace) !void {
        if (self.html_reporter) |reporter| {
            try reporter.reportFail(test_num, cases, case_file, err, trace);
        } else {
            std.debug.print("FAIL ({s})\n", .{@errorName(err)});
            if (trace) |t| {
                std.debug.dumpStackTrace(t.*);
            }
        }
    }
};

fn initRefTestsDir(alloc: std.mem.Allocator) !void {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();

    const allocator = arena.allocator();
    var client = Client{
        .allocator = allocator,
    };

    var arr = std.ArrayList(u8).init(allocator);
    var tarArr = std.ArrayList(u8).init(allocator);
    const url = try std.fmt.allocPrint(allocator, "https://github.com/microsoft/TypeScript/archive/refs/tags/v{s}.tar.gz", .{TS_VERSION});

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

    const file_buffer = try allocator.alloc(u8, zapts.MAX_FILE_SIZE);

    var tests_count: u32 = 0;
    while (try iter.next()) |entry| {
        const real_path = entry.name[bytes_to_skip..];
        if (std.mem.startsWith(u8, real_path, "tests/")) {
            switch (entry.kind) {
                .file => {
                    std.debug.print("writing file: {s}\n", .{real_path});
                    const file = try output_dir.createFile(real_path, .{});
                    var file_writer = std.io.bufferedWriter(file.writer());
                    defer file.close();
                    defer file_writer.flush() catch @panic("flush failed");

                    const len = try entry.reader().readAll(file_buffer);

                    try writeAndFixNewlines(file_writer.writer(), file_buffer[0..len]);
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

fn getRefTestCases(alloc: std.mem.Allocator, filter: ?[]const u8) ![]TestRunner.CaseFile {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();

    const allocator = arena.allocator();

    std.fs.cwd().access(REF_TESTS_DIR, .{}) catch |err| {
        if (err == error.FileNotFound) {
            std.debug.print("Creating {s} directory ...\n", .{REF_TESTS_DIR});
            try std.fs.cwd().makePath(REF_TESTS_DIR);
            try initRefTestsDir(allocator);
        } else {
            return err;
        }
    };

    var result = std.ArrayList(TestRunner.CaseFile).init(allocator);
    const cases_dir_path = try std.mem.join(allocator, "/", &[_][]const u8{ REF_TESTS_DIR, "tests", "cases" });
    const expects_dir = try std.mem.join(allocator, "/", &[_][]const u8{ REF_TESTS_DIR, "tests", "baselines", "reference" });

    var cases_dir = try std.fs.cwd().openDir(cases_dir_path, .{
        .iterate = true,
    });
    defer cases_dir.close();

    var walker = try cases_dir.walk(allocator);

    while (try walker.next()) |entry| {
        if (entry.kind == .file) {
            const is_filter_match = if (filter) |filter_str| std.mem.startsWith(u8, filter_str, entry.path) else true;

            if (is_filter_match) {
                const expect_name = try std.mem.replaceOwned(u8, allocator, entry.basename, ".ts", ".js");

                const basename_path = path.relative(allocator, cases_dir_path, entry.path);
                try result.append(.{
                    .filename = try path.join(allocator, &[_][]const u8{ cases_dir_path, basename_path }),
                    .expect_filename = try path.join(allocator, &[_][]const u8{ expects_dir, expect_name }),
                });
            }
        }
    }

    return result.toOwnedSlice();
}

fn writeAndFixNewlines(writer: anytype, buffer: []const u8) !void {
    for (0..buffer.len) |i| {
        if (should_replace_newline(buffer, i)) {
            try writer.writeAll(newline);
        } else {
            try writer.writeByte(buffer[i]);
        }
    }
}

fn should_replace_newline(buffer: []const u8, i: usize) bool {
    if (builtin.target.os.tag == .windows) {
        return buffer[i] == '\n' and i > 0 and buffer[i - 1] != '\r';
    } else {
        return buffer[i] == '\n' and i > 0 and buffer[i - 1] == '\r';
    }
}
