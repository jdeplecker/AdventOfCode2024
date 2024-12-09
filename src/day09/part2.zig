const std = @import("std");
const print = std.debug.print;
const input = @embedFile("test_input.txt");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const file_sizes = try allocator.alloc(usize, input.len / 2 + 1);
    defer allocator.free(file_sizes);
    const already_moved = try allocator.alloc(bool, input.len / 2 + 1);
    defer allocator.free(already_moved);
    const white_spaces = try allocator.alloc(usize, input.len / 2);
    defer allocator.free(white_spaces);

    for (0..input.len) |i| {
        if (i % 2 == 0) {
            file_sizes[i / 2] = @as(usize, @intCast(input[i])) - 48;
            already_moved[i / 2] = false;
        } else {
            white_spaces[i / 2] = @as(usize, @intCast(input[i])) - 48;
        }
    }

    var fwd_file_ptr: usize = 0;
    var fwd_white_ptr: usize = 0;
    var forward = true;
    var pos_counter: usize = 0;
    var check_sum: usize = 0;

    while (fwd_file_ptr < file_sizes.len and fwd_white_ptr < white_spaces.len) {
        if (forward) {
            if (!already_moved[fwd_file_ptr]) {
                for (0..file_sizes[fwd_file_ptr]) |_| {
                    check_sum += fwd_file_ptr * pos_counter;
                    pos_counter += 1;
                }
            } else {
                pos_counter += file_sizes[fwd_file_ptr];
            }
            forward = false;
            already_moved[fwd_file_ptr] = true;
            fwd_file_ptr += 1;
        } else {
            var white_left = white_spaces[fwd_white_ptr];
            var i = file_sizes.len;
            while (i > 0) : (i -= 1) {
                const bwd_file_ptr = i - 1;
                if (file_sizes[bwd_file_ptr] <= white_left and !already_moved[bwd_file_ptr]) {
                    for (0..file_sizes[bwd_file_ptr]) |_| {
                        check_sum += (bwd_file_ptr) * pos_counter;
                        pos_counter += 1;
                    }
                    already_moved[bwd_file_ptr] = true;
                    white_left -= file_sizes[bwd_file_ptr];
                }
            }
            pos_counter += white_left;
            forward = true;
            fwd_white_ptr += 1;
        }
    }

    print("{}", .{check_sum});
}
