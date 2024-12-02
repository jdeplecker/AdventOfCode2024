const std = @import("std");
const print = std.debug.print;
const input = @embedFile("test_input.txt");

pub fn main() !void {
    // var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    // defer _ = gpa.deinit();
    // const allocator = gpa.allocator();

    print("hello", .{});
}
