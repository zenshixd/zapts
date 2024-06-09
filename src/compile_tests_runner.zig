//! Default test runner for unit tests.
const std = @import("std");
const io = std.io;
const builtin = @import("builtin");
const getTestCases = @import("tests/compile.zig").getTestCases;
const runTest = @import("tests/compile.zig").runTest;

var log_err_count: usize = 0;

pub fn main() !void {
    var ok_count: usize = 0;
    var skip_count: usize = 0;
    var fail_count: usize = 0;
    const cases = try getTestCases(std.heap.page_allocator);
    const root_node = std.Progress.start(.{
        .root_name = "Test",
        .estimated_total_items = cases.len,
    });
    const have_tty = std.io.getStdErr().isTty();

    var leaks: usize = 0;
    for (cases, 0..) |case_file, i| {
        std.testing.allocator_instance = .{};
        defer {
            if (std.testing.allocator_instance.deinit() == .leak) {
                leaks += 1;
            }
        }
        std.testing.log_level = .warn;

        var test_node = root_node.start(case_file, 0);
        if (!have_tty) {
            std.debug.print("{d}/{d} {s}... ", .{ i + 1, cases.len, case_file });
        }
        if (runTest(std.heap.page_allocator, case_file)) |_| {
            ok_count += 1;
            test_node.end();
            if (!have_tty) std.debug.print("OK\n", .{});
        } else |err| switch (err) {
            error.SkipZigTest => {
                skip_count += 1;
                if (have_tty) {
                    std.debug.print("{d}/{d} {s}...SKIP\n", .{ i + 1, cases.len, case_file });
                } else {
                    std.debug.print("SKIP\n", .{});
                }
                test_node.end();
            },
            else => {
                fail_count += 1;
                if (have_tty) {
                    std.debug.print("{d}/{d} {s}...FAIL ({s})\n", .{
                        i + 1, cases.len, case_file, @errorName(err),
                    });
                } else {
                    std.debug.print("FAIL ({s})\n", .{@errorName(err)});
                }
                if (@errorReturnTrace()) |trace| {
                    std.debug.dumpStackTrace(trace.*);
                }
                test_node.end();
            },
        }
    }
    root_node.end();
    if (ok_count == cases.len) {
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
