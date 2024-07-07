const std = @import("std");

pub const ATTList = std.DoublyLinkedList(ATTData);
pub const ATTNode = ATTList.Node;

pub const ATTData = union(enum) {
    generic: ATTList,
    generic_params: ATTList,
    object: ATTList,
    object_property: ATTBinary,
    object_method: ATTList,
    signature_access: ATTBinary,
    signature_access_key: ATTBinary,
    array: *ATTNode,
    tuple: ATTList,
    function: ATTList,
    function_args: ATTList,
    function_arg: ATTBinary,
    typeof: *ATTNode,
    keyof: *ATTNode,
    @"union": ATTBinary,
    intersection: ATTBinary,

    identifier: []const u8,
    literal: []const u8,

    bigint: void,
    number: void,
    string: void,
    boolean: void,
    true: void,
    false: void,
    null: void,
    undefined: void,
    unknown: void,
    any: void,
    void: void,
    none: void,
};

pub const ATTBinary = struct {
    left: *ATTNode,
    right: *ATTNode,
};
