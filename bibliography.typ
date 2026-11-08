// Citations in the WSZiB-ANS style: footnotes (10 pt, single spacing, ending with a full stop) in the
// formats of Table 1 of the standard, and a bibliography grouped by kind of source and sorted
// alphabetically. Data is in refs.yml; only the sources that are cited are listed.

#import "template.typ": todo

#let data = yaml("refs.yml")
#let months = ("stycznia", "lutego", "marca", "kwietnia", "maja", "czerwca", "lipca", "sierpnia", "września", "października", "listopada", "grudnia")
#let nb = sym.space.nobreak

#let date-text(d) = {
  let p = d.split("-")
  str(int(p.at(2))) + nb + months.at(int(p.at(1)) - 1) + nb + p.at(0)
}
// "A. B. Surname" in a note, "Surname A. B." in the list; more than three authors: the first and "i in."
#let note-name(a) = a.given + nb + a.family
#let list-name(a) = a.family + nb + a.given
#let people(list, f) = if list.len() > 3 { f(list.first()) + " i in." } else { list.map(f).join(", ") }
#let lead(e, f) = if "authors" in e { people(e.authors, f) } else if "organization" in e { e.organization } else { none }

#let year-place(e) = {
  let place = e.at("place", default: none)
  (if place != none { place + " " } else { "" }) + e.year
}

// The body of a note for one entry (Table 1 of the standard).
#let note-body(e, page) = {
  let pages = if page != none { [, s. #page] } else { [] }
  let who = lead(e, note-name)
  if e.type == "book" {
    [#who, #emph(e.title), #e.publisher, #year-place(e)#pages.]
  } else if e.type == "collection" {
    let pub = if "publisher" in e { e.publisher + ", " } else { "" }
    [#who, #emph(e.title), \[w:\] #e.in, #pub#year-place(e)#pages.]
  } else if e.type == "article" {
    let nr = if "number" in e { ", nr " + e.number } else { "" }
    [#who, #emph(e.title), „#e.journal” #e.year#nr#pages.]
  } else {
    let when = if "accessed" in e { date-text(e.accessed) } else { todo[wpisać datę] }
    [#if who != none [#who, ]#e.title, #link(e.url) (data odczytu #when).]
  }
}

#let last-cited = state("wx-last-cited", none)

// Footnote for a source. A repeated citation of the previous note is "Ibidem".
#let fnote(key, p: none) = {
  let e = data.at(key)
  [#metadata(key) <wx-cited>]
  context {
    let previous = last-cited.get()
    last-cited.update(key)
    if previous == key {
      footnote[Ibidem#if p != none [, s. #p].]
    } else {
      footnote(note-body(e, p))
    }
  }
}

// The bibliography: only cited sources, in groups, alphabetical, numbered afresh in each group.
#let render-bibliography() = context {
  let keys = query(<wx-cited>).map(m => m.value).dedup()
  let pl = text.lang == "pl"
  let groups = (
    (if pl { "Książki i publikacje konferencyjne" } else { "Books and conference papers" }, ("book", "collection")),
    (if pl { "Czasopisma" } else { "Journals" }, ("article",)),
    (if pl { "Netografia" } else { "Web sources" }, ("web",)),
  )
  for (name, types) in groups {
    let entries = keys.map(k => data.at(k)).filter(e => e.type in types)
    if entries.len() == 0 { continue }
    let sorted-entries = entries.sorted(key: e => lower(if lead(e, it => it.family) != none { lead(e, it => it.family) } else { e.title }))
    block(above: 1.4em, below: 0.6em, text(weight: "bold", name))
    set par(first-line-indent: 0pt, justify: false, hanging-indent: 1.25cm, leading: 0.8em, spacing: 0.7em)
    for (i, e) in sorted-entries.enumerate() {
      let who = lead(e, list-name)
      let line = if e.type == "book" {
        [#who, #emph(e.title), #e.publisher, #year-place(e).]
      } else if e.type == "collection" {
        let pub = if "publisher" in e { e.publisher + ", " } else { "" }
        let pp = if "pages" in e { [, s. #e.pages] } else { [] }
        [#who, #emph(e.title), \[w:\] #e.in, #pub#year-place(e)#pp.]
      } else if e.type == "article" {
        let nr = if "number" in e { ", nr " + e.number } else { "" }
        let pp = if "pages" in e { [, s. #e.pages] } else { [] }
        [#who, #emph(e.title), „#e.journal” #e.year#nr#pp.]
      } else {
        [#if who != none [#who, ]#e.title, #link(e.url).]
      }
      [#(i + 1).#h(0.5em)#line]
      parbreak()
    }
  }
}
