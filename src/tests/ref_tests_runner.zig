const std = @import("std");
const assert = std.debug.assert;

const io = std.io;
const path = std.fs.path;
const Dir = std.fs.Dir;
const Client = std.http.Client;
const builtin = @import("builtin");
const MAX_FILE_SIZE = @import("zapts").MAX_FILE_SIZE;
const Reporter = @import("zapts").Reporter;
const Parser = @import("zapts").Parser;

const expect = std.testing.expect;
const expectEqualStrings = std.testing.expectEqualStrings;

const REF_TESTS_DIR = ".reftests";
const COMPILER_TESTS_DIR = REF_TESTS_DIR ++ "/cases/compiler";
const CONFORMANCE_TESTS_DIR = REF_TESTS_DIR ++ "/cases/conformance";
const BASELINES_REF_DIR = REF_TESTS_DIR ++ "/baselines/reference";
const BASELINES_LOCAL_DIR = REF_TESTS_DIR ++ "/baselines/local";

const TS_VERSION = "5.4.5";

var log_err_count: usize = 0;

const TestRunnerArgs = struct {
    html: bool = false,
    filter: ?[]const u8 = null,
};

fn parseArgs(allocator: std.mem.Allocator) !TestRunnerArgs {
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    var result = TestRunnerArgs{};

    for (args, 0..) |arg, i| {
        if (std.mem.eql(u8, arg, "--filter")) {
            result.filter = try allocator.dupe(u8, args[i + 1]);
        }

        if (std.mem.eql(u8, arg, "--html")) {
            result.html = true;
        }
    }

    return result;
}

pub fn main() !void {
    var timer = try std.time.Timer.start();

    const allocator = std.testing.allocator;
    defer _ = std.testing.allocator_instance.deinit();
    const options = try parseArgs(allocator);

    var ok_count: usize = 0;
    var skip_count: usize = 0;
    var fail_count: usize = 0;

    const have_tty = std.io.getStdErr().isTty();
    var test_runner = TestRunner{
        .have_tty = have_tty,
        .filter = options.filter,
        .runner_arena = std.heap.ArenaAllocator.init(allocator),
        .test_arena = std.heap.ArenaAllocator.init(allocator),
    };
    defer test_runner.test_arena.deinit();
    defer test_runner.runner_arena.deinit();

    var walker = try test_runner.walk();

    const case_count = try walker.count();
    const root_node = std.Progress.start(.{
        .root_name = "Test",
        .estimated_total_items = case_count,
    });

    var leaks: usize = 0;
    _ = &leaks;
    var i: usize = 0;
    while (try walker.next()) |case_file| : (i += 1) {
        std.testing.log_level = .warn;

        var test_node = root_node.start(case_file.filename, 0);
        try test_runner.reportStart(i, case_count, case_file);
        if (test_runner.runTest(case_file)) |_| {
            ok_count += 1;
            try test_runner.reportSuccess();
        } else |err| {
            if (err == error.SkipZigTest) {
                skip_count += 1;
                try test_runner.reportSkip();
            } else {
                fail_count += 1;
                try test_runner.reportFail(err, @errorReturnTrace());
            }
        }
        test_node.end();
    }
    root_node.end();

    const test_duration = timer.read() / std.time.ns_per_ms;
    if (ok_count == case_count) {
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

pub const CaseFile = struct {
    filename: []const u8,
    baseline_filename: []const u8,

    pub fn basename(self: CaseFile) []const u8 {
        return path.basename(self.filename);
    }

    pub fn localBaseline(self: CaseFile, allocator: std.mem.Allocator) ![]const u8 {
        return path.join(allocator, &[_][]const u8{ BASELINES_LOCAL_DIR, self.basename() });
    }

    pub fn referenceBaseline(self: CaseFile, allocator: std.mem.Allocator) ![]const u8 {
        return path.join(allocator, &[_][]const u8{ BASELINES_REF_DIR, self.basename() });
    }

    pub const Walker = struct {
        runner: *TestRunner,
        dir: Dir,
        walker: Dir.Walker,

        pub fn init(runner: *TestRunner, dir: Dir) !Walker {
            return .{
                .runner = runner,
                .dir = dir,
                .walker = try dir.walk(runner.runner_arena.allocator()),
            };
        }

        pub fn deinit(self: *Walker) void {
            self.dir.close();
            self.walker.deinit();
        }

        pub fn isCaseFile(self: *Walker, kind: Dir.Entry.Kind, name: []const u8) bool {
            if (kind != .file) {
                return false;
            }

            if (self.runner.filter) |filter| {
                if (std.mem.indexOfPos(u8, name, 0, filter) == null) {
                    return false;
                }
            }

            return true;
        }

        pub fn count(self: *Walker) !usize {
            var iter = self.dir.iterate();

            var items_count: usize = 0;
            while (try iter.next()) |entry| {
                if (self.isCaseFile(entry.kind, entry.name)) {
                    items_count += 1;
                }
            }
            return items_count;
        }

        pub fn next(self: *Walker) !?CaseFile {
            const allocator = self.walker.allocator;
            const entry = try self.walker.next() orelse return null;

            if (!self.isCaseFile(entry.kind, entry.basename)) return self.next();

            return .{
                .filename = try std.mem.join(allocator, path.sep_str, &[_][]const u8{ COMPILER_TESTS_DIR, entry.path }),
                .baseline_filename = "",
            };
        }
    };
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
    filter: ?[]const u8,
    have_tty: bool,
    runner_arena: std.heap.ArenaAllocator,
    test_arena: std.heap.ArenaAllocator,

    fn runTest(self: *TestRunner, case_file: CaseFile) !void {
        std.testing.log_level = .debug;
        defer _ = self.test_arena.reset(.retain_capacity);

        const buffer = try parseCaseFile(self, self.test_arena.allocator(), case_file.filename);
        var reporter = Reporter.init(self.test_arena.allocator());
        defer reporter.deinit();

        var parser = Parser.init(self.test_arena.allocator(), buffer, &reporter);
        defer parser.deinit();

        _ = parser.parse() catch |err| {
            if (err != error.SyntaxError) {
                return err;
            }
        };

        try self.writePrinterSnapshots(case_file);
        try self.writeSymbolsSnapshots(case_file);
        try self.writeTypesSnapshots(case_file);
        try self.writeErrorsSnapshots(case_file, &reporter);
    }

    fn parseCaseFile(_: *TestRunner, allocator: std.mem.Allocator, case_filepath: []const u8) ![:0]const u8 {
        var file = try std.fs.cwd().openFile(case_filepath, .{ .mode = .read_only });
        defer file.close();

        return try file.readToEndAllocOptions(allocator, MAX_FILE_SIZE, null, @alignOf(u8), 0);
    }

    pub fn writePrinterSnapshots(self: *TestRunner, case: CaseFile) !void {
        var baselines_local_dir = try std.fs.cwd().makeOpenPath(BASELINES_LOCAL_DIR, .{});
        defer baselines_local_dir.close();

        const out_filename = try std.mem.replaceOwned(u8, self.test_arena.allocator(), case.basename(), ".ts", ".js");
        const file = try baselines_local_dir.createFile(out_filename, .{});
        defer file.close();

        try file.writeAll("output");
    }

    pub fn writeSymbolsSnapshots(self: *TestRunner, case: CaseFile) !void {
        var baselines_local_dir = try std.fs.cwd().makeOpenPath(BASELINES_LOCAL_DIR, .{});
        defer baselines_local_dir.close();

        const out_filename = try std.mem.replaceOwned(u8, self.test_arena.allocator(), case.basename(), ".ts", ".symbols");
        const file = try baselines_local_dir.createFile(out_filename, .{});
        defer file.close();

        try file.writeAll("symbols");
    }

    pub fn writeTypesSnapshots(self: *TestRunner, case: CaseFile) !void {
        var baselines_local_dir = try std.fs.cwd().makeOpenPath(BASELINES_LOCAL_DIR, .{});
        defer baselines_local_dir.close();

        const out_filename = try std.mem.replaceOwned(u8, self.test_arena.allocator(), case.basename(), ".ts", ".types");
        const file = try baselines_local_dir.createFile(out_filename, .{});
        defer file.close();

        try file.writeAll("types");
    }

    pub fn writeErrorsSnapshots(self: *TestRunner, case: CaseFile, reporter: *Reporter) !void {
        if (reporter.errors.len == 0) return;

        var baselines_local_dir = try std.fs.cwd().makeOpenPath(BASELINES_LOCAL_DIR, .{});
        defer baselines_local_dir.close();

        const out_filename = try std.mem.replaceOwned(u8, self.test_arena.allocator(), case.basename(), ".ts", ".errors.txt");
        const file = try baselines_local_dir.createFile(out_filename, .{});
        defer file.close();

        var i: usize = 0;
        while (i < reporter.errors.len) : (i += 1) {
            try file.writeAll(reporter.errors.items(.message)[i]);
            try file.writeAll("\n");
        }
    }

    pub fn reportStart(_: *TestRunner, test_num: usize, case_count: usize, case_file: CaseFile) !void {
        std.debug.print("{d}/{d} {s}... ", .{ test_num + 1, case_count, case_file.filename });
    }

    pub fn reportSuccess(_: *TestRunner) !void {
        std.debug.print("OK\n", .{});
    }

    pub fn reportSkip(_: *TestRunner) !void {
        std.debug.print("SKIP\n", .{});
    }

    pub fn reportFail(_: *TestRunner, err: anyerror, trace: ?*std.builtin.StackTrace) !void {
        std.debug.print("FAIL ({s})\n", .{@errorName(err)});
        if (trace) |t| {
            std.debug.dumpStackTrace(t.*);
        }
    }

    fn walk(self: *TestRunner) !CaseFile.Walker {
        std.fs.cwd().access(REF_TESTS_DIR, .{}) catch |err| {
            if (err == error.FileNotFound) {
                try initRefTestsDir(self.runner_arena.allocator());
            } else {
                return err;
            }
        };

        return CaseFile.Walker.init(
            self,
            try std.fs.cwd().openDir(COMPILER_TESTS_DIR, .{
                .iterate = true,
            }),
        );
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

    var file_name: [std.fs.max_path_bytes]u8 = undefined;
    var link_name: [std.fs.max_path_bytes]u8 = undefined;
    var iter = std.tar.iterator(fb.reader(), .{ .file_name_buffer = &file_name, .link_name_buffer = &link_name });

    const first_file = try iter.next();
    const bytes_to_skip = first_file.?.name.len;

    var output_dir = try std.fs.cwd().makeOpenPath(REF_TESTS_DIR, .{});
    defer output_dir.close();

    var tests_count: u32 = 0;
    while (try iter.next()) |entry| {
        const real_path = entry.name[bytes_to_skip..];
        if (std.mem.startsWith(u8, real_path, "tests/")) {
            switch (entry.kind) {
                .file => {
                    const out_filename = std.mem.trimLeft(u8, real_path, "tests/");
                    std.debug.print("writing file: {s}\n", .{out_filename});

                    const out_dir = std.fs.path.dirname(out_filename) orelse unreachable;
                    try output_dir.makePath(out_dir);

                    const file = try output_dir.createFile(out_filename, .{});
                    defer file.close();

                    var file_writer = std.io.bufferedWriter(file.writer());
                    defer file_writer.flush() catch @panic("flush failed");

                    const file_buffer = try entry.reader().readAllAlloc(allocator, MAX_FILE_SIZE);

                    try writeAndFixNewlines(file_writer.writer(), file_buffer);
                    tests_count += 1;
                },
                else => {},
            }
        }
    }

    std.debug.print("Files extracted: {d}\n", .{tests_count});
}

fn writeAndFixNewlines(writer: anytype, buffer: []const u8) !void {
    for (0..buffer.len) |i| {
        if (shouldReplaceNewline(buffer, i)) {
            try writer.writeAll("\n");
        } else {
            try writer.writeByte(buffer[i]);
        }
    }
}

fn shouldReplaceNewline(buffer: []const u8, i: usize) bool {
    if (builtin.target.os.tag == .windows) {
        return buffer[i] == '\n' and i > 0 and buffer[i - 1] != '\r';
    } else {
        return buffer[i] == '\n' and i > 0 and buffer[i - 1] == '\r';
    }
}
