const std = @import("std");
const print = std.debug.print;
const input = @embedFile("test_input.txt");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var lines = std.mem.splitScalar(u8, input, '\n');
    var design_split = std.mem.splitSequence(u8, lines.next().?, ", ");
    var designs = std.StringHashMap(bool).init(allocator);
    defer designs.deinit();

    while (design_split.next()) |design| {
        try designs.put(design, true);
    }

    var total: usize = 0;
    while (lines.next()) |line| {
        if (std.mem.eql(u8, line, "")) continue;
        if (try is_possible(line, &designs)) {
            total += 1;
        }
    }

    print("{}", .{total});
}

fn is_possible(to_cover: []const u8, designs: *std.StringHashMap(bool)) !bool {
    for (0..to_cover.len + 1) |i| {
        const len = to_cover.len - i;
        if (!(designs.get(to_cover[0..len]) orelse true)) {
            break;
        }
        if (designs.get(to_cover[0..len]) orelse false) {
            const rest_to_cover = to_cover[len..to_cover.len];
            if (len == to_cover.len or designs.get(rest_to_cover) orelse false) {
                return true;
            }
            if (try is_possible(rest_to_cover, designs)) {
                try designs.*.put(rest_to_cover, true);
                return true;
            }
        }
    }
    try designs.*.put(to_cover, false);
    return false;
}
