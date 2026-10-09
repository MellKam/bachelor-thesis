#import "template.typ": *

// Everything a department is likely to want on the title page. Placeholders are
// marked TBD; they are the only things to fill in before the first full build.
#let meta = (
  lang: "en",
  // Polish: "Projektowanie i implementacja języka programowania opartego na WebAssembly"
  title: "Design and Implementation of a Programming Language Based on WebAssembly",
  author: "Artem Melnyk",
  // Polish: prof. WSZiB - ANS dr inż. Janusz Majewski (promotor),
  //         mgr inż. Marta Majewska (promotor pomocniczy)
  supervisor: "Prof. Janusz Majewski, PhD Eng.",
  auxiliary-supervisor: "Marta Majewska, MSc Eng.",
  // Polish: Wyższa Szkoła Zarządzania i Bankowości w Krakowie
  university: "School of Management and Banking in Kraków",
  // Polish: Wydział Nauk Stosowanych
  faculty: "Faculty of Applied Sciences",
  // Polish: Informatyka (stacjonarne), zakres kształcenia: Programowanie obiektowe
  programme: "Computer Science, specialisation: Object-Oriented Programming",
  // Polish: Praca inżynierska
  degree: "Engineering thesis",
  place: "Kraków",
  date: "2026",
)

#show: thesis.with(meta: meta)

#title-page(meta)

#show: front-matter

// Original Polish text, kept for the Polish edition (streszczenie):
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
  WebAssembly (Wasm) currently holds a significant position among target platforms for programming languages. However, many existing compilers treat it much like a machine assembler, often producing bloated and inefficient bytecode. This thesis presents a programming language designed specifically for WebAssembly, optimized to make full use of Wasm's features and of ecosystem standards such as the WebAssembly Interface Types (WIT). The aim is to provide solid tooling support, including syntax highlighting and an implementation of the Language Server Protocol (LSP), while simplifying the debugging process through support for both the text and binary formats of Wasm. To demonstrate its effectiveness, I will present an example project that showcases the language's features and illustrates its practical use in web development workflows.
]

#contents()
#figure-lists()

#show: main-matter

#include "chapters/en/01-introduction.typ"
#include "chapters/en/02-background.typ"
#include "chapters/en/03-items.typ"

#unnumbered[Bibliography]
#bibliography("refs.bib", title: none, style: "ieee")
