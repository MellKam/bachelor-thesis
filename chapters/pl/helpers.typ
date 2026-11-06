// Helpers shared by the Polish chapters.
//
// A reference like `@ch:background` renders "Rozdział N" (nominative, and the
// template forces it for chapters), `@fig:x` renders "Wykres N": neither fits a
// Polish sentence ("w rozdziale Rozdział 1", "na Wykres 2"). `nr` renders only
// the number, so the text carries the noun in the right case:
// `w rozdziale #nr(<ch:background>)`, `na wykresie #nr(<fig:matrix>)`.
#let nr(label) = context {
  let el = query(label).first()
  if el.func() == figure {
    link(label, numbering(el.numbering, ..counter(figure.where(kind: el.kind)).at(label)))
  } else {
    link(label, numbering("1.1", ..counter(heading).at(label)))
  }
}
