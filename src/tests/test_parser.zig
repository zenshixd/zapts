const std = @import("std");

const AST = @import("../ast.zig");
const Token = @import("../consts.zig").Token;
const TokenType = @import("../consts.zig").TokenType;
const diagnostics = @import("../diagnostics.zig");
const Parser = @import("../parser.zig");
const ParserError = @import("../parser.zig").ParserError;
const Reporter = @import("../reporter.zig");
const MessageId = @import("../reporter.zig").MessageId;

const Snapshot = @import("snapshots.zig").Snapshot;
const expectSnapshotMatch = @import("snapshots.zig").expectSnapshotMatch;

const ReturnTypeOf = @import("../meta.zig").ReturnTypeOf;
const ErrorUnionOf = @import("../meta.zig").ErrorUnionOf;

const assert = std.debug.assert;
const expectEqual = std.testing.expectEqual;
const expectEqualStrings = std.testing.expectEqualStrings;
const expectEqualSlices = std.testing.expectEqualSlices;
const expectEqualDeep = std.testing.expectEqualDeep;
const expectStringStartsWith = std.testing.expectStringStartsWith;
const expectError = std.testing.expectError;

const TestParser = @This();

var arena: std.heap.ArenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);

parser: Parser,

pub fn run(text: [:0]const u8, fn_ptr: anytype) !struct { TestParser, ReturnTypeOf(fn_ptr), []Marker } {
    const sourceText, const markers = try getMarkers(arena.allocator(), text);
    const reporter = try arena.allocator().create(Reporter);
    reporter.* = Reporter.init(arena.allocator());
    var t = TestParser{
        .parser = Parser.init(arena.allocator(), sourceText, reporter),
    };
    const node = try fn_ptr(&t.parser);

    return .{ t, node, markers };
}

pub fn runCatch(text: [:0]const u8, fn_ptr: anytype) !struct { TestParser, ErrorUnionOf(fn_ptr), []Marker } {
    const sourceText, const markers = try getMarkers(arena.allocator(), text);
    const reporter = try arena.allocator().create(Reporter);
    reporter.* = Reporter.init(arena.allocator());
    var t = TestParser{
        .parser = Parser.init(arena.allocator(), sourceText, reporter),
    };

    const nodeOrError = fn_ptr(&t.parser);

    return .{ t, nodeOrError, markers };
}

pub fn deinit(_: TestParser) void {
    _ = arena.reset(.free_all);
}

pub const Marker = struct {
    pos: u32,
    line: u32,
    col: u32,

    pub fn fromText(comptime text: []const u8) Marker {
        const pos = std.mem.indexOfScalar(u8, text, '^').?;
        return Marker{ .pos = @intCast(pos), .line = 0, .col = @intCast(pos + 1) };
    }

    // LCOV_EXCL_START
    pub fn format(self: Marker, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        for (0..self.col) |_| {
            try writer.writeByte(' ');
        }
        try writer.writeByte('^');
    }
    // LCOV_EXCL_STOP
};

pub fn getMarkers(allocator: std.mem.Allocator, text: [:0]const u8) !struct { [:0]const u8, []Marker } {
    var text_buffer = std.ArrayList(u8).init(allocator);
    var marker_buffer = std.ArrayList(Marker).init(allocator);

    var prev_line_len: u32 = 0;
    var pos: u32 = 0;
    var line: u32 = 0;
    var col: u32 = 0;
    var marker_line: bool = false;

    for (0..text.len) |i| {
        const c = text[i];
        if (c == '\n') {
            marker_line = i + 1 < text.len and text[i + 1] == '>';
            prev_line_len = col;
            col = 0;

            if (!marker_line) {
                line += 1;
            }
        } else {
            col += 1;
        }

        if (marker_line) {
            if (c == '^') {
                assert(prev_line_len > 0);
                try marker_buffer.append(Marker{
                    // col is 1 based so we need to subtract 1 from it
                    .pos = @intCast(text_buffer.items.len - prev_line_len + col - 1),
                    .line = line,
                    .col = col,
                });
            }
        } else {
            try text_buffer.append(c);
        }
        pos += 1;
    }

    try text_buffer.append(0);

    return .{
        text_buffer.items[0 .. text_buffer.items.len - 1 :0],
        marker_buffer.items,
    };
}

test "should parse markers" {
    const text, const markers = try getMarkers(arena.allocator(),
        \\1234567890
        \\>    ^
        \\ 345
        \\>^
    );
    defer _ = arena.reset(.free_all);

    try expectEqualStrings("1234567890\n 345", text);
    try expectEqualDeep(Marker{
        .line = 0,
        .col = 6,
        .pos = 5,
    }, markers[0]);
    try expectEqualDeep(Marker{
        .line = 1,
        .col = 2,
        .pos = 12,
    }, markers[1]);
}

pub fn getNode(t: TestParser, node: AST.Node.Index) AST.Node {
    return t.parser.getNode(node);
}

pub fn expectAST(t: TestParser, maybe_node: ?AST.Node.Index, expected: ?AST.Node) !void {
    try std.testing.expectEqualDeep(expected, if (maybe_node) |node| t.parser.getNode(node) else null);
}

pub fn expectASTSnapshot(t: TestParser, maybe_node: ?AST.Node.Index, expected: Snapshot) !void {
    const node = if (maybe_node) |node| t.parser.getNode(node) else null;
    try expectSnapshotMatch(node, expected);
}

pub fn expectTokenAt(t: TestParser, marker: Marker, node: AST.Node.Index) !void {
    const raw = t.parser.getRawNode(node);
    const tok = t.parser.tokens.items[raw.main_token.int()];

    if (tok.start != marker.pos) {
        return t.tokenPosMismatch(marker, tok);
    }
}

pub fn getTokenAt(t: TestParser, marker: Marker) Token.Index {
    var found_token_idx: ?Token.Index = null;
    for (t.parser.tokens.items, 0..) |tok, i| {
        if (tok.start == marker.pos) {
            found_token_idx = Token.at(@intCast(i));
            break;
        }
    }

    return found_token_idx.?;
}

// LCOV_EXCL_START
pub fn tokenPosMismatch(t: TestParser, expected: Marker, tok: Token) anyerror {
    var cur_marker = std.testing.allocator.alloc(u8, t.parser.buffer.len + 1) catch unreachable;
    defer std.testing.allocator.free(cur_marker);

    for (0..cur_marker.len) |i| {
        cur_marker[i] = ' ';
    }
    cur_marker[tok.start] = '^';

    std.debug.print("expected token at:\n{s}\n{}\nfound at:\n{s}\n{s}\n", .{ t.parser.buffer, expected, t.parser.buffer, cur_marker });
    return error.TestExpectedEqual;
}
// LCOV_EXCL_STOP

pub fn expectSyntaxError(
    t: TestParser,
    nodeOrError: anytype,
    comptime expected_error: diagnostics.DiagnosticMessage,
    args: anytype,
) !void {
    try expectError(ParserError.SyntaxError, nodeOrError);
    const expected_string = try std.fmt.allocPrint(std.testing.allocator, expected_error.format(), args);
    defer std.testing.allocator.free(expected_string);

    try expectEqualStrings(expected_string, t.parser.reporter.getMessage(MessageId.at(0)));
}

pub fn expectSyntaxErrorAt(
    t: TestParser,
    nodeOrError: anytype,
    comptime expected_error: diagnostics.DiagnosticMessage,
    args: anytype,
    expected_location: Marker,
) !void {
    try t.expectSyntaxError(nodeOrError, expected_error, args);

    const loc = t.parser.reporter.errors.items(.location)[0];
    const error_token = t.parser.tokens.items[loc.int()];

    if (error_token.start != expected_location.pos) {
        return t.tokenPosMismatch(expected_location, error_token);
    }
}

pub fn expectToken(t: TestParser, expected_tok_type: TokenType, expected_value: []const u8, node: AST.Node.Index) !void {
    const raw = t.parser.getRawNode(node);
    try expectEqual(expected_tok_type, t.parser.tokens.items[raw.main_token.int()].type);
    try expectEqualStrings(expected_value, t.parser.tokens.items[raw.main_token.int()].literal(t.parser.buffer));
}

pub fn expectSimpleMethod(t: TestParser, node_idx: AST.Node.Index, expected_flags: anytype, expected_name: []const u8) !void {
    const node = t.parser.getNode(node_idx);
    try expectEqual(expected_flags, node.object_method.flags);

    const name_node = t.parser.getRawNode(node.object_method.name);
    const name_token = t.parser.tokens.items[name_node.main_token.int()].literal(t.parser.buffer);
    try expectEqualStrings(expected_name, name_token);
}

pub fn expectNodesToEqual(t: TestParser, expected_nodes: []const AST.Raw) !void {
    try expectEqualSlices(AST.Raw, expected_nodes, t.parser.ast.nodes.items[1..]);
}
