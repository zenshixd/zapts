const std = @import("std");
const MemoryPool = @import("memory_pool.zig").MemoryPool;
const Symbol = @import("symbols.zig").Symbol;
const SymbolTable = @import("symbols.zig").SymbolTable;

pub const Closure = struct {
    allocator: std.mem.Allocator,
    symbols: SymbolTable,
    index: u8 = 0,

    pub fn init(allocator: std.mem.Allocator) !Closure {
        return Closure{
            .allocator = allocator,
            .symbols = SymbolTable.init(allocator),
        };
    }

    pub fn deinit(self: *Closure) void {
        self.symbols.deinit();
    }

    pub fn new_closure(self: *Closure) void {
        self.index += 1;
    }

    pub fn close_closure(self: *Closure) void {
        self.index -= 1;
    }

    pub fn addSymbol(self: *Closure, name: []const u8, symbol: Symbol) !*Symbol {
        const new_symbol = try self.allocator.create(Symbol);
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
