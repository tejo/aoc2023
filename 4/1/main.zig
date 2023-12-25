const std = @import("std");

pub fn main() !void {
    const fileName = "input.txt";
    const file = try std.fs.cwd().openFile(fileName, .{});
    defer file.close();

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const read_buf = try file.readToEndAlloc(allocator, 1024 * 1024);
    defer allocator.free(read_buf);

    var total: u64 = 0;

    var it = std.mem.tokenizeAny(u8, read_buf, "\n");
    var row_index: u8 = 0;
    while (it.next()) |row| {
        std.debug.print("\n row_index: {d}\n", .{row_index});
        total += try process_row(row);
        row_index += 1;
    }
    std.debug.print("total: {d}\n", .{total});
}

fn process_row(row: []const u8) !u32 {
    var it = std.mem.tokenizeAny(u8, row, ":");
    _ = it.next();
    var it2 = std.mem.tokenizeAny(u8, it.next().?, "|");

    var player_numbers = std.ArrayList(u32).init(std.heap.page_allocator);
    defer player_numbers.deinit();

    var it3 = std.mem.tokenizeAny(u8, it2.next().?, " ");
    while (it3.next()) |number| {
        const n = try parse_u32(number);
        try player_numbers.append(n);
    }

    var winning_numbers = std.ArrayList(u32).init(std.heap.page_allocator);
    defer winning_numbers.deinit();

    it3 = std.mem.tokenizeAny(u8, it2.next().?, " ");
    while (it3.next()) |number| {
        const n = try parse_u32(number);
        try winning_numbers.append(n);
    }

    var total: u32 = 0;
    for (player_numbers.items) |player_number| {
        for (winning_numbers.items) |winning_number| {
            if (player_number == winning_number) {
                total += 1;
            }
        }
    }

    if (total == 1) {
        return 1;
    }
    if (total == 2) {
        return 2;
    }
    if (total > 2) {
        return std.math.pow(u32, 2, total - 1);
    }
    return 0;
}

fn extract_numbers(numbers: []const u8) !std.ArrayList(u32) {
    var result = std.ArrayList(u32).init(std.heap.page_allocator);
    defer result.deinit();

    var it = std.mem.tokenizeAny(u8, numbers, " ");
    while (it.next()) |number| {
        const n = try parse_u32(number);
        try result.append(n);
    }

    return result;
}

fn parse_u32(s: []const u8) !u32 {
    const result = try std.fmt.parseInt(u32, s, 10);
    return result;
}
