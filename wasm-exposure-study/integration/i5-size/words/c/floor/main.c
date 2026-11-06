/* `words`, floor ABI: export memory, alloc(len) -> ptr, analyse(ptr, len) -> ptr to { words, bytes, longest_ptr, longest_len }. */
#define EXPORT(n) __attribute__((export_name(n)))
static unsigned char heap[1 << 20] __attribute__((aligned(8)));
static unsigned top;
static unsigned record[4];

EXPORT("alloc") unsigned char *alloc(unsigned len) {
  unsigned char *p = heap + top;
  top += (len + 7) & ~7u;
  return p;
}

static int is_ws(unsigned char c) { return c == ' ' || c == '\t' || c == '\n' || c == '\r'; }

EXPORT("analyse") unsigned *analyse(const unsigned char *s, unsigned len) {
  unsigned words = 0, best = 0, best_at = 0, i = 0;
  while (i < len) {
    while (i < len && is_ws(s[i])) i++;
    unsigned start = i;
    while (i < len && !is_ws(s[i])) i++;
    if (i > start) {
      words++;
      if (i - start > best) { best = i - start; best_at = start; }
    }
  }
  top = 0;
  record[0] = words; record[1] = len; record[2] = (unsigned)(s + best_at); record[3] = best;
  return record;
}
