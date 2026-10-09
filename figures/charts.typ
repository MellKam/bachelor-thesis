// Native Typst charts for the exposure study (Chapter 2).
//
// Everything is read from the study's generated data, never retyped:
//   results/rating/rating.json       exposure ratings, one record per language × feature
//   results/integration/rating.json  integration and combined scores
// Re-run `make rating` / `make integration-rating` in wasm-exposure-study/ and recompile
// and the figures and the numbers quoted in the prose follow. No external packages.

#let study = "../wasm-exposure-study/results/"
#let rating = json(study + "rating/rating.json")
#let integration = json(study + "integration/rating.json")

// --- palette (colour-blind safe; every colour is also carried by a letter) ----
#let c-construct = rgb("#1f4e79")  // a language construct or annotation
#let c-config = rgb("#7fb2d9")     // build configuration outside the source
#let c-asm = rgb("#e69f00")        // hand-written assembly / Wasm text
#let c-absent = luma(230)          // no way found
#let muted = luma(105)
#let sans = ("Liberation Sans", "Inter", "Libertinus Serif")
#let c-exposure = rgb("#1f4e79")
#let c-integration = rgb("#8f5aa8")

// --- data access ---------------------------------------------------------------
#let language-groups = (
  (label: "Linear memory", ids: ("rust", "zig", "c", "swift")),
  (label: "Both backends", ids: ("moonbit",)),
  (label: "Linear + runtime GC", ids: ("assemblyscript", "tinygo")),
  (label: "Wasm GC", ids: ("kotlin",)),
)
#let order = language-groups.map(g => g.ids).flatten()
#let lang = rating.languages.map(l => (l.id, l)).to-dict()
#let integ = integration.languages.map(l => (l.id, l)).to-dict()
#let cell-at = rating.cells.map(c => (c.language + ":" + c.feature, c)).to-dict()
#let cell(l, f) = cell-at.at(l + ":" + f)
#let feature-ids = rating.features.map(f => f.id)

#let is-reached(c) = c.status == "reached"
#let is-construct(c) = is-reached(c) and c.expressedAs in ("native", "annotation")
#let route-of(c) = if not is-reached(c) { "absent" } else if is-construct(c) { "construct" } else if c.expressedAs == "config" { "config" } else { "asm" }

// --- numbers quoted in the prose ---------------------------------------------
#let n-pairs = rating.cells.len()
#let n-features = feature-ids.len()
#let n-languages = order.len()
#let count-route(r) = rating.cells.filter(c => route-of(c) == r).len()
#let n-construct = count-route("construct")
#let n-config = count-route("config")
#let n-asm = count-route("asm")
#let n-absent = count-route("absent")
#let n-reached = n-pairs - n-absent

#let broadest = order.map(l => lang.at(l)).sorted(key: l => -l.reached).first()
#let narrowest = order.map(l => lang.at(l)).sorted(key: l => l.reached).first()

#let languages-where(f, pred) = order.filter(l => pred(cell(l, f)))
#let features-where(pred) = feature-ids.filter(f => pred(
  order.len(),
  languages-where(f, is-reached).len(),
  languages-where(f, is-construct).len(),
))
#let reached-by-none = features-where((n, r, k) => r == 0)
#let reached-by-all = features-where((n, r, k) => r == n)
#let construct-in-all = features-where((n, r, k) => k == n)
#let construct-in-none = features-where((n, r, k) => k == 0)
#let feature-name(f) = rating.features.find(x => x.id == f).name

// Short feature names so the matrix fits on the page.
#let short-names = (
  "01": "Imports and exports",
  "02": "Memory limits and names",
  "03": "Table and indirect call",
  "04": "Table import and export",
  "05": "Start function",
  "06": "Data segment placement",
  "07": "Custom sections",
  "08": "Integer operations",
  "09": "Float builtins",
  "10": "Globals",
  "11": "Non-trapping conversions",
  "12": "Bulk memory",
  "13": "Passive data segments",
  "14": "Multi-value",
  "15": "SIMD",
  "16": "SIMD memory and bitwise",
  "17": [`externref`],
  "18": "Multiple tables",
  "19": "Table ops on references",
  "20": "Tail calls",
  "21": "Extended constants",
  "22": "Typed function references",
  "23": "GC structs and arrays",
  "24": "GC casts, i31, packed fields",
  "25": "Multiple memories",
  "26": "Relaxed SIMD",
  "27": "Exception tags",
  "28": [Exceptions with `exnref`],
  "29": "64-bit memory",
  "30": "Branch hinting",
)

// The same features as lower-case phrases for running text.
#let phrases = (
  "01": "imports and exports", "02": "memory limits and names", "03": "tables and indirect calls",
  "04": "table import and export", "05": "the start function", "06": "data segment placement",
  "07": "custom sections", "08": "integer operations", "09": "float builtins", "10": "globals",
  "11": "non-trapping conversions and sign extension", "12": "bulk memory", "13": "passive data segments",
  "14": "multi-value results", "15": "SIMD", "16": "SIMD memory and bitwise operations",
  "17": "externref", "18": "multiple tables", "19": "table operations on references", "20": "tail calls",
  "21": "extended constant expressions", "22": "typed function references", "23": "GC structs and arrays",
  "24": "GC casts, subtyping and packed fields", "25": "multiple memories", "26": "relaxed SIMD",
  "27": "exception tags", "28": "exception handling with exnref", "29": "64-bit memory", "30": "branch hinting",
)
// "a, b and c" from a list of feature ids.
#let list-of(ids) = ids.map(f => phrases.at(f)).join(", ", last: " and ")
#let cap-first(s) = upper(s.first()) + s.slice(1)

// --- shared pieces -------------------------------------------------------------
#let swatch(color, label) = box(inset: (right: 1.1em))[
  #box(width: 0.85em, height: 0.85em, fill: color, radius: 1pt, baseline: 0.1em)
  #h(0.3em)#label
]

#let legend() = {
  set text(font: sans, size: 0.78em)
  align(center)[
    #swatch(c-construct, [construct or annotation])
    #swatch(c-config, [build configuration])
    #swatch(c-asm, [inline assembly])
    #swatch(c-absent, [absent])
  ]
}

#let lang-name(l) = lang.at(l).name
// Narrow matrix columns need a manual break in the two long names.
#let head-name(l) = if l == "assemblyscript" [Assembly­Script] else if l == "moonbit" [Moon­Bit] else { lang-name(l) }
// 0.4 -> "0.40"
#let fmt2(x) = {
  let n = int(calc.round(x * 100))
  str(calc.quo(n, 100)) + "." + (if calc.rem(n, 100) < 10 { "0" } else { "" }) + str(calc.rem(n, 100))
}

// --- scoring coefficients and orderings (read from the data, never retyped) ------
#let i6 = json(study + "integration/i6.json").languages
#let obstacle-factor(kind) = rating.coefficients.obstacles.find(o => o.kind == kind).factor
#let route-factor(kind) = integration.weights.routes.find(r => r.kind == kind).factor
#let icrit = ("I1", "I2", "I3", "I4", "I5")
#let criterion(c) = integration.criteria.at(c)
#let w-exposure = integration.weights.combined.exposure
#let w-integration = integration.weights.combined.integration
#let weight-sum = icrit.map(c => criterion(c).weight).sum()

#let by-exposure = order.sorted(key: l => -lang.at(l).score)
#let by-integration = order.sorted(key: l => -integ.at(l).integration)
#let by-combined = order.sorted(key: l => -integ.at(l).combined)
// 1-based place of a language in an ordering.
#let place-of(ordering, l) = ordering.position(x => x == l) + 1
#let rank-text(r) = if r.best == r.worst [#r.best] else [#r.best–#r.worst]

// A value on a 0..1 scale: a faint full-length track with the bar on top.
#let bar-track(value, color, width, height: 0.34cm) = box(width: width, height: height, fill: luma(240),
  place(left + top, rect(width: value * width, height: height, fill: color, stroke: none)))
#let bar-label(body) = box(height: 0.34cm, align(horizon, text(size: 0.8em, weight: "bold", body)))

// ===========================================================================
// Figure A. Feature × language matrix
// ===========================================================================
#let matrix-cell(c) = {
  let r = route-of(c)
  let (fill, ink, code) = if r == "construct" {
    (c-construct, white, if c.expressedAs == "native" { "N" } else { "A" })
  } else if r == "config" {
    (c-config, black, "C")
  } else if r == "asm" {
    (c-asm, black, "I")
  } else {
    (c-absent, luma(120), if c.absent == "not found" { "?" } else { "–" })
  }
  let partial = if is-reached(c) and c.partial != none and c.partial != false { super("p") } else { none }
  table.cell(fill: fill, align: center + horizon, text(fill: ink, size: 0.8em, weight: "bold")[#code#partial])
}

#let matrix-figure() = {
  set text(font: sans)
  let first-ids = language-groups.map(g => g.ids.first())
  let versions = ("1.0", "2.0", "3.0")
  // A thicker rule between memory-model groups.
  let group-start = i => order.at(i) in first-ids and i > 0
  let rows = ()
  for v in versions {
    rows.push(table.cell(colspan: 1 + order.len(), align: left, fill: luma(245),
      text(size: 0.78em, weight: "bold", fill: muted)[Specification #v]))
    for f in feature-ids.filter(f => rating.features.find(x => x.id == f).since == v) {
      rows.push(table.cell(align: left + horizon, text(size: 0.7em)[#text(fill: muted)[#f] #h(0.4em) #short-names.at(f)]))
      for (i, l) in order.enumerate() {
        rows.push(matrix-cell(cell(l, f)))
      }
    }
  }
  set par(justify: false)
  table(
    columns: (5.0cm,) + (1.2cm,) * order.len(),
    rows: 0.46cm,
    inset: (x: 3pt, y: 0pt),
    stroke: (x, y) => if x > 0 and group-start(x - 1) { (left: 0.8pt + white, rest: 0.4pt + white) } else { 0.4pt + white },
    table.header(
      table.cell(align: left + bottom, inset: (y: 5pt), text(size: 0.8em, fill: muted)[Feature]),
      ..order.map(l => table.cell(align: center + bottom, inset: (x: 0pt, y: 5pt),
        text(size: 0.62em, weight: "bold")[#head-name(l)])),
    ),
    ..rows,
  )
  v(0.2em)
  legend()
  v(-0.3em)
  align(center, text(size: 0.78em, fill: muted)[N native construct · A annotation · C build configuration · I inline assembly · – absent (confirmed) · ? absent (not found) · #super[p] partial])
}

// ===========================================================================
// Figure B. How each language reaches the 30 features (stacked bars)
// ===========================================================================
#let reach-figure() = {
  set text(font: sans)
  let unit = 0.36cm
  let seg(n, color, ink: black) = if n > 0 {
    box(width: n * unit, height: 0.52cm, fill: color,
      align(center + horizon, text(size: 0.78em, fill: ink, weight: "bold")[#n]))
  }
  let rows = ()
  for l in order {
    let cs = feature-ids.map(f => cell(l, f))
    let n(r) = cs.filter(c => route-of(c) == r).len()
    rows.push(table.cell(align: right + horizon, text(size: 0.88em)[#lang-name(l)]))
    rows.push(table.cell(align: left + horizon, stack(dir: ltr,
      seg(n("construct"), c-construct, ink: white),
      seg(n("config"), c-config),
      seg(n("asm"), c-asm),
      seg(n("absent"), c-absent, ink: luma(90)),
    )))
  }
  table(
    columns: (3.1cm, auto),
    column-gutter: 0.2cm,
    inset: (x: 0pt, y: 1.6pt),
    stroke: none,
    ..rows,
  )
  v(0.3em)
  legend()
}

// ===========================================================================
// Figure C. Reached features by specification version
// ===========================================================================
#let version-figure() = {
  set text(font: sans)
  let versions = ("1.0", "2.0", "3.0")
  let n-in(v) = rating.features.filter(f => f.since == v).len()
  let tint(ratio) = color.mix((c-construct, ratio * 100%), (white, (1 - ratio) * 100%), space: oklab)
  let rows = ()
  for l in order {
    rows.push(table.cell(align: left + horizon, text(size: 0.88em)[#lang-name(l)]))
    for v in versions {
      let k = lang.at(l).bySpecVersion.at(v)
      let ratio = k.reached / k.features
      rows.push(table.cell(fill: tint(ratio), align: center + horizon,
        text(size: 0.85em, fill: if ratio > 0.55 { white } else { black })[#k.reached / #k.features]))
    }
  }
  table(
    columns: (3.1cm,) + (2.2cm,) * 3,
    rows: 0.55cm,
    inset: (x: 4pt, y: 0pt),
    stroke: 0.6pt + white,
    table.header(
      [],
      ..versions.map(v => table.cell(align: center + bottom, inset: (y: 3pt),
        text(size: 0.82em, weight: "bold")[Spec #v \ #text(weight: "regular", fill: muted)[#n-in(v) features]])),
    ),
    ..rows,
  )
}


// ===========================================================================
// Synthesis (section 2.6): numbers and a compact figure for the claims of the problem statement
// ===========================================================================
#let llvm-languages = ("rust", "zig", "c", "swift", "tinygo")
#let own-backend-languages = ("moonbit", "assemblyscript", "kotlin")
// Features offered as a construct by some language with its own backend and by none that goes through LLVM.
#let llvm-gap = feature-ids.filter(f => llvm-languages.all(l => not is-construct(cell(l, f))) and own-backend-languages.any(l => is-construct(cell(l, f))))

// The module entities the problem statement wants as typed constructs.
#let entity-features = ("02", "25", "10", "03", "04", "18", "27")
#let entity-names = short-names + ("03": "Indirect calls", "04": "Table import and export", "18": "Multiple tables")
#let entity-constructs(l) = entity-features.filter(f => is-construct(cell(l, f))).len()
#let max-entity-constructs = calc.max(..order.map(entity-constructs))
#let n-by-route(f, r) = order.filter(l => route-of(cell(l, f)) == r).len()

// Integration criteria I1 to I3 (WASI, components, JS bindings): which route each language needs.
#let i123 = icrit.slice(0, 3)
#let route-of-i(l, c) = integ.at(l).detail.at(c).at("route", default: none)
#let n-i-cells = order.len() * i123.len()
#let n-i-route(r) = order.map(l => i123.filter(c => route-of-i(l, c) == r).len()).sum()
#let n-i-tool = n-i-route("official-tool") + n-i-route("community-tool")
#let n-i-absent = order.map(l => i123.filter(c => route-of-i(l, c) == none).len()).sum()

#let n-asm-routes = order.map(l => lang.at(l).counts.reachedVia.inlineAsmChecked + lang.at(l).counts.reachedVia.inlineAsmUnchecked).sum()
#let n-asm-checked = order.map(l => lang.at(l).counts.reachedVia.inlineAsmChecked).sum()

#let entity-figure() = {
  set text(font: sans)
  set par(justify: false)
  let rows = ()
  for f in entity-features {
    rows.push(table.cell(align: left + horizon, text(size: 0.8em)[#entity-names.at(f)]))
    for l in order { rows.push(matrix-cell(cell(l, f))) }
  }
  table(
    columns: (4.4cm,) + (1.25cm,) * order.len(),
    rows: (auto,) + (0.55cm,) * entity-features.len(),
    inset: (x: 3pt, y: 0pt),
    stroke: 0.4pt + white,
    table.header(
      table.cell(align: left + bottom, inset: (y: 5pt), text(size: 0.8em, fill: muted)[Feature]),
      ..order.map(l => table.cell(align: center + bottom, inset: (x: 0pt, y: 5pt),
        text(size: 0.62em, weight: "bold")[#head-name(l)])),
    ),
    ..rows,
  )
  v(0.2em)
  legend()
  v(-0.3em)
  align(center, text(size: 0.78em, fill: muted)[N native construct · A annotation · C build configuration · I inline assembly · – absent (confirmed) · ? absent (not found) · #super[p] partial])
}

// ===========================================================================
// Figure D. Exposure score, ordered
// ===========================================================================
#let exposure-figure() = {
  set text(font: sans)
  let rows = ()
  for (i, l) in by-exposure.enumerate() {
    let s = lang.at(l).score
    rows.push(table.cell(align: right + horizon, text(size: 0.8em, fill: muted)[#(i + 1)]))
    rows.push(table.cell(align: left + horizon, text(size: 0.88em)[#lang-name(l)]))
    rows.push(table.cell(align: left + horizon, stack(dir: ltr, spacing: 5pt,
      bar-track(s, c-exposure, 6.5cm), bar-label(fmt2(s)))))
    rows.push(table.cell(align: center + horizon, text(size: 0.85em)[#rank-text(lang.at(l).scoreRank)]))
  }
  table(
    columns: (0.6cm, 3.0cm, 8.0cm, 2.6cm),
    inset: (x: 3pt, y: 3pt),
    stroke: none,
    table.header(
      [], [],
      table.cell(align: left, text(size: 0.8em, fill: muted)[exposure score, 0 to 1]),
      table.cell(align: center, text(size: 0.8em, fill: muted)[rank range]),
    ),
    table.hline(stroke: 0.4pt + muted),
    ..rows,
  )
}

// ===========================================================================
// Figure E. Integration criteria × language, ordered by integration score
// ===========================================================================
#let integration-figure() = {
  set text(font: sans)
  let tint(ratio) = color.mix((c-integration, ratio * 100%), (white, (1 - ratio) * 100%), space: oklab)
  let rows = ()
  for (i, l) in by-integration.enumerate() {
    let s = integ.at(l)
    rows.push(table.cell(align: left + horizon, inset: (x: 3pt, y: 0pt), text(size: 0.88em)[#lang-name(l)]))
    for c in icrit {
      let v = s.per.at(c)
      let unsupported = s.detail.at(c).at("absent", default: none) != none
      rows.push(table.cell(
        fill: if unsupported { c-absent } else { tint(v) },
        align: center + horizon,
        text(size: 0.85em, fill: if unsupported { luma(110) } else if v > 0.55 { white } else { black })[
          #if unsupported [–] else [#fmt2(v)]
        ],
      ))
    }
    rows.push(table.cell(align: left + horizon, inset: (x: 8pt, y: 0pt), stack(dir: ltr, spacing: 5pt,
      bar-track(s.integration, c-integration, 2.2cm), bar-label(fmt2(s.integration)))))
  }
  table(
    columns: (2.9cm,) + (1.65cm,) * icrit.len() + (3.6cm,),
    rows: (auto,) + (0.62cm,) * order.len(),
    inset: (x: 3pt, y: 0pt),
    stroke: 0.6pt + white,
    table.header(
      [],
      ..icrit.map(c => table.cell(align: center + bottom, inset: (y: 3pt),
        text(size: 0.66em, weight: "bold")[#c \ #criterion(c).name \ #text(weight: "regular", fill: muted)[weight #criterion(c).weight]])),
      table.cell(align: left + bottom, inset: (x: 8pt, y: 3pt),
        text(size: 0.66em, weight: "bold")[Integration \ #text(weight: "regular", fill: muted)[weighted mean]]),
    ),
    ..rows,
  )
}

// ===========================================================================
// Figure F. Combined score, ordered: the two weighted parts stacked
// ===========================================================================
#let combined-figure() = {
  set text(font: sans)
  let width = 6.5cm
  let height = 0.34cm
  let part(value, color) = box(width: value * width, height: height, fill: color,
    align(center + horizon, text(size: 0.72em, fill: white, weight: "bold")[#fmt2(value)]))
  let rows = ()
  for (i, l) in by-combined.enumerate() {
    let s = integ.at(l)
    rows.push(table.cell(align: right + horizon, text(size: 0.8em, fill: muted)[#(i + 1)]))
    rows.push(table.cell(align: left + horizon, text(size: 0.88em)[#lang-name(l)]))
    rows.push(table.cell(align: left + horizon, stack(dir: ltr, spacing: 5pt,
      box(width: width, height: height, fill: luma(240),
        place(left + top, stack(dir: ltr, part(w-exposure * s.exposure, c-exposure), part(w-integration * s.integration, c-integration)))),
      bar-label(fmt2(s.combined)))))
    rows.push(table.cell(align: center + horizon, text(size: 0.85em)[#rank-text(s.rank)]))
  }
  table(
    columns: (0.6cm, 3.0cm, 8.0cm, 2.6cm),
    inset: (x: 3pt, y: 3pt),
    stroke: none,
    table.header(
      [], [],
      table.cell(align: left, text(size: 0.8em)[
        #swatch(c-exposure, [#w-exposure × exposure]) #swatch(c-integration, [#w-integration × integration])]),
      table.cell(align: center, text(size: 0.8em, fill: muted)[rank range]),
    ),
    table.hline(stroke: 0.4pt + muted),
    ..rows,
  )
}
