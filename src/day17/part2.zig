const std = @import("std");
const print = std.debug.print;
const input = @embedFile("test_input.txt");

fn value_of_next(spliterator: *std.mem.SplitIterator(u8, std.mem.DelimiterType.scalar)) []const u8 {
    var next = std.mem.splitSequence(u8, spliterator.next().?, ": ");
    _ = next.next();
    return next.next().?;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var line_split = std.mem.splitScalar(u8, input, '\n');
    _ = line_split.next();
    _ = line_split.next();
    _ = line_split.next();
    _ = line_split.next();

    var instructions = std.ArrayList(usize).init(allocator);
    defer instructions.deinit();

    var instructions_text = std.mem.splitScalar(u8, value_of_next(&line_split), ',');
    while (instructions_text.next()) |instruction| {
        try instructions.append(try std.fmt.parseInt(usize, instruction, 10));
    }

    print("{}\n", .{instructions});
    var output = std.ArrayList(usize).init(allocator);
    defer output.deinit();

    var valid = std.ArrayList(usize).init(allocator);
    defer valid.deinit();
    try valid.append(0);

    for (1..instructions.items.len + 1) |length| {
        const old_valid = try allocator.dupe(usize, valid.items);
        valid.clearRetainingCapacity();
        for (old_valid) |num| {
            for (0..8) |offset| {
                const new_A = 8 * num + offset;
                output.clearRetainingCapacity();
                try run(instructions, new_A, &output);
                if (output.items.len == length and std.mem.containsAtLeast(usize, instructions.items, 1, output.items)) {
                    try valid.append(new_A);
                }
            }
        }
    }
    print("result = {d}", .{min(valid.items)});
}

fn min(array: []usize) usize {
    var min_num = array[0];
    for (array) |num| {
        if (num < min_num) {
            min_num = num;
        }
    }
    return min_num;
}

fn run(instructions: std.ArrayList(usize), reg_A_start: usize, output: *std.ArrayList(usize)) !void {
    var reg_A = reg_A_start;
    var reg_B: usize = 0;
    var reg_C: usize = 0;

    var ip: usize = 0;
    while (ip < instructions.items.len) {
        const op = instructions.items[ip];
        const operand = instructions.items[ip + 1];

        switch (op) {
            0 => adv(operand, &reg_A, &reg_B, &reg_C),
            1 => bxl(operand, &reg_B),
            2 => bst(operand, &reg_A, &reg_B, &reg_C),
            3 => {
                if (reg_A > 0) {
                    ip = operand;
                    continue;
                }
            },
            4 => bxc(&reg_B, &reg_C),
            5 => try output.*.append(7 & combo(operand, &reg_A, &reg_B, &reg_C)),
            6 => bdv(operand, &reg_A, &reg_B, &reg_C),
            7 => cdv(operand, &reg_A, &reg_B, &reg_C),
            else => unreachable,
        }
        ip += 2;
    }
}

fn combo(operand: usize, reg_A: *usize, reg_B: *usize, reg_C: *usize) usize {
    switch (operand) {
        0...3 => return operand,
        4 => return reg_A.*,
        5 => return reg_B.*,
        6 => return reg_C.*,
        else => unreachable,
    }
}

fn adv(operand: usize, reg_A: *usize, reg_B: *usize, reg_C: *usize) void {
    const value = combo(operand, reg_A, reg_B, reg_C);
    reg_A.* = reg_A.* >> @intCast(value);
}
fn bxl(operand: usize, reg_B: *usize) void {
    reg_B.* = reg_B.* ^ operand;
}
fn bst(operand: usize, reg_A: *usize, reg_B: *usize, reg_C: *usize) void {
    const value = combo(operand, reg_A, reg_B, reg_C);
    reg_B.* = 7 & value;
}
fn bxc(reg_B: *usize, reg_C: *usize) void {
    reg_B.* = reg_B.* ^ reg_C.*;
}
fn bdv(operand: usize, reg_A: *usize, reg_B: *usize, reg_C: *usize) void {
    const value = combo(operand, reg_A, reg_B, reg_C);
    reg_B.* = reg_A.* >> @intCast(value);
}
fn cdv(operand: usize, reg_A: *usize, reg_B: *usize, reg_C: *usize) void {
    const value = combo(operand, reg_A, reg_B, reg_C);
    reg_C.* = reg_A.* >> @intCast(value);
}
