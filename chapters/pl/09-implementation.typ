#import "../../template.typ": booktable, muted, todo
#import "../../bibliography.typ": fnote
#import "../../figures/architecture-pl.typ" as arch
#import "helpers.typ": nr

= Implementacja i narzędzia <ch:implementation>

Kompilator jest jedną biblioteką, a wszystko inne, co pracuje z kodem WX, jest jej klientem. Moduł sprawdzania typów pozostaje dostępny po zakończeniu sprawdzania, bo późniejsze etapy wciąż o coś go pytają. Kod przechodzi przez kilka reprezentacji pośrednich, z których każda upraszcza jedno zadanie. Rozdział kończy się metodyką testowania i opisem tego, co nie działa.

== Przegląd <sec:impl-overview>

Kompilator to crate Rusta `wx-compiler`. Biblioteka standardowa jest jednym plikiem WX, osadzanym w kompilatorze przy jego budowaniu. Rysunek #nr(<fig:impl-pipeline>) pokazuje etapy budowania, a pod nimi to, do których etapów sięga każdy klient biblioteki. Budowanie czyta pakiety (`vfs`) i parsuje je (`ast`), sprawdza cały program (`tir::check`), obniża osiągalne funkcje do MIR (`tir::lower`, ang. _lowering_), wykonuje inlining, czyli wstawianie funkcji (`mir::inline`), optymalizuje każdą funkcję (`opt`) i koduje moduł (`codegen`). Wiersz poleceń zatrzymuje się na pierwszym etapie, który zgłasza błąd, więc błąd składni nigdy nie dociera do sprawdzania typów, a błąd typów nigdy nie dociera do obniżania.

#figure(
  arch.pipeline-figure(),
  kind: image,
  caption: [Etapy kompilatora (u góry, z produktem, który każdy przekazuje następnemu) i klienci biblioteki, każdy narysowany jako pasek nad etapami, których używa. Pasek przerywany oznacza klienta, który jest napisany, ale nie kompiluje się z obecnym modułem sprawdzania typów (podrozdział #nr(<sec:impl-state>)).],
  placement: auto,
) <fig:impl-pipeline>

Rysunek pokazuje pierwszą decyzję. Formatter potrzebuje tylko drzewa składniowego, serwer języka potrzebuje front endu i sprawdzania typów, a testy backendu nie potrzebują niczego przed MIR. Każdy etap przekazuje następnemu zwykłą strukturę danych i żaden nie zależy od swoich odbiorców, więc klient może zacząć lub zakończyć na dowolnym etapie. Dlatego jest jeden kompilator, a nie po jednym na narzędzie: druga implementacja rozwiązywania nazw dla edytora byłaby drugim miejscem, w którym definiowany jest język, a oba by się rozjechały.

Wykres #nr(<fig:impl-size>) podaje rozmiar każdej części. Sprawdzanie typów to około dwie trzecie kodu produkcyjnego kompilatora; backend, od MIR do bajtów, to około jedna szósta.

#figure(
  arch.size-figure(),
  kind: "chart",
  caption: [Wiersze działającego kodu w Ruście, bez komentarzy i pustych wierszy (`cloc`, 2026-11-06); testy obejmują te wewnątrz plików źródłowych. Biblioteka standardowa, w WX, dodaje około 2 000 wierszy.],
  placement: auto,
) <fig:impl-size>

== Front end <sec:impl-front>

Każda kompilacja ma korzeń w pakiecie, czyli katalogu z manifestem `wx.json`, który wskazuje plik wejściowy i zależności, i zawsze obejmuje bibliotekę standardową. Lekser i parser są napisane ręcznie, a parser czyta wyrażenia metodą pierwszeństwa operatorów (parsowanie Pratta) #fnote("pratt1973")\; jego drzewo składniowe zachowuje komentarze, których potrzebuje formatter. Wszystkie etapy raportują przez jeden typ diagnostyki, z zakresami w źródle (ang. _spans_), etykietami i uwagami, a każdy klient renderuje te same komunikaty diagnostyczne do własnych celów: wiersz poleceń drukuje je jako tekst lub JSON, a testy robią na nich asercje.

== Sprawdzanie typów: kontekst, który pozostaje dostępny <sec:impl-check>

Sprawdzanie typów jest największą częścią kompilatora.

*Sygnatury na żądanie.* Deklaracje odwołują się do siebie w dowolnej kolejności, więc kompilator oblicza sygnaturę, gdy jest pierwszy raz potrzebna, a nie w kolejności źródła, i utrzymuje stos zapytań, aby cykl był zgłaszany wraz z całą pętlą. Zbudowanie sygnatury tylko zamienia zapisaną składnię na typy. Wymagania, które zapisuje, są sprawdzane, gdy istnieją już wszystkie sygnatury, a ciała funkcji na końcu, bo tylko one potrzebują całej reszty. Przez cały czas wracają dwa pytania: czemu równa się typ skojarzony lub stała w typie oraz który impl dotyczy danego typu. Odpowiada na oba jeden silnik, solver. Sam nigdy nie zgłasza problemu: diagnostykę ma konstrukcja, która zapisała typ lub wymaganie, więc definicja zależna od samej siebie jest zgłaszana raz.

Kontekst sprawdzania nie jest zamrażany po jego zakończeniu. `tir::check` uruchamia sprawdzanie, porzuca kontekst i zwraca diagnostyki. `tir::build` zachowuje kontekst, bo obniżanie funkcji generycznej potrzebuje znowu odpowiedzi sprawdzania (postaci normalnej typu, układu agregatu, impl wybranego przez wywołanie), i zwraca MIR razem z diagnostykami.

== Od sprawdzonego programu do bajtów <sec:impl-lower>

Po sprawdzaniu typów następują trzy reprezentacje.

*Obniżanie i MIR.* Sprawdzony program jest generyczny, a moduł nie jest, więc obniżanie monomorfizuje. Zaczyna od eksportów i zmiennych globalnych i obniża funkcję wraz z jej argumentami typów, gdy coś ją pierwszy raz wywoła, więc instancja, do której nic nie sięga, nigdy nie jest budowana. Wynik, MIR, ma kształt WebAssembly: funkcje nad wartościami skalarnymi, pamięci z ich limitami, agregaty z offsetami bajtów ich układu. Sprawdzona forma, której obniżanie jeszcze nie obejmuje, jest zgłaszana jako niewspierana i nigdy nie jest pomijana, więc brakujący przypadek jest błędem, a nie błędnym programem.

*Wstawianie funkcji (inlining).* Inliner wstawia małe wywoływane funkcje, funkcje oznaczone `#[inline]` oraz funkcje o jednym miejscu wywołania do ich wywołujących i usuwa funkcje, do których nic nie sięga. Biblioteka standardowa na tym polega: operatory na typach prymitywnych to małe funkcje oznaczone `#[inline]` nad funkcjami wewnętrznymi, więc `a + b` na liczbach całkowitych, które system typów traktuje jako wywołanie metody traitu, kończy jako jedno `i32.add` w module.

*Optymalizator.* Dla każdej funkcji budowany jest graf typu sea-of-nodes #fnote("click1995"), w którym obliczenie jest węzłem zależnym tylko od swoich wejść i nie ma pozycji, więc identyczne obliczenia to jeden węzeł, a obliczenie, którego nic nie używa, nigdy nie jest emitowane. Scheduler zamienia graf z powrotem na instrukcje.

Ten backend jest celowo prosty: nie szereguje jeszcze pod kątem stosu, więc moduły wychodzą większe, niż to konieczne (podrozdział #nr(<sec:wx-comparison>)). Jest to własność optymalizatora, a nie języka, ponieważ typowany wynik każdej konstrukcji wynika z typów.

== Narzędzia wokół kompilatora <sec:impl-tooling>

`wx` to jeden program z podpoleceniami `build`, `check` i `format`, a każde z nich przyjmuje katalog z `wx.json`. Formatter (`wx-fmt`) drukuje kod z drzewa składniowego i nie potrzebuje informacji o typach. Serwer języka i wersja biblioteki dla przeglądarki były pisane pod poprzedni moduł sprawdzania typów i są pracą niedokończoną (podrozdział #nr(<sec:impl-state>)).

== Testowanie <sec:impl-testing>

Każdy etap jest testowany na własnej granicy, z danymi wejściowymi, które otrzymuje, i wynikiem, który przekazuje dalej, a testy etapu działają bez etapów po nim. Tabela #nr(<tbl:impl-tests>) wymienia warstwy; kompilator ma około 1350 testów, a formatter 75.

#figure(
  booktable(
    columns: (auto, 1fr),
    align: (left, left),
    table.header([Warstwa], [Co sprawdza test]),
    table.hline(stroke: 0.5pt),
    [Pakiety i pliki],
    [Manifesty, ścieżki, rozwiązywanie modułów i zależności.],
    [Składnia],
    [Tekst źródłowy i kształt jego drzewa albo jego diagnostyka.],
    [Deklaracje i solver],
    [Sygnatury, ograniczenia, zgodność impl, stałe, układy.],
    [Ciała],
    [Typy i diagnostyka wyrażeń, wzorców i miejsc.],
    [Obniżanie],
    [Program jest kompilowany, uruchamiany w Wasmtime, a jego wynik sprawdzany.],
    [MIR, optymalizator, backend],
    [Inlining, niezmienniki schedulera, moduły zbudowane ręcznie z MIR.],
    table.hline(stroke: 0.5pt),
    [Formatter],
    [Tekst wytworzony dla źródła i idempotentność.],
  ),
  caption: [Warstwy testów kompilatora i formattera.],
) <tbl:impl-tests>

*Komunikaty diagnostyczne, a nie snapshoty.* Test sprawdzania typów w większości określa, jakie komunikaty diagnostyczne program musi wytworzyć, sprawdzane wraz z ich poziomem ważności, a nie tylko kodem, a nieudana asercja drukuje kod źródłowy wokół diagnostyki. Snapshot dużej struktury zapisuje to, co kompilator robi, nie mówiąc, co powinien robić, więc parser ma tylko dwa testy snapshotowe, a pozostałe wprost formułują sprawdzaną tezę.

*Testy wykonania.* Testy obniżania biorą program jako tekst, uruchamiają sekwencję, którą wykonuje `wx build`, tworzą instancję modułu w Wasmtime i wywołują jego eksporty. Wasmtime waliduje moduł przy ładowaniu, więc każdy z tych testów sprawdza też, że kompilator emituje poprawny WebAssembly. Program można uruchomić z inliningiem i bez niego, więc niepowodzenie można przypisać obniżaniu albo inlinerowi. To warstwa, która mówi, co robi skompilowany program. Drugi zestaw testów buduje MIR ręcznie, bez sprawdzania typów, i go uruchamia, co ustala kontrakt między obniżaniem a backendem.

== Stan i ograniczenia <sec:impl-state>

Nie wszystko, co opisano powyżej, obecnie działa.

- *Serwer języka i wersja dla przeglądarki są niedokończone.* Oba były pisane pod moduł sprawdzania typów, który zastąpiono, a `wx lsp` tylko zgłasza, że serwer nie jest podłączony. Potrzebują punktu wejścia sprawdzania typów zwracającego jego kontekst oraz przepisania indeksu symboli i uzupełniania serwera nad nowymi tabelami.
- *Nie każda sprawdzona forma jest obniżana.* Referencje do funkcji (wywołania przez `call_ref`), stałe typu funkcji lub wektora, slice będący polem i wzorce ze stałymi zmiennoprzecinkowymi są zgłaszane jako niewspierane.
- *Optymalizacja backendu jest ograniczona.* Usuwa wspólne podwyrażenia i martwe wartości, ale brakuje jej pełnego szeregowania pod kątem stosu i upraszczania przepływu sterowania.
