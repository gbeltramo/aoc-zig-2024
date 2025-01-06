const std = @import("std");

pub fn as_column_array(lines: std.ArrayList([]const u8), locations: *std.ArrayList(u32), column_idx: usize) !void {
    for (lines.items[0..]) |line| {
        var it = std.mem.splitSequence(u8, line, "   ");
        var locations_idx: u2 = 0;
        while (it.next()) |x| {
            const num = try std.fmt.parseInt(u32, x, 10);

            if (locations_idx == column_idx) {
                try locations.append(num);
            }

            locations_idx += 1;
        }
    }
}
