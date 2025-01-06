/// 1. Define input file
/// 2. Read input file
/// 3. Parse input lines in lists of integers and hash map of counts of second column
/// 4. For each integer in first list count how many times it appears in the second list
/// 5. Sum up similarity scores.
const std = @import("std");
const print = std.debug.print;
const assert = std.debug.assert;

const read = @import("read.zig");
const io = @import("io.zig");
const sort = @import("sort.zig");
const parse_lines = @import("parse_lines.zig");

const input_path: []const u8 = "puzzles/02/input.txt";
// const input_path: []const u8 = "puzzles/02/example_input.txt";

pub fn main() !void {
    // Define arena allocator
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const ga = arena.allocator();

    // Get absolute path to input file
    // Get absolute path to input file and read it
    var _abs_path_array: [std.fs.MAX_PATH_BYTES]u8 = undefined;
    for (0..std.fs.MAX_PATH_BYTES) |i| {
        _abs_path_array[i] = 0;
    }
    const abs_path = try std.fs.realpath(input_path, &_abs_path_array);
    const lines = try read.abs_file_line_by_line(abs_path, 1024, ga);

    // Parse columns in ArrayLists and AutoHashMap
    const initial_capacity = 100;
    var locations1 = try std.ArrayList(u32).initCapacity(ga, initial_capacity);
    defer locations1.deinit();
    var counts2 = std.AutoHashMap(u32, u32).init(ga);
    defer counts2.deinit();

    try parse_lines.as_column_array(lines, &locations1, 0);

    for (lines.items[0..]) |line| {
        var it = std.mem.splitSequence(u8, line, "   ");
        var locations_idx: u2 = 0;
        while (it.next()) |x| {
            const num = try std.fmt.parseInt(u32, x, 10);

            if (locations_idx == 1) {
                const maybe_null_value: ?u32 = counts2.get(num);
                const value = maybe_null_value orelse 0;
                try counts2.put(num, value + 1);
            }
            locations_idx += 1;
        }
    }

    // print("Parsed locations1 of length {d}\n", .{locations1.items.len});
    // print("Parsed counts2 of containing {d} key/value pairs\n", .{counts2.count()});

    // // Uncomment for debugging
    // print("Elements in the AutoHashMap()\n", .{});
    // var key_it = counts2.keyIterator();
    // while (key_it.next()) |key_ptr| {
    //     const v = counts2.get(key_ptr.*) orelse 12345;
    //     print("{d} - {d}\n", .{ key_ptr.*, v });
    // }

    var total: u64 = 0;
    for (0..locations1.items.len) |idx| {
        const key: u32 = locations1.items[idx];
        const value: u32 = counts2.get(key) orelse 0;
        total += key * value;
    }

    try io.stdout.print("INFO: The solution to puzzle 02 is: {d}\n", .{total});

    return;
}
