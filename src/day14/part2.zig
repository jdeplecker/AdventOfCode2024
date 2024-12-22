const std = @import("std");
const print = std.debug.print;
const input = @embedFile("test_input.txt");

const Robot = struct {
    const Self = @This();
    x: isize,
    y: isize,
    vx: isize,
    vy: isize,
    steps: usize = 0,
    pub fn ux(self: Self) usize {
        return @as(usize, @intCast(self.x));
    }
    pub fn uy(self: Self) usize {
        return @as(usize, @intCast(self.y));
    }
    pub fn step(self: *Self) void {
        self.steps += 1;
        self.x = @mod(self.x + self.vx, width);
        self.y = @mod(self.y + self.vy, height);
    }
    pub fn create(allocator: std.mem.Allocator, x: isize, y: isize, vx: isize, vy: isize) *Self {
        const robot = allocator.create(Self) catch @panic("OOM");
        robot.* = .{
            .x = x,
            .y = y,
            .vx = vx,
            .vy = vy,
        };
        return robot;
    }
};

const width = 101;
const height = 103;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var robots = std.ArrayList(*Robot).init(allocator);
    defer robots.deinit();

    var line_input = std.mem.splitSequence(u8, input, "\n");
    while (line_input.next()) |line| {
        if (std.mem.eql(u8, line, "")) {
            continue;
        }
        var pos_vel = std.mem.splitSequence(u8, line, " ");
        var pos_x_y = std.mem.splitSequence(u8, pos_vel.next().?, ",");
        const pos_x = try std.fmt.parseInt(isize, pos_x_y.next().?[2..], 10);
        const pos_y = try std.fmt.parseInt(isize, pos_x_y.next().?, 10);
        var vel_x_y = std.mem.splitSequence(u8, pos_vel.next().?, ",");
        const vel_x = try std.fmt.parseInt(isize, vel_x_y.next().?[2..], 10);
        const vel_y = try std.fmt.parseInt(isize, vel_x_y.next().?, 10);

        try robots.append(Robot.create(allocator, pos_x, pos_y, vel_x, vel_y));
    }

    var board: [height][width]u8 = undefined;
    var found = false;
    while (!found) {
        board = .{.{'.'} ** width} ** height;

        for (robots.items) |robot| {
            board[robot.*.uy()][robot.*.ux()] = 'X';
        }

        for (board) |board_line| {
            if (std.mem.indexOf(u8, &board_line, "XXXXXXXXXXXXXXXXXXXXX")) |_| {
                print_board(&board);
                found = true;
                break;
            }
        }

        for (robots.items) |robot| {
            robot.step();
        }
    }

    print("{}", .{robots.items[0].steps - 1});
    for (robots.items) |robot| {
        allocator.destroy(robot);
    }
}

fn print_board(board: *[height][width]u8) void {
    for (board) |board_line| {
        print("{s}\n", .{board_line});
    }
}
