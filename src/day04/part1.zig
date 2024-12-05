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
    const masks: [8][4]MaskType = .{
        .{.{'X', 1}, .{'M', 1}, .{'A', 1}, .{'S', 1}},
        .{.{'X', line_length}, .{'M', line_length}, .{'A', line_length}, .{'S', line_length}},
        .{.{'X', line_length - 1}, .{'M', line_length - 1}, .{'A', line_length - 1}, .{'S', line_length - 1}},
        .{.{'X', line_length + 1}, .{'M', line_length + 1}, .{'A', line_length + 1}, .{'S', line_length + 1}},
        .{.{'S', 1}, .{'A', 1}, .{'M', 1}, .{'X', 1}},
        .{.{'S', line_length}, .{'A', line_length}, .{'M', line_length}, .{'X', line_length}},
        .{.{'S', line_length - 1}, .{'A', line_length - 1}, .{'M', line_length - 1}, .{'X', line_length - 1}},
        .{.{'S', line_length + 1}, .{'A', line_length + 1}, .{'M', line_length + 1}, .{'X', line_length + 1}},
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
                    or @max(test_index_mod, prev_index_mod) - @min(test_index_mod, prev_index_mod) > 1) { // don't wrap around
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
