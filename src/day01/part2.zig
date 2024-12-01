const std = @import("std");
const print = std.debug.print;
const input = @embedFile("test_input.txt");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var left_nums = std.ArrayList(u32).init(allocator);
    defer left_nums.deinit();
    var right_nums = std.ArrayList(u32).init(allocator);
    defer right_nums.deinit();


    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        var left_right = std.mem.splitSequence(u8, line, "   ");
        const left = try std.fmt.parseInt(u32, left_right.next().?, 10);
        try left_nums.append(left);
        const right = try std.fmt.parseInt(u32, left_right.next().?, 10);
        try right_nums.append(right);
    }
    std.mem.sort(u32, left_nums.items, {}, std.sort.asc(u32));
    std.mem.sort(u32, right_nums.items, {}, std.sort.asc(u32));

    var sum: u32 = 0;
    for (left_nums.items) |left_num| {
        var occurence: u32 = 0;
        for (right_nums.items) |right_num| {
            if (right_num == left_num) {
                occurence += 1;
            }
        }

        sum += left_num * occurence;
    }
    print("{}", .{sum});
}
