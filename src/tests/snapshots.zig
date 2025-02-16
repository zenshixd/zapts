const std = @import("std");
const assert = std.debug.assert;

const SourceLocation = std.builtin.SourceLocation;
const Allocator = std.mem.Allocator;

const expectEqual = std.testing.expectEqual;
const expectEqualStrings = std.testing.expectEqualStrings;
const expectError = std.testing.expectError;

pub const Snapshot = @This();

const SourceShift = struct {
    line_num: u32,
    line_shift: i32,
};

var source_shifts: std.StringHashMapUnmanaged(std.ArrayListUnmanaged(SourceShift)) = .empty;
var snapshots_updated: u32 = 0;

source_location: SourceLocation,
text: []const u8,
should_update: bool = false,

pub fn deinitGlobals(allocator: Allocator) void {
    var it = source_shifts.iterator();
    while (it.next()) |entry| {
        entry.value_ptr.clearAndFree(allocator);
    }
    source_shifts.clearAndFree(allocator);
}

pub fn getSnapshotsUpdated() u32 {
    return snapshots_updated;
}

pub fn openSourceDir() !std.fs.Dir {
    return try std.fs.cwd().openDir("src/", .{});
}

pub fn getSourceFile(self: Snapshot, allocator: Allocator) ![]const u8 {
    var dir = try openSourceDir();
    defer dir.close();

    var file = try dir.openFileZ(self.source_location.file, .{});
    defer file.close();

    return try file.readToEndAlloc(allocator, std.math.maxInt(u32));
}

pub const SourceFileParts = struct {
    beginning: []const u8,
    snapshot: []const u8,
    snapshot_indent: u32,
    snapshot_end_line: u32,
    ending: []const u8,
};

pub fn getSourceFileParts(self: Snapshot, content: []const u8) !SourceFileParts {
    var state: enum { begin, snapshot } = .begin;
    var begin_end_idx: usize = 0;
    var snapshot_end_idx: usize = 0;
    var snapshot_end_line: u32 = 0;
    var indent: u32 = 0;
    var it = std.mem.splitScalar(u8, content, '\n');

    var line_num: u32 = 1;
    const snapshot_begin_line = self.getSnapshotBeginLine();
    while (it.next()) |line| : (line_num += 1) {
        switch (state) {
            .begin => {
                if (line_num == snapshot_begin_line) {
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
                    snapshot_end_line = line_num - 1;
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
        .snapshot_end_line = snapshot_end_line,
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

pub fn getSnapshotBeginLine(self: Snapshot) u32 {
    if (source_shifts.getPtr(self.source_location.file)) |shifts| {
        var new_line_num = self.source_location.line;
        for (shifts.items) |shift| {
            if (new_line_num >= shift.line_num) {
                const signed_line_num: i32 = @intCast(new_line_num);
                new_line_num = @intCast(signed_line_num + shift.line_shift);
            }
        }

        return new_line_num;
    }

    return self.source_location.line;
}

pub fn writeNewSnapshot(self: Snapshot, allocator: Allocator, writer: anytype, parts: SourceFileParts, new_snapshot: []const u8) !void {
    const old_snapshot_line_count: i32 = @intCast(std.mem.count(u8, parts.snapshot, "\n"));
    var new_snapshot_line_count: i32 = 0;
    var it = std.mem.splitScalar(u8, new_snapshot, '\n');

    while (it.next()) |line| {
        for (0..parts.snapshot_indent) |_| {
            try writer.writeByte(' ');
        }
        try writer.writeAll("\\\\");
        try writer.writeAll(line);
        try writer.writeByte('\n');
        new_snapshot_line_count += 1;
    }

    const line_shift: i32 = new_snapshot_line_count - old_snapshot_line_count;
    if (line_shift != 0) {
        const result = try source_shifts.getOrPutValue(allocator, self.source_location.file, .empty);
        try result.value_ptr.append(allocator, .{
            .line_num = parts.snapshot_end_line,
            .line_shift = line_shift,
        });
    }
}

pub fn updateSourceFile(self: Snapshot, new_text: []const u8) !void {
    var dir = try openSourceDir();
    defer dir.close();

    var file = try dir.createFile(self.source_location.file, .{});
    defer file.close();

    try file.writeAll(new_text);
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

    const content = try self.getSourceFile(gpa);
    defer gpa.free(content);

    const parts = try self.getSourceFileParts(content);

    try new_file_content.appendSlice(parts.beginning);
    try self.writeNewSnapshot(gpa, new_file_content.writer(), parts, new_text);
    try new_file_content.appendSlice(parts.ending);

    try self.updateSourceFile(new_file_content.items);

    snapshots_updated += 1;
}

pub fn snap(source_location: SourceLocation, text: []const u8) Snapshot {
    return .{
        .source_location = source_location,
        .text = text,
    };
}

pub fn expectSnapshotMatch(received: anytype, expected: Snapshot) !void {
    const gpa = std.testing.allocator;
    const type_info = @typeInfo(@TypeOf(received));
    const received_text = switch (type_info) {
        .optional => try std.fmt.allocPrint(gpa, "{?}", .{received}),
        .array => try std.fmt.allocPrint(gpa, "{s}", .{received}),
        .pointer => |ptr| switch (ptr.size) {
            .one => try std.fmt.allocPrint(gpa, "{s}", .{received}),
            .slice => try std.fmt.allocPrint(gpa, "{s}", .{received}),
            else => try std.fmt.allocPrint(gpa, "{}", .{received}),
        },
        else => try std.fmt.allocPrint(gpa, "{}", .{received}),
    };
    defer gpa.free(received_text);

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
    deinitGlobals(std.testing.allocator);
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
    deinitGlobals(std.testing.allocator);
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
            try snapshot.update(
                \\2
            );

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
            try snapshot.update(
                \\1
                \\2
                \\3
                \\4
                \\5
            );

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
            try snapshots[0].update(
                \\11
                \\12
            );
            try snapshots[1].update(
                \\21
                \\22
            );

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

test "should update multiple multiline snapshots" {
    const snapshot_texts = [_][]const u8{
        \\1
        ,
        \\2
        ,
        \\3
        ,
        \\4
        ,
    };

    const updated_texts = [_][]const u8{
        \\11
        \\12
        \\13
        \\14
        ,
        \\21
        \\22
        \\23
        \\24
        ,
        \\31
        \\32
        \\33
        \\34
        ,
        \\41
        \\42
        \\43
        \\44
        ,
    };

    try testMultipleSnapshots(&snapshot_texts, struct {
        fn run(snapshots: []Snapshot) !void {
            for (snapshots, 0..) |snapshot, i| {
                try snapshot.update(updated_texts[i]);
            }

            const content = try testReadFile();
            defer std.testing.allocator.free(content);

            try expectEqualStrings(
                \\snap(@src(),
                \\    \\11
                \\    \\12
                \\    \\13
                \\    \\14
                \\);
                \\snap(@src(),
                \\    \\21
                \\    \\22
                \\    \\23
                \\    \\24
                \\);
                \\snap(@src(),
                \\    \\31
                \\    \\32
                \\    \\33
                \\    \\34
                \\);
                \\snap(@src(),
                \\    \\41
                \\    \\42
                \\    \\43
                \\    \\44
                \\);
                \\
            , content);
        }
    });
}
