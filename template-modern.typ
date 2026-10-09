// Shared thesis template. Everything about page layout, typography and front
// matter lives here, so a university template can be matched later by editing
// this one file (and `meta` in main-*.typ), never the chapters.
//
// Design notes. Text is strictly neutral: near-black ink, greys for secondary
// information, no colour in headings, links or captions. Colour is reserved for
// the data in charts. Ideas borrowed on purpose:
//   - ilm:          tracked small-caps labels, a quiet footer carrying the chapter
//                   name, unhyphenated headings, luma-only fills and hairlines
//   - dmi-basilea:  an oversized chapter numeral next to a bold chapter title
//   - classicthesis/booktabs: generous leading, rules instead of boxes in tables
// Fonts: Libertinus Serif body and DejaVu Sans Mono code ship with Typst; Inter
// (headings, captions, labels) is vendored in fonts/ and needs `--font-path fonts`.

// ---------------------------------------------------------------------------
// Tunable layout parameters — the values most likely to be dictated by a
// department. Change them here.
// ---------------------------------------------------------------------------
#let layout = (
  paper: "a4",
  margin: (left: 3.0cm, right: 3.0cm, top: 2.8cm, bottom: 3.0cm),
  serif: ("Libertinus Serif", "New Computer Modern"),
  sans: ("Inter", "Libertinus Serif"),
  mono: "DejaVu Sans Mono",
  size: 11.5pt,
  leading: 0.72em,   // gap between lines
  spacing: 1.2em,    // gap between paragraphs (no first-line indent)
)

#let ink = luma(15)
#let muted = luma(105)
#let faint = luma(190)
#let hairline = luma(215)
#let sans = layout.sans

// Tracked small-caps label, e.g. "CHAPTER" or a footer chapter name.
#let caps(body, size: 0.68em) = text(font: sans, size: size, weight: "medium", tracking: 0.09em, fill: muted, upper(body))

// Drafting aid: `#todo[...]` shows a visible marker. Set to false for a clean PDF.
#let show-todos = true
#let todo(body) = if show-todos {
  box(
    fill: luma(245),
    stroke: (paint: muted, thickness: 0.6pt, dash: "dashed"),
    inset: (x: 4pt, y: 2pt),
    radius: 2pt,
    text(font: sans, size: 0.76em, fill: ink)[*TODO* #body],
  )
}

// A three-line ("booktabs") table with a sans header row. Pass `table.header(...)` first.
#let booktable(..args) = {
  show table.cell.where(y: 0): set text(font: sans, weight: "semibold", size: 0.8em)
  set text(size: 0.93em)
  table(
    stroke: none,
    inset: (x: 6pt, y: 5pt),
    table.hline(stroke: 1pt + ink),
    ..args,
    table.hline(stroke: 1pt + ink),
  )
}

// ---------------------------------------------------------------------------
// Whole-document rules
// ---------------------------------------------------------------------------
#let thesis(meta: (:), body) = {
  set document(title: meta.title, author: meta.author)
  set text(
    font: layout.serif,
    size: layout.size,
    fill: ink,
    lang: meta.at("lang", default: "en"),
  )
  set par(
    justify: true,
    linebreaks: "optimized",
    leading: layout.leading,
    spacing: layout.spacing,
  )

  // Page: a quiet footer with the chapter name (left) and page number (right).
  set page(
    paper: layout.paper,
    margin: layout.margin,
    footer-descent: 35%,
    footer: context {
      if here().page-numbering() == none { return }
      let starts = query(heading.where(level: 1)).map(h => h.location().page())
      let page-no = text(font: sans, size: 0.8em, weight: "medium", numbering(here().page-numbering(), ..counter(page).get()))
      let prior = query(heading.where(level: 1).before(here()))
      let name = if here().page() in starts or prior.len() == 0 { none } else { caps(prior.last().body) }
      line(length: 100%, stroke: 0.4pt + hairline)
      v(-0.2em)
      grid(columns: (1fr, auto), align: (left + horizon, right + horizon), name, page-no)
    },
  )

  // Headings: bold sans, neutral ink, never hyphenated.
  set heading(numbering: "1.1", supplement: [Section])
  show heading: set text(hyphenate: false, font: sans, fill: ink)
  show heading: set par(justify: false, leading: 0.45em)

  let numbered(it, size, weight, gap) = block(above: size * 1.7, below: size * 0.75, sticky: true, {
    set text(size: size, weight: weight)
    if it.numbering != none {
      text(fill: muted, weight: "regular", counter(heading).display(it.numbering))
      h(gap)
    }
    it.body
  })
  show heading.where(level: 2): it => numbered(it, 15pt, "semibold", 0.7em)
  show heading.where(level: 3): it => numbered(it, 12pt, "semibold", 0.6em)
  show heading.where(level: 4): it => block(above: 1.4em, below: 0.5em, sticky: true,
    text(size: 10.5pt, weight: "medium", style: "italic", it.body))

  // Chapters: a heavy rule, an oversized numeral beside a bold title.
  show heading.where(level: 1): it => {
    pagebreak(weak: true)
    // Figure, table and listing numbers restart in every chapter.
    for kind in (image, table, raw) { counter(figure.where(kind: kind)).update(0) }
    v(1.2cm)
    block(above: 0pt, below: 1.4cm, {
      line(length: 100%, stroke: 2.5pt + ink)
      v(0.7cm)
      if it.numbering != none {
        grid(
          columns: (auto, 1fr),
          column-gutter: 0.55cm,
          align: bottom,
          text(size: 62pt, weight: "bold", tracking: -0.02em, counter(heading).display(it.numbering)),
          pad(bottom: 0.45em, text(size: 25pt, weight: "bold", tracking: -0.01em, it.body)),
        )
      } else {
        text(size: 25pt, weight: "bold", tracking: -0.01em, it.body)
      }
    })
  }

  // Figures and tables: numbered per chapter (2.1, 2.2, ...); table captions on top;
  // captions are left-aligned sans, with a bold label.
  set figure(numbering: n => numbering("1.1", counter(heading).get().first(), n), gap: 1em)
  show figure.where(kind: table): set figure.caption(position: top)
  show figure.caption: it => align(left, {
    set text(font: sans, size: 8.5pt, fill: luma(55))
    set par(justify: false, leading: 0.55em)
    strong(it.supplement + [ ] + it.counter.display(it.numbering))
    h(0.6em)
    it.body
  })
  show figure: set block(above: 1.8em, below: 1.8em, breakable: false)
  set table(stroke: none)
  show table: set par(justify: false)

  // Code
  set raw(align: left)
  show raw: set text(font: layout.mono, size: 0.8em)
  show raw.where(block: false): it => box(fill: luma(240), outset: (x: 2pt, y: 3pt), radius: 2pt, it)
  show raw.where(block: true): it => block(
    width: 100%,
    fill: luma(248),
    stroke: (y: 0.5pt + hairline),
    inset: (x: 10pt, y: 9pt),
    { set align(left); it },
  )

  // Links stay in ink: external addresses get a hairline underline, references nothing.
  show link: it => underline(offset: 2pt, stroke: 0.4pt + muted, it)
  show ref: it => {
    let el = it.element
    // A reference to a chapter reads "Chapter 2"; everything else keeps its supplement.
    if el != none and el.func() == heading and el.level == 1 and el.numbering != none {
      link(el.location())[Chapter #numbering(el.numbering, ..counter(heading).at(el.location()))]
    } else { it }
  }

  set list(marker: [–], indent: 0.5em, body-indent: 0.7em, spacing: 0.8em)
  set enum(indent: 0.5em, body-indent: 0.7em, spacing: 0.8em)

  body
}

// ---------------------------------------------------------------------------
// Front matter
// ---------------------------------------------------------------------------
#let title-page(meta) = {
  set page(numbering: none, footer: none, margin: (left: 3.2cm, right: 3.2cm, top: 3cm, bottom: 3cm))
  set par(justify: false, leading: 0.5em, spacing: 0pt)
  caps(meta.university + " · " + meta.faculty, size: 0.75em)
  v(1fr)
  caps(meta.degree, size: 0.8em)
  v(0.9em)
  text(font: sans, size: 38pt, weight: "bold", tracking: -0.02em, meta.title)
  if meta.at("subtitle", default: none) != none {
    v(0.9em)
    text(size: 16pt, style: "italic", fill: muted, meta.subtitle)
  }
  v(1.4em)
  line(length: 4cm, stroke: 3pt + ink)
  v(1fr)
  grid(
    columns: (3.2cm, 1fr),
    row-gutter: 1.1em,
    caps[Author], text(size: 12pt, weight: "semibold", meta.author),
    caps[Supervisor], text(size: 12pt, meta.supervisor),
    caps[Programme], text(size: 12pt, meta.programme),
    caps[Date], text(size: 12pt, meta.place + ", " + meta.date),
  )
}

// Roman page numbers for everything before Chapter 1.
#let front-matter(body) = {
  set page(numbering: "i")
  counter(page).update(1)
  body
}

// Arabic numbers from Chapter 1.
#let main-matter(body) = {
  set page(numbering: "1")
  counter(page).update(1)
  body
}

// Unnumbered chapter-level heading for abstract, bibliography, ...
#let unnumbered(title) = heading(level: 1, numbering: none, title)

#let abstract(body) = {
  unnumbered[Abstract]
  body
}

#let dots = repeat(text(fill: faint)[.], gap: 0.25em)

#let contents() = {
  set outline.entry(fill: dots)
  heading(level: 1, numbering: none, outlined: false)[Contents]
  show outline.entry.where(level: 1): set block(above: 1.15em)
  show outline.entry.where(level: 1): set text(font: sans, weight: "semibold", size: 0.9em)
  outline(title: none, depth: 3, indent: 1.4em)
}

#let figure-lists() = {
  set outline.entry(fill: dots)
  show outline.entry: set text(size: 0.92em)
  heading(level: 1, numbering: none, outlined: false)[List of figures]
  outline(title: none, target: figure.where(kind: image))
  heading(level: 1, numbering: none, outlined: false)[List of tables]
  outline(title: none, target: figure.where(kind: table))
}
