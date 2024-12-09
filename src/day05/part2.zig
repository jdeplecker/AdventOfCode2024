const std = @import("std");
const print = std.debug.print;
const input = @embedFile("test_input.txt");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const Rule = struct { u32, u32 };
    var rules = std.ArrayList(Rule).init(allocator);
    defer rules.deinit();
    var rules_pages = std.mem.splitSequence(u8, input, "\n\n");
    var rules_input = std.mem.splitSequence(u8, rules_pages.next().?, "\n");
    while (rules_input.next()) |rule_input| {
        var left_right_rule = std.mem.splitSequence(u8, rule_input, "|");
        const left = try std.fmt.parseInt(u32, left_right_rule.next().?, 10);
        const right = try std.fmt.parseInt(u32, left_right_rule.next().?, 10);
        try rules.append(.{ left, right });
    }

    var result: u32 = 0;
    var pages_input = std.mem.splitSequence(u8, rules_pages.next().?, "\n");
    while (pages_input.next()) |page_input| {
        if (std.mem.eql(u8, page_input, "")) {
            break;
        }
        var pages = std.mem.splitSequence(u8, page_input, ",");
        var page_list = std.ArrayList(u32).init(allocator);
        defer page_list.deinit();
        while (pages.next()) |page| {
            try page_list.append(try std.fmt.parseInt(u32, page, 10));
        }

        var rules_broken = false;
        var has_fixed = true;
        while (has_fixed) {
            has_fixed = false;
            for (rules.items) |rule| {
                var found_right: ?usize = null;
                for (page_list.items, 0..page_list.items.len) |page, i| {
                    if (page == rule[1]) {
                        found_right = i;
                    }
                    if (found_right != null and page == rule[0]) {
                        std.mem.swap(u32, &page_list.items[found_right.?], &page_list.items[i]);
                        found_right = null;
                        rules_broken = true;
                        has_fixed = true;
                    }
                }
            }
        }
        if (rules_broken) {
            result += page_list.items[page_list.items.len / 2];
        }
    }
    print("{}", .{result});
}
