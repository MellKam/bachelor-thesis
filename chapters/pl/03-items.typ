#import "../../template.typ": booktable, layout, muted, todo
#import "../../bibliography.typ": fnote
#import "helpers.typ": nr

= Itemy: encje platformy jako typy <ch:items>

W rozdziale #nr(<ch:background>) wskazano luki w sposobie, w jaki języki udostępniają encje modułu, takie jak pamięci, zmienne globalne, tabele i tagi (wykres #nr(<fig:matrix>)). WX reprezentuje każdą encję jako *item* o odrębnym typie. Implementacje traitów dostarczane przez kompilator opisują operacje dostępne na danym itemie. Kolejne trzy rozdziały rozwijają pokrewne mechanizmy dla wartości, wywołań i instrukcji.

== Jak czytać WX <sec:reading-wx>

Składnia WX opiera się na Ruście, a słowa kluczowe dla encji pochodzą z tekstowego formatu WebAssembly. Listing #nr(<lst:wx-tour>) pokazuje mały, kompletny moduł. Przechodzi on kontrolę typów w obecnym kompilatorze.

#figure(
  ```wx
  import "host" as host {
      global step: i32;
      func log(value: i32);
  }

  global mut count: i32 = 0;

  func increment() {
      local next = count.get() + host::step.get();
      count.set(next);
      host::log(next);
  }

  func decrement() {
      local next = count.get() - host::step.get();
      count.set(next);
      host::log(next);
  }

  export { count, increment, decrement }
  ```,
  caption: [Mały moduł WX.],
) <lst:wx-tour>

Przy tworzeniu instancji modułu host dostarcza zmienną globalną `step` oraz implementację `log`. Wywołanie `increment` lub `decrement` zmienia licznik o tę wartość i loguje jego nową wartość. Licznik jest też eksportowany, więc host może go bezpośrednio odczytać lub zmienić. Listing wprowadza kilka podstawowych konstrukcji:

- `global mut` deklaruje modyfikowalną zmienną globalną WebAssembly. Jej wartość utrzymuje się między wywołaniami, a `get` i `set` ją odczytują i aktualizują.
- `func` deklaruje funkcję, a `local` zmienną wewnątrz niej. Każde wywołanie oblicza nowe `next`, którego typ jest wnioskowany jako `i32`. Nie potrzebuje `mut`, bo nigdy nie jest przypisywane ponownie.
- `import` deklaruje encje dostarczane przez hosta. W `import "host" as host` napis wskazuje zewnętrzną przestrzeń nazw importu, a nazwa po `as` służy do odwoływania się do jej encji w WX. Importowana zmienna globalna nie ma inicjalizatora; jej wartość pochodzi od hosta. Bez `mut` moduł może `step` odczytywać, ale nie zmieniać.
- `export` udostępnia zmienne globalne i funkcje hostowi. Eksportowane `count` to ta sama zmienna globalna, którą aktualizują obie funkcje.

Do zmiennych globalnych dostęp odbywa się przez `get` i `set`, aby odróżnić dostęp do stanu modułu od zwykłych obliczeń lokalnych. Traity, na których opierają się te metody, wyjaśnia podrozdział #nr(<sec:global-access>).

== W WebAssembly odwołania do encji są indeksami <sec:identity-shape>

Instrukcje WebAssembly odwołują się do encji modułu przez indeksy w osobnych przestrzeniach indeksów. W przestrzeni indeksów funkcji funkcje importowane poprzedzają zdefiniowane #fnote("wasm-spec-modules"). Dodanie importu funkcji zmienia więc indeks każdej funkcji zdefiniowanej w module:

```wat
(module
  (import "env" "log" (func (param i32)))   ;; funkcja 0
  (func (result i32) i32.const 42)          ;; funkcja 1, przed importem była 0
  (export "run" (func 1)))
```

Format tekstowy pozwala używać nazw takich jak `$run` zamiast liczb i zastępuje je indeksami przy kodowaniu modułu. Pamięci, tabele, zmienne globalne i tagi działają tak samo, każde z własną przestrzenią indeksów. Nazwa taka jak `$run` jest nadal tylko nazwą liczby.

Język, który pozwala programowi używać tych encji, musi zdecydować, jakiego są typu. Są dwie proste odpowiedzi i każda ma wadę.

Pierwsza odpowiedź to użyć samego indeksu. Wbudowana funkcja `@wasmMemoryGrow` w Zigu przyjmuje pamięć jako indeks `u32` #fnote("zig-wasm-builtins"). Dla niskopoziomowej funkcji wbudowanej jest to w porządku, ale wtedy jako pamięci można użyć dowolnej liczby całkowitej, a system typów nie odróżni indeksu pamięci od licznika pętli. Nie wie też, czy pamięć używa adresów 32- czy 64-bitowych, bo sama liczba tego nie mówi.

Druga odpowiedź to opisać tylko to, jak encja wygląda: funkcję przez jej sygnaturę, pamięć przez typ adresu. Wtedy dwie funkcje o tej samej sygnaturze mają ten sam typ, podobnie jak dwie pamięci z adresami 32-bitowymi. Wskaźnik do jednej pamięci dałoby się użyć jako wskaźnik do drugiej, a kompilator nie zauważyłby błędu.

Program potrzebuje więc obu informacji: jakiego rodzaju jest encja i która to dokładnie encja (jej *tożsamość*) oraz co można z nią zrobić (jej *kształt*). Tabela #nr(<tbl:kinds>) podaje kształt każdego rodzaju. To rozróżnienie pojawiło się dopiero po kilku wersjach projektu; nie było punktem wyjścia.

#figure(
  booktable(
    columns: (auto, 1fr, auto),
    align: (left, left, left),
    table.header([Rodzaj], [Kształt: względem czego sprawdzane jest użycie], [W WX]),
    table.hline(stroke: 0.5pt),
    [Funkcja],
    [typy parametrów i wyniku],
    [zaimplementowane],
    [Zmienna globalna],
    [typ wartości, mutowalność],
    [zaimplementowane],
    [Pamięć],
    [typ adresu (32 lub 64 bity)],
    [zaimplementowane],
    [Tabela],
    [typ referencji, typ adresu],
    [zaprojektowane],
    [Tag],
    [typy ładunku],
    [zaprojektowane],
  ),
  caption: [Rodzaje encji WebAssembly i ich kształt.],
) <tbl:kinds>

Stąd trzy cele projektu:

- *Stabilne odwołania.* Dodanie importu lub definicji nigdy nie zmienia sposobu, w jaki istniejący kod odwołuje się do encji.
- *Każdy rodzaj może przekraczać granicę modułu.* Każdy rodzaj encji można zdefiniować, zaimportować i wyeksportować.
- *Odrębne tożsamości bez liczb.* Dwie encje tego samego rodzaju są dla systemu typów różne, a program nigdy nie używa indeksu encji jako liczby całkowitej.

== Każdy item jest typem <sec:items-as-types>

W WX każda encja jest deklarowana jako item i każdy item ma własny typ. Deklaracja `memory heap: u32;` tworzy item `heap` oraz typ, który również nazywa się `heap`. Ten typ ma *zerowy rozmiar*: jego wartości nie zajmują miejsca w czasie wykonania. Ma dokładnie jedną wartość, którą też zapisuje się `heap`. Nazwy itemów mogą pełnić trzy role:

- *Typ:* w typie wskaźnika `heap::&u32` albo jako argument generyczny, jak w `size_of::<T, heap>()`.
- *Wartość:* `count.get()` wywołuje metodę na zmiennej globalnej `count`.
- *Przestrzeń nazw:* `heap::PAGE_SIZE` jest stałą pamięci.

Tożsamością itemu jest jego typ. Kompilator zna ją wszędzie tam, gdzie item jest użyty, i zamienia ją na indeks WebAssembly dopiero przy generowaniu kodu, gdy zna już wszystkie importy i definicje. Ponieważ wartość ma zerowy rozmiar, przekazanie itemu do funkcji nic nie kosztuje w czasie wykonania: instrukcja dostaje indeks jako argument natychmiastowy (ang. _immediate_), a nie jako operand.

Podobny pomysł ma Rust. Każda funkcja w Ruście ma własny typ o zerowym rozmiarze, więc dwie funkcje o tej samej sygnaturze mają różne typy. Program w Ruście nie może jednak zapisać tego typu, a po zamianie funkcji na wskaźnik do funkcji typ ten ginie. W WX typ każdego itemu można zapisać w kodzie źródłowym, a własny typ ma każdy rodzaj encji, nie tylko funkcje.

== Wskaźniki niosą swoją pamięć <sec:pointers-memory>

Pamięć liniowa to rosnąca tablica bajtów, mierzona w stronach po 64 KiB #fnote("wasm-spec-modules"). `u32` w `memory heap: u32;` jest typem adresu, a nie bieżącym rozmiarem pamięci. WX przyjmuje też `memory heap: u64;` dla Memory64.

Dzięki rozszerzeniu multi-memory moduł może mieć kilka pamięci liniowych #fnote("wasm-multi-memory"). Każda pamięć ma własne adresy, a każda instrukcja odczytu i zapisu wskazuje swoją pamięć jako argument natychmiastowy. Typ wskaźnika, który mówi tylko, na co wskazuje, jak `*u8`, nie wystarcza: dwa wskaźniki tego typu mogą wskazywać na różne pamięci, a kompilator musi wiedzieć, której pamięci użyć przy każdym odczycie.

Jedna z możliwości to *gruby wskaźnik* (ang. _fat pointer_), który w czasie wykonania przechowuje indeks pamięci obok adresu. Kosztuje to miejsce w każdym wskaźniku, a ponieważ odczyt wskazuje pamięć jako argument natychmiastowy, indeks znany dopiero w czasie wykonania wymagałby przy każdym dostępie rozgałęzienia po wszystkich pamięciach.

WX umieszcza pamięć w typie wskaźnika. `heap::*u8` to wskaźnik na bajt w `heap`. Wskaźnik do innej pamięci ma inny typ, a użycie go w niewłaściwym miejscu jest zwykłym błędem typów (listing #nr(<fig:cross-memory>)). Kompilator zna pamięć każdego odczytu i zapisu z typu, więc w czasie wykonania nic nie jest przechowywane.

#figure(
  ```wx
  memory heap: u32;
  memory io: u32;

  func read(p: heap::&u32) -> u32 { p.* }

  func wrong(p: io::&u32) -> u32 {
      read(p)
      //   ^ error[E2001]: type mismatch:
      //     expected `heap::&u32`, found `io::&u32`
  }
  ```,
  caption: [Wskaźnik do jednej pamięci użyty tam, gdzie oczekiwany jest wskaźnik do innej. Komunikat jest skróconym wyjściem kompilatora.],
) <fig:cross-memory>

Nie ma pamięci domyślnej. Typ wskaźnika bez pamięci jest błędem, nawet w module z jedną pamięcią, a komunikat kompilatora podaje tę regułę (listing #nr(<fig:untagged-pointer>)).

#figure(
  ```wx
  memory heap: u32;

  func read(p: *u32) -> u32 { p.* }
  //           ^^^^ error[E2038]: missing memory in pointer type
  //           help: write the memory before the pointer, like `heap::*u32`
  ```,
  caption: [Typ wskaźnika bez pamięci. Komunikat pochodzi od kompilatora, zapisany w postaci komentarzy.],
) <fig:untagged-pointer>

Typ wskaźnika ma trzy części (rysunek #nr(<fig:pointer-anatomy>)). Środkowa część, `*` lub `&`, to *własność* wskaźnika. Wskaźnik `*` jest wyłączny i modyfikowalny: program może przez niego czytać i zapisywać. Wskaźnik `&` jest współdzielony i tylko do odczytu.

#figure(
  {
    let c-mem = rgb("#1f6fb2")
    let c-ownership = rgb("#b25a1f")
    let c-pointee = rgb("#2a7d4b")
    let part(name, note, color) = stack(
      dir: ttb,
      spacing: 4pt,
      line(length: 100%, stroke: 1.5pt + color),
      align(center, text(weight: "bold", fill: color, name)),
      align(center, text(size: 0.85em, note)),
    )
    stack(
      dir: ttb,
      spacing: 10pt,
      block(width: 100%, text(size: 1.25em, weight: "bold", {
        // Equal flexible space before, between and after the two types.
        for (memory, sigil, pointee) in (("heap", "*", "u8"), ("io", "&", "u32")) {
          h(1fr)
          text(font: layout.mono, fill: c-mem, memory + "::")
          text(font: layout.mono, fill: c-ownership, sigil)
          text(font: layout.mono, fill: c-pointee, pointee)
        }
        h(1fr)
      })),
      grid(
        columns: (1fr, 1fr, 1fr),
        column-gutter: 6pt,
        part("pamięć", "w której pamięci leży adres", c-mem),
        part("własność", [`*` wyłączny, `&` współdzielony], c-ownership),
        part("wskazywany typ", "typ wartości pod adresem", c-pointee),
      ),
    )
  },
  kind: image,
  supplement: [Rysunek],
  caption: [Części typu wskaźnika, na przykładzie `heap::*u8` i `io::&u32`.],
) <fig:pointer-anatomy>

== Skąd się bierze wskaźnik <sec:pointer-sources>

Typ wskaźnika wskazuje pamięć, ale deklaracja pamięci tworzy tylko item `heap`, który nie zawiera żadnych bajtów, które program mógłby nazwać. Najprostszym źródłem wskaźników są dane statyczne. Literał napisowy taki jak `"hi"` ma typ `[u8; 2]`: tablicy dwóch bajtów, która nie leży w żadnej pamięci, więc nie ma adresu. Gdy deklaracja żąda typu wskaźnika, kompilator *umieszcza* te bajty w danych statycznych pamięci wskazanej przez typ, a wartość staje się wskaźnikiem do nich (listing #nr(<lst:literal-placement>)).

#figure(
  ```wx
  memory heap: u32;
  memory io: u32;

  func demo() {
      local a: heap::&[u8] = "hi";
      local b: io::&[u8] = "hi";
  }
  ```,
  caption: [Jeden literał umieszczony w dwóch pamięciach. Pamięć wybiera kontekst, więc `a` i `b` mają różne typy.],
) <lst:literal-placement>

== Pamięć dynamiczna jest konwencją <sec:dynamic-memory>

Dane statyczne są ustalone w chwili kompilacji programu. Program, który potrzebuje pamięci o rozmiarze znanym dopiero w trakcie działania, musi o nią poprosić. WebAssembly nie robi tego za program. Środowisko uruchomieniowe daje modułowi pamięci liniowe, czyli rosnący bufor bajtów dla każdej zadeklarowanej w module `memory`, a język nie ma wbudowanego sposobu podziału bufora na bloki. Program podejmuje tę decyzję sam, za pomocą *alokatora*: zwykłego kodu, który prowadzi ewidencję wolnych bajtów i wydaje je na żądanie.

Najprostszy alokator przechowuje jedną liczbę, pierwszy wolny adres, i przesuwa ją do przodu przy każdym żądaniu:

```wx
memory heap: u32;

global mut next: u32 = 4; // adres 0 oznacza null

func alloc(size: u32) -> heap::*u8 {
    local start = next.get();
    next.set(start + size);
    local p: heap::*u8 = transmute(start);
    p
}
```

Ta wersja nie ma `free` i nigdy nie powiększa bufora. Prawdziwe alokatory ponownie używają zwolnionych bloków i powiększają pamięć, gdy się zapełni, ale podejmują decyzje tego samego rodzaju.

Skoro język nie dostarcza alokatora, alokacja jest konwencją, taką samą jak w Zigu: program wybiera alokator i przekazuje go kodowi, który potrzebuje pamięci #fnote("zig-allocators"). Ceną jest to, że nic nie sprawdza, jak program używa pamięci. Blok można użyć po zwolnieniu, zwolnić dwukrotnie albo osiągnąć przez dwa wskaźniki. Kontrola własności i pożyczek (ang. _ownership and borrow checking_) by temu zapobiegła, ale wykracza poza zakres tej pracy.

== Polimorfizm i traity nad pamięciami <sec:why-traits>

Powyższy alokator działa tylko dla `heap`. Jego typem zwracanym jest `heap::*u8`, a `io::*u8` to inny typ. Drugi alokator dla `io` powtarzałby tę samą logikę, a alokatory można też łączyć: arena pobiera bloki z większego alokatora. Każdy alokator powinno się dać napisać raz i używać z dowolną pamięcią.

*Polimorfizm* oznacza jeden fragment kodu działający dla wielu typów. Funkcja przyjmuje parametr typu `M`, który oznacza „jakąś pamięć”, a wywołujący go uzupełnia:

```wx
// `M` wybiera wywołujący; ciało jest takie jak wyżej, z `M` w miejsce `heap`.
func alloc<M: Memory>(size: M::Size) -> M::*u8 { .. }
```

Wywołanie z `heap` daje `heap::*u8`, a wywołanie z `io` daje `io::*u8`. Kompilator sprawdza ciało raz, względem typu zastępczego, a następnie tworzy osobną kopię funkcji dla każdej pamięci, z którą jest użyta.

Sam typ zastępczy nie wystarcza. Ciało porównuje i dodaje adresy, a kompilator nie może zakładać, że takie operacje istnieją dla dowolnego typu. *Trait* określa, co musi zapewniać typ. Jest to nazwany zbiór typów i operacji, które typ może zaimplementować, jak traity w Ruście i klasy typów w Haskellu #fnote("rust-traits")#super[,]#fnote("haskell-type-classes"). Funkcja zapisana jako `func f<M: Memory>(..)` przyjmuje tylko typy implementujące `Memory`, a jej ciało może używać wyłącznie tego, co `Memory` obiecuje.

Pierwsza rzecz, którą kod generyczny musi wiedzieć o pamięci, to jej typ adresu, dlatego `Memory` zaczyna się od niego. Kompilator implementuje ten trait dla każdej zadeklarowanej pamięci, więc w kodzie źródłowym nie ma żadnego impl. Dla `memory heap: u32;` kompilator zachowuje się tak, jakby istniał taki impl:

```wx
trait Memory {
    type Size;
}

impl Memory for heap {
    type Size = u32;
}
```

`Size` to *typ skojarzony* (ang. _associated type_): każdy typ implementujący `Memory` wybiera własny. Dla `heap` jest to `u32`, a dla `memory big: u64;` byłby to `u64`. Kod generyczny odwołuje się do niego jako `M::Size`, więc alokator może przyjmować długość typu `M::Size` i działać poprawnie zarówno dla pamięci 32-, jak i 64-bitowej.

=== Typesety <sec:typesets>

Dotąd `Size` może być dowolnym typem. Pamięć WebAssembly ma jednak tylko dwa typy adresu, 32- i 64-bitowy. Kod generyczny powinien móc na tym polegać, na przykład by dodać dwa adresy lub je porównać, a nic w `type Size;` tego nie gwarantuje.

Naturalna poprawka to wymóg, by `Size` implementował trait `PointerSize`, który implementują `u32` i `u64`. To nie działa, ponieważ trait jest *otwarty*: dowolny kod może go później zaimplementować dla innego typu. Gdyby ktoś napisał `impl PointerSize for u8`, ograniczenie by to przyjęło, a pamięć z adresami 8-bitowymi przeszłaby kontrolę typów.

Dlatego WX dodaje *typeset*: zamknięty zbiór typów, wymieniony w swojej deklaracji (listing #nr(<fig:typeset-vs-trait>)).

#figure(
  kind: raw,
  supplement: [Listing],
  grid(
    columns: (1fr, 1fr),
    column-gutter: 1.2em,
    row-gutter: 0.6em,
    [*Zamknięty: `typeset`*], [*Otwarty: `trait`*],
    [
      ```wx
      typeset PointerSize { u32, u64 }

      impl PointerSize for u8 {}
      // error[E2031]: expected trait,
      // found typeset
      ```
    ],
    [
      ```wx
      trait PointerSize {}
      impl PointerSize for u32 {}
      impl PointerSize for u64 {}

      impl PointerSize for u8 {} // przyjęte
      ```
    ],
  ),
  caption: [Ten sam trzeci `impl`, odrzucony przez typeset i przyjęty przez zwykły trait.],
) <fig:typeset-vs-trait>

Typeset używa się w ograniczeniach tak jak trait, ale nie można go implementować: jego członkowie są wymienieni wyłącznie w deklaracji. Może też wymagać traitów, więc każdy członek `PointerSize` ma również dodawanie, porównywanie i pozostałe operacje, których kod generyczny potrzebuje na adresie.

Trait `Memory` używa tego typesetu, by ograniczyć `Size` i zdefiniować operacje w jego terminach. Poniższy trait jest skrócony:

```wx
pub trait Memory {
    type Size: PointerSize;
    const PAGE_SIZE: Self::Size = 65536;

    func grow(self: Self, delta: Self::Size) -> Self::Size::Signed { .. }
    func size_pages(self: Self) -> Self::Size { .. }
}
```

`type Size: PointerSize` mówi, że typem adresu każdej pamięci jest `u32` lub `u64`. `PAGE_SIZE` jest stałą skojarzoną, a `grow` i `size_pages` odpowiadają wprost instrukcjom WebAssembly `memory.grow` i `memory.size`. Program nie może zaimplementować `Memory` dla własnych typów, ponieważ te operacje potrzebują za sobą prawdziwej pamięci WebAssembly.

=== Zmienne globalne i jawny dostęp <sec:global-access>

Zmienne globalne korzystają z tego samego mechanizmu itemów i traitów. Dla `global mut count: i32 = 0;` kompilator implementuje `Global` z `type Value = i32` oraz `GlobalMut`. Pierwszy trait dostarcza `get`, a drugi dodaje `set`. Niemodyfikowalna zmienna globalna, jak importowane `step` w listingu #nr(<lst:wx-tour>), dostaje tylko `Global`, więc nie ma metody `set`.

Poniższe traity są skrócone, aby pokazać skojarzony typ wartości i operacje. Ograniczenia określające, jakie wartości może przechowywać zmienna globalna, wyjaśnia rozdział #nr(<ch:stack-values>).

```wx
pub trait Global {
    type Value;

    func get(self: Self) -> Self::Value {
        global_get(self)
    }
}

pub trait GlobalMut: Global {
    func set(self: Self, value: Self::Value) {
        global_set(self, value)
    }
}
```

Funkcje `global_get` i `global_set` zapewniają typowany dostęp do odpowiednich instrukcji WebAssembly (rozdział #nr(<ch:intrinsics>)). `GlobalMut: Global` oznacza, że każda zmienna globalna, którą można zapisać, obsługuje też odczyt.

Nazwa `count` identyfikuje item zmiennej globalnej; `count.get()` daje jej przechowywaną wartość `i32`. Arytmetyka w `count.get() + 1` działa więc na zwykłej liczbie całkowitej, a `get` i `set` jawnie wskazują dostęp do stanu modułu. Zmienna lokalna taka jak `next` przechowuje wartość w obrębie jednego wywołania i można jej używać bezpośrednio w wyrażeniach.

To rozróżnienie jest zamierzone. Odczyt modyfikowalnej zmiennej globalnej obserwuje stan, który mogą zmienić inne wywołania lub host, a zapis ten stan zmienia. Dodatkowa składnia czyni obie operacje widocznymi w kodzie. Odczyt niemodyfikowalnej zmiennej globalnej nie zależy w ten sam sposób od zmiennego stanu, ale dla spójności używa tej samej metody dostępu. Umieszczenie dostępu do zmiennych globalnych w funkcjach daje też podstawę pod przyszłe śledzenie efektów, w którym informację o efekcie można dołączyć do tych wywołań.

Kod generyczny używa tych samych metod. Aktualizację licznika z listingu #nr(<lst:wx-tour>) można zapisać jako funkcję przyjmującą dowolną modyfikowalną zmienną globalną przechowującą `i32`:

```wx
func adjust<G: GlobalMut where { Value = i32 }>(g: G, delta: i32) -> i32 {
    local next = g.get() + delta;
    g.set(next);
    next
}

func increment() {
    local next = adjust(count, host::step.get());
    host::log(next);
}
```

Ograniczenie `G: GlobalMut` dostarcza obu metod, a `Value = i32` ustala typ przechowywanej wartości, tak by dodawanie było poprawne. Przekazanie `count` dostarcza wartość itemu, której typ identyfikuje zmienną globalną; nie kopiuje przechowywanej liczby całkowitej. Kompilator wnioskuje `G` z tego argumentu. Ta sama funkcja może aktualizować inną modyfikowalną zmienną globalną `i32`, także importowaną. Przekazanie niemodyfikowalnego `host::step` jako pierwszego argumentu jest odrzucane, ponieważ nie implementuje on `GlobalMut`.

== Importy i eksporty <sec:items-imports>

Importowana encja jest takim samym itemem jak zdefiniowana. Różni się tylko pochodzeniem. Blok importu wskazuje moduł hosta i deklaruje, czego od niego oczekuje:

```wx
import "env" as env {
    func log(value: u32);
    global mut total: u32;
    memory shared: u32;
}
```

Importowana funkcja nie ma ciała, a importowana zmienna globalna nie ma wartości początkowej. Itemów używa się przez nazwę bloku: `env::log`, `env::total`, `env::shared`. Dostają te same typy i traity co itemy zdefiniowane, więc importowana pamięć jest `Memory`, a importowane `global mut` jest `GlobalMut`.

Eksporty działają w przeciwnym kierunku: wskazują itemy, których może używać host. Wpis można zapisać jako osobne polecenie albo kilka wpisów może dzielić blok `export { ... }`, a pakiet może używać jednej postaci lub obu:

```wx
export heap as "memory";
export sum as "add";

export { product, sum as "plus" };
```

Nazwa po `as` jest nazwą zewnętrzną. Wewnątrz programu item ma nazwę zgodną z regułami identyfikatorów wx, ale nazwą eksportu WebAssembly może być dowolny napis. Host może oczekiwać nazwy, która nie jest poprawnym identyfikatorem. Alias pozwala kodowi źródłowemu zachować własną nazwę, a modułowi przedstawić nazwę oczekiwaną przez hosta. Tutaj `sum` jest eksportowane dwukrotnie, raz jako `add` i raz jako `plus`. Wpis bez `as` zachowuje własną nazwę.

Kompilator przypisuje wszystkie indeksy przy generowaniu kodu, zaczynając od importów. Program nigdy nie zapisuje ani nie oblicza indeksu, więc dodanie importu nigdy nie zmienia istniejącego kodu.

== Wiele pamięci na granicy z hostem <sec:multi-memory-host>

Adres przekazany do importowanej funkcji jest tylko liczbą. Aby odczytać bajty pod tym adresem, host musi mieć też dostęp do pamięci, która je zawiera. Moduł może zaimportować pamięć dostarczoną przez hosta albo zdefiniować ją i wyeksportować. W obu przypadkach strona otrzymująca dostęp może czytać i zapisywać *całą pamięć*, a nie tylko zakres przekazany do funkcji #fnote("wasm-spec-modules"). Jeśli moduł eksportuje pamięć z danymi wewnętrznymi wyłącznie po to, by przekazać napis, dane te stają się dostępne również dla hosta. Propozycja wielu pamięci wymienia rozdzielenie danych publicznych i prywatnych jako jedną z motywacji #fnote("wasm-multi-memory").

WX przydziela wymianie osobną pamięć:

```wx
memory host_io: u32;
memory private_mem: u32;

import "host" as host {
    func write(message: super::host_io::&[u8]);
}

func main() {
    host::write("hello world");
}

export { main, host_io as "memory" }
```

Typ parametru `host_io::&[u8]` ustala pamięć literału napisowego. Host otrzymuje jego offset i długość i czyta te bajty z eksportowanej `host_io`. `private_mem` nie jest eksportowana, więc host nie ma do niej bezpośredniego dostępu. Wartości typu `private_mem::&[u8]` nie można przekazać do `host::write`: oba wskaźniki wskazują różne pamięci, a niezgodność wykrywa system typów (podrozdział #nr(<sec:pointers-memory>)). To samo rozdzielenie można uzyskać z dostarczoną przez hosta `host_io` importowaną do modułu, o ile host zarezerwuje całą tę pamięć na wymianę. Nazwy pamięci w WX są gwarancją na poziomie kodu źródłowego; funkcja hosta nadal musi interpretować numeryczny offset względem uzgodnionej pamięci.

== Tabele i tagi: zaprojektowane, niezaimplementowane <sec:items-kinds>

Tabele i tagi nie są zaimplementowane. Projekt idzie tym samym wzorcem. Tabela byłaby deklarowana jak pamięć, a kompilator implementowałby trait udostępniający jej operacje (`table.get`, `table.set`, `table.grow`). Uchwyt do slotu tabeli niósłby swoją tabelę w typie, tak jak wskaźnik niesie swoją pamięć. Tag byłby deklarowany jak struktura z ładunkiem, a kompilator implementowałby dla niego trait `Tag`. Projekty te są tu potraktowane krótko, ponieważ żadnego z nich nie da się jeszcze przetestować.

== Jeden mechanizm <sec:items-summary>

Każda część tego rozdziału korzysta z tego samego mechanizmu: krótka deklaracja tworzy item z własnym typem o zerowym rozmiarze, a kompilator implementuje dla tego typu trait (tabela #nr(<tbl:items-mechanism>)). Trait podaje kształt itemu jako typy skojarzone, a jego operacje jako metody. Nic w sprawdzaniu typów nie dotyczy specjalnie pamięci ani zmiennych globalnych poza kodem, który zapisuje te impl.

#figure(
  booktable(
    columns: (auto, auto, 1fr),
    align: (left, left, left),
    table.header([Deklaracja], [Typ], [Impl zapisany przez kompilator]),
    table.hline(stroke: 0.5pt),
    [`memory heap: u32;`],
    [`heap`],
    [`Memory` z `Size = u32`],
    [`global mut count: u32 = 0;`],
    [`count`],
    [`Global` z `Value = u32` oraz `GlobalMut`],
    [`func add(a: i32, b: i32) -> i32`],
    [`add`],
    [`Call` z `Args = (i32, i32)`, `Result = i32` (rozdział #nr(<ch:calls>))],
  ),
  caption: [Deklaracje, typy ich itemów i traity, które kompilator dla nich implementuje.],
) <tbl:items-mechanism>

Kolejne rozdziały stosują ten sam mechanizm do rzeczy, które nie są deklaracjami. Rozdział #nr(<ch:stack-values>) opisuje trait, który kompilator implementuje dla każdego typu, a rozdział #nr(<ch:calls>) trait implementowany dla każdej funkcji.
