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
            if (board.len == 0) {
                board = try allocator.alloc([]u8, line.len);
            }

            if (std.mem.indexOf(u8, line, "@")) |robot_i| {
                robot = Pos{ .x = robot_i, .y = board_size };
            }

            board[board_size] = try allocator.dupe(u8, line);
            board_size += 1;
        } else {
            instructions = try std.mem.concat(allocator, u8, &[_][]const u8{ instructions, try allocator.dupe(u8, line) });
        }
    }

    for (instructions) |instruction| {
        switch (instruction) {
            '<' => {
                move_robot(-1, 0, 0, board_size - 1, &board, &robot);
            },
            '>' => {
                move_robot(1, 0, 0, board_size - 1, &board, &robot);
            },
            '^' => {
                move_robot(0, -1, 0, board_size - 1, &board, &robot);
            },
            'v' => {
                move_robot(0, 1, 0, board_size - 1, &board, &robot);
            },
            else => {},
        }
    }

    var total: usize = 0;
    for (board, 0..) |board_line, y| {
        for (board_line, 0..) |letter, x| {
            if (letter == 'O') {
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
        if (board.*[look_y][look_x] == 'O') {
            found_box = true;
        }
        if (board.*[look_y][look_x] == '#') {
            break;
        }
        if (board.*[look_y][look_x] == '.') {
            if (found_box) {
                board.*[look_y][look_x] = 'O';
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
