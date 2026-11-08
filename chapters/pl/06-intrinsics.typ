#import "../../template.typ": booktable, muted, todo
#import "../../bibliography.typ": fnote
#import "helpers.typ": nr

= Funkcje wewnętrzne: instrukcje jako funkcje <ch:intrinsics>

WX udostępnia wybrane instrukcje WebAssembly jako funkcje biblioteki standardowej o typowanych sygnaturach i bez ciał. Wywołania są sprawdzane tymi samymi mechanizmami co zwykłe funkcje. Ten rozdział wyjaśnia te funkcje wewnętrzne (ang. _intrinsics_) i ich opakowania w bibliotece, a następnie odróżnia je od operacji dostępu do pamięci, które mają osobną składnię.

== Instrukcje w bibliotece standardowej <sec:intrinsic-functions>

Języki docierają do instrukcji, których nie obejmuje ich język źródłowy, na dwa sposoby. Asembler wbudowany dociera do wszystkich, ale kompilator nie sprawdza jego użycia systemem typów języka; wynikowy moduł przechodzi tylko walidację WebAssembly (podrozdział #nr(<sec:synthesis>)). Funkcje wbudowane (ang. _builtins_) są sprawdzane, ale kompilator definiuje ich nazwy i typy, często przyjmują encję jako zwykłą liczbę całkowitą i obejmują tylko te instrukcje, które wybrali ich autorzy.

W WX *funkcja wewnętrzna* (ang. _intrinsic_) to funkcja zadeklarowana w bibliotece standardowej bez ciała:

```wx
pub func i32_add(a: i32, b: i32) -> i32;
pub func u32_div(a: u32, b: u32) -> u32;
pub func i64_extend_i32(value: i32) -> i64;
pub func f32_reinterpret_i32(value: i32) -> f32;
pub func trap() -> !;
```

Deklaracja to wszystko, co widzi program. Kompilator odwzorowuje każdą z nich na jej instrukcję WebAssembly. Poza tym nie ma w niej nic szczególnego: jest znajdowana przez rozwiązywanie nazw, sprawdzana względem swojej sygnatury i może być opakowana lub pozostać prywatna dla biblioteki. Gdy serwer języka zostanie podłączony do obecnego modułu sprawdzania typów, będzie pokazywał jej sygnaturę tak jak każdej innej funkcji.

Każda sygnatura jest sygnaturą samej instrukcji, jak wyjaśniono w podrozdziale #nr(<sec:transmute>). `i32.add` czyta dwie wartości `i32`, więc `i32_add` przyjmuje dwa `i32`. Tam, gdzie WebAssembly ma osobne instrukcje ze znakiem i bez znaku, biblioteka ma osobne funkcje: `i32_div` przyjmuje `i32`, a `u32_div` przyjmuje `u32`. Zmiana reprezentacji jest zawsze nazwaną funkcją (`i64_extend_i32`, `i32_wrap_i64`, `f32_reinterpret_i32`), a nigdy niejawną konwersją, bo każda z nich jest inną instrukcją.

Dodanie nowej instrukcji oznacza dodanie jednej deklaracji do biblioteki i jej odwzorowania do kompilatora. Nie jest potrzebna nowa składnia ani nowy rodzaj itemu, więc pokrycie może rosnąć po jednej instrukcji.

// Not settled (2026-10-30): how the compiler recognizes a bodiless std function as an intrinsic. Types use
// "a reserved name of the right kind declared in std" (`IntrinsicDefs`); functions have no rule yet, and a bodiless
// function in user code is not diagnosed.

== Encje jako argumenty <sec:intrinsic-entities>

Wiele instrukcji wskazuje encję: `memory.size` i `memory.grow` wskazują pamięć, `global.get` zmienną globalną. W formacie binarnym jest to indeks zapisany w instrukcji. Funkcja wewnętrzna dla takiej instrukcji przyjmuje encję jako wartość swojego typu itemu (podrozdział #nr(<sec:items-as-types>)):

```wx
pub func memory_size<Mem: Memory>(mem: Mem) -> Mem::Size;
pub func memory_grow<Mem: Memory>(mem: Mem, delta: Mem::Size) -> Mem::Size::Signed;
pub func memory_fill<Mem: Memory>(dst: Mem::*u8, val: u8, len: Mem::Size);
```

Argument `mem` ma zerowy rozmiar. Nie zajmuje miejsca na stosie, a kompilator odczytuje z jego typu, o którą pamięć chodzi, i zapisuje indeks w instrukcji. Pozostałe parametry są typowane tą samą pamięcią: `delta` jest `u32` dla pamięci 32-bitowej i `u64` dla 64-bitowej. `memory.grow` zwraca dawny rozmiar, a $-1$, jeśli pamięci nie można powiększyć, więc jego wynik ma typ ze znakiem o tej samej szerokości (`Size::Signed`, `i32` lub `i64`). Żadna funkcja wewnętrzna nie przyjmuje liczby całkowitej tam, gdzie oczekiwana jest encja, więc indeks nigdy nie pojawia się w programie jako wartość. To dopełnia cel z podrozdziału #nr(<sec:identity-shape>): program nigdy nie używa indeksu encji jako liczby całkowitej.

== Od instrukcji do metody <sec:intrinsic-layers>

Większość programów nigdy nie wywołuje tych funkcji bezpośrednio. Biblioteka opakowuje je w domyślne metody traitów, które kompilator implementuje dla każdego itemu (podrozdział #nr(<sec:why-traits>)):

```wx
pub trait GlobalMut: Global {
    func set(self: Self, value: Self::Value) {
        global_set(self, value)
    }
}
```

Są więc trzy warstwy, a każda jest zwykłym kodem nad warstwą niższą: funkcja wewnętrzna, metoda traitu, która ją wywołuje, oraz kod użytkownika, który wywołuje metodę, na przykład `count.set(count.get() + 1)`. Warstwy pozwalają bibliotece decydować, co program może zrobić. `global_get` i `global_set` są prywatne dla biblioteki, więc program czyta i zapisuje zmienną globalną tylko przez `get` i `set`, a `set` jest dostępne tylko dla `global mut`. Instrukcja pod spodem to nadal jedno `global.set`. Ograniczenie wynika z tego, które funkcje są widoczne, a nie z dodatkowego sprawdzenia w kompilatorze.

`Memory` ma tego samego rodzaju metody, `grow` i `size_pages`, nad `memory_grow` i `memory_size`.

Operatory podlegają tym samym warstwom: operator jest wywołaniem metody traitu, jak pokazuje podrozdział #nr(<sec:operators>).

== Operatory są wywołaniami traitów <sec:operators>

Operatory arytmetyczne i porównania są rozdzielane przez traity biblioteki standardowej. `a + b` wywołuje metodę `add` traitu `Add`; inne traity to m.in. `Sub`, `Mul`, `PartialEq` dla `==` i `PartialOrd` dla `<`. `Add` jest zadeklarowany tak:

```wx
pub trait Add: StackValue {
    func add(self: Self, rhs: Self) -> Self;
}
```

Biblioteka implementuje ten trait dla każdego typu prymitywnego za pomocą funkcji wewnętrznej. Dla `u32` metoda reinterpretuje operandy jako `i32`, dodaje je instrukcją `i32` i reinterpretuje wynik (podrozdział #nr(<sec:transmute>)):

```wx
impl Add for u32 {
    #[inline]
    func add(self: Self, rhs: Self) -> Self {
        transmute(i32_add(transmute(self), transmute(rhs)))
    }
}
```

Metoda jest `#[inline]`, więc wywołanie znika. Wyrażenie `a + b` dla dwóch wartości `u32` kompiluje się do `local.get`, `local.get` i `i32.add`, bez żadnego wywołania w module.

Własne typy programu implementują te same traity. Listing #nr(<fig:operator-trait>) definiuje `+` dla `Vec2`, a `sum` używa go dokładnie tak, jak użyłaby `+` na `u32`. `bad` używa `*`, którego `Vec2` nie implementuje, więc kompilator ją odrzuca.

#figure(
  ```wx
  struct Vec2(x: i32, y: i32);

  impl Add for Vec2 {
      func add(self: Self, rhs: Self) -> Self {
          Vec2({ x: self.x + rhs.x, y: self.y + rhs.y })
      }
  }

  pub func sum(a: Vec2, b: Vec2) -> Vec2 {
      a + b // przyjęte: `Vec2` implementuje `Add`
  }

  pub func bad(a: Vec2, b: Vec2) -> Vec2 {
      a * b
      // error[E2063]: the trait bound `Vec2: Mul` is not satisfied
      // the trait `Mul` is not implemented for `Vec2`, required by `*` operator
  }
  ```,
  caption: [Operatory na typie użytkownika. `+` jest przyjmowany, gdy `Vec2` implementuje `Add`; `*` jest odrzucany, ponieważ `Vec2` nie implementuje `Mul`. Błąd jest wyjściem kompilatora dla tego kodu.],
) <fig:operator-trait>

Nie każdy operator jest traitem. `&&`, `||` i przypisanie są wbudowane w język i nie można ich przeciążać.

== Bool i Char są typami biblioteki <sec:bool-char>

WebAssembly nie ma typu logicznego ani znakowego, więc WX również nie ma ich jako typów wbudowanych. Biblioteka standardowa buduje oba z typów prymitywnych. `Bool` jest enumem, którego reprezentacją jest `u8`, a `Char` strukturą opakowującą `u32`:

```wx
pub enum Bool(u8) {
    False = 0,
    True = 1,
}

pub struct Char(value: u32);
```

Ich metody są zwykłym kodem nad opakowaną wartością. Równość dla `Char` porównuje zawarte w nim `u32`, używając operatora `u32` z poprzedniego podrozdziału:

```wx
impl PartialEq for Char {
    func eq(self: Self, other: Self) -> Bool {
        self.value == other.value
    }
}
```

`Bool` działa tak samo, z funkcjami wewnętrznymi zamiast dostępu do pola. Jego `!` reinterpretuje wartość jako `i32` i sprawdza, czy jest zerem (`i32_eqz`), więc `Bool` jest jednym `i32` w reprezentacji na stosie (tabela #nr(<tbl:repr>)).

== Trap <sec:trap>

`trap` to instrukcja `unreachable` z WebAssembly: wykonanie zatrzymuje się trapem. Jej typem zwracanym jest `!`, typ bez wartości. Wyrażenia typu `!` można użyć tam, gdzie oczekiwany jest dowolny typ, więc trap może stać w dowolnej pozycji:

```wx
func expect(ok: Bool, value: u32) -> u32 {
    if ok { value } else { trap() }
}
```

`break` i `return` również mają typ `!`, bo nie przekazują wartości do następnego wyrażenia, tylko przenoszą sterowanie w inne miejsce. `trap` nie potrzebuje więc własnej reguły: jest po prostu funkcją zwracającą `!`.

== Dostęp do pamięci jest składnią <sec:memory-access>

Odczyty i zapisy są najczęstszymi instrukcjami i WX nie udostępnia ich jako funkcji. Zapisuje się je jako operacje na *miejscach* (ang. _places_), czyli lokalizacjach w pamięci osiąganych przez wskaźnik (tabela #nr(<tbl:places>)).

#figure(
  booktable(
    columns: (auto, auto, 1fr),
    align: (left, left, left),
    table.header([Zapis], [Znaczenie], [Instrukcja]),
    table.hline(stroke: 0.5pt),
    [`p.*`],
    [miejsce, na które wskazuje `p`],
    [odczyt (load), gdy jest czytane, zapis (store), gdy jest zapisywane],
    [`p.field`],
    [pole tego miejsca],
    [to samo, pod offsetem pola],
    [`xs[i]`],
    [element `i` slice'a lub tablicy],
    [to samo; trap, jeśli `i` jest poza zakresem],
    [`place.&`],
    [wskaźnik do miejsca],
    [brak; obliczany jest tylko adres],
  ),
  caption: [Dostęp do pamięci w WX. Pamięcią jest ta z typu wskaźnika (podrozdział #nr(<sec:pointers-memory>)).],
) <tbl:places>

```wx
func read(p: heap::&u32) -> u32 { p.* }
func write(p: heap::*u32) { p.* = 5; }
```

Pamięć i rozmiar dostępu wynikają z typu wskaźnika: `heap::&u32` czyta cztery bajty z `heap`. Ten sam kod ze wskaźnikiem do innej pamięci kompiluje się do tej samej instrukcji z innym indeksem pamięci.

Wszystkie te operacje zapisuje się po operandzie, więc łańcuch czyta się od lewej do prawej, w kolejności wykonywania kroków: `n.*.next.*.value` idzie za dwoma wskaźnikami, gdzie C wymaga `(*(*n).next).value`. Zig dokonał tego samego wyboru dla `p.*`. Program nie może przeciążyć tych operacji dla własnych typów, więc każde `.*` jest dostępem do pamięci i nigdy wywołaniem kodu użytkownika.

== Porównanie <sec:intrinsic-comparison>

#figure(
  booktable(
    columns: (auto, auto, 1fr),
    align: (left, left, left),
    table.header([Język], [Powiększanie pamięci], [Pamięć jest wskazywana przez]),
    table.hline(stroke: 0.5pt),
    [C/C++ (clang)],
    [`__builtin_wasm_memory_grow(0, n)`],
    [stałą całkowitą],
    [Rust],
    [`core::arch::wasm32::memory_grow::<0>(n)`],
    [stały całkowity argument generyczny],
    [Zig],
    [`@wasmMemoryGrow(0, n)`],
    [liczbę całkowitą],
    [AssemblyScript],
    [`memory.grow(n)`],
    [nic; jest jedna pamięć],
    [WX],
    [`memory_grow(heap, n)`],
    [item pamięci, wartość jej własnego typu],
  ),
  caption: [Powiększanie pamięci w WX i czterech innych językach.],
) <tbl:intrinsic-comparison>

Zapisy pochodzą z dokumentacji clanga #fnote("clang-extensions"), modułu `core::arch::wasm32` w Ruście #fnote("rust-memory-grow"), Ziga #fnote("zig-wasm-builtins") i AssemblyScript #fnote("as-globals"), a każdy z nich skompilowano toolchainem z badania.

Wszystkie te języki oferują instrukcję jako funkcję wbudowaną i sprawdzają jej operandy. Różnica polega na tym, jak wskazywana jest pamięć. Gdy pamięcią jest liczba całkowita, system typów nie odróżni indeksu pamięci od jakiejkolwiek innej liczby, a z niej nie może wynikać typ adresu pamięci (32 lub 64 bity). W WX pamięć jest itemem, więc pozostałe operandy są typowane tą pamięcią, a program nigdy nie obsługuje jej indeksu.
