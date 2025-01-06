const std = @import("std");
const assert = std.debug.assert;
const io = @import("io.zig");
const read = @import("read.zig");

const input_path_parts = [3][]const u8{ "puzzles", "12", "input.txt" };
// const input_path_parts = [3][]const u8{ "puzzles", "12", "example-input.txt" };

const MapValue = enum(u2) {
    Dot = 0,
    Wall = 1,
    X = 2,
};

const GuardValue = enum(u2) {
    Up = 0,
    Right = 1,
    Down = 2,
    Left = 3,
};

const Coord = struct {
    x: i32,
    y: i32,
};

const MatrixIndexError = error{
    InvalidRowIndex,
    InvalidColIndex,
    OutOfBoundsIndexing,
};

fn MakeGenericMatrix(comptime T: type) type {
    return struct {
        _data: []u8,
        items: std.PackedIntSlice(T),
        num_rows: i32,
        num_cols: i32,

        fn get(self: *MakeGenericMatrix(T), idx_i: i32, idx_j: i32) !T {
            if ((idx_i < 0) or (idx_i >= self.num_rows)) {
                // try io.stderr.print("\tERR: MatrixIndexError.InvalidRowIndex in .at({d}, {d})\n", .{ idx_i, idx_j });
                return MatrixIndexError.InvalidRowIndex;
            }

            if ((idx_j < 0) or (idx_j >= self.num_cols)) {
                // try io.stderr.print("\tERR: MatrixIndexError.InvalidColIndex in .at({d}, {d})\n", .{ idx_i, idx_j });
                return MatrixIndexError.InvalidColIndex;
            }

            const index: usize = @as(usize, @intCast(idx_i * self.num_cols + idx_j));

            if (index >= self.items.len) {
                // try io.stderr.print("\tERR: MatrixIndexError.OutOfBoundsIndexing in .at({d}, {d})\\n", .{ idx_i, idx_j });
                return MatrixIndexError.OutOfBoundsIndexing;
            }

            return self.items.get(index);
        }

        fn set(self: *MakeGenericMatrix(T), idx_i: i32, idx_j: i32, new_value: T) !void {
            if ((idx_i < 0) or (idx_i >= self.num_rows)) {
                // try io.stderr.print("\tERR: MatrixIndexError.InvalidRowIndex in .at({d}, {d})\n", .{ idx_i, idx_j });
                return MatrixIndexError.InvalidRowIndex;
            }

            if ((idx_j < 0) or (idx_j >= self.num_cols)) {
                // try io.stderr.print("\tERR: MatrixIndexError.InvalidColIndex in .at({d}, {d})\n", .{ idx_i, idx_j });
                return MatrixIndexError.InvalidColIndex;
            }

            const index: usize = @as(usize, @intCast(idx_i * self.num_cols + idx_j));

            if (index >= self.items.len) {
                // try io.stderr.print("\tERR: MatrixIndexError.OutOfBoundsIndexing in .at({d}, {d})\\n", .{ idx_i, idx_j });
                return MatrixIndexError.OutOfBoundsIndexing;
            }

            self.items.set(index, new_value);

            return;
        }
    };
}

const MatrixMap = MakeGenericMatrix(u2);

fn getNextGuardValue(guard_value: GuardValue) GuardValue {
    return switch (guard_value) {
        GuardValue.Up => GuardValue.Right,
        GuardValue.Right => GuardValue.Down,
        GuardValue.Down => GuardValue.Left,
        GuardValue.Left => GuardValue.Up,
    };
}

fn handleStepInto(guard_map: *GuardMap, idx_i: i32, idx_j: i32) !bool {
    const next_value = guard_map.map.get(idx_i, idx_j) catch |err| switch (err) {
        MatrixIndexError.InvalidRowIndex, MatrixIndexError.InvalidColIndex, MatrixIndexError.OutOfBoundsIndexing => {
            return false;
        },
    };

    switch (next_value) {
        @intFromEnum(MapValue.Dot) => {
            guard_map.count_visited += 1;
            guard_map.map.set(idx_i, idx_j, @intFromEnum(MapValue.X)) catch unreachable;
            try guard_map.already_visited.put(Coord{ .x = idx_i, .y = idx_j }, guard_map.guard_value);
            guard_map.pos.x = idx_i;
            guard_map.pos.y = idx_j;
            // try io.stderr.print("\tDEBUG: .step(): next pos is ({d}, {d}) and increased count_visited\n", .{ idx_i, idx_j });
        },
        @intFromEnum(MapValue.Wall) => {
            guard_map.guard_value = getNextGuardValue(guard_map.guard_value);
        },
        @intFromEnum(MapValue.X) => {
            guard_map.pos.x = idx_i;
            guard_map.pos.y = idx_j;
            const prev_guard_value = guard_map.already_visited.get(Coord{ .x = idx_i, .y = idx_j }) orelse unreachable;
            if (guard_map.guard_value == prev_guard_value) {
                guard_map.is_in_loop = true;
            }
        },
        else => {
            @panic("PANIC: invalid next_value in .step() method\n");
        },
    }
    return true;
}

const GuardMap = struct {
    pos: Coord,
    map: MatrixMap,
    count_visited: u64,
    guard_value: GuardValue,
    already_visited: std.AutoHashMap(Coord, GuardValue),
    is_in_loop: bool,

    fn init(lines: std.ArrayList([]const u8), allocator: std.mem.Allocator) !GuardMap {
        const num_rows = lines.items.len;
        const num_cols = lines.items[0].len;
        for (lines.items) |line| {
            assert(line.len == num_cols);
        }
        const n = num_rows * num_rows;
        const num_required_for_u2 = std.PackedIntSlice(u2).bytesRequired(n);
        // try io.stderr.print("DEBUG: num_required bytes PackedIntSlice(u2): {d} \n", .{num_required_for_u2});
        const _data: []u8 = try allocator.alloc(u8, num_required_for_u2);
        var items = std.PackedIntSlice(u2).init(_data, n);

        var initial_pos = Coord{ .x = 0, .y = 0 };
        for (lines.items, 0..) |line, idx_i| {
            for (line, 0..) |c, idx_j| {
                const x: u2 = switch (c) {
                    '.' => @intFromEnum(MapValue.Dot),
                    '#' => @intFromEnum(MapValue.Wall),
                    '^' => blk: {
                        initial_pos.x = @as(i32, @intCast(idx_i));
                        initial_pos.y = @as(i32, @intCast(idx_j));
                        break :blk @intFromEnum(MapValue.X);
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
                items.set(idx_i * num_cols + idx_j, x);
            }
        }

        var already_visited = std.AutoHashMap(Coord, GuardValue).init(allocator);
        try already_visited.put(initial_pos, GuardValue.Up);
        //        already_visited

        return GuardMap{
            .pos = initial_pos,
            .map = MatrixMap{
                ._data = _data,
                .items = items,
                .num_rows = @as(i32, @intCast(num_rows)),
                .num_cols = @as(i32, @intCast(num_cols)),
            },
            .count_visited = 1,
            .guard_value = GuardValue.Up,
            .already_visited = already_visited,
            .is_in_loop = false,
        };
    }

    fn deinit(self: *GuardMap, allocator: std.mem.Allocator) void {
        // io.stderr.print("DEBUG: freeing self.map._data\n", .{}) catch unreachable;
        allocator.free(self.map._data);
    }

    fn step(self: *GuardMap) !bool {
        var idx_i: i32 = 0;
        var idx_j: i32 = 0;

        switch (self.guard_value) {
            GuardValue.Up => {
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
                idx_i = self.pos.x;
                idx_j = self.pos.y - 1;
            },
        }
        const continue_to_next_step = try handleStepInto(self, idx_i, idx_j);
        return continue_to_next_step;
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

    var coords_iter = prerun_gmap.already_visited.iterator();

    // while (coords_iter.next()) |Entry| {
    //     const coord = Entry.key_ptr.*;
    //     try io.stderr.print("DEBUG: coord: (x={d}, y={d})\n", .{ coord.x, coord.y });
    // }
    // try io.stderr.print("DEBUG: number of already visited {d} / {d}\n", .{ prerun_gmap.already_visited.count(), prerun_gmap.map.num_rows * prerun_gmap.map.num_cols });

    while (coords_iter.next()) |entry| {
        const coord = entry.key_ptr.*;
        const row_new_wall = coord.x;
        const col_new_wall = coord.y;

        // try io.stderr.print("\t -- DEBUG: inner check ({d}, {d})\n", .{ row_new_wall, col_new_wall });

        var gmap = try GuardMap.init(lines, allocator);
        defer gmap.deinit(allocator);
        var a_loop_was_found = false;
        try gmap.map.set(@as(i32, @intCast(row_new_wall)), @as(i32, @intCast(col_new_wall)), @intFromEnum(MapValue.Wall));
        while ((!a_loop_was_found) and (try gmap.step())) {
            if (gmap.is_in_loop) {
                count_walls_causing_loop += 1;
                a_loop_was_found = true;
            }
        }
    }

    try io.stdout.print("INFO: The solution to puzzle 12 is: {d}\n", .{count_walls_causing_loop});

    return;
}
