const std = @import("std");
const print = std.debug.print;
const input = @embedFile("test_input.txt");

const Pos = struct {
    const Self = @This();
    x: i32,
    y: i32,
    pub fn ux(self: Self) usize {
        return @as(usize, @intCast(self.x));
    }
    pub fn uy(self: Self) usize {
        return @as(usize, @intCast(self.y));
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var antennas = std.AutoHashMap(u8, std.ArrayList(Pos)).init(allocator);
    defer antennas.deinit();

    var antinodes = std.ArrayList([]u8).init(allocator);
    defer antinodes.deinit();

    var lines_input = std.mem.splitSequence(u8, input, "\n");
    var antenna_y: i32 = 0;
    while (lines_input.next()) |line| {
        if (line.len > 1) {
            const antinode_line = try allocator.alloc(u8, line.len);
            for (0..line.len) |i| {
                antinode_line[i] = '.';
                if (line[i] != '.') {
                    const antenna_entry = try antennas.getOrPutValue(line[i], std.ArrayList(Pos).init(allocator));
                    try antenna_entry.value_ptr.*.append(Pos{ .x = @as(i32, @intCast(i)), .y = antenna_y });
                }
            }
            try antinodes.append(antinode_line);
            antenna_y += 1;
        }
    }

    var antenna_itr = antennas.iterator();
    while (antenna_itr.next()) |item| {
        put_antinodes(antinodes, item.value_ptr.*);
        item.value_ptr.*.deinit();
    }
    print("{}\n", .{count_chars(antinodes, 'X')});
    print_board(antinodes);
    for (antinodes.items) |item| {
        allocator.free(item);
    }
}

fn print_board(board: std.ArrayList([]u8)) void {
    for (board.items) |line| {
        for (line) |item| {
            print("{c}", .{item});
        }
        print("\n", .{});
    }
}

fn put_antinodes(antinode_board: std.ArrayList([]u8), antenna_positions: std.ArrayList(Pos)) void {
    for (antenna_positions.items, 0..) |antenna_pos_left, i| {
        for (antenna_positions.items, 0..) |antenna_pos_right, j| {
            if (i == j) {
                continue;
            }
            var pos1_idx: i32 = 0;
            var anti_position1 = anti1(antenna_pos_left, antenna_pos_right, pos1_idx);
            while (anti_position1.x >= 0 and anti_position1.y >= 0 and anti_position1.x < antinode_board.items.len and anti_position1.y < antinode_board.items.len) {
                antinode_board.items[anti_position1.uy()][anti_position1.ux()] = 'X';
                anti_position1 = anti1(antenna_pos_left, antenna_pos_right, pos1_idx);
                pos1_idx += 1;
            }
            var pos2_idx: i32 = 0;
            var anti_position2 = anti2(antenna_pos_left, antenna_pos_right, pos2_idx);
            if (anti_position2.x >= 0 and anti_position2.y >= 0 and anti_position2.x < antinode_board.items.len and anti_position2.y < antinode_board.items.len) {
                antinode_board.items[anti_position2.uy()][anti_position2.ux()] = 'X';
                anti_position2 = anti1(antenna_pos_left, antenna_pos_right, pos2_idx);
                pos2_idx += 1;
            }
        }
    }
}

fn anti1(antenna_pos_left: Pos, antenna_pos_right: Pos, pos_idx: i32) Pos {
    return Pos{ .x = antenna_pos_left.x - pos_idx * (antenna_pos_right.x - antenna_pos_left.x), .y = antenna_pos_left.y - pos_idx * (antenna_pos_right.y - antenna_pos_left.y) };
}

fn anti2(antenna_pos_left: Pos, antenna_pos_right: Pos, pos_idx: i32) Pos {
    return Pos{ .x = antenna_pos_right.x + pos_idx * (antenna_pos_right.x - antenna_pos_left.x), .y = antenna_pos_right.y + pos_idx * (antenna_pos_right.y - antenna_pos_left.y) };
}

fn count_chars(haystack: std.ArrayList([]u8), needle: u8) usize {
    var result: usize = 0;
    for (haystack.items) |line| {
        for (line) |char_to_test| {
            if (char_to_test == needle) {
                result += 1;
            }
        }
    }
    return result;
}
