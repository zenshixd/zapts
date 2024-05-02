const std = @import("std");
const String = @import("string.zig").String;
const File = std.fs.File;
const FixedBufferStream = std.io.FixedBufferStream;
const Allocator = std.mem.Allocator;

pub const PUNCTUATION_CHARS = ".,:;()[]'\"{}";
pub const OPERATOR_CHARS = "<>?+-=*|&!%/\\";
pub const WHITESPACE = " \t\n\r";
// zig fmt: off
pub const KEYWORDS = [_][]const u8{
    "var",
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
    "catch",
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
    "from"
};

pub const TokenType = enum(u8) {
    Eof,
    Whitespace,
    LineComment,
    MultilineComment,
    Identifier,
    Keyword,
    StringConstant,
    NumberConstant,
    BigIntConstant,
    Ampersand,
    AmpersandAmpersand,
    Caret,
    Bar,
    BarBar,
    Plus,
    PlusPlus,
    Minus,
    MinusMinus,
    Star,
    StarStar,
    Slash,
    Percent,
    ExclamationMark,
    ExclamationMarkEqual,
    ExclamationMarkEqualEqual,
    Equal,
    EqualEqual,
    EqualEqualEqual,
    GreaterThan,
    GreaterThanEqual,
    GreaterThanGreaterThan,
    GreaterThanGreaterThanEqual,
    GreaterThanGreaterThanGreaterThan,
    GreaterThanGreaterThanGreaterThanEqual,
    LessThan,
    LessThanEqual,
    LessThanLessThan,
    LessThanLessThanEqual,
    AmpersandEqual,
    AmpersandAmpersandEqual,
    BarEqual,
    BarBarEqual,
    CaretEqual,
    PlusEqual,
    MinusEqual,
    StarEqual,
    StarStarEqual,
    SlashEqual,
    PercentEqual,
    OpenCurlyBrace,
    CloseCurlyBrace,
    OpenSquareBracket,
    CloseSquareBracket,
    OpenParen,
    CloseParen,
    Dot,
    DotDotDot,
    Comma,
    Semicolon,
    Colon,
    QuestionMark,
    QuestionMarkDot,
    QuestionMarkQuestionMark,
    QuestionMarkQuestionMarkEqual,
    At,
    Tilde,
};
// zig fmt: on

pub const Token = struct {
    type: TokenType,
    value: ?String,

    pub fn deinit(self: *Token) void {
        if (self.value) |value| {
            value.deinit();
        }
    }
};

const StreamType = enum {
    fixed_buffer,
    file,
};

const Stream = union(StreamType) {
    fixed_buffer: *FixedBufferStream([]const u8),
    file: *File,
};

const Self = @This();

stream: Stream,
allocator: Allocator,

pub fn init(allocator: Allocator, stream: Stream) Self {
    return .{ .allocator = allocator, .stream = stream };
}

pub fn next(self: Self) !Token {
    var token: Token = undefined;
    var current_char: u8 = try self.advance();

    switch (current_char) {
        '\n', '\r', ' ', '\t' => {
            token = Token{
                .type = TokenType.Whitespace,
                .value = null,
            };
        },
        '<' => {
            var next_char = try self.advance();
            if (next_char == '=') {
                token = Token{
                    .type = TokenType.LessThanEqual,
                    .value = null,
                };
            } else if (next_char == '<') {
                next_char = try self.advance();

                if (next_char == '=') {
                    token = Token{
                        .type = TokenType.LessThanLessThanEqual,
                        .value = null,
                    };
                } else {
                    try self.rewind(-1);
                    token = Token{
                        .type = TokenType.LessThanLessThan,
                        .value = null,
                    };
                }
            } else {
                try self.rewind(-1);
                token = Token{
                    .type = TokenType.LessThan,
                    .value = null,
                };
            }
        },
        '>' => {
            var next_char = try self.advance();
            if (next_char == '=') {
                token = Token{
                    .type = TokenType.GreaterThanEqual,
                    .value = null,
                };
            } else if (next_char == '>') {
                next_char = try self.advance();

                if (next_char == '=') {
                    token = Token{
                        .type = TokenType.GreaterThanGreaterThanEqual,
                        .value = null,
                    };
                } else {
                    next_char = try self.advance();

                    if (next_char == '=') {
                        token = Token{
                            .type = TokenType.GreaterThanGreaterThanGreaterThanEqual,
                            .value = null,
                        };
                    } else {
                        try self.rewind(-1);
                        token = Token{
                            .type = TokenType.GreaterThanGreaterThanGreaterThan,
                            .value = null,
                        };
                    }
                }
            } else {
                try self.rewind(-1);
                token = Token{
                    .type = TokenType.GreaterThan,
                    .value = null,
                };
            }
        },
        '!' => {
            var next_char = try self.advance();
            if (next_char == '=') {
                next_char = try self.advance();

                if (next_char == '=') {
                    token = Token{
                        .type = TokenType.ExclamationMarkEqualEqual,
                        .value = null,
                    };
                } else {
                    token = Token{
                        .type = TokenType.ExclamationMarkEqual,
                        .value = null,
                    };
                }
            } else {
                try self.rewind(-1);
                token = Token{
                    .type = TokenType.ExclamationMark,
                    .value = null,
                };
            }
        },
        '/' => {
            var next_char = try self.advance();
            if (next_char == '=') {
                token = Token{
                    .type = TokenType.SlashEqual,
                    .value = null,
                };
            } else if (next_char == '/') {
                var str = try String.new(self.allocator, 100);
                while (true) {
                    next_char = try self.advance();
                    if (next_char == '\n' or next_char == '\r') {
                        break;
                    }
                    try str.append(next_char);
                }
                token = Token{
                    .type = TokenType.LineComment,
                    .value = str,
                };
            } else if (next_char == '*') {
                var str = try String.new(self.allocator, 100);
                while (true) {
                    next_char = self.advance() catch |err| {
                        if (err == error.EndOfStream) {
                            break;
                        }
                        return err;
                    };

                    if (next_char == '*') {
                        const one_more_char = self.advance() catch |err| {
                            if (err == error.EndOfStream) {
                                break;
                            }
                            return err;
                        };

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
                token = Token{
                    .type = TokenType.MultilineComment,
                    .value = str,
                };
            } else {
                try self.rewind(-1);
                token = Token{
                    .type = TokenType.Slash,
                    .value = null,
                };
            }
        },
        '&' => {
            var next_char = try self.advance();
            if (next_char == '&') {
                next_char = try self.advance();
                if (next_char == '=') {
                    token = Token{
                        .type = TokenType.AmpersandAmpersandEqual,
                        .value = null,
                    };
                } else {
                    try self.rewind(-1);
                    token = Token{
                        .type = TokenType.AmpersandAmpersand,
                        .value = null,
                    };
                }
            } else if (next_char == '=') {
                token = Token{
                    .type = TokenType.AmpersandEqual,
                    .value = null,
                };
            } else {
                try self.rewind(-1);
                token = Token{
                    .type = TokenType.Ampersand,
                    .value = null,
                };
            }
        },
        '^' => {
            const next_char = try self.advance();
            if (next_char == '=') {
                token = Token{
                    .type = TokenType.CaretEqual,
                    .value = null,
                };
            } else {
                try self.rewind(-1);
                token = Token{
                    .type = TokenType.Caret,
                    .value = null,
                };
            }
        },
        '|' => {
            var next_char = try self.advance();
            if (next_char == '|') {
                next_char = try self.advance();
                if (next_char == '=') {
                    token = Token{
                        .type = TokenType.BarBarEqual,
                        .value = null,
                    };
                } else {
                    try self.rewind(-1);
                    token = Token{
                        .type = TokenType.BarBar,
                        .value = null,
                    };
                }
            } else if (next_char == '=') {
                token = Token{
                    .type = TokenType.BarEqual,
                    .value = null,
                };
            } else {
                try self.rewind(-1);
                token = Token{
                    .type = TokenType.Bar,
                    .value = null,
                };
            }
        },
        '+' => {
            const next_char = try self.advance();
            if (next_char == '=') {
                token = Token{
                    .type = TokenType.PlusEqual,
                    .value = null,
                };
            } else {
                try self.rewind(-1);
                token = Token{
                    .type = TokenType.Plus,
                    .value = null,
                };
            }
        },
        '-' => {
            const next_char = try self.advance();
            if (next_char == '=') {
                token = Token{
                    .type = TokenType.MinusEqual,
                    .value = null,
                };
            } else if (next_char == '-') {
                token = Token{
                    .type = TokenType.MinusMinus,
                    .value = null,
                };
            } else {
                try self.rewind(-1);
                token = Token{
                    .type = TokenType.Minus,
                    .value = null,
                };
            }
        },
        '*' => {
            var next_char = try self.advance();
            if (next_char == '*') {
                next_char = try self.advance();
                if (next_char == '=') {
                    token = Token{
                        .type = TokenType.StarStarEqual,
                        .value = null,
                    };
                } else {
                    try self.rewind(-1);
                    token = Token{
                        .type = TokenType.StarStar,
                        .value = null,
                    };
                }
            } else if (next_char == '=') {
                token = Token{
                    .type = TokenType.StarEqual,
                    .value = null,
                };
            } else {
                try self.rewind(-1);
                token = Token{
                    .type = TokenType.Star,
                    .value = null,
                };
            }
        },
        '%' => {
            const next_char = try self.advance();
            if (next_char == '=') {
                token = Token{
                    .type = TokenType.PercentEqual,
                    .value = null,
                };
            } else {
                try self.rewind(-1);
                token = Token{
                    .type = TokenType.Percent,
                    .value = null,
                };
            }
        },
        '=' => {
            var next_char = try self.advance();
            if (next_char == '=') {
                next_char = try self.advance();
                if (next_char == '=') {
                    token = Token{
                        .type = TokenType.EqualEqualEqual,
                        .value = null,
                    };
                } else {
                    try self.rewind(-1);
                    token = Token{
                        .type = TokenType.EqualEqual,
                        .value = null,
                    };
                }
            } else {
                try self.rewind(-1);
                token = Token{
                    .type = TokenType.Equal,
                    .value = null,
                };
            }
        },
        '{' => {
            token = Token{
                .type = TokenType.OpenCurlyBrace,
                .value = null,
            };
        },
        '}' => {
            token = Token{
                .type = TokenType.CloseCurlyBrace,
                .value = null,
            };
        },
        '[' => {
            token = Token{
                .type = TokenType.OpenSquareBracket,
                .value = null,
            };
        },
        ']' => {
            token = Token{
                .type = TokenType.CloseSquareBracket,
                .value = null,
            };
        },
        '(' => {
            token = Token{
                .type = TokenType.OpenParen,
                .value = null,
            };
        },
        ')' => {
            token = Token{
                .type = TokenType.CloseParen,
                .value = null,
            };
        },
        ',' => {
            token = Token{
                .type = TokenType.Comma,
                .value = null,
            };
        },
        ';' => {
            token = Token{
                .type = TokenType.Semicolon,
                .value = null,
            };
        },
        ':' => {
            token = Token{
                .type = TokenType.Colon,
                .value = null,
            };
        },
        '?' => {
            var next_char = try self.advance();
            if (next_char == '?') {
                next_char = try self.advance();
                if (next_char == '=') {
                    token = Token{
                        .type = TokenType.QuestionMarkQuestionMarkEqual,
                        .value = null,
                    };
                } else {
                    try self.rewind(-1);
                    token = Token{
                        .type = TokenType.QuestionMarkQuestionMark,
                        .value = null,
                    };
                }
            } else if (next_char == '.') {
                token = Token{
                    .type = TokenType.QuestionMarkDot,
                    .value = null,
                };
            } else {
                try self.rewind(-1);
                token = Token{
                    .type = TokenType.QuestionMark,
                    .value = null,
                };
            }
        },
        '.' => {
            var next_char = try self.advance();
            if (next_char == '.') {
                next_char = try self.advance();
                if (next_char == '.') {
                    token = Token{
                        .type = TokenType.DotDotDot,
                        .value = null,
                    };
                } else {
                    try self.rewind(-2);
                    token = Token{
                        .type = TokenType.Dot,
                        .value = null,
                    };
                }
            } else {
                try self.rewind(-1);
                token = Token{
                    .type = TokenType.Dot,
                    .value = null,
                };
            }
        },
        '~' => {
            token = Token{
                .type = TokenType.Tilde,
                .value = null,
            };
        },
        '\'', '"' => {
            var str = try String.new(self.allocator, 100);
            const starting_char = current_char;
            while (true) {
                const next_char = try self.advance();
                if (next_char == '\n' or next_char == '\r' or next_char == starting_char) {
                    break;
                }
                try str.append(next_char);
            }

            token = Token{
                .type = TokenType.StringConstant,
                .value = str,
            };
        },
        '0'...'9' => {
            var str = try String.new(self.allocator, 100);

            try str.append(current_char);
            while (true) {
                const next_char = try self.advance();

                if ((next_char == '_' or next_char == '.') and (str.at(-1) == '_' or str.at(-1) == '.')) {
                    try self.rewind(-1);
                    break;
                }

                if ((next_char < '0' or next_char > '9')) {
                    if (next_char == 'n') {
                        try str.append(next_char);
                        token = Token{
                            .type = TokenType.BigIntConstant,
                            .value = str,
                        };
                    } else {
                        try self.rewind(-1);
                        token = Token{
                            .type = TokenType.NumberConstant,
                            .value = str,
                        };
                    }
                    break;
                }
                try str.append(next_char);
            }
        },
        else => {
            var str = try String.new(self.allocator, 100);

            try str.append(current_char);

            while (true) {
                current_char = try self.advance();
                if (is_whitespace(current_char) or is_punctuation(current_char) or is_operator(current_char)) {
                    try self.rewind(-1);
                    break;
                }
                try str.append(current_char);
            }

            token = Token{
                .type = TokenType.Identifier,
                .value = str,
            };
        },
    }

    return token;
}

fn advance(self: Self) !u8 {
    var buffer: [1]u8 = undefined;
    var bytes_read: usize = undefined;
    switch (self.stream) {
        .fixed_buffer => {
            bytes_read = try self.stream.fixed_buffer.read(&buffer);
        },
        .file => {
            bytes_read = try self.stream.file.read(&buffer);
        },
    }

    if (bytes_read < 1) {
        return error.EndOfStream;
    }

    return buffer[0];
}

fn rewind(self: Self, offset: i64) !void {
    switch (self.stream) {
        .fixed_buffer => {
            try self.stream.fixed_buffer.seekBy(offset);
        },
        .file => {
            try self.stream.file.seekBy(offset);
        },
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

test "should tokenize comments" {
    var buffer = FixedBufferStream([]const u8){
        .buffer =
        \\// single line comment
        \\/*
        \\ * multiline
        \\ * comment
        \\ *
        \\ */
        ,
        .pos = 0,
    };
    const lexer = Self.init(std.testing.allocator, .{ .fixed_buffer = &buffer });

    var token1 = try lexer.next();
    defer token1.deinit();

    try std.testing.expectEqual(TokenType.LineComment, token1.type);
    try std.testing.expectEqualStrings(" single line comment", token1.value.?.value());

    var token2 = try lexer.next();
    defer token2.deinit();

    try std.testing.expectEqual(TokenType.MultilineComment, token2.type);
    try std.testing.expectEqualStrings("\n * multiline\n * comment\n *\n ", token2.value.?.value());
}

test "should tokenize strings" {
    var buffer = FixedBufferStream([]const u8){
        .buffer = "'hello' \"hello\" \"hello''world\"",
        .pos = 0,
    };
    const lexer = Self.init(std.testing.allocator, .{ .fixed_buffer = &buffer });

    var token1 = try lexer.next();
    defer token1.deinit();

    try std.testing.expectEqual(TokenType.StringConstant, token1.type);
    try std.testing.expectEqualStrings("hello", token1.value.?.value());

    _ = try lexer.next();
    var token2 = try lexer.next();
    defer token2.deinit();

    try std.testing.expectEqual(TokenType.StringConstant, token2.type);
    try std.testing.expectEqualStrings("hello", token2.value.?.value());

    _ = try lexer.next();
    var token3 = try lexer.next();
    defer token3.deinit();

    try std.testing.expectEqual(TokenType.StringConstant, token3.type);
    try std.testing.expectEqualStrings("hello''world", token3.value.?.value());
}

test "should tokenize numbers" {
    var buffer = FixedBufferStream([]const u8){
        .buffer = "123 123.456 123e456 123.456e456 123n 123_456 123_456n",
        .pos = 0,
    };
    const lexer = Self.init(std.testing.allocator, .{ .fixed_buffer = &buffer });

    var token1 = try lexer.next();
    defer token1.deinit();

    try std.testing.expectEqual(TokenType.NumberConstant, token1.type);
    try std.testing.expectEqualStrings("123", token1.value.?.value());

    _ = try lexer.next();
    var token2 = try lexer.next();
    defer token2.deinit();

    try std.testing.expectEqual(TokenType.NumberConstant, token2.type);
    try std.testing.expectEqualStrings("123.456", token2.value.?.value());

    _ = try lexer.next();
    var token3 = try lexer.next();
    defer token3.deinit();

    try std.testing.expectEqual(TokenType.NumberConstant, token3.type);
    try std.testing.expectEqualStrings("123e456", token3.value.?.value());

    _ = try lexer.next();
    var token4 = try lexer.next();
    defer token4.deinit();

    try std.testing.expectEqual(TokenType.NumberConstant, token4.type);
    try std.testing.expectEqualStrings("123.456e456", token4.value.?.value());

    _ = try lexer.next();
    var token5 = try lexer.next();
    defer token5.deinit();

    try std.testing.expectEqual(TokenType.NumberConstant, token5.type);
    try std.testing.expectEqualStrings("123n", token5.value.?.value());

    _ = try lexer.next();
    var token6 = try lexer.next();
    defer token6.deinit();

    try std.testing.expectEqual(TokenType.NumberConstant, token6.type);
    try std.testing.expectEqualStrings("123_456", token6.value.?.value());

    _ = try lexer.next();
    var token7 = try lexer.next();
    defer token7.deinit();

    try std.testing.expectEqual(TokenType.NumberConstant, token7.type);
    try std.testing.expectEqualStrings("123_456n", token7.value.?.value());
}
