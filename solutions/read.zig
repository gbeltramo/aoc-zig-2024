const std = @import("std");

pub fn abs_file_line_by_line(abs_path: []const u8, max_char_per_line: usize, allocator: std.mem.Allocator) !std.ArrayList([]const u8) {
    var file = try std.fs.openFileAbsolute(abs_path, .{ .mode = .read_only });
    defer file.close();

    return stream_and_allocate_lines(file, max_char_per_line, allocator);
}

pub fn rel_file_line_by_line(rel_path: []const u8, max_char_per_line: usize, allocator: std.mem.Allocator) !std.ArrayList([]const u8) {
    var cwd = std.fs.cwd();
    var file = try cwd.openFile(rel_path, .{ .mode = .read_only });
    defer file.close();

    const lines = stream_and_allocate_lines(file, max_char_per_line, allocator);
    return lines;
}

fn stream_and_allocate_lines(file: std.fs.File, max_char_per_line: usize, allocator: std.mem.Allocator) !std.ArrayList([]const u8) {
    var buf_reader = std.io.bufferedReader(file.reader());
    const file_reader = buf_reader.reader();
    var lines = try std.ArrayList([]const u8).initCapacity(allocator, 128);

    var line = try std.ArrayList(u8).initCapacity(allocator, 128);
    const writer = line.writer();

    while (file_reader.streamUntilDelimiter(writer, '\n', max_char_per_line)) {
        var copied_line = try allocator.alloc(u8, line.items.len);
        @memcpy(copied_line[0..], line.items[0..]);
        try lines.append(copied_line);
        defer line.clearRetainingCapacity();
    } else |err| switch (err) {
        error.EndOfStream => {},
        else => return err,
    }

    return lines;
}
