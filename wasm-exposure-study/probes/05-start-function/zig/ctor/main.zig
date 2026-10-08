var g: i32 = 0;

fn init() callconv(.c) void {
    g = 7;
}

export const init_entry linksection(".init_array") = &init;

export fn get() i32 {
    return @as(*volatile i32, &g).*;
}
