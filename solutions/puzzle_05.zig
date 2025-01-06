const std = @import("std");
const five_utils = @import("five_utils.zig");
const io = @import("io.zig");

const RetReport = struct {
    index: usize,
    is_safe: bool,
};

const input_filename: []const u8 = "input.txt";
// const input_filename: []const u8 = "example-input.txt";

const max_content_length = 200_000;
var content_buffer: [max_content_length]u8 = undefined;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    arena.deinit();
    const allocator = arena.allocator();

    // Initial variables
    var total: i64 = 0;

    // Open current working directory and a relative directory form it
    var cwd = std.fs.cwd();
    const things_to_join = [2][]const u8{ "puzzles", "05" };
    const rel_dir_path = try std.fs.path.join(allocator, &things_to_join);
    try io.stderr.print("DEBUG: join results into relative path: {s}\n", .{rel_dir_path});
    var puzzle_dir = try cwd.openDir(rel_dir_path, .{ .iterate = false });

    // Open a file and create a buffered reader for it
    var file = try puzzle_dir.openFile(input_filename, .{ .mode = .read_only });
    defer file.close();
    var buf_reader = std.io.bufferedReader(file.reader());
    var file_reader = buf_reader.reader();
    _ = try file_reader.readAll(&content_buffer);
    // try io.stderr.print("Num bytes: {d}\n", .{num_bytes_read});
    // try io.stderr.print("Contents\n{s}\n", .{&content_buffer});

    const content: []u8 = &content_buffer;
    for (0..content.len) |idx| {
        const c: u8 = content[idx];
        if (c == 0) {
            break;
        }
        if (five_utils.isStartMul(content, idx)) {
            const next_par_idx = five_utils.findNextClosePar(content, idx + 4);
            const numbers: []u8 = content[idx + 4 .. next_par_idx];

            // Do not use if there is a space
            var need_to_continue = false;
            for (0..numbers.len) |idx_j| {
                if (numbers[idx_j] == 32) {
                    need_to_continue = true;
                    break;
                }
            }
            if (need_to_continue) {
                continue;
            }

            // try io.stderr.print("numbers={s}\n", .{numbers});

            var it = std.mem.splitSequence(u8, numbers, ",");
            const str_num1 = it.next() orelse "no-number";
            const str_num2 = it.next() orelse "no-number";
            const must_be_null = it.next();

            if (must_be_null != null) {
                // try io.stderr.print("must_be_null: {?s}\n", .{must_be_null});
                continue;
            }
            const num1 = std.fmt.parseInt(i64, str_num1, 10) catch -1;
            const num2 = std.fmt.parseInt(i64, str_num2, 10) catch -1;

            if (num1 == -1 or num2 == -1) {
                continue;
            }
            try io.stderr.print("DEBUG: {d} {d}\n", .{ num1, num2 });

            const delta: i64 = num1 * num2;
            total += delta;
        }
    }

    try io.stdout.print("INFO: The solution to puzzle 05 is: {d}\n", .{total});

    return;
}
