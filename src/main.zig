const std = @import("std");
const String = @import("string.zig").String;
const Lexer = @import("lexer.zig");
const fs = std.fs;
const ArrayList = std.ArrayList;

const CompileError = error{UnknownCharacter};

const CHUNK_SIZE = 1000;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const args = try std.process.argsAlloc(arena.allocator());
    std.log.info("\nArgs: {s}", .{args});

    if (args.len < 2) {
        std.log.info("You need to provide filename!", .{});
        std.log.info("Usage: zig-tsc <filename>", .{});
        return;
    }

    const filename = args[1];
    fs.cwd().access(filename, .{ .mode = .read_only }) catch |err| {
        std.log.info("Access error {}!", .{err});
        return;
    };

    var file = try fs.cwd().openFile(filename, .{ .mode = .read_only });
    defer file.close();

    var lexer = Lexer.init(arena.allocator(), .{ .file = &file });

    var token: Lexer.Token = undefined;
    while (true) {
        token = lexer.next() catch |err| {
            if (err == error.EndOfStream) {
                break;
            }

            return err;
        };
        if (token.value) |v| {
            std.log.info("token: type={} value={s} ({1d})", .{ token.type, v.value() });
        } else {
            std.log.info("token: type={}", .{token.type});
        }
    }
}
