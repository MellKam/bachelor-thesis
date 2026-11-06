// Native Typst charts for the exposure study (Chapter 2): Polish edition.
// A copy of charts.typ with Polish labels; keep the two in step when the data
// access or layout changes.
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
#let sans = ("Liberation Serif", "Libertinus Serif")
#let c-exposure = rgb("#1f4e79")
#let c-integration = rgb("#8f5aa8")
#let c-highlight = rgb("#fff2cc")  // the row of the language the figure is about

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
#let route-of(c) = if not is-reached(c) { "absent" } else if is-construct(c) { "construct" } else if (
  c.expressedAs == "config"
) { "config" } else { "asm" }

// --- numbers quoted in the prose ---------------------------------------------
// Polish noun after a count: 1 cecha, 2-4 cechy, 5+ cech.
#let plural-pl(n, one, few, many) = if n == 1 { one } else if (
  calc.rem(n, 10) in (2, 3, 4) and calc.rem(n, 100) not in (12, 13, 14)
) { few } else { many }

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
  "01": "Importy i eksporty",
  "02": "Limity pamięci i nazwy",
  "03": "Wywołanie przez tabelę",
  "04": "Import i eksport tabeli",
  "05": "Funkcja startowa",
  "06": "Rozmieszczenie danych",
  "07": "Sekcje niestandardowe",
  "08": "Operacje całkowitoliczbowe",
  "09": "Wbudowane operacje float",
  "10": "Zmienne globalne",
  "11": "Konwersje bez trap",
  "12": "Operacje zbiorcze na pamięci",
  "13": "Pasywne segmenty danych",
  "14": "Wiele wyników (multi-value)",
  "15": "SIMD",
  "16": "SIMD: pamięć i bity",
  "17": [`externref`],
  "18": "Wiele tabel",
  "19": "Referencje w tabelach",
  "20": "Wywołania ogonowe",
  "21": "Rozszerzone wyrażenia stałe",
  "22": "Typowane referencje funkcji",
  "23": "Struktury i tablice GC",
  "24": "GC: rzutowania, i31, pola",
  "25": "Wiele pamięci",
  "26": "Relaxed SIMD",
  "27": "Tagi wyjątków",
  "28": [Wyjątki z `exnref`],
  "29": "Pamięć 64-bitowa",
  "30": "Podpowiedzi dla rozgałęzień",
)

// The same features as lower-case phrases for running text.
#let phrases = (
  "01": "imports and exports",
  "02": "memory limits and names",
  "03": "tables and indirect calls",
  "04": "table import and export",
  "05": "the start function",
  "06": "data segment placement",
  "07": "custom sections",
  "08": "integer operations",
  "09": "float builtins",
  "10": "globals",
  "11": "non-trapping conversions and sign extension",
  "12": "bulk memory",
  "13": "passive data segments",
  "14": "multi-value results",
  "15": "SIMD",
  "16": "SIMD memory and bitwise operations",
  "17": "externref",
  "18": "multiple tables",
  "19": "table operations on references",
  "20": "tail calls",
  "21": "extended constant expressions",
  "22": "typed function references",
  "23": "GC structs and arrays",
  "24": "GC casts, subtyping and packed fields",
  "25": "multiple memories",
  "26": "relaxed SIMD",
  "27": "exception tags",
  "28": "exception handling with exnref",
  "29": "64-bit memory",
  "30": "branch hinting",
)
// "a, b and c" from a list of feature ids.
#let list-of(ids) = ids.map(f => phrases.at(f)).join(", ", last: " and ")
#let cap-first(s) = upper(s.first()) + s.slice(1)

// --- shared pieces -------------------------------------------------------------
#let grid-stroke = 0.5pt + black
#let header-fill = luma(230)
#let section-fill = luma(242)

#let swatch(color, label) = box(inset: (right: 1.1em))[
  #box(width: 0.85em, height: 0.85em, fill: color, stroke: 0.4pt + luma(140), radius: 1pt, baseline: 0.1em)
  #h(0.3em)#label
]

#let legend() = {
  set text(font: sans, size: 10pt)
  align(center)[
    #swatch(c-construct, [konstrukcja lub adnotacja])
    #swatch(c-config, [konfiguracja budowania])
    #swatch(c-asm, [asembler wbudowany])
    #swatch(c-absent, [brak])
  ]
}

#let lang-name(l) = lang.at(l).name
// Narrow matrix columns need a manual break in the two long names.
#let head-name(l) = if l == "assemblyscript" [Assembly-\ Script] else if l == "moonbit" [MoonBit] else { lang-name(l) }
// 0.4 -> "0.40"
#let fmt2(x) = {
  let n = int(calc.round(x * 100))
  str(calc.quo(n, 100)) + "," + (if calc.rem(n, 100) < 10 { "0" } else { "" }) + str(calc.rem(n, 100))
}

// --- scoring coefficients and orderings (read from the data, never retyped) ------
#let i6 = json(study + "integration/i6.json").languages
#let obstacle-factor(kind) = rating.coefficients.obstacles.find(o => o.kind == kind).factor
#let route-factor(kind) = integration.weights.routes.find(r => r.kind == kind).factor
#let icrit = ("I1", "I2", "I3", "I4", "I5")
#let criterion(c) = integration.criteria.at(c)
#let icrit-head(c) = if c == "I2" [I2: Component\ Model] else if c == "I3" [I3: wiązania\ JS] else if (
  c == "I4"
) [I4: Debugo-\ wanie] else if c == "I5" [I5: Rozmiar] else [#c: #criterion(c).name]
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
#let bar-track(value, color, width, height: 0.36cm) = box(
  width: width,
  height: height,
  fill: luma(240),
  stroke: 0.3pt + luma(190),
  place(left + top, rect(width: value * width, height: height, fill: color, stroke: none)),
)
#let bar-label(body) = box(height: 0.36cm, align(horizon, text(size: 10pt, weight: "bold", body)))

// ===========================================================================
// Figure A. Feature × language matrix
// ===========================================================================
#let matrix-cell(c) = {
  let r = route-of(c)
  let (fill, ink, code) = if r == "construct" {
    (c-construct, white, if c.expressedAs == "native" { "N" } else { "A" })
  } else if r == "config" {
    (c-config, black, "K")
  } else if r == "asm" {
    (c-asm, black, "W")
  } else {
    (c-absent, luma(100), if c.absent == "not found" { "?" } else { "–" })
  }
  let partial = if is-reached(c) and c.partial != none and c.partial != false { super("cz.") } else { none }
  table.cell(fill: fill, align: center + horizon, text(fill: ink, size: 10pt, weight: "bold")[#code#partial])
}

// The module entities the problem statement wants as typed constructs; bold in the matrix.
#let entity-features = ("02", "25", "10", "03", "04", "18", "27")

#let matrix-figure() = {
  set text(font: sans, size: 10pt)
  let first-ids = language-groups.map(g => g.ids.first())
  let versions = ("1.0", "2.0", "3.0")
  let rows = ()
  for v in versions {
    rows.push(table.cell(
      colspan: 1 + order.len(),
      align: left + horizon,
      fill: section-fill,
      inset: (x: 5pt, y: 3pt),
      text(size: 10pt, weight: "bold")[Specyfikacja #v],
    ))
    for f in feature-ids.filter(f => rating.features.find(x => x.id == f).since == v) {
      rows.push(table.cell(align: left + horizon, inset: (x: 5pt, y: 0pt), text(size: 10pt)[#text(fill: muted)[#f] #h(
          0.35em,
        ) #if f in entity-features { strong(short-names.at(f)) } else { short-names.at(f) }]))
      for (i, l) in order.enumerate() {
        rows.push(matrix-cell(cell(l, f)))
      }
    }
  }
  set par(justify: false, leading: 0.45em)
  // 18 cm wide: 1 cm into each margin of the 16 cm text block, so the names fit on one line.
  pad(x: -1cm, table(
    columns: (6cm,) + (1.5cm,) * order.len(),
    rows: (auto,) + (0.62cm,) * (versions.len() + feature-ids.len()),
    inset: (x: 3pt, y: 2pt),
    stroke: grid-stroke,
    table.header(
      table.cell(align: left + horizon, fill: header-fill, inset: (x: 5pt, y: 4pt), text(
        size: 10pt,
        weight: "bold",
      )[Cecha]),
      ..order.map(l => table.cell(align: center + horizon, fill: header-fill, inset: (x: 2pt, y: 4pt), text(
        size: 9.5pt,
        weight: "bold",
      )[#head-name(l)])),
    ),
    ..rows,
  ))
  v(0.4em)
  legend()
  v(-0.2em)
  align(center, text(
    size: 10pt,
    fill: muted,
  )[N konstrukcja natywna · A adnotacja · K konfiguracja budowania · W asembler wbudowany · – brak (potwierdzony) · ? brak (nie znaleziono) · #super[cz.] częściowo])
}

// ===========================================================================
// Figure B. How each language reaches the 30 features (stacked bars)
// ===========================================================================
#let reach-figure() = {
  set text(font: sans, size: 10pt)
  let unit = 0.34cm
  let seg(n, color, ink: black) = if n > 0 {
    box(width: n * unit, height: 0.48cm, fill: color, align(center + horizon, text(
      size: 10pt,
      fill: ink,
      weight: "bold",
    )[#n]))
  }
  let rows = ()
  for l in order {
    let cs = feature-ids.map(f => cell(l, f))
    let n(r) = cs.filter(c => route-of(c) == r).len()
    rows.push(table.cell(align: left + horizon, inset: (x: 6pt, y: 3pt), text(size: 10pt)[#lang-name(l)]))
    rows.push(table.cell(align: left + horizon, inset: (x: 6pt, y: 3pt), box(stroke: 0.3pt + luma(180), stack(
      dir: ltr,
      seg(n("construct"), c-construct, ink: white),
      seg(n("config"), c-config),
      seg(n("asm"), c-asm),
      seg(n("absent"), c-absent, ink: luma(90)),
    ))))
  }
  table(
    columns: (3.2cm, auto),
    inset: (x: 4pt, y: 3pt),
    stroke: grid-stroke,
    table.header(
      table.cell(align: center + horizon, fill: header-fill, inset: (x: 6pt, y: 5pt), text(
        size: 10pt,
        weight: "bold",
      )[Język]),
      table.cell(align: center + horizon, fill: header-fill, inset: (x: 6pt, y: 5pt), text(
        size: 10pt,
        weight: "bold",
      )[Osiągnięte cechy (z #n-features)]),
    ),
    ..rows,
  )
  v(0.4em)
  legend()
}

// ===========================================================================
// Figure C. Reached features by specification version
// ===========================================================================
#let version-figure() = {
  set text(font: sans, size: 10pt)
  let versions = ("1.0", "2.0", "3.0")
  let n-in(v) = rating.features.filter(f => f.since == v).len()
  let tint(ratio) = color.mix((c-construct, ratio * 100%), (white, (1 - ratio) * 100%), space: oklab)
  let rows = ()
  for l in order {
    rows.push(table.cell(align: left + horizon, inset: (x: 6pt, y: 0pt), text(size: 10pt)[#lang-name(l)]))
    for v in versions {
      let k = lang.at(l).bySpecVersion.at(v)
      let ratio = k.reached / k.features
      rows.push(table.cell(fill: tint(ratio), align: center + horizon, text(size: 10pt, fill: if ratio > 0.55 {
        white
      } else { black })[#k.reached / #k.features]))
    }
  }
  set par(justify: false, leading: 0.45em)
  table(
    columns: (3.2cm,) + (2.5cm,) * 3,
    rows: (auto,) + (0.55cm,) * order.len(),
    inset: (x: 5pt, y: 3pt),
    stroke: grid-stroke,
    table.header(
      table.cell(align: center + horizon, fill: header-fill, inset: (x: 6pt, y: 5pt), text(
        size: 10pt,
        weight: "bold",
      )[Język]),
      ..versions.map(v => table.cell(align: center + horizon, fill: header-fill, inset: (y: 4pt), text(
        size: 10pt,
        weight: "bold",
      )[Spec. #v \ #text(size: 10pt, weight: "regular")[#n-in(v) #plural-pl(n-in(v), "cecha", "cechy", "cech")]])),
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
#let llvm-gap = feature-ids.filter(f => (
  llvm-languages.all(l => not is-construct(cell(l, f))) and own-backend-languages.any(l => is-construct(cell(l, f)))
))

#let entity-constructs(l) = entity-features.filter(f => is-construct(cell(l, f))).len()
#let max-entity-constructs = calc.max(..order.map(entity-constructs))

// Integration criteria I1 to I3 (WASI, components, JS bindings): which route each language needs.
#let i123 = icrit.slice(0, 3)
#let route-of-i(l, c) = integ.at(l).detail.at(c).at("route", default: none)
#let n-i-cells = order.len() * i123.len()
#let n-i-route(r) = order.map(l => i123.filter(c => route-of-i(l, c) == r).len()).sum()
#let n-i-tool = n-i-route("official-tool") + n-i-route("community-tool")
#let n-i-absent = order.map(l => i123.filter(c => route-of-i(l, c) == none).len()).sum()

#let n-asm-routes = (
  order.map(l => lang.at(l).counts.reachedVia.inlineAsmChecked + lang.at(l).counts.reachedVia.inlineAsmUnchecked).sum()
)
#let n-asm-checked = order.map(l => lang.at(l).counts.reachedVia.inlineAsmChecked).sum()

// ===========================================================================
// Figure D. Exposure score, ordered
// ===========================================================================
#let exposure-figure() = {
  set text(font: sans, size: 10pt)
  let rows = ()
  for (i, l) in by-exposure.enumerate() {
    let s = lang.at(l).score
    rows.push(table.cell(align: center + horizon, text(size: 10pt)[#(i + 1).]))
    rows.push(table.cell(align: left + horizon, inset: (x: 6pt), text(size: 10pt)[#lang-name(l)]))
    rows.push(table.cell(align: left + horizon, inset: (x: 6pt), stack(
      dir: ltr,
      spacing: 6pt,
      bar-track(s, c-exposure, 6.2cm),
      bar-label(fmt2(s)),
    )))
    rows.push(table.cell(align: center + horizon, text(size: 10pt)[#rank-text(lang.at(l).scoreRank)]))
  }
  table(
    columns: (0.9cm, 3.1cm, 7.8cm, 2.4cm),
    inset: (x: 4pt, y: 4pt),
    stroke: grid-stroke,
    table.header(
      table.cell(align: center + horizon, fill: header-fill, text(size: 10pt, weight: "bold")[#sym.numero]),
      table.cell(align: center + horizon, fill: header-fill, text(size: 10pt, weight: "bold")[Język]),
      table.cell(align: center + horizon, fill: header-fill, text(size: 10pt, weight: "bold")[Wskaźnik udostępnienia (0–1)]),
      table.cell(align: center + horizon, fill: header-fill, text(size: 10pt, weight: "bold")[Zakres pozycji]),
    ),
    ..rows,
  )
}

// ===========================================================================
// Figure E. Integration criteria × language, ordered by integration score
// ===========================================================================
#let integration-figure(langs: order, highlight: none) = {
  set text(font: sans, size: 10pt)
  set par(justify: false, leading: 0.45em)
  let tint(ratio) = color.mix((c-integration, ratio * 100%), (white, (1 - ratio) * 100%), space: oklab)
  let rows = ()
  let ordered = langs.sorted(key: l => -integ.at(l).integration)
  for (i, l) in ordered.enumerate() {
    let s = integ.at(l)
    let strong-row = l == highlight
    rows.push(table.cell(
      fill: if strong-row { c-highlight } else { none },
      align: left + horizon,
      inset: (x: 5pt, y: 0pt),
      text(size: 10pt, weight: if strong-row { "bold" } else { "regular" })[#lang-name(l)],
    ))
    for c in icrit {
      let v = s.per.at(c)
      let unsupported = s.detail.at(c).at("absent", default: none) != none
      rows.push(table.cell(
        fill: if unsupported { c-absent } else { tint(v) },
        align: center + horizon,
        text(size: 10pt, fill: if unsupported { luma(100) } else if v > 0.55 { white } else { black })[
          #if unsupported [–] else [#fmt2(v)]
        ],
      ))
    }
    rows.push(table.cell(align: center + horizon, inset: (x: 6pt, y: 0pt), bar-label(fmt2(s.integration))))
  }
  table(
    columns: (2.9cm,) + (2.2cm,) * icrit.len() + (2.1cm,),
    rows: (auto,) + (0.58cm,) * langs.len(),
    inset: (x: 3pt, y: 3pt),
    stroke: grid-stroke,
    table.header(
      table.cell(align: center + horizon, fill: header-fill, inset: (x: 4pt, y: 4pt), text(
        size: 10pt,
        weight: "bold",
      )[Język]),
      ..icrit.map(c => table.cell(align: center + horizon, fill: header-fill, inset: (x: 1pt, y: 4pt), text(
        size: 9pt,
        weight: "bold",
      )[#icrit-head(c) \ #text(size: 9pt, weight: "regular")[waga #criterion(c).weight]])),
      table.cell(align: center + horizon, fill: header-fill, inset: (x: 4pt, y: 4pt), text(
        size: 10pt,
        weight: "bold",
      )[Integracja \ #text(size: 10pt, weight: "regular")[średnia ważona]]),
    ),
    ..rows,
  )
}

// ===========================================================================
// Figure F. Combined score, ordered: the two weighted parts stacked
// ===========================================================================
#let combined-figure(langs: order, highlight: none) = {
  set text(font: sans, size: 10pt)
  let width = 6.2cm
  let height = 0.36cm
  let part(value, color) = box(width: value * width, height: height, fill: color, align(center + horizon, text(
    size: 10pt,
    fill: white,
    weight: "bold",
  )[#fmt2(value)]))
  let rows = ()
  let ordered = langs.sorted(key: l => -integ.at(l).combined)
  for (i, l) in ordered.enumerate() {
    let s = integ.at(l)
    let strong-row = l == highlight
    rows.push(table.cell(
      fill: if strong-row { c-highlight } else { none },
      align: center + horizon,
      text(size: 10pt)[#(i + 1).],
    ))
    rows.push(table.cell(
      fill: if strong-row { c-highlight } else { none },
      align: left + horizon,
      inset: (x: 6pt),
      text(size: 10pt, weight: if strong-row { "bold" } else { "regular" })[#lang-name(l)],
    ))
    rows.push(table.cell(align: left + horizon, inset: (x: 6pt), stack(
      dir: ltr,
      spacing: 6pt,
      box(width: width, height: height, fill: luma(240), stroke: 0.3pt + luma(190), place(left + top, stack(
        dir: ltr,
        part(w-exposure * s.exposure, c-exposure),
        part(w-integration * s.integration, c-integration),
      ))),
      bar-label(fmt2(s.combined)),
    )))
    rows.push(table.cell(align: center + horizon, text(size: 10pt)[#rank-text(s.rank)]))
  }
  table(
    columns: (0.9cm, 3.1cm, 7.8cm, 2.4cm),
    inset: (x: 4pt, y: 4pt),
    stroke: grid-stroke,
    table.header(
      table.cell(align: center + horizon, fill: header-fill, text(size: 10pt, weight: "bold")[#sym.numero]),
      table.cell(align: center + horizon, fill: header-fill, text(size: 10pt, weight: "bold")[Język]),
      table.cell(align: center + horizon, fill: header-fill, text(size: 10pt, weight: "bold")[Combined score]),
      table.cell(align: center + horizon, fill: header-fill, text(size: 10pt, weight: "bold")[Zakres pozycji]),
    ),
    ..rows,
  )
  v(0.4em)
  set text(font: sans, size: 10pt)
  align(center)[
    #swatch(c-exposure, [#w-exposure × exposure])
    #swatch(c-integration, [#w-integration × integration])
  ]
}

// ===========================================================================
// Figure W. The features WX covers: one row per feature, with the route and the reason for a gap
// ===========================================================================
// Why a feature is not (fully) reached: where it stands, and a note where there is more to say.
#let wx-status = (
  designed: "Zaprojektowane",
  easy: "Gotowe do implementacji",
  research: "Wymaga badań",
  unconsidered: "Jeszcze nierozważone",
  deferred: "Odroczone",
  depends: "Zależy od tabel",
  gap: "Ograniczenie",
)
#let wx-notes = (
  "01": none,
  "02": ("easy", "limitów nie można ustawić dla importu"),
  "03": ("designed", ""),
  "04": ("designed", ""),
  "05": ("research", ""),
  "06": ("gap", "nie można wybrać adresu danych"),
  "07": ("unconsidered", ""),
  "08": ("easy", "nie wszystkie instrukcje mają funkcję wewnętrzną"),
  "09": none,
  "10": none,
  "11": ("easy", ""),
  "12": none,
  "13": ("unconsidered", ""),
  "14": none,
  "15": ("easy", "wymaga typu wektorowego i funkcji wewnętrznych"),
  "16": ("easy", "wymaga typu wektorowego i funkcji wewnętrznych"),
  "17": ("research", ""),
  "18": ("designed", ""),
  "19": ("designed", ""),
  "20": ("designed", ""),
  "21": ("deferred", "wynika z leniwej inicjalizacji zmiennych globalnych"),
  "22": ("depends", "zbudowane na tabelach i referencjach do funkcji"),
  "23": ("research", ""),
  "24": ("research", ""),
  "25": none,
  "26": ("designed", ""),
  "27": ("designed", ""),
  "28": ("designed", ""),
  "29": none,
  "30": ("research", ""),
)

#let wx-figure() = {
  set text(font: sans, size: 10pt)
  let versions = ("1.0", "2.0", "3.0")
  let rows = ()
  for v in versions {
    rows.push(table.cell(colspan: 3, align: left + horizon, fill: section-fill, inset: (x: 5pt, y: 2pt), text(
      size: 10pt,
      weight: "bold",
    )[Specyfikacja #v]))
    for f in feature-ids.filter(f => rating.features.find(x => x.id == f).since == v) {
      rows.push(table.cell(align: left + horizon, inset: (x: 5pt, y: 2.5pt), text(size: 10pt)[#text(fill: muted)[#f] #h(
          0.35em,
        ) #short-names.at(f)]))
      rows.push(matrix-cell(cell("wx", f)))
      let n = wx-notes.at(f)
      rows.push(table.cell(align: left + horizon, inset: (x: 5pt, y: 2.5pt), if n == none { [] } else {
        text(size: 10pt)[#wx-status.at(n.at(0))]
        if n.at(1) != "" { text(size: 10pt, fill: muted)[ #sym.dash.en #n.at(1)] }
      }))
    }
  }
  set par(justify: false, leading: 0.45em)
  table(
    columns: (5.4cm, 1.1cm, 1fr),
    inset: (x: 3pt, y: 3pt),
    stroke: grid-stroke,
    table.header(
      table.cell(align: left + horizon, fill: header-fill, inset: (x: 5pt, y: 4pt), text(
        size: 10pt,
        weight: "bold",
      )[Cecha]),
      table.cell(align: center + horizon, fill: header-fill, inset: (x: 2pt, y: 4pt), text(
        size: 10pt,
        weight: "bold",
      )[WX]),
      table.cell(align: left + horizon, fill: header-fill, inset: (x: 5pt, y: 4pt), text(
        size: 10pt,
        weight: "bold",
      )[Status]),
    ),
    ..rows,
  )
  v(0.4em)
  align(center, text(size: 10pt, fill: muted)[N konstrukcja natywna · A adnotacja · – brak · #super[cz.] częściowo])
}

// ===========================================================================
// Figure S. Size of the three programs, floor builds, logarithmic axis
// ===========================================================================
#let sizes = json(study + "integration/size.json").sizes
#let size-figure(langs: order, highlight: none) = {
  set text(font: sans, size: 10pt)
  let programs = ("cat", "life", "words")
  let width = 2.5cm
  let lo = 2.0 // log10 of 100 bytes
  let hi = 7.0 // log10 of 10 MB
  let pos(n) = calc.max(0, calc.min(1, (calc.log(n) - lo) / (hi - lo))) * width
  let fmt-size(n) = if n >= 1000000 { str(calc.round(n / 1000000, digits: 1)).replace(".", ",") + " MB" } else if n >= 1000 { str(calc.round(n / 1000, digits: 1)).replace(".", ",") + " kB" } else { str(n) + " B" }
  // ordered by the mean of the logarithms of the three sizes
  let mean-log(l) = programs.map(p => calc.log(sizes.at(l).at(p).floor.best)).sum() / programs.len()
  let ordered = langs.sorted(key: mean-log)
  let rows = ()
  for l in ordered {
    let strong-row = l == highlight
    let fill = if strong-row { c-highlight } else { none }
    rows.push(table.cell(fill: fill, align: left + horizon, inset: (x: 4pt, y: 0pt),
      text(size: 10pt, weight: if strong-row { "bold" } else { "regular" })[#lang-name(l)]))
    for p in programs {
      let f = sizes.at(l).at(p).floor
      let color = if strong-row { c-exposure } else { c-config }
      rows.push(table.cell(fill: fill, align: left + horizon, inset: (x: 4pt, y: 0pt), stack(dir: ltr, spacing: 4pt,
        box(width: width, height: 0.34cm, fill: luma(245), stroke: 0.3pt + luma(190), {
          place(left + top, rect(width: pos(f.raw), height: 0.34cm, fill: none, stroke: 0.6pt + luma(90)))
          place(left + top, rect(width: pos(f.best), height: 0.34cm, fill: color, stroke: none))
        }),
        box(height: 0.34cm, align(horizon, text(size: 10pt)[#fmt-size(f.best)])),
      )))
    }
  }
  set par(justify: false, leading: 0.4em)
  table(
    columns: (2.6cm,) + (auto,) * programs.len(),
    rows: (auto,) + (0.52cm,) * langs.len(),
    inset: (x: 3pt, y: 2pt),
    stroke: grid-stroke,
    table.header(
      table.cell(align: center + horizon, fill: header-fill, inset: (y: 4pt), text(size: 10pt, weight: "bold")[Język]),
      ..programs.map(n => table.cell(align: center + horizon, fill: header-fill, inset: (y: 4pt), text(size: 10pt, weight: "bold")[#n])),
    ),
    ..rows,
  )
  v(0.4em)
  align(center, text(size: 10pt, fill: muted)[
    wypełniony pasek: rozmiar po `wasm-opt -Oz` (mniejszy z dwóch, jak w ocenie) · obrys: surowe wyjście kompilatora · oś: od 100 B do 10 MB, logarytmiczna
  ])
}
