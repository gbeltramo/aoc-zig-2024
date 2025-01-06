const std = @import("std");
const utils = @import("utils.zig");

/// Quick sort of ArrayList of u32 integers. TODO: make this more generic
pub fn integers_inplace(numbers: std.ArrayList(u32), start_index: usize, end_index: usize) !void {
    if (end_index < (start_index + 1)) {
        return;
    } else if (end_index == (start_index + 1)) {
        if (numbers.items[start_index] > numbers.items[end_index]) {
            utils.swap_integers(numbers.items, start_index, end_index);
        }
    } else {
        const pivot: u32 = numbers.items[start_index];
        var pivot_index: usize = start_index;
        var front_index: usize = start_index + 1;

        while (front_index <= end_index) {
            const front = numbers.items[front_index];
            if (front < pivot) {
                utils.swap_integers(numbers.items, pivot_index + 1, front_index);
                pivot_index += 1;
            }
            front_index += 1;
        }

        utils.swap_integers(numbers.items, start_index, pivot_index);

        if (pivot_index > 0) {
            try integers_inplace(numbers, start_index, pivot_index - 1);
        }
        try integers_inplace(numbers, pivot_index + 1, end_index);
    }

    return;
}
