use std::panic::catch_unwind;

// The only stable "catch" in the language: catch_unwind. On wasm32-unknown-unknown panics abort.
#[unsafe(no_mangle)]
pub extern "C" fn roundtrip(x: i32) -> i32 {
    match catch_unwind(|| {
        if x >= 0 {
            panic!("boom")
        }
        x
    }) {
        Ok(v) => v,
        Err(_) => x,
    }
}
