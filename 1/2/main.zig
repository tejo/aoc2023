const std = @import("std");

const Sub = struct {
    search: []const u8,
    replace: []const u8,
};

const subs: [16]Sub = .{
    Sub{ .search = "eightwo", .replace = "82" },
    Sub{ .search = "oneight", .replace = "18" },
    Sub{ .search = "twone", .replace = "21" },
    Sub{ .search = "nineight", .replace = "98" },
    Sub{ .search = "fiveight", .replace = "58" },
    Sub{ .search = "sevenine", .replace = "79" },
    Sub{ .search = "threeight", .replace = "38" },
    Sub{ .search = "one", .replace = "1" },
    Sub{ .search = "two", .replace = "2" },
    Sub{ .search = "three", .replace = "3" },
    Sub{ .search = "four", .replace = "4" },
    Sub{ .search = "five", .replace = "5" },
    Sub{ .search = "six", .replace = "6" },
    Sub{ .search = "seven", .replace = "7" },
    Sub{ .search = "eight", .replace = "8" },
    Sub{ .search = "nine", .replace = "9" },
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

    var byteNums = std.ArrayList(u8).init(allocator);
    defer byteNums.deinit();

    var total: u32 = 0;

    var it = std.mem.split(u8, read_buf, "\n");
    while (it.next()) |row| {
        byteNums.clearRetainingCapacity();

        var myRow: []const u8 = row;

        for (subs) |sub| {
            myRow = replaceSubstring(allocator, myRow, sub.search, sub.replace);
        }

        for (myRow) |char| {
            if (char >= '0' and char <= '9') {
                try byteNums.append(char);
            }
        }

        if (byteNums.items.len == 1) {
            const num = [_]u8{byteNums.items[0]} ++ [_]u8{byteNums.items[0]};
            const result = try std.fmt.parseInt(u32, &num, 10);
            total += result;
        }

        if (byteNums.items.len > 1) {
            const num = [_]u8{byteNums.items[0]} ++ [_]u8{byteNums.items[byteNums.items.len - 1]};
            const result = try std.fmt.parseInt(u32, &num, 10);
            total += result;
        }
    }
    std.debug.print("{d}\n", .{total}); //281
}

fn replaceSubstring(allocator: std.mem.Allocator, original: []const u8, search: []const u8, replace: []const u8) []const u8 {
    const len_search = search.len;

    const index = std.mem.indexOf(u8, original, search);
    if (index == null) {
        return original;
    } else {
        const prefix = original[0..index.?];
        const suffix = original[(index.? + len_search)..];
        const result = std.fmt.allocPrint(allocator, "{s}{s}{s}", .{ prefix, replace, suffix }) catch "format failed";
        return result;
    }
}
