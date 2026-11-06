use wasm_bindgen::prelude::*;

#[wasm_bindgen]
pub struct Stats {
    pub words: u32,
    pub bytes: u32,
    longest: String,
}

#[wasm_bindgen]
impl Stats {
    #[wasm_bindgen(getter)]
    pub fn longest(&self) -> String {
        self.longest.clone()
    }
}

#[wasm_bindgen]
pub fn analyse(text: &str) -> Stats {
    let mut words = 0;
    let mut longest = "";
    for w in text.split(|c: char| matches!(c, ' ' | '\t' | '\n' | '\r')).filter(|w| !w.is_empty()) {
        words += 1;
        if w.len() > longest.len() {
            longest = w;
        }
    }
    Stats { words, bytes: text.len() as u32, longest: longest.to_string() }
}
