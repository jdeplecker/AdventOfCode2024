const std = @import("std");
const print = std.debug.print;
const input = @embedFile("test_input.txt");

const Pos = struct { x: usize, y: usize };

pub fn main() !void {
    var line_split = std.mem.splitSequence(u8, input, "\n");
    var a_button_pos: Pos = undefined;
    var b_button_pos: Pos = undefined;

    var total: usize = 0;
    while (line_split.next()) |line| {
        if (std.mem.eql(u8, line, "")) {
            continue;
        }
        var name_split = std.mem.splitSequence(u8, line, ": ");
        const name = name_split.next().?;
        const pos_str = name_split.next().?;
        if (std.mem.eql(u8, name, "Button A")) {
            var x_y_split = std.mem.splitSequence(u8, pos_str, ", ");
            a_button_pos = Pos{ .x = try std.fmt.parseInt(usize, x_y_split.next().?[2..], 10), .y = try std.fmt.parseInt(usize, x_y_split.next().?[2..], 10) };
        }
        if (std.mem.eql(u8, name, "Button B")) {
            var x_y_split = std.mem.splitSequence(u8, pos_str, ", ");
            b_button_pos = Pos{ .x = try std.fmt.parseInt(usize, x_y_split.next().?[2..], 10), .y = try std.fmt.parseInt(usize, x_y_split.next().?[2..], 10) };
        }
        if (std.mem.eql(u8, name, "Prize")) {
            var x_y_split = std.mem.splitSequence(u8, pos_str, ", ");
            const prize_pos = Pos{ .x = try std.fmt.parseInt(usize, x_y_split.next().?[2..], 10), .y = try std.fmt.parseInt(usize, x_y_split.next().?[2..], 10) };
            total += find_smallest_cost(a_button_pos, b_button_pos, prize_pos);
        }
    }
    print("{}\n", .{total});
}

fn find_smallest_cost(a_button_pos: Pos, b_button_pos: Pos, prize_pos: Pos) usize {
    var lowest_cost: usize = 400;
    var winner_a: usize = 200;
    var winner_b: usize = 200;

    for (0..100) |a_presses| {
        for (0..100) |b_presses| {
            const x = a_button_pos.x * a_presses + b_button_pos.x * b_presses;
            const y = a_button_pos.y * a_presses + b_button_pos.y * b_presses;
            const cost = a_presses * 3 + b_presses;

            if (cost < lowest_cost and x == prize_pos.x and y == prize_pos.y) {
                winner_a = a_presses;
                winner_b = b_presses;
                lowest_cost = cost;
            }
        }
    }
    if (lowest_cost == 400) {
        return 0;
    }
    return lowest_cost;
}
