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

    var byteNums = std.ArrayList(u8).init(allocator);
    defer byteNums.deinit();

    var total: u32 = 0;

    var it = std.mem.split(u8, read_buf, "\n");
    while (it.next()) |row| {
        byteNums.clearRetainingCapacity();
        for (row) |char| {
            if (char >= '0' and char <= '9') {
                try byteNums.append(char);
            }
        }
        if (byteNums.items.len == 1) {
            const num = [_]u8{byteNums.items[0]} ++ [_]u8{byteNums.items[0]};
            const result: u32 = try std.fmt.parseInt(u32, &num, 10);
            total += result;
        }
        if (byteNums.items.len > 1) {
            const num = [_]u8{byteNums.items[0]} ++ [_]u8{byteNums.items[byteNums.items.len - 1]};
            const result: u32 = try std.fmt.parseInt(u32, &num, 10);
            total += result;
        }
    }
    std.debug.print("{d}\n", .{total});
}
