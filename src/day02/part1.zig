const std = @import("std");
const print = std.debug.print;
const input = @embedFile("test_input.txt");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    var success: i32 = 0;
    while (lines.next()) |line| {
        var split_input = std.mem.splitSequence(u8, line, " ");
        var nums = std.ArrayList(i32).init(allocator);
        defer nums.deinit();
        while (split_input.next()) |num_str| {
            const num = try std.fmt.parseInt(i32, num_str, 10);
            try nums.append(num);
        }
        if (try isSuccess(nums)) {
            success += 1;
        }
    }
    print("success: {}", .{success});
}

fn isSuccess(nums: std.ArrayList(i32)) !bool {
    var increasing: i32 = 0;
    var prev: i32 = -1;
    var line_success: i32 = 0;
    var i: i32 = 0;
    for (nums.items) |num| {
        i += 1;
        if (prev != -1) {
            if (increasing == 0 and prev < num) {
                increasing = 1;
            }
            if (increasing == 0 and prev > num) {
                increasing = -1;
            }
            if ((num == prev + increasing or num == prev + increasing * 2 or num == prev + increasing * 3) and increasing != 0) {
                line_success += 1;
            }
        }
        prev = num;
    }
    return line_success == i - 1;
}
