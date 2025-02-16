const std = @import("std");
const compile = @import("compile.zig").compile;

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    std.log.info("\nArgs: {s}", .{args});

    if (args.len < 2) {
        std.log.info("You need to provide filename!", .{});
        std.log.info("Usage: zapts <filename>", .{});
        return;
    }

    const filename = args[1];

    const cwd = try std.process.getCwdAlloc(allocator);
    const result = try compile(.{
        .gpa = allocator,
        .cwd = cwd,
        .filenames = &[_][]const u8{filename},
    });

    std.log.info("Output file:\n{s}\n", .{result[0].outputFiles[0].filename});
    std.log.info("Output:\n{s}", .{result[0].outputFiles[0].buffer});
}

test {
    _ = @import("ast.zig");
    _ = @import("consts.zig");
    _ = @import("compile.zig");
    _ = @import("lexer.zig");
    _ = @import("parser.zig");
    _ = @import("sema.zig");
    _ = @import("string_interner.zig");
    _ = @import("tests/test_parser.zig");
    _ = @import("tests/snapshots.zig");
}
