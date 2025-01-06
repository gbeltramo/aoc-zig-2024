const std = @import("std");
const assert = std.debug.assert;
const io = @import("io.zig");

const read = @import("read.zig");
const matrix = @import("matrix.zig");

var input_path_parts = [3][]const u8{ "puzzles", "20", "input.txt" };
// var input_path_parts = [3][]const u8{ "puzzles", "20", "example-input.txt" };

const MatrixU8 = matrix.MakeMatrix(u8, usize);

fn searchAndCountPaths(map: *MatrixU8, row_i: usize, col_i: usize, next_value: u8, total: usize) usize {
    const map_value = map.safe_get(row_i, col_i) catch |err| switch (err) {
        else => {
            return 0;
        },
    };

    if (map_value == next_value) {
        if (map_value == 9) {
            return 1;
        } else {
            const total_0 = searchAndCountPaths(map, row_i + 1, col_i, map_value + 1, total);
            const total_1 = searchAndCountPaths(map, row_i, col_i + 1, map_value + 1, total);

            var total_2: usize = 0;
            if (row_i > 0) {
                total_2 = searchAndCountPaths(map, row_i - 1, col_i, map_value + 1, total);
            }

            var total_3: usize = 0;
            if (col_i > 0) {
                total_3 = searchAndCountPaths(map, row_i, col_i - 1, map_value + 1, total);
            }

            return total_0 + total_1 + total_2 + total_3;
        }
    } else {
        // io.stderr.print("DEBUG: not next value\n", .{}) catch unreachable;
        return 0;
    }
}

pub fn main() !void {
    // >>> Create Arena allocator used for everything
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    // <<<

    // >>> Read map into a matrix
    const rel_input_path = try std.fs.path.join(allocator, &input_path_parts);
    const lines = try read.rel_file_line_by_line(rel_input_path, 256, allocator);
    defer lines.deinit();
    // <<<

    // >>> Define table to convert strings of digits into digits, e.g. "0" to 0
    // >>> Note that ASCII digits are in the range [48, 57].
    var parse_int_table: [64]u8 = undefined;
    for (0..64) |i| {
        parse_int_table[i] = 0;
    }
    for (48..58, 0..) |index, digit| {
        parse_int_table[index] = @as(u8, @intCast(digit));
    }
    // <<<

    // <<< Create map
    var map = try MatrixU8.init(lines.items.len, lines.items[0].len, allocator);
    defer map.deinit(allocator);
    for (0..map.num_rows) |row_i| {
        for (0..map.num_cols) |col_i| {
            const digit = lines.items[row_i][col_i];
            try map.safe_set(
                row_i,
                col_i,
                parse_int_table[digit],
            );
        }
    }
    // <<<

    // >>> A stack
    var total: usize = 0;

    for (0..map.num_rows) |row_i| {
        for (0..map.num_cols) |col_i| {
            var partial_total: usize = 0;
            const map_value = try map.safe_get(row_i, col_i);

            if (map_value == 0) {
                const num_valid_paths_0 = searchAndCountPaths(&map, row_i + 1, col_i, map_value + 1, 0);
                const num_valid_paths_1 = searchAndCountPaths(&map, row_i, col_i + 1, map_value + 1, 0);

                var num_valid_paths_2: usize = 0;
                if (row_i > 0) {
                    num_valid_paths_2 = searchAndCountPaths(&map, row_i - 1, col_i, map_value + 1, 0);
                }

                var num_valid_paths_3: usize = 0;
                if (col_i > 0) {
                    num_valid_paths_3 = searchAndCountPaths(&map, row_i, col_i - 1, map_value + 1, 0);
                }

                partial_total += num_valid_paths_0;
                partial_total += num_valid_paths_1;
                partial_total += num_valid_paths_2;
                partial_total += num_valid_paths_3;

                io.stderr.print("\n---\nDEBUG: partial_total={d} for this head \n", .{partial_total}) catch unreachable;
                total += partial_total;
            }
        }
    }
    // <<<

    // >>> Print solution of puzzle to STDOUT
    try io.stdout.print("INFO: The solution to puzzle 20 is: {d}\n", .{total});
    // <<<

    return;
}
