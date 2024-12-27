const std = @import("std");
const print = std.debug.print;
const input = @embedFile("input.txt");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var result_map = std.AutoHashMap(usize, usize).init(allocator);
    defer result_map.deinit();

    var found_map = std.AutoHashMap(usize, void).init(allocator);
    defer found_map.deinit();

    var lines_input = std.mem.splitSequence(u8, input, "\n");
    while (lines_input.next()) |line| {
        if (line.len == 0) continue;

        var price_array: [2000]usize = .{0} ** 2000;
        var price_diff_array: [2000]isize = .{0} ** 2000;
        found_map.clearRetainingCapacity();

        price_diff_array[0] = 0;
        var secret_number = try std.fmt.parseInt(usize, line, 10);
        for (0..2000) |i| {
            secret_number = prune(mix(secret_number, secret_number * 64));
            secret_number = prune(mix(secret_number, secret_number / 32));
            secret_number = prune(mix(secret_number, secret_number * 2048));
            price_array[i] = @mod(secret_number, 10);
            if (i > 0) {
                price_diff_array[i] = @as(isize, @intCast(price_array[i])) - @as(isize, @intCast(price_array[i - 1]));
            }
            if (i > 3) {
                const current_key = map_key(price_diff_array[i - 3 .. i + 1]);
                if (!found_map.contains(current_key)) {
                    try result_map.put(current_key, (result_map.get(current_key) orelse 0) + price_array[i]);
                    try found_map.put(current_key, {});
                }
            }
        }
    }
    var result_map_it = result_map.iterator();
    var biggest: usize = 0;
    while (result_map_it.next()) |entry| {
        if (entry.value_ptr.* > biggest) {
            biggest = entry.value_ptr.*;
        }
    }
    print("{}\n", .{biggest});
}

fn mix(a: usize, b: usize) usize {
    return a ^ b;
}

fn prune(number: usize) usize {
    return @mod(number, 16777216);
}

fn map_key(seq: []isize) usize {
    var result: usize = 0;
    for (seq, 0..) |num, i| {
        result += @as(usize, @intCast(@abs(num))) << @intCast(5 * i);
        if (num < 0) {
            result += @as(usize, @intCast(10)) << @intCast(5 * i);
        }
    }
    return result;
}
