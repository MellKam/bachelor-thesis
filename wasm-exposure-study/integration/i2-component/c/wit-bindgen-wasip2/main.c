#include "gen/words_world.h"

static int is_ws(uint8_t c) { return c == ' ' || c == '\t' || c == '\n' || c == '\r'; }

void exports_study_words_words_analyse(words_world_string_t *text, exports_study_words_words_stats_t *ret) {
  uint32_t words = 0, best = 0, best_at = 0, i = 0;
  while (i < text->len) {
    while (i < text->len && is_ws(text->ptr[i])) i++;
    uint32_t start = i;
    while (i < text->len && !is_ws(text->ptr[i])) i++;
    if (i > start) {
      words++;
      if (i - start > best) { best = i - start; best_at = start; }
    }
  }
  ret->words = words;
  ret->bytes = (uint32_t)text->len;
  words_world_string_dup_n(&ret->longest, (const char *)text->ptr + best_at, best);
  words_world_string_free(text);
}
