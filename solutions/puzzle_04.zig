const std = @import("std");
const io = @import("io.zig");

const RetReport = struct {
    index: usize,
    is_safe: bool,
};

const input_filename: []const u8 = "input.txt";
// const input_filename: []const u8 = "example-input.txt";
// const input_filename: []const u8 = "example-input-2.txt";

const MAX_LINE_LENGTH = 64;
var LINE_MEMORY_BUFFER: [MAX_LINE_LENGTH]u8 = undefined;

pub fn isReportSafe(report: std.ArrayList(i32)) RetReport {
    if (report.items.len < 1) {
        return RetReport{ .index = 0, .is_safe = false };
    }

    if (report.items[0] == report.items[1]) {
        return RetReport{ .index = 0, .is_safe = false };
    } else if (report.items[0] < report.items[1]) {
        for (1..report.items.len) |idx| {
            const a = report.items[idx - 1];
            const b = report.items[idx];
            if ((a >= b) or ((b - a) > 3)) {
                return RetReport{ .index = idx, .is_safe = false };
            }
        }
    } else {
        for (1..report.items.len) |idx| {
            const a = report.items[idx - 1];
            const b = report.items[idx];
            if ((b >= a) or ((a - b) > 3)) {
                return RetReport{ .index = idx, .is_safe = false };
            }
        }
    }

    return RetReport{ .index = 0, .is_safe = true };
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    arena.deinit();
    const allocator = arena.allocator();

    // Initial variables
    var total: usize = 0;

    // Open current working directory and a relative directory form it
    var cwd = std.fs.cwd();
    const things_to_join = [2][]const u8{ "puzzles", "04" };
    const rel_dir_path = try std.fs.path.join(allocator, &things_to_join);
    try io.stderr.print("DEBUG: join results into relative path: {s}\n", .{rel_dir_path});
    var puzzle_dir = try cwd.openDir(rel_dir_path, .{ .iterate = false });

    // Open a file and create a buffered reader for it
    var file = try puzzle_dir.openFile(input_filename, .{ .mode = .read_only });
    defer file.close();
    var buf_reader = std.io.bufferedReader(file.reader());
    var file_reader = buf_reader.reader();

    // Create a line (as an ArrayList) using a FixedBufferAllocator to hold its memory
    var fba_line = std.heap.FixedBufferAllocator.init(&LINE_MEMORY_BUFFER);
    const line_allocator = fba_line.allocator();
    var line = try std.ArrayList(u8).initCapacity(line_allocator, MAX_LINE_LENGTH);
    defer line.deinit();

    var line_index: usize = 0;
    while (file_reader.streamUntilDelimiter(line.writer(), '\n', MAX_LINE_LENGTH)) {
        // Parse report
        var report = try std.ArrayList(i32).initCapacity(allocator, 16);
        var it = std.mem.splitSequence(u8, line.items, " ");
        while (it.next()) |item| {
            const value_i = try std.fmt.parseInt(i32, item, 10);
            try report.append(value_i);
        }

        // Decide if it is safe
        const ret_report: RetReport = isReportSafe(report);
        if (ret_report.is_safe) {
            total += 1;
            // try io.stderr.print("{d}\n", .{line_index});
        } else { // Give it another try
            var new_report1 = try std.ArrayList(i32).initCapacity(std.heap.page_allocator, report.items.len);
            var new_report2 = try std.ArrayList(i32).initCapacity(std.heap.page_allocator, report.items.len);
            for (report.items) |item| {
                try new_report1.append(item);
                try new_report2.append(item);
            }

            // try io.stderr.print("before {d}\n", .{report.items});
            _ = report.orderedRemove(ret_report.index);
            // try io.stderr.print("after report {d}\n", .{report.items});

            var new_report_index_to_remove = ret_report.index;
            if (new_report_index_to_remove > 0) {
                new_report_index_to_remove -= 1;
            }
            _ = new_report1.orderedRemove(new_report_index_to_remove);
            // try io.stderr.print("after new {d}\n", .{new_report1.items});

            _ = new_report2.orderedRemove(0);
            // try io.stderr.print("DEBUG: after new 2 {d}\n", .{new_report2.items});

            const second_ret_report: RetReport = isReportSafe(report);
            const third_ret_report: RetReport = isReportSafe(new_report1);
            // In case the first element is removed, the ascending or descending rule could change
            const fourth_ret_report: RetReport = isReportSafe(new_report2);
            if (second_ret_report.is_safe or third_ret_report.is_safe or fourth_ret_report.is_safe) {
                total += 1;
                try io.stderr.print("DEBUG: {d}\n", .{line_index});
                try io.stderr.print("DEBUG: correct\n---\n", .{});
            }
        }

        line.clearRetainingCapacity();
        line_index += 1;
    } else |err| switch (err) {
        error.EndOfStream => {},
        else => {},
    }

    try io.stdout.print("INFO: The solution to puzzle 04 is: {d}\n", .{total});

    return;
}
