pub fn ReturnTypeOf(comptime fn_ptr: anytype) type {
    const error_union = @typeInfo(@TypeOf(fn_ptr)).@"fn".return_type.?;
    return @typeInfo(error_union).error_union.payload;
}

pub fn ErrorUnionOf(comptime fn_ptr: anytype) type {
    return @typeInfo(@TypeOf(fn_ptr)).@"fn".return_type.?;
}
