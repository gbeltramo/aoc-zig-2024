/// We iterate on the subdirectories of ./puzzles to find which source files to compile
/// Then we compile one executable for each ./solutions/puzzle_<XY>.zig
/// Note: it is assumed that "zig build" will run from the root of the repo
const std = @import("std");

const MAX_LENGTH_FMT: comptime_int = 64;

fn findNumberOfPuzzlePrograms(rel_path_to_dir: []const u8) !usize {
    var dir = try std.fs.cwd().openDir(rel_path_to_dir, .{
        .iterate = true,
        .no_follow = true,
    });
    defer dir.close();

    const stdout = std.io.getStdErr().writer();
    var iterator_dir = dir.iterate();
    var num_puzzle_programs: usize = 0;
    while (try iterator_dir.next()) |entry| {
        try stdout.print("INFO: Found subdir={s}/ in dir ./{s}/\n", .{ entry.name, rel_path_to_dir });
        num_puzzle_programs += 1;
    }

    return num_puzzle_programs;
}

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const N = findNumberOfPuzzlePrograms("./puzzles") catch unreachable;
    for (1..N + 1) |idx_puzzle| {
        var puzzle_name_array: [MAX_LENGTH_FMT]u8 = undefined;
        for (0..MAX_LENGTH_FMT) |idx_array| {
            puzzle_name_array[idx_array] = 0;
        }
        const puzzle_name = std.fmt.bufPrint(&puzzle_name_array, "puzzle_{0d:0>2}", .{idx_puzzle}) catch unreachable;

        var puzzle_src_path_array: [MAX_LENGTH_FMT]u8 = undefined;
        for (0..MAX_LENGTH_FMT) |idx_array| {
            puzzle_src_path_array[idx_array] = 0;
        }
        const puzzle_src_path = std.fmt.bufPrint(&puzzle_src_path_array, "solutions/puzzle_{0d:0>2}.zig", .{idx_puzzle}) catch unreachable;

        const puzzle_exe = b.addExecutable(.{
            .name = puzzle_name,
            .root_source_file = b.path(puzzle_src_path),
            .target = target,
            .optimize = optimize,
        });
        b.installArtifact(puzzle_exe);
    }
}
