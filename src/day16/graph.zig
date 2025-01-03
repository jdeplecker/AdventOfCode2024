// Adapted from https://github.com/neobsv/zigraph/tree/master
const std = @import("std");
const mem = std.mem;
const warn = std.debug.print;
const gallocator = std.heap.page_allocator;

pub fn Graph(comptime T: type) type {
    return struct {
        N: usize,
        connected: usize,
        root: ?*Node,
        vertices: ?std.StringHashMap(*Node),
        graph: ?std.AutoHashMap(*Node, std.ArrayList(*Edge)),
        allocator: mem.Allocator,

        const Self = @This();

        pub const Node = struct {
            name: []const u8,
            data: T,

            pub fn init(n: []const u8, d: T) Node {
                return Node{ .name = n, .data = d };
            }
        };

        pub const Edge = struct {
            node: *Node,
            weight: u32,

            pub fn init(n1: *Node, w: u32) Edge {
                return Edge{ .node = n1, .weight = w };
            }
        };

        pub fn init(alloc: std.mem.Allocator) Self {
            return Self{ .N = 0, .connected = 0, .root = undefined, .vertices = undefined, .graph = undefined, .allocator = alloc };
        }

        pub fn deinit(self: *Self) void {
            self.graph.?.deinit();

            var vert_it = self.vertices.?.iterator();
            while (vert_it.next()) |entry| {
                self.allocator.destroy(entry.value_ptr.*);
            }
            self.vertices.?.deinit();

            self.N = 0;
        }

        pub fn addVertex(self: *Self, n: []const u8, d: T) !void {
            if (self.N == 0) {
                const rt = try self.allocator.create(Node);
                errdefer self.allocator.destroy(rt);
                rt.* = Node.init(n, d);

                self.root = rt;
                self.vertices = std.StringHashMap(*Node).init(self.allocator);
                _ = try self.vertices.?.put(rt.name, rt);

                self.graph = std.AutoHashMap(*Node, std.ArrayList(*Edge)).init(self.allocator);
                _ = try self.graph.?.put(rt, std.ArrayList(*Edge).init(self.allocator));

                self.N += 1;
                return;
            }

            if (self.vertices.?.contains(n) == false) {
                const node = try self.allocator.create(Node);
                errdefer self.allocator.destroy(node);
                node.* = Node.init(n, d);

                _ = try self.vertices.?.put(node.name, node);
                _ = try self.graph.?.put(node, std.ArrayList(*Edge).init(self.allocator));
            }

            self.N += 1;
        }

        pub fn addEdge(self: *Self, n1: []const u8, d1: T, n2: []const u8, d2: T, w: u32) !void {
            if (self.N == 0 or self.vertices.?.contains(n1) == false) {
                try self.addVertex(n1, d1);
            }

            if (self.vertices.?.contains(n2) == false) {
                try self.addVertex(n2, d2);
            }

            const node1: *Node = self.vertices.?.get(n1).?;
            const node2: *Node = self.vertices.?.get(n2).?;

            var arr: std.ArrayList(*Edge) = self.graph.?.get(node1).?;

            const edge = try self.allocator.create(Edge);
            errdefer self.allocator.destroy(edge);
            edge.* = Edge.init(node2, w);

            try arr.append(edge);

            _ = try self.graph.?.put(node1, arr);
        }

        pub fn print(self: *Self) void {
            warn("\r\n", .{});
            warn("Size: {}\r\n", .{self.N});
            warn("\r\n", .{});
            warn("Root: {?}\r\n", .{self.root});
            warn("\r\n", .{});
            warn("Vertices:\r\n", .{});
            var vert_key_it = self.vertices.?.keyIterator();
            while (vert_key_it.next()) |entry| {
                warn("\r\n{s}\r\n", .{entry.*});
            }
            warn("\r\n", .{});
            warn("Graph:\r\n", .{});
            var graph_it = self.graph.?.iterator();
            while (graph_it.next()) |entry| {
                warn("\r\nConnections: {}  =>", .{entry.key_ptr.*});
                for (entry.value_ptr.*.items) |v| {
                    warn("  {}  =>", .{v.*});
                }
                warn("|| \r\n", .{});
            }
            warn("\r\n", .{});
        }

        fn topoDriver(self: *Self, node: []const u8, visited: *std.StringHashMap(i32), stack: *std.ArrayList(*Node)) !bool {
            // In the process of visiting this vertex, we reach the same vertex again.
            // Return to stop the process. (#cond1)
            if (visited.get(node).? == 1) {
                return false;
            }

            // Finished visiting this vertex, it is now marked 2. (#cond2)
            if (visited.get(node).? == 2) {
                return true;
            }

            // Color the node 1, indicating that it is being processed, and initiate a loop
            // to visit all its neighbors. If we reach the same vertex again, return (#cond1)
            _ = try visited.put(node, 1);

            const nodePtr: *Node = self.vertices.?.get(node).?;
            const neighbors: std.ArrayList(*Edge) = self.graph.?.get(nodePtr).?;
            for (neighbors.items) |n| {
                // warn("\r\n nbhr: {} ", .{n});
                if (visited.get(n.node.name).? == 0) {
                    const check: bool = self.topoDriver(n.node.name, visited, stack) catch unreachable;
                    if (check == false) {
                        return false;
                    }
                }
            }

            // Finish processing the current node and mark it 2.
            _ = try visited.put(node, 2);

            // Add node to stack of visited nodes.
            try stack.append(nodePtr);
            // warn("\r\n reach {} ", .{nodePtr});

            return true;
        }

        pub fn topoSort(self: *Self) !std.ArrayList(*Node) {
            var visited = std.StringHashMap(i32).init(self.allocator);
            defer visited.deinit();

            var stack = std.ArrayList(*Node).init(self.allocator);
            defer stack.deinit();

            var result = std.ArrayList(*Node).init(self.allocator);

            // Initially, color all the nodes 0, to mark them unvisited.
            var node_it = self.vertices.?.keyIterator();
            while (node_it.next()) |node| {
                _ = try visited.put(node.*, 0);
            }

            node_it = self.vertices.?.keyIterator();
            while (node_it.next()) |node| {
                if (visited.get(node.*).? == 0) {
                    const check: bool = self.topoDriver(node.*, &visited, &stack) catch unreachable;
                    if (check == false) {
                        for (stack.items) |n| {
                            try result.append(n);
                        }
                        return result;
                    }
                    self.connected += 1;
                }
            }

            self.connected -= 1;

            for (stack.items) |n| {
                try result.append(n);
            }
            return result;
        }

        pub fn dfs(self: *Self) !std.ArrayList(*Node) {
            var visited = std.StringHashMap(i32).init(self.allocator);
            defer visited.deinit();

            var result = std.ArrayList(*Node).init(self.allocator);

            // Initially, color all the nodes 0, to mark them unvisited.
            var node_it = self.vertices.?.keyIterator();
            while (node_it.next()) |node| {
                _ = try visited.put(node.*, 0);
            }

            var stack = std.ArrayList(*Node).init(self.allocator);
            defer stack.deinit();

            try stack.append(self.root.?);

            while (stack.items.len > 0) {
                const current: *Node = stack.pop();

                const neighbors: std.ArrayList(*Edge) = self.graph.?.get(current).?;
                for (neighbors.items) |n| {
                    // warn("\r\n nbhr: {} ", .{n});
                    if (visited.get(n.node.name).? == 0) {
                        try stack.append(n.node);
                        _ = try visited.put(n.node.name, 1);
                        try result.append(n.node);
                    }
                }
            }

            return result;
        }

        pub fn bfs(self: *Self) !std.ArrayList(*Node) {
            var visited = std.StringHashMap(i32).init(self.allocator);
            defer visited.deinit();

            var result = std.ArrayList(*Node).init(self.allocator);

            // Initially, color all the nodes 0, to mark them unvisited.
            var node_it = self.vertices.?.keyIterator();
            while (node_it.next()) |node| {
                _ = try visited.put(node.*, 0);
            }

            var qu = std.ArrayList(*Node).init(self.allocator);
            defer qu.deinit();

            try qu.append(self.root.?);

            while (qu.items.len > 0) {
                const current: *Node = qu.orderedRemove(0);

                const neighbors: std.ArrayList(*Edge) = self.graph.?.get(current).?;
                for (neighbors.items) |n| {
                    // warn("\r\n nbhr: {} ", .{n});
                    if (visited.get(n.node.name).? == 0) {
                        try qu.append(n.node);
                        _ = try visited.put(n.node.name, 1);
                        try result.append(n.node);
                    }
                }
            }

            return result;
        }

        pub const Element = struct { name: []const u8, distance: i32 };
        pub fn minCompare(_: void, a: Element, b: Element) std.math.Order {
            return std.math.order(a.distance, b.distance);
        }

        pub fn dijikstra(self: *Self, src: []const u8, dst: []const u8) !std.ArrayList(Element) {
            var result = std.StringHashMap(i32).init(self.allocator);
            var path = std.ArrayList(Element).init(self.allocator);

            if ((self.vertices.?.contains(src) == false) or (self.vertices.?.contains(dst) == false)) {
                return path;
            }

            const source: *Node = self.vertices.?.get(src).?;

            var pq = std.PriorityQueue(Element, void, minCompare).init(self.allocator, {});
            defer pq.deinit();

            var visited = std.StringHashMap(i32).init(self.allocator);
            defer visited.deinit();

            var distances = std.StringHashMap(i32).init(self.allocator);
            defer distances.deinit();

            var prev = std.StringHashMap(*Node).init(self.allocator);
            defer prev.deinit();

            // Initially, push all the nodes into the distances hashmap with a distance of infinity.

            var node_it = self.vertices.?.keyIterator();
            while (node_it.next()) |node| {
                if (!mem.eql(u8, source.name, node.*)) {
                    _ = try distances.put(node.*, 9999);
                    try pq.add(Element{ .name = node.*, .distance = 9999 });
                }
            }

            _ = try distances.put(src, 0);
            try pq.add(Element{ .name = source.name, .distance = 0 });

            while (pq.count() > 0) {
                const current: Element = pq.remove();

                if (mem.eql(u8, current.name, dst)) {
                    break;
                }

                if (!visited.contains(current.name)) {
                    const currentPtr: *Node = self.vertices.?.get(current.name).?;
                    const neighbors: std.ArrayList(*Edge) = self.graph.?.get(currentPtr).?;

                    for (neighbors.items) |n| {
                        // Update the distance values from all neighbors, to the current node
                        // and obtain the shortest distance to the current node from all of its neighbors.
                        const best_dist = distances.get(n.node.name).?;
                        const n_dist = @as(i32, @intCast(current.distance)) + @as(i32, @intCast(n.weight));

                        // warn("\r\n n1 {} nbhr {} ndist {} best {}", .{current.node, n.node.name, n_dist, best_dist});
                        if (n_dist < best_dist) {
                            // Shortest way to reach current node is through this neighbor.
                            // Update the node's distance from source, and add it to prev.
                            _ = try distances.put(n.node.name, n_dist);

                            _ = try prev.put(n.node.name, currentPtr);

                            // Update the priority queue with the new, shorter distance.
                            var modIndex: usize = 0;
                            for (pq.items, 0..) |item, i| {
                                if (mem.eql(u8, item.name, n.node.name)) {
                                    modIndex = i;
                                    break;
                                }
                            }
                            _ = pq.removeIndex(modIndex);
                            try pq.add(Element{ .name = n.node.name, .distance = n_dist });
                        }
                    }

                    // After updating all the distances to all neighbors, get the
                    // best leading edge from the closest neighbor to this node. Mark that
                    // distance as the best distance to this node, and add it to the results.
                    const best = distances.get(current.name).?;
                    _ = try result.put(current.name, best);
                    _ = try visited.put(current.name, 1);
                }
            }

            // Path tracing, to return a list of nodes from src to dst.
            var x: []const u8 = dst;
            try path.append(Element{ .name = dst, .distance = result.get(dst) orelse 0 });
            while (prev.contains(x)) {
                const temp: *Node = prev.get(x).?;
                try path.append(Element{ .name = temp.name, .distance = result.get(temp.name).? });
                x = temp.name;
            }

            std.mem.reverse(Graph(i32).Element, path.items);
            return path;
        }

        pub const Pair = struct { n1: []const u8, n2: []const u8 };

        pub fn prim(self: *Self, src: []const u8) !std.ArrayList(std.ArrayList(*Node)) {
            // Start with a vertex, and pick the minimum weight edge that belongs to that
            // vertex. Traverse the edge and then repeat the same procedure, till an entire
            // spannning tree is formed.
            var path = std.ArrayList(std.ArrayList(*Node)).init(self.allocator);

            if (self.vertices.?.contains(src) == false) {
                return path;
            }

            const source: *Node = self.vertices.?.get(src).?;
            var dest = std.ArrayList(Pair).init(self.allocator);
            defer dest.deinit();

            var pq = std.PriorityQueue(Element, void, minCompare).init(self.allocator, {});
            defer pq.deinit();

            var visited = std.StringHashMap(bool).init(self.allocator);
            defer visited.deinit();

            var distances = std.StringHashMap(i32).init(self.allocator);
            defer distances.deinit();

            var prev = std.StringHashMap(?std.ArrayList(*Node)).init(self.allocator);
            defer prev.deinit();

            // Initially, push all the nodes into the distances hashmap with a distance of infinity.
            var node_it = self.vertices.?.keyIterator();
            while (node_it.next()) |node| {
                if (!mem.eql(u8, source.name, node.*)) {
                    _ = try distances.put(node.*, 9999);
                    try pq.add(Element{ .name = node.*, .distance = 9999 });
                }
            }

            _ = try distances.put(src, 0);
            try pq.add(Element{ .name = source.name, .distance = 0 });

            while (pq.count() > 0) {
                const current: Element = pq.remove();

                if (!visited.contains(current.name)) {
                    const currentPtr: *Node = self.vertices.?.get(current.name).?;
                    const neighbors: std.ArrayList(*Edge) = self.graph.?.get(currentPtr).?;

                    for (neighbors.items) |n| {
                        // If the PQ contains this vertex (meaning, it hasn't been considered yet), then the
                        // then check if the edge between the current and this neighbor is the min. spanning edge
                        // from current. Choose the edge, mark the distance map and fill the prev vector.

                        // Contains:
                        var pqcontains: bool = false;
                        for (pq.items) |item| {
                            if (mem.eql(u8, item.name, n.node.name)) {
                                pqcontains = true;
                                break;
                            }
                        }
                        // Distance of current vertex with its neighbors (best_so_far)
                        const best_dist = distances.get(n.node.name).?;
                        // Distance between current vertex and this neighbor n
                        const n_dist = @as(i32, @intCast(n.weight));

                        // warn("\r\n current {} nbhr {} ndist {} best {}", .{current.node, n.node.name, n_dist, best_dist});

                        if (pqcontains == true and n_dist < best_dist) {
                            // We have found the edge that needs to be added to our MST, add it to path,
                            // set distance and prev. and update the priority queue with the new weight. (n_dist)
                            _ = try distances.put(n.node.name, n_dist);

                            var prevArr: ?std.ArrayList(*Node) = undefined;
                            if (prev.contains(n.node.name) == true) {
                                prevArr = prev.get(n.node.name).?;
                            } else {
                                prevArr = std.ArrayList(*Node).init(self.allocator);
                            }

                            try prevArr.?.append(currentPtr);
                            // for (prevArr.?.items) |y| {
                            //     warn("\r\n prev: {}", .{y});
                            // }
                            // warn("\r\n next\r\n", .{});
                            _ = try prev.put(n.node.name, prevArr);

                            // Update the priority queue with the new edge weight.
                            var modIndex: usize = 0;
                            for (pq.items, 0..) |item, i| {
                                if (mem.eql(u8, item.name, n.node.name)) {
                                    modIndex = i;
                                    break;
                                }
                            }
                            _ = pq.removeIndex(modIndex);
                            try pq.add(Element{ .name = n.node.name, .distance = n_dist });
                        }

                        // Identify leaf nodes for path tracing

                        // pull out the neighbors list for the current neighbor, and check length.
                        const cPtr: *Node = self.vertices.?.get(n.node.name).?;
                        const nbhr: std.ArrayList(*Edge) = self.graph.?.get(cPtr).?;

                        if (nbhr.items.len == 0) {
                            // warn("\r\n last node: {} {}", .{current.name, n.node.name});
                            try dest.append(Pair{ .n1 = current.name, .n2 = n.node.name });
                        }
                    }
                }

                _ = try visited.put(current.name, true);
            }

            // Path tracing, to return the MST as an arraylist of arraylist.
            for (dest.items) |item| {
                const spacer = try self.allocator.create(Node);
                errdefer self.allocator.destroy(spacer);
                spacer.* = Node.init("spacer", 1);

                var t0 = std.ArrayList(*Node).init(self.allocator);
                try t0.append(spacer);
                try path.append(t0);

                var t1 = std.ArrayList(*Node).init(self.allocator);
                try t1.append(self.vertices.?.get(item.n2).?);
                try path.append(t1);

                var dst = item.n1;
                var t2 = std.ArrayList(*Node).init(self.allocator);
                try t2.append(self.vertices.?.get(dst).?);
                try path.append(t2);

                while (prev.contains(dst)) {
                    const temp: ?std.ArrayList(*Node) = prev.get(dst).?;
                    // for (temp.?.items) |k| {
                    //     warn("\r\n path: {}", .{k});
                    // }
                    try path.append(temp.?);
                    dst = temp.?.items[0].name;
                }
            }

            return path;
        }

        fn arrayContains(arr: std.ArrayList(*Node), node: *Node) bool {
            for (arr.items) |item| {
                if (mem.eql(u8, item.name, node.name)) {
                    return true;
                }
            }
            return false;
        }

        fn min(a: i32, b: i32) i32 {
            if (a < b) {
                return a;
            }
            return b;
        }

        fn tarjanDriver(self: *Self, current: *Node, globalIndexCounter: *i32, index: *std.StringHashMap(i32), low: *std.StringHashMap(i32), stack: *std.ArrayList(*Node), result: *std.ArrayList(std.ArrayList(*Node))) !void {
            // Set the indices for the current recursion, increment the global index, mark the index
            // for the node, mark low, and append the node to the recursion stack.
            _ = try index.put(current.name, globalIndexCounter.*);
            _ = try low.put(current.name, globalIndexCounter.*);
            try stack.append(current);
            globalIndexCounter.* += 1;

            // Get the neighbors of the current node.
            const neighbors: std.ArrayList(*Edge) = self.graph.?.get(current).?;

            // warn("\r\n begin iteration for node: {}\r\n", .{current});
            for (neighbors.items) |n| {
                if (index.contains(n.node.name) == false) {
                    self.tarjanDriver(n.node, globalIndexCounter, index, low, stack, result) catch unreachable;

                    // Update the low index after the recursion, set low index to the min of
                    // prev and current recursive calls.
                    const currLow: i32 = low.get(current.name).?;
                    const nLow: i32 = low.get(n.node.name).?;

                    _ = try low.put(current.name, min(currLow, nLow));
                } else if (arrayContains(stack.*, current)) {

                    // Update the low index after the recursion, set low index to the min of
                    // prev and current recursive calls.
                    const currLow: i32 = low.get(current.name).?;
                    // IMP: notice that 'index' is being used here, not low.
                    const nIndex: i32 = index.get(n.node.name).?;

                    _ = try low.put(current.name, min(currLow, nIndex));
                }
            }

            // for(low.entries) |entry|{
            //     if (entry.used) {
            //         warn("\r\n  low entry:   {}", .{entry});
            //     }
            // }
            // warn("\r\n end iteration for node: {}", .{current});

            const currentLow: i32 = low.get(current.name).?;
            const currentIndex: i32 = index.get(current.name).?;

            // warn("\r\n current {} index {} low {}", .{current, currentIndex, currentLow});

            if (currentLow == currentIndex) {
                var scc = std.ArrayList(*Node).init(self.allocator);

                while (true) {

                    // for (stack.items) |k| {
                    //     warn("\r\n   stack: {}", .{k});
                    // }

                    const successor: *Node = stack.pop();
                    try scc.append(successor);
                    if (mem.eql(u8, successor.name, current.name)) {
                        try result.append(scc);
                        break;
                    }
                }
            }
        }

        pub fn tarjan(self: *Self) !std.ArrayList(std.ArrayList(*Node)) {
            // Tarjan uses dfs in order to traverse a graph, and return all the strongly connected components in it.
            // The algorithm uses two markers called index and low. Index marks the order in which the node has been visited. The
            // count of nodes from the start vertex. The other marker, low, marks the lowest index value
            // seen by the algorithm so far. Once the recursion unwraps, the key of this algorithm
            // is to compare the current stack 'low' (c1) with the previous stack 'low' (c0)
            // while it collapses the stacks. If c1 < c0, then the low for the previous node is updated
            // to low[prev] = c1, if c1 > c0 then we have found a min-cut edge for the graph. These edges
            // separate the strongly connected components from each other.
            var result = std.ArrayList(std.ArrayList(*Node)).init(self.allocator);

            var globalIndexCounter: i32 = 0;

            var stack = std.ArrayList(*Node).init(self.allocator);
            defer stack.deinit();

            var index = std.StringHashMap(i32).init(self.allocator);
            defer index.deinit();

            var low = std.StringHashMap(i32).init(self.allocator);
            defer low.deinit();

            var node_it = self.vertices.?.valueIterator();
            while (node_it.next()) |node| {
                if (index.contains(node.*.name) == false) {
                    self.tarjanDriver(node.*, &globalIndexCounter, &index, &low, &stack, &result) catch unreachable;
                }
            }

            return result;
        }
    };
}

test "basic graph insertion and printing" {
    var graph = Graph(i32).init(gallocator);
    defer graph.deinit();

    try graph.addEdge("A", 10, "B", 20, 1);
    try graph.addEdge("B", 20, "C", 40, 2);
    try graph.addEdge("C", 110, "A", 10, 3);
    try graph.addEdge("A", 10, "A", 10, 0);
    try graph.addEdge("J", 1, "K", 1, 1);
    graph.print();
    warn("\r\n", .{});
    warn("\r\n", .{});
}

test "basic graph toposort" {
    var graph = Graph(i32).init(gallocator);
    defer graph.deinit();

    try graph.addEdge("A", 10, "B", 20, 1);
    try graph.addEdge("B", 20, "C", 40, 2);
    try graph.addEdge("C", 110, "A", 10, 3);
    try graph.addEdge("A", 10, "A", 10, 0);
    try graph.addEdge("J", 1, "K", 1, 1);
    graph.print();

    warn("\r\nTopoSort: ", .{});
    var res = try graph.topoSort();
    defer res.deinit();

    for (res.items) |n| {
        warn("\r\n stack: {} ", .{n});
    }
    warn("\r\n", .{});

    warn("\r\nConnected components: {}", .{graph.connected});
    warn("\r\n", .{});
    warn("\r\n", .{});
}

test "basic graph bfs" {
    var graph = Graph(i32).init(gallocator);
    defer graph.deinit();

    try graph.addEdge("A", 10, "B", 20, 1);
    try graph.addEdge("B", 20, "C", 40, 2);
    try graph.addEdge("C", 110, "A", 10, 3);
    try graph.addEdge("A", 10, "A", 10, 0);
    try graph.addEdge("J", 1, "K", 1, 1);
    graph.print();

    warn("\r\n", .{});
    warn("\r\nBFS: ", .{});
    var res1 = try graph.bfs();
    defer res1.deinit();

    for (res1.items) |n| {
        warn("\r\n bfs result: {} ", .{n});
    }
    warn("\r\n", .{});
    warn("\r\n", .{});
}

test "basic graph dfs" {
    var graph = Graph(i32).init(gallocator);
    defer graph.deinit();

    try graph.addEdge("A", 10, "B", 20, 1);
    try graph.addEdge("B", 20, "C", 40, 2);
    try graph.addEdge("C", 110, "A", 10, 3);
    try graph.addEdge("A", 10, "A", 10, 0);
    try graph.addEdge("J", 1, "K", 1, 1);
    graph.print();

    warn("\r\n", .{});
    warn("\r\nBFS: ", .{});
    var res1 = try graph.dfs();
    defer res1.deinit();

    for (res1.items) |n| {
        warn("\r\n dfs result: {} ", .{n});
    }
    warn("\r\n", .{});
    warn("\r\n", .{});
}

test "basic graph dijikstra" {
    // Graph with no self loops for dijiksta.
    var graph2 = Graph(i32).init(gallocator);
    defer graph2.deinit();

    try graph2.addEdge("A", 1, "B", 1, 1);
    try graph2.addEdge("B", 1, "C", 1, 2);
    try graph2.addEdge("C", 1, "D", 1, 5);
    try graph2.addEdge("D", 1, "E", 1, 4);
    // try graph2.addEdge("B", 1, "E", 1, 1);
    graph2.print();

    _ = try graph2.topoSort();
    warn("\r\nConnected components: {}", .{graph2.connected});

    warn("\r\n", .{});
    warn("\r\nDijikstra: ", .{});
    var res3 = try graph2.dijikstra("A", "E");
    defer res3.deinit();

    for (res3.items) |n| {
        warn("\r\n dijikstra: {} ", .{n});
    }
    warn("\r\n", .{});
    warn("\r\n", .{});
}

test "basic graph prim" {
    // Graph for prim.
    var graph3 = Graph(i32).init(gallocator);
    defer graph3.deinit();

    try graph3.addEdge("A", 1, "B", 1, 1);
    try graph3.addEdge("B", 1, "C", 1, 2);
    try graph3.addEdge("C", 1, "D", 1, 5);
    try graph3.addEdge("D", 1, "E", 1, 4);
    try graph3.addEdge("B", 1, "E", 1, 1);
    graph3.print();

    _ = try graph3.topoSort();
    warn("\r\nConnected components: {}", .{graph3.connected});

    warn("\r\n", .{});
    warn("\r\nPrim: ", .{});
    var res4 = try graph3.prim("A");
    defer res4.deinit();

    for (res4.items) |n| {
        for (n.items) |x| {
            warn("\r\n prim: {} ", .{x});
        }
    }
    warn("\r\n", .{});
    warn("\r\n", .{});
}

test "basic graph tarjan" {
    // Graph for tarjan.
    var graph4 = Graph(i32).init(gallocator);
    defer graph4.deinit();

    try graph4.addEdge("A", 1, "B", 1, 1);
    try graph4.addEdge("B", 1, "A", 1, 1);
    try graph4.addEdge("B", 1, "C", 1, 2);
    try graph4.addEdge("C", 1, "B", 1, 1);
    try graph4.addEdge("C", 1, "D", 1, 5);
    try graph4.addEdge("D", 1, "E", 1, 4);
    try graph4.addEdge("B", 1, "E", 1, 1);
    try graph4.addEdge("J", 1, "K", 1, 1);
    try graph4.addEdge("M", 1, "N", 1, 1);
    graph4.print();

    _ = try graph4.topoSort();
    warn("\r\nConnected components: {}", .{graph4.connected});

    warn("\r\n", .{});
    warn("\r\nTarjan: ", .{});
    var res5 = try graph4.tarjan();
    defer res5.deinit();

    for (res5.items) |n| {
        warn("\r\n begin component:", .{});
        for (n.items) |x| {
            warn("\r\n    tarjan: {} ", .{x});
        }
        warn("\r\n end component.", .{});
    }
    warn("\r\n", .{});
    warn("\r\n", .{});
}
