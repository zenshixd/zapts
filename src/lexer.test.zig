const std = @import("std");
const String = @import("string.zig").String;
const Lexer = @import("lexer.zig");
const TokenType = @import("consts.zig").TokenType;
const SymbolsTable = @import("symbol_table.zig").SymbolTable;
const File = std.fs.File;
const FixedBufferStream = std.io.FixedBufferStream;
const Allocator = std.mem.Allocator;
const expectEqualStrings = std.testing.expectEqualStrings;
const expectEqual = std.testing.expectEqual;

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
