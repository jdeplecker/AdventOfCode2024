const std = @import("std");
const print = std.debug.print;
const input = @embedFile("test_input.txt");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var locks_keys = std.ArrayList(std.ArrayList(usize)).init(allocator);
    defer {
        for (locks_keys.items) |list| {
            list.deinit();
        }
        locks_keys.deinit();
    }

    var line_input = std.mem.splitSequence(u8, input, "\n\n");
    while (line_input.next()) |line| {
        if (std.mem.eql(u8, "", line)) continue;
        var current_lock_key = std.ArrayList(usize).init(allocator);
        for (line, 0..) |char, i| {
            if (char == '#') {
                try current_lock_key.append(i);
            }
        }
        try locks_keys.append(current_lock_key);
    }

    var result: usize = 0;
    for (locks_keys.items) |lock| {
        key_loop: for (locks_keys.items) |key| {
            for (lock.items) |lock_item| {
                for (key.items) |key_item| {
                    if (lock_item == key_item) {
                        continue :key_loop;
                    }
                }
            }
            result += 1;
        }
    }
    print("result: {}\n", .{result / 2});
}
