const std = @import("std");
const Token = @import("consts.zig").Token;
const diagnostics = @import("diagnostics.zig");

pub const CompilationError = error{ SyntaxError, OutOfMemory };

pub const CompilationErrorMessage = struct {
    message: []const u8,
    location: Token.Index,

    pub fn init(allocator: std.mem.Allocator, comptime message: diagnostics.DiagnosticMessage, args: anytype, location: Token.Index) CompilationErrorMessage {
        return .{
            .message = std.fmt.allocPrint(allocator, "TS" ++ message.code ++ ": " ++ message.message, args) catch @panic("Out of memory"),
            .location = location,
        };
    }
};
