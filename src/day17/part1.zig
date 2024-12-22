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
    var reg_A = try std.fmt.parseInt(usize, value_of_next(&line_split), 10);
    var reg_B = try std.fmt.parseInt(usize, value_of_next(&line_split), 10);
    var reg_C = try std.fmt.parseInt(usize, value_of_next(&line_split), 10);
    _ = line_split.next();

    var instructions = std.ArrayList(usize).init(allocator);
    defer instructions.deinit();

    var instructions_text = std.mem.splitScalar(u8, value_of_next(&line_split), ',');
    while (instructions_text.next()) |instruction| {
        try instructions.append(try std.fmt.parseInt(usize, instruction, 10));
    }

    print("{} {} {}\n", .{ reg_A, reg_B, reg_C });
    print("{}\n", .{instructions});

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
            5 => print("{},", .{7 & combo(operand, &reg_A, &reg_B, &reg_C)}),
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
