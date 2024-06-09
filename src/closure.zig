const std = @import("std");
const MemoryPool = @import("memory_pool.zig").MemoryPool;
const Symbol = @import("symbols.zig").Symbol;
const SymbolTable = @import("symbols.zig").SymbolTable;

pub const Closure = struct {
    mempool: MemoryPool(Symbol, .{ .step = 32 }),
    symbols: SymbolTable,
    index: u8 = 0,

    pub fn init(allocator: std.mem.Allocator) !Closure {
        return Closure{
            .mempool = try MemoryPool(Symbol, .{ .step = 32 }).init(allocator),
            .symbols = SymbolTable.init(allocator),
        };
    }

    pub fn deinit(self: *Closure) void {
        self.mempool.deinit();
        self.symbols.deinit();
    }

    pub fn new_closure(self: *Closure) void {
        self.index += 1;
    }

    pub fn close_closure(self: *Closure) void {
        self.index -= 1;
    }

    pub fn addSymbol(self: *Closure, name: []const u8, symbol: Symbol) !*Symbol {
        const new_symbol = try self.mempool.create();
        new_symbol.* = symbol;
        try self.symbols.put(
            .{
                .name = name,
                .closure = self.index,
            },
            new_symbol,
        );
        return new_symbol;
    }

    pub fn getSymbol(self: *Closure, name: []const u8) ?*Symbol {
        return self.symbols.get(.{
            .name = name,
            .closure = self.index,
        });
    }

    pub fn symbolExists(self: *Closure, name: []const u8) bool {
        return self.symbols.contains(.{ .name = name, .closure = self.index });
    }
};
