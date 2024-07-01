const std = @import("std");
const compile = @import("compile.zig").compile;
const raw_allocator = @import("./raw_allocator.zig");
const JdzAllocator = @import("jdz_allocator").JdzAllocator;

pub fn main() !void {
    var jdz = JdzAllocator(.{
        .backing_allocator = raw_allocator.allocator(),
    }).init();
    defer jdz.deinit();

    const allocator = jdz.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    std.log.info("\nArgs: {s}", .{args});

    if (args.len < 2) {
        std.log.info("You need to provide filename!", .{});
        std.log.info("Usage: zapts <filename>", .{});
        return;
    }

    const filename = args[1];

    const result = try compile(allocator, filename);

    defer allocator.free(result.file_name);
    defer allocator.free(result.output);

    std.log.info("Output:\n{s}", .{result.output});
}
test {
    _ = @import("compile.zig");
    _ = @import("lexer.zig");
}
