const std = @import("std");
pub const Lexer = @import("lexer.zig");
pub const Token = @import("consts.zig").Token;
pub const TokenType = @import("consts.zig").TokenType;
pub const Parser = @import("parser.zig");
pub const SymbolsTable = @import("symbol_table.zig").SymbolTable;
const fs = std.fs;
const ArrayList = std.ArrayList;

// 10 MB ?
const MAX_FILE_SIZE = 10 * 1024 * 1024;

pub fn main() !void {
    var allocator = std.heap.page_allocator;

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    std.log.info("\nArgs: {s}", .{args});

    if (args.len < 2) {
        std.log.info("You need to provide filename!", .{});
        std.log.info("Usage: zapts <filename>", .{});
        return;
    }

    const filename = args[1];
    fs.cwd().access(filename, .{ .mode = .read_only }) catch |err| {
        std.log.info("Access error {}!", .{err});
        return;
    };

    var file = try fs.cwd().openFile(filename, .{ .mode = .read_only });
    defer file.close();

    const buffer = try file.readToEndAlloc(allocator, MAX_FILE_SIZE);

    var lexer = Lexer.init(allocator, buffer);

    const tokens = try lexer.nextAll();

    allocator.free(buffer);

    for (tokens) |token| {
        if (token.value) |v| {
            std.log.info("token: type={} value={s} ({1d})", .{ token.type, v });
        } else {
            std.log.info("token: type={}", .{token.type});
        }
    }

    var parser = Parser.init(allocator, tokens);
    const nodes = parser.parse() catch |err| {
        std.log.info("Parse error: {}", .{err});
        for (parser.errors.items) |parser_error| {
            std.log.info("  {s}", .{parser_error});
        }
        return;
    };

    for (nodes) |node| {
        std.log.info("{}", .{node});
    }
}

test {
    _ = @import("lexer.zig");
    _ = @import("parser.zig");
}
