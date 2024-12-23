const std = @import("std");
const print = std.debug.print;
const input = @embedFile("test_input.txt");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var lines = std.mem.splitScalar(u8, input, '\n');
    var design_split = std.mem.splitSequence(u8, lines.next().?, ", ");
    var designs = std.StringHashMap(usize).init(allocator);
    defer designs.deinit();

    while (design_split.next()) |design| {
        try designs.put(design, 1);
    }

    var total: usize = 0;
    while (lines.next()) |line| {
        if (std.mem.eql(u8, line, "")) continue;
        total += try amount_possible(line, &designs);
        print("{}\n", .{total});
    }

    print("{}", .{total});
}

fn amount_possible(to_cover: []const u8, designs: *std.StringHashMap(usize)) !usize {
    var amount: usize = 0;
    for (0..to_cover.len + 1) |i| {
        const len = to_cover.len - i;
        if (designs.get(to_cover[0..len]) orelse 1 == 0) {
            break;
        }
        if (designs.get(to_cover[0..len]) orelse 0 > 0) {
            const rest_to_cover = to_cover[len..to_cover.len];
            if (len == to_cover.len or designs.get(rest_to_cover) orelse 0 > 0) {
                amount += designs.get(rest_to_cover) orelse 1;
                continue;
            }
            const rest_amount = try amount_possible(rest_to_cover, designs);
            if (rest_amount > 0) {
                amount += rest_amount;
                continue;
            }
        }
    }
    try designs.*.put(to_cover, amount);
    return amount;
}
