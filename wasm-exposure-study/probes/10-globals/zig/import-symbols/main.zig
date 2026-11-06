extern "host" const base: i32;
export var counter: i32 = 0;

export fn bump() i32 {
    counter = base + 1;
    return counter;
}
