// Native Typst diagrams for Chapter 9 (implementation). Everything is drawn from boxes and
// a grid: no packages, the same fonts as the rest of the thesis, and no colour, so it prints
// in greyscale. A solid outline is a part that works on this branch; a dashed one is
// written, and does not compile against the current checker (see the chapter's last section).

#import "charts.typ" as ch
#let sans = ("Liberation Serif", "Libertinus Serif")
#let ink = black
#let muted = luma(105)
#let fill-stage = luma(245)
#let fill-bar = luma(225)

// (name, module path, what it hands on)
#let stages = (
  ("Front end", "vfs, ast", "syntax trees"),
  ("Checker", "tir::check", "typed program"),
  ("Lowering", "tir::lower", "MIR"),
  ("Inlining", "mir::inline", "MIR"),
  ("Optimizer", "opt", "instructions"),
  ("Encoder", "codegen", "bytes"),
)

// (name, first stage, last stage, connected, note)
#let consumers = (
  ("wx build", 0, 5, true, "stops after each stage that reports an error"),
  ("wx check", 0, 1, true, "diagnostics only"),
  ("wx format", 0, 0, true, "syntax tree and source text, no types"),
  ("execution tests", 0, 5, true, "run the module under Wasmtime"),
  ("backend tests", 3, 5, true, "hand-built MIR"),
  ("language server", 0, 1, false, "also the formatter; not connected"),
  ("browser compiler", 0, 5, false, "the library as Wasm; not connected"),
)

#let pipeline-figure() = {
  set text(font: sans, size: 10pt, hyphenate: false)
  set par(justify: false)
  let n = stages.len()
  // columns: box, arrow, box, arrow, ..., box
  let cols = ()
  for i in range(n) {
    cols.push(1fr)
    if i < n - 1 { cols.push(0.3cm) }
  }
  let cells = ()
  for (i, s) in stages.enumerate() {
    cells.push(box(
      width: 100%,
      height: 1.5cm,
      fill: fill-stage,
      stroke: 0.7pt + ink,
      inset: 3pt,
      align(center + horizon)[
        #text(weight: "bold", s.at(0)) \
        #s.at(1)
      ],
    ))
    if i < n - 1 { cells.push(align(center + horizon, sym.arrow.r)) }
  }
  // what flows between: the product of each stage, under its box
  for (i, s) in stages.enumerate() {
    cells.push(align(center, text(size: 10pt, fill: muted, emph(s.at(2)))))
    if i < n - 1 { cells.push([]) }
  }
  // one bar per consumer, spanning the stages it reaches
  let bars = ()
  for c in consumers {
    let (name, first, last, live, note) = c
    let start = first * 2
    let span = (last - first) * 2 + 1
    // leading gap, the bar, trailing gap
    if start > 0 { bars.push(table.cell(colspan: start, [])) }
    bars.push(table.cell(
      colspan: span,
      box(
        width: 100%,
        fill: if live { fill-bar } else { white },
        stroke: (paint: ink, thickness: 0.7pt, dash: if live { none } else { "dashed" }),
        inset: (x: 4pt, y: 3pt),
        align(left)[#text(weight: "bold", name)#if span >= 5 [ #h(4pt) #text(size: 10pt, fill: muted, note)]],
      ),
    ))
    let rest = 2 * n - 1 - start - span
    if rest > 0 { bars.push(table.cell(colspan: rest, [])) }
  }
  block(width: 100%, breakable: false)[
    #grid(columns: cols, row-gutter: 3pt, ..cells)
    #v(6pt)
    #line(length: 100%, stroke: 0.4pt + luma(170))
    #v(2pt)
    #text(size: 10pt, fill: muted)[Consumers of the library, by the stages they reach]
    #v(2pt)
    #table(
      columns: cols,
      stroke: none,
      inset: 0pt,
      row-gutter: 3pt,
      column-gutter: 0pt,
      ..bars
    )
  ]
}

// Lines of live Rust, without comments and blank lines (cloc, 2026-11-06); dead code and the
// suites of the earlier pipeline are not counted, tests written inside source files are.
// (label, code, tests)
#let sizes = (
  ("Front end (vfs, ast, diagnostics)", 7153, 4503),
  ("Checker (tir)", 31985, 25282),
  ("Lowering (tir::lower)", 4230, 5947),
  ("MIR and inlining (mir)", 1411, 472),
  ("Optimizer (opt)", 5650, 140),
  ("Encoding (codegen, wasm)", 2153, 0),
)
#let tools = (
  ("Formatter (wx-fmt)", 3142, 2886),
  ("Command line (wx-cli)", 426, 0),
)

#let thousands(v) = {
  let digits = str(v).clusters()
  let out = ()
  for (k, d) in digits.enumerate() {
    if k > 0 and calc.rem(digits.len() - k, 3) == 0 { out.push(sym.space.nobreak) }
    out.push(d)
  }
  out.join()
}

#let size-figure() = {
  set text(font: sans, size: 10pt)
  let width = 3.3cm
  let peak = 32000
  let pos(v) = calc.min(1, v / peak) * width
  let pad = (x: 7pt, y: 0pt)
  // a number always sits in the same right-aligned slot, so the columns read as columns
  let number(v, weight: "regular", size: 10pt) = box(width: 1.25cm, align(right + horizon, text(size: size, weight: weight, thousands(v))))
  let cell-bar(v, color) = table.cell(align: left + horizon, inset: pad, stack(dir: ltr, spacing: 6pt,
    box(width: width, height: 0.3cm, fill: luma(245), stroke: 0.3pt + luma(190),
      place(left + top, rect(width: pos(v), height: 0.3cm, fill: color, stroke: none))),
    number(v),
  ))
  let label(t) = table.cell(align: left + horizon, inset: pad, text(size: 10pt, t))
  let bars(list) = {
    let out = ()
    for r in list {
      out.push(label(r.at(0)))
      out.push(cell-bar(r.at(1), ch.c-exposure))
      out.push(cell-bar(r.at(2), ch.c-config))
    }
    out
  }
  let total-label(t) = table.cell(fill: ch.section-fill, align: left + horizon, inset: pad, text(size: 10pt, weight: "bold", t))
  let total-number(v) = table.cell(fill: ch.section-fill, align: left + horizon, inset: pad,
    stack(dir: ltr, spacing: 6pt, box(width: width), number(v, weight: "bold", size: 10pt)))
  let rows = bars(sizes) + (total-label[Compiler, total], total-number(52678), total-number(37555)) + bars(tools)
  set par(justify: false, leading: 0.4em)
  let head(t) = table.cell(align: center + horizon, fill: ch.header-fill, inset: (y: 4pt), text(size: 10pt, weight: "bold", t))
  table(
    columns: (5cm, 1fr, 1fr),
    rows: (auto,) + (0.54cm,) * (sizes.len() + tools.len() + 1),
    inset: (x: 3pt, y: 2pt),
    stroke: ch.grid-stroke,
    table.header(head[Part], head[Code], head[Tests]),
    ..rows,
  )
  v(0.5em)
  align(center, text(size: 10pt, fill: ch.muted)[
    lines of live Rust without comments and blank lines · axis: linear, 0 to 32 000 lines
  ])
}
