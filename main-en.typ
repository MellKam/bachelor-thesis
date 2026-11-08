#import "template.typ": *
#import "bibliography.typ": render-bibliography

// Everything a department is likely to want on the title page.
// Metadata follows the WSZiB-ANS standard (Rysunek 1).
#let meta = (
  lang: "en",
  title: "Projektowanie i implementacja języka programowania opartego na WebAssembly",
  subtitle: "Design and Implementation of a Programming Language Based on WebAssembly",
  author: "Artem Melnyk",
  supervisor: "prof. WSZiB - ANS dr inż. Janusz Majewski",
  auxiliary-supervisor: "mgr inż. Marta Majewska",
  university: "Wyższa Szkoła Zarządzania i Bankowości\n- Akademia Nauk Stosowanych w Krakowie",
  faculty: "Wydział Nauk Stosowanych",
  field: "Informatyka",
  scope: "Programowanie obiektowe",
  degree: "PRACA DYPLOMOWA",
  place: "KRAKÓW",
  date: "2026",
)

// Read by the Makefile to name the PDF (author and English title).
#metadata(meta) <thesis-meta>

#show: thesis.with(meta: meta)

#title-page(meta)

#show: front-matter

#contents()

// Original Polish text from the thesis proposal. It no longer matches the thesis;
// translate the English abstract below for the Polish edition (streszczenie).
//
//   WebAssembly (WASM) zajmuje obecnie istotną pozycję wśród platform docelowych dla
//   języków programowania. Jednakże, wiele istniejących kompilatorów traktuje go
//   podobnie jak asembler maszynowy, często produkując rozbudowany i nieefektywny kod
//   bajtowy. Niniejsza praca przedstawia język programowania zaprojektowany specjalnie
//   dla WebAssembly, zoptymalizowany tak, aby w pełni wykorzystać funkcje WASM i
//   standardy ekosystemu, takie jak Wasm Interface Types (WIT). Celem jest zapewnienie
//   solidnego wsparcia narzędziowego, w tym podświetlania składni i implementacji
//   Language Server Protocol (LSP), przy jednoczesnym uproszczeniu procesu debugowania
//   poprzez obsługę zarówno tekstowego, jak i binarnego formatu WASM. Aby
//   zademonstrować jego skuteczność, przedstawię przykładowy projekt, który prezentuje
//   funkcje języka i ilustruje jego praktyczne zastosowanie w procesach programowania
//   webowego.
#abstract[
  WebAssembly (Wasm) was designed to support programs compiled from many languages. That flexibility has helped bring existing software to new environments, including the browser. It also means that developers usually work with Wasm through a language designed around a particular way of writing programs. The language decides which parts of Wasm are visible, how memory is handled, and what additional runtime support is needed. Even a language built for Wasm can expose only one view of what the platform offers.

  This thesis presents WX, a language whose type system and supporting compiler mechanisms are shaped by Wasm's model. They make it possible to describe module resources directly in source code and check how those resources are used. This gives developers a more direct way to program for Wasm without committing every program to the same runtime or memory-management strategy. The goal is to make Wasm a platform developers can program against deliberately, rather than something they see only after compilation.

  The thesis presents the language design, implements its core in a proof-of-concept Rust compiler, and examines it with example programs and a comparison with other languages that target Wasm.
]

#show: main-matter

#include "chapters/en/01-introduction.typ"
#include "chapters/en/02-background.typ"
#include "chapters/en/03-items.typ"
#include "chapters/en/04-stack-values.typ"
#include "chapters/en/05-calls.typ"
#include "chapters/en/06-intrinsics.typ"
#include "chapters/en/07-bodies.typ"
#include "chapters/en/08-hosts.typ"
#include "chapters/en/09-implementation.typ"
#include "chapters/en/10-evaluation.typ"
#include "chapters/en/11-conclusion.typ"

#unnumbered[Bibliografia]
#render-bibliography()

#figure-lists()
