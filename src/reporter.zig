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
allocator: std.mem.Allocator,

pub fn init(allocator: std.mem.Allocator) Self {
    return .{
        .errors = std.MultiArrayList(Message){},
        .allocator = allocator,
    };
}

pub fn deinit(self: *Self) void {
    for (self.errors.items(.message)) |message| {
        self.allocator.free(message);
    }
    self.errors.deinit(self.allocator);
}

pub fn put(self: *Self, comptime message: diagnostics.DiagnosticMessage, args: anytype, location: Token.Index) void {
    self.errors.append(self.allocator, Message.init(self.allocator, message, args, location)) catch @panic("Out of memory");
}

pub fn print(self: *Self) void {
    const stderr = std.io.getStdErr().writer();
    for (self.errors.items) |message| {
        stderr.print("{s}\n", .{message.message}) catch @panic("Out of memory");
    }
}
