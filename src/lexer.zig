const std = @import("std");
const consts = @import("consts.zig");

const Reporter = @import("reporter.zig");
const diagnostics = @import("diagnostics.zig");
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
const LexerError = error{ SyntaxError, OutOfMemory };

pub const Context = enum { regex, template };
pub const ContextSet = std.EnumSet(Context);
pub const ContextChange = union(enum) {
    none: void,
    add: Context,
    remove: Context,
};

buffer: [:0]const u8,
reporter: *Reporter,
context: ContextSet = ContextSet.initEmpty(),

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
    question_mark,
    question_mark_question_mark,
    hash,
    shebang,
    dot,
    string_single_quote,
    string_double_quote,
    template,
    template_maybe_substitution,
    template_middle,
    template_middle_maybe_substitution,
    regex_literal_first_char,
    regex_literal_escape_sequence,
    regex_literal_char_class,
    regex_literal_body,
    regex_literal_flags,
    number,
    number_dot,
    number_exponent,
    number_exponent_sign,
    escape_sequence,
    escape_sequence_unicode,
    escape_sequence_hex,
    escape_sequence_code_point,
    identifier,
};

pub fn is_eof(self: Self, index: u32) bool {
    return self.buffer[index] == 0;
}

pub fn fail(self: *Self, index: u32, comptime error_msg: diagnostics.DiagnosticMessage, args: anytype) void {
    self.reporter.put(error_msg, args, Token.at(index));
}

pub fn tokenize(self: *Self, gpa: std.mem.Allocator) []const Token {
    var index: u32 = 0;
    var tokens = std.ArrayList(Token).init(gpa);
    errdefer tokens.deinit();

    while (true) {
        const tok = self.next(index);
        tokens.append(tok) catch unreachable;
        index = tok.end;
        if (tok.type == .Eof) {
            break;
        }
    }

    return tokens.toOwnedSlice() catch unreachable;
}

pub fn tokenizeWithContexts(self: *Self, gpa: std.mem.Allocator, contextChanges: []ContextChange) []const Token {
    var tok_index: u32 = 0;
    var index: u32 = 0;
    var tokens = std.ArrayList(Token).init(gpa);
    errdefer tokens.deinit();

    while (true) {
        if (tok_index < contextChanges.len) {
            switch (contextChanges[tok_index]) {
                .none => {},
                .add => self.setContext(contextChanges[tok_index].add),
                .remove => self.unsetContext(contextChanges[tok_index].remove),
            }
        }
        const tok = self.next(index);
        tokens.append(tok) catch unreachable;

        index = tok.end;
        tok_index += 1;

        if (tok.type == .Eof) {
            break;
        }
    }

    return tokens.toOwnedSlice() catch unreachable;
}

pub fn setContext(self: *Self, context: Context) void {
    self.context.insert(context);
}

pub fn unsetContext(self: *Self, context: Context) void {
    self.context.remove(context);
}

pub fn next(self: *Self, start_index: u32) Token {
    if (self.buffer.len == 0) {
        return .{
            .type = .Eof,
            .start = 0,
            .end = 0,
        };
    }

    var index = start_index;
    var result: Token = .{
        .type = undefined,
        .start = index,
        .end = undefined,
    };

    var state: State = State.start;

    while (true) : (index += 1) {
        switch (state) {
            .start => switch (self.buffer[index]) {
                0 => {
                    if (index >= self.buffer.len) {
                        index -= 1;
                        result.type = .Eof;
                        break;
                    }
                },
                ' ', '\t', '\r', '\n' => {
                    result.start = index + 1;
                },
                '|' => state = .bar,
                '&' => state = .ampersand,
                '^' => state = .caret,
                '=' => state = .equal,
                '+' => state = .plus,
                '-' => state = .minus,
                '*' => state = .asterisk,
                '/' => {
                    if (self.context.contains(.regex)) {
                        state = .regex_literal_body;
                    } else {
                        state = .slash;
                    }
                },
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
                    if (self.context.contains(.template)) {
                        state = .template_middle;
                    } else {
                        result.type = .CloseCurlyBrace;
                        break;
                    }
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
                '\\' => state = .escape_sequence,
                '`' => state = .template,
                else => state = .identifier,
            },
            .ampersand => switch (self.buffer[index]) {
                '&' => state = .ampersand_ampersand,
                '=' => {
                    result.type = .AmpersandEqual;
                    break;
                },
                else => {
                    index -= 1;
                    result.type = .Ampersand;
                    break;
                },
            },
            .ampersand_ampersand => switch (self.buffer[index]) {
                '=' => {
                    result.type = .AmpersandAmpersandEqual;
                    break;
                },
                else => {
                    index -= 1;
                    result.type = .AmpersandAmpersand;
                    break;
                },
            },
            .bar => switch (self.buffer[index]) {
                '|' => state = .bar_bar,
                '=' => {
                    result.type = .BarEqual;
                    break;
                },
                else => {
                    index -= 1;
                    result.type = .Bar;
                    break;
                },
            },
            .bar_bar => switch (self.buffer[index]) {
                '=' => {
                    result.type = .BarBarEqual;
                    break;
                },
                else => {
                    index -= 1;
                    result.type = .BarBar;
                    break;
                },
            },
            .caret => switch (self.buffer[index]) {
                '=' => {
                    result.type = .CaretEqual;
                    break;
                },
                else => {
                    index -= 1;
                    result.type = .Caret;
                    break;
                },
            },
            .equal => switch (self.buffer[index]) {
                '=' => state = .equal_equal,
                '>' => {
                    result.type = .Arrow;
                    break;
                },
                else => {
                    index -= 1;
                    result.type = .Equal;
                    break;
                },
            },
            .equal_equal => switch (self.buffer[index]) {
                '=' => {
                    result.type = .EqualEqualEqual;
                    break;
                },
                else => {
                    index -= 1;
                    result.type = .EqualEqual;
                    break;
                },
            },
            .exclamation_mark => switch (self.buffer[index]) {
                '=' => state = .exclamation_mark_equal,
                else => {
                    index -= 1;
                    result.type = .ExclamationMark;
                    break;
                },
            },
            .exclamation_mark_equal => switch (self.buffer[index]) {
                '=' => {
                    result.type = .ExclamationMarkEqualEqual;
                    break;
                },
                else => {
                    index -= 1;
                    result.type = .ExclamationMarkEqual;
                    break;
                },
            },
            .question_mark => switch (self.buffer[index]) {
                '?' => state = .question_mark_question_mark,
                '.' => {
                    result.type = .QuestionMarkDot;
                    break;
                },
                else => {
                    index -= 1;
                    result.type = .QuestionMark;
                    break;
                },
            },
            .question_mark_question_mark => switch (self.buffer[index]) {
                '=' => {
                    result.type = .QuestionMarkQuestionMarkEqual;
                    break;
                },
                else => {
                    index -= 1;
                    result.type = .QuestionMarkQuestionMark;
                    break;
                },
            },
            .dot => switch (self.buffer[index]) {
                '.' => {
                    index += 1;
                    switch (self.buffer[index]) {
                        '.' => {
                            result.type = .DotDotDot;
                            break;
                        },
                        else => {
                            index -= 1;
                            result.type = .Dot;
                            break;
                        },
                    }
                },
                '0'...'9', '_' => state = .number_dot,
                else => {
                    index -= 1;
                    result.type = .Dot;
                    break;
                },
            },
            .plus => switch (self.buffer[index]) {
                '=' => {
                    result.type = .PlusEqual;
                    break;
                },
                '+' => {
                    result.type = .PlusPlus;
                    break;
                },
                else => {
                    index -= 1;
                    result.type = .Plus;
                    break;
                },
            },
            .minus => switch (self.buffer[index]) {
                '=' => {
                    result.type = .MinusEqual;
                    break;
                },
                '-' => {
                    result.type = .MinusMinus;
                    break;
                },
                else => {
                    index -= 1;
                    result.type = .Minus;
                    break;
                },
            },
            .asterisk => switch (self.buffer[index]) {
                '=' => {
                    result.type = .StarEqual;
                    break;
                },
                '*' => state = .asterisk_asterisk,
                else => {
                    index -= 1;
                    result.type = .Star;
                    break;
                },
            },
            .asterisk_asterisk => switch (self.buffer[index]) {
                '=' => {
                    result.type = .StarStarEqual;
                    break;
                },
                else => {
                    index -= 1;
                    result.type = .StarStar;
                    break;
                },
            },
            .slash => switch (self.buffer[index]) {
                '=' => {
                    result.type = .SlashEqual;
                    break;
                },
                '/' => state = .line_comment,
                else => {
                    index -= 1;
                    result.type = .Slash;
                    break;
                },
            },
            .percent => switch (self.buffer[index]) {
                '=' => {
                    result.type = .PercentEqual;
                    break;
                },
                else => {
                    index -= 1;
                    result.type = .Percent;
                    break;
                },
            },
            .less_than => switch (self.buffer[index]) {
                '=' => {
                    result.type = .LessThanEqual;
                    break;
                },
                '<' => state = .less_than_less_than,
                else => {
                    index -= 1;
                    result.type = .LessThan;
                    break;
                },
            },
            .less_than_less_than => switch (self.buffer[index]) {
                '=' => {
                    result.type = .LessThanLessThanEqual;
                    break;
                },
                else => {
                    index -= 1;
                    result.type = .LessThanLessThan;
                    break;
                },
            },
            .greater_than => switch (self.buffer[index]) {
                '=' => {
                    result.type = .GreaterThanEqual;
                    break;
                },
                else => {
                    index -= 1;
                    result.type = .GreaterThan;
                    break;
                },
            },
            .line_comment => switch (self.buffer[index]) {
                '\n' => {
                    result.type = .LineComment;
                    break;
                },
                else => {
                    if (self.is_eof(index)) {
                        index -= 1;
                        result.type = .LineComment;
                        break;
                    }
                },
            },
            .multiline_comment => switch (self.buffer[index]) {
                '*' => {
                    index += 1;
                    if (self.buffer[index] == '/') {
                        result.type = .MultilineComment;
                        break;
                    } else {
                        index -= 1;
                    }
                },
                else => {
                    if (self.is_eof(index)) {
                        result.type = .MultilineComment;
                        self.fail(index, diagnostics.ARG_expected, .{"*/"});
                        break;
                    }
                },
            },
            .string_single_quote => switch (self.buffer[index]) {
                '\'' => {
                    result.type = .StringConstant;
                    break;
                },
                else => {
                    if (self.buffer[index] == '\n' or self.is_eof(index)) {
                        result.type = .StringConstant;
                        index -= 1;
                        self.fail(index, diagnostics.unterminated_string_literal, .{});
                        break;
                    }
                },
            },
            .string_double_quote => switch (self.buffer[index]) {
                '"' => {
                    result.type = .StringConstant;
                    break;
                },
                else => {
                    if (self.buffer[index] == '\n' or self.is_eof(index)) {
                        result.type = .StringConstant;
                        index -= 1;
                        self.fail(index, diagnostics.unterminated_string_literal, .{});
                        break;
                    }
                },
            },
            .template => switch (self.buffer[index]) {
                '$' => state = .template_maybe_substitution,
                '`' => {
                    result.type = .TemplateNoSubstitution;
                    break;
                },
                else => {
                    if (self.is_eof(index)) {
                        result.type = .TemplateNoSubstitution;
                        index -= 1;
                        self.fail(index, diagnostics.unterminated_template_literal, .{});
                        break;
                    }
                },
            },
            .template_maybe_substitution => switch (self.buffer[index]) {
                '{' => {
                    result.type = .TemplateHead;
                    break;
                },
                else => {
                    if (self.is_eof(index)) {
                        result.type = .TemplateNoSubstitution;
                        index -= 1;
                        self.fail(index, diagnostics.unterminated_template_literal, .{});
                        break;
                    }
                    state = .template;
                },
            },
            .template_middle => switch (self.buffer[index]) {
                '$' => state = .template_middle_maybe_substitution,
                '`' => {
                    result.type = .TemplateTail;
                    break;
                },
                else => {
                    if (self.is_eof(index)) {
                        result.type = .TemplateMiddle;
                        index -= 1;
                        self.fail(index, diagnostics.unterminated_template_literal, .{});
                        break;
                    }
                },
            },
            .template_middle_maybe_substitution => switch (self.buffer[index]) {
                '{' => {
                    result.type = .TemplateMiddle;
                    break;
                },
                else => {
                    if (self.is_eof(index)) {
                        result.type = .TemplateMiddle;
                        index -= 1;
                        self.fail(index, diagnostics.unterminated_template_literal, .{});
                        break;
                    }
                    state = .template_middle;
                },
            },
            .regex_literal_first_char => switch (self.buffer[index]) {
                '/' => state = .line_comment,
                '*' => state = .multiline_comment,
                '[' => state = .regex_literal_char_class,
                '\\' => state = .regex_literal_escape_sequence,
                else => {
                    if (self.buffer[index] == '\n' or self.is_eof(index)) {
                        result.type = .RegexLiteral;
                        index -= 1;
                        self.fail(index, diagnostics.unterminated_regular_expression_literal, .{});
                        break;
                    }

                    state = .regex_literal_body;
                },
            },
            .regex_literal_body => switch (self.buffer[index]) {
                '/' => state = .regex_literal_flags,
                '[' => state = .regex_literal_char_class,
                '\\' => state = .regex_literal_escape_sequence,
                else => {
                    if (self.buffer[index] == '\n' or self.is_eof(index)) {
                        result.type = .RegexLiteral;
                        index -= 1;
                        self.fail(index, diagnostics.unterminated_regular_expression_literal, .{});
                        break;
                    }
                },
            },
            .regex_literal_char_class => switch (self.buffer[index]) {
                '\\' => state = .regex_literal_escape_sequence,
                ']' => state = .regex_literal_body,
                else => {
                    if (self.buffer[index] == '\n' or self.is_eof(index)) {
                        result.type = .RegexLiteral;
                        index -= 1;
                        self.fail(index, diagnostics.unterminated_regular_expression_literal, .{});
                        break;
                    }
                },
            },
            .regex_literal_escape_sequence => switch (self.buffer[index]) {
                else => {
                    if (self.buffer[index] == '\n' or self.is_eof(index)) {
                        result.type = .RegexLiteral;
                        index -= 1;
                        self.fail(index, diagnostics.unterminated_regular_expression_literal, .{});
                        break;
                    }
                    state = .regex_literal_body;
                },
            },
            .regex_literal_flags => switch (self.buffer[index]) {
                'a'...'z', 'A'...'Z', '0'...'9', '$', '_' => {},
                else => {
                    result.type = .RegexLiteral;
                    index -= 1;
                    break;
                },
            },
            .number => switch (self.buffer[index]) {
                '0'...'9', '_' => {},
                '.' => state = .number_dot,
                'e', 'E' => state = .number_exponent_sign,
                'n' => {
                    result.type = .BigIntConstant;
                    break;
                },
                else => {
                    index -= 1;
                    result.type = .NumberConstant;
                    break;
                },
            },
            .number_dot => switch (self.buffer[index]) {
                '0'...'9', '_' => {},
                'e', 'E' => state = .number_exponent_sign,
                'n' => {
                    result.type = .BigIntConstant;
                    break;
                },
                else => {
                    index -= 1;
                    result.type = .NumberConstant;
                    break;
                },
            },
            .number_exponent_sign => switch (self.buffer[index]) {
                '+', '-' => state = .number_exponent,
                '0'...'9', '_' => state = .number_exponent,
                'n' => {
                    result.type = .BigIntConstant;
                    break;
                },
                else => {
                    index -= 1;
                    result.type = .NumberConstant;
                    break;
                },
            },
            .number_exponent => switch (self.buffer[index]) {
                '0'...'9', '_' => {},
                'n' => {
                    result.type = .BigIntConstant;
                    break;
                },
                else => {
                    index -= 1;
                    result.type = .NumberConstant;
                    break;
                },
            },
            .hash => switch (self.buffer[index]) {
                '0'...'9', 'a'...'z', 'A'...'Z', '_', '$' => {},
                '!' => state = .shebang,
                else => {
                    index -= 1;
                    result.type = .PrivateIdentifier;
                    break;
                },
            },
            .shebang => switch (self.buffer[index]) {
                '\n' => {
                    result.type = .Shebang;
                    break;
                },
                else => {
                    if (self.is_eof(index)) {
                        result.type = .Shebang;
                        index -= 1;
                        break;
                    }
                },
            },
            .escape_sequence => switch (self.buffer[index]) {
                'u' => state = .escape_sequence_unicode,
                else => {
                    result.type = .UnknownSequence;
                    self.fail(index, diagnostics.invalid_character, .{});
                    break;
                },
            },
            .escape_sequence_unicode => switch (self.buffer[index]) {
                '0'...'9', 'a'...'f', 'A'...'F' => state = .escape_sequence_hex,
                '{' => state = .escape_sequence_code_point,
                else => {
                    result.type = .UnknownSequence;
                    self.fail(index, diagnostics.invalid_character, .{});
                    break;
                },
            },
            .escape_sequence_hex => switch (self.buffer[index]) {
                '0'...'9', 'a'...'f', 'A'...'F' => {
                    const len = index - result.start;
                    if (len >= 4) {
                        state = .identifier;
                    }
                },
                else => {
                    result.type = .UnknownSequence;
                    self.fail(index, diagnostics.invalid_character, .{});
                    break;
                },
            },
            .escape_sequence_code_point => switch (self.buffer[index]) {
                '0'...'9', 'a'...'f', 'A'...'F' => {},
                '}' => {
                    state = .identifier;
                },
                else => {
                    result.type = .UnknownSequence;
                    self.fail(index, diagnostics.invalid_character, .{});
                    break;
                },
            },
            .identifier => switch (self.buffer[index]) {
                'a'...'z', 'A'...'Z', '_', '$', '0'...'9' => {},
                '\\' => state = .escape_sequence,
                else => {
                    if (keywords_map.get(self.buffer[result.start..index])) |token_type| {
                        result.type = token_type;
                    } else {
                        result.type = .Identifier;
                    }
                    index -= 1;
                    break;
                },
            },
        }
    }

    index += 1;
    result.end = index;

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

var test_reporter: Reporter = undefined;
fn testInstance(text: [:0]const u8) Self {
    test_reporter = Reporter.init(std.testing.allocator);

    return .{
        .reporter = &test_reporter,
        .buffer = text,
    };
}

fn expectTokens(text: [:0]const u8, expected: []const ExpectedToken) !void {
    var lexer = testInstance(text);
    defer lexer.reporter.deinit();

    const tokens = lexer.tokenize(std.testing.allocator);
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

fn expectTokensWithContexts(text: [:0]const u8, contextsList: []ContextChange, expected: []const ExpectedToken) !void {
    var lexer = testInstance(text);
    defer lexer.reporter.deinit();

    const tokens = lexer.tokenizeWithContexts(std.testing.allocator, contextsList);
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

fn expectSyntaxError(text: [:0]const u8, comptime expected_error: diagnostics.DiagnosticMessage, args: anytype) !void {
    var lexer = testInstance(text);
    defer lexer.reporter.deinit();

    const tokens = lexer.tokenize(std.testing.allocator);
    defer std.testing.allocator.free(tokens);

    var buffer: [512]u8 = undefined;
    const expected_string = try std.fmt.bufPrint(&buffer, expected_error.format(), args);
    try expectEqualStrings(expected_string, lexer.reporter.errors.items(.message)[0]);
}

fn expectSyntaxErrorWithContexts(text: [:0]const u8, contextsList: []ContextChange, comptime expected_error: diagnostics.DiagnosticMessage, args: anytype) !void {
    var lexer = testInstance(text);
    defer lexer.reporter.deinit();

    const tokens = lexer.tokenizeWithContexts(std.testing.allocator, contextsList);
    defer std.testing.allocator.free(tokens);

    var buffer: [512]u8 = undefined;
    const expected_string = try std.fmt.bufPrint(&buffer, expected_error.format(), args);
    try expectEqualStrings(expected_string, lexer.reporter.errors.items(.message)[0]);
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
    const text = "foo bar baz \\u00FFfoo \\u{FF}foo goo\\uAABBcc\\u{AA}dd";
    const expected_tokens = [_]ExpectedToken{
        .{ TokenType.Identifier, "foo" },
        .{ TokenType.Identifier, "bar" },
        .{ TokenType.Identifier, "baz" },
        .{ TokenType.Identifier, "\\u00FFfoo" },
        .{ TokenType.Identifier, "\\u{FF}foo" },
        .{ TokenType.Identifier, "goo\\uAABBcc\\u{AA}dd" },
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

test "should parse template literals without middle" {
    const buffer = "`a${b}c`";

    var contexts = [_]ContextChange{
        .{ .add = .template },
        .{ .none = {} },
        .{ .none = {} },
    };

    try expectTokensWithContexts(buffer, &contexts, &[_]ExpectedToken{
        .{ TokenType.TemplateHead, "`a${" },
        .{ TokenType.Identifier, "b" },
        .{ TokenType.TemplateTail, "}c`" },
        .{ TokenType.Eof, "" },
    });
}

test "should parse template literals with middle" {
    const buffer = "`a${b}c${d}e`";

    var contexts = [_]ContextChange{
        .{ .none = {} },
        .{ .add = .template },
        .{ .none = {} },
        .{ .none = {} },
        .{ .none = {} },
        .{ .remove = .template },
    };
    try expectTokensWithContexts(buffer, &contexts, &[_]ExpectedToken{
        .{ TokenType.TemplateHead, "`a${" },
        .{ TokenType.Identifier, "b" },
        .{ TokenType.TemplateMiddle, "}c${" },
        .{ TokenType.Identifier, "d" },
        .{ TokenType.TemplateTail, "}e`" },
        .{ TokenType.Eof, "" },
    });
}

test "should parse template literals with objects in substitution" {
    const buffer = "`a${{a: 1}}d`";

    var contexts = [_]ContextChange{
        .{ .none = {} },
        .{ .add = .template },
        .{ .remove = .template },
        .{ .none = {} },
        .{ .none = {} },
        .{ .none = {} },
        .{ .add = .template },
        .{ .none = {} },
    };

    try expectTokensWithContexts(buffer, &contexts, &[_]ExpectedToken{
        .{ TokenType.TemplateHead, "`a${" },
        .{ TokenType.OpenCurlyBrace, "{" },
        .{ TokenType.Identifier, "a" },
        .{ TokenType.Colon, ":" },
        .{ TokenType.NumberConstant, "1" },
        .{ TokenType.CloseCurlyBrace, "}" },
        .{ TokenType.TemplateTail, "}d`" },
        .{ TokenType.Eof, "" },
    });
}

test "should return syntax error if template is unclosed" {
    const buffer = "`a${b}c";

    var contexts = [_]ContextChange{
        .{ .add = .template },
        .{ .none = {} },
        .{ .none = {} },
    };
    try expectSyntaxErrorWithContexts(buffer, &contexts, diagnostics.unterminated_template_literal, .{});
}

test "should parse regex literal" {
    const buffer = "/[a-z]/";

    var contexts = [_]ContextChange{
        .{ .add = .regex },
        .{ .none = {} },
    };
    try expectTokensWithContexts(buffer, &contexts, &[_]ExpectedToken{
        .{ TokenType.RegexLiteral, "/[a-z]/" },
        .{ TokenType.Eof, "" },
    });
}

test "should parse regex literal with flags" {
    const buffer = "/[a-z]/abcd";

    var contexts = [_]ContextChange{
        .{ .add = .regex },
        .{ .none = {} },
    };
    try expectTokensWithContexts(buffer, &contexts, &[_]ExpectedToken{
        .{ TokenType.RegexLiteral, "/[a-z]/abcd" },
        .{ TokenType.Eof, "" },
    });
}

test "should return syntax error if regex literal is unclosed" {
    const buffers = .{ "/[a-z]", "/[a-z]\n" };

    var contexts = [_]ContextChange{
        .{ .add = .regex },
        .{ .none = {} },
    };

    inline for (buffers) |buffer| {
        try expectSyntaxErrorWithContexts(buffer, &contexts, diagnostics.unterminated_regular_expression_literal, .{});
    }
}

test "should return syntax error if char class bracket is missing" {
    const buffers = .{ "/[a-z/", "/[a-z/\n" };

    var contexts = [_]ContextChange{
        .{ .add = .regex },
        .{ .none = {} },
    };

    inline for (buffers) |buffer| {
        try expectSyntaxErrorWithContexts(buffer, &contexts, diagnostics.unterminated_regular_expression_literal, .{});
    }
}

test "should allow to escape forward slash" {
    const buffer = "/abc\\//";

    var contexts = [_]ContextChange{
        .{ .add = .regex },
        .{ .none = {} },
    };
    try expectTokensWithContexts(buffer, &contexts, &[_]ExpectedToken{
        .{ TokenType.RegexLiteral, "/abc\\//" },
        .{ TokenType.Eof, "" },
    });
}

test "should allow to escape brackets" {
    const buffer = "/abc\\[/";

    var contexts = [_]ContextChange{
        .{ .add = .regex },
        .{ .none = {} },
    };
    try expectTokensWithContexts(buffer, &contexts, &[_]ExpectedToken{
        .{ TokenType.RegexLiteral, "/abc\\[/" },
        .{ TokenType.Eof, "" },
    });
}
