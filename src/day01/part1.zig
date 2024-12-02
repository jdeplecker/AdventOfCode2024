const std = @import("std");
const print = std.debug.print;
const input = @embedFile("test_input.txt");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var left_nums = std.ArrayList(i32).init(allocator);
    defer left_nums.deinit();
    var right_nums = std.ArrayList(i32).init(allocator);
    defer right_nums.deinit();

    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        var left_right = std.mem.splitSequence(u8, line, "   ");
        const left = try std.fmt.parseInt(i32, left_right.next().?, 10);
        try left_nums.append(left);
        const right = try std.fmt.parseInt(i32, left_right.next().?, 10);
        try right_nums.append(right);
    }
    std.mem.sort(i32, left_nums.items, {}, std.sort.asc(i32));
    std.mem.sort(i32, right_nums.items, {}, std.sort.asc(i32));

    var sum: u32 = 0;
    for (left_nums.items, 0..left_nums.items.len) |left_num, i| {
        sum += @abs(left_num - right_nums.items[i]);
    }
    print("{}", .{sum});
}
