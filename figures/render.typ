// Renders one figure of the thesis to a picture, so that it reaches Word (and any PDF-to-Word
// converter) as an image and not as loose shapes. Drawn by the same code as before, so fonts and
// colours are those of the thesis. Used by `make figures`:
//   typst compile --font-path fonts --format png --ppi 300 \
//     --input chart=reach --input lang=pl figures/render.typ figures/build/reach-pl.png
#import "charts.typ" as chen
#import "charts-pl.typ" as chpl
#import "architecture.typ" as aen
#import "architecture-pl.typ" as apl

#let pl = sys.inputs.lang == "pl"
#let ch = if pl { chpl } else { chen }
#let arch = if pl { apl } else { aen }
#let which = sys.inputs.chart

// the text width of the thesis (A4 with 2.5 cm margins), so the picture is placed at 100%
#set page(width: 16cm, height: auto, margin: (x: 0pt, y: 6pt), fill: white)
#set par(leading: 0.65em)

#align(center, {
  if which == "reach" { ch.reach-figure() }
  else if which == "exposure" { ch.exposure-figure() }
  else if which == "size-wx" { ch.size-figure(langs: ch.order + ("wx",), highlight: "wx") }
  else if which == "impl-size" { arch.size-figure() }
  else if which == "pipeline" { arch.pipeline-figure() }
  else { panic("unknown chart: " + which) }
})
