#import "template.typ": *
#import "bibliography.typ": render-bibliography

// Polish edition: every chapter is included from chapters/pl.

// Everything a department is likely to want on the title page.
// Metadata follows the WSZiB-ANS standard (Rysunek 1).
#let meta = (
  lang: "pl",
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

#abstract[
  WebAssembly (Wasm) zaprojektowano tak, aby obsługiwał programy kompilowane z wielu języków. Ta elastyczność pomogła przenieść istniejące oprogramowanie do nowych środowisk, także do przeglądarki. Oznacza ona jednak również, że programiści zwykle pracują z Wasm za pośrednictwem języka zbudowanego wokół określonego sposobu pisania programów. To język decyduje, które części Wasm są widoczne, jak zarządzana jest pamięć i jakiego dodatkowego wsparcia środowiska uruchomieniowego potrzeba. Nawet język stworzony dla Wasm pokazuje tylko wybrany wycinek tego, co platforma oferuje.

  Praca przedstawia WX, język, którego system typów i wspierające go mechanizmy kompilatora wynikają z modelu Wasm. Pozwalają one opisać zasoby modułu wprost w kodzie źródłowym i sprawdzać, jak są używane. Dzięki temu programista może programować dla Wasm bardziej bezpośrednio, bez przypisywania każdego programu do tego samego środowiska uruchomieniowego czy strategii zarządzania pamięcią. Celem jest, aby Wasm stał się platformą, dla której programuje się świadomie, a nie czymś, co widać dopiero po kompilacji.

  W pracy opisano projekt języka, zaimplementowano jego rdzeń w prototypowym kompilatorze napisanym w Rust i zbadano go na programach przykładowych oraz przez porównanie z innymi językami kompilowanymi do Wasm.
]

#show: main-matter

#include "chapters/pl/01-introduction.typ"
#include "chapters/pl/02-background.typ"
#include "chapters/pl/03-items.typ"
#include "chapters/pl/04-stack-values.typ"
#include "chapters/pl/05-calls.typ"
#include "chapters/pl/06-intrinsics.typ"
#include "chapters/pl/07-bodies.typ"
#include "chapters/pl/08-hosts.typ"
#include "chapters/pl/09-implementation.typ"
#include "chapters/pl/10-evaluation.typ"
#include "chapters/pl/11-conclusion.typ"

#unnumbered[Bibliografia]
#render-bibliography()

#figure-lists()
