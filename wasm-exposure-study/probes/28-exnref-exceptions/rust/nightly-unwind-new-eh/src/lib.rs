use std::panic::{catch_unwind, resume_unwind};

#[unsafe(no_mangle)]
pub extern "C" fn rethrow_test(x: i32) -> i32 {
    let outer = catch_unwind(|| {
        match catch_unwind(|| resume_unwind(Box::new(x))) {
            Ok(()) => 0,
            Err(e) => resume_unwind(e), // throw the captured exception again
        }
    });
    match outer {
        Ok(_) => -1,
        Err(e) => *e.downcast::<i32>().unwrap(),
    }
}
