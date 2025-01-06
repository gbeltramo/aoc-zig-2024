/// Generic Matrix structs that can be used to store 2D data structures.
const std = @import("std");
const stderr = std.io.getStdErr().writer();

pub fn MakeCoord(comptime T_indices: type) type {
    return struct {
        row_i: T_indices,
        col_i: T_indices,
    };
}

pub const MatrixError = error{
    InvalidRowIndex,
    InvalidColIndex,
    OutOfBoundsIndexing,
};

/// Generics Matrix with elements of type "T_data" and indices of type "T_indices".
/// Note that "T_indices" needs to be unsigned, e.g. u32.
pub fn MakeMatrix(comptime T_data: type, comptime T_indices: type) type {
    return struct {
        data: []T_data,
        num_rows: T_indices,
        num_cols: T_indices,

        pub fn init(num_rows: usize, num_cols: usize, allocator: std.mem.Allocator) !MakeMatrix(T_data, T_indices) {
            const data: []T_data = try allocator.alloc(T_data, num_rows * num_cols);
            return MakeMatrix(T_data, T_indices){
                .data = data,
                .num_rows = @as(T_indices, @intCast(num_rows)),
                .num_cols = @as(T_indices, @intCast(num_cols)),
            };
        }

        pub fn deinit(self: *MakeMatrix(T_data, T_indices), allocator: std.mem.Allocator) void {
            allocator.free(self.data);
            return;
        }

        fn safe_index(self: *MakeMatrix(T_data, T_indices), row_i: T_indices, col_i: T_indices) !usize {
            if (row_i >= self.num_rows) {
                try stderr.print(">>> ERROR: MatrixError.InvalidRowIndex in matrix.safe_get({d}, {d})\n", .{ row_i, col_i });
                return MatrixError.InvalidRowIndex;
            }

            if (col_i >= self.num_cols) {
                try stderr.print(">>> ERROR: MatrixError.InvalidColIndex in matrix.safe_get({d}, {d})\n", .{ row_i, col_i });
                return MatrixError.InvalidColIndex;
            }

            const index: T_indices = row_i * self.num_cols + col_i;

            if (index >= self.data.len) {
                try stderr.print(">>> ERROR: MatrixError.OutOfBoundsIndexing in matrix.safe_get({d}, {d})\\n", .{ row_i, col_i });
                return MatrixError.OutOfBoundsIndexing;
            }

            return index;
        }

        pub fn safe_get(self: *MakeMatrix(T_data, T_indices), row_i: T_indices, col_i: T_indices) !T_data {
            const index = try self.safe_index(row_i, col_i);
            return self.data[index];
        }

        pub fn safe_set(self: *MakeMatrix(T_data, T_indices), row_i: T_indices, col_i: T_indices, new_value: T_data) !void {
            const index = try self.safe_index(row_i, col_i);
            self.data[index] = new_value;
            return;
        }

        pub fn print(self: *MakeMatrix(T_data, T_indices)) !void {
            var row_i: T_indices = 0;
            var col_i: T_indices = 0;
            while (row_i < self.num_rows) {
                col_i = 0;
                try stderr.print("[", .{});
                while (col_i < self.num_cols) {
                    try stderr.print("{d: >2} ", .{try self.safe_get(row_i, col_i)});
                    col_i += 1;
                }
                try stderr.print("{d: >2}]\n", .{try self.safe_get(row_i, self.num_cols - 1)});
                row_i += 1;
            }
        }

        pub fn printAsASCII(self: *MakeMatrix(T_data, T_indices)) !void {
            var row_i: T_indices = 0;
            var col_i: T_indices = 0;
            while (row_i < self.num_rows) {
                col_i = 0;
                while (col_i < self.num_cols) {
                    try stderr.print("{c}", .{try self.safe_get(row_i, col_i)});
                    col_i += 1;
                }
                try stderr.print("{c}\n", .{try self.safe_get(row_i, self.num_cols - 1)});
                row_i += 1;
            }
        }
    };
}
