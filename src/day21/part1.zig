const std = @import("std");
const print = std.debug.print;
const input = @embedFile("test_input.txt");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var key_map = try create_key_map(allocator);
    defer key_map.deinit();
    var key_pos: usize = to_map_key(2, 3);

    var arrow_map = try create_arrow_map(allocator);
    defer arrow_map.deinit();
    var arrow_pos = to_map_key(2, 0);
    var arrow2_pos = to_map_key(2, 0);

    var total: usize = 0;
    var lines_input = std.mem.splitSequence(u8, input, "\n");
    while (lines_input.next()) |line| {
        if (line.len > 0) {
            print("{s}\n", .{line});
            var seq_length: usize = 0;
            for (line) |target| {
                const target_key_pos = key_map.get(target).?;
                const target_key_arrows = try to_dirs(allocator, target_key_pos, key_pos);
                for (target_key_arrows) |target_arrow| {
                    const target_arrow_pos = arrow_map.get(target_arrow).?;
                    const target_arrow_dirs = try to_dirs(allocator, target_arrow_pos, arrow_pos);
                    for (target_arrow_dirs) |target2_arrow| {
                        const target2_arrow_pos = arrow_map.get(target2_arrow).?;
                        const target2_arrow_dirs = try to_dirs(allocator, target2_arrow_pos, arrow2_pos);
                        arrow2_pos = target2_arrow_pos;
                        seq_length += target2_arrow_dirs.len;
                    }
                    arrow_pos = target_arrow_pos;
                }
                key_pos = target_key_pos;
            }
            total += (seq_length * try numeric_code(line));
        }
    }

    print("total {}", .{total});
}

fn numeric_code(input_code: []const u8) !usize {
    return try std.fmt.parseInt(usize, input_code[0 .. input_code.len - 1], 10);
}

fn create_key_map(allocator: std.mem.Allocator) !std.AutoHashMap(u8, usize) {
    var key_map = std.AutoHashMap(u8, usize).init(allocator);
    const key_layout: [4][3]u8 = .{ .{ '7', '8', '9' }, .{ '4', '5', '6' }, .{ '1', '2', '3' }, .{ 'B', '0', 'A' } };
    for (key_layout, 0..) |key_row, y| {
        for (key_row, 0..) |key, x| {
            try key_map.put(key, to_map_key(x, y));
        }
    }
    return key_map;
}

fn create_arrow_map(allocator: std.mem.Allocator) !std.AutoHashMap(u8, usize) {
    var arrow_map = std.AutoHashMap(u8, usize).init(allocator);
    const arrow_layout: [2][3]u8 = .{ .{ 'B', '^', 'A' }, .{ '<', 'v', '>' } };
    for (arrow_layout, 0..) |arrow_row, y| {
        for (arrow_row, 0..) |arrow, x| {
            try arrow_map.put(arrow, to_map_key(x, y));
        }
    }
    return arrow_map;
}

fn to_map_key(x: usize, y: usize) usize {
    return (y << 10) + x;
}

fn from_map_key(key: usize) struct { usize, usize } {
    return .{
        key - ((key >> 10) << 10),
        key >> 10,
    };
}

fn map_key_distance(a: usize, b: usize) usize {
    const a_pos = from_map_key(a);
    const b_pos = from_map_key(b);

    return @as(usize, @intCast(@abs(a_pos[0] - b_pos[0]))) + @as(usize, @intCast(@abs(a_pos[1] - b_pos[1])));
}

fn to_dirs(allocator: std.mem.Allocator, a: usize, b: usize) ![]u8 {
    const a_pos = from_map_key(a);
    const b_pos = from_map_key(b);

    var dirs = std.ArrayList(u8).init(allocator);
    defer dirs.deinit();

    const x_diff = @as(isize, @intCast(a_pos[0])) - @as(isize, @intCast(b_pos[0]));
    const y_diff = @as(isize, @intCast(a_pos[1])) - @as(isize, @intCast(b_pos[1]));
    for (0..@abs(x_diff)) |_| {
        if (x_diff < 0) {
            try dirs.append('<');
        } else {
            try dirs.append('>');
        }
    }
    for (0..@abs(y_diff)) |_| {
        if (y_diff < 0) {
            try dirs.append('^');
        } else {
            try dirs.append('v');
        }
    }
    try dirs.append('A');

    return allocator.dupe(u8, dirs.items);
}
