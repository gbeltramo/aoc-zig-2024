/// 1. Define input file
/// 2. Read input file
/// 3. Parse input lines in lists of integers
/// 4. Sort lists of integers
/// 5. Compare sorted integers
const std = @import("std");
const print = std.debug.print;
const assert = std.debug.assert;

const read = @import("read.zig");
const io = @import("io.zig");
const sort = @import("sort.zig");
const parse_lines = @import("parse_lines.zig");

const input_path: []const u8 = "puzzles/01/input.txt";
// const input_path: []const u8 = "puzzles/01/example_input.txt";

pub fn main() !void {
    // Define arena allocator
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const ga = arena.allocator();

    // Get absolute path to input file and read it
    var _abs_path_array: [std.fs.MAX_PATH_BYTES]u8 = undefined;
    for (0..std.fs.MAX_PATH_BYTES) |i| {
        _abs_path_array[i] = 0;
    }
    const abs_path = try std.fs.realpath(input_path, &_abs_path_array);
    const lines = try read.abs_file_line_by_line(abs_path, 1024, ga);

    // Parse columns in ArrayLists
    const initial_capacity = 100;
    var locations1 = try std.ArrayList(u32).initCapacity(ga, initial_capacity);
    var locations2 = try std.ArrayList(u32).initCapacity(ga, initial_capacity);
    try parse_lines.as_column_array(lines, &locations1, 0);
    try parse_lines.as_column_array(lines, &locations2, 1);
    assert(locations1.items.len == locations2.items.len);
    // print("Parsed locations1 of length {d}\n", .{locations1.items.len});
    // print("Parsed locations2 of length {d}\n", .{locations2.items.len});

    // Sort locations
    try sort.integers_inplace(locations1, 0, locations1.items.len - 1);
    try sort.integers_inplace(locations2, 0, locations2.items.len - 1);

    // // Uncomment for debugging
    // print("Locations 1\n", .{});
    // for (locations1.items[0..3]) |num| {
    //     print("- {d}\n", .{num});
    // }

    // print("Locations 2\n", .{});
    // for (locations2.items[0..3]) |num| {
    //     print("- {d}\n", .{num});
    // }

    // Comparing aligned values and summing their absolute
    // value difference
    var total: u64 = 0;
    for (0..locations1.items.len) |idx| {
        const a: i64 = locations1.items[idx];
        const b: i64 = locations2.items[idx];
        // print("idx={d} -> a={d}, b={d} and diff={d}\n", .{ idx, a, b, @abs(a - b) });
        total += @abs(a - b);
    }

    try io.stdout.print("INFO: The solution to puzzle 01 is: {d}\n", .{total});

    return;
}
