const std = @import("std");
const Lexer = @import("lexer.zig");
const Parser = @import("parser.zig");
const Printer = @import("printer.zig");
const OutputFiles = @import("printer.zig").OutputFiles;

const fs = std.fs;
const ArrayList = std.ArrayList;

// ~4 GB max file size
pub const MAX_FILE_SIZE = std.math.maxInt(u32);

pub const CompileOptions = struct {
    gpa: std.mem.Allocator,
    cwd: []const u8,
    filenames: []const []const u8,
};

pub const CompileResult = struct {
    source_filename: []const u8,
    source_buffer: []const u8,
    outputFiles: []OutputFiles,
};

pub fn compile(opts: CompileOptions) ![]CompileResult {
    var cwd_dir = try fs.openDirAbsolute(opts.cwd, .{});
    defer cwd_dir.close();

    var result = std.ArrayList(CompileResult).init(opts.gpa);

    for (opts.filenames) |filename| {
        fs.cwd().access(filename, .{ .mode = .read_only }) catch |err| {
            std.log.info("Access error {}!", .{err});
            return err;
        };

        var file = try cwd_dir.openFile(filename, .{ .mode = .read_only });
        defer file.close();

        const buffer = try file.readToEndAlloc(opts.gpa, MAX_FILE_SIZE);
        const output = try compileBuffer(opts.gpa, filename, buffer);

        try result.append(output);
    }

    return result.items;
}

pub fn compileBuffer(allocator: std.mem.Allocator, filename: []const u8, buffer: []const u8) !CompileResult {
    var parser = try Parser.init(allocator, buffer);
    defer parser.deinit();

    _ = parser.parse() catch |err| {
        std.log.info("Error: {}", .{err});
        std.log.info("Current token: {}", .{parser.tokens.items[parser.cur_token]});
        for (parser.errors.items) |parser_error| {
            std.log.info("{s}", .{parser_error});
        }
        return err;
    };

    for (parser.errors.items) |parser_error| {
        std.debug.print("Error: {s}\n", .{parser_error});
    }

    var printer = Printer.init(allocator, filename, &parser.tokens, &parser.pool);

    const output = try printer.print();

    return CompileResult{
        .source_filename = filename,
        .source_buffer = buffer,
        .outputFiles = try allocator.dupe(OutputFiles, &.{output}),
    };
}
