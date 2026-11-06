#import "../../template.typ": booktable, muted, todo
#import "../../bibliography.typ": fnote
#import "../../figures/charts-pl.typ" as ch
#import "helpers.typ": nr

// Where the full study lives. Pin this to a tagged commit before submission.
#let study-url = "https://github.com/MellKam/bachelor-thesis/tree/main/wasm-exposure-study"

= Podstawy i prace pokrewne <ch:background>

Ten rozdział wprowadza pojęcia WebAssembly potrzebne do zrozumienia WX, a następnie porównuje, jak istniejące języki je udostępniają. Porównanie dotyczy dostępu do cech platformy oraz integracji z hostami i kończy się pytaniami, które kierują projektem WX.

// Chapter plan (see also chapter-2-test-matrix.md):
//   2.1 The structure of a WebAssembly module          written
//   2.2 Comparing languages                             first draft (shared design, evidence, scores)
//   2.3 Exposure: tests, rating, results                first draft, charts native
//   2.4 Integration: tests, rating, results             first draft, charts native
//   2.5 Combined ranking                                first draft
//   2.6 Synthesis and design questions                  first draft

== Budowa modułu WebAssembly <sec:module-structure>

Program WebAssembly jest dostarczany jako moduł: samodzielna jednostka, którą host, na przykład przeglądarka lub samodzielne środowisko uruchomieniowe, ładuje i tworzy z niej instancję. Moduł składa się z kilku rodzajów encji. Najważniejsze z nich to:

- *Funkcje* to jednostki kodu, każda z typowaną sygnaturą.
- *Pamięci* to rosnące tablice bajtów.
- *Zmienne globalne* przechowują pojedynczą wartość zadeklarowanego typu i mają określoną mutowalność.
- *Tabele* przechowują referencje i służą głównie do wywołań pośrednich.
- *Tagi* to nominalne identyfikatory powiązane z sygnaturami typów; w WebAssembly używa się ich obecnie do wyjątków.

Moduł może sam definiować te encje albo importować je z hosta, a także wybierać, które z nich wyeksportować #fnote("wasm-spec-modules").

Do ilustrowania modułów służy w tej pracy WAT, tekstowy format WebAssembly. Nawiasy grupują części modułu, a nazwy zaczynające się od `$` identyfikują encje. W listingu #nr(<lst:wat-example>) zagnieżdżone instrukcje przekazują stałą `42` do importowanej funkcji `$log`.

#figure(
  ```wat
  (module
    (import "host" "log" (func $log (param i32)))
    (func $run
      (call $log (i32.const 42)))
    (export "run" (func $run)))
  ```,
  caption: [Minimalny moduł WebAssembly w formacie tekstowym.],
) <lst:wat-example>

+ Zaimportuj funkcję `"log"` z przestrzeni nazw `"host"` i nadaj jej wewnętrzną nazwę `$log`. Przyjmuje ona jeden parametr `i32`.
+ Zdefiniuj funkcję `$run`, która wywołuje `$log` ze stałą `42`.
+ Wyeksportuj `$run` pod nazwą `"run"`, aby host mógł się do niej odwołać.

=== Piaskownica <sec:sandbox>

Ten moduł sam niczego nie zaloguje. Importowaną funkcję `host.log` musi dostarczyć host podczas tworzenia instancji modułu. Dobrze to ilustruje jedną z podstaw modelu izolacji w WebAssembly: moduł może komunikować się z otoczeniem wyłącznie przez udostępnione mu zasoby, takie jak importowane funkcje i pamięci #fnote("wasm-spec-intro").

Tę granicę pomagają utrzymać trzy właściwości:

+ *Dostęp do pamięci jest ograniczony.* Moduł ma dostęp tylko do pamięci, które są mu dostępne, zdefiniowanych wewnętrznie lub importowanych. Każdy dostęp do pamięci jest sprawdzany pod kątem granic, a odwołanie poza jej aktualny rozmiar kończy się trapem (ang. _trap_).
+ *Strukturalny przepływ sterowania.* Skoki podlegają regułom strukturalnego przepływu sterowania w WebAssembly, a wywołania pośrednie są sprawdzane względem oczekiwanego typu funkcji. Reguły te ograniczają wykonanie, choć nie chronią przed błędami wewnątrz samego modułu.
+ *Dostęp na zewnątrz odbywa się przez importy.* Pliki, sieć i zegar systemowy nie są dla modułu domyślnie dostępne. Host musi udostępnić takie możliwości przez importowane funkcje lub inne interfejsy.

Piaskownica nie chroni modułu przed jego własnymi błędami: program może uszkodzić dane w swojej pamięci liniowej, nie wychodząc poza jej granice. Importowane funkcje mogą też przyznawać duże uprawnienia. WASI definiuje interfejsy dostępu do systemu plików i innych usług systemowych, ale to host wybiera, które możliwości udostępni. WASI jest odrębne od podstawowej specyfikacji WebAssembly.

=== Rozszerzenia rdzenia <sec:extensions>

Zestaw instrukcji i model wykonania WebAssembly rozszerzono o funkcje włączone do podstawowej specyfikacji, a kolejne propozycje wciąż się rozwijają #fnote("wasm-proposals").

Kilka rozszerzeń ma szczególne znaczenie dla projektu języka badanego w tej pracy:

- *Multi-memory* pozwala modułowi używać wielu pamięci liniowych, na przykład aby oddzielić dane prywatne od pamięci współdzielonej z hostem.
- *Reference types* pozwalają modułowi przechowywać i przekazywać nieprzezroczyste referencje. `externref` może wskazywać obiekt hosta, na przykład węzeł DOM, bez przedstawiania go jako ręcznie zarządzanego uchwytu w postaci liczby całkowitej.
- *Multi-value* pozwala funkcjom i blokom zwracać wiele wyników. Dzięki temu, gdy funkcja ma zwrócić kilka wartości, nie trzeba przekazywać wskaźnika na wynik.
- *SIMD* wprowadza typ wartości `v128` i instrukcje wektorowe, które mogą wykonywać operacje na wielu liczbowych elementach wektora (ang. _lane_) równolegle.
- *Exception handling* wykorzystuje tagi do rozróżniania typowanych wyjątków, które moduł może zgłaszać i przechwytywać. Są one odrębne od trapów, które oznaczają awarie wykonania.

Te encje i instrukcje to pojęcia, które programista może chcieć wyrazić w kodzie źródłowym. Język może udostępniać je bezpośrednio, dawać do nich dostęp przez biblioteki lub mechanizmy specyficzne dla kompilatora albo w ogóle ich nie udostępniać.

== Porównanie języków <sec:method>

Osiem języków porównano wzdłuż dwóch osi. *Udostępnienie* dotyczy tego, które cechy WebAssembly programista może nazwać, skonfigurować i kontrolować z poziomu kodu źródłowego. *Integracja* dotyczy tego, jak powstały moduł jest uruchamiany, wywoływany, pakowany i debugowany oraz jak jest duży. Osie te opisują dostęp do platformy i jej narzędzi; ukrywanie szczegółów platformy może być świadomym wyborem języka. Są raportowane osobno (podrozdziały #nr(<sec:exposure>), #nr(<sec:integration>)).

*Języki.* Zbadano osiem kolumn językowych (tabela #nr(<tbl:languages>)). C i C++ mają wspólną kolumnę, ponieważ korzystają z jednego toolchainu. MoonBit ma dwa backendy, `wasm` i `wasm-gc`, których nie da się połączyć w jednym module; każdy test uruchomiono na obu, a cechę oferowaną wyłącznie przez drugi backend liczono jako przeszkodę. Zestaw wybrano ze względu na aktualne użycie jako cel kompilacji do WebAssembly i różnorodność założeń projektowych. Nie jest kompletny: znane pominięcia to Emscripten, standardowy kompilator Go i Dart.

#figure(
  booktable(
    columns: (auto, 1fr, auto, auto),
    align: (left, left, left, left),
    table.header([Język], [Wersja], [Model pamięci], [Droga]),
    table.hline(stroke: 0.5pt),
    [Rust],
    [1.99.0],
    [liniowy],
    [LLVM],
    [Zig],
    [0.16.0],
    [liniowy],
    [LLVM],
    [C/C++],
    [clang 23.1.0 (wasi-sdk 34.0)],
    [liniowy],
    [LLVM],
    [Swift],
    [6.4.0 (Embedded Swift)],
    [liniowy],
    [LLVM],
    [MoonBit],
    [`moon` 0.1.20260920, `moonc` v0.10.14],
    [liniowy / Wasm GC],
    [własny backend],
    [AssemblyScript],
    [0.28.20],
    [liniowy + GC w środowisku uruchomieniowym],
    [Binaryen],
    [TinyGo],
    [0.42.0 (Go 1.27.1)],
    [liniowy + GC w środowisku uruchomieniowym],
    [LLVM],
    [Kotlin],
    [2.4.21 (Kotlin/Wasm)],
    [Wasm GC],
    [własny backend],
  ),
  caption: [Porównywane języki w kolejności użytej na wszystkich rysunkach, pogrupowane według modelu pamięci.],
) <tbl:languages>

Kolumna modelu pamięci odróżnia odśmiecanie pamięci realizowane w pamięci liniowej przez środowisko uruchomieniowe języka od własnych mechanizmów GC w WebAssembly. Kolumna drogi podaje infrastrukturę kompilatora użytą do wytworzenia modułu.

*Jak to zweryfikowano.* Każdy test to mały program oparty na dokumentacji języka i zbudowany toolchainem przypiętym w kontenerze. Program sprawdzający analizuje skompilowany plik `.wasm` albo uruchamia go w V8, Wasmtime lub Node. Wyniki są migawką. Programy, program sprawdzający i dowody dla poszczególnych komórek są dostępne w repozytorium projektu #fnote("wx-study"). Wersja kompilatora WX, z którą wykonano przykłady i testy, to commit `1612da8` gałęzi `tir-refactor` #fnote("wx-compiler"). #todo[przypiąć repozytorium badania do commita po wypchnięciu zmian]

== Udostępnienie cech platformy <sec:exposure>

=== Co jest testowane <sec:exposure-tests>

Sprawdzono trzydzieści cech z opublikowanych wersji specyfikacji (1.0, 2.0 i 3.0). Cecha to albo element struktury modułu (pamięć, zmienna globalna, tag), albo rodzina instrukcji badana jako jedna całość, na przykład SIMD. Dla każdej cechy i każdego języka mały program próbuje sprawić, by cecha pojawiła się w skompilowanym module. Każda para dostaje jeden wynik, który mówi, gdzie cecha znajduje się względem języka (tabela #nr(<tbl:vocabulary>)); wynik osiągnięty z zastrzeżeniem otrzymuje flagę, na przykład *częściowo*, gdy kontrolować można tylko część cechy.

#figure(
  booktable(
    columns: (auto, auto, auto, 1fr),
    align: (left, center, center, left),
    table.header([Wynik], [W kodzie źródłowym], [Sprawdzane przez kompilator], [Znaczenie]),
    table.hline(stroke: 0.5pt),
    [Natywna],
    [tak],
    [tak],
    [konstrukcja języka albo typowana funkcja biblioteczna lub wewnętrzna; kompilator może sam wybrać kodowanie],
    [Adnotacja],
    [tak],
    [tak],
    [atrybut przy zwykłej konstrukcji],
    [Konfiguracja],
    [nie],
    [nie],
    [flaga budowania, plik konfiguracyjny lub argument linkera],
    [Asembler wbudowany],
    [tak],
    [nie],
    [asembler lub tekst Wasm pisany ręcznie],
    [Brak],
    [n/d],
    [n/d],
    [nie znaleziono żadnej drogi; _potwierdzony_, jeśli dokumentacja lub kompilator ją odrzuca, w przeciwnym razie _nie znaleziono_],
  ),
  caption: [Słownik używany do klasyfikacji każdej komórki porównania.],
) <tbl:vocabulary>

=== Jak jest oceniana <sec:exposure-rating>

Dowodem są zliczenia wyników. Podsumowuje je jedna ocena od 0 do 1 dla każdego języka. Każda cecha liczy się w całości, częściowo albo wcale; jest dyskontowana za każdą przeszkodę na drodze (opcję budowania, ręcznie pisany asembler, eksperymentalny lub nightly kompilator, środowisko uruchomieniowe dołączane do każdego modułu, ograniczonego hosta albo inny backend); liczy się też bardziej, jeśli należy do rdzenia modułu, z którego korzysta każdy program. Dyskonta i wagi są wyborem autora i wymieniono je w repozytorium. Mają z grubsza uporządkować języki, a nie mierzyć je z dokładnością do drugiego miejsca po przecinku.

=== Wyniki <sec:results>

Wykres #nr(<fig:matrix>) pokazuje, jak każdy język dociera do każdej cechy, odróżniając konstrukcje źródłowe od konfiguracji, asemblera i cech, do których nie znaleziono drogi.

#figure(
  ch.matrix-figure(),
  kind: "chart",
  caption: [Jak każdy język dociera do każdej z #ch.n-features cech WebAssembly, pogrupowanych według modelu pamięci i wersji specyfikacji. Komórka pokazuje najlepszą znalezioną drogę. Pogrubione cechy odpowiadają encjom modułu WebAssembly (podrozdział #nr(<sec:synthesis>)).],
  placement: auto,
) <fig:matrix>

Dla #ch.construct-in-none.len() z #ch.n-features cech żaden język nie oferuje konstrukcji źródłowej ani adnotacji. Te luki obejmują kontrolę nad limitami pamięci i rozmieszczeniem danych, a oba te elementy wpływają na strukturę powstałego modułu.

*Pokrycie różni się między językami.* Wykres #nr(<fig:reach>) zlicza, jak każdy język dociera do trzydziestu testowanych cech. Nawet najszerszy z nich, który osiąga #ch.broadest.reached z #ch.n-features, aż #(ch.broadest.reached - ch.broadest.counts.reachedVia.language) z nich osiąga wyłącznie przez konfigurację lub asembler.

#figure(
  ch.reach-figure(),
  kind: "chart",
  caption: [Liczba spośród #ch.n-features cech, do których każdy język dociera jako konstrukcja języka lub adnotacja, przez konfigurację budowania, jako asembler wbudowany albo wcale.],
) <fig:reach>

*Żaden zestaw cech nie obejmuje pozostałych.* Wykres #nr(<fig:versions>) pokazuje, że języki oparte na pamięci liniowej osiągają więcej z próbkowanych cech wersji 1.0 i 2.0, podczas gdy Kotlin osiąga cechy GC i wyjątków z wersji 3.0. Żaden język nie osiąga w pełni zarówno cech GC, jak i testowanych cech pamięci liniowej. MoonBit oferuje obie grupy, ale na osobnych backendach, których nie można połączyć w jednym module. To wzorzec opisany we wstępie: użycie obu zwykle oznacza łączenie języków.

#figure(
  ch.version-figure(),
  kind: "chart",
  caption: [Osiągnięte cechy spośród badanych, według wersji specyfikacji.],
) <fig:versions>

Wykres #nr(<fig:exposure>) podsumowuje pokrycie i przeszkody w dotarciu do poszczególnych cech. Zakresy pozycji pokazują, jak zmienia się uporządkowanie, gdy zmieniają się współczynniki oceny.

#figure(
  ch.exposure-figure(),
  kind: "chart",
  caption: [Wskaźnik udostępnienia (od 0 do 1) każdego języka, w kolejności malejącej, z zakresem jego pozycji, gdy współczynniki oceny losowo zmieniano 2000 razy.],
) <fig:exposure>

== Integracja <sec:integration>

=== Co jest testowane <sec:integration-tests>

Dostęp do cech platformy to tylko część korzystania z WebAssembly: powstały moduł musi też współpracować ze swoim hostem. Oceniono pięć kryteriów integracji, a szóste raportowano osobno (tabela #nr(<tbl:criteria>)). Kryteria opierają się na trzech małych programach ze skryptami hosta wspólnymi dla wszystkich języków: `life` (obliczenia na pamięci liniowej), `cat` (program WASI typu _command_, który kopiuje standardowe wejście na standardowe wyjście) i `words` (napis na wejściu, rekord na wyjściu).

#figure(
  booktable(
    columns: (auto, 1fr, auto),
    align: (left, left, left),
    table.header([Kryterium], [Test], [Oceniane według]),
    table.hline(stroke: 0.5pt),
    [I1 WASI],
    [`cat` jest budowany dla celu WASI i uruchamiany w Wasmtime],
    [drogi],
    [I2 Component Model],
    [`words` jest budowany jako komponent z typowanym interfejsem i wywoływany w Wasmtime; liczy się tylko bezpośrednie wsparcie, a nie ręcznie pisany kod sklejający],
    [drogi],
    [I3 Wiązania JS],
    [`words` jest wywoływany z Node z napisem i zwraca obiekt, przez kod sklejający generowany przez narzędzia danego języka],
    [drogi],
    [I4 Debugowalność],
    [debugowa wersja `life` jest sprawdzana pod kątem sekcji nazw, DWARF lub source mapy oraz trapa, którego stos wskazuje funkcję ze źródeł],
    [pełna lub częściowa],
    [I5 Rozmiar],
    [wszystkie trzy programy są budowane jako najmniejsza i jako domyślna wersja, a rozmiar mierzony jest po `wasm-opt -Oz`],
    [bajty],
    [I6 Koszt toolchainu],
    [rozmiar instalacji toolchainu, czas zimnej budowy i potrzebne dodatkowe narzędzia],
    [tylko raportowane],
  ),
  caption: [Kryteria integracji.],
) <tbl:criteria>

=== Jak jest oceniana <sec:integration-rating>

Kryteria I1–I3 ocenia się według *drogi*, od najlepszej do najgorszej: wbudowana w toolchain samego języka, oficjalne dodatkowe narzędzie (z projektu języka lub Bytecode Alliance), narzędzie społeczności albo kod sklejający pisany ręcznie przez programistę. Droga bez bezpośredniego wsparcia otrzymuje 0. Rozmiar oceniany jest w skali logarytmicznej, aby jedno bardzo duże środowisko uruchomieniowe nie spłaszczało pozostałych wyników: wersja tysiąc razy większa od najmniejszej dostaje 0. Wynik integracji to średnia ważona kryteriów I1–I5, z wagami podanymi na wykresie #nr(<fig:integration>). Podobnie jak przy udostępnieniu, współczynniki są wyborem autora, a wynik jest tylko podsumowaniem.

=== Wyniki <sec:integration-results>

Wykres #nr(<fig:integration>) przedstawia pięć ocenianych kryteriów i ich ważone podsumowanie.

#figure(
  ch.integration-figure(),
  kind: "chart",
  caption: [Wynik każdego języka w pięciu ocenianych kryteriach integracji (od 0 do 1; – oznacza brak bezpośredniego wsparcia) oraz wynik integracji, czyli ich średnia ważona. Waga każdego kryterium podana jest pod jego nazwą.],
  placement: auto,
) <fig:integration>

Wszystkie osiem języków uruchamia `cat` jako program WASI typu _command_, sześć z nich zwykłym toolchainem. Wsparcie dla Component Model jest mniej jednolite: bezpośrednią drogę ma tylko #ch.order.filter(l => ch.integ.at(l).per.I2 > 0).len() z nich, w każdym przypadku przez oficjalne dodatkowe narzędzie. Integracja z JavaScriptem również jest zróżnicowana, od generowanych wiązań po ręcznie pisany kod sklejający.

Rozmiar modułu także bardzo się różni: najmniejsze wersje `life` mają od 408 bajtów w AssemblyScript do 61 KB w Kotlinie.

== Jak czytać wyniki <sec:reading-scores>

*Jak czytać te liczby.* To migawka testów napisanych na potrzeby tego badania i uruchomionych na przypiętych toolchainach, a autor nie jest jednakowo biegły we wszystkich językach. Zestaw testów próbkuje specyfikację, a nie pokrywa jej w całości, programy integracyjne są małe, a komórka oznaczona jako _nie znaleziono_ znaczy tylko tyle, że nie znaleziono drogi, co jest słabsze niż „niemożliwe”. Niektóre drogi liczono zachowawczo: ręcznie zbudowany komponent nie jest wsparciem dla komponentów. Badanie nie sprawdza, czy język chroni granicę z hostem pod względem bezpieczeństwa. Wyniki podsumowują zliczenia i nie są wyrokiem o żadnym języku.

== Synteza i pytania projektowe <sec:synthesis>

Powtarzające się luki dotyczą struktury modułu i nowszych rozszerzeń. Mogą one odzwierciedlać świadome decyzje dopasowane do odbiorców danego języka. Dla WX wskazują pojęcia, które język zbudowany wokół WebAssembly mógłby uczynić jawnymi.

Pogrubienie na wykresie #nr(<fig:matrix>) oznacza #ch.entity-features.len() cech odpowiadających encjom modułu WebAssembly: sekcji pamięci, wielu pamięciom, zmiennym globalnym, tabelom (wywołania pośrednie, import i eksport oraz wiele tabel) i tagom wyjątków. Żaden język nie oferuje konstrukcji dla więcej niż #ch.max-entity-constructs z nich.

Porównanie dotyczy każdego języka razem z testowanym toolchainem. Ustala, które drogi znaleziono, ale samo w sobie nie wskazuje, czy luka wynika z języka, jego backendu czy linkera.

Z tych luk wynika pięć pytań, które kierują projektem WX:

+ *Zadeklarowane encje.* Czy pamięci, zmienne globalne, importy i eksporty mogą być typowanymi konstrukcjami kodu źródłowego, a nie kontrolowanymi przez opcje budowania czy asembler?
+ *Wiele pamięci.* Czy program może używać wielu pamięci, tak by tożsamość pamięci była reprezentowana w typach i sprawdzana przez kompilator?
+ *Brak narzuconego modelu.* Czy programy mogą przyjmować możliwości w miarę potrzeby, bez wiązania się ze stałym środowiskiem uruchomieniowym czy strategią zarządzania pamięcią?
+ *Sprawdzany dostęp do instrukcji.* Czy surowe instrukcje WebAssembly można udostępnić jako typowane operacje sprawdzane przez kompilator?
+ *Zadeklarowana granica z hostem.* Czy deklaracje w kodzie źródłowym mogą jawnie opisać interfejs z hostem i zmniejszyć zależność od ręcznie pisanego kodu sklejającego?
