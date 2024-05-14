const std = @import("std");
const Token = @import("../consts.zig").Token;
const TokenType = @import("../consts.zig").TokenType;

pub fn simple(token_type: TokenType) Token {
    return Token{
        .type = token_type,
        .value = null,
    };
}

pub fn valued(token_type: TokenType, value: []const u8) Token {
    return Token{
        .type = token_type,
        .value = value,
    };
}
