const std = @import("std");
const print = std.debug.print;

pub fn main() !void {
    const day: []const u8 = "2";

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const input_data = try get_input_day(allocator, day);
    defer allocator.free(input_data);
    try create_day_folder(allocator, day, input_data);
}

fn concat(allocator: std.mem.Allocator, str1: []const u8, str2: []const u8) ![]u8 {
    return std.mem.concat(allocator, u8, &[_][]const u8{ str1, str2 });
}

fn create_day_folder(allocator: std.mem.Allocator, day: []const u8, input_data: []const u8) !void {
    var day_str = try allocator.dupe(u8, day);
    if (day_str.len < 2) {
        allocator.free(day_str);
        day_str = try concat(allocator, "0", day);
    }
    defer allocator.free(day_str);
    const day_path = try concat(allocator, "src/day", day_str);
    defer allocator.free(day_path);
    try std.fs.cwd().makePath(day_path);
    const part1_filename = try concat(allocator, day_path, "/part1.zig");
    defer allocator.free(part1_filename);
    try std.fs.cwd().copyFile("src/solution_template.zig", std.fs.cwd(), part1_filename, .{});
    const part2_filename = try concat(allocator, day_path, "/part2.zig");
    defer allocator.free(part2_filename);
    try std.fs.cwd().copyFile("src/solution_template.zig", std.fs.cwd(), part2_filename, .{});

    // empty test input
    const test_input_file_name = try concat(allocator, day_path, "/test_input.txt");
    defer allocator.free(test_input_file_name);
    const test_input_file = try std.fs.cwd().createFile(test_input_file_name, .{});
    defer test_input_file.close();

    // fetched test input
    const input_file_name = try concat(allocator, day_path, "/input.txt");
    defer allocator.free(input_file_name);
    const input_file = try std.fs.cwd().createFile(input_file_name, .{});
    defer input_file.close();

    try input_file.writeAll(input_data);
}

fn get_input_day(allocator: std.mem.Allocator, day: []const u8) ![]const u8 {
    const input_uri = try std.fmt.allocPrint(allocator, "https://adventofcode.com/2024/day/{s}/input", .{day});
    defer allocator.free(input_uri);
    const uri = try std.Uri.parse(input_uri);

    var client = std.http.Client{ .allocator = allocator };
    defer client.deinit();

    const server_header_buffer: []u8 = try allocator.alloc(u8, 1024 * 8);
    defer allocator.free(server_header_buffer);

    const cookie = try std.fs.cwd().readFileAlloc(allocator, "cookie.txt", 1024 * 8);
    defer allocator.free(cookie);

    const extra_headers: []std.http.Header = try allocator.alloc(std.http.Header, 1);
    extra_headers[0] = std.http.Header{
        .name = "Cookie",
        .value = cookie,
    };
    defer allocator.free(extra_headers);

    var req = try client.open(.GET, uri, .{ .server_header_buffer = server_header_buffer, .extra_headers = extra_headers });
    defer req.deinit();

    try req.send();
    try req.finish();
    try req.wait();

    print("Response status: {d}\n\n", .{req.response.status});

    return req.reader().readAllAlloc(allocator, 1024 * 32);
}
