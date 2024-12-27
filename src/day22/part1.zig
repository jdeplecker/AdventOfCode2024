const std = @import("std");
const print = std.debug.print;
const input = @embedFile("test_input.txt");

pub fn main() !void {
    var total: usize = 0;
    var lines_input = std.mem.splitSequence(u8, input, "\n");
    while (lines_input.next()) |line| {
        if (line.len == 0) continue;
        var secret_number = try std.fmt.parseInt(usize, line, 10);
        for (0..2000) |_| {
            secret_number = prune(mix(secret_number, secret_number * 64));
            secret_number = prune(mix(secret_number, secret_number / 32));
            secret_number = prune(mix(secret_number, secret_number * 2048));
        }
        total += secret_number;
    }
    print("total {}\n", .{total});
}

fn mix(a: usize, b: usize) usize {
    return a ^ b;
}

fn prune(number: usize) usize {
    return @mod(number, 16777216);
}
