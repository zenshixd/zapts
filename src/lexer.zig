const std = @import("std");
const consts = @import("consts.zig");
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

const Self = @This();
const Lexer = @This();

allocator: Allocator,
buffer: [:0]const u8,
index: u32 = 0,

pub fn init(allocator: Allocator, buffer: [:0]const u8) Self {
    return .{
        .allocator = allocator,
        .buffer = buffer,
    };
}

const State = enum {
    start,
    line_comment,
    multiline_comment,
    ampersand,
    ampersand_ampersand,
    bar,
    bar_bar,
    caret,
    equal,
    equal_equal,
    plus,
    minus,
    asterisk,
    asterisk_asterisk,
    slash,
    percent,
    exclamation_mark,
    exclamation_mark_equal,
    less_than,
    less_than_less_than,
    greater_than,
    greater_than_greater_than,
    greater_than_greater_than_greater_than,
    question_mark,
    question_mark_question_mark,
    hash,
    shebang,
    dot,
    string_single_quote,
    string_double_quote,
    number,
    number_dot,
    number_exponent,
    number_exponent_sign,
    identifier,
};

pub fn tokenize(self: *Self) []const Token {
    var tokens = std.ArrayList(Token).init(self.allocator);

    while (true) {
        const tok = self.next();
        tokens.append(tok) catch unreachable;
        if (tok.type == .Eof) {
            break;
        }
    }

    return tokens.toOwnedSlice() catch unreachable;
}

pub fn next(self: *Self) Token {
    var result: Token = .{
        .type = undefined,
        .start = self.index,
        .end = undefined,
    };

    var state: State = State.start;

    while (true) : (self.index += 1) {
        switch (state) {
            .start => switch (self.buffer[self.index]) {
                0 => {
                    if (self.index >= self.buffer.len) {
                        self.index -= 1;
                        result.type = .Eof;
                        break;
                    }
                },
                ' ', '\t', '\r', '\n' => {
                    result.start = self.index + 1;
                },
                '|' => state = .bar,
                '&' => state = .ampersand,
                '^' => state = .caret,
                '=' => state = .equal,
                '+' => state = .plus,
                '-' => state = .minus,
                '*' => state = .asterisk,
                '/' => state = .slash,
                '%' => state = .percent,
                '!' => state = .exclamation_mark,
                '<' => state = .less_than,
                '>' => state = .greater_than,
                '?' => state = .question_mark,
                '#' => state = .hash,
                '.' => state = .dot,
                ':' => {
                    result.type = .Colon;
                    break;
                },
                ';' => {
                    result.type = .Semicolon;
                    break;
                },
                ',' => {
                    result.type = .Comma;
                    break;
                },
                '{' => {
                    result.type = .OpenCurlyBrace;
                    break;
                },
                '}' => {
                    result.type = .CloseCurlyBrace;
                    break;
                },
                '[' => {
                    result.type = .OpenSquareBracket;
                    break;
                },
                ']' => {
                    result.type = .CloseSquareBracket;
                    break;
                },
                '(' => {
                    result.type = .OpenParen;
                    break;
                },
                ')' => {
                    result.type = .CloseParen;
                    break;
                },
                '@' => {
                    result.type = .At;
                    break;
                },
                '~' => {
                    result.type = .Tilde;
                    break;
                },
                '0'...'9' => state = .number,
                '\'' => state = .string_single_quote,
                '"' => state = .string_double_quote,
                else => state = .identifier,
            },
            .ampersand => switch (self.buffer[self.index]) {
                '&' => state = .ampersand_ampersand,
                '=' => {
                    result.type = .AmpersandEqual;
                    break;
                },
                else => {
                    self.index -= 1;
                    result.type = .Ampersand;
                    break;
                },
            },
            .ampersand_ampersand => switch (self.buffer[self.index]) {
                '=' => {
                    result.type = .AmpersandAmpersandEqual;
                    break;
                },
                else => {
                    self.index -= 1;
                    result.type = .AmpersandAmpersand;
                    break;
                },
            },
            .bar => switch (self.buffer[self.index]) {
                '|' => state = .bar_bar,
                '=' => {
                    result.type = .BarEqual;
                    break;
                },
                else => {
                    self.index -= 1;
                    result.type = .Bar;
                    break;
                },
            },
            .bar_bar => switch (self.buffer[self.index]) {
                '=' => {
                    result.type = .BarBarEqual;
                    break;
                },
                else => {
                    self.index -= 1;
                    result.type = .BarBar;
                    break;
                },
            },
            .caret => switch (self.buffer[self.index]) {
                '=' => {
                    result.type = .CaretEqual;
                    break;
                },
                else => {
                    self.index -= 1;
                    result.type = .Caret;
                    break;
                },
            },
            .equal => switch (self.buffer[self.index]) {
                '=' => state = .equal_equal,
                '>' => {
                    result.type = .Arrow;
                    break;
                },
                else => {
                    self.index -= 1;
                    result.type = .Equal;
                    break;
                },
            },
            .equal_equal => switch (self.buffer[self.index]) {
                '=' => {
                    result.type = .EqualEqualEqual;
                    break;
                },
                else => {
                    self.index -= 1;
                    result.type = .EqualEqual;
                    break;
                },
            },
            .exclamation_mark => switch (self.buffer[self.index]) {
                '=' => state = .exclamation_mark_equal,
                else => {
                    self.index -= 1;
                    result.type = .ExclamationMark;
                    break;
                },
            },
            .exclamation_mark_equal => switch (self.buffer[self.index]) {
                '=' => {
                    result.type = .ExclamationMarkEqualEqual;
                    break;
                },
                else => {
                    self.index -= 1;
                    result.type = .ExclamationMarkEqual;
                    break;
                },
            },
            .question_mark => switch (self.buffer[self.index]) {
                '?' => state = .question_mark_question_mark,
                '.' => {
                    result.type = .QuestionMarkDot;
                    break;
                },
                else => {
                    self.index -= 1;
                    result.type = .QuestionMark;
                    break;
                },
            },
            .question_mark_question_mark => switch (self.buffer[self.index]) {
                '=' => {
                    result.type = .QuestionMarkQuestionMarkEqual;
                    break;
                },
                else => {
                    self.index -= 1;
                    result.type = .QuestionMarkQuestionMark;
                    break;
                },
            },
            .dot => switch (self.buffer[self.index]) {
                '.' => {
                    self.index += 1;
                    switch (self.buffer[self.index]) {
                        '.' => {
                            result.type = .DotDotDot;
                            break;
                        },
                        else => {
                            self.index -= 1;
                            result.type = .Dot;
                            break;
                        },
                    }
                },
                '0'...'9', '_' => state = .number_dot,
                else => {
                    self.index -= 1;
                    result.type = .Dot;
                    break;
                },
            },
            .plus => switch (self.buffer[self.index]) {
                '=' => {
                    result.type = .PlusEqual;
                    break;
                },
                '+' => {
                    result.type = .PlusPlus;
                    break;
                },
                else => {
                    self.index -= 1;
                    result.type = .Plus;
                    break;
                },
            },
            .minus => switch (self.buffer[self.index]) {
                '=' => {
                    result.type = .MinusEqual;
                    break;
                },
                '-' => {
                    result.type = .MinusMinus;
                    break;
                },
                else => {
                    self.index -= 1;
                    result.type = .Minus;
                    break;
                },
            },
            .asterisk => switch (self.buffer[self.index]) {
                '=' => {
                    result.type = .StarEqual;
                    break;
                },
                '*' => state = .asterisk_asterisk,
                else => {
                    self.index -= 1;
                    result.type = .Star;
                    break;
                },
            },
            .asterisk_asterisk => switch (self.buffer[self.index]) {
                '=' => {
                    result.type = .StarStarEqual;
                    break;
                },
                else => {
                    self.index -= 1;
                    result.type = .StarStar;
                    break;
                },
            },
            .slash => switch (self.buffer[self.index]) {
                '=' => {
                    result.type = .SlashEqual;
                    break;
                },
                '/' => state = .line_comment,
                else => {
                    self.index -= 1;
                    result.type = .Slash;
                    break;
                },
            },
            .percent => switch (self.buffer[self.index]) {
                '=' => {
                    result.type = .PercentEqual;
                    break;
                },
                else => {
                    self.index -= 1;
                    result.type = .Percent;
                    break;
                },
            },
            .less_than => switch (self.buffer[self.index]) {
                '=' => {
                    result.type = .LessThanEqual;
                    break;
                },
                '<' => state = .less_than_less_than,
                else => {
                    self.index -= 1;
                    result.type = .LessThan;
                    break;
                },
            },
            .less_than_less_than => switch (self.buffer[self.index]) {
                '=' => {
                    result.type = .LessThanLessThanEqual;
                    break;
                },
                else => {
                    self.index -= 1;
                    result.type = .LessThanLessThan;
                    break;
                },
            },
            .greater_than => switch (self.buffer[self.index]) {
                '=' => {
                    result.type = .GreaterThanEqual;
                    break;
                },
                '>' => state = .greater_than_greater_than,
                else => {
                    self.index -= 1;
                    result.type = .GreaterThan;
                    break;
                },
            },
            .greater_than_greater_than => switch (self.buffer[self.index]) {
                '=' => {
                    result.type = .GreaterThanGreaterThanEqual;
                    break;
                },
                '>' => state = .greater_than_greater_than_greater_than,
                else => {
                    self.index -= 1;
                    result.type = .GreaterThanGreaterThan;
                    break;
                },
            },
            .greater_than_greater_than_greater_than => switch (self.buffer[self.index]) {
                '=' => {
                    result.type = .GreaterThanGreaterThanGreaterThanEqual;
                    break;
                },
                else => {
                    self.index -= 1;
                    result.type = .GreaterThanGreaterThanGreaterThan;
                    break;
                },
            },
            .line_comment => switch (self.buffer[self.index]) {
                '\n' => {
                    result.type = .LineComment;
                    break;
                },
                else => {},
            },
            .multiline_comment => switch (self.buffer[self.index]) {
                '*' => {
                    self.index += 1;
                    if (self.buffer[self.index] == '/') {
                        result.type = .MultilineComment;
                        break;
                    } else {
                        self.index -= 1;
                    }
                },
                else => {},
            },
            .string_single_quote => switch (self.buffer[self.index]) {
                '\'' => {
                    result.type = .StringConstant;
                    break;
                },
                else => {},
            },
            .string_double_quote => switch (self.buffer[self.index]) {
                '"' => {
                    result.type = .StringConstant;
                    break;
                },
                else => {},
            },
            .number => switch (self.buffer[self.index]) {
                '0'...'9', '_' => {},
                '.' => state = .number_dot,
                'e', 'E' => state = .number_exponent_sign,
                'n' => {
                    result.type = .BigIntConstant;
                    break;
                },
                else => {
                    self.index -= 1;
                    result.type = .NumberConstant;
                    break;
                },
            },
            .number_dot => switch (self.buffer[self.index]) {
                '0'...'9', '_' => {},
                'e', 'E' => state = .number_exponent_sign,
                'n' => {
                    result.type = .BigIntConstant;
                    break;
                },
                else => {
                    self.index -= 1;
                    result.type = .NumberConstant;
                    break;
                },
            },
            .number_exponent_sign => switch (self.buffer[self.index]) {
                '+', '-' => state = .number_exponent,
                '0'...'9', '_' => state = .number_exponent,
                'n' => {
                    result.type = .BigIntConstant;
                    break;
                },
                else => {
                    self.index -= 1;
                    result.type = .NumberConstant;
                    break;
                },
            },
            .number_exponent => switch (self.buffer[self.index]) {
                '0'...'9', '_' => {},
                'n' => {
                    result.type = .BigIntConstant;
                    break;
                },
                else => {
                    self.index -= 1;
                    result.type = .NumberConstant;
                    break;
                },
            },
            .hash => switch (self.buffer[self.index]) {
                '0'...'9', 'a'...'z', 'A'...'Z', '_', '$' => {},
                '!' => state = .shebang,
                else => {
                    self.index -= 1;
                    result.type = .PrivateIdentifier;
                    break;
                },
            },
            .shebang => switch (self.buffer[self.index]) {
                '\n' => {
                    result.type = .Shebang;
                    break;
                },
                else => {},
            },
            .identifier => switch (self.buffer[self.index]) {
                'a'...'z', 'A'...'Z', '_', '$', '0'...'9' => {},
                else => {
                    if (keywords_map.get(self.buffer[result.start..self.index])) |token_type| {
                        result.type = token_type;
                    } else {
                        result.type = .Identifier;
                    }
                    self.index -= 1;
                    break;
                },
            },
        }
    }

    self.index += 1;
    result.end = self.index;

    return result;
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

const ExpectedToken = struct { TokenType, []const u8 };

fn expectTokens(text: [:0]const u8, expected: []const ExpectedToken) !void {
    var lexer = Lexer.init(std.testing.allocator, text);
    const tokens = lexer.tokenize();
    defer std.testing.allocator.free(tokens);

    for (expected, 0..) |expected_token, i| {
        if (i >= tokens.len) {
            std.debug.print("expected {}, but found end of token list\n", .{expected_token});
            return error.TestExpectedEqual;
        }

        if (expected_token[0] != tokens[i].type) {
            std.debug.print("expected {s}, found {s}\n", .{ @tagName(expected_token[0]), @tagName(tokens[i].type) });
            return error.TestExpectedEqual;
        }

        if (!std.mem.eql(u8, expected_token[1], tokens[i].literal(text))) {
            std.debug.print("expected {s}, found {s}\n", .{ expected_token[1], tokens[i].literal(text) });
            return error.TestExpectedEqual;
        }
    }
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
    const text =
        \\var
        \\let
        \\const
        \\async
        \\await
        \\function
        \\return
        \\for
        \\while
        \\break
        \\continue
        \\do
        \\if
        \\else
        \\class
        \\extends
        \\interface
        \\type
        \\case
        \\debugger
        \\default
        \\delete
        \\enum
        \\import
        \\export
        \\false
        \\true
        \\finally
        \\try
        \\catch
        \\in
        \\instanceof
        \\new
        \\null
        \\undefined
        \\super
        \\switch
        \\this
        \\throw
        \\void
        \\with
        \\as
        \\implements
        \\package
        \\private
        \\protected
        \\public
        \\static
        \\yield
        \\from
        \\any
        \\unknown
    ;

    const expected_tokens = [_]ExpectedToken{
        .{ TokenType.Var, "var" },
        .{ TokenType.Let, "let" },
        .{ TokenType.Const, "const" },
        .{ TokenType.Async, "async" },
        .{ TokenType.Await, "await" },
        .{ TokenType.Function, "function" },
        .{ TokenType.Return, "return" },
        .{ TokenType.For, "for" },
        .{ TokenType.While, "while" },
        .{ TokenType.Break, "break" },
        .{ TokenType.Continue, "continue" },
        .{ TokenType.Do, "do" },
        .{ TokenType.If, "if" },
        .{ TokenType.Else, "else" },
        .{ TokenType.Class, "class" },
        .{ TokenType.Extends, "extends" },
        .{ TokenType.Interface, "interface" },
        .{ TokenType.Type, "type" },
        .{ TokenType.Case, "case" },
        .{ TokenType.Debugger, "debugger" },
        .{ TokenType.Default, "default" },
        .{ TokenType.Delete, "delete" },
        .{ TokenType.Enum, "enum" },
        .{ TokenType.Import, "import" },
        .{ TokenType.Export, "export" },
        .{ TokenType.False, "false" },
        .{ TokenType.True, "true" },
        .{ TokenType.Finally, "finally" },
        .{ TokenType.Try, "try" },
        .{ TokenType.Catch, "catch" },
        .{ TokenType.In, "in" },
        .{ TokenType.Instanceof, "instanceof" },
        .{ TokenType.New, "new" },
        .{ TokenType.Null, "null" },
        .{ TokenType.Undefined, "undefined" },
        .{ TokenType.Super, "super" },
        .{ TokenType.Switch, "switch" },
        .{ TokenType.This, "this" },
        .{ TokenType.Throw, "throw" },
        .{ TokenType.Void, "void" },
        .{ TokenType.With, "with" },
        .{ TokenType.As, "as" },
        .{ TokenType.Implements, "implements" },
        .{ TokenType.Package, "package" },
        .{ TokenType.Private, "private" },
        .{ TokenType.Protected, "protected" },
        .{ TokenType.Public, "public" },
        .{ TokenType.Static, "static" },
        .{ TokenType.Yield, "yield" },
        .{ TokenType.From, "from" },
        .{ TokenType.Any, "any" },
        .{ TokenType.Unknown, "unknown" },
        .{ TokenType.Eof, "" },
    };

    try expectTokens(text, &expected_tokens);
}

test "should tokenize identifiers" {
    const text = "foo bar baz";
    const expected_tokens = [_]ExpectedToken{
        .{ TokenType.Identifier, "foo" },
        .{ TokenType.Identifier, "bar" },
        .{ TokenType.Identifier, "baz" },
        .{ TokenType.Eof, "" },
    };

    try expectTokens(text, &expected_tokens);
}

test "should parse both identifiers and operators" {
    const text = "a + b a+b c;";
    const expected_tokens = .{
        .{ TokenType.Identifier, "a" },
        .{ TokenType.Plus, "+" },
        .{ TokenType.Identifier, "b" },
        .{ TokenType.Identifier, "a" },
        .{ TokenType.Plus, "+" },
        .{ TokenType.Identifier, "b" },
        .{ TokenType.Identifier, "c" },
        .{ TokenType.Semicolon, ";" },
        .{ TokenType.Eof, "" },
    };

    try expectTokens(text, &expected_tokens);
}

test "should tokenize operators" {
    const text =
        \\&
        \\&&
        \\^
        \\|
        \\||
        \\+
        \\++
        \\-
        \\--
        \\*
        \\**
        \\/
        \\%
        \\!
        \\!=
        \\!==
        \\=
        \\==
        \\===
        \\>
        \\>=
        \\>>
        \\>>=
        \\>>>
        \\>>>=
        \\<
        \\<=
        \\<<
        \\<<=
        \\&=
        \\&&=
        \\|=
        \\||=
        \\^=
        \\+=
        \\-=
        \\*=
        \\**=
        \\/=
        \\%=
        \\{
        \\}
        \\[
        \\]
        \\(
        \\)
        \\.
        \\...
        \\,
        \\;
        \\:
        \\?
        \\?.
        \\??
        \\??=
        \\~
        \\@
    ;

    const expected_tokens = [_]ExpectedToken{
        .{ TokenType.Ampersand, "&" },
        .{ TokenType.AmpersandAmpersand, "&&" },
        .{ TokenType.Caret, "^" },
        .{ TokenType.Bar, "|" },
        .{ TokenType.BarBar, "||" },
        .{ TokenType.Plus, "+" },
        .{ TokenType.PlusPlus, "++" },
        .{ TokenType.Minus, "-" },
        .{ TokenType.MinusMinus, "--" },
        .{ TokenType.Star, "*" },
        .{ TokenType.StarStar, "**" },
        .{ TokenType.Slash, "/" },
        .{ TokenType.Percent, "%" },
        .{ TokenType.ExclamationMark, "!" },
        .{ TokenType.ExclamationMarkEqual, "!=" },
        .{ TokenType.ExclamationMarkEqualEqual, "!==" },
        .{ TokenType.Equal, "=" },
        .{ TokenType.EqualEqual, "==" },
        .{ TokenType.EqualEqualEqual, "===" },
        .{ TokenType.GreaterThan, ">" },
        .{ TokenType.GreaterThanEqual, ">=" },
        .{ TokenType.GreaterThanGreaterThan, ">>" },
        .{ TokenType.GreaterThanGreaterThanEqual, ">>=" },
        .{ TokenType.GreaterThanGreaterThanGreaterThan, ">>>" },
        .{ TokenType.GreaterThanGreaterThanGreaterThanEqual, ">>>=" },
        .{ TokenType.LessThan, "<" },
        .{ TokenType.LessThanEqual, "<=" },
        .{ TokenType.LessThanLessThan, "<<" },
        .{ TokenType.LessThanLessThanEqual, "<<=" },
        .{ TokenType.AmpersandEqual, "&=" },
        .{ TokenType.AmpersandAmpersandEqual, "&&=" },
        .{ TokenType.BarEqual, "|=" },
        .{ TokenType.BarBarEqual, "||=" },
        .{ TokenType.CaretEqual, "^=" },
        .{ TokenType.PlusEqual, "+=" },
        .{ TokenType.MinusEqual, "-=" },
        .{ TokenType.StarEqual, "*=" },
        .{ TokenType.StarStarEqual, "**=" },
        .{ TokenType.SlashEqual, "/=" },
        .{ TokenType.PercentEqual, "%=" },
        .{ TokenType.OpenCurlyBrace, "{" },
        .{ TokenType.CloseCurlyBrace, "}" },
        .{ TokenType.OpenSquareBracket, "[" },
        .{ TokenType.CloseSquareBracket, "]" },
        .{ TokenType.OpenParen, "(" },
        .{ TokenType.CloseParen, ")" },
        .{ TokenType.Dot, "." },
        .{ TokenType.DotDotDot, "..." },
        .{ TokenType.Comma, "," },
        .{ TokenType.Semicolon, ";" },
        .{ TokenType.Colon, ":" },
        .{ TokenType.QuestionMark, "?" },
        .{ TokenType.QuestionMarkDot, "?." },
        .{ TokenType.QuestionMarkQuestionMark, "??" },
        .{ TokenType.QuestionMarkQuestionMarkEqual, "??=" },
        .{ TokenType.Tilde, "~" },
        .{ TokenType.At, "@" },
        .{ TokenType.Eof, "" },
    };

    try expectTokens(text, &expected_tokens);
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
    const buffer = "'hello' \"hello\" \"hello''world\"";

    try expectTokens(buffer, &[_]ExpectedToken{
        .{ TokenType.StringConstant, "'hello'" },
        .{ TokenType.StringConstant, "\"hello\"" },
        .{ TokenType.StringConstant, "\"hello''world\"" },
        .{ TokenType.Eof, "" },
    });
}

test "should tokenize decimal numbers" {
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
        .{ TokenType.Eof, "" },
    };
    const buffer = "123 123.456 123e456 123.456e456 123n 123_456 123_456n .123 .123e456";

    try expectTokens(buffer, &expected_tokens);
}
