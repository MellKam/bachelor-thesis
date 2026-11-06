#import "../../template.typ": booktable, muted, todo
#import "../../bibliography.typ": fnote
#import "helpers.typ": nr

= Wartości stosowe: typy na stosie WebAssembly <ch:stack-values>

Tabela #nr(<tbl:kinds>) podała kształt zmiennej globalnej jako typ wartości i mutowalność. W WebAssembly typ wartości jest jednym z kilku typów zdefiniowanych przez platformę. W WX zmienna globalna jest deklarowana z typem WX, a WX ma znacznie więcej typów: struktury, krotki, enumy, wskaźniki i slice'y. Ten rozdział odpowiada, które z nich może przechowywać zmienna globalna. Odpowiedź wymagała ogólniejszego pojęcia: opisu tego, jak dowolny typ WX jest przechowywany na stosie WebAssembly. Ten sam opis rozstrzyga później, jak reinterpretuje się wartości (podrozdział #nr(<sec:transmute>)) i jaka jest sygnatura funkcji w WebAssembly (rozdział #nr(<ch:calls>)).

== Zmienna globalna przechowuje jedną wartość <sec:one-value>

Zmienna globalna WebAssembly przechowuje dokładnie jedną wartość jednego typu wartości #fnote("wasm-spec-modules"):

```wat
(global $count (mut i32) (i32.const 0))
(global $scale f64 (f64.const 1.5))
```

Typami wartości są liczby `i32`, `i64`, `f32` i `f64`, typ wektorowy `v128` oraz typy referencyjne. Nie ma zmiennych globalnych będących krotkami ani strukturami. Funkcja może zwrócić kilka wartości (multi-value), ale zmienna globalna przechowuje jedną.

Typy WX nie odwzorowują się na typy wartości jeden do jednego. `u8`, `u16`, `u32`, `Bool` i `Char` są przechowywane jako jedno `i32`, podobnie jak wskaźnik do pamięci 32-bitowej. Inne typy są przechowywane jako kilka wartości albo jako żadna:

```wx
struct Meters(u32);            // jedno i32
struct Point(x: u32, y: f64);  // i32 oraz f64
global origin: Point = Point(0, 0);
```

`Meters` mieści się w zmiennej globalnej. `Point` nie, podobnie jak slice, który jest adresem i długością. Kompilator musi to rozstrzygnąć dla każdej zmiennej globalnej, a reguła powinna spełniać trzy wymagania:

- *Jeden item, jedna encja.* Zmienna globalna WX musi być dokładnie jedną zmienną globalną WebAssembly, aby host widział to, co zadeklarowano, gdy zmienna jest importowana lub eksportowana.
- *Kod generyczny.* WX sprawdza funkcję generyczną raz, dla wszystkich możliwych argumentów typów. Kod generyczny względem zmiennej globalnej (`G: Global`) musi wiedzieć, że `G::Value` mieści się w jednej wartości, nie wiedząc, czym jest `G::Value`.
- *Brak szczególnego przypadku.* Reguła powinna korzystać z mechanizmu, który już opisuje itemy (podrozdział #nr(<sec:items-summary>)), a nie ze sprawdzenia napisanego wyłącznie dla zmiennych globalnych.

== Rozważane podejścia <sec:stack-approaches>

*Rozbicie zmiennej globalnej.* Kompilator mógłby zamienić `global origin: Point` na dwie zmienne globalne WebAssembly, po jednej na pole. Wtedy jednak jeden item staje się dwiema encjami, a wyeksportowane `origin` staje się dwoma eksportami o nazwach wymyślonych przez kompilator. Host musiałby znać reguły WX, żeby z niego korzystać.

*Przechowanie wartości w pamięci.* Zmienna globalna mogłaby zawierać wskaźnik do wartości w pamięci liniowej. Wtedy jednak zmienna wymaga pamięci, jest czytana instrukcją load zamiast `global.get`, a host widzi adres. Program, który tego chce, może to już zapisać, ze zmienną globalną typu wskaźnikowego.

*Trait znacznikowy.* Wcześniejsza wersja WX miała trait `ValueType`, który kompilator implementował dla każdego typu przechowywanego jako dokładnie jedna wartość, i wymagała `Global::Value: ValueType`. To spełniało pierwsze dwa wymagania. Potrafił jednak odpowiedzieć tylko „tak” lub „nie”. Nie umiał powiedzieć, że `Meters` jest przechowywany dokładnie tak jak `u32`, więc przydawał się do zmiennych globalnych i do niczego więcej. Projekt, który go zastąpił, odpowiada na ogólniejsze pytanie.

== Reprezentacja na stosie <sec:stack-repr>

Ogólne pytanie brzmi: jak wartość danego typu jest przechowywana na stosie WebAssembly? WX odpowiada na nie traitem, który kompilator implementuje dla każdego typu:

```wx
pub trait StackValue {
    type Repr;
}

pub typeset StackScalar { i32, i64, f32, f64, funcref }
```

`Repr` opisuje ciąg typów wartości WebAssembly użytych do reprezentacji wartości WX, zapisany własnymi typami prymitywnymi WX. Pojedyncza wartość jest reprezentowana swoim typem skalarnym, kilka wartości krotką, a brak wartości przez `()`. WX utożsamia krotkę jednoelementową z jej elementem, więc przypadek jednej wartości nie wymaga osobnej postaci krotki. Przykłady podaje tabela #nr(<tbl:repr>).

#figure(
  booktable(
    columns: (auto, auto),
    align: (left, left),
    table.header([Typ], [`Repr`]),
    table.hline(stroke: 0.5pt),
    [`u8`, `i16`, `u32`, `i32`, `Bool`, `Char`],
    [`i32`],
    [`u64`, `i64`],
    [`i64`],
    [`f32`, `f64`],
    [`f32`, `f64`],
    [`funcref`, `func(A) -> R`],
    [`funcref`],
    [enum],
    [`Repr` jego typu reprezentacji],
    [`M::*T`, `M::&T`],
    [jak `M::Size` (adres)],
    [`M::&[T]`],
    [jak `M::Size`, dwukrotnie (adres i długość)],
    [`Meters(u32)`],
    [`i32`],
    [`Point(x: u32, y: f64)`, `(u8, f64)`],
    [`(i32, f64)`],
    [`()`, typ itemu],
    [`()`],
    [`!`, `(u32, !)`],
    [`!`],
  ),
  caption: [Reprezentacja na stosie wybranych typów WX. Części są spłaszczane w kolejności deklaracji, a części o zerowym rozmiarze są pomijane.],
) <tbl:repr>

W kodzie źródłowym nie pisze się żadnego `impl StackValue`. Kompilator wyprowadza reprezentację ze struktury typu, gdy jest potrzebna. Struktury i krotki są spłaszczane w kolejności deklaracji, z pominięciem części o zerowym rozmiarze. Trait obejmuje typy wartości czasu wykonania oraz `!` (typ bez wartości). Jeśli typ zawiera `!` gdziekolwiek, jego reprezentacją jest w całości `!`, jak pokazują ostatnie wiersze tabeli #nr(<tbl:repr>).

`StackScalar` jest typesetem (podrozdział #nr(<sec:typesets>)) typów jednej wartości WebAssembly. Brakuje w nim `v128` tylko dlatego, że WX nie obsługuje jeszcze SIMD. `funcref` to referencja do funkcji WebAssembly o dowolnej sygnaturze.

*Stos, a nie pamięć.* `StackValue` opisuje wartości na stosie WebAssembly: w zmiennych lokalnych, parametrach, wynikach i zmiennych globalnych. Ta reprezentacja jest odrębna od sposobu przechowywania wartości w pamięci liniowej. W pamięci kompilator kontroluje offsety pól, wyrównanie i dopełnienie (ang. _padding_), więc WX domyślnie zmienia kolejność pól struktury, aby zmniejszyć dopełnienie. Struktura oznaczona `#[fixed_order]` zachowuje natomiast kolejność deklaracji, choć wyrównanie może nadal wymagać dopełnienia.

Stos WebAssembly nie ma równoważnych wymagań co do układu. Jego wartościami zajmuje się środowisko uruchomieniowe, które może trzymać je w rejestrach lub fizycznej pamięci stosu. Ich fizyczne rozmieszczenie nie jest kontrolowane przez WX. Dlatego `Repr` zawsze spłaszcza pola w kolejności deklaracji, pomijając części o zerowym rozmiarze, niezależnie od ich układu w pamięci. Dzięki temu każdy typ ma przewidywalną reprezentację na stosie, bez narzucania decyzji o układzie pamięci wywołaniom funkcji ani wartościom lokalnym.

== Zmienne globalne jako ograniczenie <sec:globals-bound>

Dzięki `Repr` reguła dla zmiennych globalnych to jedno ograniczenie w traicie `Global`:

```wx
pub trait Global {
    type Value: StackValue where { Repr: StackScalar };

    func get(self: Self) -> Self::Value {
        global_get(self)
    }
}
```

Wartość zmiennej globalnej musi być przechowywana jako dokładnie jedna wartość WebAssembly. Dla `global origin: Point = ..` kompilator zapisuje `impl Global for origin { type Value = Point; }`, a ten impl musi spełniać ograniczenia traitu jak każdy inny. `Point` ich nie spełnia, a błąd jest zwykłym błędem niespełnionego ograniczenia (listing #nr(<fig:global-diagnostic>)).

#figure(
  kind: raw,
  supplement: [Listing],
  text(size: 0.8em)[```text
  error[E2063]: the trait bound `(i32, f64): StackScalar` is not satisfied
     ┌─ /main.wx:20:16
     │
  10 │ trait Global { type Value: StackValue where { Repr: StackScalar }; }
     │                                                     ----------- required by a bound in `Global`
     ·
  20 │ global origin: Pair = Pair(0, 0);
     │                ^^^^ the trait `StackScalar` is not implemented for `(i32, f64)`
  ```],
  caption: [Zmienna globalna o dwóch wartościach jest odrzucana (`struct Pair(x: u32, y: f64)`). Test używa minimalnej biblioteki standardowej, więc `Global` jest zapisany w jednym wierszu.],
) <fig:global-diagnostic>

Wszystkie trzy wymagania są spełnione. Zmienna globalna WX jest jedną zmienną globalną WebAssembly, więc zmienną globalną może być `Meters`, enum, wskaźnik lub referencja do funkcji, a `Point` nie. Kod generyczny dostaje gwarancję z traitu: dla każdego `G: Global` `G::Value` jest jedną wartością. A reguła nie jest specjalnym kodem dla zmiennych globalnych. To ograniczenie typu skojarzonego, ten sam mechanizm, który ogranicza `Memory::Size` do `PointerSize`.

== Reinterpretacja wartości <sec:transmute>

`ValueType` mógł tylko powiedzieć, czy typ mieści się w zmiennej globalnej. `Repr` mówi, czym typ jest na stosie, więc może też powiedzieć, kiedy dwa typy są przechowywane tak samo. Wtedy wartość jednego typu można użyć jako drugiego bez wykonywania żadnej instrukcji:

```wx
pub func transmute<
    T: StackValue,
    U: StackValue where { Repr = T::Repr },
>(value: T) -> U;
```

`transmute` zamienia `T` na `U`, gdy oba są przechowywane jako te same wartości WebAssembly. Nie ma ciała, a w czasie wykonania nic nie robi. `Meters` na `u32`, `Point` na `(u32, f64)` i wskaźnik do pamięci 32-bitowej na `u32` są przyjmowane. `u32` na `u64` jest odrzucane: ich reprezentacjami są `i32` i `i64`, a zamiana jednego w drugie to instrukcja (`i64.extend_i32_u`), którą WX udostępnia jako funkcję (rozdział #nr(<ch:intrinsics>)).

Ponieważ `Repr` zachowuje kolejność deklaracji, `transmute` nie może zmienić kolejności pól. Zamiana `(u8, u64)` na `(u64, u8)` jest odrzucana (listing #nr(<fig:transmute-diagnostic>)). Gdyby `Repr` podążał za układem w pamięci, który sortuje pola według wyrównania, obie krotki byłyby `(i64, i32)`, a konwersja zostałaby przyjęta, po cichu zamieniając pola miejscami.


#figure(
  ```wx
  func swap(x: (u8, u64)) -> (u64, u8) {
      transmute(x)
      // error[E2112]: type mismatch resolving `<(u64, u8) as StackValue>::Repr == <(u8, u64) as StackValue>::Repr`
      // expected `(i32, i64)`, found `(i64, i32)`
      // required by this equality in `transmute`: `U: StackValue where { Repr = T::Repr }`
  }
  ```,
  caption: [`transmute`, który zmieniłby kolejność pól, jest odrzucany. Błąd jest wyjściem kompilatora dla tego kodu.],
) <fig:transmute-diagnostic>

*Odpowiedzialność wywołującego.* `transmute` jest niebezpiecznym (ang. _unsafe_) prymitywem reinterpretacji stosu. Jego ograniczenie gwarantuje, że źródło i cel mają tę samą reprezentację na stosie; wywołujący musi zadbać, by powstała wartość była poprawna dla typu docelowego. Na przykład `transmute::<u8, Bool>(2)` jest przyjmowane przez moduł sprawdzania typów, ale łamie to wymaganie, ponieważ `Bool` ma tylko wartości 0 i 1. Biblioteka standardowa buduje na tym prymitywie operacje wyższego poziomu, a konwersje sprawdzane mogą walidować wartości przed jego użyciem. WX nie ma jeszcze adnotacji `unsafe`; oznaczanie takich operacji jest planowane w ramach projektu systemu efektów.

`transmute` pozwala też bibliotece standardowej typować każdą instrukcję dokładnie tak, jak WebAssembly czyta jej operandy. `i32.add` dodaje dwie wartości `i32` i nie zna znaku liczby, więc funkcja dla niej przyjmuje dwa `i32`. Dodawanie dla `u32` reinterpretuje wartości na wejściu i wyjściu:

```wx
impl Add for u32 {
    func add(self: Self, rhs: Self) -> Self {
        transmute(i32_add(transmute(self), transmute(rhs)))
    }
}
```

== Kod generyczny <sec:stack-generic>

WX sprawdza funkcję generyczną raz, gdy jej parametry typów są nieznane. `transmute` w funkcji generycznej musi więc być poprawny dla każdego możliwego argumentu typu:

```wx
struct Wrap<T>(T);

func unwrap<T: StackValue>(w: Wrap<T>) -> T {
    transmute(w)
}
```

Tutaj kompilator musi wykazać, że `Wrap<T>` i `T` mają tę samą reprezentację, choć `T` jest nieznane. Dla typu o kilku częściach nie da się tego zapisać jako jednego impl: reprezentacja `Pair<T, u32>` nie jest `(T::Repr, i32)`, ponieważ `T::Repr` może samo być krotką, a WX nie ma typu dla konkatenacji dwóch krotek. Zamiast tego kompilator przepisuje reprezentację do *postaci normalnej*, spłaszczonej tak daleko, jak to znane: części zagnieżdżone są spłaszczane, znane skalary zastępowane swoją reprezentacją, części o zerowym rozmiarze pomijane, a każda nieznana część pozostaje jednym elementem (tabela #nr(<tbl:repr-normal>)).

#figure(
  booktable(
    columns: (auto, auto),
    align: (left, left),
    table.header([Zapis], [Postać normalna]),
    table.hline(stroke: 0.5pt),
    [`<Wrap<T> as StackValue>::Repr`],
    [`<T as StackValue>::Repr`],
    [`<Pair<T, u32> as StackValue>::Repr`],
    [`<(T, i32) as StackValue>::Repr`],
    [`<(T, u32) as StackValue>::Repr`],
    [`<(T, i32) as StackValue>::Repr`],
    [`<Point as StackValue>::Repr`],
    [`(i32, f64)`],
  ),
  caption: [Postacie normalne `Repr`. Bez nieznanej części wynikiem jest płaska krotka. Z nieznaną częścią projekcja jest zachowana nad spłaszczonym typem.],
) <tbl:repr-normal>

Dwie reprezentacje porównuje się potem jak dowolne dwa typy, porównując ich postacie normalne. `unwrap` jest przyjmowane, podobnie jak `transmute` między `Pair<T, u32>` a `(T, u32)`. To nie działa w drugą stronę: `(T, U)` i `(U, T)` są w kodzie generycznym różne, choć są równe, gdy `T` i `U` są tym samym typem.

== Porównanie <sec:stack-comparison>

Tabela #nr(<tbl:stack-comparison>) porównuje WX z trzema językami z rozdziału #nr(<ch:background>) pod względem dwóch pytań tego rozdziału.

#figure(
  booktable(
    columns: (auto, 1fr, 1fr),
    align: (left, left, left),
    table.header([Język], [Zmienna globalna typu złożonego], [Co sprawdza reinterpretacja]),
    table.hline(stroke: 0.5pt),
    [Rust],
    [pamięć liniowa; `static` nigdy nie jest zmienną globalną WebAssembly],
    [`transmute`: równy rozmiar w bajtach; `unsafe`],
    [Zig],
    [pamięć liniowa],
    [`@bitCast`: równy rozmiar w bitach],
    [AssemblyScript],
    [zmienna globalna WebAssembly przechowująca wskaźnik do obiektu],
    [`reinterpret<T>`: liczba całkowita i zmiennoprzecinkowa tej samej szerokości],
    [WX],
    [odrzucone; zmienna globalna to jedna wartość WebAssembly],
    [`transmute`: te same wartości na stosie, w tej samej kolejności],
  ),
  caption: [Zmienne globalne typów złożonych i reinterpretacja w WX i trzech innych językach.],
) <tbl:stack-comparison>

Wiersze sprawdzono, kompilując mały program w każdym języku toolchainami z badania. Struktura `static` w Ruście i globalna struktura w Zigu leżą w pamięci liniowej, a jedyną zmienną globalną WebAssembly w module jest wskaźnik stosu (lub, dla eksportowanego `static` w Ruście, stała przechowująca jego adres). AssemblyScript eksportuje zmienną globalną, która przechowuje adres obiektu. `transmute` w Ruście #fnote("rust-transmute") i `@bitCast` w Zigu #fnote("zig-bitcast") między typami o różnych rozmiarach są odrzucane w czasie kompilacji, a `reinterpret` w AssemblyScript #fnote("as-globals") przyjmuje tylko liczbę całkowitą i liczbę zmiennoprzecinkową o tej samej szerokości.

Operacje te reinterpretują wartości na różnych poziomach. `transmute` w Ruście i `@bitCast` w Zigu wymagają równych rozmiarów. `transmute` w WX wymaga tego samego ciągu typów ze stosu WebAssembly, więc sam równy rozmiar w bajtach nie wystarcza. Podobnie jak `transmute` w Ruście, pozostawia poprawność wartości wywołującemu. Jego ograniczenie reprezentacji określa, kiedy reinterpretacja stosu nie wymaga instrukcji; bezpieczniejsze konwersje można zbudować na tym prymitywie (podrozdział #nr(<sec:transmute>)).

// Status (2026-10-30, `tir-refactor` at `186ba25`): StackValue, StackScalar, transmute and the Global bound are
// implemented in the type checker and tested. Codegen is disabled on the branch, so nothing using them has been
// compiled to Wasm yet. The lowering of values to the stack must follow declaration order; the previous MIR
// flattened in physical (layout) order.
