const std = @import("std");
const print = std.debug.print;
const input = @embedFile("input.txt");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const grid_size: isize = 71;
    const steps = 1024;
    var corrupted_memory = std.AutoHashMap(isize, void).init(allocator);
    defer corrupted_memory.deinit();

    var lines = std.mem.splitScalar(u8, input, '\n');
    for (0..steps) |_| {
        try corrupted_memory.put(try to_map_key_input(lines.next().?), {});
    }

    const dirs: [4][2]isize = .{ .{ 1, 0 }, .{ 0, 1 }, .{ -1, 0 }, .{ 0, -1 } };
    const start_pos: [2]isize = .{ 0, 0 };
    const end_key = to_map_key(grid_size - 1, grid_size - 1);
    var visited = std.AutoHashMap(isize, isize).init(allocator);
    defer visited.deinit();
    try visited.put(to_map_key_pos(start_pos), 0);
    var queue = std.ArrayList(isize).init(allocator);
    defer queue.deinit();
    try queue.append(to_map_key_pos(start_pos));

    while (!visited.contains(end_key)) {
        const current_map_key = queue.orderedRemove(0);
        const current_pos = from_map_key(current_map_key);
        const current_steps = visited.get(current_map_key).?;

        for (dirs) |dir| {
            const new_x = current_pos[0] + dir[0];
            const new_y = current_pos[1] + dir[1];
            const new_map_key = to_map_key(new_x, new_y);
            if (between(new_x, 0, grid_size - 1) and between(new_y, 0, grid_size - 1) and !visited.contains(new_map_key) and !corrupted_memory.contains(new_map_key)) {
                try queue.append(new_map_key);
                try visited.put(new_map_key, current_steps + 1);
            }
        }
    }

    print("{}\n", .{visited.get(end_key).?});
}

fn between(num: isize, min: isize, max: isize) bool {
    return num >= min and num <= max;
}

fn to_map_key_input(line: []const u8) !isize {
    var split = std.mem.splitScalar(u8, line, ',');
    const x = try std.fmt.parseInt(isize, split.next().?, 10);
    const y = try std.fmt.parseInt(isize, split.next().?, 10);
    return to_map_key(x, y);
}

fn to_map_key_pos(pos: [2]isize) isize {
    return (pos[1] << 10) + pos[0];
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
