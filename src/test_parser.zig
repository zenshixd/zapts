const std = @import("std");

const AST = @import("ast.zig");
const Token = @import("consts.zig").Token;
const TokenType = @import("consts.zig").TokenType;
const diagnostics = @import("diagnostics.zig");
const Parser = @import("parser.zig");
const CompilationError = @import("consts.zig").CompilationError;
const Reporter = @import("reporter.zig");

const ReturnTypeOf = @import("meta.zig").ReturnTypeOf;
const ErrorUnionOf = @import("meta.zig").ErrorUnionOf;

const assert = std.debug.assert;
const expectEqual = std.testing.expectEqual;
const expectEqualStrings = std.testing.expectEqualStrings;
const expectEqualSlices = std.testing.expectEqualSlices;
const expectEqualDeep = std.testing.expectEqualDeep;
const expectStringStartsWith = std.testing.expectStringStartsWith;
const expectError = std.testing.expectError;

const TestParser = @This();

reporter: *Reporter,
parser: *Parser,

pub fn run(comptime text: []const u8, comptime fn_ptr: anytype, Expects: type) !void {
    var reporter = Reporter.init(std.testing.allocator);
    defer reporter.deinit();

    const sourceText, const markers = comptime getMarkers(text);
    var parser = try Parser.init(std.testing.allocator, &sourceText, &reporter);
    defer parser.deinit();

    const node = try fn_ptr(&parser);
    const t = TestParser{ .parser = &parser, .reporter = &reporter };
    Expects.expect(t, node, markers) catch |err| {
        std.debug.print("Parsing failed, text: {s}\n", .{sourceText});
        return err;
    };
}

pub fn runAny(comptime text: []const u8, comptime fn_ptr: anytype, Expects: type) !void {
    var reporter = Reporter.init(std.testing.allocator);
    defer reporter.deinit();

    const sourceText, const markers = comptime getMarkers(text);
    var parser = try Parser.init(std.testing.allocator, &sourceText, &reporter);
    defer parser.deinit();

    const nodeOrError = fn_ptr(&parser);
    const t = TestParser{ .parser = &parser, .reporter = &reporter };
    Expects.expect(t, nodeOrError, markers) catch |err| {
        std.debug.print("Parsing failed, text: {s}\n", .{sourceText});
        return err;
    };
}

pub const Marker = struct {
    pos: u32,
    line: u32,
    col: u32,

    pub fn fromText(comptime text: []const u8) Marker {
        const pos = std.mem.indexOfScalar(u8, text, '^').?;
        return Marker{ .pos = @intCast(pos), .line = 0, .col = @intCast(pos + 1) };
    }

    pub fn asText(comptime self: Marker) [self.col]u8 {
        var buffer: [self.col]u8 = undefined;
        for (0..self.col) |i| {
            buffer[i] = ' ';
        }
        buffer[self.col - 1] = '^';
        return buffer;
    }
};

pub fn MarkerList(comptime text: []const u8) type {
    return [std.mem.count(u8, text, "^")]Marker;
}

pub fn getMarkers(comptime text: []const u8) struct { [text.len:0]u8, MarkerList(text) } {
    var text_pos: u32 = 0;
    var prev_line_len: u32 = 0;
    var text_buffer: [text.len:0]u8 = undefined;

    var marker_buffer: MarkerList(text) = undefined;
    var pos: u32 = 0;
    var line: u32 = 0;
    var col: u32 = 0;
    var marker_count: u32 = 0;
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
                marker_buffer[marker_count] = Marker{
                    // col is 1 based so we need to subtract 1 from it
                    .pos = text_pos - prev_line_len + col - 1,
                    .line = line,
                    .col = col,
                };
                marker_count += 1;
            }
        } else {
            text_buffer[text_pos] = c;
        }

        if (!marker_line) {
            text_pos += 1;
        }
        pos += 1;
    }

    text_buffer[text_pos] = 0;

    return .{
        text_buffer,
        marker_buffer,
    };
}

test "should parse markers" {
    const text, const markers = getMarkers(
        \\1234567890
        \\>    ^
        \\ 345
        \\>^
    );

    try expectEqualStrings("1234567890\n 345", std.mem.sliceTo(&text, 0));
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

pub fn expectTokenAt(t: TestParser, comptime marker: Marker, node: AST.Node.Index) !void {
    const raw = t.parser.getRawNode(node);
    const tok = t.parser.tokens[raw.main_token.int()];

    if (tok.start != marker.pos) {
        return t.tokenPosMismatch(marker, tok);
    }
}

pub fn getTokenAt(t: TestParser, comptime marker: Marker) Token.Index {
    var found_token_idx: ?Token.Index = null;
    for (t.parser.tokens, 0..) |tok, i| {
        if (tok.start == marker.pos) {
            found_token_idx = Token.at(@intCast(i));
            break;
        }
    }

    return found_token_idx.?;
}

pub fn tokenPosMismatch(t: TestParser, comptime expected: Marker, tok: Token) anyerror {
    var cur_marker = std.testing.allocator.alloc(u8, t.parser.buffer.len + 1) catch unreachable;
    defer std.testing.allocator.free(cur_marker);

    for (0..cur_marker.len) |i| {
        cur_marker[i] = ' ';
    }
    cur_marker[tok.start] = '^';

    std.debug.print("expected token at:\n{s}\n{s}\nfound at:\n{s}\n{s}\n", .{ t.parser.buffer, expected.asText(), t.parser.buffer, cur_marker });
    return error.TestExpectedEqual;
}

pub fn expectSyntaxError(
    t: TestParser,
    nodeOrError: anytype,
    comptime expected_error: diagnostics.DiagnosticMessage,
    args: anytype,
) !void {
    try expectError(CompilationError.SyntaxError, nodeOrError);
    const expected_string = try std.fmt.allocPrint(std.testing.allocator, expected_error.format(), args);
    defer std.testing.allocator.free(expected_string);

    try expectEqualStrings(t.reporter.errors.items(.message)[0], expected_string);
}

pub fn expectSyntaxErrorAt(
    t: TestParser,
    nodeOrError: anytype,
    comptime expected_error: diagnostics.DiagnosticMessage,
    args: anytype,
    comptime expected_location: Marker,
) !void {
    try t.expectSyntaxError(nodeOrError, expected_error, args);

    const loc = t.reporter.errors.items(.location)[0];
    const error_token = t.parser.tokens[loc.int()];

    if (error_token.start != expected_location.pos) {
        return t.tokenPosMismatch(expected_location, error_token);
    }
}

pub fn expectToken(t: TestParser, expected_tok_type: TokenType, expected_value: []const u8, node: AST.Node.Index) !void {
    const raw = t.parser.getRawNode(node);
    try expectEqual(expected_tok_type, t.parser.tokens[raw.main_token.int()].type);
    try expectEqualStrings(expected_value, t.parser.tokens[raw.main_token.int()].literal(t.parser.buffer));
}

pub fn expectSimpleMethod(t: TestParser, node_idx: AST.Node.Index, expected_flags: anytype, expected_name: []const u8) !void {
    const node = t.parser.getNode(node_idx);
    try expectEqual(expected_flags, node.object_method.flags);

    const name_node = t.parser.getRawNode(node.object_method.name);
    const name_token = t.parser.tokens[name_node.main_token.int()].literal(t.parser.buffer);
    try expectEqualStrings(expected_name, name_token);
}

pub fn expectNodesToEqual(t: TestParser, expected_nodes: []const AST.Raw) !void {
    try expectEqualSlices(AST.Raw, expected_nodes, t.parser.nodes.items[1..]);
}
