#include <emscripten/bind.h>
#include <string>

struct Stats {
  unsigned words;
  unsigned bytes;
  std::string longest;
};

static bool is_ws(unsigned char c) { return c == ' ' || c == '\t' || c == '\n' || c == '\r'; }

Stats analyse(const std::string &text) {
  Stats r{0, (unsigned)text.size(), ""};
  size_t best = 0, best_at = 0, i = 0;
  while (i < text.size()) {
    while (i < text.size() && is_ws(text[i])) i++;
    size_t start = i;
    while (i < text.size() && !is_ws(text[i])) i++;
    if (i > start) {
      r.words++;
      if (i - start > best) { best = i - start; best_at = start; }
    }
  }
  r.longest = text.substr(best_at, best);
  return r;
}

EMSCRIPTEN_BINDINGS(words) {
  emscripten::value_object<Stats>("Stats")
      .field("words", &Stats::words)
      .field("bytes", &Stats::bytes)
      .field("longest", &Stats::longest);
  emscripten::function("analyse", &analyse);
}
