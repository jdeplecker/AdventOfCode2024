const std = @import("std");
const print = std.debug.print;
const input = @embedFile("test_input.txt");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var single_line_input: []u8 = "";
    defer allocator.free(single_line_input);
    var line_length:usize = 0;
    var line_splits = std.mem.splitSequence(u8, input, "\n");
    while (line_splits.next()) |line_split| {
        if (line_length == 0) {
            line_length = line_split.len;
        }
        const concat_line = try concat(allocator, single_line_input, line_split);
        allocator.free(single_line_input);
        single_line_input = concat_line;
    }
    const MaskType = struct {u8, usize};
    const masks: [4][5]MaskType = .{
        .{.{'M', 2}, .{'M', line_length - 1}, .{'A', line_length - 1}, .{'S', 2}, .{'S', 0}},
        .{.{'M', 2}, .{'S', line_length - 1}, .{'A', line_length - 1}, .{'M', 2}, .{'S', 0}},
        .{.{'S', 2}, .{'M', line_length - 1}, .{'A', line_length - 1}, .{'S', 2}, .{'M', 0}},
        .{.{'S', 2}, .{'S', line_length - 1}, .{'A', line_length - 1}, .{'M', 2}, .{'M', 0}},
    };

    var matches: u32 = 0;
    for (0..single_line_input.len) | input_letter_idx| {
        for (masks) |mask| {
            var test_index = input_letter_idx;
            var prev_index = input_letter_idx;
            var match = true;
            for (mask) |mask_tuple| {
                const test_index_mod: usize = @mod(test_index, line_length);
                const prev_index_mod: usize = @mod(prev_index, line_length);
                if (test_index >= single_line_input.len
                    or single_line_input[test_index] != mask_tuple[0]
                    or @max(test_index_mod, prev_index_mod) - @min(test_index_mod, prev_index_mod) > 2) { // don't wrap around
                    match = false;
                    break;
                }

                prev_index = test_index;
                test_index += mask_tuple[1];
            }
            if (match) {
                matches += 1;
            }
        }
    }
    print("{}", .{matches});

}

fn concat(allocator: std.mem.Allocator, str1: []const u8, str2: []const u8) ![]u8 {
    return std.mem.concat(allocator, u8, &[_][]const u8{ str1, str2 });
}
