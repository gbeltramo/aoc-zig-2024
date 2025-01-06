const std = @import("std");
const assert = std.debug.assert;
const read = @import("read.zig");
const io = @import("io.zig");

const input_path_parts = [3][]const u8{ "puzzles", "07", "input.txt" };
// const input_path_parts = [3][]const u8{ "puzzles", "07", "example-input.txt" };

const TextMatrixIndexError = error{
    InvalidRowIndex,
    InvalidColIndex,
    OutOfBoundsIndexing,
};

const TextMatrixError = io.ErrorSet || TextMatrixIndexError;

/// A block of text with fixed (num_rows x num_cols) dimensions.
const TextMatrix = struct {
    text: []u8,
    num_rows: usize,
    num_cols: usize,

    /// Create a TextMatrix using the contents of an ArrayList where each
    /// element is a line of text
    fn init(lines: std.ArrayList([]const u8), allocator: std.mem.Allocator) !TextMatrix {
        const _num_rows: usize = lines.items.len;
        const _num_cols: usize = lines.items[0].len;
        for (lines.items) |line| {
            // try stdout.print("DEBUG: Checking line for length consistency: {d}\n", .{line.len});
            assert(line.len == _num_cols);
        }
        const n: usize = _num_rows * _num_rows;
        const _text: []u8 = try allocator.alloc(u8, n);

        for (lines.items, 0..) |line, idx_i| {
            for (line, 0..) |c, idx_j| {
                _text[idx_i * _num_cols + idx_j] = c;
            }
        }

        return TextMatrix{
            .text = _text,
            .num_rows = _num_rows,
            .num_cols = _num_cols,
        };
    }

    /// Free the memory used by TextMatrix
    fn deinit(self: *TextMatrix, allocator: std.mem.Allocator) void {
        _ = io.stderr.print("INFO: TextMatrix.deinit(allocator): Freeing the TextMatrix.text field\n", .{}) catch unreachable;
        allocator.free(self.text);
    }

    fn at(self: *TextMatrix, idx_i: isize, idx_j: isize) TextMatrixError!u8 {
        if ((idx_i < 0) or (idx_i >= self.num_rows)) {
            try io.stderr.print("\tERR: TextMatrixError.InvalidRowIndex in .at({d}, {d})\n", .{ idx_i, idx_j });
            return TextMatrixError.InvalidRowIndex;
        }

        if ((idx_j < 0) or (idx_j >= self.num_cols)) {
            try io.stderr.print("\tERR: TextMatrixError.InvalidColIndex in .at({d}, {d})\n", .{ idx_i, idx_j });
            return TextMatrixError.InvalidColIndex;
        }

        const index: usize = @as(usize, @intCast(idx_i)) * self.num_cols + @as(usize, @intCast(idx_j));

        if (index >= self.text.len) {
            try io.stderr.print("\tERR: TextMatrixError.OutOfBoundsIndexing in .at({d}, {d})\\n", .{ idx_i, idx_j });
            return TextMatrixError.OutOfBoundsIndexing;
        }

        return self.text[index];
    }
};

const TwoTuple = struct {
    x: isize,
    y: isize,
};

/// The coordinates on one element in a TextMatrix
const Coord = struct {
    idx_i: isize,
    idx_j: isize,

    fn jumpTo(self: *const Coord, offset_i: isize, offset_j: isize) Coord {
        return Coord{
            .idx_i = self.idx_i + offset_i,
            .idx_j = self.idx_j + offset_j,
        };
    }

    fn is_valid(self: *const Coord, text_matrix: TextMatrix) bool {
        const condition_rows = (self.idx_i >= 0) or (self.idx_i < text_matrix.num_rows);
        const condition_cols = (self.idx_j >= 0) or (self.idx_j < text_matrix.num_cols);
        return (condition_rows and condition_cols);
    }
};

pub fn main() !void {
    var total: i64 = -1;
    total += 1;

    var arena_allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_allocator.deinit();
    const allocator = arena_allocator.allocator();

    const rel_input_path = try std.fs.path.join(allocator, &input_path_parts);
    const lines: std.ArrayList([]const u8) = try read.rel_file_line_by_line(rel_input_path, 512, allocator);
    // try.iostdout.print("INFO: The input.txt file contains {d} lines\n", .{lines.items.len});

    var text_matrix: TextMatrix = try TextMatrix.init(lines, allocator);
    defer text_matrix.deinit(allocator);

    const XMAS_as_ints = [4]u8{ 88, 77, 65, 83 };
    var all_offsets = try std.ArrayList([4]TwoTuple).initCapacity(allocator, 8);

    // Horizontal offsets
    const list_offsets_1 = [4]TwoTuple{
        TwoTuple{ .x = 0, .y = 0 },
        TwoTuple{ .x = 0, .y = 1 },
        TwoTuple{ .x = 0, .y = 2 },
        TwoTuple{ .x = 0, .y = 3 },
    };
    try all_offsets.append(list_offsets_1);

    const list_offsets_2 = [4]TwoTuple{
        TwoTuple{ .x = 0, .y = 0 },
        TwoTuple{ .x = 0, .y = -1 },
        TwoTuple{ .x = 0, .y = -2 },
        TwoTuple{ .x = 0, .y = -3 },
    };
    try all_offsets.append(list_offsets_2);

    // Vertical offsets
    const list_offsets_3 = [4]TwoTuple{
        TwoTuple{ .x = 0, .y = 0 },
        TwoTuple{ .x = 1, .y = 0 },
        TwoTuple{ .x = 2, .y = 0 },
        TwoTuple{ .x = 3, .y = 0 },
    };
    try all_offsets.append(list_offsets_3);

    const list_offsets_4 = [4]TwoTuple{
        TwoTuple{ .x = 0, .y = 0 },
        TwoTuple{ .x = -1, .y = 0 },
        TwoTuple{ .x = -2, .y = 0 },
        TwoTuple{ .x = -3, .y = 0 },
    };
    try all_offsets.append(list_offsets_4);

    // Diagonal offsets
    const list_offsets_5 = [4]TwoTuple{
        TwoTuple{ .x = 0, .y = 0 },
        TwoTuple{ .x = 1, .y = 1 },
        TwoTuple{ .x = 2, .y = 2 },
        TwoTuple{ .x = 3, .y = 3 },
    };
    try all_offsets.append(list_offsets_5);

    const list_offsets_6 = [4]TwoTuple{
        TwoTuple{ .x = 0, .y = 0 },
        TwoTuple{ .x = 1, .y = -1 },
        TwoTuple{ .x = 2, .y = -2 },
        TwoTuple{ .x = 3, .y = -3 },
    };
    try all_offsets.append(list_offsets_6);

    const list_offsets_7 = [4]TwoTuple{
        TwoTuple{ .x = 0, .y = 0 },
        TwoTuple{ .x = -1, .y = 1 },
        TwoTuple{ .x = -2, .y = 2 },
        TwoTuple{ .x = -3, .y = 3 },
    };
    try all_offsets.append(list_offsets_7);

    const list_offsets_8 = [4]TwoTuple{
        TwoTuple{ .x = 0, .y = 0 },
        TwoTuple{ .x = -1, .y = -1 },
        TwoTuple{ .x = -2, .y = -2 },
        TwoTuple{ .x = -3, .y = -3 },
    };
    try all_offsets.append(list_offsets_8);

    for (0..text_matrix.num_rows) |idx_i| {
        for (0..text_matrix.num_cols) |idx_j| {
            const coord = Coord{ .idx_i = @as(isize, @intCast(idx_i)), .idx_j = @as(isize, @intCast(idx_j)) };

            for (all_offsets.items) |list_offsets| {
                var failed_XMAS_loop = false;
                for (XMAS_as_ints, 0..) |letter, index| {
                    if (failed_XMAS_loop) {
                        break;
                    }

                    const offset = list_offsets[index];
                    const target_coord = coord.jumpTo(offset.x, offset.y);

                    const target_letter = text_matrix.at(target_coord.idx_i, target_coord.idx_j) catch |err| switch (err) {
                        TextMatrixIndexError.InvalidRowIndex, TextMatrixIndexError.InvalidColIndex, TextMatrixIndexError.OutOfBoundsIndexing => {
                            failed_XMAS_loop = true;
                            continue;
                        },
                        else => @panic("PANIC: text_matrix.at() to get target_letter"),
                    };

                    if (!(target_letter == letter)) {
                        failed_XMAS_loop = true;
                        continue;
                    }
                }

                if (!failed_XMAS_loop) {
                    // try.iostdout.print("Found XMAS at {}\n", .{coord});
                    total += 1;
                }
            }
        }
    }

    // // Sanity check
    // const N: comptime_int = 10;
    // var letters = try allocator.alloc(u8, N);
    // for (letters) |*l| {
    //     l.* = 0;
    // }
    // try io.stdout.print("INFO: Initial letters: {s}\n", .{letters});

    // const idx_i: isize = 0;
    // for (0..N) |idx_j| {
    //     letters[idx_j] = try text_matrix.at(idx_i, @as(isize, @intCast(idx_j)));
    // }
    // try io.stdout.print("INFO: The first {d} letters are: {s}\n", .{ letters.len, letters });

    // // Debugging
    // _ = text_matrix.at(-1, 2) catch |err| switch (err) {
    //     TextMatrixIndexError.InvalidRowIndex => {},
    //     TextMatrixIndexError.InvalidColIndex => {},
    //     TextMatrixIndexError.OutOfBoundsIndexing => {},
    //     else => {
    //         try io.stderr.print("\tERR: text_matrix.at(): unknown error\n", .{});
    //     },
    // };

    try io.stdout.print("INFO: The solution to puzzle 07 is: {d}\n", .{total});

    return;
}
