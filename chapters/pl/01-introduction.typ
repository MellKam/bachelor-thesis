#import "../../template.typ": todo, unnumbered
#import "../../bibliography.typ": fnote
#import "helpers.typ": nr

#unnumbered[Wstęp] <ch:introduction>

#heading(level: 2, numbering: none, outlined: false)[Motywacja] <sec:motivation>

WebAssembly (Wasm) to przenośny format kodu bajtowego, zaprojektowany do bezpiecznego wykonywania w izolowanym środowisku (ang. _sandbox_). Wywodzi się z asm.js, ograniczonego podzbioru JavaScriptu służącego do kompilowania C i C++ na potrzeby przeglądarki, ale ma własny format binarny i własny model wykonania #fnote("haas2017")#super[,]#fnote("asmjs").

WebAssembly powstał jako technologia dla sieci WWW, lecz dziś używa się go znacznie szerzej. Samodzielne środowiska uruchomieniowe pozwalają stosować go po stronie serwera i w usługach _serverless_, gdzie liczą się szybki start i silna izolacja. Ten sam model izolacji sprawia, że WebAssembly nadaje się także na format rozszerzeń: umożliwia uruchamianie cudzego lub niezaufanego kodu w kontrolowanej piaskownicy.

Jednocześnie WebAssembly wciąż się rozwija. Jego rdzeń pozostaje celowo mały, a nowe możliwości wprowadzają rozszerzenia. Odśmiecanie pamięci (ang. _garbage collection_), wiele pamięci, obsługa wyjątków i powstające właśnie przełączanie stosów poszerzają zakres modeli programowania, które WebAssembly może obsługiwać bezpośrednio. Component Model rozwija z kolei wyższy poziom współpracy niezależnie skompilowanych komponentów ponad granicami języków.

Wraz z tymi rozszerzeniami WebAssembly pozwala pisać programy na coraz więcej sposobów. Programiści zazwyczaj nie piszą jednak bezpośrednio w WebAssembly, tylko w języku źródłowym. Jeden język opiera się na pamięci liniowej, inny na odśmiecaniu pamięci. Użycie obu zwykle oznacza łączenie dwóch języków, choć platforma obsługuje oba podejścia.

#heading(level: 2, numbering: none, outlined: false)[Sformułowanie problemu] <sec:problem>

To, że na WebAssembly kompiluje się wiele różnych języków, jest zamierzone i nie stanowi problemu do rozwiązania: obsługa wielu modeli programowania jest właśnie zadaniem tej platformy. Problem polega na tym, że programista dociera do WebAssembly przez model własny danego języka. Autorzy języka wybierają paradygmat, a ten decyduje o tym, co da się wyrazić, zanim kod zamieni się w WebAssembly. Konstrukcje platformy są dostępne tylko w takim zakresie, w jakim udostępnia je język i jego toolchain.

Wynikają z tego dwie konsekwencje. Po pierwsze, programista często słabo widzi, jakie konstrukcje WebAssembly powstają z jego kodu, ponieważ między jednym a drugim stoją abstrakcje języka. Po drugie, gdy model języka nie sięga tego, co oferuje platforma, zlikwidowanie luki zwykle wymaga opcji budowania, generatorów powiązań albo przekształceń kodu spoza samego języka.

Dotyczy to również języków projektowanych od początku z myślą o WebAssembly. Także one przyjmują określony model programowania, na który składają się strategia zarządzania pamięcią, zestaw abstrakcji i pewne rozumienie bezpieczeństwa, i to właśnie jego udostępniają, zamiast pełnego zakresu konstrukcji platformy. Projektowanie z myślą o WebAssembly oznaczało dotąd przede wszystkim dobrą kompilację do niego, a nie udostępnianie wszystkiego, co oferuje.

Stąd pomysł języka zorganizowanego wokół zasobów WebAssembly, w którym alokacja i polityki środowiska uruchomieniowego są zostawione bibliotekom i aplikacjom. Pamięci, zmienne globalne, tabele i tagi byłyby typowanymi konstrukcjami języka. Długofalowym celem jest połączenie w jednym języku jak największej części możliwości platformy; ta praca bada fundament takiego języka na przykładzie pamięci, zmiennych globalnych, funkcji i wybranych instrukcji.

#heading(level: 2, numbering: none, outlined: false)[Cele] <sec:goals>

Celem pracy jest zbadanie, czy język źródłowy może wprost udostępniać zasoby WebAssembly i kontrolować ich użycie za pomocą systemu typów. Praca sprawdza, czy podstawowe mechanizmy da się zaimplementować w działającym kompilatorze, czy tworzą spójną całość i czy wystarczają do napisania praktycznych programów przykładowych.

Implementacja opiera się na następujących zasadach projektowych:

+ *Typowany model platformy.* Pojęcia WebAssembly są pełnoprawnymi konstrukcjami języka. Programista myśli w modelu samej platformy, a typowana konstrukcja opakowująca pojęcie platformy ma z założenia nie dodawać kosztu w czasie wykonania.
+ *Minimalny rdzeń, możliwości na życzenie.* Podstawowy język jest tak szczupły jak rdzeń WebAssembly. Nie narzuca programiście modelu zarządzania pamięcią, środowiska uruchomieniowego ani rozszerzeń. Dodatkowe możliwości programista włącza stopniowo, w miarę potrzeby.
+ *Jednolite mechanizmy.* Te same mechanizmy systemu typów służą do opisu encji (ang. _entity_) modułu, wartości, wywołań i instrukcji. Ta wspólna podstawa ma pozwolić objąć kolejne możliwości WebAssembly bez osobnego mechanizmu językowego dla każdej z nich.

#heading(level: 2, numbering: none, outlined: false)[Pytania badawcze] <sec:research-questions>

Porównanie istniejących języków w rozdziale #nr(<ch:background>) kończy się pięcioma pytaniami, na które reszta pracy odpowiada dla WX. Czy pamięci, zmienne globalne, importy i eksporty mogą być typowanymi konstrukcjami kodu źródłowego, a nie ustawieniami budowania czy asemblera? Czy program może używać wielu pamięci, tak aby tożsamość pamięci była częścią typów i podlegała kontroli kompilatora? Czy programy mogą przyjmować możliwości w miarę potrzeby, bez ustalonego środowiska uruchomieniowego i strategii zarządzania pamięcią? Czy surowe instrukcje można udostępnić jako typowane operacje sprawdzane przez kompilator? Czy deklaracje w kodzie źródłowym mogą opisywać interfejs z hostem, tak by mniej kodu trzeba było pisać ręcznie? Pełne brzmienie pytań podano w podrozdziale #nr(<sec:synthesis>), a zakończenie do nich wraca.

#heading(level: 2, numbering: none, outlined: false)[Metody] <sec:methods>

W pracy zastosowano cztery metody. Pierwszą jest badanie porównawcze: osiem języków sprawdzono pod kątem trzydziestu cech specyfikacji WebAssembly i pięciu kryteriów integracji z hostami i narzędziami, na małych programach budowanych przypiętymi wersjami toolchainów i weryfikowanych automatycznie (rozdział #nr(<ch:background>)). Następnie projekt WX wyprowadzono ze struktury platformy: kolejno omówiono każdy rodzaj encji, wartości, wywołania i instrukcji, a mechanizm systemu typów, który go reprezentuje, opisano na przykładzie wraz z wynikiem pracy kompilatora (rozdziały #nr(<ch:items>)–#nr(<ch:hosts>)). Trzecią metodą jest implementacja projektu w prototypowym kompilatorze napisanym w Rust; jego budowę i testy opisuje rozdział #nr(<ch:implementation>). Na koniec projekt oceniono tymi samymi testami cech i kryteriami integracji, które zastosowano do pozostałych języków, a także na podstawie rozmiarów generowanych modułów i programów przykładowych łączących te mechanizmy (rozdział #nr(<ch:evaluation>)).

#heading(level: 2, numbering: none, outlined: false)[Inspiracje projektowe] <sec:design-influences>

WX czerpie z kilku tradycji językowych. System typów Rusta, zwłaszcza traity i typy generyczne, zainspirował sposób, w jaki WX opisuje, co potrafi dana encja WebAssembly; kolejną inspiracją były pokrewne klasy typów z Haskella #fnote("rust-traits")#super[,]#fnote("haskell-type-classes")#super[,]#fnote("wadler1989"). Jawna kontrola nad alokacją znana z Ziga wpłynęła na decyzję, by wybory dotyczące alokacji i środowiska uruchomieniowego zostawić programiście #fnote("zig-allocators"). Języki z rodziny ML ukształtowały wyrażeniowy styl WX, wnioskowanie typów i traktowanie funkcji jako wartości, które można składać #fnote("milner1997").

Składnia opiera się na gramatyce w stylu Rusta, ale tam, gdzie pomaga to wyjaśnić powstający moduł, używa słownictwa samego WebAssembly. Nazwy `memory`, `global`, `func`, `import` i `export` znamy z WAT, tekstowego formatu WebAssembly #fnote("wasm-spec-text"). Na sposób, w jaki WX opisuje granice między programem a hostem, wpłynął też WIT, język opisu interfejsów w Component Model #fnote("wasm-wit"). Wszystkie te wpływy służą jednemu celowi: uwidocznić platformę w kodzie źródłowym, nie zmuszając programistów do pisania bezpośrednio w WebAssembly.

#heading(level: 2, numbering: none, outlined: false)[Wkład pracy] <sec:contributions>

Praca wnosi następujące elementy:

+ *Porównanie sposobów, w jakie języki udostępniają WebAssembly* (rozdział #nr(<ch:background>)). Osiem języków sprawdzono pod kątem trzydziestu cech specyfikacji oraz integracji ich modułów z hostami i narzędziami. Badanie opiera się na małych programach budowanych przypiętymi wersjami toolchainów, a ich wyniki są weryfikowane automatycznie. Programy i dowody opublikowano, aby porównanie można było powtórzyć.
+ *Itemy: encje platformy jako typy* (rozdział #nr(<ch:items>)). W WX każda pamięć, zmienna globalna i funkcja jest itemem (nazwaną deklaracją) z własnym typem o zerowym rozmiarze, a trait implementowany przez kompilator opisuje, co ten item potrafi. Typ wskaźnika mówi, do jakiej pamięci wskazuje. Dzięki temu wiele pamięci oraz kod generyczny względem pamięci stają się częścią systemu typów.
+ *Ten sam mechanizm dla wartości i wywołań* (rozdziały #nr(<ch:stack-values>), #nr(<ch:calls>)). Trait wyliczany przez kompilator opisuje, jak dowolny typ WX jest przechowywany na stosie WebAssembly. Rozstrzyga on, jakie typy może przechowywać zmienna globalna, sprawdza reinterpretację między typami i sprawia, że sygnatura funkcji w WebAssembly wynika wprost z jej sygnatury w WX.
+ *Instrukcje jako funkcje z typami* (rozdział #nr(<ch:intrinsics>)). Wybrane instrukcje WebAssembly są udostępnione jako funkcje w bibliotece standardowej. Funkcja wewnętrzna, która wskazuje encję, przyjmuje jej item, nigdy numeryczny indeks.
+ *Kompilator* napisany w Rust, który implementuje ten projekt, z testami dla każdej jego części. Każdy komunikat o błędzie pokazany w rozdziałach projektowych wygenerował właśnie on.

#heading(level: 2, numbering: none, outlined: false)[Zakres pracy] <sec:scope>

Praca koncentruje się na projekcie języka WX i prototypowej implementacji. Kompilator i programy przykładowe pokazują, jak projekt działa w praktyce, a ocena omawia jego mocne strony i ograniczenia.

Implementacja obejmuje:

+ *Podstawy języka.* Parsowanie, analizę semantyczną, system typów z wnioskowaniem, traity i moduły.
+ *Pamięć i wskaźniki.* Część najważniejsza dla pracy. Pamięci deklaruje się w kodzie źródłowym, a wskaźniki niosą informację o pamięci, na którą wskazują.
+ *Zmienne globalne.* Deklarowane w kodzie źródłowym jako typowane konstrukcje, tak jak pamięci.
+ *Importy i eksporty.* Jawne deklaracje w kodzie źródłowym.
+ *Generowanie kodu i optymalizację.* Generowanie kodu WebAssembly oraz przebiegi takie jak wstawianie funkcji (ang. _inlining_) i eliminacja martwego kodu.

Praktyczność sprawdza zestaw programów przykładowych, z których każdy wykorzystuje inną część projektu; są wśród nich programy korzystające z systemu operacyjnego przez WASI Preview 1. Wyniki zestawiono z zasadami wymienionymi w sekcji „Cele”, a ograniczenia, które ujawniły się po drodze, opisano jako ustalenia.

Dalsze prace mogłyby rozszerzyć model o śledzenie efektów, WebAssembly GC, przełączanie stosów i pełniejszą kontrolę bezpieczeństwa pamięci.

#heading(level: 2, numbering: none, outlined: false)[Struktura pracy] <sec:structure>

Rozdział #nr(<ch:background>) przedstawia budowę modułu WebAssembly i porównuje, jak osiem języków ją udostępnia. Porównanie kończy się pięcioma pytaniami, które kierują projektem języka. Rozdział #nr(<ch:items>) pokazuje, jak WX reprezentuje pamięci, zmienne globalne i funkcje jako itemy z własnymi typami oraz jak wskaźniki wskazują swoją pamięć. Rozdział #nr(<ch:stack-values>) opisuje reprezentację na stosie, rozdział #nr(<ch:calls>) stosuje ją do wywołań funkcji, a rozdział #nr(<ch:intrinsics>) wyjaśnia typowany dostęp do instrukcji. Rozdział #nr(<ch:bodies>) opisuje ciała funkcji, a rozdział #nr(<ch:hosts>) łączy te mechanizmy w programach dla przeglądarki i WASI. Rozdział #nr(<ch:implementation>) przedstawia architekturę kompilatora i jego testy. Rozdział #nr(<ch:evaluation>) podaje pokrycie funkcji, integrację i rozmiary modułów, a następnie omawia ograniczenia i dalsze prace. Zakończenie wraca do pytań badawczych.
