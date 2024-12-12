const std = @import("std");
const print = std.debug.print;
const input = @embedFile("input.txt");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var stone_split = std.mem.splitSequence(u8, input, " ");
    var stones = std.AutoHashMap(usize, usize).init(allocator);
    defer stones.deinit();
    var new_stones = std.AutoHashMap(usize, usize).init(allocator);
    defer new_stones.deinit();

    while (stone_split.next()) |stone_str| {
        const stone_entry = try stones.getOrPutValue(try std.fmt.parseInt(usize, stone_str, 10), 0);
        stone_entry.value_ptr.* += 1;
    }

    for (0..75) |_| {
        var stones_it = stones.iterator();
        while (stones_it.next()) |stone_entry| {
            const stone = stone_entry.key_ptr.*;
            const stone_amount = stone_entry.value_ptr.*;
            if (stone == 0) {
                const new_stone_entry = try new_stones.getOrPutValue(1, 0);
                new_stone_entry.value_ptr.* += stone_amount;
            } else if (std.math.log10(stone) % 2 == 1) {
                const left_stone = stone / std.math.pow(usize, 10, (std.math.log10(stone) + 1) / 2);
                const right_stone = stone % std.math.pow(usize, 10, (std.math.log10(stone) + 1) / 2);
                const new_stone_entry = try new_stones.getOrPutValue(left_stone, 0);
                new_stone_entry.value_ptr.* += stone_amount;
                const new_stone_entry2 = try new_stones.getOrPutValue(right_stone, 0);
                new_stone_entry2.value_ptr.* += stone_amount;
            } else {
                const new_stone_entry = try new_stones.getOrPutValue(2024 * stone, 0);
                new_stone_entry.value_ptr.* += stone_amount;
            }
        }
        stones.clearRetainingCapacity();
        std.mem.swap(std.AutoHashMap(usize, usize), &stones, &new_stones);

        var stone_value_it = stones.valueIterator();
        var result: usize = 0;
        while (stone_value_it.next()) |value| {
            result += value.*;
        }
        print("{}\n", .{result});
    }
}
