const std = @import("std");
const print = std.debug.print;
const input = @embedFile("input.txt");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var lines_input = std.mem.splitSequence(u8, input, "\n");
    var result: usize = 0;
    var line_index_count :usize= 0;
    while (lines_input.next()) |line| {
        line_index_count+=1;
        if (line_index_count % 50 == 0) {
            print("{}\n", .{line_index_count});
        }
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

        for (0..std.math.pow(usize, 3, values.items.len - 1)) |i| {
            var op_str = try allocator.alloc(u8, 64);
            const pos = std.fmt.formatIntBuf(op_str, i, 3, std.fmt.Case.lower, .{});
            op_str = try allocator.realloc(op_str, pos);
            while (op_str.len < values.items.len - 1) {
                const new_bin_str = try std.fmt.allocPrint(allocator, "0{s}", .{op_str});
                allocator.free(op_str);
                op_str = new_bin_str;
            }
            defer allocator.free(op_str);

            var operator_result: usize = values.items[0];
            for (op_str, 1..(op_str.len + 1)) |operator, value_index| {
                if (operator == '1') {
                    operator_result += values.items[value_index];
                } else if (operator == '2') {
                    const concat_result = try std.fmt.allocPrint(allocator, "{d}{d}", .{operator_result, values.items[value_index]});
                    defer allocator.free(concat_result);
                    operator_result = try std.fmt.parseInt(usize, concat_result, 10);
                }
                else {
                    operator_result = operator_result * values.items[value_index];
                }
                if (operator_result > expected_result) {
                    break;
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
