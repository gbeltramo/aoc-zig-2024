const std = @import("std");
const print = std.debug.print;
const io = @import("io.zig");

const input_filename: []const u8 = "input.txt";
// const input_filename: []const u8 = "example-input.txt";

const MAX_LINE_LENGTH = 64;
var LINE_MEMORY_BUFFER: [MAX_LINE_LENGTH]u8 = undefined;

pub fn isReportSafe(line: std.ArrayList(u8), allocator: std.mem.Allocator) !bool {
    var report = try std.ArrayList(i32).initCapacity(allocator, 16);
    var it = std.mem.splitSequence(u8, line.items, " ");
    while (it.next()) |item| {
        const value_i = try std.fmt.parseInt(i32, item, 10);
        try report.append(value_i);
    }

    if (report.items.len < 2) {
        return false;
    }

    if (report.items[0] == report.items[1]) {
        return false;
    } else if (report.items[0] < report.items[1]) {
        for (1..report.items.len) |idx| {
            const a = report.items[idx - 1];
            const b = report.items[idx];
            if ((a >= b) or ((b - a) > 3)) {
                return false;
            }
        }
    } else {
        for (1..report.items.len) |idx| {
            const a = report.items[idx - 1];
            const b = report.items[idx];
            if ((b >= a) or ((a - b) > 3)) {
                return false;
            }
        }
    }

    return true;
}

pub fn main() !void {
    var fba_line = std.heap.FixedBufferAllocator.init(&LINE_MEMORY_BUFFER);
    const line_allocator = fba_line.allocator();

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    arena.deinit();
    const allocator = arena.allocator();

    // Initial variables
    var total: usize = 0;

    // Open current working directory and a relative directory form it
    var cwd = std.fs.cwd();
    const things_to_join = [2][]const u8{ "puzzles", "03" };
    const rel_dir_path = try std.fs.path.join(allocator, &things_to_join);
    try io.stderr.print("DEBUG: join results into relative path: {s}\n", .{rel_dir_path});
    var puzzle_dir = try cwd.openDir(rel_dir_path, .{ .iterate = false });

    // Open a file and create a buffered reader for it
    var file = try puzzle_dir.openFile(input_filename, .{ .mode = .read_only });
    defer file.close();
    var buf_reader = std.io.bufferedReader(file.reader());
    const file_reader = buf_reader.reader();
    try io.stderr.print("DEBUG: got file.handle={}\n", .{file.handle});

    // Create a line (as an ArrayList) using a FixedBufferAllocator to hold its memory
    var line = try std.ArrayList(u8).initCapacity(line_allocator, MAX_LINE_LENGTH);
    defer line.deinit();

    while (file_reader.streamUntilDelimiter(line.writer(), '\n', MAX_LINE_LENGTH)) {
        const report_is_safe = try isReportSafe(line, std.heap.page_allocator);
        if (report_is_safe) {
            total += 1;
        }
        line.clearRetainingCapacity();
    } else |err| switch (err) {
        error.EndOfStream => {},
        else => {},
    }

    try io.stdout.print("INFO: The solution to puzzle 03 is: {d}\n", .{total});

    return;
}
