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
            const wire_value = wire_name_value.next().?;
            try wires.put(wire_name, try std.fmt.parseInt(u1, wire_value, 10));
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

    var has_solved = true;
    while (has_solved) {
        has_solved = false;
        for (gates.items) |gate| {
            if (wires.contains(gate.output)) continue;
            if (wires.contains(gate.input1) and wires.contains(gate.input2)) {
                const input1 = wires.get(gate.input1).?;
                const input2 = wires.get(gate.input2).?;
                switch (gate.op[0]) {
                    'A' => {
                        if (input1 == 1 and input2 == 1) {
                            try wires.put(gate.output, 1);
                        } else {
                            try wires.put(gate.output, 0);
                        }
                    },
                    'X' => {
                        try wires.put(gate.output, input1 + input2);
                    },
                    'O' => {
                        if (input1 == 1 or input2 == 1) {
                            try wires.put(gate.output, 1);
                        } else {
                            try wires.put(gate.output, 0);
                        }
                    },
                    else => unreachable,
                }
                has_solved = true;
            }
        }
    }

    var result: usize = 0;
    var wires_it = wires.iterator();
    while (wires_it.next()) |entry| {
        if (entry.key_ptr.*[0] == 'z') {
            const bit_index = try std.fmt.parseInt(u6, entry.key_ptr.*[1..], 10) - 1;
            result += (@as(usize, @intCast(2)) << bit_index) * @as(usize, @intCast(entry.value_ptr.*));
        }
    }
    print("result {}\n", .{result});
}
