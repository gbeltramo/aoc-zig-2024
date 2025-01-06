pub fn swap_integers(slice: []u32, idx1: usize, idx2: usize) void {
    const tmp = slice[idx1];
    slice[idx1] = slice[idx2];
    slice[idx2] = tmp;
    return;
}
