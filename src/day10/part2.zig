const std = @import("std");
const print = std.debug.print;
const input = @embedFile("input.txt");

const Pos = struct {
    const Self = @This();
    x: usize,
    y: usize,
    pub fn eq(self: Self, other: Pos) bool {
        return self.x == other.x and self.y == other.y;
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var mountain = std.ArrayList([]usize).init(allocator);
    defer mountain.deinit();

    var trail_heads = std.ArrayList(Pos).init(allocator);
    defer trail_heads.deinit();

    var lines_input = std.mem.splitSequence(u8, input, "\n");
    while (lines_input.next()) |line| {
        if (line.len > 1) {
            const mountain_line = try allocator.alloc(usize, line.len);
            for (0..line.len) |i| {
                mountain_line[i] = @as(usize, @intCast(line[i])) - 48;
                if (mountain_line[i] == 0) {
                    try trail_heads.append(Pos{ .x = i, .y = mountain.items.len });
                }
            }
            try mountain.append(mountain_line);
        }
    }

    var result: usize = 0;
    for (trail_heads.items) |head| {
        result += try get_trail_score(allocator, mountain, head);
    }
    print("{}", .{result});
    for (mountain.items) |item| {
        allocator.free(item);
    }
}

fn get_trail_score(allocator: std.mem.Allocator, mountain: std.ArrayList([]usize), start: Pos) !usize {
    var num_trails: usize = 0;
    var positions_to_visit = std.ArrayList(Pos).init(allocator);
    defer positions_to_visit.deinit();
    try positions_to_visit.append(start);
    while (positions_to_visit.items.len > 0) {
        const current_pos: Pos = positions_to_visit.pop();
        const height_to_look_for = mountain.items[current_pos.y][current_pos.x] + 1;
        if (height_to_look_for == 10) {
            num_trails += 1;
            continue;
        }
        if (current_pos.y > 0 and mountain.items[current_pos.y - 1][current_pos.x] == height_to_look_for) {
            try positions_to_visit.append(Pos{ .y = current_pos.y - 1, .x = current_pos.x });
        }
        if (current_pos.y < mountain.items.len - 1 and mountain.items[current_pos.y + 1][current_pos.x] == height_to_look_for) {
            try positions_to_visit.append(Pos{ .y = current_pos.y + 1, .x = current_pos.x });
        }
        if (current_pos.x > 0 and mountain.items[current_pos.y][current_pos.x - 1] == height_to_look_for) {
            try positions_to_visit.append(Pos{ .y = current_pos.y, .x = current_pos.x - 1 });
        }
        if (current_pos.x < mountain.items[0].len - 1 and mountain.items[current_pos.y][current_pos.x + 1] == height_to_look_for) {
            try positions_to_visit.append(Pos{ .y = current_pos.y, .x = current_pos.x + 1 });
        }
    }

    return num_trails;
}
