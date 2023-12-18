const std = @import("std");

const Move = struct {
    red: u8,
    green: u8,
    blue: u8,
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

    var it = std.mem.tokenizeAny(u8, read_buf, "\n");
    while (it.next()) |row| {
        const sep = std.mem.indexOfScalar(u8, row, ':').?;
        // const game_id = try parse_game(row[0..sep]);
        // _ = game_id;
        const hands = row[sep + 1 ..];
        total += try calculate_min_game_amount(hands);
    }
    std.debug.print("{d}\n", .{total});
}

fn calculate_min_game_amount(hands: []const u8) !u32 {
    var moves = std.mem.tokenizeAny(u8, hands, ";");

    var red: u32 = 0;
    var green: u32 = 0;
    var blue: u32 = 0;
    while (moves.next()) |move| {
        const m = try decode_move(move);
        if (m.red > red) {
            red = m.red;
        }
        if (m.green > green) {
            green = m.green;
        }

        if (m.blue > blue) {
            blue = m.blue;
        }
    }
    return red * green * blue;
}

fn decode_move(hand: []const u8) !Move {
    var move = Move{ .blue = 0, .green = 0, .red = 0 };
    var colors = std.mem.tokenizeAny(u8, hand, ",");
    var value: u8 = undefined;
    while (colors.next()) |color| {
        var cs = std.mem.tokenizeAny(u8, color, " ");
        while (cs.next()) |c| {
            if (std.mem.eql(u8, c, "red")) {
                move.red = value;
            } else if (std.mem.eql(u8, c, "green")) {
                move.green = value;
            } else if (std.mem.eql(u8, c, "blue")) {
                move.blue = value;
            } else {
                value = try parse_u8(c);
            }
        }
    }
    return move;
}

fn parse_u8(s: []const u8) !u8 {
    const result = try std.fmt.parseInt(u8, s, 10);
    return result;
}

fn parse_game(range: []const u8) !u8 {
    const sep = std.mem.indexOfScalar(u8, range, ' ').?;
    return try parse_u8(range[sep + 1 ..]);
}
