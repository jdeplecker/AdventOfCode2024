const std = @import("std");
const print = std.debug.print;
const input = @embedFile("test_input.txt");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var lines_input = std.mem.splitSequence(u8, input, "\n");
    var result: usize = 0;
    while (lines_input.next()) |line| {
        if (line.len == 0) {
            continue;
        }
        var result_values_split = std.mem.splitSequence(u8, line, ":");
        const expected_result = try std.fmt.parseInt(usize, result_values_split.next().?, 10);
        var values = std.ArrayList(usize).init(allocator);
        defer values.deinit();

        var value_split = std.mem.splitSequence(u8, result_values_split.next().?, " ");
        while (value_split.next()) |value| {
            if (value.len != 0) {
                try values.append(try std.fmt.parseInt(usize, value, 10));
            }
        }

        for (0..std.math.pow(usize, 2, values.items.len - 1)) |i| {
            var bin_str = try std.fmt.allocPrint(allocator, "{b}", .{i});
            while (bin_str.len < values.items.len - 1) {
                const new_bin_str = try std.fmt.allocPrint(allocator, "0{s}", .{bin_str});
                allocator.free(bin_str);
                bin_str = new_bin_str;
            }
            defer allocator.free(bin_str);

            var operator_result: usize = values.items[0];
            for (bin_str, 1..(bin_str.len + 1)) |operator, value_index| {
                if (operator == '1') {
                    operator_result += values.items[value_index];
                } else {
                    operator_result = operator_result * values.items[value_index];
                }
            }
            if (operator_result == expected_result) {
                result += expected_result;
                break;
            }
        }
    }
    print("{}", .{result});
}

fn concat(allocator: std.mem.Allocator, str1: []const u8, str2: []const u8) ![]u8 {
    return std.mem.concat(allocator, u8, &[_][]const u8{ str1, str2 });
}
