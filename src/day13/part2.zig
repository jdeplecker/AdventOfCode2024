const std = @import("std");
const print = std.debug.print;
const input = @embedFile("test_input.txt");

const Pos = struct {
    const Self = @This();
    x: usize,
    y: usize,
    pub fn ix(self: Self) isize {
        return @as(isize, @intCast(self.x));
    }
    pub fn iy(self: Self) isize {
        return @as(isize, @intCast(self.y));
    }
};

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
            const prize_pos = Pos{ .x = 10000000000000 + try std.fmt.parseInt(usize, x_y_split.next().?[2..], 10), .y = 10000000000000 + try std.fmt.parseInt(usize, x_y_split.next().?[2..], 10) };
            print("{} {} {}\n", .{ a_button_pos, b_button_pos, prize_pos });
            total += find_smallest_cost(a_button_pos, b_button_pos, prize_pos);
        }
    }
    print("{}\n", .{total});
}

fn find_smallest_cost(a_button_pos: Pos, b_button_pos: Pos, prize_pos: Pos) usize {
    // a_nom=By * Px − Bx * Py
    // b_nom=Ax * Py − Ay * Px
    // denom=Ax * By − Ay * Bx
    const a_nom = b_button_pos.iy() * prize_pos.ix() - b_button_pos.ix() * prize_pos.iy();
    const b_nom = a_button_pos.ix() * prize_pos.iy() - a_button_pos.iy() * prize_pos.ix();
    const denom = a_button_pos.ix() * b_button_pos.iy() - a_button_pos.iy() * b_button_pos.ix();

    const a_presses: isize = @divFloor(a_nom, denom);
    const b_presses: isize = @divFloor(b_nom, denom);

    const x = a_button_pos.ix() * a_presses + b_button_pos.ix() * b_presses;
    const y = a_button_pos.iy() * a_presses + b_button_pos.iy() * b_presses;

    if (x == prize_pos.x and y == prize_pos.y) {
        return @as(usize, @intCast(a_presses * 3 + b_presses));
    }

    return 0;
}
