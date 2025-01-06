const std = @import("std");
const assert = std.debug.assert;
const read = @import("read.zig");
const io = @import("io.zig");

const input_path_parts = [3][]const u8{ "puzzles", "08", "input.txt" };
// const input_path_parts = [3][]const u8{ "puzzles", "08", "example-input.txt" };

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

    const AMMSSas_ints = [5]u8{ 65, 77, 77, 83, 83 };
    var all_offsets = try std.ArrayList([5]TwoTuple).initCapacity(allocator, 4);

    // The four possible rotations in 2D of a X
    const list_offsets_1 = [5]TwoTuple{
        TwoTuple{ .x = 0, .y = 0 },
        TwoTuple{ .x = -1, .y = 1 },
        TwoTuple{ .x = 1, .y = 1 },
        TwoTuple{ .x = 1, .y = -1 },
        TwoTuple{ .x = -1, .y = -1 },
    };
    try all_offsets.append(list_offsets_1);

    const list_offsets_2 = [5]TwoTuple{
        TwoTuple{ .x = 0, .y = 0 },
        TwoTuple{ .x = 1, .y = 1 },
        TwoTuple{ .x = 1, .y = -1 },
        TwoTuple{ .x = -1, .y = -1 },
        TwoTuple{ .x = -1, .y = 1 },
    };
    try all_offsets.append(list_offsets_2);

    const list_offsets_3 = [5]TwoTuple{
        TwoTuple{ .x = 0, .y = 0 },
        TwoTuple{ .x = 1, .y = -1 },
        TwoTuple{ .x = -1, .y = -1 },
        TwoTuple{ .x = -1, .y = 1 },
        TwoTuple{ .x = 1, .y = 1 },
    };
    try all_offsets.append(list_offsets_3);

    const list_offsets_4 = [5]TwoTuple{
        TwoTuple{ .x = 0, .y = 0 },
        TwoTuple{ .x = -1, .y = -1 },
        TwoTuple{ .x = -1, .y = 1 },
        TwoTuple{ .x = 1, .y = 1 },
        TwoTuple{ .x = 1, .y = -1 },
    };
    try all_offsets.append(list_offsets_4);

    for (0..text_matrix.num_rows) |idx_i| {
        for (0..text_matrix.num_cols) |idx_j| {
            const coord = Coord{ .idx_i = @as(isize, @intCast(idx_i)), .idx_j = @as(isize, @intCast(idx_j)) };

            for (all_offsets.items) |list_offsets| {
                var failed_AMMSS_loop = false;
                for (AMMSSas_ints, 0..) |letter, index| {
                    if (failed_AMMSS_loop) {
                        break;
                    }

                    const offset = list_offsets[index];
                    const target_coord = coord.jumpTo(offset.x, offset.y);

                    const target_letter = text_matrix.at(target_coord.idx_i, target_coord.idx_j) catch |err| switch (err) {
                        TextMatrixIndexError.InvalidRowIndex, TextMatrixIndexError.InvalidColIndex, TextMatrixIndexError.OutOfBoundsIndexing => {
                            failed_AMMSS_loop = true;
                            continue;
                        },
                        else => @panic("PANIC: text_matrix.at() to get target_letter"),
                    };

                    if (!(target_letter == letter)) {
                        failed_AMMSS_loop = true;
                        continue;
                    }
                }

                if (!failed_AMMSS_loop) {
                    // try.iostdout.print("Found AMMSS at {}\n", .{coord});
                    total += 1;
                }
            }
        }
    }

    try io.stdout.print("INFO: The solution to puzzle 08 is: {d}\n", .{total});

    return;
}
