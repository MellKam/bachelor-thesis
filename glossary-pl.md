# Glosariusz EN → PL (wersja polska pracy)

Terminy zatwierdzone po rozdziale 1; uzupełniany w kolejnych rozdziałach.

| EN | PL | Uwagi |
|---|---|---|
| sandbox | izolowane środowisko / piaskownica | przy pierwszym użyciu (ang. _sandbox_) |
| bytecode | kod bajtowy | |
| linear memory | pamięć liniowa | |
| garbage collection | odśmiecanie pamięci | przy pierwszym użyciu (ang. _garbage collection_); „WebAssembly GC" jako nazwa rozszerzenia |
| multiple memories | wiele pamięci | |
| exception handling | obsługa wyjątków | |
| stack switching | przełączanie stosów | |
| Component Model | Component Model | nazwa własna, bez tłumaczenia |
| host | host | bez tłumaczenia |
| toolchain | toolchain | bez tłumaczenia |
| glue code | kod sklejający | |
| binding generators | generatory powiązań | |
| entity (module entity) | encja (modułu) | do decyzji, zob. uwagi |
| item | item (itemy, itemu) | do decyzji, zob. uwagi |
| global | zmienna globalna | słowo kluczowe `global` bez zmian |
| table / tag | tabela / tag | |
| zero-sized type | typ o zerowym rozmiarze | |
| type system | system typów | |
| trait | trait (traity) | |
| generics / generic code | typy generyczne / kod generyczny | |
| pointer | wskaźnik | |
| stack value | wartość na stosie | |
| intrinsic | funkcja wewnętrzna | do decyzji, zob. uwagi |
| proof-of-concept | prototypowy (kompilator) | |
| standard library | biblioteka standardowa | |
| first-class | pełnoprawny | |
| opt-in | na życzenie / w miarę potrzeby | |
| inlining | wstawianie funkcji | przy pierwszym użyciu (ang. _inlining_) |
| dead-code elimination | eliminacja martwego kodu | |
| effect tracking | śledzenie efektów | |
| memory safety | bezpieczeństwo pamięci | |
| findings | ustalenia | |
| conclusion | zakończenie | rozdz. 11 |
| thesis (self-reference) | praca | bez „niniejsza praca" |
| exposure / integration | udostępnienie / integracja | rozdz. 2; „dostępność" odrzucone (kojarzy się z accessibility) |
| route (in the study) | droga | rozdz. 2 |
| trap | trap | przy pierwszym użyciu (ang. _trap_) |
| identity / shape (of an entity) | tożsamość / kształt | rozdz. 3 |
| ownership (`*` / `&`) | własność (nazwa części typu wskaźnika); `*` wyłączny, `&` współdzielony | rozdz. 3; „własnościowy" odrzucone (kompilator ma Exclusive/Shared) |
| immediate (instruction operand) | argument natychmiastowy (ang. _immediate_) | |
| fat pointer | gruby wskaźnik (ang. _fat pointer_) | |
| associated type / constant | typ skojarzony / stała skojarzona | |
| typeset | typeset | słowo kluczowe, „zamknięty zbiór typów" |
| open / closed trait | otwarty / zamknięty trait | |
| bound (`G: GlobalMut`) | ograniczenie | |
| allocator | alokator | |
| polymorphism | polimorfizm | |
| placeholder type | typ zastępczy | |
| static data | dane statyczne | |
| stack value / stack representation | wartość stosowa / reprezentacja na stosie | rozdz. 4 |
| marker trait | trait znacznikowy | |
| normal form | postać normalna | |
| padding | dopełnienie (ang. _padding_) | |
| slice, tuple, struct | slice, krotka, struktura | `enum` bez zmian; unikać „slice slice'ów" i „pod-slice" |
| variadic generics | typy wariadyczne (ang. _variadic generics_) | rozdz. 5 |
| calling convention | konwencja wywołań | |
| named / positional arguments | argumenty nazwane / pozycyjne | |
| receiver | odbiorca (ang. _receiver_) | |
| closure | domknięcie | |
| pattern | wzorzec | |
| function reference | referencja do funkcji | |
| intrinsic | funkcja wewnętrzna (ang. _intrinsic_) | rozdz. 6; „funkcja wbudowana" = builtin |
| inline assembly | asembler wbudowany | |
| place | miejsce (ang. _place_) | |
| statement | polecenie (ang. _statement_) | rozdz. 7; „instrukcja" zarezerwowana dla instrukcji Wasm; „polecenie" nie dla WASI command ani CLI |
| structured control flow | strukturalny przepływ sterowania | |
| branch (`br`) | skok | |
| exhaustiveness check | sprawdzanie wyczerpywalności | |
| polymorphic stack | stos polimorficzny | |
| bidirectional type checking | dwukierunkowe sprawdzanie typów | |
| sum types | typy sumy | |
| sentinel | wartownik | |
| (WASI) command | program typu _command_ | rozdz. 8; „polecenie" zarezerwowane dla statement |
| witness (exhaustiveness) | kontrprzykład (ang. _witness_) | |
| open enum | enum otwarty | |
| arena / bump allocator | arena / alokator typu bump | |
| view (of bytes) | widok | |
| embedding (host) | środowisko osadzające | |
| front end | front end | rozdz. 9 |
| checker | sprawdzanie typów (w rysunku: „Sprawdzanie") | |
| lowering | obniżanie (ang. _lowering_) w tekście i nagłówkach; „Lowering" tylko jako nazwa etapu na rysunku | |
| inlining | inlining / wstawianie funkcji | w rysunkach „Inlining" |
| monomorphization | monomorfizacja | |
| solver | solver | |
| scheduler | scheduler | |
| span | zakres w źródle (ang. _span_) | |
| snapshot (test) | snapshot / test snapshotowy | |
| stackify | układać wartości na stosie (ang. _stackify_) | rozdz. 10 |
| effect handlers / typed continuations | handlery efektów / typowane kontynuacje | WasmFX bez zmian |
| borrow checker | kontrola pożyczek (ang. _borrow checker_) | |
| canonical ABI | kanoniczne ABI | |

## Odsyłacze do rozdziałów
Szablon wymusza „Rozdział N" w mianowniku dla każdego `@ch:...`, co w polskim zdaniu daje „w rozdziale Rozdział 1". W tekście polskim używamy `#nr(<etykieta>)` z `chapters/pl/helpers.typ`: pisze się rzeczownik w odpowiednim przypadku, a makro daje sam numer.
