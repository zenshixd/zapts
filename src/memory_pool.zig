const std = @import("std");

pub const MemoryPoolError = error{OutOfMemory};

pub const Options = struct {
    step: comptime_int = 32,
};

pub fn MemoryPool(comptime Item: type, comptime pool_options: Options) type {
    return struct {
        const Pool = @This();

        const Span = struct {
            items: []Item,
            next: ?*Span = null,
        };

        pub const span_size: comptime_int = @sizeOf(Span);
        pub const item_size: comptime_int = @sizeOf(Item);
        pub const total_span_size: comptime_int = span_size + item_size * pool_options.step;

        allocator: std.mem.Allocator,
        span: *Span,
        index: usize = 0,

        /// Creates a new memory pool.
        pub fn init(allocator: std.mem.Allocator) !Pool {
            return .{
                .allocator = allocator,
                .span = try allocSpan(allocator, null),
            };
        }

        /// Destroys the memory pool and frees all allocated memory.
        pub fn deinit(self: *Pool) void {
            var current_span: ?*Span = self.span;
            while (current_span) |span| {
                const next_span = span.next;

                const ptr: [*]u8 = @ptrCast(span);
                self.allocator.free(ptr[0..total_span_size]);

                current_span = next_span;
            }
        }

        /// Creates a new item and adds it to the memory pool.
        pub fn create(self: *Pool) !*Item {
            if (self.index >= self.span.items.len) {
                const next_span = try allocSpan(self.allocator, self.span);
                self.span = next_span;
                self.index = 0;
            }
            const ptr = &self.span.items[self.index];
            self.index += 1;
            ptr.* = undefined;
            return ptr;
        }

        fn allocSpan(allocator: std.mem.Allocator, next: ?*Span) MemoryPoolError!*Span {
            const mem = try allocator.alignedAlloc(u8, @alignOf(Span), total_span_size);
            const span: *Span = @alignCast(@ptrCast(mem[0..span_size]));
            span.items.ptr = @alignCast(@ptrCast(mem[span_size..][0 .. item_size * pool_options.step].ptr));
            span.items.len = pool_options.step;
            span.next = next;
            return span;
        }
    };
}

test "basic" {
    var pool = try MemoryPool(u32, .{ .step = 2 }).init(std.testing.allocator);
    defer pool.deinit();

    const first_span = pool.span;
    const p1 = try pool.create();
    const p2 = try pool.create();

    try std.testing.expect(pool.span.next == null);
    const p3 = try pool.create();
    try std.testing.expect(pool.span.next != null);
    try std.testing.expect(pool.span != first_span);
    const second_span = pool.span;

    // Assert uniqueness
    try std.testing.expect(p1 != p2);
    try std.testing.expect(p1 != p3);
    try std.testing.expect(p2 != p3);

    _ = try pool.create();
    _ = try pool.create();
    try std.testing.expect(second_span != pool.span);
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
    var pool = try MemoryPool(TestStruct, .{ .step = 2 }).init(std.testing.allocator);
    defer pool.deinit();

    const first_span = pool.span;
    const p1 = try pool.create();
    const p2 = try pool.create();

    try std.testing.expect(pool.span.next == null);
    const p3 = try pool.create();
    try std.testing.expect(pool.span.next != null);
    try std.testing.expect(pool.span != first_span);
    const second_span = pool.span;

    // Assert uniqueness
    try std.testing.expect(p1 != p2);
    try std.testing.expect(p1 != p3);
    try std.testing.expect(p2 != p3);

    _ = try pool.create();
    _ = try pool.create();
    try std.testing.expect(second_span != pool.span);
}

const Test = struct {
    data: u32,
};

pub fn main() !void {
    var mempool = try MemoryPool(Test, .{ .step = 2 }).init(std.heap.page_allocator);
    defer mempool.deinit();

    const item1 = try mempool.create();
    item1.data = 1;
    const item2 = try mempool.create();
    item2.data = 2;
    const item3 = try mempool.create();
    item3.data = 3;

    std.log.info("\n{any} {any} {any}", .{ item1, item2, item3 });
}
