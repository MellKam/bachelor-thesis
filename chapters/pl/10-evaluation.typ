#import "../../template.typ": booktable, muted, todo
#import "../../bibliography.typ": fnote
#import "../../figures/charts-pl.typ" as ch
#import "helpers.typ": nr

= Ocena i dalsze prace <ch:evaluation>

== Pokrycie cech WebAssembly <sec:coverage>

WX przetestowano tymi samymi testami cech, programem sprawdzającym i kryteriami akceptacji co pozostałe języki (podrozdział #nr(<sec:exposure>)). Osiąga 10 z 30 grup cech: siedem w pełni i trzy częściowo. Daje to remis z TinyGo w najniższej liczbie osiągniętych cech. Wyniki ustalają pokrycie zaimplementowanego podzbioru; wsparcie dla pozostałych cech wymaga dalszej implementacji lub pracy projektowej. Tabela #nr(<fig:wx-coverage>) podaje drogę do każdej cechy i status każdej luki.

#figure(
  ch.wx-figure(),
  kind: table,
  caption: [#ch.n-features cech WebAssembly z badania, w postaci, w jakiej osiąga je WX, pogrupowane według wersji specyfikacji. Brakująca cecha jest na tym etapie nieobecna w kompilatorze; kolumna statusu mówi, czy jest zaprojektowana, gotowa do implementacji, wymaga badań, nie była rozważana, czy jest odroczona.],
  placement: auto,
) <fig:wx-coverage>

*Osiągnięte częściowo.* Trzy cechy próbowano osiągnąć i każda zawodzi na jednym sprawdzeniu: importowana pamięć bierze limity od hosta, więc atrybut limitów jest odrzucany przy imporcie (cecha 2); dane statyczne są umieszczane przez kompilator na początku pamięci, a program nie może wybrać, gdzie się zaczynają (cecha 6); a `clz`, `ctz`, `popcnt`, `rotl` i `rotr` nie mają funkcji wewnętrznej (cecha 8).

*Instrukcje, które potrzebują tylko funkcji wewnętrznej.* Konwersje z rozszerzeniem znaku i nasycone (cecha 11) oraz instrukcje wektorowe (cechy 15, 16 i 26) są podobne do instrukcji, które język już udostępnia: każda to deklaracja w bibliotece standardowej związana z instrukcją, a dla drugiej grupy także typ wektorowy. Żadna nie została jeszcze napisana.

*Cechy zależne od tabel i referencji do funkcji.* Tabele (cechy 3, 4, 18 i 19) są zaprojektowane, ale niezaimplementowane, a referencje do funkcji (cecha 22) są na nich zbudowane: typ wartości funkcyjnej jest już określony tak, by obniżał się do wywołania przez typowaną referencję, ale bez tabel nie ma na co go obniżyć. Te pięć to jedna praca, a nie pięć.

*Cechy odroczone lub wymagające badań.* Rozszerzone wyrażenia stałe (cecha 21) wynikają z próby leniwie inicjalizowanych zmiennych globalnych, która została odłożona. Sekcje niestandardowe (cecha 7), pasywne segmenty danych (cecha 13) i funkcja startowa (cecha 5) nie zostały zaprojektowane: nie rozstrzygnięto, jakiemu przypadkowi użycia ma służyć forma na poziomie kodu źródłowego. Pozostałe (`externref`, typy i rzutowania z odśmiecaniem pamięci, obsługa wyjątków, wywołania ogonowe i podpowiedzi dla rozgałęzień: cechy 17, 20, 23, 24, 27, 28 i 30) pasują do istniejącego projektu, ale każda wymaga zbadania, jak pojawiłaby się w systemie typów; typy GC i obsługa wyjątków są w podrozdziale #nr(<sec:future>).

== WX na tle innych języków <sec:wx-comparison>

Kryteria integracji i ocenę z podrozdziału #nr(<sec:integration>) zastosowano do WX bez zmian, więc jego wyniki można czytać na tle ośmiu języków z tamtego rozdziału. Poniższe wykresy dodają WX do wykresów z tamtego rozdziału, w wyróżnionym wierszu; wcześniejszych wykresów nie rysowano na nowo.

*Rozmiar.* Trzy programy to te z badania: `cat` (WASI Preview 1), `life` i `words`. Miara jest ta sama co dla pozostałych języków: moduł po `wasm-opt -Oz` z Binaryen, gdy jest mniejszy niż własne wyjście kompilatora. Ma to większe znaczenie dla WX niż dla pozostałych, ponieważ backend nie układa jeszcze wartości na stosie (ang. _stackify_): trzyma części agregatów w osobnych zmiennych lokalnych, a każda wartość pośrednia przechodzi przez zmienną lokalną. Surowe `cat` i `words` są około dwa razy większe niż najmniejsze surowe moduły, a Binaryen usuwa większość tej różnicy (wykres #nr(<fig:wx-size>)). Wyjście kompilatora nie ma więc rozmiaru, jaki moduły WX muszą mieć, a scheduler układający wartości na stosie zmniejszyłby tę różnicę.

#figure(
  ch.size-figure(langs: ch.order + ("wx",), highlight: "wx"),
  kind: "chart",
  caption: [Rozmiar trzech programów dla wersji każdego języka o najniższym poziomie abstrakcji. `cat` w WX deklaruje trzy używane importy WASI i sam umieszcza swoje bufory; wersja przez bibliotekę WASI z rozdziału #nr(<ch:hosts>) ma 4307 bajtów w postaci surowej i 634 po `wasm-opt`.],
  placement: auto,
) <fig:wx-size>

Najmniejsze moduły `cat` są prawdopodobnie małe dlatego, że nie dołączają żadnej biblioteki ani środowiska uruchomieniowego: MoonBit, AssemblyScript i WX wywołują funkcje WASI bezpośrednio, a Zig sięga do nich przez cienkie powiązania. `cat` w Ruście i C dołącza bibliotekę standardową i jest znacznie większy, podobnie jak te w TinyGo, Kotlinie i Swifcie, które niosą środowisko uruchomieniowe. Wynik w rozmiarze, czyli logarytmiczna odległość od najmniejszego programu każdego rodzaju (podrozdział #nr(<sec:integration>)), wynosi dla WX 0,95, najwięcej spośród dziewięciu języków.

*Integracja.* Wykres #nr(<fig:wx-integration>) pokazuje pięć kryteriów. WX jest ostatni, z wynikiem 0,40: mocny w rozmiarze, słaby w tym, co zbudowano wokół kompilatora. Droga, którą programista pisze ręcznie, ma wagę o połowę mniejszą, a tym są dziś dla WX WASI i wiązania JavaScript: programista deklaruje importy i sam przekształca dane. Biblioteka z rozdziału #nr(<ch:hosts>) pokazuje, że można to napisać raz w samym WX, ale nie jest ona częścią dystrybucji, a badanie ocenia to, co programista znajduje.

Droga pisana ręcznie jest zamierzona: biblioteka standardowa zawiera tylko to, czego wymaga język, a interfejsy hosta są pakietami, więc program może połączyć się z WASI, przeglądarką lub jeszcze nieistniejącym interfejsem na tych samych zasadach. Pozostałe dwie luki to praca nad kompilatorem. Component Model wymaga obniżania do kanonicznego ABI, a nie ma wersji debugowej, więc moduł nie ma sekcji nazw, DWARF ani source mapy, a trap pokazuje tylko indeks funkcji.

#figure(
  ch.integration-figure(langs: ch.order + ("wx",), highlight: "wx"),
  kind: "chart",
  caption: [Kryteria integracji z podrozdziału #nr(<sec:integration>) z dodanym WX, uporządkowane według wyniku integracji. Kreska oznacza brak kryterium.],
  placement: auto,
) <fig:wx-integration>

Podsumowując, WX osiąga 10 z 30 cech, wszystkie jako konstrukcje źródłowe lub adnotacje, a żadnej przez konfigurację budowania ani asembler wbudowany. To więcej cech jako konstrukcji niż oferują Swift (9), Zig (8) czy TinyGo (5) i o jedną mniej niż Rust (11), który osiąga łącznie 24, ale większość z nich przez konfigurację lub asembler. WX ma najwyższy wynik w rozmiarze spośród dziewięciu języków. Jego wynik integracji jest najniższy: jego drogi WASI i JavaScript są pisane ręcznie, a nie ma on wsparcia dla Component Model ani wersji debugowej.

== Dalsze prace <sec:future>

Język opisany w tej pracy obejmuje encje platformy, wartości, wywołania, instrukcje i ciała funkcji. Poniższe punkty to ograniczenia, na które natrafiły przykłady z poprzednich rozdziałów, oraz rzeczy, które język pomija. Każdy z nich jest w jakimś stopniu zaprojektowany albo ma uzasadnienie w konkretnym przykładzie; żaden nie jest ukończony. Kolejność nie wyraża priorytetów.

*Typy sumy.* WX ma struktury, krotki i enumy będące liczbami całkowitymi, ale nie ma typu, którego wartość jest jednym z kilku kształtów. Obejścia widać w przykładach: wyszukiwanie podłańcucha zwraca `(Bool, Mem::Size)` zamiast `Option` (listing #nr(<lst:body-search>)), a wywołanie WASI wytwarzające wartość zwraca parę numeru błędu i wartości. Typ sumy dałby obu właściwą postać. Potrzebuje też reprezentacji na stosie Wasm, którą podrozdział #nr(<sec:stack-repr>) definiuje jako płaską listę wartości, więc wariant trzeba przechowywać jako tag oraz sumę (ang. _union_) wartości jego alternatyw.

*Mniejsze rozszerzenia języka.* Zakres slice'a `x[a..b]` jest parsowany, ale zgłaszany jako niewspierany, więc kod buduje fragment slice'a z części (rozdział #nr(<ch:hosts>)), a iteratory zastąpiłyby ręcznie pisane pętle indeksowe z przykładów. Trait `Sized` określałby rozmiar i wyrównanie typu w ograniczeniu zamiast dwóch funkcji wewnętrznych. Stałe generyczne (`const N<S: PointerSize>: S`) są rozpoczęte i niedokończone, a traity generyczne to celowe ograniczenie, którego złagodzenie jest kwestią otwartą.

*Parametry pakietów.* Pakiet nie może przyjąć pamięci jako parametru, więc biblioteka importująca funkcje hosta musi sama deklarować pamięć (podrozdział #nr(<sec:hosts-limits>)). Uczynienie pakietu szablonem nad pamięcią, tworzonym przez program, który go używa, pozwoliłoby takiej bibliotece być zwykłą zależnością.

*Śledzenie efektów.* Projekt w repozytorium to system lokalny, włączany na życzenie: każda funkcja jest nieczysta, chyba że jest oznaczona adnotacją, a adnotacja jest ograniczeniem na efekty, jakie funkcja może wykonać, sprawdzanym bez wnioskowania przez wywoływane funkcje. Pozwoliłby sygnaturze powiedzieć, że funkcja nie dotyka pamięci lub dotyka tylko jednej. Propozycja WebAssembly dla typowanych kontynuacji i handlerów efektów (WasmFX) jest odpowiednikiem po stronie platformy, a połączenie obu to praca otwarta.

*Własność i pożyczanie.* Wskaźniki niosą sigil, `*` dla wyłącznego i `&` dla współdzielonego, ale moduł sprawdzania typów nie narzuca na nie żadnej dyscypliny. Widok może przeżyć pamięć, do której wskazuje: arena z podrozdziału #nr(<sec:wasi-library>) wydaje komórki, które późniejsze wywołanie ponownie wykorzystuje, a nic nie zapobiega temu, by program jedną zatrzymał. Kontrola pożyczek (ang. _borrow checker_) jest zaprojektowana, ale niezaimplementowana, i zamieniłaby te konwencje w błędy.

*Typy z odśmiecaniem pamięci.* WX udostępnia pamięć liniową i typy referencyjne, które istnieją jako wartości. Propozycja GC dodaje struktury i tablice zarządzane przez hosta, osiągane przez typowane referencje zamiast adresów #fnote("wasm-proposals"). Byłyby drugim rodzajem encji podobnej do pamięci: referencja nie ma adresu, więc typy wskaźników z tej pracy jej nie opisują, a system typów potrzebowałby dla niej formy.

*Serwer języka i wersja dla przeglądarki.* Oba istnieją, ale są pisane pod poprzedni moduł sprawdzania typów (podrozdział #nr(<sec:impl-state>)). Ich ponowne podłączenie wymaga punktu wejścia sprawdzania typów zwracającego jego kontekst oraz przepisania indeksu symboli i uzupełniania nad nowymi tabelami.

*Component Model i WIT.* Biblioteka WASI z rozdziału #nr(<ch:hosts>) jest przeznaczona dla Preview 1, które potrzebuje tylko podstawowego WebAssembly. Późniejsze wersje WASI i większość integracji między językami są definiowane przez Component Model #fnote("wasm-component-model"), którego interfejsy zapisuje się w WIT #fnote("wasm-wit"). Wsparcie dla niego oznacza generowanie deklaracji importów i eksportów z opisu interfejsu oraz obniżanie wartości WX do kanonicznej reprezentacji ich typów. Jawne pamięci i sygnatury na granicy w WX są dobrą podstawą, bo kanoniczne ABI jest opisane w terminach pamięci i liczb.
