wit_bindgen::generate!({ path: "../../../wit/words.wit", world: "words-world" });

use exports::study::words::words::{Guest, Stats};

struct Words;

impl Guest for Words {
    fn analyse(text: String) -> Stats {
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
}

export!(Words);
