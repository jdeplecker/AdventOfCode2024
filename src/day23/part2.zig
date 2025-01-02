const std = @import("std");
const graph = @import("graph.zig");
const print = std.debug.print;
const input = @embedFile("input.txt");

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

    var networks = std.ArrayList(*std.StringHashMap(void)).init(allocator);
    defer {
        for (networks.items) |network| {
            network.deinit();
        }
        networks.deinit();
    }

    var graph_key_it = network_graph.graph.?.keyIterator();
    while (graph_key_it.next()) |node| {
        var network = std.StringHashMap(void).init(allocator);
        try network.put(node.*.name, {});
        try networks.append(&network);
    }

    for (networks.items) |network| {
        var graph_it = network_graph.graph.?.iterator();
        while (graph_it.next()) |entry| {
            const node_b = entry.key_ptr.*;
            if (contains_all(network, entry.value_ptr.items)) {
                try network.put(node_b.name, {});
            }
        }
    }

    var biggest: u32 = 0;
    var biggest_network: ?*std.StringHashMap(void) = undefined;
    for (networks.items) |network| {
        if (network.count() > biggest) {
            biggest = network.count();
            biggest_network = network;
        }
    }
    print("count: {}\n", .{biggest});
    var biggest_network_it = biggest_network.?.keyIterator();
    var biggest_nodes_array = try allocator.alloc([]const u8, biggest_network_it.len);
    var i: u32 = 0;
    while (biggest_network_it.next()) |node| : (i += 1) {
        print("{s}\n", .{node.*});
        biggest_nodes_array[i] = node.*;
    }
    std.mem.sort([]const u8, biggest_nodes_array, {}, string_less_than);
    print("{s}\n", .{biggest_nodes_array});
}

fn string_less_than(_: void, lhs: []const u8, rhs: []const u8) bool {
    return std.mem.order(u8, lhs, rhs) == .lt;
}

fn contains_all(haystack: *std.StringHashMap(void), needles: []*graph.Graph(i32).Edge) bool {
    var haystack_it = haystack.keyIterator();

    outer: while (haystack_it.next()) |item| {
        for (needles) |needle| {
            if (std.mem.eql(u8, needle.node.name, item.*)) continue :outer;
        }
        return false;
    }

    return true;
}
