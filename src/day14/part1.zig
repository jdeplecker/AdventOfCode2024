const std = @import("std");
const print = std.debug.print;
const input = @embedFile("test_input.txt");

pub fn main() !void {
    const width = 11;
    const height = 7;

    var quadrants: [4]usize = undefined;
    @memset(&quadrants, 0);

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

        const end_pos_x = @mod(pos_x + 100 * vel_x, width);
        const end_pos_y = @mod(pos_y + 100 * vel_y, height);

        if (end_pos_x < width / 2 and end_pos_y < height / 2) {
            quadrants[0] += 1;
        }
        if (end_pos_x > width / 2 and end_pos_y < height / 2) {
            quadrants[1] += 1;
        }
        if (end_pos_x > width / 2 and end_pos_y > height / 2) {
            quadrants[2] += 1;
        }
        if (end_pos_x < width / 2 and end_pos_y > height / 2) {
            quadrants[3] += 1;
        }
    }

    print("{d} {}", .{ quadrants, quadrants[0] * quadrants[1] * quadrants[2] * quadrants[3] });
}
