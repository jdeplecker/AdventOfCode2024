const std = @import("std");
const print = std.debug.print;
const input = @embedFile("test_input.txt");

const Pos = struct {
    x: usize,
    y: usize,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var board_list = std.ArrayList([]u8).init(allocator);
    var board: [][]u8 = undefined;
    var instructions: []u8 = undefined;
    var robot: Pos = undefined;

    var line_input = std.mem.splitSequence(u8, input, "\n");
    var board_size: usize = 0;
    while (line_input.next()) |line| {
        if (std.mem.eql(u8, line, "")) {
            continue;
        }

        if (line[0] == '#') {
            const wall_replaced = try replace(allocator, try allocator.dupe(u8, line), "#", "##");
            const chest_replaced = try replace(allocator, wall_replaced, "O", "[]");
            const empty_replaced = try replace(allocator, chest_replaced, ".", "..");
            const robot_replaced = try replace(allocator, empty_replaced, "@", "@.");
            try board_list.append(robot_replaced);
            if (std.mem.indexOf(u8, robot_replaced, "@")) |robot_i| {
                robot = Pos{ .x = robot_i, .y = board_size };
            }
            board_size += 1;
        } else {
            instructions = try std.mem.concat(allocator, u8, &[_][]const u8{ instructions, try allocator.dupe(u8, line) });
        }
    }
    board = try board_list.toOwnedSlice();

    print_board(board);
    print("{s} {s} {}\n", .{ board, instructions, robot });
    for (instructions) |instruction| {
        switch (instruction) {
            '<' => {
                move_robot(-1, 0, 0, (board_size - 1) * 2, &board, &robot);
            },
            '>' => {
                move_robot(1, 0, 0, (board_size - 1) * 2, &board, &robot);
            },
            '^' => {
                move_robot(0, -1, 0, (board_size - 1) * 2, &board, &robot);
            },
            'v' => {
                move_robot(0, 1, 0, (board_size - 1) * 2, &board, &robot);
            },
            else => {},
        }
        print_board(board);
        print("{}\n", .{robot});
    }

    var total: usize = 0;
    for (board, 0..) |board_line, y| {
        for (board_line, 0..) |letter, x| {
            if (letter == '[') {
                total += 100 * y + x;
            }
        }
    }
    print("{}\n", .{total});
}

fn move_robot(dx: comptime_int, dy: comptime_int, left_limit: usize, right_limit: usize, board: *[][]u8, robot: *Pos) void {
    var look_x = add(robot.x, dx);
    var look_y = add(robot.y, dy);
    var found_box = false;
    while (look_x > left_limit and look_y > left_limit and look_x < right_limit and look_y < right_limit) {
        if (board.*[look_y][look_x] == '[' or board.*[look_y][look_x] == ']') {
            found_box = true;
        }
        if (board.*[look_y][look_x] == '#') {
            break;
        }
        if (board.*[look_y][look_x] == '.') {
            if (found_box) {
                if (dy == 0) {
                    std.mem.rotate(u8, board.*[look_y][look_x..robot.x], 1);
                } else if (!isVerticalCollision(board, Pos{ .x = robot.x, .y = robot.y }, dy)) {
                    moveVertical(board, Pos{ .x = robot.x, .y = robot.y }, dy);
                } else {
                    break;
                }
            }
            board.*[add(robot.y, dy)][add(robot.x, dx)] = '@';
            board.*[robot.y][robot.x] = '.';
            robot.x = add(robot.x, dx);
            robot.y = add(robot.y, dy);
            break;
        }
        look_x = add(look_x, dx);
        look_y = add(look_y, dy);
    }
}

fn add(a: usize, b: isize) usize {
    return @as(usize, @intCast(@as(isize, @intCast(a)) + b));
}

fn replace(allocator: std.mem.Allocator, string: []u8, needle: *const [1:0]u8, replacement: *const [2:0]u8) ![]u8 {
    const replaced_string = try allocator.alloc(u8, std.mem.replacementSize(u8, string, needle, replacement));
    defer allocator.free(replaced_string);
    _ = std.mem.replace(u8, string, needle, replacement, replaced_string);
    return try allocator.dupe(u8, replaced_string);
}

fn print_board(board: [][]u8) void {
    for (board) |board_line| {
        print("{s}\n", .{board_line});
    }
}

fn isVerticalCollision(board: *[][]u8, pos: Pos, dy: comptime_int) bool {
    const x = pos.x;
    const y = add(pos.y, dy);
    switch (board.*[y][x]) {
        '#' => return true,
        '.' => return false,
        '[' => return isVerticalCollision(board, Pos{ .x = x, .y = y }, dy) or
            isVerticalCollision(board, Pos{ .x = x + 1, .y = y }, dy),
        ']' => return isVerticalCollision(board, Pos{ .x = x, .y = y }, dy) or
            isVerticalCollision(board, Pos{ .x = x - 1, .y = y }, dy),
        else => unreachable,
    }
}

fn moveVertical(board: *[][]u8, pos: Pos, dy: comptime_int) void {
    const x = pos.x;
    const y = add(pos.y, dy);
    switch (board.*[y][x]) {
        '.' => {
            board.*[y][x] = board.*[pos.y][pos.x];
            board.*[pos.y][pos.x] = '.';
        },
        '[' => {
            moveVertical(board, Pos{ .x = x, .y = y }, dy);
            moveVertical(board, Pos{ .x = x + 1, .y = y }, dy);
            board.*[y][x] = board.*[pos.y][pos.x];
            board.*[pos.y][pos.x] = '.';
        },
        ']' => {
            moveVertical(board, Pos{ .x = x, .y = y }, dy);
            moveVertical(board, Pos{ .x = x - 1, .y = y }, dy);
            board.*[y][x] = board.*[pos.y][pos.x];
            board.*[pos.y][pos.x] = '.';
        },
        else => unreachable,
    }
}
