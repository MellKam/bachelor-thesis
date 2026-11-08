#import "../../template.typ": booktable, muted, todo
#import "../../bibliography.typ": fnote
#import "helpers.typ": nr

= Ciała funkcji: wyrażenia na stosie <ch:bodies>

Ciała funkcji łączą encje, wartości, wywołania i instrukcje opisane w poprzednich rozdziałach. WebAssembly jest maszyną stosową ze strukturalnym przepływem sterowania: instrukcje zużywają operandy ze stosu, a pętle i instrukcje warunkowe są konstrukcjami zagnieżdżonymi. WX podąża za wyrażeniową składnią Rusta. Omówienie skupia się na reprezentacji w WebAssembly i na regułach, które różnią się od Rusta.

== Ciało jest wyrażeniem <sec:body-stack-machine>

Każda instrukcja WebAssembly zdejmuje swoje operandy ze stosu i odkłada wyniki #fnote("wasm-spec-exec-instructions"), a żadna instrukcja nie nazywa zmiennej dla wartości pośredniej:

```wat
(func $area (param $w i32) (param $h i32) (result i32)
  local.get $w     ;; stos: w
  local.get $h     ;; stos: w h
  i32.mul          ;; stos: (w*h)
  i32.const 1      ;; stos: (w*h) 1
  i32.add)         ;; stos: (w*h)+1
```

Język może to ukryć za poleceniami (ang. _statements_) i zmiennymi, jak robi to C, albo sprawić, że każda konstrukcja wytwarza wartość, tak że wynik jednej jest operandem następnej. WX robi to drugie. Ciało jest wyrażeniem, a jego ostatnie wyrażenie jest wynikiem funkcji:

```wx
func area(w: u32, h: u32) -> u32 {
    w * h + 1
}
```

Kompiluje się to do powyższego ciągu, bez `return` i bez zmiennej. Typ wyrażenia wyznacza jego reprezentację na stosie przez `StackValue::Repr` (podrozdział #nr(<sec:stack-repr>)): `u32` zostawia jedno `i32`, `()` nic nie zostawia, a struktura zostawia spłaszczone reprezentacje swoich pól. WebAssembly waliduje stos wyników funkcji względem zadeklarowanych typów wyników. WX sprawdza, czy końcowe wyrażenie ciała ma zadeklarowany typ wyniku WX, który wyznacza także tę reprezentację na stosie.

== Bloki, polecenia i wiele wartości <sec:body-blocks>

Blok `{ ... }` to polecenia, po których może następować końcowe wyrażenie będące wartością bloku. Polecenie kończy się `;` i nic nie zostawia na stosie, więc jego wyrażenie musi mieć typ `()` lub `!`. Różni się to od Rusta, gdzie `;` odrzuca wartość. W WebAssembly wartość, której nic nie zużywa, czyni funkcję niepoprawną, a `drop` jest sposobem, w jaki program mówi, że jej nie chce. WX ma tę samą regułę w kodzie źródłowym: `g();` dla `g` zwracającego `u32` jest błędem (E2003, „value must be used”), a program zapisuje drop tam, gdzie do niego dochodzi:

```wx
_ = g();       // oblicza g, odrzuca jego u32
```

Wynik, który łatwo przypadkiem zignorować, taki jak kod statusu wywołania WASI, jest więc ignorowany tylko przez wiersz, który to mówi wprost.

`if` bez `else` nic nie zostawia, gdy warunek jest fałszywy, więc jego typem jest `()`. `if` z obiema gałęziami musi mieć gałęzie tego samego typu, aby stos miał ten sam kształt na obu ścieżkach, jak walidacja wymaga od `if ... else ... end` (listing #nr(<lst:body-errors>)).

#figure(
  ```wx
  func f() -> i32 { local x: i32 = 1; }
  // error[E2001]: type mismatch (the body is `()`, not `i32`)

  func g(c: Bool) -> i32 { if c { 1 } }
  // error[E2052]: `if` may be missing an `else` clause
  ```,
  caption: [Dwa ciała, które zostawiłyby na stosie niewłaściwe wartości. Komunikaty pochodzą od kompilatora, w skróconej postaci.],
) <lst:body-errors>

Funkcja może zwracać kilka wartości, a wyrażenie typu krotki lub struktury zostawia ich kilka, więc multi-value nie potrzebuje specjalnej składni:

```wx
func divmod(a: u32, b: u32) -> (u32, u32) {
    (a / b, a % b)
}

func quotient_plus_rest(a: u32, b: u32) -> u32 {
    local (q, r) = divmod(a, b);
    q + r
}
```

`divmod` ma typ Wasm `(i32 i32) -> (i32 i32)`. Wywołujący rozkłada parę destrukturyzującym `local`, jedynym sposobem rozłożenia krotki, ponieważ WX nie ma pozycyjnego dostępu do pól.

== Przepływ sterowania zachowuje strukturę WebAssembly <sec:body-control>

*Strukturalny* przepływ sterowania oznacza, że skok może prowadzić tylko do konstrukcji, która go otacza: nie ma `goto` ani sposobu wejścia do pętli w środku. Zagnieżdżenie w kodzie źródłowym jest więc zagnieżdżeniem w module. Kompilator nie potrzebuje analizy przepływu sterowania, by wiedzieć, że skok jest poprawny, bo `break` jest poprawny, gdy jego etykieta wskazuje otaczający `block` lub `loop` (E2012, gdy żaden nie wskazuje).

WebAssembly ma trzy konstrukcje, `block`, `loop` i `if`, a skok `br n` opuszcza otaczającą konstrukcję o `n` poziomów wyżej #fnote("wasm-spec-modules"). Opuszczenie `block` lub `if` kontynuuje za jego `end`, opuszczenie `loop` kontynuuje od jego początku, a skok może nieść wartości, które stają się wynikiem konstrukcji. Liczba `n` to względny indeks etykiety, z innej przestrzeni indeksów niż encje modułu, ale ma tę samą wadę, której unikano w podrozdziale #nr(<sec:identity-shape>): zmienia się, gdy wokół skoku doda się konstrukcję, a nic w instrukcji nie mówi, do czego służy. WX nigdy jej nie zapisuje. Skok wskazuje swój cel po nazwie, a kompilator oblicza głębokość (tabela #nr(<tbl:control-flow>)).

#figure(
  booktable(
    columns: (auto, auto),
    align: (left, left),
    table.header([WX], [WebAssembly]),
    table.hline(stroke: 0.5pt),
    [`if c { a } else { b }`],
    [`if` … `else` … `end`],
    [`block :l { ... }`],
    [`block` … `end`],
    [`loop { ... }`],
    [`block` zawierający `loop`],
    [`break :l value`],
    [`br` do końca konstrukcji `:l`, niosący `value`],
    [`continue :l`],
    [`br` do początku pętli `:l`],
    [`return value`],
    [`return`],
    [`match x { ... }`],
    [zagnieżdżone `block` i `br_table` dla gęstego zbioru liczb całkowitych, w przeciwnym razie łańcuch `if`],
  ),
  caption: [Przepływ sterowania w WX i konstrukcja WebAssembly, do której kompiluje się każda forma.],
) <tbl:control-flow>

`loop` to `block` wokół `loop`, ponieważ `loop` w WebAssembly można tylko wejść ponownie: skok do niego wraca na jego początek, a nic nie opuszcza go do przodu. Zewnętrzny `block` jest tym, dokąd prowadzi `break`. Oba należą do jednego wyrażenia WX, którego wartość nadają jego `break`:

```wx
func first_multiple(n: u32, of: u32) -> u32 {
    local mut i: u32 = 1;
    loop {
        if i * of >= n { break i * of };
        i += 1;
    }
}
```

```wat
block                      ;; cel `break`
  loop                     ;; cel `continue`
    ...
    if
      ...                  ;; wartość `i * of`
      br 2                 ;; `break`: z `if` i z `loop`
    end
    ... i += 1 ...
    br 0                   ;; z powrotem na początek `loop`
  end
end
```

Etykieta pozwala `break` lub `continue` opuścić pętlę inną niż najbardziej wewnętrzna, a `block` z etykietą daje kodowi, który nie jest pętlą, to samo wcześniejsze wyjście. Potrzebuje go wyszukiwanie podłańcucha: jedna pętla przebiega po pozycjach w tekście, wewnętrzna porównuje bajty na danej pozycji, a dopasowanie znalezione w pętli wewnętrznej kończy zewnętrzną (listing #nr(<lst:body-search>)).

#figure(
  ```wx
  func find<Mem: Memory>(
      text: Mem::&[u8],
      pattern: Mem::&[u8],
  ) -> (Bool, Mem::Size) {
      local mut start: Mem::Size = 0;
      loop :outer {
          if start + pattern.len() > text.len() {
              break :outer (False, 0)
          };
          local mut k: Mem::Size = 0;
          loop {
              if k == pattern.len() { break :outer (True, start) };
              if text[start + k] != pattern[k] {
                  start += 1;
                  continue :outer
              };
              k += 1;
          }
      }
  }
  ```,
  caption: [Naiwne wyszukiwanie podłańcucha, generyczne względem pamięci (`examples/search`). `break :outer` opuszcza obie pętle z wynikiem, a `continue :outer` porzuca pętlę wewnętrzną i przechodzi do następnej pozycji.],
) <lst:body-search>

Trzy wyjścia opuszczają różne liczby konstrukcji: w skompilowanym module `break :outer` to `br 2` w pętli zewnętrznej i `br 4` w wewnętrznej, a `continue :outer` to `br 3`. Kod źródłowy nie zapisuje żadnego z nich. Pozycje i długości mają własny typ adresu pamięci, więc jedna definicja przeszukuje pamięć 32- i 64-bitową. Ponieważ ten typ nie jest znany, nie ma wartownika, takiego jak `u32::MAX`, oznaczającego „nie znaleziono”, a wynik niesie flagę: para `(Bool, Mem::Size)` zastępuje `Option<Mem::Size>`, bo WX nie ma jeszcze typów sumy. Są one planowane, a do tego czasu pozycja w parze ma znaczenie tylko wtedy, gdy flaga to `True`. Moduł eksportuje instancję funkcji dla jednej pamięci, ponieważ eksport nie może być generyczny.

== Kod bez normalnego powrotu sterowania: typ `!` <sec:body-never>

`!` w WX to typ never z Rusta: mają go `return`, `break`, `continue`, `trap()` i `loop` bez `break`, a daje się on niejawnie przekształcić w dowolny typ. WebAssembly potrzebuje tej samej idei do walidacji. Po `br`, `return` lub `unreachable` stos jest *polimorficzny*: kod, który następuje, jest sprawdzany tak, jakby stos zawierał to, czego potrzebuje, bo nigdy nie może się wykonać #fnote("wasm-spec-modules"). `!` jest postacią tej reguły na poziomie typów, więc moduł sprawdzania typów przyjmuje to, co przyjmuje walidacja, z tego samego powodu. `if x == 0 { trap() } else { x - 1 }` ma typ `u32`, a jego gałąź `trap()` kompiluje się do `unreachable`.

== Zmienne lokalne i wzorce <sec:body-locals>

Funkcja WebAssembly ma ponumerowane, typowane zmienne lokalne, czytane i zapisywane przez `local.get`, `local.set` i `local.tee`. Parametr WX jest zmienną lokalną, a `local` deklaruje kolejną, niemodyfikowalną, chyba że oznaczono ją `mut`. W przeciwieństwie do zmiennej w C zmienna lokalna nie ma adresu: WebAssembly nie może na nią wskazać, więc `.&` dotyczy tylko miejsc w pamięci (podrozdział #nr(<sec:memory-access>)), a struktura, która potrzebuje adresu, jest świadomie alokowana w pamięci.

`local` i `match` przyjmują te same wzorce, jak w Ruście: nazwy, `_`, krotki i struktury, zagnieżdżone. Jedno sprawdzenie wyczerpywalności obsługuje oba, a brakujący przypadek jest zgłaszany z przykładem (E2066, „pattern `Dir::Down` not covered”). Destrukturyzujący `local` musi być wyczerpujący, a `..` łagodzi ten wymóg.

== Typy są ustalane w obrębie polecenia <sec:body-inference>

Każda instrukcja WebAssembly ma ustalony typ: `i32.add` dodaje `i32`, a `f32.add` dodaje `f32`, i żadna instrukcja nie dodaje „liczb”. Reguła zgadywania typu jest więc regułą wyboru instrukcji, a WX utrzymuje jedno i drugie jawnie. Nie ma niejawnych konwersji: dodanie `u8` do `u32` jest niezgodnością typów (E2001), mimo że oba są przechowywane jako `i32`, a zmianę typu zapisuje się tam, gdzie następuje, przez `transmute` między typami o tej samej reprezentacji (podrozdział #nr(<sec:transmute>)) lub nazwaną instrukcję, taką jak `i64_extend_i32` (podrozdział #nr(<sec:intrinsic-functions>)).

Literał taki jak `5` ma typ `{integer}`: liczby całkowitej, której szerokość i znak nie są jeszcze rozstrzygnięte. Istnieje tylko w czasie kompilacji, ponieważ WebAssembly nie ma takiej wartości (`i32.const 5` i `i64.const 5` to różne instrukcje), a `{integer}` nie jest `StackValue` (podrozdział #nr(<sec:stack-repr>)), więc nic nie może go przechowywać na stosie. Literał dostaje więc konkretny typ z kontekstu, a gdy kontekst go nie daje, nie ma typu domyślnego. Zmienna lokalna potrzebuje `StackValue`, więc `local c = 5` nie ma czego przechować. Stała, która jest obliczana w czasie kompilacji i nigdy nie jest przechowywana, może zachować ten typ: `const X: {integer} = 4` dostaje typ przy każdym użyciu.

```wx
local a: u8 = 5;        // z adnotacji
local b = (5: u8);      // z typu zapisanego przy wyrażeniu
local c = 5;            // error[E2002]: type annotation required
```

W obrębie jednego wyrażenia informacja o typach płynie w obu kierunkach, jak w dwukierunkowym sprawdzaniu typów (ang. _bidirectional type checking_) #fnote("dunfield2021"). Płynie *w dół* od oczekiwanego typu: w `func f() -> u8 { id(5) }` typ wyniku ustala argument typu `id<T>`, a ten z kolei ustala literał. Płynie *w górę* od operandów: w `x + 1` z `x: u8` literał przyjmuje typ drugiego operandu, a w `id(x)` argument mówi wywołaniu, czym jest `T`. Argumenty typów wywołania są poznawane w tej kolejności, z oczekiwanego typu, a potem z argumentów, a argument nadal nieznany, gdy wyrażenie się kończy, jest błędem (E2002 na `T` dla `make()` z `func make<T>() -> T`).

Przepływ zatrzymuje się tam, gdzie wyrażenie jest związane ze zmienną lokalną. Zmienna ma typ, jaki nadano jej inicjalizatorowi, a późniejsze użycie nigdy nie sięga wstecz: `local y = id(5); y` w funkcji zwracającej `u8` jest odrzucane, mimo że `y` jest zwracane jako `u8` w następnym wierszu, natomiast `local y = (id(5): u8)` jest przyjmowane.

== Porównanie <sec:body-comparison>

Bloki wyrażeniowe, `loop` z `break value` i bloki z etykietami istnieją w Ruście, a Zig ma bloki z etykietami, które kończą się z wartością. C i AssemblyScript używają poleceń i potrzebują zmiennej lub operatora warunkowego, by wynieść wartość z gałęzi. Wnioskowanie jest też węższe niż w językach z rodziny ML: przy wnioskowaniu Hindleya–Milnera #fnote("damas1982") późniejsze użycie może rozstrzygnąć typ wcześniejszej zmiennej lokalnej. W WX wnioskowanie zatrzymuje się tam, gdzie wyrażenie jest związane ze zmienną lokalną, ale za to czytelnik nigdy nie musi patrzeć naprzód, by wiedzieć, w którą instrukcję zamienia się dany wiersz. WX nie dodaje nowej konstrukcji, tylko odczytuje platformę: ostatnie wyrażenie jest stosem na końcu funkcji, nazwany skok zastępuje głębokość, `!` jest stosem polimorficznym, `;` nic nie zostawia, więc drop jest jawny, a typowane instrukcje sprawiają, że literały nie mają typu domyślnego.
