const std = @import("std");
const print = std.debug.print;
const input = @embedFile("test_input.txt");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var board = std.AutoHashMap(isize, void).init(allocator);
    defer board.deinit();

    var lines_input = std.mem.splitSequence(u8, input, "\n");
    var y: isize = 0;
    var start: isize = 0;
    while (lines_input.next()) |line| {
        if (line.len > 1) {
            for (line, 0..) |char, x| {
                if (char != '#') {
                    const map_key = to_map_key(@intCast(x), y);
                    try board.put(map_key, {});
                    if (char == 'S') {
                        start = map_key;
                    }
                }
            }
            y += 1;
        }
    }

    print("{} {}\n", .{ board.count(), start });

    var distances = std.AutoHashMap(isize, isize).init(allocator);
    defer distances.deinit();
    try distances.put(start, 0);

    var queue = std.ArrayList(isize).init(allocator);
    defer queue.deinit();
    try queue.append(start);

    const dirs: [4][2]isize = .{ .{ 1, 0 }, .{ 0, 1 }, .{ -1, 0 }, .{ 0, -1 } };
    while (queue.items.len > 0) {
        const pos = queue.orderedRemove(0);
        const pos_xy = from_map_key(pos);
        for (dirs) |dir| {
            const new_pos = to_map_key(pos_xy[0] + dir[0], pos_xy[1] + dir[1]);
            if (board.contains(new_pos) and !distances.contains(new_pos)) {
                try distances.put(new_pos, distances.get(pos).? + 1);
                try queue.append(new_pos);
            }
        }
    }
    var result: usize = 0;
    var distance_it_a = distances.iterator();
    while (distance_it_a.next()) |dist_entry_a| {
        const pos_a = dist_entry_a.key_ptr.*;
        const dist_a = dist_entry_a.value_ptr.*;
        var distance_it_b = distances.iterator();
        while (distance_it_b.next()) |dist_entry_b| {
            const pos_b = dist_entry_b.key_ptr.*;
            const dist_b = dist_entry_b.value_ptr.*;
            const pos_dist = map_key_distance(pos_a, pos_b);
            if (pos_dist == 2 and dist_b - dist_a - pos_dist >= 100) {
                result += 1;
            }
        }
    }
    print("{}\n", .{result});
}

fn to_map_key(x: isize, y: isize) isize {
    return (y << 10) + x;
}

fn from_map_key(key: isize) struct { isize, isize } {
    return .{
        key - ((key >> 10) << 10),
        key >> 10,
    };
}

fn map_key_distance(a: isize, b: isize) isize {
    const a_pos = from_map_key(a);
    const b_pos = from_map_key(b);

    return @as(isize, @intCast(@abs(a_pos[0] - b_pos[0]))) + @as(isize, @intCast(@abs(a_pos[1] - b_pos[1])));
}
