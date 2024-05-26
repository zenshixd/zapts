const std = @import("std");
const Symbol = @import("symbols.zig").Symbol;
const SymbolTable = @import("symbols.zig").SymbolTable;

pub const Closure = struct {
    parent: ?*Closure,
    allocator: std.mem.Allocator,
    symbols: SymbolTable,

    pub fn init(allocator: std.mem.Allocator) Closure {
        return Closure{
            .parent = null,
            .allocator = allocator,
            .symbols = SymbolTable.init(allocator),
        };
    }

    pub fn initWithParent(allocator: std.mem.Allocator, parent: *Closure) Closure {
        return Closure{
            .parent = parent,
            .allocator = allocator,
            .symbols = SymbolTable.init(allocator),
        };
    }

    pub fn deinit(self: *Closure) void {
        for (self.symbols.items) |symbol| {
            self.allocator.destroy(symbol);
        }
        self.symbols.deinit();
    }

    pub fn spawn(self: *Closure) !*Closure {
        const new_closure = try self.allocator.create(Closure);
        new_closure.* = Closure.initWithParent(self.allocator, self);
        return new_closure;
    }

    pub fn addSymbol(self: *Closure, name: []const u8, symbol: Symbol) !*Symbol {
        const new_symbol = try self.allocator.create(Symbol);
        new_symbol.* = symbol;
        try self.symbols.put(name, new_symbol);
        std.log.info("added symbol {}", .{new_symbol});
        return new_symbol;
    }

    pub fn getSymbol(self: *Closure, name: []const u8) !?*Symbol {
        const symbol = self.symbols.get(name);

        if (symbol) |s| {
            return s;
        }

        if (self.parent) |parent| {
            return try parent.getSymbol(name);
        }

        return null;
    }

    pub fn symbolExists(self: *Closure, name: []const u8) bool {
        if (self.symbols.contains(name)) {
            return true;
        }

        if (self.parent) |parent| {
            return try parent.symbolExists(name);
        }

        return false;
    }
};
