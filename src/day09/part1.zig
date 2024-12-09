const std = @import("std");
const print = std.debug.print;
const input = @embedFile("test_input.txt");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const file_sizes = try allocator.alloc(usize, input.len / 2 + 1);
    defer allocator.free(file_sizes);
    const white_spaces = try allocator.alloc(usize, input.len / 2);
    defer allocator.free(white_spaces);

    for (0..input.len) |i| {
        if (i % 2 == 0) {
            file_sizes[i / 2] = @as(usize, @intCast(input[i])) - 48;
        } else {
            white_spaces[i / 2] = @as(usize, @intCast(input[i])) - 48;
        }
    }

    var fwd_file_ptr: usize = 0;
    var bwd_file_ptr = file_sizes.len;
    var bwd_file_rest: usize = 0;
    var fwd_white_ptr: usize = 0;
    var forward = true;
    var pos_counter: usize = 0;
    var check_sum: usize = 0;

    while (fwd_file_ptr < file_sizes.len and fwd_white_ptr < white_spaces.len and fwd_file_ptr < bwd_file_ptr) {
        if (forward) {
            for (0..file_sizes[fwd_file_ptr]) |_| {
                print("fwd: {} {}\n", .{ fwd_file_ptr, pos_counter });
                check_sum += fwd_file_ptr * pos_counter;
                pos_counter += 1;
            }
            forward = false;
            fwd_file_ptr += 1;
        } else {
            for (0..white_spaces[fwd_white_ptr]) |_| {
                if (bwd_file_rest == 0) {
                    bwd_file_ptr -= 1;
                    bwd_file_rest = file_sizes[bwd_file_ptr];
                }
                print("bwd: {} {}\n", .{ bwd_file_ptr, pos_counter });
                bwd_file_rest -= 1;
                check_sum += bwd_file_ptr * pos_counter;
                pos_counter += 1;
            }
            forward = true;
            fwd_white_ptr += 1;
        }
    }

    if (bwd_file_rest > 0) {
        for (0..bwd_file_rest) |_| {
            check_sum += bwd_file_ptr * pos_counter;
            pos_counter += 1;
        }
    }

    print("{}", .{check_sum});
}
