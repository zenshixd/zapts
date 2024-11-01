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

allocator: Allocator,
buffer: []const u8,
index: u32 = 0,
toks: std.ArrayList(Token),
strings: std.ArrayList([]const u8),

pub fn init(allocator: Allocator, buffer: []const u8) Self {
    return .{
        .allocator = allocator,
        .buffer = buffer,
        .toks = std.ArrayList(Token).init(allocator),
        .strings = std.ArrayList([]const u8).init(allocator),
    };
}

pub fn deinit(self: *Self) void {
    self.toks.deinit();
    self.strings.deinit();
}

pub fn tokens(self: Self) []Token {
    return self.toks.items;
}

pub fn getToken(self: Self, tok_idx: usize) Token {
    return self.toks.items[tok_idx];
}

pub fn getTokenValue(self: Self, tok_idx: usize) ?[]const u8 {
    const tok = self.getToken(tok_idx);
    if (tok.string_idx) |string_idx| {
        return self.strings.items[string_idx];
    }

    return null;
}

fn newToken(self: *Self, token_type: TokenType) !void {
    try self.toks.append(Token{
        .type = token_type,
        .pos = self.index,
        .string_idx = null,
    });
}

fn newTokenWithValue(self: *Self, token_type: TokenType, value: []const u8) !void {
    if (token_type == .LineComment or token_type == .MultilineComment) {
        return;
    }

    const string_idx = self.strings.items.len;
    try self.strings.append(value);
    try self.toks.append(Token{
        .type = token_type,
        .pos = self.index,
        .string_idx = @intCast(string_idx),
    });
}

pub fn tokenize(self: *Self) !void {
    if (self.buffer.len == 0) {
        try self.newToken(TokenType.Eof);
        return;
    }

    while (true) : (self.index += 1) {
        if (self.index >= self.buffer.len) {
            try self.newToken(TokenType.Eof);
            return;
        }

        const current_char = self.buffer[self.index];
        switch (current_char) {
            '\n', '\r', ' ', '\t' => {},
            '<' => {
                var next_char = try self.advance();
                if (next_char == '=') {
                    try self.newToken(TokenType.LessThanEqual);
                } else if (next_char == '<') {
                    next_char = try self.advance();

                    if (next_char == '=') {
                        try self.newToken(TokenType.LessThanLessThanEqual);
                    } else {
                        try self.rewind(-1);
                        try self.newToken(TokenType.LessThanLessThan);
                    }
                } else {
                    try self.rewind(-1);
                    try self.newToken(TokenType.LessThan);
                }
            },
            '>' => {
                var next_char = try self.advance();
                if (next_char == '=') {
                    try self.newToken(TokenType.GreaterThanEqual);
                } else if (next_char == '>') {
                    next_char = try self.advance();

                    if (next_char == '>') {
                        next_char = try self.advance();

                        if (next_char == '=') {
                            try self.newToken(TokenType.GreaterThanGreaterThanGreaterThanEqual);
                        } else {
                            try self.rewind(-1);
                            try self.newToken(TokenType.GreaterThanGreaterThanGreaterThan);
                        }
                    } else if (next_char == '=') {
                        try self.newToken(TokenType.GreaterThanGreaterThanEqual);
                    } else {
                        try self.rewind(-1);
                        try self.newToken(TokenType.GreaterThanGreaterThan);
                    }
                } else {
                    try self.rewind(-1);
                    try self.newToken(TokenType.GreaterThan);
                }
            },
            '!' => {
                var next_char = try self.advance();
                if (next_char == '=') {
                    next_char = try self.advance();

                    if (next_char == '=') {
                        try self.newToken(TokenType.ExclamationMarkEqualEqual);
                    } else {
                        try self.newToken(TokenType.ExclamationMarkEqual);
                    }
                } else {
                    try self.rewind(-1);
                    try self.newToken(TokenType.ExclamationMark);
                }
            },
            '/' => {
                var next_char = try self.advance();
                if (next_char == '=') {
                    try self.newToken(TokenType.SlashEqual);
                } else if (next_char == '/') {
                    const start_index = self.index - 1;
                    var end_index: u32 = start_index;

                    while (true) {
                        next_char = try self.maybe_advance() orelse break;
                        if (next_char == '\n' or next_char == '\r') {
                            break;
                        }
                        end_index += 1;
                    }

                    try self.newTokenWithValue(TokenType.LineComment, self.buffer[start_index..end_index]);
                } else if (next_char == '*') {
                    const start_index = self.index - 1;
                    var end_index: u32 = start_index;

                    while (true) {
                        next_char = try self.maybe_advance() orelse break;

                        if (next_char == '*') {
                            const one_more_char = try self.maybe_advance() orelse break;

                            if (one_more_char == '/') {
                                break;
                            } else {
                                end_index += 2;
                            }
                        } else {
                            end_index += 1;
                        }
                    }

                    try self.newTokenWithValue(TokenType.MultilineComment, self.buffer[start_index..end_index]);
                } else {
                    try self.rewind(-1);
                    try self.newToken(TokenType.Slash);
                }
            },
            '&' => {
                var next_char = try self.advance();
                if (next_char == '&') {
                    next_char = try self.advance();
                    if (next_char == '=') {
                        try self.newToken(TokenType.AmpersandAmpersandEqual);
                    } else {
                        try self.rewind(-1);
                        try self.newToken(TokenType.AmpersandAmpersand);
                    }
                } else if (next_char == '=') {
                    try self.newToken(TokenType.AmpersandEqual);
                } else {
                    try self.rewind(-1);
                    try self.newToken(TokenType.Ampersand);
                }
            },
            '^' => {
                const next_char = try self.advance();
                if (next_char == '=') {
                    try self.newToken(TokenType.CaretEqual);
                } else {
                    try self.rewind(-1);
                    try self.newToken(TokenType.Caret);
                }
            },
            '|' => {
                var next_char = try self.advance();
                if (next_char == '|') {
                    next_char = try self.advance();
                    if (next_char == '=') {
                        try self.newToken(TokenType.BarBarEqual);
                    } else {
                        try self.rewind(-1);
                        try self.newToken(TokenType.BarBar);
                    }
                } else if (next_char == '=') {
                    try self.newToken(TokenType.BarEqual);
                } else {
                    try self.rewind(-1);
                    try self.newToken(TokenType.Bar);
                }
            },
            '+' => {
                const next_char = try self.advance();
                if (next_char == '=') {
                    try self.newToken(TokenType.PlusEqual);
                } else if (next_char == '+') {
                    try self.newToken(TokenType.PlusPlus);
                } else {
                    try self.rewind(-1);
                    try self.newToken(TokenType.Plus);
                }
            },
            '-' => {
                const next_char = try self.advance();
                if (next_char == '=') {
                    try self.newToken(TokenType.MinusEqual);
                } else if (next_char == '-') {
                    try self.newToken(TokenType.MinusMinus);
                } else {
                    try self.rewind(-1);
                    try self.newToken(TokenType.Minus);
                }
            },
            '*' => {
                var next_char = try self.advance();
                if (next_char == '*') {
                    next_char = try self.advance();
                    if (next_char == '=') {
                        try self.newToken(TokenType.StarStarEqual);
                    } else {
                        try self.rewind(-1);
                        try self.newToken(TokenType.StarStar);
                    }
                } else if (next_char == '=') {
                    try self.newToken(TokenType.StarEqual);
                } else {
                    try self.rewind(-1);
                    try self.newToken(TokenType.Star);
                }
            },
            '%' => {
                const next_char = try self.advance();
                if (next_char == '=') {
                    try self.newToken(TokenType.PercentEqual);
                } else {
                    try self.rewind(-1);
                    try self.newToken(TokenType.Percent);
                }
            },
            '=' => {
                var next_char = try self.advance();
                if (next_char == '=') {
                    next_char = try self.advance();
                    if (next_char == '=') {
                        try self.newToken(TokenType.EqualEqualEqual);
                    } else {
                        try self.rewind(-1);
                        try self.newToken(TokenType.EqualEqual);
                    }
                } else if (next_char == '>') {
                    try self.newToken(TokenType.Arrow);
                } else {
                    try self.rewind(-1);
                    try self.newToken(TokenType.Equal);
                }
            },
            '{' => {
                try self.newToken(TokenType.OpenCurlyBrace);
            },
            '}' => {
                try self.newToken(TokenType.CloseCurlyBrace);
            },
            '[' => {
                try self.newToken(TokenType.OpenSquareBracket);
            },
            ']' => {
                try self.newToken(TokenType.CloseSquareBracket);
            },
            '(' => {
                try self.newToken(TokenType.OpenParen);
            },
            ')' => {
                try self.newToken(TokenType.CloseParen);
            },
            ',' => {
                try self.newToken(TokenType.Comma);
            },
            ';' => {
                try self.newToken(TokenType.Semicolon);
            },
            ':' => {
                try self.newToken(TokenType.Colon);
            },
            '?' => {
                var next_char = try self.advance();
                if (next_char == '?') {
                    next_char = try self.advance();
                    if (next_char == '=') {
                        try self.newToken(TokenType.QuestionMarkQuestionMarkEqual);
                    } else {
                        try self.rewind(-1);
                        try self.newToken(TokenType.QuestionMarkQuestionMark);
                    }
                } else if (next_char == '.') {
                    try self.newToken(TokenType.QuestionMarkDot);
                } else {
                    try self.rewind(-1);
                    try self.newToken(TokenType.QuestionMark);
                }
            },
            '.' => {
                var next_char = try self.advance();
                if (next_char == '.') {
                    next_char = try self.advance();
                    if (next_char == '.') {
                        try self.newToken(TokenType.DotDotDot);
                    } else {
                        try self.rewind(-2);
                        try self.newToken(TokenType.Dot);
                    }
                } else if (next_char > '0' and next_char < '9') {
                    try self.readNumericLiteral(self.index - 1, true);
                } else {
                    try self.rewind(-1);
                    try self.newToken(TokenType.Dot);
                }
            },
            '~' => {
                try self.newToken(TokenType.Tilde);
            },
            '#' => {
                try self.newToken(TokenType.Hash);
            },
            '\'', '"' => {
                const start_pos = self.index;
                var end_pos = self.index + 1;

                const starting_char = current_char;
                while (true) {
                    const next_char = try self.maybe_advance() orelse break;
                    end_pos += 1;

                    if (next_char == '\n' or next_char == '\r' or next_char == starting_char) {
                        break;
                    }
                }

                try self.newTokenWithValue(TokenType.StringConstant, self.buffer[start_pos..end_pos]);
            },
            '0'...'9' => {
                try self.readNumericLiteral(self.index, false);
            },
            else => {
                const start_pos = self.index;
                var end_pos = self.index + 1;
                var next_char: u8 = undefined;
                while (true) {
                    next_char = try self.maybe_advance() orelse break;
                    if (is_whitespace(next_char) or is_punctuation(next_char) or is_operator(next_char)) {
                        try self.rewind(-1);
                        break;
                    }
                    end_pos += 1;
                }

                if (keywords_map.get(self.buffer[start_pos..end_pos])) |keyword_type| {
                    try self.newToken(keyword_type);
                } else {
                    try self.newTokenWithValue(TokenType.Identifier, self.buffer[start_pos..end_pos]);
                }

                self.index = end_pos - 1;
            },
        }
    }
}

fn readNumericLiteral(self: *Self, start_index: u32, default_has_dot: bool) !void {
    var token_type: TokenType = TokenType.NumberConstant;

    var has_dot = default_has_dot;
    var has_exponent = false;

    var end_index: u32 = start_index;
    while (true) {
        const next_char = try self.maybe_advance() orelse break;

        if (next_char == '.') {
            if (has_exponent or has_dot or self.buffer[end_index - 1] == '_') {
                return LexerError.SyntaxError;
            }
            has_dot = true;
            end_index += 1;
            continue;
        }

        if (next_char == 'e' or next_char == 'E') {
            if (has_exponent or self.buffer[end_index - 1] == '_') {
                return LexerError.SyntaxError;
            }
            has_exponent = true;
            end_index += 1;
            continue;
        }

        if (next_char == '_') {
            if (self.buffer[end_index - 1] == '_' or self.buffer[end_index - 1] == '.' or self.buffer[end_index - 1] == 'e' or self.buffer[end_index - 1] == 'E') {
                return LexerError.SyntaxError;
            }

            end_index += 1;
            continue;
        }

        if ((next_char < '0' or next_char > '9')) {
            if (next_char == 'n') {
                end_index += 1;
                token_type = TokenType.BigIntConstant;
            } else {
                try self.rewind(-1);
            }
            break;
        }
        end_index += 1;
    }

    end_index += 1;
    if (default_has_dot) {
        end_index += 1;
    }

    try self.newTokenWithValue(token_type, self.buffer[start_index..end_index]);
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

fn rewind(self: *Self, offset: i32) !void {
    if (offset < 0) {
        if (self.index > 0) {
            self.index -= @as(u32, @intCast(-offset));
        }
    } else {
        self.index += @as(u32, @intCast(offset));
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
    try lexer.tokenize();

    try expectEqual(expected_tokens.len, lexer.tokens().len - 1);
    for (expected_tokens, 0..) |expected_token, i| {
        const token = lexer.getToken(i);
        try expectEqual(expected_token, token.type);
    }
}

test "should tokenize identifiers" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const expected_tokens = [_]TokenType{
        TokenType.Identifier,
        TokenType.Identifier,
        TokenType.Identifier,
    };
    const expected_values = [_][]const u8{
        "foo",
        "bar",
        "baz",
    };
    const buffer = "foo bar baz";
    var lexer = Lexer.init(arena.allocator(), buffer);
    try lexer.tokenize();

    try expectEqual(expected_tokens.len, lexer.tokens().len - 1);
    for (expected_tokens, 0..) |expected_token, i| {
        const token = lexer.getToken(i);
        try expectEqual(expected_token, token.type);
        try expectEqualStrings(expected_values[i], lexer.getTokenValue(i).?);
    }
}

test "should parse both identifiers and operators" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const buffer = "a + b a+b c;";
    var lexer = Lexer.init(arena.allocator(), buffer);
    try lexer.tokenize();

    const expected_tokens = .{
        .{ TokenType.Identifier, "a" },
        .{ TokenType.Plus, "+" },
        .{ TokenType.Identifier, "b" },
        .{ TokenType.Identifier, "a" },
        .{ TokenType.Plus, "+" },
        .{ TokenType.Identifier, "b" },
        .{ TokenType.Identifier, "c" },
        .{ TokenType.Semicolon, ";" },
    };

    inline for (expected_tokens, 0..) |expected_token, i| {
        const token = lexer.getToken(i);
        try expectEqual(expected_token[0], token.type);
        try expectEqualStrings(expected_token[1], lexer.getTokenValue(i) orelse token.lexeme());
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
    const expected_tokens = [_]TokenType{
        TokenType.Ampersand,
        TokenType.AmpersandAmpersand,
        TokenType.Caret,
        TokenType.Bar,
        TokenType.BarBar,
        TokenType.Plus,
        TokenType.PlusPlus,
        TokenType.Minus,
        TokenType.MinusMinus,
        TokenType.Star,
        TokenType.StarStar,
        TokenType.Slash,
        TokenType.Percent,
        TokenType.ExclamationMark,
        TokenType.ExclamationMarkEqual,
        TokenType.ExclamationMarkEqualEqual,
        TokenType.Equal,
        TokenType.EqualEqual,
        TokenType.EqualEqualEqual,
        TokenType.GreaterThan,
        TokenType.GreaterThanEqual,
        TokenType.GreaterThanGreaterThan,
        TokenType.GreaterThanGreaterThanEqual,
        TokenType.GreaterThanGreaterThanGreaterThan,
        TokenType.GreaterThanGreaterThanGreaterThanEqual,
        TokenType.LessThan,
        TokenType.LessThanEqual,
        TokenType.LessThanLessThan,
        TokenType.LessThanLessThanEqual,
        TokenType.AmpersandEqual,
        TokenType.AmpersandAmpersandEqual,
        TokenType.BarEqual,
        TokenType.BarBarEqual,
        TokenType.CaretEqual,
        TokenType.PlusEqual,
        TokenType.MinusEqual,
        TokenType.StarEqual,
        TokenType.StarStarEqual,
        TokenType.SlashEqual,
        TokenType.PercentEqual,
        TokenType.OpenCurlyBrace,
        TokenType.CloseCurlyBrace,
        TokenType.OpenSquareBracket,
        TokenType.CloseSquareBracket,
        TokenType.OpenParen,
        TokenType.CloseParen,
        TokenType.Dot,
        TokenType.DotDotDot,
        TokenType.Comma,
        TokenType.Semicolon,
        TokenType.Colon,
        TokenType.QuestionMark,
        TokenType.QuestionMarkDot,
        TokenType.QuestionMarkQuestionMark,
        TokenType.QuestionMarkQuestionMarkEqual,
        TokenType.Tilde,
    };
    var lexer = Lexer.init(arena.allocator(), try std.mem.join(arena.allocator(), " ", &operators));
    try lexer.tokenize();

    // we remove one because of Eof token
    try expectEqual(expected_tokens.len, lexer.tokens().len - 1);
    for (expected_tokens, 0..) |expected_token, i| {
        const token = lexer.getToken(i);
        try expectEqual(expected_token, token.type);
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
    try lexer.tokenize();

    var token = lexer.getToken(0);
    try expectEqual(TokenType.StringConstant, token.type);
    try expectEqualStrings("'hello'", lexer.getTokenValue(0).?);

    token = lexer.getToken(1);
    try expectEqual(TokenType.StringConstant, token.type);
    try expectEqualStrings("\"hello\"", lexer.getTokenValue(1).?);

    token = lexer.getToken(2);
    try expectEqual(TokenType.StringConstant, token.type);
    try expectEqualStrings("\"hello''world\"", lexer.getTokenValue(2).?);
}

test "should tokenize decimal numbers" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const expected_tokens = .{
        .{ TokenType.NumberConstant, "123" },
        .{ TokenType.NumberConstant, "123.456" },
        .{ TokenType.NumberConstant, "123e456" },
        .{ TokenType.NumberConstant, "123.456e456" },
        .{ TokenType.BigIntConstant, "123n" },
        .{ TokenType.NumberConstant, "123_456" },
        .{ TokenType.BigIntConstant, "123_456n" },
        .{ TokenType.NumberConstant, ".123" },
        .{ TokenType.NumberConstant, ".123e456" },
    };

    const buffer = "123 123.456 123e456 123.456e456 123n 123_456 123_456n .123 .123e456";
    var lexer = Lexer.init(arena.allocator(), buffer);
    try lexer.tokenize();

    inline for (expected_tokens, 0..) |expected_token, i| {
        const token = lexer.getToken(i);
        try expectEqual(expected_token.@"0", token.type);
        try expectEqualStrings(expected_token.@"1", lexer.getTokenValue(i).?);
    }
}
