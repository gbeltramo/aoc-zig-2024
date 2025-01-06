const std = @import("std");
const assert = std.debug.assert;
const io = @import("io.zig");
const read = @import("read.zig");
const thirteen_utils = @import("thirteen_utils.zig");
const TotalAndNumbers = thirteen_utils.TotalAndNumbers;
const MulOrAdd = thirteen_utils.MulOrAdd;

const input_path_parts = [3][]const u8{ "puzzles", "13", "input.txt" };
// const input_path_parts = [3][]const u8{ "puzzles", "13", "example-input.txt" };

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const rel_input_path = try std.fs.path.join(allocator, &input_path_parts);
    const lines = try read.rel_file_line_by_line(rel_input_path, 128, allocator);
    try io.stderr.print("DEBUG: The file at rel_input_path={s} contains {d} lines\n", .{ rel_input_path, lines.items.len });

    var grand_total: u64 = 0;
    next_line: for (lines.items) |line| {
        try io.stderr.print("DEBUG: line={s}\n", .{line});
        const total_and_numbers: TotalAndNumbers = try thirteen_utils.parse_line(line, allocator);
        const total = total_and_numbers.total;
        const numbers: std.ArrayList(u64) = total_and_numbers.numbers;

        const ops = try thirteen_utils.allSequencesTwoOps(numbers.items.len - 1, allocator);

        try io.stderr.print("\tDEBUG: got all ops for {d} numbers\n", .{numbers.items.len});
        try io.stderr.print("\tDEBUG: Total sequences ops={d}\n", .{ops.items.len});

        for (ops.items) |op| {
            var current_total = numbers.items[0];

            // try io.stderr.print("\tDEBUG: op={any}\n", .{op});

            for (0..numbers.items.len - 1) |idx_op| {
                const n = numbers.items[idx_op + 1];
                const o = op[idx_op];
                // try io.stderr.print("\t\tDEBUG: n={d} o={}\n", .{ n, o });
                current_total = switch (o) {
                    MulOrAdd.Mul => current_total * n,
                    MulOrAdd.Add => current_total + n,
                };
            }

            // try io.stderr.print("\tDEBUG: current total={d}\n", .{current_total});

            if (total == current_total) {
                try io.stderr.print("\tDEBUG: total={d} is satisfied\n", .{total});
                try io.stderr.print("\tDEBUG: --------------------\n", .{});

                grand_total += total;
                continue :next_line;
            }
        }
    }

    try io.stdout.print("INFO: The solution to puzzle 13 is: {d}\n", .{grand_total});

    return;
}
