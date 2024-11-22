const std = @import("std");

pub const newline = "\n";
pub const PUNCTUATION_CHARS = ".,:;()[]'\"{}";
pub const OPERATOR_CHARS = "<>?+-=*|&!%/\\";
pub const WHITESPACE = " \t\r\n";

pub const keywords_map = std.StaticStringMap(TokenType).initComptime(.{
    .{ "var", TokenType.Var },
    .{ "let", TokenType.Let },
    .{ "const", TokenType.Const },
    .{ "async", TokenType.Async },
    .{ "await", TokenType.Await },
    .{ "function", TokenType.Function },
    .{ "return", TokenType.Return },
    .{ "for", TokenType.For },
    .{ "while", TokenType.While },
    .{ "break", TokenType.Break },
    .{ "continue", TokenType.Continue },
    .{ "do", TokenType.Do },
    .{ "if", TokenType.If },
    .{ "else", TokenType.Else },
    .{ "get", TokenType.Get },
    .{ "set", TokenType.Set },
    .{ "class", TokenType.Class },
    .{ "abstract", TokenType.Abstract },
    .{ "extends", TokenType.Extends },
    .{ "interface", TokenType.Interface },
    .{ "type", TokenType.Type },
    .{ "declare", TokenType.Declare },
    .{ "case", TokenType.Case },
    .{ "debugger", TokenType.Debugger },
    .{ "default", TokenType.Default },
    .{ "delete", TokenType.Delete },
    .{ "enum", TokenType.Enum },
    .{ "import", TokenType.Import },
    .{ "export", TokenType.Export },
    .{ "false", TokenType.False },
    .{ "true", TokenType.True },
    .{ "finally", TokenType.Finally },
    .{ "try", TokenType.Try },
    .{ "catch", TokenType.Catch },
    .{ "in", TokenType.In },
    .{ "of", TokenType.Of },
    .{ "instanceof", TokenType.Instanceof },
    .{ "typeof", TokenType.Typeof },
    .{ "keyof", TokenType.Keyof },
    .{ "new", TokenType.New },
    .{ "null", TokenType.Null },
    .{ "undefined", TokenType.Undefined },
    .{ "super", TokenType.Super },
    .{ "switch", TokenType.Switch },
    .{ "this", TokenType.This },
    .{ "throw", TokenType.Throw },
    .{ "void", TokenType.Void },
    .{ "with", TokenType.With },
    .{ "as", TokenType.As },
    .{ "implements", TokenType.Implements },
    .{ "package", TokenType.Package },
    .{ "private", TokenType.Private },
    .{ "protected", TokenType.Protected },
    .{ "public", TokenType.Public },
    .{ "readonly", TokenType.Readonly },
    .{ "static", TokenType.Static },
    .{ "yield", TokenType.Yield },
    .{ "from", TokenType.From },
    .{ "any", TokenType.Any },
    .{ "unknown", TokenType.Unknown },
});

pub const TokenType = enum(u8) {
    Eof,
    NewLine,
    Whitespace,
    LineComment,
    MultilineComment,
    PrivateIdentifier,
    Identifier,
    Keyword,
    StringConstant,
    NumberConstant,
    BigIntConstant,
    Arrow,
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
    Tilde,
    Shebang,
    At,

    // Keywords
    Var,
    Let,
    Const,
    Async,
    Await,
    Function,
    Return,
    For,
    While,
    Break,
    Continue,
    Do,
    If,
    Else,
    Get,
    Set,
    Abstract,
    Class,
    Extends,
    Interface,
    Type,
    Declare,
    Case,
    Debugger,
    Default,
    Delete,
    Enum,
    Import,
    Export,
    False,
    True,
    Finally,
    Try,
    Catch,
    In,
    Of,
    Instanceof,
    Typeof,
    Keyof,
    New,
    Null,
    Undefined,
    Super,
    Switch,
    This,
    Throw,
    Void,
    With,
    As,
    Implements,
    Package,
    Private,
    Protected,
    Public,
    Readonly,
    Static,
    Yield,
    From,
    Any,
    Unknown,
};

pub const Token = struct {
    type: TokenType,
    start: u32,
    end: u32,

    pub const Empty = 0;
    pub const Index = u32;

    pub fn format(self: Token, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        try std.fmt.format(writer, "Token{{ .type = {s}, .start = {d}, .end = {d} }}", .{ @tagName(self.type), self.start, self.end });
    }

    pub fn literal(self: Token, buffer: []const u8) []const u8 {
        return buffer[self.start..self.end];
    }

    pub fn lexeme(self: Token) []const u8 {
        return switch (self.type) {
            .Var => "var",
            .Let => "let",
            .Const => "const",
            .Async => "async",
            .Await => "await",
            .Function => "function",
            .Return => "return",
            .For => "for",
            .While => "while",
            .Break => "break",
            .Continue => "continue",
            .Do => "do",
            .If => "if",
            .Else => "else",
            .Get => "get",
            .Set => "set",
            .Class => "class",
            .Readonly => "readonly",
            .Abstract => "abstract",
            .Extends => "extends",
            .Interface => "interface",
            .Type => "type",
            .Declare => "declare",
            .Case => "case",
            .Debugger => "debugger",
            .Default => "default",
            .Delete => "delete",
            .Enum => "enum",
            .Import => "import",
            .Export => "export",
            .False => "false",
            .True => "true",
            .Finally => "finally",
            .Try => "try",
            .Catch => "catch",
            .In => "in",
            .Of => "of",
            .Instanceof => "instanceof",
            .Typeof => "typeof",
            .Keyof => "keyof",
            .New => "new",
            .Null => "null",
            .Undefined => "undefined",
            .Super => "super",
            .Switch => "switch",
            .This => "this",
            .Throw => "throw",
            .Void => "void",
            .With => "with",
            .As => "as",
            .Implements => "implements",
            .Package => "package",
            .Private => "private",
            .Protected => "protected",
            .Public => "public",
            .Static => "static",
            .Yield => "yield",
            .From => "from",
            .Any => "any",
            .Unknown => "unknown",
            .Arrow => "=>",
            .Ampersand => "&",
            .AmpersandAmpersand => "&&",
            .Caret => "^",
            .Bar => "|",
            .BarBar => "||",
            .Plus => "+",
            .PlusPlus => "++",
            .Minus => "-",
            .MinusMinus => "--",
            .Star => "*",
            .StarStar => "**",
            .Slash => "/",
            .Percent => "%",
            .ExclamationMark => "!",
            .ExclamationMarkEqual => "!=",
            .ExclamationMarkEqualEqual => "!==",
            .Equal => "=",
            .EqualEqual => "==",
            .EqualEqualEqual => "===",
            .GreaterThan => ">",
            .GreaterThanEqual => ">=",
            .GreaterThanGreaterThan => ">>",
            .GreaterThanGreaterThanEqual => ">>=",
            .GreaterThanGreaterThanGreaterThan => ">>>",
            .GreaterThanGreaterThanGreaterThanEqual => ">>>=",
            .LessThan => "<",
            .LessThanEqual => "<=",
            .LessThanLessThan => "<<",
            .LessThanLessThanEqual => "<<=",
            .AmpersandEqual => "&=",
            .AmpersandAmpersandEqual => "&&=",
            .BarEqual => "|=",
            .BarBarEqual => "||=",
            .CaretEqual => "^=",
            .PlusEqual => "+=",
            .MinusEqual => "-=",
            .StarEqual => "*=",
            .StarStarEqual => "**=",
            .SlashEqual => "/=",
            .PercentEqual => "%=",
            .OpenCurlyBrace => "{",
            .CloseCurlyBrace => "}",
            .OpenSquareBracket => "[",
            .CloseSquareBracket => "]",
            .OpenParen => "(",
            .CloseParen => ")",
            .Comma => ",",
            .Semicolon => ";",
            .Colon => ":",
            .QuestionMark => "?",
            .QuestionMarkDot => "?.",
            .QuestionMarkQuestionMark => "??",
            .QuestionMarkQuestionMarkEqual => "??=",
            .Dot => ".",
            .DotDotDot => "...",
            .Tilde => "~",
            .Hash => "#",
            .NumberConstant => "number",
            .BigIntConstant => "bigint",
            .StringConstant => "string",
            .PrivateIdentifier => "private identifier",
            .Identifier => "identifier",
            .Shebang => "shebang",
            .Keyword => "keyword",
            .Whitespace => "whitespace",
            .LineComment => "line comment",
            .MultilineComment => "multiline comment",
            .NewLine => "new line",
            .Eof => "eof",
        };
    }
};

pub const ALLOWED_KEYWORDS_AS_IDENTIFIERS = [_]TokenType{
    .Async,
    .Get,
    .Set,
    .Abstract,
    .Interface,
    .Type,
    .Of,
    .Undefined,
    .As,
    .Implements,
    .Package,
    .Private,
    .Protected,
    .Public,
    .Static,
    .From,
    .Any,
    .Unknown,
};

pub fn isAllowedIdentifier(token_type: TokenType) bool {
    return std.mem.indexOfScalar(TokenType, &ALLOWED_KEYWORDS_AS_IDENTIFIERS, token_type) != null;
}

test "isAllowedIdentifier" {
    try std.testing.expect(!isAllowedIdentifier(.Var));
    try std.testing.expect(!isAllowedIdentifier(.Let));
    try std.testing.expect(!isAllowedIdentifier(.Const));
    try std.testing.expect(isAllowedIdentifier(.Async));
    try std.testing.expect(!isAllowedIdentifier(.Await));
    try std.testing.expect(!isAllowedIdentifier(.Function));
    try std.testing.expect(!isAllowedIdentifier(.Return));
    try std.testing.expect(!isAllowedIdentifier(.For));
    try std.testing.expect(!isAllowedIdentifier(.While));
    try std.testing.expect(!isAllowedIdentifier(.Break));
    try std.testing.expect(!isAllowedIdentifier(.Continue));
    try std.testing.expect(!isAllowedIdentifier(.Do));
    try std.testing.expect(!isAllowedIdentifier(.If));
    try std.testing.expect(!isAllowedIdentifier(.Else));
    try std.testing.expect(isAllowedIdentifier(.Get));
    try std.testing.expect(isAllowedIdentifier(.Set));
    try std.testing.expect(!isAllowedIdentifier(.Class));
    try std.testing.expect(isAllowedIdentifier(.Abstract));
    try std.testing.expect(!isAllowedIdentifier(.Extends));
    try std.testing.expect(isAllowedIdentifier(.Interface));
    try std.testing.expect(isAllowedIdentifier(.Type));
    try std.testing.expect(!isAllowedIdentifier(.Case));
    try std.testing.expect(!isAllowedIdentifier(.Debugger));
    try std.testing.expect(!isAllowedIdentifier(.Default));
    try std.testing.expect(!isAllowedIdentifier(.Delete));
    try std.testing.expect(!isAllowedIdentifier(.Enum));
    try std.testing.expect(!isAllowedIdentifier(.Import));
    try std.testing.expect(!isAllowedIdentifier(.Export));
    try std.testing.expect(!isAllowedIdentifier(.False));
    try std.testing.expect(!isAllowedIdentifier(.True));
    try std.testing.expect(!isAllowedIdentifier(.Finally));
    try std.testing.expect(!isAllowedIdentifier(.Try));
    try std.testing.expect(!isAllowedIdentifier(.Catch));
    try std.testing.expect(!isAllowedIdentifier(.In));
    try std.testing.expect(isAllowedIdentifier(.Of));
    try std.testing.expect(!isAllowedIdentifier(.Instanceof));
    try std.testing.expect(!isAllowedIdentifier(.Typeof));
    try std.testing.expect(!isAllowedIdentifier(.New));
    try std.testing.expect(!isAllowedIdentifier(.Null));
    try std.testing.expect(isAllowedIdentifier(.Undefined));
    try std.testing.expect(!isAllowedIdentifier(.Super));
    try std.testing.expect(!isAllowedIdentifier(.Switch));
    try std.testing.expect(!isAllowedIdentifier(.This));
    try std.testing.expect(!isAllowedIdentifier(.Throw));
    try std.testing.expect(!isAllowedIdentifier(.Void));
    try std.testing.expect(!isAllowedIdentifier(.With));
    try std.testing.expect(isAllowedIdentifier(.As));
    try std.testing.expect(isAllowedIdentifier(.Implements));
    try std.testing.expect(isAllowedIdentifier(.Package));
    try std.testing.expect(isAllowedIdentifier(.Private));
    try std.testing.expect(isAllowedIdentifier(.Protected));
    try std.testing.expect(isAllowedIdentifier(.Public));
    try std.testing.expect(isAllowedIdentifier(.Static));
    try std.testing.expect(!isAllowedIdentifier(.Yield));
    try std.testing.expect(isAllowedIdentifier(.From));
    try std.testing.expect(isAllowedIdentifier(.Any));
    try std.testing.expect(isAllowedIdentifier(.Unknown));
}
