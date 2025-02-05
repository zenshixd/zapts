const std = @import("std");
const assert = std.debug.assert;

const AST = @import("ast.zig");
const Token = @import("consts.zig").Token;
const Parser = @import("parser.zig");
const Reporter = @import("reporter.zig");
const diagnostics = @import("diagnostics.zig");

const Sema = @This();

pub const SemaError = error{ SemanticError, OutOfMemory };

parser: *Parser,
reporter: *Reporter,

pub fn analyze(self: Sema, root_idx: AST.Node.Index) SemaError!void {
    const node_root = self.parser.getNode(root_idx);

    for (node_root.root) |node_idx| {
        const node = self.parser.getNode(node_idx);
        switch (node) {
            .assignment => {
                std.debug.print("Assignment\n", .{});
            },
            .simple_value => try checkSimpleValue(self, node),
            else => {
                std.debug.print("Unknown node\n", .{});
            },
        }
    }
}

pub fn checkSimpleValue(self: Sema, node: AST.Node) SemaError!void {
    assert(node == .simple_value);
    if (node.simple_value.kind == .identifier) {
        self.reporter.put(diagnostics.cannot_find_name_ARG, .{"name"}, Token.at(0));
    }
}

test "analyze" {
    var reporter = Reporter.init(std.testing.allocator);
    defer reporter.deinit();

    var parser = Parser.init(std.testing.allocator, "a = b;", &reporter);
    defer parser.deinit();

    const sema = Sema{
        .parser = &parser,
        .reporter = &reporter,
    };

    const root_idx = try parser.parse();
    try sema.analyze(root_idx);
}
