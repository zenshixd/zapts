const std = @import("std");
const assert = std.debug.assert;

const SourceLocation = std.builtin.SourceLocation;
const Allocator = std.mem.Allocator;

const expectEqualStrings = std.testing.expectEqualStrings;
const expectError = std.testing.expectError;

pub const Snapshot = @This();
const Source = struct {
    content: std.ArrayListUnmanaged(u8),
    shifts: std.ArrayListUnmanaged(i32),
};

var snapshot_sources: std.StringHashMapUnmanaged(Source) = .empty;

source_location: SourceLocation,
text: []const u8,
should_update: bool = false,

pub fn openSourceDir() !std.fs.Dir {
    return try std.fs.cwd().openDir("src/", .{});
}

pub fn getSourceFile(self: Snapshot, allocator: Allocator) ![]const u8 {
    const result = try snapshot_sources.getOrPut(allocator, self.source_location.file);
    if (result.found_existing) {
        return result.value_ptr.content.items;
    }

    var dir = try openSourceDir();
    defer dir.close();

    var file = try dir.openFileZ(self.source_location.file, .{});
    defer file.close();

    var file_content: std.ArrayListUnmanaged(u8) = .empty;
    while (true) {
        const c = file.reader().readByte() catch |err| {
            if (err == error.EndOfStream) break;
            return err;
        };
        try file_content.append(allocator, c);
    }

    result.value_ptr.* = .{
        .content = file_content,
        .shifts = .empty,
    };

    return result.value_ptr.content.items;
}

pub const SourceFileParts = struct {
    beginning: []const u8,
    snapshot: []const u8,
    snapshot_indent: u32,
    ending: []const u8,
};

pub fn getSourceFileParts(self: Snapshot, allocator: Allocator) !SourceFileParts {
    const content = try self.getSourceFile(allocator);
    var state: enum { begin, snapshot } = .begin;
    var begin_end_idx: usize = 0;
    var snapshot_end_idx: usize = 0;
    var indent: u32 = 0;
    var it = std.mem.splitScalar(u8, content, '\n');

    var line_num: u32 = 1;
    while (it.next()) |line| : (line_num += 1) {
        switch (state) {
            .begin => {
                if (line_num == self.source_location.line) {
                    begin_end_idx = it.index.?;
                    state = .snapshot;
                }
            },
            .snapshot => {
                if (indent == 0) {
                    if (std.mem.indexOf(u8, line, "\\\\") == null) {
                        return error.SnapshotNotFound;
                    }
                    indent = getIndent(line);
                }

                if (std.mem.indexOf(u8, line, "\\\\") == null) {
                    break;
                } else {
                    snapshot_end_idx = it.index.?;
                }
            },
        }
    }

    return .{
        .beginning = content[0..begin_end_idx],
        .snapshot = content[begin_end_idx..snapshot_end_idx],
        .snapshot_indent = indent,
        .ending = content[snapshot_end_idx..],
    };
}

fn getIndent(text: []const u8) u32 {
    var indent: u32 = 0;
    for (text) |c| {
        if (c == ' ') {
            indent += 1;
        } else {
            break;
        }
    }

    return indent;
}

pub fn formatAsSnapshotString(_: Snapshot, writer: anytype, indent: u32, text: []const u8) !void {
    var it = std.mem.splitScalar(u8, text, '\n');

    while (it.next()) |line| {
        for (0..indent) |_| {
            try writer.writeByte(' ');
        }
        try writer.writeAll("\\\\");
        try writer.writeAll(line);
        try writer.writeByte('\n');
    }
}

pub fn updateSourceFile(self: Snapshot, allocator: Allocator, new_text: []const u8) !void {
    var result = snapshot_sources.getPtr(self.source_location.file).?;

    result.content.clearRetainingCapacity();
    try result.content.appendSlice(allocator, new_text);
}

pub fn flushSourceFiles(allocator: Allocator) !void {
    var it = snapshot_sources.iterator();
    var dir = try openSourceDir();
    defer dir.close();

    while (it.next()) |entry| {
        var file = try dir.createFile(entry.key_ptr.*, .{});
        defer file.close();

        try file.writeAll(entry.value_ptr.content.items);

        entry.value_ptr.content.clearAndFree(allocator);
        entry.value_ptr.shifts.clearAndFree(allocator);
    }

    snapshot_sources.clearAndFree(allocator);
}

pub fn diff(expected: Snapshot, got: []const u8) !void {
    if (!std.mem.eql(u8, expected.text, got)) {
        if (!expected.shouldUpdate()) {
            return error.SnapshotMismatch;
        }

        return expected.update(got);
    }
}

pub fn shouldUpdate(self: Snapshot) bool {
    return self.should_update or std.process.hasEnvVarConstant("ZAPTS_SNAPSHOT_UPDATE");
}

pub fn update(self: Snapshot, new_text: []const u8) !void {
    const gpa = std.testing.allocator;

    var new_file_content = std.ArrayList(u8).init(gpa);
    defer new_file_content.deinit();

    const parts = try self.getSourceFileParts(gpa);

    try new_file_content.appendSlice(parts.beginning);
    try self.formatAsSnapshotString(new_file_content.writer(), parts.snapshot_indent, new_text);
    try new_file_content.appendSlice(parts.ending);

    try self.updateSourceFile(gpa, new_file_content.items);

    return error.SnapshotUpdated;
}

pub fn snap(source_location: SourceLocation, text: []const u8) Snapshot {
    return .{
        .source_location = source_location,
        .text = text,
    };
}

pub fn expectSnapshotMatch(received: anytype, expected: Snapshot) !void {
    var buf: [1024]u8 = undefined;
    const type_info = @typeInfo(@TypeOf(received));
    const received_text = switch (type_info) {
        .optional => try std.fmt.bufPrint(&buf, "{?}", .{received}),
        .array => try std.fmt.bufPrint(&buf, "{s}", .{received}),
        .pointer => |ptr| switch (ptr.size) {
            .one => try std.fmt.bufPrint(&buf, "{s}", .{received}),
            .slice => try std.fmt.bufPrint(&buf, "{s}", .{received}),
            else => @compileError(std.fmt.comptimePrint("unsupported pointer size {s}", .{@tagName(ptr.size)})),
        },
        else => @compileError(std.fmt.comptimePrint("unsupported type {s}", .{@typeName(received)})),
    };

    expected.diff(received_text) catch |err| {
        if (err == error.SnapshotMismatch) {
            std.debug.print(
                \\SnapshotMismatch
                \\expected:
                \\{s}
                \\
                \\got:
                \\{s}
                \\
            , .{ expected.text, received_text });
        }

        return err;
    };
}

fn testSnap(text: []const u8) ![]const u8 {
    var result = std.ArrayList(u8).init(std.testing.allocator);
    const writer = result.writer();

    try writer.writeAll("snap(@src(),\n");
    var it = std.mem.splitScalar(u8, text, '\n');
    while (it.next()) |line| {
        try writer.writeAll("    \\\\");
        try writer.writeAll(line);
        try writer.writeAll("\n");
    }
    try writer.writeAll(");\n");

    return result.toOwnedSlice();
}

const test_file_path = "tests/$$test_file.zig";
fn testSetupFile(snapshot_text: []const u8, file_text: []const u8) !Snapshot {
    var dir = try std.fs.cwd().openDir("src/", .{});
    defer dir.close();

    const file = try dir.createFile(test_file_path, .{});
    defer file.close();

    try file.writeAll(file_text);

    return Snapshot{
        .source_location = .{ .file = test_file_path, .line = 1, .column = 1, .fn_name = "", .module = "" },
        .text = snapshot_text,
        .should_update = false,
    };
}

fn testReadFile() ![]const u8 {
    var dir = try openSourceDir();
    defer dir.close();

    const file = try dir.openFile(test_file_path, .{});
    defer file.close();

    return file.readToEndAlloc(std.testing.allocator, std.math.maxInt(u32));
}

fn testDumpFile() !void {
    const content = try testReadFile();
    defer std.testing.allocator.free(content);
    std.debug.print("content:\n{s}\n", .{content});
}

fn testDeleteFile(path: []const u8) !void {
    var dir = try std.fs.cwd().openDir("src/", .{});
    defer dir.close();

    try dir.deleteFile(path);
}

fn testSnapshots(snapshot_text: []const u8, Expect: anytype) !void {
    const text = try testSnap(snapshot_text);
    defer std.testing.allocator.free(text);

    try testSnapshotsExtra(snapshot_text, text, Expect);
}

fn testSnapshotsExtra(snapshot_text: []const u8, file_content: []const u8, Expect: anytype) !void {
    const snapshot = try testSetupFile(snapshot_text, file_content);
    defer testDeleteFile(snapshot.source_location.file) catch @panic("couldnt delete file");

    try Expect.run(snapshot);
}

fn testMultipleSnapshots(snapshots_texts: []const []const u8, Expect: anytype) !void {
    var dir = try std.fs.cwd().openDir("src/", .{});
    defer dir.close();

    const file = try dir.createFile(test_file_path, .{});
    defer file.close();

    var snapshots = std.ArrayList(Snapshot).init(std.testing.allocator);
    defer snapshots.deinit();

    var line_num: u32 = 1;
    for (snapshots_texts) |snapshot_text| {
        const file_content = try testSnap(snapshot_text);
        defer std.testing.allocator.free(file_content);

        try file.writeAll(file_content);
        try snapshots.append(.{
            .source_location = .{ .file = test_file_path, .line = line_num, .column = 1, .fn_name = "", .module = "" },
            .text = snapshot_text,
        });

        line_num += @intCast(std.mem.count(u8, file_content, "\n"));
    }

    try Expect.run(snapshots.items);
}

test "should return void if snapshot matches" {
    const snapshot_text = "hello world";

    try testSnapshots(snapshot_text, struct {
        fn run(snapshot: Snapshot) !void {
            try expectSnapshotMatch("hello world", snapshot);
        }
    });
}

test "should return error if snapshot is mismatched" {
    const snapshot_text = "hello world";
    try testSnapshots(snapshot_text, struct {
        fn run(snapshot: Snapshot) !void {
            const result = snapshot.diff("hello worlds");

            try expectError(error.SnapshotMismatch, result);
        }
    });
}

test "should return error if snapshot is not found" {
    const file_content =
        \\snap(@src(), "hello world");
        \\
    ;

    try testSnapshotsExtra("hello world", file_content, struct {
        fn run(snapshot: Snapshot) !void {
            const result = snapshot.update("hello worlds");
            try flushSourceFiles(std.testing.allocator);

            try expectError(error.SnapshotNotFound, result);
        }
    });
}

test "should update single line snapshot" {
    const snapshot_text =
        \\1
    ;
    try testSnapshots(snapshot_text, struct {
        fn run(snapshot: Snapshot) !void {
            const result = snapshot.update(
                \\2
            );
            try flushSourceFiles(std.testing.allocator);
            try expectError(error.SnapshotUpdated, result);

            const content = try testReadFile();
            defer std.testing.allocator.free(content);

            try expectEqualStrings(
                \\snap(@src(),
                \\    \\2
                \\);
                \\
            , content);
        }
    });
}

test "should update multiline snapshot" {
    const snapshot_text =
        \\1
        \\2
        \\3
    ;
    try testSnapshots(snapshot_text, struct {
        fn run(snapshot: Snapshot) !void {
            const result = snapshot.update(
                \\1
                \\2
                \\3
                \\4
                \\5
            );
            try flushSourceFiles(std.testing.allocator);
            try expectError(error.SnapshotUpdated, result);

            const content = try testReadFile();
            defer std.testing.allocator.free(content);

            try expectEqualStrings(
                \\snap(@src(),
                \\    \\1
                \\    \\2
                \\    \\3
                \\    \\4
                \\    \\5
                \\);
                \\
            , content);
        }
    });
}

test "should update multiple snapshots" {
    const snapshot_text1 =
        \\11
    ;
    const snapshot_text2 =
        \\21
    ;

    try testMultipleSnapshots(&[_][]const u8{ snapshot_text1, snapshot_text2 }, struct {
        fn run(snapshots: []Snapshot) !void {
            const result1 = snapshots[0].update(
                \\11
                \\12
            );
            const result2 = snapshots[1].update(
                \\21
                \\22
            );
            try flushSourceFiles(std.testing.allocator);

            try expectError(error.SnapshotUpdated, result1);
            try expectError(error.SnapshotUpdated, result2);

            const content = try testReadFile();
            defer std.testing.allocator.free(content);

            try expectEqualStrings(
                \\snap(@src(),
                \\    \\11
                \\    \\12
                \\);
                \\snap(@src(),
                \\    \\21
                \\    \\22
                \\);
                \\
            , content);
        }
    });
}
