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
  WebAssembly (Wasm) has been designed as a compilation target for a wide range of programming languages, but each language reaches it through its own programming model, which hides much of what the platform offers. A comparison of eight languages on thirty Wasm features, carried out for this thesis, shows that the entities of a module, such as memories, globals, tables and tags, are rarely available as language constructs, and that no language supports multiple memories.

  This thesis explores representing Wasm's essential concepts in a language's semantics and type system, so that they are written in the source and checked by the compiler. In the proposed language, WX, every memory, global and function is an item with its own zero-sized type, and a trait implemented by the compiler describes what the item can do. Pointer types name the memory they point into, so a program can use several memories, both 32-bit and 64-bit, and write code that is generic over them. The same mechanism describes how any type is held on the Wasm stack: it decides which types a global can hold, checks reinterpretation between types, and makes the Wasm signature of a function follow directly from its source. Wasm instructions are typed functions in the standard library that take entities as items, never as integer indices. No runtime or memory-management model is imposed, so a program adopts the platform's capabilities as it needs them.

  The idea is realised in WX, a proof-of-concept compiler written in Rust, and examined through its design, its implementation, a set of example programs and a comparison with other languages that target Wasm.
]

#contents()
#figure-lists()

#show: main-matter

#include "chapters/en/01-introduction.typ"
#include "chapters/en/02-background.typ"
#include "chapters/en/03-items.typ"
#include "chapters/en/04-stack-values.typ"
#include "chapters/en/05-calls.typ"
#include "chapters/en/06-intrinsics.typ"

#unnumbered[Bibliography]
#bibliography("refs.bib", title: none, style: "ieee")
