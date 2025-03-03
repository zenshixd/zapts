const std = @import("std");
const Token = @import("consts.zig").Token;
const diagnostics = @import("diagnostics.zig");

const Self = @This();

pub const MessageId = enum(u32) {
    _,

    pub inline fn at(index: u32) MessageId {
        return @enumFromInt(index);
    }
};

pub const Message = struct {
    message: MessageId,
    location: Token.Index,
};

pub const MessageLocation = struct {
    pos: u32,
    len: u32,
};

pub const ErrorList = std.MultiArrayList(Message);

gpa: std.mem.Allocator,
errors: ErrorList = .empty,
messages_bytes: std.ArrayListUnmanaged(u8) = .empty,
messages_table: std.ArrayListUnmanaged(MessageLocation) = .empty,

pub fn init(allocator: std.mem.Allocator) Self {
    return .{
        .gpa = allocator,
    };
}

pub fn deinit(self: *Self) void {
    self.messages_bytes.deinit(self.gpa);
    self.messages_table.deinit(self.gpa);
    self.errors.deinit(self.gpa);
}

pub fn getMessage(self: Self, index: MessageId) []const u8 {
    const loc = self.messages_table.items[@intFromEnum(index)];
    return self.messages_bytes.items[loc.pos..][0..loc.len];
}

pub fn put(self: *Self, comptime message: diagnostics.DiagnosticMessage, args: anytype, location: Token.Index) void {
    const pos = self.messages_bytes.items.len;
    std.fmt.format(self.messages_bytes.writer(self.gpa), message.format(), args) catch @panic("Out of memory");

    const index = self.messages_table.items.len;
    self.messages_table.append(self.gpa, .{
        .pos = @intCast(pos),
        .len = @intCast(self.messages_bytes.items.len - pos),
    }) catch @panic("Out of memory");

    self.errors.append(self.gpa, .{
        .message = MessageId.at(@intCast(index)),
        .location = location,
    }) catch @panic("Out of memory");
}

pub fn print(self: *Self, tokens: []const Token) void {
    const stderr = std.io.getStdErr().writer();
    for (0..self.errors.len) |i| {
        const message_id = self.errors.items(.message)[i];
        stderr.print("{s}\n", .{self.getMessage(message_id)}) catch @panic("Out of memory");
        stderr.print("at token: {}\n", .{tokens[@intFromEnum(self.errors.items(.location)[i])]}) catch @panic("Out of memory");
    }
}

pub fn toOwnedSlice(self: *Self) !ErrorList.Slice {
    return self.errors.toOwnedSlice();
}
