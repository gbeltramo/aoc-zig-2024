const std = @import("std");
const assert = std.debug.assert;
const io = @import("io.zig");

var input_path_parts = [3][]const u8{ "puzzles", "18", "input.txt" };
// var input_path_parts = [3][]const u8{ "puzzles", "18", "example-input.txt" };

const FILL_VALUE: usize = 65_535;

const Contents = struct {
    buffer: []u8,
    len: usize,
};

const Block = struct {
    start_index: usize,
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
    const max_bytes_to_read: usize = 65_535;
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
    try io.stderr.print("DEBUG: Initial disk[0..20]={any}\n", .{disk[0..20]}); // Note: debug
    // try io.stderr.print("DEBUG: Initial disk[-20..]={any}\n", .{disk[disk.len - 20 .. disk.len]}); // Note: debug
    // try io.stderr.print("DEBUG: ------------------------------\n\n", .{}); // Note: debug
    // <<<

    // >>> Find empty blocks going up
    var empty_blocks = try std.ArrayList(Block).initCapacity(allocator, 10_000);
    defer empty_blocks.deinit();

    var start_index: usize = 0;
    assert(disk[start_index] != FILL_VALUE);
    while ((start_index + 1) < disk.len) {
        // try io.stderr.print("DEBUG: start_index={d}\n", .{start_index}); // Note: debug
        while ((disk[start_index] != FILL_VALUE) and ((start_index + 1) < disk.len)) {
            start_index += 1;
        }
        var len: usize = 0;
        while ((disk[start_index + len] == FILL_VALUE) and ((start_index + 1) < disk.len)) {
            len += 1;
        }

        if ((disk[start_index + len] == FILL_VALUE) and (start_index == (disk.len - 1))) {
            len += 1;
        }

        if (len > 0) {
            try empty_blocks.append(Block{ .start_index = start_index, .len = len });
            start_index += len;
        }
    }
    // <<<

    // // >>> Debug
    // try io.stderr.print("DEBUG: found {d} empty_blocks\n", .{empty_blocks.items.len}); // Note: debug
    // for (0..3) |idx| { // Note: debug
    //     try io.stderr.print("\tDEBUG: found empty_blocks.items[{d}]={any}\n", .{ idx, empty_blocks.items[idx] }); // Note: debug
    // }
    // for (0..3) |idx| { // Note: debug
    //     const inv_idx = empty_blocks.items.len - 1 - idx; // Note: debug
    //     try io.stderr.print("\tDEBUG: found empty_blocks.items[{d}]={any}\n", .{ inv_idx, empty_blocks.items[inv_idx] }); // Note: debug
    // }
    // // <<<

    // >>> Find file blocks going down
    var file_blocks = try allocator.alloc(Block, 10_000);
    for (0..10_000) |i| {
        file_blocks[i] = Block{ .start_index = 0, .len = 0 };
    }
    var len_file_blocks: usize = 0;
    defer allocator.free(file_blocks);

    file_index = disk.len - 1;
    assert(disk[file_index] != FILL_VALUE);

    while (file_index > 0) {
        // try io.stderr.print("DEBUG: file_index={d}\n", .{file_index}); // Note: debug
        while ((disk[file_index] == FILL_VALUE) and (file_index > 0)) {
            file_index -= 1;
        }
        var len: usize = 0;
        file_id = disk[file_index - len];
        while ((disk[file_index - len] == file_id) and ((file_index - len) > 0)) {
            len += 1;
        }

        if ((disk[file_index - len] == file_id) and ((file_index - len) == 0)) {
            len += 1;
        }

        file_blocks[len_file_blocks] = Block{
            .start_index = file_index + 1 - len,
            .len = len,
        };
        len_file_blocks += 1;

        if (len < file_index) {
            file_index -= len;
        } else {
            file_index = 0;
        }
    }
    // <<<

    // // >>> Debug
    // try io.stderr.print("DEBUG: found {d} file_blocks\n", .{file_blocks.items.len}); // Note: debug
    // for (0..3) |idx| { // Note: debug
    //     const inv_idx = file_blocks.items.len - 1 - idx; // Note: debug
    //     try io.stderr.print("\tDEBUG: found file_blocks.items[{d}]={any}\n", .{ inv_idx, file_blocks.items[inv_idx] }); // Note: debug
    // }
    // for (0..3) |idx| { // Note: debug
    //     try io.stderr.print("\tDEBUG: found file_blocks.items[{d}]={any}\n", .{ idx, file_blocks.items[idx] }); // Note: debug
    // }
    // // <<<

    // >>> Run defragmentation of disk
    next_file_to_move: for (0..len_file_blocks) |idx| {
        const file_block_to_move = file_blocks[idx];
        file_id = disk[file_block_to_move.start_index];
        for (0..empty_blocks.items.len) |idx_empty| {
            const empty_block = empty_blocks.items[idx_empty];
            if (empty_block.start_index > file_block_to_move.start_index) {
                continue :next_file_to_move;
            }

            if (empty_block.len >= file_block_to_move.len) {
                for (empty_block.start_index..empty_block.start_index + file_block_to_move.len) |i| {
                    disk[i] = file_id;
                }

                for (file_block_to_move.start_index..file_block_to_move.start_index + file_block_to_move.len) |i| {
                    disk[i] = FILL_VALUE;
                }

                empty_blocks.items[idx_empty].start_index += file_block_to_move.len;
                empty_blocks.items[idx_empty].len -= file_block_to_move.len;

                continue :next_file_to_move;
            }
        }
    }
    // <<<

    // >>> Compute checksum
    var checksum: usize = 0;
    for (0..disk.len) |i| {
        if (disk[i] != FILL_VALUE) {
            checksum += disk[i] * i;
        }
    }
    // <<<

    // >>> Print solution of puzzle to STDOUT
    try io.stdout.print("INFO: The solution to puzzle 18 is: {d}\n", .{checksum});
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
