#import "../../template.typ": booktable, muted, todo
#import "../../bibliography.typ": fnote
#import "helpers.typ": nr

= Funkcje i wywołania <ch:calls>

Typ funkcji w WebAssembly to lista typów parametrów i lista typów wyników, na przykład `(param i32 i32) (result i32)`. Platforma nie ma krotek ani struktur: funkcja przyjmuje płaską listę wartości i zwraca płaską listę wartości. Rozdział #nr(<ch:stack-values>) opisał, jak każdy typ WX jest przechowywany jako taka lista. Ten rozdział pokazuje, jak funkcje WX korzystają z tego opisu. Reguła jest krótka: *każda funkcja przyjmuje dokładnie jedną wartość*, a jej parametrami w WebAssembly jest reprezentacja tej wartości. Reszta rozdziału z niej wynika, a głównym rezultatem jest to, że kod generyczny może opisać dowolną funkcję dwoma typami, bez typów wariadycznych.

== Problem: opisać dowolną funkcję <sec:call-trait>

Kod generyczny operujący na funkcjach potrzebuje typu dla wejścia funkcji. Najmniejszym przykładem jest składanie funkcji. `compose(f, g, x)` oblicza `g(f(x))`, a jego sygnatura musi mówić, że `g` przyjmuje to, co zwraca `f`, dla funkcji o dowolnej liczbie parametrów:

```wx
func add(a: i32, b: i32) -> i32 { a + b }
func twice(x: i32) -> i32 { x * 2 }

compose(add, twice, (1, 2))  // twice(add(1, 2)) = 6
```

`add` przyjmuje dwie wartości, a `twice` jedną. Rust opisuje funkcje traitami `Fn`, które przyjmują typy argumentów jako krotkę: `Fn<(i32, i32)>` dla dwóch argumentów i `Fn<(i32,)>`, z krotką jednoelementową, dla jednego. Ponieważ funkcja w Ruście tak naprawdę nie przyjmuje krotki, kompilator potrzebuje specjalnej konwencji wywołań, by rozłożyć krotkę na osobne argumenty, a kod użytkownika nie może implementować tych traitów w stabilnym Ruście. C++ i Swift używają zamiast tego *typów wariadycznych* (ang. _variadic generics_): parametru typu, który oznacza listę typów, z własną składnią.

Celem było coś prostszego: opisać dowolną funkcję dwoma typami, jej argumentami i jej wynikiem, bez typów wariadycznych i bez składni rozwijania.

== Każda funkcja przyjmuje jedną wartość <sec:one-parameter>

WX przejmuje swoją regułę z rodziny języków ML: funkcja przyjmuje dokładnie jedną wartość, a lista parametrów jest notacją typu tej wartości (tabela #nr(<tbl:parameter-type>)).

#figure(
  booktable(
    columns: (auto, auto),
    align: (left, left),
    table.header([Zapis], [Jedna wartość, którą przyjmuje funkcja]),
    table.hline(stroke: 0.5pt),
    [`func() -> R`],
    [`()`],
    [`func(A) -> R`],
    [`A`],
    [`func(A, B) -> R`],
    [`(A, B)`],
    [`func((A, B)) -> R`],
    [`(A, B)`, ten sam typ co w wierszu wyżej],
  ),
  caption: [Typ parametru funkcji według zapisanej listy parametrów.],
) <tbl:parameter-type>

WX utożsamia krotkę jednoelementową z jej elementem: `(T)`, `(T,)` i `T` to ten sam typ. Dzięki temu typ argumentu `func(T)` jest równy `T`, a ta sama reguła wywołania obejmuje zero, jeden lub kilka parametrów. Rust natomiast odróżnia `(T,)` od `T`.

Przy jednej wartości na funkcję trait dla wszystkiego, co można wywołać, potrzebuje tylko dwóch typów skojarzonych:

```wx
pub trait Call: StackValue {
    type Args: StackValue;
    type Result: StackValue;

    func call(self: Self, args: Self::Args) -> Self::Result;
}
```

Kompilator implementuje `Call` dla każdego itemu funkcji, więc `<add as Call>::Args` to `(i32, i32)`, a `<twice as Call>::Args` to `i32`. Implementuje go także dla każdego typu referencji do funkcji `func(A) -> R`. Program może zaimplementować `Call` dla własnych typów, a wtedy wartość tego typu można wywołać jak funkcję: `v(a, b)` oznacza `v.call((a, b))`.

Teraz `compose` jest zwykłą funkcją generyczną:

```wx
func compose<F: Call, G: Call where { Args = F::Result }>(
    f: F,
    g: G,
    x: F::Args,
) -> G::Result {
    g(f(x))
}
```

`F::Args` to to, co przyjmuje `f`: para dla `add`, jedna wartość dla `twice`, `()` dla funkcji bez parametrów. Ograniczenie `Args = F::Result` mówi, że `g` przyjmuje to, co zwraca `f`. Ponieważ kilka wartości i krotka to to samo, funkcję zwracającą parę można złożyć z funkcją o dwóch parametrach:

```wx
func divmod(a: i32, b: i32) -> (i32, i32) { (a / b, a % b) }

compose(add, twice, (1, 2))    // 6
compose(divmod, add, (17, 5))  // add(3, 2) = 5
```

Obecny moduł sprawdzania typów przyjmuje oba wywołania. Nie był potrzebny ani wariadyczny parametr typu, ani składnia rozwijania, ani specjalna konwencja wywołań.

Reguła ma jeden zaskakujący skutek. `func g(p: (A, B))` i `func f(a: A, b: B)` mają ten sam typ, bo obie przyjmują `(A, B)`. Widać to tylko w kodzie generycznym i w komunikatach o błędach i jest to dokładnie to, czego potrzebuje `compose`.

== Wywołanie funkcji <sec:filling>

Wywołanie nadal podąża za deklaracją. Pozycyjna lista argumentów daje jedną wartość dla parametrów, które wypełnia:

- Dla `f(a: A, b: B)` wywołanie `f(x, y)` przekazuje dwa argumenty. `f(p)` z `p: (A, B)` przekazuje oba naraz, bo jedna wartość dla kilku parametrów jest ich krotką.
- Dla `g(p: (A, B))` wywołania `g(x, y)` i `g((x, y))` są tym samym wywołaniem.

Kompilator nigdy nie przegrupowuje listy, by ją dopasować. Dla `add3(a: i32, b: i32, c: i32)` i `p: (i32, i32)` wywołanie `add3(p, 3)` jest błędem, a kompilator nie próbuje odczytać `p` jako dwóch argumentów. Odbiorca metody (ang. _receiver_) wypełnia jej pierwszy parametr, a lista wypełnia resztę.

== Struktury i argumenty nazwane <sec:structs>

W Ruście struktura krotkowa `struct Point(i32, i32)` jest budowana przez pozycję, a struktura rekordowa `struct Point { x: i32, y: i32 }` przez nazwanie jej pól. Te dwie formy różnią się deklaracją, konstrukcją, dostępem do pól i wzorcami. W WX jest jedna forma struktury, a jej pola zapisuje się jak parametry, każde z nazwą lub bez:

```wx
struct Point(x: i32, y: i32);
struct Pair(i32, pub u8);
```

Strukturę buduje się przez wywołanie jej nazwy, jak funkcji, która zamienia pola w strukturę: `Point(1, 2)`. Kompilator sprawdza konstrukcję tym samym kodem co wywołanie funkcji, więc wszystkie komunikaty o argumentach są wspólne.

Skoro konstrukcja jest wywołaniem, nazywanie pól przy konstrukcji oznacza nazywanie argumentów wywołania. Dlatego każde wywołanie może nazwać swoje argumenty, grupą w nawiasach klamrowych:

```wx
func blit(dst: heap::*u8, src: heap::&u8, len: u32) { .. }

blit({ dst: buffer, src: image, len: 64 })
blit({ len, src: image, dst: buffer })    // to samo wywołanie; `len` znaczy `len: len`
Point({ x: 1, y: 2 })
```

Nazwy czynią widocznymi role argumentów, takie jak cel i źródło w `blit`. Wywołanie jest albo pozycyjne, albo nazwane, nigdy mieszane. Nazwy należą do deklaracji i nigdy nie są częścią typu, więc referencję do funkcji `func(A, B) -> R`, która nie ma nazw, wywołuje się pozycyjnie (listing #nr(<fig:named-reference>)). Argumenty nazwane nie tworzą struktury i nie zmieniają sygnatury w WebAssembly.

#figure(
  kind: raw,
  supplement: [Listing],
  text(size: 0.8em)[
    ```text
    error[E2123]: a value of type `func(i32, i32) -> i32` is called through `Call`, so it is called by position
         ┌─ /main.wx:2378:47
         │
    2378 │ func apply(f: func(i32, i32) -> i32) -> i32 { f({ a: 1, b: 2 }) }
         │                                               ^^^^^^^^^^^^^^^^^
    ```
  ],
  caption: [Wywołanie przez nazwy wymaga deklaracji. Referencja do funkcji ma tylko typ, a typ nie ma nazw parametrów. Test dołącza swój kod do biblioteki standardowej, stąd numery wierszy.],
) <fig:named-reference>

Argumenty nazwane oddzielają też kolejność obliczania od kolejności parametrów. Wyrażenia są obliczane od lewej do prawej, tak jak zapisano je w miejscu wywołania, nawet gdy nazwy występują w innej kolejności niż w deklaracji. Powstałe wartości są następnie układane w kolejności parametrów. Na przykład:

```wx
struct Point(x: i32, y: i32);

Point({
    y: compute_y(),
    x: compute_x(),
})
```

Jest to równoważne, pod względem kolejności obliczania i wyniku, z:

```wx
local y = compute_y();
local x = compute_x();
Point(x, y)
```

Tutaj `compute_y` wykonuje się przed `compute_x`, co ma znaczenie, jeśli któreś z wywołań ma efekty uboczne. Powstały `Point` nadal ma pola w kolejności deklaracji, `(x, y)`. Ta sama reguła dotyczy nazwanych argumentów funkcji. Kompilator może zoptymalizować obliczanie, ale tylko wtedy, gdy zachowuje obserwowalne zachowanie.

Wzorzec rozbiera strukturę tą samą składnią, która ją buduje: `local Point(a, b) = p;` lub `local Point({ x, y: py }) = p;`. WX nie ma pozycyjnego dostępu do pól jak `t.0` w Ruście. Krotkę rozbiera się wzorcem, a pole struktury czyta po nazwie.

== Reprezentacja funkcji i ABI <sec:calls-abi>

Traktowanie `func(A, B)` i `func((A, B))` jako jednego typu jest poprawne tylko wtedy, gdy obie kompilują się do tego samego typu funkcji WebAssembly. Tak jest. Parametrami funkcji w WebAssembly jest reprezentacja na stosie jej `Args` (podrozdział #nr(<sec:stack-repr>)), a wynikami reprezentacja jej `Result` (tabela #nr(<tbl:call-abi>)).

#figure(
  booktable(
    columns: (auto, auto),
    align: (left, left),
    table.header([Funkcja WX], [Typ WebAssembly]),
    table.hline(stroke: 0.5pt),
    [`func add(a: i32, b: i32) -> i32`],
    [`(param i32 i32) (result i32)`],
    [`func g(p: (i32, i32)) -> i32`],
    [`(param i32 i32) (result i32)`],
    [`func divmod(a: i32, b: i32) -> (i32, i32)`],
    [`(param i32 i32) (result i32 i32)`],
    [`func shift(p: Point, d: u8) -> Point`],
    [`(param i32 i32 i32) (result i32 i32)`],
    [`func reset()`],
    [`(param) (result)`],
  ),
  caption: [Typ WebAssembly funkcji WX jest reprezentacją na stosie jej `Args` i `Result`.],
) <tbl:call-abi>

Funkcja zwracająca kilka wartości używa multi-value, bez ukrytego wskaźnika na wynik. Struktura przekazywana lub zwracana przez wartość jest spłaszczana do swoich pól w kolejności deklaracji, zgodnie z `StackValue::Repr` (podrozdział #nr(<sec:stack-repr>)). Jej układ w pamięci liniowej jest od tej kolejności niezależny. Na przykład `func(u8, u64)` staje się `(param i32 i64)`, niezależnie od tego, jak te typy byłyby ułożone w pamięci.

Dla funkcji importowanych i eksportowanych ta reprezentacja wyznacza dokładny ciąg typów parametrów i wyników WebAssembly widocznych dla hosta. Pozostaje stabilna niezależnie od optymalizacji układu pamięci i od kolejności argumentów nazwanych w miejscu wywołania. Funkcje wewnętrzne mogą podlegać przekształceniom, takim jak wstawianie funkcji (ang. _inlining_) czy usuwanie nieużywanych parametrów, o ile zachowane jest ich obserwowalne zachowanie. Funkcje na granicy modułu muszą jednak zachować zadeklarowane sygnatury. Dzięki temu WX może optymalizować swój wewnętrzny kod bez zmiany interfejsu widzianego przez hosta.

`Repr` definiuje podstawową reprezentację wywołań w WebAssembly, a nie pełne ABI między językami. Typy o tej samej reprezentacji mogą mieć różne znaczenie: `(u32, i32)` i `(i32, u32)` stają się `(i32, i32)`. Host musi więc uzgodnić znaczenie i kolejność wartości, a nie tylko ich typy WebAssembly.

== Porównanie <sec:calls-comparison>

#figure(
  booktable(
    columns: (auto, 1fr, 1fr, 1fr),
    align: (left, left, left, left),
    table.header([Język], [Argumenty jako jedna wartość], [Krotka jednoelementowa], [Argumenty nazwane]),
    table.hline(stroke: 0.5pt),
    [Standard ML],
    [tak],
    [brak],
    [nie; zamiast tego przekazuje się rekord],
    [Rust],
    [tylko w traitach `Fn`],
    [`(T,)`, różna od `T`],
    [nie],
    [Swift],
    [usunięte (SE-0029); typy funkcji rozdzielone (SE-0110)],
    [brak],
    [tak, część nazwy funkcji],
    [Python],
    [nie],
    [`(x,)`],
    [tak, można mieszać z pozycyjnymi],
    [Kotlin],
    [nie],
    [brak krotek],
    [tak, można mieszać z pozycyjnymi],
    [WX],
    [tak],
    [brak: `(T,)` to `T`],
    [tak, z deklaracji, nigdy mieszane, nie w typach],
  ),
  caption: [Sposoby przekazywania argumentów w WX i pięciu innych językach.],
) <tbl:calls-comparison>

Wiersze opierają się na definicji Standard ML #fnote("milner1997"), dokumentacji Rusta dotyczącej traitów `Fn` #fnote("rust-fn-traits") i typów krotkowych #fnote("rust-tuples"), książce o Swifcie #fnote("swift-functions") oraz dokumentacji Pythona #fnote("python-functions")#super[,]#fnote("python-tuples") i Kotlina #fnote("kotlin-functions").

Standard ML jest źródłem reguły jednej wartości: funkcja przyjmuje jeden argument, a funkcja wielu parametrów przyjmuje krotkę. WX zachowuje tę regułę i dodaje nazwy argumentów.

Swift wypróbował ten sam pomysł i z niego zrezygnował. Wczesny Swift pozwalał wywołać funkcję wielu parametrów jedną krotką. SE-0029 usunęło to „rozwijanie krotki” (ang. _tuple splat_) #fnote("swift-se0029"), między innymi dlatego, że etykiety krotki musiały zgadzać się z etykietami funkcji. SE-0110 uczyniło następnie funkcję wielu parametrów i funkcję jednej krotki różnymi typami #fnote("swift-se0110")\; później dodano wyjątek, który zachowuje wygodę domknięć. W WX nazwy nigdy nie są częścią typu, więc taki konflikt nie może wystąpić.

// Open point (2026-10-30): a struct constructor is not a first-class value yet (`compose(divmod, Point, ..)` is
// rejected, E2110). It may become a function item later.
