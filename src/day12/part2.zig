const std = @import("std");
const print = std.debug.print;
const input = @embedFile("input.txt");

const Pos = struct { x: usize, y: usize };

const Region = struct {
    const Self = @This();
    letter: u8,
    positions: std.ArrayList(Pos),
    max_x: usize = 0,
    max_y: usize = 0,
    pub fn create(allocator: std.mem.Allocator, letter: u8) *Self {
        const region = allocator.create(Self) catch @panic("OOM");
        region.* = .{
            .letter = letter,
            .positions = std.ArrayList(Pos).init(allocator),
        };
        return region;
    }
    pub fn deinit(self: Self) void {
        self.positions.deinit();
    }
    pub fn add(self: *Self, pos: Pos) !void {
        try self.positions.append(pos);
        if (pos.x > self.*.max_x) {
            self.*.max_x = pos.x;
        }
        if (pos.y > self.*.max_y) {
            self.*.max_y = pos.y;
        }
    }
    pub fn count_fences(self: Self) !usize {
        var total: usize = 0;
        var positions_field = try self.positions.allocator.alloc([]bool, self.max_y + 2);
        defer self.positions.allocator.free(positions_field);
        for (0..self.max_y + 2) |y| {
            positions_field[y] = try self.positions.allocator.alloc(bool, self.max_x + 2);
            for (0..self.max_x + 2) |x| {
                positions_field[y][x] = false;
            }
        }
        for (self.positions.items) |plot| {
            positions_field[plot.y][plot.x] = true;
        }
        for (self.positions.items) |plot| {
            var fences: usize = 0;

            const left_up = plot.y > 0 and plot.x > 0 and positions_field[plot.y - 1][plot.x - 1];
            const up = plot.y > 0 and positions_field[plot.y - 1][plot.x];
            const right_up = plot.y > 0 and positions_field[plot.y - 1][plot.x + 1];
            const right = positions_field[plot.y][plot.x + 1];
            const down = positions_field[plot.y + 1][plot.x];
            const down_left = plot.x > 0 and positions_field[plot.y + 1][plot.x - 1];
            const left = plot.x > 0 and positions_field[plot.y][plot.x - 1];

            if (!up and (left_up or !left)) {
                fences += 1;
            } else if (plot.y == 0 and !left) {
                fences += 1;
            }
            if (!right and (right_up or !up)) {
                fences += 1;
            } else if (plot.y == 0 and !right) {
                fences += 1;
            }
            if (!down and (down_left or !left)) {
                fences += 1;
            } else if (plot.y == self.max_y and !left) {
                fences += 1;
            }
            if (!left and (left_up or !up)) {
                fences += 1;
            } else if (plot.x == 0 and !up) {
                fences += 1;
            }
            total += fences;
        }
        return total;
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var regions = std.ArrayList(std.ArrayList(*Region)).init(allocator);
    defer regions.deinit();

    var plot_lines = std.mem.splitSequence(u8, input, "\n");
    var y: usize = 0;
    while (plot_lines.next()) |line| {
        try regions.append(std.ArrayList(*Region).init(allocator));
        for (line, 0..) |letter, x| {
            var new_region_ptr: *Region = undefined;
            if (x > 0 and regions.items[y].items[x - 1].*.letter == letter) {
                new_region_ptr = regions.items[y].items[x - 1];
                if (y > 0 and regions.items[y - 1].items[x].*.letter == letter and regions.items[y - 1].items[x] != regions.items[y].items[x - 1]) {
                    for (regions.items[y - 1].items[x].*.positions.items) |position_to_merge| {
                        const pos_to_change = &regions.items[position_to_merge.y].items[position_to_merge.x];
                        pos_to_change.* = new_region_ptr;
                        try new_region_ptr.*.add(position_to_merge);
                    }
                }
            } else if (y > 0 and regions.items[y - 1].items[x].*.letter == letter) {
                new_region_ptr = regions.items[y - 1].items[x];
            } else {
                new_region_ptr = Region.create(allocator, letter);
            }
            try new_region_ptr.*.add(Pos{ .x = x, .y = y });
            try regions.items[y].append(new_region_ptr);
        }
        y += 1;
    }

    var region_set = std.AutoHashMap(*Region, bool).init(allocator);
    for (regions.items) |region_line| {
        for (region_line.items) |region| {
            try region_set.put(region, true);
        }
    }

    var region_it = region_set.keyIterator();
    var result: usize = 0;
    while (region_it.next()) |region_ptr| {
        print("{c} {} {}\n", .{ region_ptr.*.letter, region_ptr.*.positions.items.len, try region_ptr.*.count_fences() });
        result += region_ptr.*.positions.items.len * try region_ptr.*.count_fences();
    }
    print("{}", .{result});
}
