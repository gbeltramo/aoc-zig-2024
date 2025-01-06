const std = @import("std");
const assert = std.debug.assert;
const io = @import("io.zig");
const read = @import("read.zig");

const input_path_parts = [3][]const u8{ "puzzles", "12", "input.txt" };
// const input_path_parts = [3][]const u8{ "puzzles", "12", "example-input.txt" };

const DOT_VALUE = 0;
const WALL_VALUE = 1;
const X_VALUE = 2;

const GuardValue = enum(u8) {
    Up = 1,
    Right = 2,
    Down = 3,
    Left = 4,
};

const Coord = struct {
    x: usize,
    y: usize,
};

const MatrixIndexError = error{
    InvalidRowIndex,
    InvalidColIndex,
    OutOfBoundsIndexing,
};

const MatrixMap = struct {
    items: []u8,
    num_rows: usize,
    num_cols: usize,

    fn get(self: *MatrixMap, idx_i: usize, idx_j: usize) !u8 {
        if (idx_i >= self.num_rows) {
            // try io.stderr.print("\tERR: MatrixIndexError.InvalidRowIndex in .at({d}, {d})\n", .{ idx_i, idx_j });
            return MatrixIndexError.InvalidRowIndex;
        }

        if (idx_j >= self.num_cols) {
            // try io.stderr.print("\tERR: MatrixIndexError.InvalidColIndex in .at({d}, {d})\n", .{ idx_i, idx_j });
            return MatrixIndexError.InvalidColIndex;
        }

        const index = idx_i * self.num_cols + idx_j;

        if (index >= self.items.len) {
            // try io.stderr.print("\tERR: MatrixIndexError.OutOfBoundsIndexing in .at({d}, {d})\\n", .{ idx_i, idx_j });
            return MatrixIndexError.OutOfBoundsIndexing;
        }

        return self.items[index];
    }

    fn set(self: *MatrixMap, idx_i: usize, idx_j: usize, new_value: u8) !void {
        if (idx_i >= self.num_rows) {
            // try io.stderr.print("\tERR: MatrixIndexError.InvalidRowIndex in .at({d}, {d})\n", .{ idx_i, idx_j });
            return MatrixIndexError.InvalidRowIndex;
        }

        if (idx_j >= self.num_cols) {
            // try io.stderr.print("\tERR: MatrixIndexError.InvalidColIndex in .at({d}, {d})\n", .{ idx_i, idx_j });
            return MatrixIndexError.InvalidColIndex;
        }

        const index = idx_i * self.num_cols + idx_j;

        if (index >= self.items.len) {
            // try io.stderr.print("\tERR: MatrixIndexError.OutOfBoundsIndexing in .at({d}, {d})\\n", .{ idx_i, idx_j });
            return MatrixIndexError.OutOfBoundsIndexing;
        }

        self.items[index] = new_value;

        return;
    }
};

inline fn getNextGuardValue(guard_value: GuardValue) GuardValue {
    return switch (guard_value) {
        GuardValue.Up => GuardValue.Right,
        GuardValue.Right => GuardValue.Down,
        GuardValue.Down => GuardValue.Left,
        GuardValue.Left => GuardValue.Up,
    };
}

// inline fn handleStepInto(guard_map: *GuardMap, idx_i: usize, idx_j: usize) !bool {

// }

const GuardMap = struct {
    map: MatrixMap,
    already_visited: MatrixMap,
    guard_value: GuardValue,
    pos: Coord,
    is_in_loop: bool,

    fn init(lines: std.ArrayList([]const u8), allocator: std.mem.Allocator) !GuardMap {
        const num_rows = lines.items.len;
        const num_cols = lines.items[0].len;
        for (lines.items) |line| {
            assert(line.len == num_cols);
        }
        const n = num_rows * num_rows;
        var items: []u8 = try allocator.alloc(u8, n);

        var visited_items: []u8 = try allocator.alloc(u8, n);
        for (0..n) |i| {
            visited_items[i] = 0; // Note: 0 is not a guard value
        }
        var initial_pos = Coord{ .x = 0, .y = 0 };
        for (lines.items, 0..) |line, idx_i| {
            for (line, 0..) |c, idx_j| {
                const x: u8 = switch (c) {
                    '.' => DOT_VALUE,
                    '#' => WALL_VALUE,
                    '^' => blk: {
                        initial_pos.x = idx_i;
                        initial_pos.y = idx_j;
                        break :blk X_VALUE;
                    },
                    else => {
                        var msg_array: [64]u8 = undefined;
                        for (0..64) |idx| {
                            msg_array[idx] = 0;
                        }
                        const msg = try std.fmt.bufPrint(&msg_array, "PANIC: invalid character c={d}\n", .{c});
                        @panic(msg);
                    },
                };
                items[idx_i * num_cols + idx_j] = x;
            }
        }

        visited_items[initial_pos.x * num_cols + initial_pos.y] = @intFromEnum(GuardValue.Up);

        return GuardMap{
            .pos = initial_pos,
            .map = MatrixMap{
                .items = items,
                .num_rows = num_rows,
                .num_cols = num_cols,
            },
            .guard_value = GuardValue.Up,
            .already_visited = MatrixMap{
                .items = visited_items,
                .num_rows = num_rows,
                .num_cols = num_cols,
            },
            .is_in_loop = false,
        };
    }

    fn deinit(self: *GuardMap, allocator: std.mem.Allocator) void {
        // io.stderr.print("DEBUG: freeing self.map._data\n", .{}) catch unreachable;
        allocator.free(self.map.items);
        allocator.free(self.already_visited.items);
    }

    fn step(self: *GuardMap) !bool {
        var idx_i: usize = 0;
        var idx_j: usize = 0;

        switch (self.guard_value) {
            GuardValue.Up => {
                if (self.pos.x == 0) {
                    return false;
                }

                idx_i = self.pos.x - 1;
                idx_j = self.pos.y;
            },
            GuardValue.Right => {
                idx_i = self.pos.x;
                idx_j = self.pos.y + 1;
            },
            GuardValue.Down => {
                idx_i = self.pos.x + 1;
                idx_j = self.pos.y;
            },
            GuardValue.Left => {
                if (self.pos.y == 0) {
                    return false;
                }

                idx_i = self.pos.x;
                idx_j = self.pos.y - 1;
            },
        }
        const next_value = self.map.get(idx_i, idx_j) catch |err| switch (err) {
            MatrixIndexError.InvalidRowIndex, MatrixIndexError.InvalidColIndex, MatrixIndexError.OutOfBoundsIndexing => {
                return false;
            },
        };

        switch (next_value) {
            DOT_VALUE => {
                self.map.set(idx_i, idx_j, X_VALUE) catch unreachable;
                try self.already_visited.set(idx_i, idx_j, @intFromEnum(self.guard_value));
                self.pos.x = idx_i;
                self.pos.y = idx_j;
                // try io.stderr.print("\tDEBUG: .step(): next pos is ({d}, {d}) and increased count_visited\n", .{ idx_i, idx_j });
            },
            WALL_VALUE => {
                self.guard_value = getNextGuardValue(self.guard_value);
            },
            X_VALUE => {
                self.pos.x = idx_i;
                self.pos.y = idx_j;
                const prev_guard_value = try self.already_visited.get(idx_i, idx_j);
                if (@intFromEnum(self.guard_value) == prev_guard_value) {
                    self.is_in_loop = true;
                }
            },
            else => {
                @panic("PANIC: invalid next_value in .step() method\n");
            },
        }
        return true;
    }
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const rel_input_path = try std.fs.path.join(allocator, &input_path_parts);
    const lines: std.ArrayList([]const u8) = try read.rel_file_line_by_line(rel_input_path, 512, allocator);
    var count_walls_causing_loop: usize = 0;

    var prerun_gmap = try GuardMap.init(lines, allocator);
    defer prerun_gmap.deinit(allocator);
    while (try prerun_gmap.step()) {}

    for (0..prerun_gmap.map.num_rows) |row_new_wall| {
        for (0..prerun_gmap.map.num_cols) |col_new_wall| {
            const int_guard_value = try prerun_gmap.already_visited.get(row_new_wall, col_new_wall);
            if (int_guard_value > 0) {
                // try io.stderr.print("\t -- DEBUG: inner check ({d}, {d})\n", .{ row_new_wall, col_new_wall });

                var gmap = try GuardMap.init(lines, allocator);
                defer gmap.deinit(allocator);
                var a_loop_was_found = false;
                try gmap.map.set(row_new_wall, col_new_wall, WALL_VALUE);
                while ((!a_loop_was_found) and (try gmap.step())) {
                    if (gmap.is_in_loop) {
                        count_walls_causing_loop += 1;
                        a_loop_was_found = true;
                    }
                }
            }
        }
    }

    try io.stdout.print("INFO: The solution to puzzle 12 is: {d}\n", .{count_walls_causing_loop});

    return;
}
