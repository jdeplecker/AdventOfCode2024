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

    var board = std.ArrayList([]u8).init(allocator);
    defer board.deinit();

    var lines_input = std.mem.splitSequence(u8, input, "\n");
    while (lines_input.next()) |line| {
        if (line.len > 1) {
            try board.append(try allocator.dupe(u8, line));
        }
    }

    var guard_pos = find_start_pos(board);
    var guard_dir_index: usize = 0;
    const guard_dirs: [4][2]i32 = .{ .{ 0, -1 }, .{ 1, 0 }, .{ 0, 1 }, .{ -1, 0 } };
    while (is_in_board(board, guard_pos)) {
        board.items[guard_pos.uy()][guard_pos.ux()] = 'X';
        var next_pos = Pos{ .x = guard_pos.x + guard_dirs[guard_dir_index][0], .y = guard_pos.y + guard_dirs[guard_dir_index][1] };
        while (is_in_board(board, next_pos) and board.items[next_pos.uy()][next_pos.ux()] == '#') {
            guard_dir_index = (guard_dir_index + 1) % 4;
            next_pos = Pos{ .x = guard_pos.x + guard_dirs[guard_dir_index][0], .y = guard_pos.y + guard_dirs[guard_dir_index][1] };
        }
        guard_pos = Pos{ .x = next_pos.x, .y = next_pos.y };
    }

    print("{}", .{count_char_on_board(board, 'X')});
    for (board.items) |line| {
        allocator.free(line);
    }
}

fn is_in_board(board: std.ArrayList([]u8), pos: Pos) bool {
    return pos.x >= 0 and pos.y >= 0 and pos.x < board.items[0].len and pos.y < board.items.len;
}

fn find_start_pos(board: std.ArrayList([]u8)) Pos {
    for (0..board.items.len) |i| {
        for (0..board.items[i].len) |j| {
            if (board.items[i][j] == '^') {
                return Pos{ .x = @as(i32, @intCast(j)), .y = @as(i32, @intCast(i)) };
            }
        }
    }
    return Pos{ .x = 0, .y = 0 };
}

fn count_char_on_board(board: std.ArrayList([]u8), char: u8) usize {
    var result: usize = 0;
    for (board.items) |line| {
        for (line) |board_char| {
            if (board_char == char) {
                result += 1;
            }
        }
    }
    return result;
}
