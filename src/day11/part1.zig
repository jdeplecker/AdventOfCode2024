const std = @import("std");
const print = std.debug.print;
const input = @embedFile("test_input.txt");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var stone_split = std.mem.splitSequence(u8, input, " ");
    var stones = std.ArrayList(usize).init(allocator);
    defer stones.deinit();
    while (stone_split.next()) |stone_str| {
        try stones.append(try std.fmt.parseInt(usize, stone_str, 10));
    }

    var new_stones = try blink(allocator, stones.items);
    for (0..24) |_| {
        print("{}\n", .{new_stones.len});
        new_stones = try blink(allocator, new_stones);
    }
    print("{}\n", .{new_stones.len});
}

fn blink(allocator: std.mem.Allocator, stones: []usize) ![]usize {
    var new_stones = std.ArrayList(usize).init(allocator);
    for (stones) |stone| {
        if (stone == 0) {
            try new_stones.append(1);
        } else if (std.math.log10(stone) % 2 == 1) {
            try new_stones.append(stone / std.math.pow(usize, 10, (std.math.log10(stone) + 1) / 2));
            try new_stones.append(stone % std.math.pow(usize, 10, (std.math.log10(stone) + 1) / 2));
        } else {
            try new_stones.append(2024 * stone);
        }
    }
    return new_stones.items;
}
