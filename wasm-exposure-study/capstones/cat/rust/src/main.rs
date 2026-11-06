use std::io::{self, Write};

fn main() {
    let mut out = io::stdout().lock();
    io::copy(&mut io::stdin().lock(), &mut out).unwrap();
    out.flush().unwrap();
}
