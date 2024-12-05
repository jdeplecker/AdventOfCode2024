const std = @import("std");
const print = std.debug.print;
const input = @embedFile("test_input.txt");

pub fn main() !void {
    var result: u32 = 0;
    var do = true;
    var mul_splits = std.mem.splitSequence(u8, input, "mul(");
    while (mul_splits.next()) |mul_split| {
        var end_splits = std.mem.splitSequence(u8, mul_split, ")");
        while (end_splits.next()) |end_split| {
            var comma_splits = std.mem.splitSequence(u8, end_split, ",");
            if (comma_splits.next()) |first| {
                if (comma_splits.next()) |second| {
                    if (comma_splits.next()) |_| {
                        continue;
                    }
                    const first_num = std.fmt.parseInt(u32, first, 10) catch 0;
                    const second_num = std.fmt.parseInt(u32, second, 10) catch 0;
                    if (do) {
                        result += first_num * second_num;
                    }
                }
            }
        }
        const do_index = std.mem.lastIndexOf(u8, mul_split, "do()") orelse 0;
        const dont_index = std.mem.lastIndexOf(u8, mul_split, "don't()") orelse 0;
        if (do_index > 0 and do_index > dont_index) {
            do = true;
        }
        if (dont_index > 0 and dont_index > do_index) {
            do = false;
        }
    }
    print("{}", .{result});
}
