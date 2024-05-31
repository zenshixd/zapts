const std = @import("std");
const consts = @import("consts.zig");
const ArrayList = std.ArrayList;
const Token = consts.Token;
const TokenType = consts.TokenType;
const keywords_map = consts.keywords_map;
const PUNCTUATION_CHARS = consts.PUNCTUATION_CHARS;
const OPERATOR_CHARS = consts.OPERATOR_CHARS;
const WHITESPACE = consts.WHITESPACE;
const KEYWORDS = consts.KEYWORDS;
const File = std.fs.File;
const FixedBufferStream = std.io.FixedBufferStream;
const Allocator = std.mem.Allocator;

const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
const expectEqualStrings = std.testing.expectEqualStrings;

pub const LexerError = error{ SyntaxError, EndOfStream, OutOfMemory };

const Self = @This();
const Lexer = @This();

current_line: usize = 1,
allocator: Allocator,
buffer: []const u8,
index: usize = 0,

pub fn init(allocator: Allocator, buffer: []const u8) Self {
    return .{ .allocator = allocator, .buffer = buffer };
}

fn newToken(self: *Self, token_type: TokenType) Token {
    return Token{
        .type = token_type,
        .pos = self.index,
        .end = self.index,
        .line = self.current_line,
        .value = null,
    };
}

fn newTokenWithValue(self: *Self, token_type: TokenType, value: []const u8) Token {
    return Token{
        .type = token_type,
        .pos = self.index,
        .end = self.index + value.len,
        .line = self.current_line,
        .value = value,
    };
}

pub fn next(self: *Self, current_char: u8) !Token {
    switch (current_char) {
        '\n' => {
            self.current_line += 1;
            return self.newToken(TokenType.Whitespace);
        },
        '\r', ' ', '\t' => {
            return self.newToken(TokenType.Whitespace);
        },
        '<' => {
            var next_char = try self.advance();
            if (next_char == '=') {
                return self.newToken(TokenType.LessThanEqual);
            } else if (next_char == '<') {
                next_char = try self.advance();

                if (next_char == '=') {
                    return self.newToken(TokenType.LessThanLessThanEqual);
                } else {
                    try self.rewind(-1);
                    return self.newToken(TokenType.LessThanLessThan);
                }
            } else {
                try self.rewind(-1);
                return self.newToken(TokenType.LessThan);
            }
        },
        '>' => {
            var next_char = try self.advance();
            if (next_char == '=') {
                return self.newToken(TokenType.GreaterThanEqual);
            } else if (next_char == '>') {
                next_char = try self.advance();

                if (next_char == '>') {
                    next_char = try self.advance();

                    if (next_char == '=') {
                        return self.newToken(TokenType.GreaterThanGreaterThanGreaterThanEqual);
                    } else {
                        try self.rewind(-1);
                        return self.newToken(TokenType.GreaterThanGreaterThanGreaterThan);
                    }
                } else if (next_char == '=') {
                    return self.newToken(TokenType.GreaterThanGreaterThanEqual);
                } else {
                    try self.rewind(-1);
                    return self.newToken(TokenType.GreaterThanGreaterThan);
                }
            } else {
                try self.rewind(-1);
                return self.newToken(TokenType.GreaterThan);
            }
        },
        '!' => {
            var next_char = try self.advance();
            if (next_char == '=') {
                next_char = try self.advance();

                if (next_char == '=') {
                    return self.newToken(TokenType.ExclamationMarkEqualEqual);
                } else {
                    return self.newToken(TokenType.ExclamationMarkEqual);
                }
            } else {
                try self.rewind(-1);
                return self.newToken(TokenType.ExclamationMark);
            }
        },
        '/' => {
            var next_char = try self.advance();
            if (next_char == '=') {
                return self.newToken(TokenType.SlashEqual);
            } else if (next_char == '/') {
                var str = ArrayList(u8).init(self.allocator);
                defer str.deinit();
                try str.ensureTotalCapacity(100);

                while (true) {
                    next_char = try self.maybe_advance() orelse break;
                    if (next_char == '\n' or next_char == '\r') {
                        break;
                    }
                    try str.append(next_char);
                }

                return self.newTokenWithValue(TokenType.LineComment, try str.toOwnedSlice());
            } else if (next_char == '*') {
                var str = ArrayList(u8).init(self.allocator);
                defer str.deinit();
                try str.ensureTotalCapacity(100);

                while (true) {
                    next_char = try self.maybe_advance() orelse break;

                    if (next_char == '*') {
                        const one_more_char = try self.maybe_advance() orelse break;

                        if (one_more_char == '/') {
                            break;
                        } else {
                            try str.append(next_char);
                            try str.append(one_more_char);
                        }
                    } else {
                        try str.append(next_char);
                    }
                }

                return self.newTokenWithValue(TokenType.MultilineComment, try str.toOwnedSlice());
            } else {
                try self.rewind(-1);
                return self.newToken(TokenType.Slash);
            }
        },
        '&' => {
            var next_char = try self.advance();
            if (next_char == '&') {
                next_char = try self.advance();
                if (next_char == '=') {
                    return self.newToken(TokenType.AmpersandAmpersandEqual);
                } else {
                    try self.rewind(-1);
                    return self.newToken(TokenType.AmpersandAmpersand);
                }
            } else if (next_char == '=') {
                return self.newToken(TokenType.AmpersandEqual);
            } else {
                try self.rewind(-1);
                return self.newToken(TokenType.Ampersand);
            }
        },
        '^' => {
            const next_char = try self.advance();
            if (next_char == '=') {
                return self.newToken(TokenType.CaretEqual);
            } else {
                try self.rewind(-1);
                return self.newToken(TokenType.Caret);
            }
        },
        '|' => {
            var next_char = try self.advance();
            if (next_char == '|') {
                next_char = try self.advance();
                if (next_char == '=') {
                    return self.newToken(TokenType.BarBarEqual);
                } else {
                    try self.rewind(-1);
                    return self.newToken(TokenType.BarBar);
                }
            } else if (next_char == '=') {
                return self.newToken(TokenType.BarEqual);
            } else {
                try self.rewind(-1);
                return self.newToken(TokenType.Bar);
            }
        },
        '+' => {
            const next_char = try self.advance();
            if (next_char == '=') {
                return self.newToken(TokenType.PlusEqual);
            } else if (next_char == '+') {
                return self.newToken(TokenType.PlusPlus);
            } else if ((next_char > '0' and next_char < '9') or next_char == '.') {
                return self.read_numeric_literal(&[_]u8{ current_char, next_char }, next_char == '.');
            } else {
                try self.rewind(-1);
                return self.newToken(TokenType.Plus);
            }
        },
        '-' => {
            const next_char = try self.advance();
            if (next_char == '=') {
                return self.newToken(TokenType.MinusEqual);
            } else if (next_char == '-') {
                return self.newToken(TokenType.MinusMinus);
            } else if ((next_char > '0' and next_char < '9') or next_char == '.') {
                return self.read_numeric_literal(&[_]u8{ current_char, next_char }, next_char == '.');
            } else {
                try self.rewind(-1);
                return self.newToken(TokenType.Minus);
            }
        },
        '*' => {
            var next_char = try self.advance();
            if (next_char == '*') {
                next_char = try self.advance();
                if (next_char == '=') {
                    return self.newToken(TokenType.StarStarEqual);
                } else {
                    try self.rewind(-1);
                    return self.newToken(TokenType.StarStar);
                }
            } else if (next_char == '=') {
                return self.newToken(TokenType.StarEqual);
            } else {
                try self.rewind(-1);
                return self.newToken(TokenType.Star);
            }
        },
        '%' => {
            const next_char = try self.advance();
            if (next_char == '=') {
                return self.newToken(TokenType.PercentEqual);
            } else {
                try self.rewind(-1);
                return self.newToken(TokenType.Percent);
            }
        },
        '=' => {
            var next_char = try self.advance();
            if (next_char == '=') {
                next_char = try self.advance();
                if (next_char == '=') {
                    return self.newToken(TokenType.EqualEqualEqual);
                } else {
                    try self.rewind(-1);
                    return self.newToken(TokenType.EqualEqual);
                }
            } else {
                try self.rewind(-1);
                return self.newToken(TokenType.Equal);
            }
        },
        '{' => {
            return self.newToken(TokenType.OpenCurlyBrace);
        },
        '}' => {
            return self.newToken(TokenType.CloseCurlyBrace);
        },
        '[' => {
            return self.newToken(TokenType.OpenSquareBracket);
        },
        ']' => {
            return self.newToken(TokenType.CloseSquareBracket);
        },
        '(' => {
            return self.newToken(TokenType.OpenParen);
        },
        ')' => {
            return self.newToken(TokenType.CloseParen);
        },
        ',' => {
            return self.newToken(TokenType.Comma);
        },
        ';' => {
            return self.newToken(TokenType.Semicolon);
        },
        ':' => {
            return self.newToken(TokenType.Colon);
        },
        '?' => {
            var next_char = try self.advance();
            if (next_char == '?') {
                next_char = try self.advance();
                if (next_char == '=') {
                    return self.newToken(TokenType.QuestionMarkQuestionMarkEqual);
                } else {
                    try self.rewind(-1);
                    return self.newToken(TokenType.QuestionMarkQuestionMark);
                }
            } else if (next_char == '.') {
                return self.newToken(TokenType.QuestionMarkDot);
            } else {
                try self.rewind(-1);
                return self.newToken(TokenType.QuestionMark);
            }
        },
        '.' => {
            var next_char = try self.advance();
            if (next_char == '.') {
                next_char = try self.advance();
                if (next_char == '.') {
                    return self.newToken(TokenType.DotDotDot);
                } else {
                    try self.rewind(-2);
                    return self.newToken(TokenType.Dot);
                }
            } else if (next_char > '0' and next_char < '9') {
                return self.read_numeric_literal(&[_]u8{ current_char, next_char }, true);
            } else {
                try self.rewind(-1);
                return self.newToken(TokenType.Dot);
            }
        },
        '~' => {
            return self.newToken(TokenType.Tilde);
        },
        '\'', '"' => {
            var str = ArrayList(u8).init(self.allocator);
            defer str.deinit();
            try str.ensureTotalCapacity(100);

            const starting_char = current_char;
            try str.append(starting_char);
            while (true) {
                const next_char = try self.maybe_advance() orelse break;
                try str.append(next_char);

                if (next_char == '\n' or next_char == '\r' or next_char == starting_char) {
                    break;
                }
            }

            return self.newTokenWithValue(TokenType.StringConstant, try str.toOwnedSlice());
        },
        '0'...'9' => {
            return self.read_numeric_literal(&[_]u8{current_char}, false);
        },
        else => {
            var str = ArrayList(u8).init(self.allocator);
            defer str.deinit();

            try str.ensureTotalCapacity(100);
            try str.append(current_char);

            var next_char: u8 = undefined;
            while (true) {
                next_char = try self.maybe_advance() orelse break;
                if (is_whitespace(next_char) or is_punctuation(next_char) or is_operator(next_char)) {
                    try self.rewind(-1);
                    break;
                }
                try str.append(next_char);
            }

            if (keywords_map.get(str.items)) |keyword_type| {
                return self.newToken(keyword_type);
            }

            return self.newTokenWithValue(TokenType.Identifier, try str.toOwnedSlice());
        },
    }

    unreachable;
}

pub fn nextAll(self: *Self) ![]Token {
    var tokens = std.ArrayList(Token).init(self.allocator);
    defer tokens.deinit();

    if (self.buffer.len == 0) {
        try tokens.append(self.newToken(TokenType.Eof));
        return try tokens.toOwnedSlice();
    }

    var current_char: u8 = self.buffer[0];

    while (true) {
        const token = try self.next(current_char);

        if (token.type != TokenType.Whitespace and token.type != TokenType.LineComment and token.type != TokenType.MultilineComment) {
            try tokens.append(token);
        }

        current_char = self.advance() catch |err| {
            if (err == error.EndOfStream) {
                try tokens.append(self.newToken(TokenType.Eof));
                break;
            }

            return err;
        };
    }

    return tokens.toOwnedSlice();
}

fn read_numeric_literal(self: *Self, buffer: []const u8, default_has_dot: bool) !Token {
    var token_type: TokenType = TokenType.NumberConstant;
    var str = ArrayList(u8).init(self.allocator);
    defer str.deinit();
    try str.ensureTotalCapacity(100);

    var has_dot = default_has_dot;
    var has_exponent = false;

    try str.appendSlice(buffer);
    while (true) {
        const next_char = try self.maybe_advance() orelse break;

        if (next_char == '.') {
            if (has_exponent or has_dot or str.items[str.items.len - 1] == '_') {
                return LexerError.SyntaxError;
            }
            has_dot = true;
            try str.append(next_char);
            continue;
        }

        if (next_char == 'e' or next_char == 'E') {
            if (has_exponent or str.items[str.items.len - 1] == '_') {
                return LexerError.SyntaxError;
            }
            has_exponent = true;
            try str.append(next_char);
            continue;
        }

        if (next_char == '_') {
            if (str.items[str.items.len - 1] == '_' or str.items[str.items.len - 1] == '.' or str.items[str.items.len - 1] == 'e' or str.items[str.items.len - 1] == 'E') {
                return LexerError.SyntaxError;
            }

            try str.append(next_char);
            continue;
        }

        if ((next_char < '0' or next_char > '9')) {
            if (next_char == 'n') {
                try str.append(next_char);
                token_type = TokenType.BigIntConstant;
            } else {
                try self.rewind(-1);
            }
            break;
        }
        try str.append(next_char);
    }

    return self.newTokenWithValue(token_type, try str.toOwnedSlice());
}

fn advance(self: *Self) !u8 {
    self.index += 1;
    if (self.index >= self.buffer.len) {
        return error.EndOfStream;
    }
    return self.buffer[self.index];
}

fn maybe_advance(self: *Self) !?u8 {
    return self.advance() catch |err| switch (err) {
        error.EndOfStream => {
            return null;
        },
    };
}

fn match(self: *Self, expected_char: u8) !bool {
    if (self.index >= self.buffer.len) {
        return error.EndOfStream;
    }

    if (self.buffer[self.index] == expected_char) {
        self.index += 1;
        return true;
    }

    return false;
}

fn rewind(self: *Self, offset: i64) !void {
    if (offset < 0) {
        if (self.index > 0) {
            self.index -= @as(usize, @intCast(-offset));
        }
    } else {
        self.index += @as(usize, @intCast(offset));
    }
}

fn is_whitespace(s: u8) bool {
    return std.mem.indexOfScalar(u8, WHITESPACE, s) != null;
}

fn is_punctuation(s: u8) bool {
    return std.mem.indexOfScalar(u8, PUNCTUATION_CHARS, s) != null;
}

fn is_operator(s: u8) bool {
    return std.mem.indexOfScalar(u8, OPERATOR_CHARS, s) != null;
}

fn is_keyword(s: []u8) bool {
    for (KEYWORDS) |keyword| {
        if (std.mem.eql(u8, s, keyword)) {
            return true;
        }
    }

    return false;
}

test "is_whitespace" {
    try std.testing.expect(is_whitespace(' '));
    try std.testing.expect(is_whitespace('\t'));
    try std.testing.expect(is_whitespace('\n'));
    try std.testing.expect(is_whitespace('\r'));
}

test "is_punctuation" {
    try std.testing.expect(is_punctuation('.'));
    try std.testing.expect(is_punctuation(','));
    try std.testing.expect(is_punctuation(':'));
    try std.testing.expect(is_punctuation(';'));
    try std.testing.expect(is_punctuation('('));
    try std.testing.expect(is_punctuation(')'));
    try std.testing.expect(is_punctuation('['));
    try std.testing.expect(is_punctuation(']'));
    try std.testing.expect(is_punctuation('{'));
    try std.testing.expect(is_punctuation('}'));
    try std.testing.expect(is_punctuation('\''));
    try std.testing.expect(is_punctuation('"'));
}

test "is_operator" {
    try std.testing.expect(is_operator('<'));
    try std.testing.expect(is_operator('>'));
    try std.testing.expect(is_operator('?'));
    try std.testing.expect(is_operator('+'));
    try std.testing.expect(is_operator('-'));
    try std.testing.expect(is_operator('='));
    try std.testing.expect(is_operator('*'));
    try std.testing.expect(is_operator('|'));
    try std.testing.expect(is_operator('&'));
    try std.testing.expect(is_operator('!'));
    try std.testing.expect(is_operator('%'));
    try std.testing.expect(is_operator('/'));
    try std.testing.expect(is_operator('\\'));
}

test "should tokenize keywords" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const keywords = [_][]const u8{
        "var",
        "let",
        "const",
        "async",
        "await",
        "function",
        "return",
        "for",
        "while",
        "break",
        "continue",
        "do",
        "if",
        "else",
        "class",
        "extends",
        "interface",
        "type",
        "case",
        "debugger",
        "default",
        "delete",
        "enum",
        "import",
        "export",
        "false",
        "true",
        "finally",
        "try",
        "catch",
        "in",
        "instanceof",
        "new",
        "null",
        "undefined",
        "super",
        "switch",
        "this",
        "throw",
        "void",
        "with",
        "as",
        "implements",
        "package",
        "private",
        "protected",
        "public",
        "static",
        "yield",
        "from",
    };
    const expected_tokens = [_]TokenType{
        TokenType.Var,
        TokenType.Let,
        TokenType.Const,
        TokenType.Async,
        TokenType.Await,
        TokenType.Function,
        TokenType.Return,
        TokenType.For,
        TokenType.While,
        TokenType.Break,
        TokenType.Continue,
        TokenType.Do,
        TokenType.If,
        TokenType.Else,
        TokenType.Class,
        TokenType.Extends,
        TokenType.Interface,
        TokenType.Type,
        TokenType.Case,
        TokenType.Debugger,
        TokenType.Default,
        TokenType.Delete,
        TokenType.Enum,
        TokenType.Import,
        TokenType.Export,
        TokenType.False,
        TokenType.True,
        TokenType.Finally,
        TokenType.Try,
        TokenType.Catch,
        TokenType.In,
        TokenType.Instanceof,
        TokenType.New,
        TokenType.Null,
        TokenType.Undefined,
        TokenType.Super,
        TokenType.Switch,
        TokenType.This,
        TokenType.Throw,
        TokenType.Void,
        TokenType.With,
        TokenType.As,
        TokenType.Implements,
        TokenType.Package,
        TokenType.Private,
        TokenType.Protected,
        TokenType.Public,
        TokenType.Static,
        TokenType.Yield,
        TokenType.From,
    };

    var lexer = Lexer.init(arena.allocator(), try std.mem.join(arena.allocator(), " ", &keywords));
    const tokens = try lexer.nextAll();

    try expectEqual(expected_tokens.len, tokens.len - 1);
    for (expected_tokens, 0..tokens.len - 1) |expected_token, i| {
        try expectEqual(expected_token, tokens[i].type);
    }
}

test "should tokenize operators" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const operators = [_][]const u8{
        "&",
        "&&",
        "^",
        "|",
        "||",
        "+",
        "++",
        "-",
        "--",
        "*",
        "**",
        "/",
        "%",
        "!",
        "!=",
        "!==",
        "=",
        "==",
        "===",
        ">",
        ">=",
        ">>",
        ">>=",
        ">>>",
        ">>>=",
        "<",
        "<=",
        "<<",
        "<<=",
        "&=",
        "&&=",
        "|=",
        "||=",
        "^=",
        "+=",
        "-=",
        "*=",
        "**=",
        "/=",
        "%=",
        "{",
        "}",
        "[",
        "]",
        "(",
        ")",
        ".",
        "...",
        ",",
        ";",
        ":",
        "?",
        "?.",
        "??",
        "??=",
        "~",
    };
    const expected_tokens = [_]TokenType{ TokenType.Ampersand, TokenType.AmpersandAmpersand, TokenType.Caret, TokenType.Bar, TokenType.BarBar, TokenType.Plus, TokenType.PlusPlus, TokenType.Minus, TokenType.MinusMinus, TokenType.Star, TokenType.StarStar, TokenType.Slash, TokenType.Percent, TokenType.ExclamationMark, TokenType.ExclamationMarkEqual, TokenType.ExclamationMarkEqualEqual, TokenType.Equal, TokenType.EqualEqual, TokenType.EqualEqualEqual, TokenType.GreaterThan, TokenType.GreaterThanEqual, TokenType.GreaterThanGreaterThan, TokenType.GreaterThanGreaterThanEqual, TokenType.GreaterThanGreaterThanGreaterThan, TokenType.GreaterThanGreaterThanGreaterThanEqual, TokenType.LessThan, TokenType.LessThanEqual, TokenType.LessThanLessThan, TokenType.LessThanLessThanEqual, TokenType.AmpersandEqual, TokenType.AmpersandAmpersandEqual, TokenType.BarEqual, TokenType.BarBarEqual, TokenType.CaretEqual, TokenType.PlusEqual, TokenType.MinusEqual, TokenType.StarEqual, TokenType.StarStarEqual, TokenType.SlashEqual, TokenType.PercentEqual, TokenType.OpenCurlyBrace, TokenType.CloseCurlyBrace, TokenType.OpenSquareBracket, TokenType.CloseSquareBracket, TokenType.OpenParen, TokenType.CloseParen, TokenType.Dot, TokenType.DotDotDot, TokenType.Comma, TokenType.Semicolon, TokenType.Colon, TokenType.QuestionMark, TokenType.QuestionMarkDot, TokenType.QuestionMarkQuestionMark, TokenType.QuestionMarkQuestionMarkEqual, TokenType.Tilde };
    var lexer = Lexer.init(arena.allocator(), try std.mem.join(arena.allocator(), " ", &operators));
    const tokens = try lexer.nextAll();

    // we remove one because of Eof token
    try expectEqual(expected_tokens.len, tokens.len - 1);
    for (expected_tokens, 0..tokens.len - 1) |expected_token, i| {
        try expectEqual(expected_token, tokens[i].type);
    }
}

// test "should tokenize comments" {
//     var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
//     defer arena.deinit();
//
//     const buffer =
//         \\// single line comment
//         \\/*
//         \\ * multiline
//         \\ * comment
//         \\ *
//         \\ */
//     ;
//     var lexer = Lexer.init(arena.allocator(), buffer);
//     const tokens = try lexer.nextAll();
//
//     try expectEqual(TokenType.LineComment, tokens[0].type);
//     try expectEqualStrings(" single line comment", tokens[0].value.?);
//
//     try expectEqual(TokenType.MultilineComment, tokens[1].type);
//     try expectEqualStrings("\n * multiline\n * comment\n *\n ", tokens[1].value.?);
// }

test "should tokenize strings" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const buffer = "'hello' \"hello\" \"hello''world\"";
    var lexer = Lexer.init(arena.allocator(), buffer);
    const tokens = try lexer.nextAll();

    try expectEqual(TokenType.StringConstant, tokens[0].type);
    try expectEqualStrings("'hello'", tokens[0].value.?);

    try expectEqual(TokenType.StringConstant, tokens[1].type);
    try expectEqualStrings("\"hello\"", tokens[1].value.?);

    try expectEqual(TokenType.StringConstant, tokens[2].type);
    try expectEqualStrings("\"hello''world\"", tokens[2].value.?);
}

test "should tokenize decimal numbers" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const buffer = "123 123.456 123e456 123.456e456 123n 123_456 123_456n .123 .123e456 +123 -123 +123.456 -123.456 +123n -123n +123_456 -123_456 +.123 -.123 +.123e456 -.123e456";
    var lexer = Lexer.init(arena.allocator(), buffer);
    const tokens = try lexer.nextAll();

    try expectEqual(TokenType.NumberConstant, tokens[0].type);
    try expectEqualStrings("123", tokens[0].value.?);

    try expectEqual(TokenType.NumberConstant, tokens[1].type);
    try expectEqualStrings("123.456", tokens[1].value.?);

    try expectEqual(TokenType.NumberConstant, tokens[2].type);
    try expectEqualStrings("123e456", tokens[2].value.?);

    try expectEqual(TokenType.NumberConstant, tokens[3].type);
    try expectEqualStrings("123.456e456", tokens[3].value.?);

    try expectEqual(TokenType.BigIntConstant, tokens[4].type);
    try expectEqualStrings("123n", tokens[4].value.?);

    try expectEqual(TokenType.NumberConstant, tokens[5].type);
    try expectEqualStrings("123_456", tokens[5].value.?);

    try expectEqual(TokenType.BigIntConstant, tokens[6].type);
    try expectEqualStrings("123_456n", tokens[6].value.?);

    try expectEqual(TokenType.NumberConstant, tokens[7].type);
    try expectEqualStrings(".123", tokens[7].value.?);

    try expectEqual(TokenType.NumberConstant, tokens[8].type);
    try expectEqualStrings(".123e456", tokens[8].value.?);

    try expectEqual(TokenType.NumberConstant, tokens[9].type);
    try expectEqualStrings("+123", tokens[9].value.?);

    try expectEqual(TokenType.NumberConstant, tokens[10].type);
    try expectEqualStrings("-123", tokens[10].value.?);

    try expectEqual(TokenType.NumberConstant, tokens[11].type);
    try expectEqualStrings("+123.456", tokens[11].value.?);

    try expectEqual(TokenType.NumberConstant, tokens[12].type);
    try expectEqualStrings("-123.456", tokens[12].value.?);

    try expectEqual(TokenType.BigIntConstant, tokens[13].type);
    try expectEqualStrings("+123n", tokens[13].value.?);

    try expectEqual(TokenType.BigIntConstant, tokens[14].type);
    try expectEqualStrings("-123n", tokens[14].value.?);

    try expectEqual(TokenType.NumberConstant, tokens[15].type);
    try expectEqualStrings("+123_456", tokens[15].value.?);

    try expectEqual(TokenType.NumberConstant, tokens[16].type);
    try expectEqualStrings("-123_456", tokens[16].value.?);

    try expectEqual(TokenType.NumberConstant, tokens[17].type);
    try expectEqualStrings("+.123", tokens[17].value.?);

    try expectEqual(TokenType.NumberConstant, tokens[18].type);
    try expectEqualStrings("-.123", tokens[18].value.?);

    try expectEqual(TokenType.NumberConstant, tokens[19].type);
    try expectEqualStrings("+.123e456", tokens[19].value.?);

    try expectEqual(TokenType.NumberConstant, tokens[20].type);
    try expectEqualStrings("-.123e456", tokens[20].value.?);
}
