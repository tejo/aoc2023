const std = @import("std");

const red: i8 = 12;
const green: i8 = 13;
const blue: i8 = 14;

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
        const game_id = try parse_game(row[0..sep]);
        const hands = row[sep + 1 ..];
        std.debug.print("{any}\n", .{game_id});
        if (try validate_game(hands)) {
            total += game_id;
        }
    }
    std.debug.print("{d}\n", .{total});
}

fn validate_game(hands: []const u8) !bool {
    var moves = std.mem.tokenizeAny(u8, hands, ";");
    while (moves.next()) |hand| {
        const m = try decode_move(hand);
        if (m.red > red or m.green > green or m.blue > blue) {
            return false;
        }
        std.debug.print("{any}\n", .{m});
    }
    return true;
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
