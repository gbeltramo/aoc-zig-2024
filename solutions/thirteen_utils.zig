const std = @import("std");
const io = @import("io.zig");

pub const MulOrAdd = enum(u1) {
    Mul = 0,
    Add = 1,
};

pub const MulOrAddOrJoin = enum(u8) {
    Mul = 0,
    Add = 1,
    Join = 2,
};

pub const TotalAndNumbers = struct {
    total: u64,
    numbers: std.ArrayList(u64),
};

/// Parse a single line from the input file of puzzle 13
pub fn parse_line(line: []const u8, allocator: std.mem.Allocator) !TotalAndNumbers {
    var line_iter = std.mem.splitSequence(u8, line, ": ");

    // First element in line is the total of operation
    const total_str = line_iter.next() orelse unreachable;
    const total = try std.fmt.parseInt(u64, total_str, 10);

    // Second element in line are all the numbers that can be multiplied and summed
    const numbers_str = line_iter.next() orelse unreachable;
    var numbers_str_iter = std.mem.splitSequence(u8, numbers_str, " ");
    var numbers = try std.ArrayList(u64).initCapacity(allocator, 8);
    while (numbers_str_iter.next()) |n_str| {
        const n = try std.fmt.parseInt(u64, n_str, 10);
        try numbers.append(n);
    }

    // There shouldn't be a third element
    const needs_to_be_null = line_iter.next();
    if (needs_to_be_null != null) {
        @panic("PANIC: needs to be null\n");
    }

    return TotalAndNumbers{ .total = total, .numbers = numbers };
}

/// All possible sequences of operations using Mul and/or Add
pub fn allSequencesTwoOps(num_ops: usize, allocator: std.mem.Allocator) !std.ArrayList([]MulOrAdd) {
    var ops = std.ArrayList([]MulOrAdd).init(allocator);

    const num_different_ops: u64 = 2;
    const num_sequences = std.math.pow(u64, num_different_ops, @as(u64, @intCast(num_ops)));
    for (0..num_sequences) |seq_id| {
        var seq = try allocator.alloc(MulOrAdd, num_ops);
        var partial: u64 = @as(u64, @intCast(seq_id));
        for (0..num_ops) |idx_up| {
            const idx_down = @as(u64, @intCast(num_ops - 1 - idx_up));
            // try io.stderr.print("\t\tDEBUG: power of {d} and {d}\n", .{ num_different_ops, idx_down });
            const denominator = std.math.pow(u64, num_different_ops, @as(u64, @intCast(idx_down)));
            const factor: u64 = @divTrunc(partial, denominator);

            partial -= factor * denominator;

            switch (factor) {
                0 => {
                    seq[idx_down] = MulOrAdd.Mul;
                },
                1 => {
                    seq[idx_down] = MulOrAdd.Add;
                },
                else => {
                    @panic("PANIC: wrong \"factor\"\n");
                },
            }
        }
        try ops.append(seq);
    }

    return ops;
}

/// All possible sequences of operations using Mul and/or Add and/or ||
pub fn allSequencesThreeOps(num_ops: usize, allocator: std.mem.Allocator) !std.ArrayList([]MulOrAddOrJoin) {
    var ops = std.ArrayList([]MulOrAddOrJoin).init(allocator);

    const num_different_ops: u64 = 3;
    const num_sequences = std.math.pow(u64, num_different_ops, @as(u64, @intCast(num_ops)));
    for (0..num_sequences) |seq_id| {
        var seq = try allocator.alloc(MulOrAddOrJoin, num_ops);
        var partial: u64 = @as(u64, @intCast(seq_id));
        for (0..num_ops) |idx_up| {
            const idx_down = @as(u64, @intCast(num_ops - 1 - idx_up));
            // try io.stderr.print("\t\tDEBUG: power of {d} and {d}\n", .{ num_different_ops, idx_down });
            const denominator = std.math.pow(u64, num_different_ops, @as(u64, @intCast(idx_down)));
            const factor: u64 = @divTrunc(partial, denominator);

            partial -= factor * denominator;

            switch (factor) {
                0 => {
                    seq[idx_down] = MulOrAddOrJoin.Mul;
                },
                1 => {
                    seq[idx_down] = MulOrAddOrJoin.Add;
                },
                2 => {
                    seq[idx_down] = MulOrAddOrJoin.Join;
                },
                else => {
                    @panic("PANIC: wrong \"factor\"\n");
                },
            }
        }
        try ops.append(seq);
    }

    return ops;
}
