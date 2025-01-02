const std = @import("std");
const graph = @import("graph.zig");
const print = std.debug.print;
const input = @embedFile("test_input.txt");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var network_graph = graph.Graph(i32).init(allocator);
    defer network_graph.deinit();

    var line_input = std.mem.splitSequence(u8, input, "\n");
    while (line_input.next()) |line| {
        if (std.mem.eql(u8, line, "")) {
            break;
        }
        var conn_a_b = std.mem.splitSequence(u8, line, "-");
        const conn_a = conn_a_b.next().?;
        const conn_b = conn_a_b.next().?;

        try network_graph.addEdge(conn_a, 1, conn_b, 1, 1);
        try network_graph.addEdge(conn_b, 1, conn_a, 1, 1);
    }

    var connected_triples = std.StringHashMap(void).init(allocator);
    defer connected_triples.deinit();

    var graph_it = network_graph.graph.?.iterator();
    while (graph_it.next()) |entry| {
        const node_a = entry.key_ptr.*;
        for (entry.value_ptr.items) |edge_b| {
            const node_b = edge_b.node;
            if (std.mem.eql(u8, node_a.name, node_b.name)) continue;
            for (network_graph.graph.?.get(node_b).?.items) |edge_c| {
                const node_c = edge_c.node;
                if (std.mem.eql(u8, node_c.name, node_a.name) or std.mem.eql(u8, node_c.name, node_b.name)) continue;
                if (node_a.name[0] != 't') continue;
                for (network_graph.graph.?.get(node_c).?.items) |c_connected_edge| {
                    if (std.mem.eql(u8, c_connected_edge.node.name, node_a.name)) {
                        var connected_node_arr = [_][]const u8{ node_a.name, node_b.name, node_c.name };
                        std.mem.sort([]const u8, &connected_node_arr, {}, stringLessThan);
                        try connected_triples.put(try std.mem.concat(allocator, u8, &connected_node_arr), {});
                    }
                }
            }
        }
    }

    print("count: {}", .{connected_triples.count()});
}

fn stringLessThan(_: void, lhs: []const u8, rhs: []const u8) bool {
    return std.mem.order(u8, lhs, rhs) == .lt;
}
