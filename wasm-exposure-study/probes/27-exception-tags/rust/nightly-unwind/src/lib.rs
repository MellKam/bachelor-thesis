use std::panic::{catch_unwind, resume_unwind};

#[unsafe(no_mangle)]
pub extern "C" fn roundtrip(x: i32) -> i32 {
    match catch_unwind(|| { resume_unwind(Box::new(x)) }) {
        Ok(()) => -1,
        Err(e) => *e.downcast::<i32>().unwrap(),
    }
}
