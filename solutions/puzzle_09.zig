const std = @import("std");
const assert = std.debug.assert;
const read = @import("read.zig");
const io = @import("io.zig");

const input_path_parts = [3][]const u8{ "puzzles", "09", "input.txt" };
// const input_path_parts = [3][]const u8{ "puzzles", "09", "example-input.txt" };

const OrderRule = struct {
    first: u16,
    second: u16,
};

/// Allocate an ArrayList to hold the comma separated values in a line. Assumes the line is non-empty
fn splitLineByCommas(line: []const u8, allocator: std.mem.Allocator) !std.ArrayList(u16) {
    var numbers = try std.ArrayList(u16).initCapacity(allocator, 8);

    var it = std.mem.splitSequence(u8, line, ",");
    while (it.next()) |num_str| {
        const num = try std.fmt.parseInt(u16, num_str, 10);
        try numbers.append(num);
    }
    return numbers;
}

pub fn main() !void {
    var total: i64 = -1;
    total += 1;

    var arena_allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_allocator.deinit();
    const allocator = arena_allocator.allocator();

    const rel_input_path = try std.fs.path.join(allocator, &input_path_parts);
    const lines: std.ArrayList([]const u8) = try read.rel_file_line_by_line(rel_input_path, 512, allocator);
    // try io.stdout.print("INFO: The input.txt file contains {d} lines\n", .{lines.items.len});

    var index_empty_line: usize = 0;
    loop: for (lines.items, 0..) |line, idx| {
        if (line.len == 0) {
            index_empty_line = idx;
            // try io.stderr.print("DEBUG: line: {s} | length: {d} | idx: {d}\n", .{ line, line.len, idx });
            break :loop;
        }
    }

    var rules = std.AutoHashMap(OrderRule, u8).init(allocator);
    defer rules.deinit();
    for (0..index_empty_line) |idx| {
        const rule_line = lines.items[idx];
        var it = std.mem.splitSequence(u8, rule_line, "|");
        const num1_str = it.next() orelse unreachable;
        const num2_str = it.next() orelse unreachable;

        const maybe_num3_str = it.next();
        if (maybe_num3_str != null) {
            @panic("PANIC: there must be at most three elements in each rule_line\n");
        }

        const num1 = try std.fmt.parseInt(u16, num1_str, 10);
        const num2 = try std.fmt.parseInt(u16, num2_str, 10);
        try rules.put(OrderRule{ .first = num1, .second = num2 }, 0);
    }

    outer_loop: for (lines.items[index_empty_line + 1 ..]) |line| {
        const numbers = try splitLineByCommas(line, allocator);
        defer numbers.deinit();

        // try io.stderr.print("DEBUG: line {d}\n", .{idx});
        // for (numbers.items) |n| {
        //     try io.stderr.print("\tDEBUG: {d}\n", .{n});
        // }
        // try io.stderr.print("DEBUG: ------------------------------\n", .{});

        for (0..numbers.items.len - 1) |idx0| {
            const value = numbers.items[idx0];

            // Check these value are less
            for (0..idx0) |idx_before| {
                const before_value = numbers.items[idx_before];
                const correct_rule = OrderRule{ .first = before_value, .second = value };
                const wrong_rule = OrderRule{ .first = value, .second = before_value };
                const maybe_good = rules.get(correct_rule);
                const maybe_bad = rules.get(wrong_rule);

                // We skip maybe_good because if it is non-null,
                // then there is no action to take

                if (maybe_bad != null) {
                    try io.stderr.print("DEBUG: the line {s} is NOT valid because of before ({d}, {d})\n", .{ line, before_value, value });
                    continue :outer_loop;
                }

                if ((maybe_good == null) and (maybe_bad == null)) {
                    try io.stdout.print("INFO: order cannot be decided for this pair\n", .{});
                    @panic("PANIC: undefined order\n");
                }
            }

            // Check these value are more
            for (idx0 + 1..numbers.items.len) |idx_after| {
                const after_value = numbers.items[idx_after];
                const correct_rule = OrderRule{ .first = value, .second = after_value };
                const wrong_rule = OrderRule{ .first = after_value, .second = value };
                const maybe_good = rules.get(correct_rule);
                const maybe_bad = rules.get(wrong_rule);

                // We skip maybe_good because if it is non-null,
                // then there is no action to take

                if (maybe_bad != null) {
                    try io.stderr.print("DEBUG: the line {s} is NOT valid because of after ({d}, {d})\n", .{ line, value, after_value });
                    continue :outer_loop;
                }

                if ((maybe_good == null) and (maybe_bad == null)) {
                    try io.stdout.print("INFO: order cannot be decided for this pair\n", .{});
                    @panic("PANIC: undefined order\n");
                }
            }
        }

        try io.stderr.print("DEBUG: the line {s} is valid\n", .{line});

        if ((numbers.items.len % 2) == 0) {
            @panic("PANIC: found value line but it is of even lenght\n");
        }
        const middle_index: usize = @divTrunc(numbers.items.len, 2);
        try io.stderr.print("\tDEBUG: adding {d} to the total\n", .{numbers.items[middle_index]});
        total += numbers.items[middle_index];
    }

    try io.stdout.print("INFO: The solution to puzzle 09 is: {d}\n", .{total});

    return;
}
