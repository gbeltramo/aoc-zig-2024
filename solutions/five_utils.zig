/// Check if "mul(\d{0,3}, \d{0,3})" is present in `content` at index `current_idx`
pub fn isStartMul(content: []u8, current_idx: usize) bool {
    const has_m: bool = (content[current_idx] == 109);
    const has_u: bool = (content[current_idx + 1] == 117);
    const has_l: bool = (content[current_idx + 2] == 108);
    const has_par: bool = (content[current_idx + 3] == 40);
    return has_m and has_u and has_l and has_par;
}

/// Check if a "do()" is present in `content` at index `current_idx`
pub fn isDo(content: []u8, current_idx: usize) bool {
    const char_values = [4]u8{ 100, 111, 40, 41 };
    for (0..4) |idx_i| {
        if (content[current_idx + idx_i] != char_values[idx_i]) {
            return false;
        }
    }
    return true;
}

/// Check if a "don't()" is present in `content` at index `current_idx`
pub fn isDont(content: []u8, current_idx: usize) bool {
    const char_values = [7]u8{ 100, 111, 110, 39, 116, 40, 41 };
    for (0..7) |idx_i| {
        if (content[current_idx + idx_i] != char_values[idx_i]) {
            return false;
        }
    }
    return true;
}

/// Find the last index in `content` of a charactor before a ")"
pub fn findNextClosePar(content: []u8, current_idx: usize) usize {
    var next_par_idx: usize = current_idx;

    for (current_idx..content.len) |idx_i| {
        const c: u8 = content[idx_i];
        if ((c == 0) or (c == 41)) {
            break;
        }
        next_par_idx += 1;
    }

    return next_par_idx;
}
