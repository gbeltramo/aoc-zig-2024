const std = @import("std");
const assert = std.debug.assert;
const io = @import("io.zig");

var input_path_parts = [3][]const u8{ "puzzles", "17", "input.txt" };
// var input_path_parts = [3][]const u8{ "puzzles", "17", "example-input.txt" };

const FILL_VALUE: usize = 65_535;

const Contents = struct {
    buffer: []u8,
    len: usize,
};

/// Read the whole contents of a file
fn readWholeFile(path_parts: [][]const u8, max_bytes_to_read: usize, allocator: std.mem.Allocator) !Contents {
    var cwd = std.fs.cwd();

    const rel_path = try std.fs.path.join(allocator, path_parts);
    const file = try cwd.openFile(rel_path, .{});

    var buffer = try allocator.alloc(u8, max_bytes_to_read);
    for (0..max_bytes_to_read) |i| {
        buffer[i] = 0;
    }

    const num_bytes_read = try file.readAll(buffer);
    const contents = Contents{
        .buffer = buffer,
        .len = num_bytes_read,
    };

    try io.stderr.print("DEBUG: readWholeFile() got {d} bytes from the file\n", .{num_bytes_read}); // Note: debug

    allocator.free(rel_path);
    file.close();

    return contents;
}

pub fn main() !void {
    // >>> Create Arena allocator used for everything
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    // <<<

    // >>> Read input
    const max_bytes_to_read: usize = 65_536;
    const contents = try readWholeFile(
        &input_path_parts,
        max_bytes_to_read,
        allocator,
    );
    defer allocator.free(contents.buffer);
    assert(contents.len < FILL_VALUE);
    // <<<

    // >>> Define table to convert strings of digits into digits, e.g. "0" to 0
    // >>> Note that ASCII digits are in the range [48, 57].
    var parse_int_table: [64]u8 = undefined;
    for (0..64) |i| {
        parse_int_table[i] = 0;
    }
    for (48..58, 0..) |index, digit| {
        parse_int_table[index] = @as(u8, @intCast(digit));
    }
    // try io.stderr.print("DEBUG: parse_int_table={any}\n", .{parse_int_table}); // Note: debug
    // <<<

    // >>> Convert input found in file into a slice of integers values
    const disk_map: []u8 = try allocator.alloc(u8, contents.len);
    defer allocator.free(disk_map);
    for (0..contents.len) |i| {
        disk_map[i] = parse_int_table[contents.buffer[i]];
    }
    try io.stderr.print("DEBUG: First 10 parsed unsigned integers: {any}\n", .{disk_map[0..10]}); // Note: debug
    // <<<

    // >>> Use `file_id` numbers to create the array of file blocks on disk
    var total_size: usize = 0;
    for (disk_map) |file_size| {
        total_size += file_size;
    }
    var disk = try allocator.alloc(usize, total_size);
    defer allocator.free(disk);
    // Comment: we use 10 as a fill value, i.e. "."
    for (0..disk.len) |i| {
        disk[i] = FILL_VALUE;
    }
    var map_index: usize = 0;
    var file_id: usize = 0;
    var file_index: usize = 0;
    var num_id_items: u8 = 0;
    var num_skip_items: u8 = 0;
    while (map_index < disk_map.len) {
        num_id_items = disk_map[map_index];
        num_skip_items = disk_map[map_index + 1];

        for (file_index..file_index + num_id_items) |i| {
            disk[i] = file_id;
        }

        file_index += num_id_items + num_skip_items;

        file_id += 1;
        map_index += 2;
    }

    try io.stderr.print("DEBUG: Allocated {d} usize integers to represent disk space\n", .{disk.len}); // Note: debug
    try io.stderr.print("DEBUG: disk[0..30]={any}\n", .{disk[0..30]}); // Note: debug
    // <<<

    // >>> Run defragmentation of disk
    var up_index: usize = 0;
    var down_index: usize = disk.len - 1;

    while ((up_index + 1) < down_index) {
        while ((disk[up_index] != FILL_VALUE) and ((up_index + 1) < down_index)) {
            up_index += 1;
        }

        while ((disk[down_index] == FILL_VALUE) and ((up_index + 1) < down_index)) {
            down_index -= 1;
        }

        disk[up_index] = disk[down_index];
        up_index += 1;
        down_index -= 1;
    }

    // Comment: we finish the loop above with (up_index, up_index+1, up_index+2=down_index).
    // So one index is in an undefined state. We fix that here.
    if (disk[up_index] != FILL_VALUE) {
        up_index += 1;
    }

    try io.stderr.print("DEBUG: Defragmentation completed with disk[up_index-20..up_index]={any}\n", .{disk[up_index - 20 .. up_index]}); // Note: debug
    // <<<

    // >>> Compute checksum
    var checksum: usize = 0;
    for (0..up_index) |i| {
        checksum += disk[i] * i;
    }
    // <<<

    // >>> Print solution of puzzle to STDOUT
    try io.stdout.print("INFO: The solution to puzzle 17 is: {d}\n", .{checksum});
    // <<<

    // >>> Final clean up of resources
    for (0..contents.buffer.len) |i| {
        contents.buffer[i] = 0;
    }
    for (0..disk.len) |i| {
        disk[i] = 0;
    }
    // <<<

    return;
}
