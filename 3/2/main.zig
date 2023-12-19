const std = @import("std");

const Row = struct {
    index: u8,
    content: []const u8,
    parts: std.AutoHashMap(u64, []const u8),
    symbols: std.ArrayList(u8),
    total: u32,
};

pub fn main() !void {
    const fileName = "input.txt";
    const file = try std.fs.cwd().openFile(fileName, .{});
    defer file.close();

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const read_buf = try file.readToEndAlloc(allocator, 1024 * 1024);
    defer allocator.free(read_buf);

    var rows = std.ArrayList(Row).init(allocator);
    defer rows.deinit();

    var total: u64 = 0;

    var it = std.mem.tokenizeAny(u8, read_buf, "\n");
    var row_index: u8 = 0;
    while (it.next()) |row| {
        const r = Row{
            .index = row_index,
            .content = row,
            .parts = try extract_row_numbers(allocator, row),
            .symbols = try extract_stars(allocator, row),
            .total = 0,
        };
        try rows.append(r);
        row_index += 1;
    }

    for (rows.items, 0..) |row, i| {
        total += try calculate_row_total(allocator, row, rows, i);
    }

    std.debug.print("total: {d}\n", .{total});
}

fn calculate_row_total(allocator: std.mem.Allocator, row: Row, rows: std.ArrayList(Row), row_index: u64) !u64 {
    var parts = std.ArrayList(u32).init(allocator);
    defer parts.deinit();

    var total: u64 = 0;

    for (row.symbols.items) |symbol_index| {
        parts.clearAndFree();
        const adiacent_positions: [3]u64 = [_]u64{ symbol_index - 1, symbol_index, symbol_index + 1 };

        // check current row
        var kit = row.parts.iterator();
        while (kit.next()) |entry| {
            const part_index = entry.key_ptr.*;
            const part = entry.value_ptr.*;
            const part_len = part.len;
            if (check_boundaries(adiacent_positions, part_index, part_len, try parse_u32(part))) {
                try parts.append(try parse_u32(part));
            }
        }

        // check previous row
        if (row_index > 0) {
            const prev_row = rows.items[row_index - 1];
            kit = prev_row.parts.iterator();
            while (kit.next()) |entry| {
                const part_index = entry.key_ptr.*;
                const part = entry.value_ptr.*;
                const part_len = part.len;
                if (check_boundaries(adiacent_positions, part_index, part_len, try parse_u32(part))) {
                    try parts.append(try parse_u32(part));
                }
            }
        }

        // check next row
        if (row_index + 1 < rows.items.len) {
            const next_row = rows.items[row_index + 1];
            kit = next_row.parts.iterator();
            while (kit.next()) |entry| {
                const part_index = entry.key_ptr.*;
                const part = entry.value_ptr.*;
                const part_len = part.len;
                if (check_boundaries(adiacent_positions, part_index, part_len, try parse_u32(part))) {
                    try parts.append(try parse_u32(part));
                }
            }
        }

        if (parts.items.len == 2) {
            total += parts.items[0] * parts.items[1];
        }
    }

    return total;
}

fn check_boundaries(adiacent_positions: [3]u64, part_index: u64, part_len: u64, part: u32) bool {
    _ = part;
    for (adiacent_positions) |pos| {
        if (pos >= part_index and pos <= part_index + part_len - 1) {
            return true;
        }
    }

    return false;
}

fn extract_row_numbers(allocator: std.mem.Allocator, row: []const u8) !std.AutoHashMap(u64, []const u8) {
    var parts = std.AutoHashMap(u64, []const u8).init(allocator);
    errdefer parts.deinit();

    var number_start: ?usize = null;
    for (row, 0..) |c, i| {
        if (std.ascii.isDigit(c)) {
            if (number_start == null) {
                number_start = i;
            }
        } else if (number_start != null) {
            const number = row[number_start.?..i];
            try parts.put(number_start.?, number);
            number_start = null;
        }
    }

    if (number_start != null) {
        const number = row[number_start.?..];
        try parts.put(number_start.?, number);
    }
    return parts;
}

fn extract_stars(allocator: std.mem.Allocator, row: []const u8) !std.ArrayList(u8) {
    var symbols = std.ArrayList(u8).init(allocator);
    errdefer symbols.deinit();

    for (row, 0..) |c, i| {
        if (c == '*') {
            try symbols.append(@intCast(i));
        }
    }

    return symbols;
}

fn parse_u32(s: []const u8) !u32 {
    const result = try std.fmt.parseInt(u32, s, 10);
    return result;
}
