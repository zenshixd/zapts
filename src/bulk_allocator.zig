const std = @import("std");

pub const BulkAllocatorOptions = struct {
    backing_allocator: std.mem.Allocator,
    span_size: usize = 1024 * 1024 * 4, // 4kB
};

pub fn BulkAllocator(comptime options: BulkAllocatorOptions) type {
    const backing_allocator = options.backing_allocator;

    return struct {
        pub const Span = struct {
            ptr: [options.span_size]u8,
        };

        pub const SpanList = std.SinglyLinkedList(Span);
        pub const SpanListNode = SpanList.Node;

        pub const Arena = struct {
            spans: SpanList = .{},
            offset: usize = 0,

            fn alloc(ctx: *anyopaque, len: usize, log2_align: u29, len_align: u29, ret_addr: usize) error{OutOfMemory}![]u8 {
                _ = log2_align;
                _ = len_align;
                _ = ret_addr;

                const self: *Arena = @ptrCast(ctx);
                const span_node = self.spans.first orelse brk: {
                    const span_node = try backing_allocator.create(SpanListNode);
                    self.spans.append(span_node);
                    break :brk span_node;
                };

                const ptr = span_node.data.ptr[self.offset..][0..len];
                self.offset += len;
                return ptr;
            }

            fn resize(ctx: *anyopaque, buf_unaligned: []u8, buf_align: u29, new_size: usize, ret_addr: usize) bool {
                _ = ctx;
                _ = buf_unaligned;
                _ = buf_align;
                _ = new_size;
                _ = ret_addr;
                return false;
            }

            fn free(ctx: *anyopaque, buf: []u8, buf_align: u29, ret_addr: usize) void {
                _ = ctx;
                _ = buf;
                _ = buf_align;
                _ = ret_addr;
            }

            pub fn allocator(self: *const Arena) std.mem.Allocator {
                return .{
                    .ptr = self,
                    .vtable = &.{
                        .alloc = alloc,
                        .resize = resize,
                        .free = free,
                    },
                };
            }
        };

        const Self = @This();

        spans: SpanList = .{},

        pub fn arena(_: *Self) Arena {
            return Arena{};
        }

        pub fn freeArena(self: *Self, ar: Arena) void {
            for (ar.spans) |span| {
                self.spans.prepend(span);
            }
        }
    };
}
