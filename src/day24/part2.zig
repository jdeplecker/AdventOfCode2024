const std = @import("std");
const print = std.debug.print;
const input = @embedFile("test_input.txt");

const Gate = struct {
    input1: []const u8,
    input2: []const u8,
    op: []const u8,
    output: []const u8,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var wires = std.StringHashMap(u1).init(allocator);
    defer wires.deinit();

    var gates = std.ArrayList(Gate).init(allocator);
    defer gates.deinit();

    const highest_z: []const u8 = "z05";

    var line_input = std.mem.splitSequence(u8, input, "\n");
    var wire_input_finished = false;
    while (line_input.next()) |line| {
        if (std.mem.eql(u8, line, "")) {
            if (!wire_input_finished) {
                wire_input_finished = true;
                continue;
            } else break;
        }
        if (!wire_input_finished) {
            var wire_name_value = std.mem.splitSequence(u8, line, ": ");
            const wire_name = wire_name_value.next().?;
            const wire_value = try std.fmt.parseInt(u1, wire_name_value.next().?, 10);
            try wires.put(wire_name, wire_value);
        } else {
            var gate_expr_output = std.mem.splitSequence(u8, line, " -> ");
            const gate_expr = gate_expr_output.next().?;
            const gate_output = gate_expr_output.next().?;

            var gate_expr_input = std.mem.splitSequence(u8, gate_expr, " ");
            const gate_input1 = gate_expr_input.next().?;
            const gate_op = gate_expr_input.next().?;
            const gate_input2 = gate_expr_input.next().?;
            try gates.append(Gate{ .input1 = gate_input1, .input2 = gate_input2, .op = gate_op, .output = gate_output });
        }
    }
    print("{}\n", .{std.json.fmt(gates.items, .{})});

    var wrong_gates = std.StringHashMap(void).init(allocator);
    defer wrong_gates.deinit();

    for (gates.items) |gate| {
        if (gate.output[0] == 'z' and gate.op[0] != 'X' and !std.mem.eql(u8, gate.output, highest_z)) {
            try wrong_gates.put(gate.output, {});
        }
        if (gate.op[0] == 'X' and std.mem.indexOf(u8, "xyz", gate.output[0..1]) == null and std.mem.indexOf(u8, "xyz", gate.input1[0..1]) == null and std.mem.indexOf(u8, "xyz", gate.input2[0..1]) == null) {
            try wrong_gates.put(gate.output, {});
        }

        if (gate.op[0] == 'X') {
            for (gates.items) |sub_gate| {
                if ((std.mem.eql(u8, gate.output, sub_gate.input1) or std.mem.eql(u8, gate.output, sub_gate.input2)) and sub_gate.op[0] == 'O') {
                    try wrong_gates.put(gate.output, {});
                }
            }
        }

        if (gate.op[0] == 'A' and !(std.mem.eql(u8, "x00", gate.input1) or std.mem.eql(u8, "x00", gate.input2))) {
            for (gates.items) |sub_gate| {
                if ((std.mem.eql(u8, gate.output, sub_gate.input1) or std.mem.eql(u8, gate.output, sub_gate.input2)) and sub_gate.op[0] != 'O') {
                    try wrong_gates.put(gate.output, {});
                }
            }
        }
    }

    var wrong_gates_it = wrong_gates.keyIterator();
    var wrong_gates_array = try allocator.alloc([]const u8, wrong_gates.count());
    var i: u32 = 0;
    while (wrong_gates_it.next()) |wrong_gate| : (i += 1) {
        wrong_gates_array[i] = wrong_gate.*;
    }
    std.mem.sort([]const u8, wrong_gates_array, {}, string_less_than);
    print("{s}\n", .{wrong_gates_array});
}

fn string_less_than(_: void, lhs: []const u8, rhs: []const u8) bool {
    return std.mem.order(u8, lhs, rhs) == .lt;
}
