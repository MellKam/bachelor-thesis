#import "../../template.typ": todo, unnumbered
#import "helpers.typ": nr

#unnumbered[Zakończenie] <ch:conclusion>

Celem pracy było wykazanie, że język może wziąć za punkt wyjścia własny model WebAssembly, tak aby encje modułu, wartości na jego stosie, jego wywołania i jego instrukcje opisywał system typów, a nie ukrywało ich środowisko uruchomieniowe. Projekt rozwinięto w rozdziałach o itemach, wartościach stosowych, wywołaniach, funkcjach wewnętrznych, ciałach funkcji i hostach, zaimplementowano w kompilatorze (rozdział #nr(<ch:implementation>)) i zmierzono tymi samymi narzędziami co języki, z którymi go porównano (rozdział #nr(<ch:evaluation>)).

Na pięć pytań badawczych ze wstępu można teraz odpowiedzieć, z uwzględnieniem ograniczeń, które ujawniła ocena.

+ *Zadeklarowane encje.* Pamięci, zmienne globalne, importy i eksporty są konstrukcjami kodu źródłowego, a każdy item ma własny typ (rozdział #nr(<ch:items>)). Tabele i tagi są zaprojektowane, ale niezaimplementowane.
+ *Wiele pamięci.* Wskaźnik niesie pamięć, na którą wskazuje, więc program może używać wielu pamięci, a kod może być generyczny względem nich. W testach cech wiele pamięci i pamięci 64-bitowe zostały osiągnięte w pełni (podrozdział #nr(<sec:coverage>)).
+ *Brak narzuconego modelu.* Biblioteka standardowa zawiera tylko to, czego wymaga język, a alokacja jest biblioteką napisaną w WX; język nie narzuca alokatora ani obowiązkowego środowiska uruchomieniowego (rozdziały #nr(<ch:items>), #nr(<ch:hosts>)).
+ *Sprawdzany dostęp do instrukcji.* Wybrane instrukcje są udostępnione jako typowane funkcje biblioteki standardowej, a funkcja wewnętrzna, która wskazuje encję, przyjmuje item, nigdy indeks (rozdział #nr(<ch:intrinsics>)). Część zestawu instrukcji, taka jak konwersje z rozszerzeniem znaku i nasycone oraz SIMD, nie została jeszcze dodana.
+ *Zadeklarowana granica z hostem.* Importy i eksporty są deklaracjami, a warstwę WASI Preview 1 można napisać w samym WX (rozdział #nr(<ch:hosts>)). Nie jest ona częścią dystrybucji, więc kryteria integracji oceniają ją jako ręcznie pisany kod sklejający.

WX osiąga 10 z 30 grup cech, co daje remis z TinyGo w najniższej liczbie osiągniętych cech, i jest ostatni pod względem wyniku integracji (podrozdział #nr(<sec:wx-comparison>)). Jego zoptymalizowane moduły należą do najmniejszych w badaniu. Wyniki te opisują obecną implementację na małych programach; nie rozstrzygają, czy projekt pomieści każdą brakującą cechę. Kompilator jest testowany na granicy każdego etapu, a programy z rozdziałów projektowych skompilowano nim i uruchomiono (podrozdział #nr(<sec:impl-testing>)).

Wnioski ograniczają się do kilku rzeczy. Porównanie sprawdza próbkę specyfikacji małymi programami. Kompilator jest prototypem: serwer języka i wersja dla przeglądarki nie działają jeszcze z obecnym modułem sprawdzania typów, a backend nie szereguje pod kątem stosu (podrozdział #nr(<sec:impl-state>)). System typów opisuje, do której pamięci należy wskaźnik, ale typy liniowe do zarządzania zasobami, śledzenie efektów i typy sumy są przedmiotem dalszych prac (podrozdział #nr(<sec:future>)).

Wyniki sugerują praktyczne zastosowania tam, gdzie liczą się układ pamięci i interfejs z hostem: małe moduły dla środowisk uruchomieniowych i systemów wtyczek, narzędzia wiersza poleceń wywołujące WASI bezpośrednio oraz biblioteki pisane raz i używane z różnymi pamięciami. Dalsze prace powinny podłączyć serwer języka do nowego modułu sprawdzania typów, dodać brakujące instrukcje i tabele oraz wesprzeć Component Model, który jest planowaną główną drogą do hostów.
