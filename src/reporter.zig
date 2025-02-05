const std = @import("std");
const Token = @import("consts.zig").Token;
const diagnostics = @import("diagnostics.zig");

const Self = @This();

pub const Message = struct {
    message: []const u8,
    location: Token.Index,

    pub fn init(allocator: std.mem.Allocator, comptime message: diagnostics.DiagnosticMessage, args: anytype, location: Token.Index) Message {
        return .{
            .message = std.fmt.allocPrint(allocator, message.format(), args) catch @panic("Out of memory"),
            .location = location,
        };
    }
};

errors: std.MultiArrayList(Message),
arena: std.heap.ArenaAllocator,

pub fn init(allocator: std.mem.Allocator) Self {
    return .{
        .errors = std.MultiArrayList(Message){},
        .arena = std.heap.ArenaAllocator.init(allocator),
    };
}

pub fn deinit(self: *Self) void {
    self.arena.deinit();
}

pub fn put(self: *Self, comptime message: diagnostics.DiagnosticMessage, args: anytype, location: Token.Index) void {
    self.errors.append(self.arena.allocator(), Message.init(self.arena.allocator(), message, args, location)) catch @panic("Out of memory");
}

pub fn print(self: *Self, tokens: []const Token) void {
    const stderr = std.io.getStdErr().writer();
    for (0..self.errors.len) |i| {
        stderr.print("{s}\n", .{self.errors.items(.message)[i]}) catch @panic("Out of memory");
        stderr.print("at token: {}\n", .{tokens[self.errors.items(.location)[i].int()]}) catch @panic("Out of memory");
    }
}
