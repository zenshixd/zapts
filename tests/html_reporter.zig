const std = @import("std");
const CaseFile = @import("./e2e_tests_runner.zig").CaseFile;

const report_file_path = "report/report.html";
const html_header =
    \\<!DOCTYPE html>
    \\<html lang="en">
    \\<head>
    \\    <meta charset="UTF-8">
    \\    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    \\    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    \\    <title>zapts report</title>
    \\    <link rel="stylesheet" href="report.css">
    \\</head>
    \\<body>
    \\<div class="report-header">
    \\  <h1>zapts report</h1>
    \\</div>
    \\<div class="search-bar">
    \\  <input type="text" id="search-input" placeholder="Search..." autofocus> <label for="show-hidden"><input type="checkbox" id="show-hidden"> Show hidden</label>
    \\</div>
    \\<div class="report-body">
;
const html_footer =
    \\</div>
    \\<script src="report.js"></script>
    \\</body>
    \\</html>
;

const Self = @This();
allocator: std.mem.Allocator,
report_file: std.fs.File,

pub fn init(allocator: std.mem.Allocator) !Self {
    const report_file = try std.fs.cwd().createFile(report_file_path, .{});
    try report_file.writeAll(html_header);
    return .{
        .allocator = allocator,
        .report_file = report_file,
    };
}

pub fn end(self: Self) void {
    self.report_file.writeAll(html_footer) catch @panic("report file write failed");
    self.report_file.close();
}

pub fn reportSuccess(self: Self, test_num: usize, cases: []CaseFile, case_file: CaseFile) !void {
    const template =
        \\<div class="test-case-result ok">
        \\  <p>
        \\    {[i]d}/{[total]d}
        \\    <a href="#" class="test-case-name">{[test_file]s}</a>
        \\    (<a href="#" class="run-link">run</a>)
        \\    ... OK (<a class="hide-link" href="#"><span class="hide-icon">&#10006;</span><span class="show-icon">&#11014;</span></a>)
        \\  </p>
        \\</div>
    ;
    try std.fmt.format(self.report_file.writer(), template, .{
        .i = test_num + 1,
        .total = cases.len,
        .test_file = case_file.filename,
    });
}

pub fn reportSkip(self: Self, test_num: usize, cases: []CaseFile, case_file: CaseFile) !void {
    const template =
        \\<div class="test-case-result skip">
        \\  <p>{[i]d}/{[total]d}
        \\    <a href="#" class="test-case-name">{[test_file]s}</a>
        \\    (<a href="#" class="run-link">run</a>)
        \\    ... SKIP (<a class="hide-link" href="#"><span class="hide-icon">&#10006;</span><span class="show-icon">&#11014;</span></a>)
        \\  </p>
        \\</div>
    ;
    try std.fmt.format(self.report_file.writer(), template, .{
        .i = test_num + 1,
        .total = cases.len,
        .test_file = case_file.filename,
    });
}

pub fn reportFail(self: Self, test_num: usize, cases: []CaseFile, case_file: CaseFile, test_err: anyerror, trace: ?*std.builtin.StackTrace) !void {
    var trace_str = std.ArrayList(u8).init(self.allocator);
    defer trace_str.deinit();
    if (trace) |t| {
        const maybe_debug_info = std.debug.getSelfDebugInfo();
        if (maybe_debug_info) |debug_info| {
            try std.debug.writeStackTrace(t.*, trace_str.writer(), self.allocator, debug_info, .no_color);
        } else |err| {
            try trace_str.writer().print("\nUnable to print stack trace: Unable to open debug info: {s}\n", .{@errorName(err)});
        }
    }
    const template =
        \\<div class="test-case-result fail">
        \\  <p>{[i]d}/{[total]d}
        \\    <a href="#" class="test-case-name">{[test_file]s}</a>
        \\    (<a href="#" class="run-link">run</a>)
        \\    ... FAIL ({[err_name]s}) (<a class="hide-link" href="#"><span class="hide-icon">&#10006;</span><span class="show-icon">&#11014;</span></a>)
        \\  </p>
        \\  <pre>{[trace]s}</pre>
        \\</div>
    ;
    try std.fmt.format(self.report_file.writer(), template, .{
        .i = test_num + 1,
        .test_file = case_file.filename,
        .total = cases.len,
        .err_name = @errorName(test_err),
        .trace = trace_str.items,
    });
}
