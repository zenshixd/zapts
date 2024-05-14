const std = @import("std");
const String = @import("string.zig").String;
const consts = @import("consts.zig");
const SymbolsTable = @import("symbol_table.zig").SymbolTable;
const Symbol = @import("symbol_table.zig").Symbol;
const SymbolType = @import("symbol_table.zig").SymbolType;
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
index: usize = 0,

pub fn init(allocator: Allocator, buffer: []const u8) Self {
    return .{ .allocator = allocator, .buffer = buffer };
}

pub fn next(self: *Self, current_char: u8) !Token {
    switch (current_char) {
        '\n' => {
            return Token{
                .type = TokenType.NewLine,
                .value = null,
            };
        },
        '\r', ' ', '\t' => {
            return Token{
                .type = TokenType.Whitespace,
                .value = null,
            };
        },
        '<' => {
            var next_char = try self.advance();
            if (next_char == '=') {
                return Token{
                    .type = TokenType.LessThanEqual,
                    .value = null,
                };
            } else if (next_char == '<') {
                next_char = try self.advance();

                if (next_char == '=') {
                    return Token{
                        .type = TokenType.LessThanLessThanEqual,
                        .value = null,
                    };
                } else {
                    try self.rewind(-1);
                    return Token{
                        .type = TokenType.LessThanLessThan,
                        .value = null,
                    };
                }
            } else {
                try self.rewind(-1);
                return Token{
                    .type = TokenType.LessThan,
                    .value = null,
                };
            }
        },
        '>' => {
            var next_char = try self.advance();
            if (next_char == '=') {
                return Token{
                    .type = TokenType.GreaterThanEqual,
                    .value = null,
                };
            } else if (next_char == '>') {
                next_char = try self.advance();

                if (next_char == '>') {
                    next_char = try self.advance();

                    if (next_char == '=') {
                        return Token{
                            .type = TokenType.GreaterThanGreaterThanGreaterThanEqual,
                            .value = null,
                        };
                    } else {
                        try self.rewind(-1);
                        return Token{
                            .type = TokenType.GreaterThanGreaterThanGreaterThan,
                            .value = null,
                        };
                    }
                } else if (next_char == '=') {
                    return Token{
                        .type = TokenType.GreaterThanGreaterThanEqual,
                        .value = null,
                    };
                } else {
                    try self.rewind(-1);
                    return Token{
                        .type = TokenType.GreaterThanGreaterThan,
                        .value = null,
                    };
                }
            } else {
                try self.rewind(-1);
                return Token{
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
                    return Token{
                        .type = TokenType.ExclamationMarkEqualEqual,
                        .value = null,
                    };
                } else {
                    return Token{
                        .type = TokenType.ExclamationMarkEqual,
                        .value = null,
                    };
                }
            } else {
                try self.rewind(-1);
                return Token{
                    .type = TokenType.ExclamationMark,
                    .value = null,
                };
            }
        },
        '/' => {
            var next_char = try self.advance();
            if (next_char == '=') {
                return Token{
                    .type = TokenType.SlashEqual,
                    .value = null,
                };
            } else if (next_char == '/') {
                var str = try String.new(self.allocator, 100);

                while (true) {
                    next_char = try self.maybe_advance() orelse break;
                    if (next_char == '\n' or next_char == '\r') {
                        break;
                    }
                    try str.append(next_char);
                }

                return Token{
                    .type = TokenType.LineComment,
                    .value = str.value(),
                };
            } else if (next_char == '*') {
                var str = try String.new(self.allocator, 100);

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

                return Token{
                    .type = TokenType.MultilineComment,
                    .value = str.value(),
                };
            } else {
                try self.rewind(-1);
                return Token{
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
                    return Token{
                        .type = TokenType.AmpersandAmpersandEqual,
                        .value = null,
                    };
                } else {
                    try self.rewind(-1);
                    return Token{
                        .type = TokenType.AmpersandAmpersand,
                        .value = null,
                    };
                }
            } else if (next_char == '=') {
                return Token{
                    .type = TokenType.AmpersandEqual,
                    .value = null,
                };
            } else {
                try self.rewind(-1);
                return Token{
                    .type = TokenType.Ampersand,
                    .value = null,
                };
            }
        },
        '^' => {
            const next_char = try self.advance();
            if (next_char == '=') {
                return Token{
                    .type = TokenType.CaretEqual,
                    .value = null,
                };
            } else {
                try self.rewind(-1);
                return Token{
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
                    return Token{
                        .type = TokenType.BarBarEqual,
                        .value = null,
                    };
                } else {
                    try self.rewind(-1);
                    return Token{
                        .type = TokenType.BarBar,
                        .value = null,
                    };
                }
            } else if (next_char == '=') {
                return Token{
                    .type = TokenType.BarEqual,
                    .value = null,
                };
            } else {
                try self.rewind(-1);
                return Token{
                    .type = TokenType.Bar,
                    .value = null,
                };
            }
        },
        '+' => {
            const next_char = try self.advance();
            if (next_char == '=') {
                return Token{
                    .type = TokenType.PlusEqual,
                    .value = null,
                };
            } else if (next_char == '+') {
                return Token{
                    .type = TokenType.PlusPlus,
                    .value = null,
                };
            } else if ((next_char > '0' and next_char < '9') or next_char == '.') {
                return self.read_numeric_literal(&[_]u8{ current_char, next_char }, next_char == '.');
            } else {
                try self.rewind(-1);
                return Token{
                    .type = TokenType.Plus,
                    .value = null,
                };
            }
        },
        '-' => {
            const next_char = try self.advance();
            if (next_char == '=') {
                return Token{
                    .type = TokenType.MinusEqual,
                    .value = null,
                };
            } else if (next_char == '-') {
                return Token{
                    .type = TokenType.MinusMinus,
                    .value = null,
                };
            } else if ((next_char > '0' and next_char < '9') or next_char == '.') {
                return self.read_numeric_literal(&[_]u8{ current_char, next_char }, next_char == '.');
            } else {
                try self.rewind(-1);
                return Token{
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
                    return Token{
                        .type = TokenType.StarStarEqual,
                        .value = null,
                    };
                } else {
                    try self.rewind(-1);
                    return Token{
                        .type = TokenType.StarStar,
                        .value = null,
                    };
                }
            } else if (next_char == '=') {
                return Token{
                    .type = TokenType.StarEqual,
                    .value = null,
                };
            } else {
                try self.rewind(-1);
                return Token{
                    .type = TokenType.Star,
                    .value = null,
                };
            }
        },
        '%' => {
            const next_char = try self.advance();
            if (next_char == '=') {
                return Token{
                    .type = TokenType.PercentEqual,
                    .value = null,
                };
            } else {
                try self.rewind(-1);
                return Token{
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
                    return Token{
                        .type = TokenType.EqualEqualEqual,
                        .value = null,
                    };
                } else {
                    try self.rewind(-1);
                    return Token{
                        .type = TokenType.EqualEqual,
                        .value = null,
                    };
                }
            } else {
                try self.rewind(-1);
                return Token{
                    .type = TokenType.Equal,
                    .value = null,
                };
            }
        },
        '{' => {
            return Token{
                .type = TokenType.OpenCurlyBrace,
                .value = null,
            };
        },
        '}' => {
            return Token{
                .type = TokenType.CloseCurlyBrace,
                .value = null,
            };
        },
        '[' => {
            return Token{
                .type = TokenType.OpenSquareBracket,
                .value = null,
            };
        },
        ']' => {
            return Token{
                .type = TokenType.CloseSquareBracket,
                .value = null,
            };
        },
        '(' => {
            return Token{
                .type = TokenType.OpenParen,
                .value = null,
            };
        },
        ')' => {
            return Token{
                .type = TokenType.CloseParen,
                .value = null,
            };
        },
        ',' => {
            return Token{
                .type = TokenType.Comma,
                .value = null,
            };
        },
        ';' => {
            return Token{
                .type = TokenType.Semicolon,
                .value = null,
            };
        },
        ':' => {
            return Token{
                .type = TokenType.Colon,
                .value = null,
            };
        },
        '?' => {
            var next_char = try self.advance();
            if (next_char == '?') {
                next_char = try self.advance();
                if (next_char == '=') {
                    return Token{
                        .type = TokenType.QuestionMarkQuestionMarkEqual,
                        .value = null,
                    };
                } else {
                    try self.rewind(-1);
                    return Token{
                        .type = TokenType.QuestionMarkQuestionMark,
                        .value = null,
                    };
                }
            } else if (next_char == '.') {
                return Token{
                    .type = TokenType.QuestionMarkDot,
                    .value = null,
                };
            } else {
                try self.rewind(-1);
                return Token{
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
                    return Token{
                        .type = TokenType.DotDotDot,
                        .value = null,
                    };
                } else {
                    try self.rewind(-2);
                    return Token{
                        .type = TokenType.Dot,
                        .value = null,
                    };
                }
            } else if (next_char > '0' and next_char < '9') {
                return self.read_numeric_literal(&[_]u8{ current_char, next_char }, true);
            } else {
                try self.rewind(-1);
                return Token{
                    .type = TokenType.Dot,
                    .value = null,
                };
            }
        },
        '~' => {
            return Token{
                .type = TokenType.Tilde,
                .value = null,
            };
        },
        '\'', '"' => {
            var str = try String.new(self.allocator, 100);

            const starting_char = current_char;
            while (true) {
                const next_char = try self.maybe_advance() orelse break;
                if (next_char == '\n' or next_char == '\r' or next_char == starting_char) {
                    break;
                }
                try str.append(next_char);
            }

            return Token{
                .type = TokenType.StringConstant,
                .value = str.value(),
            };
        },
        '0'...'9' => {
            return self.read_numeric_literal(&[_]u8{current_char}, false);
        },
        else => {
            var str = try String.new(self.allocator, 100);

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

            if (keywords_map.get(str.value())) |keyword_type| {
                return Token{
                    .type = keyword_type,
                    .value = null,
                };
            }

            return Token{
                .type = TokenType.Identifier,
                .value = str.value(),
            };
        },
    }

    unreachable;
}

pub fn nextAll(self: *Self) !std.ArrayList(Token) {
    var current_char: u8 = self.buffer[0];
    var tokens = std.ArrayList(Token).init(self.allocator);
    while (true) {
        const token = try self.next(current_char);

        if (token.type != TokenType.Whitespace) {
            try tokens.append(token);
        }

        current_char = self.advance() catch |err| {
            if (err == error.EndOfStream) {
                try tokens.append(Token{
                    .type = TokenType.Eof,
                    .value = null,
                });
                break;
            }

            return err;
        };
    }
    return tokens;
}

fn read_numeric_literal(self: *Self, buffer: []const u8, default_has_dot: bool) !Token {
    var token_type: TokenType = TokenType.NumberConstant;
    var str = try String.new(self.allocator, 100);

    var has_dot = default_has_dot;
    var has_exponent = false;

    try str.append_many(buffer);
    while (true) {
        const next_char = try self.maybe_advance() orelse break;

        if (next_char == '.') {
            if (has_exponent or has_dot or str.at(-1) == '_') {
                return LexerError.SyntaxError;
            }
            has_dot = true;
            try str.append(next_char);
            continue;
        }

        if (next_char == 'e' or next_char == 'E') {
            if (has_exponent or str.at(-1) == '_') {
                return LexerError.SyntaxError;
            }
            has_exponent = true;
            try str.append(next_char);
            continue;
        }

        if (next_char == '_') {
            if (str.at(-1) == '_' or str.at(-1) == '.' or str.at(-1) == 'e' or str.at(-1) == 'E') {
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

    return Token{
        .type = token_type,
        .value = str.value(),
    };
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

    try expectEqual(expected_tokens.len, tokens.items.len - 1);
    for (expected_tokens, 0..tokens.items.len - 1) |expected_token, i| {
        try expectEqual(expected_token, tokens.items[i].type);
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
    try expectEqual(expected_tokens.len, tokens.items.len - 1);
    for (expected_tokens, 0..tokens.items.len - 1) |expected_token, i| {
        try expectEqual(expected_token, tokens.items[i].type);
    }
}

test "should tokenize comments" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const buffer =
        \\// single line comment
        \\/*
        \\ * multiline
        \\ * comment
        \\ *
        \\ */
    ;
    var lexer = Lexer.init(arena.allocator(), buffer);
    const tokens = try lexer.nextAll();

    try expectEqual(TokenType.LineComment, tokens.items[0].type);
    try expectEqualStrings(" single line comment", tokens.items[0].value.?);

    try expectEqual(TokenType.MultilineComment, tokens.items[1].type);
    try expectEqualStrings("\n * multiline\n * comment\n *\n ", tokens.items[1].value.?);
}

test "should tokenize strings" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const buffer = "'hello' \"hello\" \"hello''world\"";
    var lexer = Lexer.init(arena.allocator(), buffer);
    const tokens = try lexer.nextAll();

    try expectEqual(TokenType.StringConstant, tokens.items[0].type);
    try expectEqualStrings("hello", tokens.items[0].value.?);

    try expectEqual(TokenType.StringConstant, tokens.items[1].type);
    try expectEqualStrings("hello", tokens.items[1].value.?);

    try expectEqual(TokenType.StringConstant, tokens.items[2].type);
    try expectEqualStrings("hello''world", tokens.items[2].value.?);
}

test "should tokenize decimal numbers" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const buffer = "123 123.456 123e456 123.456e456 123n 123_456 123_456n .123 .123e456 +123 -123 +123.456 -123.456 +123n -123n +123_456 -123_456 +.123 -.123 +.123e456 -.123e456";
    var lexer = Lexer.init(arena.allocator(), buffer);
    const tokens = try lexer.nextAll();

    try expectEqual(TokenType.NumberConstant, tokens.items[0].type);
    try expectEqualStrings("123", tokens.items[0].value.?);

    try expectEqual(TokenType.NumberConstant, tokens.items[1].type);
    try expectEqualStrings("123.456", tokens.items[1].value.?);

    try expectEqual(TokenType.NumberConstant, tokens.items[2].type);
    try expectEqualStrings("123e456", tokens.items[2].value.?);

    try expectEqual(TokenType.NumberConstant, tokens.items[3].type);
    try expectEqualStrings("123.456e456", tokens.items[3].value.?);

    try expectEqual(TokenType.BigIntConstant, tokens.items[4].type);
    try expectEqualStrings("123n", tokens.items[4].value.?);

    try expectEqual(TokenType.NumberConstant, tokens.items[5].type);
    try expectEqualStrings("123_456", tokens.items[5].value.?);

    try expectEqual(TokenType.BigIntConstant, tokens.items[6].type);
    try expectEqualStrings("123_456n", tokens.items[6].value.?);

    try expectEqual(TokenType.NumberConstant, tokens.items[7].type);
    try expectEqualStrings(".123", tokens.items[7].value.?);

    try expectEqual(TokenType.NumberConstant, tokens.items[8].type);
    try expectEqualStrings(".123e456", tokens.items[8].value.?);

    try expectEqual(TokenType.NumberConstant, tokens.items[9].type);
    try expectEqualStrings("+123", tokens.items[9].value.?);

    try expectEqual(TokenType.NumberConstant, tokens.items[10].type);
    try expectEqualStrings("-123", tokens.items[10].value.?);

    try expectEqual(TokenType.NumberConstant, tokens.items[11].type);
    try expectEqualStrings("+123.456", tokens.items[11].value.?);

    try expectEqual(TokenType.NumberConstant, tokens.items[12].type);
    try expectEqualStrings("-123.456", tokens.items[12].value.?);

    try expectEqual(TokenType.BigIntConstant, tokens.items[13].type);
    try expectEqualStrings("+123n", tokens.items[13].value.?);

    try expectEqual(TokenType.BigIntConstant, tokens.items[14].type);
    try expectEqualStrings("-123n", tokens.items[14].value.?);

    try expectEqual(TokenType.NumberConstant, tokens.items[15].type);
    try expectEqualStrings("+123_456", tokens.items[15].value.?);

    try expectEqual(TokenType.NumberConstant, tokens.items[16].type);
    try expectEqualStrings("-123_456", tokens.items[16].value.?);

    try expectEqual(TokenType.NumberConstant, tokens.items[17].type);
    try expectEqualStrings("+.123", tokens.items[17].value.?);

    try expectEqual(TokenType.NumberConstant, tokens.items[18].type);
    try expectEqualStrings("-.123", tokens.items[18].value.?);

    try expectEqual(TokenType.NumberConstant, tokens.items[19].type);
    try expectEqualStrings("+.123e456", tokens.items[19].value.?);

    try expectEqual(TokenType.NumberConstant, tokens.items[20].type);
    try expectEqualStrings("-.123e456", tokens.items[20].value.?);
}
