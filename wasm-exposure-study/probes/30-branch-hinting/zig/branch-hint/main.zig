export fn classify(x: i32) i32 {
    if (x < 0) {
        @branchHint(.unlikely); // the rare branch
        return -1;
    }
    return x * 2;
}
