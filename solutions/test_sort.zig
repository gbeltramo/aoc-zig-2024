const std = @import("std");
const expect = std.testing.expect;

const sort = @import("sort.zig");

// Sorting 10 integer values in an ArrayList
test "sort_u32_v1" {
    const length: usize = 10;
    const array = [_]u32{ 3, 5, 1, 8, 4, 6, 9, 2, 7, 0 };
    const sorted_array = [_]u32{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 };

    var numbers = try std.ArrayList(u32).initCapacity(std.heap.page_allocator, length);
    for (0..length) |idx| {
        try numbers.append(array[idx]);
    }
    try sort.integers_inplace(numbers, 0, length - 1);

    for (0..length) |idx| {
        try expect(numbers.items[idx] == sorted_array[idx]);
    }
}
