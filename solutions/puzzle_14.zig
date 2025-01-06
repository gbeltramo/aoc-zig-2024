const std = @import("std");
const assert = std.debug.assert;
const io = @import("io.zig");
const read = @import("read.zig");
const thirteen_utils = @import("thirteen_utils.zig");
const TotalAndNumbers = thirteen_utils.TotalAndNumbers;
const MulOrAddOrJoin = thirteen_utils.MulOrAddOrJoin;

const input_path_parts = [3][]const u8{ "puzzles", "14", "input.txt" };
// const input_path_parts = [3][]const u8{ "puzzles", "14", "example-input.txt" };

const InputNumberError = error{
    TooManyDigits,
};

inline fn numberOfDigitsIn(n: u64) InputNumberError!u64 {
    return switch (n) {
        0...9 => 10,
        10...99 => 100,
        100...999 => 1_000,
        1_000...9_999 => 10_000,
        10_000...99_999 => 100_000,
        100_000...999_999 => 1_000_000,
        1_000_000...9_999_999 => 10_000_000,
        10_000_000...99_999_999 => 100_000_000,
        100_000_000...999_999_999 => 1_000_000_000,
        else => InputNumberError.TooManyDigits,
    };
}
/// Recurse on three types of operations to check whether the line equation can be satisfied
fn recursiveApplyThreeOperators(items: []u64, index_item: usize, current_total: u64, total: u64, op: MulOrAddOrJoin) !bool {
    const item = items[index_item];
    const new_current_total = switch (op) {
        MulOrAddOrJoin.Add => current_total + item,
        MulOrAddOrJoin.Mul => current_total * item,
        MulOrAddOrJoin.Join => blk: {
            const m = try numberOfDigitsIn(item);
            break :blk current_total * m + item;
        },
    };
    // try io.stderr.print("\t{d}DEBUG: starting with current_total={d} and applyng op={s}({d}) to get new={d}\n", .{ total, current_total, @tagName(op), item, new_current_total });

    if (total < new_current_total) {
        // try io.stderr.print("\t{d}DEBUG: pruning at index_item={d} with total={d} and new_current_total={}\n", .{ total, index_item, total, new_current_total });
        // try io.stderr.print("\t{d}DEBUG: ---\n", .{total});
        return false;
    }

    if (index_item == (items.len - 1)) {
        return total == new_current_total;
    } else {
        if (try recursiveApplyThreeOperators(
            items,
            index_item + 1,
            new_current_total,
            total,
            MulOrAddOrJoin.Add,
        )) {
            return true;
        } else if (try recursiveApplyThreeOperators(
            items,
            index_item + 1,
            new_current_total,
            total,
            MulOrAddOrJoin.Mul,
        )) {
            return true;
        } else if (try recursiveApplyThreeOperators(
            items,
            index_item + 1,
            new_current_total,
            total,
            MulOrAddOrJoin.Join,
        )) {
            return true;
        } else {
            return false;
        }
    }
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const rel_input_path = try std.fs.path.join(allocator, &input_path_parts);
    const lines = try read.rel_file_line_by_line(rel_input_path, 128, allocator);
    try io.stderr.print("DEBUG: The file at rel_input_path={s} contains {d} lines\n", .{ rel_input_path, lines.items.len });

    var grand_total: u64 = 0;

    const max_num_items: usize = 12;
    var possible_ops: [max_num_items - 1]std.ArrayList([]MulOrAddOrJoin) = undefined;
    for (1..max_num_items) |num_ops| {
        possible_ops[num_ops - 1] = try thirteen_utils.allSequencesThreeOps(num_ops, allocator);
    }

    next_line: for (lines.items) |line| {
        // try io.stderr.print("DEBUG: line={s}\n", .{line});
        const total_and_numbers: TotalAndNumbers = try thirteen_utils.parse_line(line, allocator);
        const total = total_and_numbers.total;
        const numbers: std.ArrayList(u64) = total_and_numbers.numbers;
        defer numbers.deinit();

        const is_solved_starting_add = try recursiveApplyThreeOperators(numbers.items, 1, numbers.items[0], total, MulOrAddOrJoin.Add);
        if (is_solved_starting_add) {
            try io.stderr.print("\tDEBUG: For line={s} => total={d} is satisfied starting Add\n", .{ line, total });
            // try io.stderr.print("\tDEBUG: --------------------\n", .{});

            grand_total += total;
            continue :next_line;
        }

        try io.stderr.print("\tDEBUG: Recursing on Mul\n", .{});
        const is_solved_starting_mul = try recursiveApplyThreeOperators(numbers.items, 1, numbers.items[0], total, MulOrAddOrJoin.Mul);
        if (is_solved_starting_mul) {
            try io.stderr.print("\tDEBUG: For line={s} => total={d} is satisfied starting Mul\n", .{ line, total });
            // try io.stderr.print("\tDEBUG: --------------------\n", .{});

            grand_total += total;
            continue :next_line;
        }

        try io.stderr.print("\tDEBUG: Recursing on Join\n", .{});
        const is_solved_starting_join = try recursiveApplyThreeOperators(numbers.items, 1, numbers.items[0], total, MulOrAddOrJoin.Join);
        if (is_solved_starting_join) {
            try io.stderr.print("\tDEBUG: For line={s} => total={d} is satisfied starting Join\n", .{ line, total });
            // try io.stderr.print("\tDEBUG: --------------------\n", .{});

            grand_total += total;
            continue :next_line;
        }
        // const ops = possible_ops[num_items - 2];

        // try io.stderr.print("\tDEBUG: got all ops for {d} numbers\n", .{numbers.items.len});
        // try io.stderr.print("\tDEBUG: Total sequences ops={d}\n", .{ops.items.len});
        // const num_ops_for_pruning: comptime_int = 3;
        // var all_pruned_start_seq = std.AutoHashMap([num_ops_for_pruning]MulOrAddOrJoin, u8).init(allocator);
        // var start_seq: [num_ops_for_pruning]MulOrAddOrJoin = undefined;

        // next_ops: for (ops.items) |op| {
        //     var current_total = numbers.items[0];

        //     for (0..numbers.items.len - 1) |idx_op| {
        //         const n = numbers.items[idx_op + 1];
        //         const o = op[idx_op];
        //         // try io.stderr.print("\t\tDEBUG: n={d} o={}\n", .{ n, o });
        //         current_total = switch (o) {
        //             MulOrAddOrJoin.Mul => current_total * n,
        //             MulOrAddOrJoin.Add => current_total + n,
        //             MulOrAddOrJoin.Join => blk: {
        //                 const m = try numberOfDigitsIn(n);
        //                 break :blk current_total * m + n;
        //             },
        //         };

        //         if (total < current_total) {
        //             continue :next_ops;
        //         }
        //     }

        // try io.stderr.print("\tDEBUG: current total={d}\n", .{current_total});

        // if (total == current_total) {
        //     try io.stderr.print("\tDEBUG: For line={s} => total={d} is satisfied\n", .{ line, total });
        //     // try io.stderr.print("\tDEBUG: --------------------\n", .{});

        //     grand_total += total;
        //     continue :next_line;
        // }
    }
    try io.stdout.print("INFO: The solution to puzzle 14 is: {d}\n", .{grand_total});

    return;
}
