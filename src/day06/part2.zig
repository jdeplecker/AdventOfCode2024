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

    var result: usize = 0;
    const guard_pos = find_start_pos(board);
    for (0..board.items.len) |i| {
        for (0..board.items[0].len) |j| {
            if (guard_pos.x != j or guard_pos.y != i) {
                var cloned_board = try deep_clone(allocator, board);
                defer cloned_board.deinit();
                if (has_loop(cloned_board, guard_pos, Pos{ .x = @as(i32, @intCast(j)), .y = @as(i32, @intCast(i)) })) {
                    result += 1;
                }
                for (cloned_board.items) |row| {
                    allocator.free(row);
                }
            }
        }
    }

    print("{}", .{result});
    for (board.items) |line| {
        allocator.free(line);
    }
}

fn deep_clone(allocator: std.mem.Allocator, board: std.ArrayList([]u8)) !std.ArrayList([]u8) {
    var result = std.ArrayList([]u8).init(allocator);
    for (board.items) |line| {
        try result.append(try allocator.dupe(u8, line));
    }
    return result;
}

fn has_loop(board: std.ArrayList([]u8), start_pos: Pos, extra_obs_pos: Pos) bool {
    board.items[extra_obs_pos.uy()][extra_obs_pos.ux()] = '#';
    var guard_pos = Pos{ .x = start_pos.x, .y = start_pos.y };
    var guard_dir_index: usize = 0;
    const guard_dirs: [4][2]i32 = .{ .{ 0, -1 }, .{ 1, 0 }, .{ 0, 1 }, .{ -1, 0 } };
    var loop_count: usize = 0;
    while (is_in_board(board, guard_pos)) {
        board.items[guard_pos.uy()][guard_pos.ux()] = 'X';
        var next_pos = Pos{ .x = guard_pos.x + guard_dirs[guard_dir_index][0], .y = guard_pos.y + guard_dirs[guard_dir_index][1] };
        while (is_in_board(board, next_pos) and board.items[next_pos.uy()][next_pos.ux()] == '#') {
            guard_dir_index = (guard_dir_index + 1) % 4;
            next_pos = Pos{ .x = guard_pos.x + guard_dirs[guard_dir_index][0], .y = guard_pos.y + guard_dirs[guard_dir_index][1] };
        }
        guard_pos = Pos{ .x = next_pos.x, .y = next_pos.y };
        if (loop_count < 10000) {
            loop_count += 1;
        } else {
            return true;
        }
    }
    return false;
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
