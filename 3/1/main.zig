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
            .symbols = try extract_row_symbols(allocator, row),
            .total = 0,
        };
        try rows.append(r);
        row_index += 1;
    }

    for (rows.items, 0..) |row, i| {
        total += try calculate_row_total(row, rows, i);
    }

    std.debug.print("total: {d}\n", .{total});
    // 4361
}

fn calculate_row_total(row: Row, rows: std.ArrayList(Row), row_index: u64) !u64 {
    var total: u64 = 0;
    var kit = row.parts.iterator();
    std.debug.print("row {d} found:", .{row_index});
    while (kit.next()) |entry| {
        const part_index = entry.key_ptr.*;
        const part = entry.value_ptr.*;
        const part_len = part.len;
        var part_found = false;
        //check current row
        for (row.symbols.items) |symbol_index| {
            if (check_boundaries(symbol_index, part_index, part_len)) {
                // if (row_index == 4) {
                //     std.debug.print("{d} {d} {d} {s} \n", .{ symbol_index, part_index, part_len, part });
                // }
                std.debug.print(" {s}", .{part});
                part_found = true;
                total += try parse_u32(part);
                break;
            }
        }
        //check previous row
        if (row_index > 0 and !part_found) {
            const prev_row = rows.items[row_index - 1];
            for (prev_row.symbols.items) |symbol_index| {
                if (check_boundaries(symbol_index, part_index, part_len)) {
                    std.debug.print(" {s}", .{part});
                    part_found = true;
                    total += try parse_u32(part);
                    break;
                }
            }
        }
        //check next row
        if (row_index + 1 < rows.items.len and !part_found) {
            const next_row = rows.items[row_index + 1];
            for (next_row.symbols.items) |symbol_index| {
                if (check_boundaries(symbol_index, part_index, part_len)) {
                    std.debug.print(" {s}", .{part});
                    part_found = true;
                    total += try parse_u32(part);
                    break;
                }
            }
        }
    }
    std.debug.print("\n", .{});
    return total;
}

fn check_boundaries(symbol_index: u64, part_index: u64, part_len: u64) bool {
    var left: u64 = 0;
    if (part_index != 0) {
        left = part_index - 1;
    }
    const right: u64 = part_index + part_len;
    if (symbol_index >= left and symbol_index <= right) {
        return true;
    } else {
        return false;
    }
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

fn extract_row_symbols(allocator: std.mem.Allocator, row: []const u8) !std.ArrayList(u8) {
    var symbols = std.ArrayList(u8).init(allocator);
    errdefer symbols.deinit();

    for (row, 0..) |c, i| {
        if (c == '.' or std.ascii.isDigit(c)) {
            continue;
        }

        try symbols.append(@intCast(i));
    }

    return symbols;
}

fn parse_u8(s: []const u8) !u8 {
    const result = try std.fmt.parseInt(u8, s, 10);
    return result;
}

fn parse_u32(s: []const u8) !u32 {
    const result = try std.fmt.parseInt(u32, s, 10);
    return result;
}
