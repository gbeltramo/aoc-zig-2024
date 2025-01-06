const std = @import("std");
const assert = std.debug.assert;
const io = @import("io.zig");
const read = @import("read.zig");
const matrix = @import("matrix.zig");

const input_path_parts = [3][]const u8{ "puzzles", "16", "input.txt" };
// const input_path_parts = [3][]const u8{ "puzzles", "16", "example-input.txt" };

const T_index = u16;
const Matrix = matrix.MakeMatrix(u8, T_index);
const Coord = matrix.MakeCoord(T_index);

/// Partition antennas found on the 2D map by their category, i.e. letter or digit.
/// - Each category is an entry in a AutoArrayHashMap
/// - Allocate space in ArraList(Coord) for their 2D locations, with an initial capacity
fn partitionAntennasByCategory(city_map: *Matrix, initial_coord_capacity: usize, allocator: std.mem.Allocator) !std.AutoArrayHashMap(u8, std.ArrayList(Coord)) {
    var antennas = std.AutoArrayHashMap(u8, std.ArrayList(Coord)).init(allocator);

    // >>> Initialize ArrayList for digits. ASCII range [48, 57]
    var key_char: u8 = 48;
    while (key_char < 58) {
        const value_list = try std.ArrayList(Coord).initCapacity(allocator, initial_coord_capacity);
        try antennas.put(key_char, value_list);
        key_char += 1;
    }
    // <<<

    // Initialize ArrayList for uppercase letters. ASCII range [65, 90]
    key_char = 65;
    while (key_char < 91) {
        const value_list = try std.ArrayList(Coord).initCapacity(allocator, initial_coord_capacity);
        try antennas.put(key_char, value_list);
        key_char += 1;
    }
    // <<<

    // Initialize ArrayList for lowercase letters. ASCII range [97, 122]
    key_char = 97;
    while (key_char < 123) {
        const value_list = try std.ArrayList(Coord).initCapacity(allocator, initial_coord_capacity);
        try antennas.put(key_char, value_list);
        key_char += 1;
    }
    // <<<

    // >>> Two nested loops to visit each 2D location and .append(coord)
    // >>> to the desired ArrayList
    const dot_ascii_value: u8 = '.';
    var row_i: T_index = 0;
    var col_i: T_index = 0;
    while (row_i < city_map.num_rows) {
        col_i = 0;
        while (col_i < city_map.num_cols) {
            key_char = try city_map.safe_get(row_i, col_i);
            if (key_char != dot_ascii_value) {
                const coord = Coord{ .row_i = row_i, .col_i = col_i };
                try io.stderr.print("DEBUG: Found valid {c} at {any}\n", .{ key_char, coord });
                var value_list = antennas.getPtr(key_char) orelse unreachable;
                try value_list.append(coord);
            }
            col_i += 1;
        }
        row_i += 1;
    }
    // <<<

    return antennas;
}

pub fn main() !void {
    // >>> Create Arena allocator used for everything
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    // <<<

    // >>> Read input
    const rel_input_path = try std.fs.path.join(allocator, &input_path_parts);
    var _abs_path_array: [std.fs.MAX_PATH_BYTES]u8 = undefined;
    for (0..std.fs.MAX_PATH_BYTES) |i| {
        _abs_path_array[i] = 0;
    }
    const abs_path = try std.fs.realpath(rel_input_path, &_abs_path_array);
    const lines = try read.abs_file_line_by_line(abs_path, 128, allocator);
    defer lines.deinit();
    try io.stderr.print("DEBUG: The file at rel_input_path={s} contains {d} lines\n", .{ rel_input_path, lines.items.len }); // Note: debug
    // <<<

    // >>> Parse input into city_map, which is a matrix of 2D locations
    const num_rows = lines.items.len;
    const num_cols = lines.items[0].len;
    for (0..num_rows) |i| {
        assert(lines.items[i].len == num_cols);
    }
    var city_map = try Matrix.init(num_rows, num_cols, allocator);
    defer city_map.deinit(allocator);

    var row_i: T_index = 0;
    var col_i: T_index = 0;
    while (row_i < city_map.num_rows) {
        col_i = 0;
        while (col_i < city_map.num_cols) {
            try city_map.safe_set(row_i, col_i, lines.items[row_i][col_i]);
            col_i += 1;
        }
        row_i += 1;
    }

    try city_map.printAsASCII(); // Note: debug
    // <<<

    // >>> Get antennas by category
    var antennas = try partitionAntennasByCategory(&city_map, 128, allocator);
    defer antennas.deinit();

    const A_list = antennas.get(65) orelse unreachable; // Note: debug
    try io.stderr.print("DEBUG: A_list --> coord_0={} | coord_1.row_i={d}, coord_1.col_i={d}\n", .{ A_list.items[0], A_list.items[1].row_i, A_list.items[1].col_i }); // Note: debug
    // <<<

    // >>> Iterate on antennas categories and find antinotes.
    // >>> Given each antinote, check whether it was already added as such
    // >>> using a mask of visited antinodes `antinodes_locations`
    var total: usize = 0;
    const antinodes_data = try allocator.alloc(u8, city_map.num_rows * city_map.num_cols);
    for (0..city_map.num_rows * city_map.num_cols) |i| {
        antinodes_data[i] = 0;
    }
    defer allocator.free(antinodes_data);
    var antinodes_locations = Matrix{
        .data = antinodes_data,
        .num_rows = city_map.num_rows,
        .num_cols = city_map.num_cols,
    };

    var antennas_iter = antennas.iterator();
    while (antennas_iter.next()) |entry| {
        // const key_char = entry.key_ptr.*; // Note: debug
        // try io.stderr.print("DEBUG: >>> key_char={}\n", .{key_char}); // Note: debug
        const value_list = entry.value_ptr.*;

        var step_row: T_index = 0;
        var step_col: T_index = 0;
        var count_step: T_index = 0;

        var delta_row: T_index = 0;
        var delta_col: T_index = 0;

        var antinote_row_0: T_index = 0;
        var antinote_col_0: T_index = 0;
        var antinote_row_1: T_index = 0;
        var antinote_col_1: T_index = 0;

        for (0..value_list.items.len) |idx_i| {
            for (idx_i + 1..value_list.items.len) |idx_j| {
                var c0: Coord = undefined;
                var c1: Coord = undefined;

                // Comment: We ensure `c0` is always on the above in the 2D map
                if (value_list.items[idx_i].row_i <= value_list.items[idx_j].row_i) {
                    c0 = value_list.items[idx_i];
                    c1 = value_list.items[idx_j];
                } else {
                    c1 = value_list.items[idx_i];
                    c0 = value_list.items[idx_j];
                }
                step_row = c1.row_i - c0.row_i;

                // try io.stderr.print("DEBUG: >>> c0={any}\n", .{c0}); // Note: debug
                // try io.stderr.print("DEBUG: >>> c1={any}\n", .{c1}); // Note: debug
                // try io.stderr.print("DEBUG: >>> delta_row={d}\n", .{delta_row}); // Note: debug

                // Comment: now there are only 2 cases, which determine antinodes locations
                //    - `c1.col_i` is greater than `c0.col_i`
                //    - `c1.col_i` is less than or equal to `c0.col_i`
                if (c1.col_i > c0.col_i) {
                    step_col = c1.col_i - c0.col_i;

                    if (step_row == 0) {
                        // Comment: step_col cannot be 0 because in the nested loop we start from `idx_i + 1`
                        step_col = 1;
                    } else if (step_col == 0) {
                        // Comment: idem
                        step_row = 1;
                    } else {
                        const factor: T_index = std.math.gcd(step_row, step_col);
                        step_row /= factor;
                        step_col /= factor;
                    }

                    // Comment: case \, antinote above c0
                    count_step = 0;
                    delta_row = count_step * step_row;
                    delta_col = count_step * step_col;
                    while ((delta_row <= c0.row_i) and (delta_col <= c0.col_i)) {
                        antinote_row_0 = c0.row_i - delta_row;
                        antinote_col_0 = c0.col_i - delta_col;
                        const index = antinote_row_0 * num_cols + antinote_col_0;
                        if (antinodes_locations.data[index] == 0) {
                            // try io.stderr.print("\tDEBUG: >>> Valid antinode above c0 (1) at ({d}, {d})\n", .{ antinote_row_0, antinote_col_0 }); // Note: debug
                            antinodes_locations.data[index] = 1;
                            total += 1;
                        }

                        count_step += 1;
                        delta_row = count_step * step_row;
                        delta_col = count_step * step_col;
                    }

                    // Comment: case \, antinote below c1
                    count_step = 0;
                    delta_row = count_step * step_row;
                    delta_col = count_step * step_col;
                    while (((delta_row + c1.row_i) < num_rows) and ((delta_col + c1.col_i) < num_cols)) {
                        antinote_row_1 = c1.row_i + delta_row;
                        antinote_col_1 = c1.col_i + delta_col;
                        const index = antinote_row_1 * num_cols + antinote_col_1;
                        if (antinodes_locations.data[index] == 0) {
                            // try io.stderr.print("\tDEBUG: >>> Valid antinode below c1 (1) at ({d}, {d})\n", .{ antinote_row_1, antinote_col_1 }); // Note: debug
                            antinodes_locations.data[index] = 1;
                            total += 1;
                        }

                        count_step += 1;
                        delta_row = count_step * step_row;
                        delta_col = count_step * step_col;
                    }
                } else {
                    step_col = c0.col_i - c1.col_i;

                    if (step_row == 0) {
                        // Comment: step_col cannot be 0 because in the nested loop we start from `idx_i + 1`
                        step_col = 1;
                    } else if (step_col == 0) {
                        // Comment: idem
                        step_row = 1;
                    } else {
                        const factor: T_index = std.math.gcd(step_row, step_col);
                        step_row /= factor;
                        step_col /= factor;
                    }

                    // Comment: case /, antinote above c0
                    count_step = 0;
                    delta_row = count_step * step_row;
                    delta_col = count_step * step_col;
                    while ((delta_row <= c0.row_i) and ((delta_col + c0.col_i) < num_cols)) {
                        antinote_row_0 = c0.row_i - delta_row;
                        antinote_col_0 = c0.col_i + delta_col;
                        const index = antinote_row_0 * num_cols + antinote_col_0;
                        if (antinodes_locations.data[index] == 0) {
                            // try io.stderr.print("\tDEBUG: >>> Valid antinode above c0 (2) at ({d}, {d})\n", .{ antinote_row_0, antinote_col_0 }); // Note: debug
                            antinodes_locations.data[index] = 1;
                            total += 1;
                        }

                        count_step += 1;
                        delta_row = count_step * step_row;
                        delta_col = count_step * step_col;
                    }

                    // Comment: case /, antinote below c1
                    count_step = 0;
                    delta_row = count_step * step_row;
                    delta_col = count_step * step_col;
                    while (((delta_row + c1.row_i) < num_rows) and (delta_col <= c1.col_i)) {
                        antinote_row_1 = c1.row_i + delta_row;
                        antinote_col_1 = c1.col_i - delta_col;
                        const index = antinote_row_1 * num_cols + antinote_col_1;
                        if (antinodes_locations.data[index] == 0) {
                            // try io.stderr.print("\tDEBUG: >>> Valid antinode below c1 (2) at ({d}, {d})\n", .{ antinote_row_1, antinote_col_1 }); // Note: debug
                            antinodes_locations.data[index] = 1;
                            total += 1;
                        }
                        count_step += 1;
                        delta_row = count_step * step_row;
                        delta_col = count_step * step_col;
                    }
                }
            }
        }
    }

    // >>> Debug
    // for (0..antinodes_locations.data.len) |i| { // Note: debug
    //     if (antinodes_locations.data[i] == 1) { // Note: debug
    //         city_map.data[i] = '#'; // Note: debug
    //     } // Note: debug
    // } // Note: debug
    // try city_map.printAsASCII(); // Note: debug
    // <<<

    // >>> Print solution of puzzle to STDOUT
    try io.stdout.print("INFO: The solution to puzzle 16 is: {d}\n", .{total});
    // <<<

    // >>> Final clean up of resources
    var antennas_iter_deinit = antennas.iterator();
    while (antennas_iter_deinit.next()) |entry| {
        entry.value_ptr.*.deinit();
    }
    // <<<

    return;
}
