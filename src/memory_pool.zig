const std = @import("std");

pub const MemoryPoolError = error{OutOfMemory};

pub const Options = struct {
    step: comptime_int = 32,
};

const Span = extern struct {
    buffer: [*]u8,
    index: usize = 0,
    prev: ?*Span = null,
};

pub fn MemoryPool(comptime pool_options: Options) type {
    return struct {
        const Pool = @This();

        allocator: std.mem.Allocator,
        pools: std.AutoHashMap(u16, *Span),
        index: usize = 0,

        /// Creates a new memory pool.
        pub fn init(allocator: std.mem.Allocator) !Pool {
            return .{
                .allocator = allocator,
                .pools = std.AutoHashMap(u16, *Span).init(allocator),
            };
        }

        /// Destroys the memory pool and frees all allocated memory.
        pub fn deinit(self: *Pool) void {
            var it = self.pools.iterator();
            while (it.next()) |entry| {
                const current_span = entry.value_ptr.*;
                var prev_span = current_span.prev orelse null;
                self.free(entry.key_ptr.*, current_span);

                while (prev_span) |span| {
                    prev_span = span.prev;
                    self.free(entry.key_ptr.*, span);
                }
            }
            self.pools.deinit();
        }

        pub fn free(self: *Pool, item_size: u16, span: *Span) void {
            std.debug.print("1 span {*} prev {*}\n", .{ span, span.prev });
            // what the fuck is this?
            std.debug.print("2\n", .{});
            var buffer: []align(@alignOf(Span)) u8 = undefined;
            buffer.ptr = @ptrCast(span);
            buffer.len = item_size * pool_options.step + @sizeOf(Span);
            std.debug.print("free {}\n", .{buffer.len});
            self.allocator.free(buffer);
        }

        /// Creates a new item and adds it to the memory pool.
        pub fn create(self: *Pool, Item: type) !*Item {
            var span: ?*Span = @ptrCast(self.pools.get(@sizeOf(Item)));
            if (span == null or span.?.index >= pool_options.step) {
                const next_span = try allocSpan(self.allocator, Item, span);
                std.debug.print("next_span {?} {*}\n", .{ next_span.prev, next_span.prev });
                try self.pools.put(@sizeOf(Item), @ptrCast(next_span));
                span = next_span;

                // test
                const x = self.pools.get(@sizeOf(Item));
                std.debug.print("create span {*} prev {*}\n", .{ x, x.?.prev });
            }
            // const ptr = &span.?.buffer[span.?.index * @sizeOf(Item)];
            const item_buf: [*]align(@alignOf(Item)) u8 = @alignCast(span.?.buffer[span.?.index * @sizeOf(Item) ..]);
            const ptr: *Item = @ptrCast(item_buf);
            span.?.index += 1;
            ptr.* = undefined;
            return ptr;
        }

        /// Creates a new item and adds it to the memory pool.
        pub fn createDefault(self: *Pool, Item: type, value: Item) !*Item {
            const ptr = try self.create(Item);
            ptr.* = value;
            return ptr;
        }

        fn allocSpan(allocator: std.mem.Allocator, Item: type, prev: ?*Span) !*Span {
            const buffer = try allocator.alignedAlloc(u8, @alignOf(Span), pool_options.step * @sizeOf(Item) + @sizeOf(Span));
            const span: *Span = @ptrCast(buffer.ptr);
            std.debug.print("\nalloc prev {*} {}\n", .{ prev, @sizeOf(Span) });
            span.prev = prev;
            span.index = 0;
            return span;
        }
    };
}

test "basic" {
    var pool = try MemoryPool(.{ .step = 2 }).init(std.testing.allocator);
    defer pool.deinit();

    const p1 = try pool.create(u32);
    const p2 = try pool.create(u32);

    const first_span = pool.pools.get(@sizeOf(u32)).?;
    try std.testing.expect(first_span.prev == null);
    const p3 = try pool.create(u32);
    const second_span = pool.pools.get(@sizeOf(u32)).?;
    try std.testing.expect(second_span.prev != null);
    try std.testing.expect(second_span != first_span);

    // Assert uniqueness
    try std.testing.expect(p1 != p2);
    try std.testing.expect(p1 != p3);
    try std.testing.expect(p2 != p3);

    _ = try pool.create(u32);
    _ = try pool.create(u32);
    const third_span = pool.pools.get(@sizeOf(u32)).?;
    try std.testing.expect(second_span != third_span);
}

test "basic2" {
    const TestStruct = struct {
        data1: usize,
        data2: usize,
        data3: usize,
        data4: usize,
        data5: usize,
        data6: usize,
        data7: usize,
        data8: usize,
        data9: usize,
        data10: usize,
        data11: usize,
        data12: usize,
        data13: usize,
    };
    var pool = try MemoryPool(.{ .step = 2 }).init(std.testing.allocator);
    defer pool.deinit();

    const p1 = try pool.create(TestStruct);
    const p2 = try pool.create(TestStruct);

    const first_span = pool.pools.get(@sizeOf(TestStruct)).?;
    try std.testing.expect(first_span.prev == null);
    const p3 = try pool.create(TestStruct);
    const second_span = pool.pools.get(@sizeOf(TestStruct)).?;
    try std.testing.expect(second_span.prev != null);
    try std.testing.expect(second_span != first_span);

    // Assert uniqueness
    try std.testing.expect(p1 != p2);
    try std.testing.expect(p1 != p3);
    try std.testing.expect(p2 != p3);

    _ = try pool.create(TestStruct);
    _ = try pool.create(TestStruct);
    const third_span = pool.pools.get(@sizeOf(TestStruct)).?;
    try std.testing.expect(second_span != third_span);
}
