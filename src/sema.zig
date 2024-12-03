const std = @import("std");
const Parser = @import("parser.zig");

pub const SemaError = error{ SemanticError, OutOfMemory };

pub fn analyze(parser: *Parser) SemaError!void {
    const root = parser.pool.getNode(0);

    for (root.root) |node_idx| {
        const node = parser.pool.getNode(node_idx);
        switch (node) {
            .assignment => {
                std.debug.print("Assignment\n", .{});
            },
            else => {},
        }
    }
}
