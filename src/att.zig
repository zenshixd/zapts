const std = @import("std");

pub const ATTNode = struct {
    tag: Tag,
    data: Data = .{ .none = {} },

    pub const Tag = enum {
        // data.list
        generic,
        // data.object
        object,
        // data.node
        array,
        // data.list
        tuple,
        // data.function
        function,
        // data.node
        typeof,
        // data.node
        keyof,
        // data.binary
        @"union",
        intersection,

        // data.node
        identifier,

        // data.literal or .none
        bigint,
        number,
        string,

        // data.none
        boolean,
        true,
        false,
        null,
        undefined,
        unknown,
        any,
        void,
        none,
    };

    pub const Data = union(enum) {
        object: []Record,
        function: *Function,
        list: []ATTNode,
        binary: *Binary,
        node: *ATTNode,
        literal: []const u8,
        none: void,
    };

    pub const Binary = struct {
        left: ATTNode,
        right: ATTNode,
    };

    pub const Function = struct {
        params: []Record,
        return_type: ?ATTNode,
    };

    pub const Record = struct {
        name: []const u8,
        type: ATTNode,
    };
};
