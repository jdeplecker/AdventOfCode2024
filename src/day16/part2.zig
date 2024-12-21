const std = @import("std");
const graph = @import("graph.zig");
const print = std.debug.print;
const input = @embedFile("input.txt");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var maze = graph.Graph(i32).init(allocator);
    defer maze.deinit();

    var start: []u8 = "";
    var end: []u8 = "";

    var line_input = std.mem.splitSequence(u8, input, "\n");
    var y: usize = 0;
    while (line_input.next()) |line| {
        if (std.mem.eql(u8, line, "")) {
            break;
        }
        for (line, 0..) |char, x| {
            const name = node_name(allocator, x, y);
            if (char == 'S') {
                start = name;
            }
            if (char == 'E') {
                end = name;
            }
            if (char != '#') {
                try maze.addVertex(name, 1);
                if (line[x - 1] != '#') {
                    const left_name = node_name(allocator, x - 1, y);
                    try maze.addEdge(left_name, 1, name, 1, 1);
                    try maze.addEdge(name, 1, left_name, 1, 1);
                }
                const top_name = node_name(allocator, x, y - 1);
                if (maze.vertices.?.get(top_name)) |_| {
                    try maze.addEdge(top_name, 1, name, 1, 1);
                    try maze.addEdge(name, 1, top_name, 1, 1);
                }
            }
        }
        y += 1;
    }
    var result_path = try find_seats(&maze, start, end);
    defer result_path.deinit();

    print("Result: {}\n", .{result_path.items.len});
}

fn node_name(allocator: std.mem.Allocator, x: usize, y: usize) []u8 {
    return std.fmt.allocPrint(allocator, "{}-{}", .{ x, y }) catch "";
}

fn node_xy(name: []const u8) struct { usize, usize } {
    var name_split = std.mem.splitScalar(u8, name, '-');
    return .{ std.fmt.parseInt(usize, name_split.next().?, 10) catch 0, std.fmt.parseInt(usize, name_split.next().?, 10) catch 0 };
}

fn concat(allocator: std.mem.Allocator, str1: []const u8, str2: []const u8) ![]u8 {
    return std.mem.concat(allocator, u8, &[_][]const u8{ str1, str2 });
}

const Dir = enum {
    up,
    right,
    down,
    left,
    pub fn from_coords(x1: usize, x2: usize, y1: usize, y2: usize) Dir {
        if (x1 == x2) {
            if (y1 < y2) {
                return Dir.up;
            }
            return Dir.down;
        }
        if (x1 < x2) {
            return Dir.left;
        }
        return Dir.right;
    }
    pub fn from(name1: []const u8, name2: []const u8) Dir {
        const x1y1 = node_xy(name1);
        const x2y2 = node_xy(name2);
        return from_coords(x1y1[0], x2y2[0], x1y1[1], x2y2[1]);
    }
    pub fn name(self: Dir) []u8 {
        return switch (self) {
            .up => @constCast("up"),
            .right => @constCast("right"),
            .down => @constCast("down"),
            .left => @constCast("left"),
        };
    }
};

fn find_seats(g: *graph.Graph(i32), src: []const u8, dst: []const u8) !std.ArrayList(graph.Graph(i32).Element) {
    var result = std.StringHashMap(i32).init(g.allocator);
    var path = std.ArrayList(graph.Graph(i32).Element).init(g.allocator);

    if ((g.vertices.?.contains(src) == false) or (g.vertices.?.contains(dst) == false)) {
        return path;
    }

    const source: *graph.Graph(i32).Node = g.vertices.?.get(src).?;

    var pq = std.PriorityQueue(graph.Graph(i32).Element, void, graph.Graph(i32).minCompare).init(g.allocator, {});
    defer pq.deinit();

    var visited = std.StringHashMap(i32).init(g.allocator);
    defer visited.deinit();

    var distances = std.StringHashMap(i32).init(g.allocator);
    defer distances.deinit();

    var prev = std.StringHashMap(*graph.Graph(i32).Node).init(g.allocator);
    defer prev.deinit();

    var prev_dir = std.StringHashMap(Dir).init(g.allocator);
    defer prev_dir.deinit();

    // Initially, push all the nodes into the distances hashmap with a distance of infinity.

    var node_it = g.vertices.?.keyIterator();
    while (node_it.next()) |node| {
        if (!std.mem.eql(u8, source.name, node.*)) {
            _ = try distances.put(node.*, 999999999);
            try pq.add(graph.Graph(i32).Element{ .name = node.*, .distance = 999999999 });
        }
    }

    _ = try distances.put(src, 0);
    _ = try prev_dir.put(src, Dir.right);
    try pq.add(graph.Graph(i32).Element{ .name = source.name, .distance = 0 });

    while (pq.count() > 0) {
        const current: graph.Graph(i32).Element = pq.remove();

        if (std.mem.eql(u8, current.name, dst)) {
            break;
        }

        if (!visited.contains(try concat(g.allocator, current.name, prev_dir.get(current.name).?.name()))) {
            const currentPtr: *graph.Graph(i32).Node = g.vertices.?.get(current.name).?;
            const neighbors: std.ArrayList(*graph.Graph(i32).Edge) = g.graph.?.get(currentPtr).?;

            for (neighbors.items) |n| {
                // Update the distance values from all neighbors, to the current node
                // and obtain the shortest distance to the current node from all of its neighbors.
                const best_dist = distances.get(n.node.name).?;
                const n_dir = Dir.from(current.name, n.node.name);
                var n_dist = @as(i32, @intCast(current.distance)) + @as(i32, @intCast(n.weight));
                if (prev_dir.get(current.name).? != n_dir) {
                    n_dist += 1000;
                }

                // warn("\r\n n1 {} nbhr {} ndist {} best {}", .{current.node, n.node.name, n_dist, best_dist});
                if (n_dist < best_dist) {
                    // Shortest way to reach current node is through this neighbor.
                    // Update the node's distance from source, and add it to prev.
                    _ = try distances.put(n.node.name, n_dist);

                    _ = try prev.put(n.node.name, currentPtr);
                    _ = try prev_dir.put(n.node.name, n_dir);

                    // Update the priority queue with the new, shorter distance.
                    var modIndex: usize = 0;
                    for (pq.items, 0..) |item, i| {
                        if (std.mem.eql(u8, item.name, n.node.name)) {
                            modIndex = i;
                            break;
                        }
                    }
                    _ = pq.removeIndex(modIndex);
                    try pq.add(graph.Graph(i32).Element{ .name = n.node.name, .distance = n_dist });
                }
            }

            // After updating all the distances to all neighbors, get the
            // best leading edge from the closest neighbor to this node. Mark that
            // distance as the best distance to this node, and add it to the results.
            const best = distances.get(current.name).?;
            _ = try result.put(current.name, best);
            _ = try visited.put(try concat(g.allocator, current.name, prev_dir.get(current.name).?.name()), 1);
        }
    }

    // Path tracing, to return a list of nodes from src to dst.
    var x: []const u8 = dst;
    while (prev.contains(x)) {
        const temp: *graph.Graph(i32).Node = prev.get(x).?;
        try path.append(graph.Graph(i32).Element{ .name = temp.name, .distance = result.get(temp.name).? });
        x = temp.name;
    }

    std.mem.reverse(graph.Graph(i32).Element, path.items);
    return path;
}
