#import "../../template.typ": booktable, muted, todo
#import "../../bibliography.typ": fnote
#import "helpers.typ": nr

= Programy w hoście: od przeglądarki do WASI <ch:hosts>

Podstawowy WebAssembly nie udostępnia instrukcji do wypisywania, czytania plików ani pobierania czasu. Moduł korzysta z tych usług przez importy dostarczane przez jego hosta (podrozdział #nr(<sec:sandbox>)). Dwa programy w tym rozdziale wypisują tekst przez funkcję zdefiniowaną przez przeglądarkę i przez WASI Preview 1. Łączą typowane importy (podrozdział #nr(<sec:items-imports>)), wskaźniki związane z konkretną pamięcią (podrozdział #nr(<sec:pointers-memory>)) i jawne sygnatury na granicy (podrozdział #nr(<sec:calls-abi>)).

== Hello, world w przeglądarce <sec:hello-browser>

Moduł potrzebuje od hosta jednej rzeczy, sposobu na wyświetlenie tekstu, więc deklaruje ją jako import (listing #nr(<lst:hello-browser>)).

#figure(
  ```wx
  memory text: u32;

  import "env" as env {
      func print(message: super::text::&[u8]);
  }

  func main() {
      env::print("Hello, world!");
  }

  export {
      main,
      text as "memory",
  }
  ```,
  caption: [Hello, world dla przeglądarki (`examples/hello_browser`).],
) <lst:hello-browser>

`print` nie ma ciała: dostarcza je strona, a moduł podaje tylko jego sygnaturę. Jego parametrem jest slice w pamięci `text`. Literał napisowy `"Hello, world!"` nie ma własnego adresu (podrozdział #nr(<sec:pointers-memory>)), ale typ parametru żąda wskaźnika do `text`, więc kompilator umieszcza trzynaście bajtów w danych statycznych tej pamięci i przekazuje wskaźnik do nich. Nic nie alokuje w czasie wykonania, a moduł nie potrzebuje alokatora.

Na granicy wskaźnik to tylko liczby. Slice to dwie wartości, adres i długość, więc `print` ma typ WebAssembly `(i32 i32) -> ()`, a host otrzymuje offset i liczbę bajtów (podrozdział #nr(<sec:calls-abi>)). Widać to w skompilowanym module (ciało funkcji skrócono do trzech instrukcji):

```wat
(import "env" "print" (func $print (param i32 i32)))
(func $main
  i32.const 0     ;; offset tekstu
  i32.const 13    ;; jego długość
  call $print)
(memory $text 1)
(export "memory" (memory $text))
(export "main" (func $main))
(data (memory $text) (i32.const 0) "Hello, world!")
```

Nazwy to etykiety z formatu tekstowego, dobrane tu tak, by odpowiadały kodowi źródłowemu. W pliku binarnym są liczbami, z importem na początku (podrozdział #nr(<sec:identity-shape>)). Cały moduł ma 105 bajtów. Sama liczba nic nie mówi hostowi, który potrzebuje też pamięci, do której odnosi się offset. Moduł eksportuje więc `text`, a strona czyta z niej bajty (listing #nr(<lst:hello-host>)). To sytuacja opisana w podrozdziale #nr(<sec:items-imports>): host dostaje całą pamięć, a nie tylko przekazany zakres. Tutaj jest to zamierzone, bo pamięć zawiera wyłącznie tekst.

#figure(
  ```js
  const { instance } = await WebAssembly.instantiate(bytes, {
    env: {
      print(offset, length) {
        const memory = new Uint8Array(instance.exports.memory.buffer);
        log(new TextDecoder().decode(memory.subarray(offset, offset + length)));
      },
    },
  });
  instance.exports.main();
  ```,
  caption: [Strona hosta dla listingu #nr(<lst:hello-browser>): `env.print` otrzymuje parę `(offset, length)` i dekoduje bajty z wyeksportowanej pamięci.],
) <lst:hello-host>

Deklaracja importu sprawdza wywołania wewnątrz WX i ustala typ importu modułu w WebAssembly. Host JavaScript musi nadal zinterpretować offset i długość względem uzgodnionej pamięci; WX nie sprawdza tej konwencji po stronie hosta. Jawne wyeksportowanie `text` daje stronie dostęp do bajtów. Pominięcie `text as "memory"` nadal się kompiluje, ale pokazany tu kod hosta nie potrafi już odczytać komunikatu.

== Czym jest WASI <sec:wasi>

Wypisywanie przez funkcję zdefiniowaną przez stronę działa dla jednej strony. Program, który ma działać w wielu hostach, potrzebuje konwencji dla importowanych funkcji. WASI, czyli WebAssembly System Interface, jest taką konwencją. Jej pierwsza wersja, Preview 1, to lista funkcji w przestrzeni nazw importu `wasi_snapshot_preview1`: `fd_write`, `fd_read`, `args_get`, `clock_time_get`, `path_open`, `proc_exit` i inne #fnote("wasi-preview1"). Nazwy i sygnatury są ustalone, a każdy host (środowisko uruchamiane z wiersza poleceń, takie jak Wasmtime, Node.js, shim w przeglądarce) je implementuje. Późniejsze wersje WASI są zdefiniowane na bazie Component Model #fnote("wasm-component-model")\; Preview 1 potrzebuje tylko podstawowego WebAssembly, dlatego można pisać wprost pod niego.

Dla programu ważne są cztery konwencje:

- *Punkt wejścia.* Program typu _command_ eksportuje funkcję o nazwie `_start`. Host ją wywołuje, a program kończy się, gdy ta funkcja zwróci lub wywoła `proc_exit`.
- *Pamięć.* Moduł eksportuje swoją pamięć jako `memory`. Każdy wskaźnik, który przyjmuje lub zwraca funkcja WASI, jest offsetem w niej, a host czyta i zapisuje bajty przez ten eksport.
- *Deskryptory.* Wejście i wyjście to deskryptory plików, zwykłe liczby całkowite: 0, 1 i 2 to standardowe wejście, wyjście i wyjście błędów. Pozostałe deskryptory pochodzą od hosta, na przykład z `path_open`.
- *Wyniki.* Funkcja zwraca numer błędu, 0 oznacza sukces. Wszystko, co wytwarza poza tym, trafia przez wskaźnik przekazany przez wywołującego, więc wywołujący musi zapewnić na to pamięć.

Bufory są przekazywane jako tablice `iovec`, czyli pary adresu i długości w pamięci. `fd_write(fd, iovs, iovs_len, nwritten)` przyjmuje adres takiej tablicy i liczbę jej elementów, a liczbę zapisanych bajtów zapisuje pod adresem `nwritten`.

== Hello, world przez WASI <sec:hello-wasi>

Listing #nr(<lst:hello-wasi>) zapisuje ten sam komunikat na standardowe wyjście.

#figure(
  ```wx
  memory heap: u32;

  enum FileDescriptor(u32) { StdIn = 0, StdOut = 1, StdErr = 2 }

  enum Errno(u16) { Success = 0, Badf = 8, Pipe = 64, .. }

  import "wasi_snapshot_preview1" as wasi {
      use super::*;
      func fd_write(
          fd: FileDescriptor,
          io_vecs: heap::&[heap::&[u8]],
          bytes_written: heap::*u32,
      ) -> Errno;
  }

  func main() {
      local io_vecs: heap::&[heap::&[u8]] = ["Hello, world!\n"];
      local written = heap::DATA_END;
      match wasi::fd_write(FileDescriptor::StdOut, io_vecs, transmute(written)) {
          Errno::Success => (),
          _ => trap(),
      }
  }

  export {
      main as "_start",
      heap as "memory",
  }
  ```,
  caption: [Hello, world przez WASI Preview 1 (`examples/hello_wasi`), skrócone do używanych kodów errno. Uruchamia się poleceniem `wasmtime hello_wasi.wasm`.],
) <lst:hello-wasi>

Listing używa typów dla tego, czym są liczby całkowite. Deskryptor jest enumem nad `u32`, a nie gołą liczbą, więc `fd_write(7, ...)` jest błędem typów (E2005, literał nie może stać się `FileDescriptor`), a trzy standardowe deskryptory mają nazwy. Numer błędu jest enumem nad `u16`, typem, którego używa dla niego WASI, a `match` na wyniku wymienia kody znane programowi.

Enum `Errno` kończy się `..`, co czyni go *otwartym*: wymienia niektóre swoje wartości, a każde `u16` jest nadal poprawnym `Errno`. Odpowiada to sytuacji. WASI definiuje dziesiątki kodów, a host może zwrócić dowolny z nich, więc program nie może wymienić ich wszystkich, a enum zamknięty byłby błędny, bo niewymieniona liczba byłaby wartością, która według typu nie może istnieć. Przy `..` moduł sprawdzania typów wymaga gałęzi `_`: `match` tylko z `Success`, `Badf` i `Pipe` jest odrzucany jako niewyczerpujący, a zgłaszany kontrprzykład (ang. _witness_) wymienia przypadki, które nie są pokryte. Ponieważ enum jest swoją liczbą całkowitą (podrozdział #nr(<sec:stack-repr>)), znacznik otwartości nic nie kosztuje w czasie wykonania. Zmienia tylko to, w co wierzy moduł sprawdzania typów co do zbioru wartości.

Tablica iovec to najciekawszy wiersz. Slice, którego elementami są slice'y (`heap::&[heap::&[u8]]`), jest tablicą, której elementami są pary adresu i długości, a taki jest układ `iovec`. Literał `["Hello, world!\n"]` jest więc już argumentem, którego chce WASI. Jego dane statyczne to dokładnie ta tablica, po której następuje tekst:

```wat
(data (i32.const 0) "\08\00\00\00\0e\00\00\00Hello, world!\0a")
```

Osiem bajtów `(adres 8, długość 14)`, a potem czternaście bajtów tekstu. Program nie zapisuje żadnego iovec ręcznie. Liczba, którą wytwarza `fd_write`, potrzebuje pamięci, do której host może pisać, więc program używa pierwszego słowa po danych statycznych, `heap::DATA_END`, i przekazuje je jako `heap::*u32`. Ponieważ jest to adres wybrany przez program, zamiana go na wskaźnik jest `transmute`: to jedyne miejsce w tym programie, które twierdzi coś, czego kompilator nie może sprawdzić, mianowicie że nie leżą tam żadne inne dane.

== Biblioteka dla programu typu command <sec:wasi-library>

Wypisanie komunikatu wymaga jednego wywołania, ale użyteczny program czyta wejście, zapisuje wyjście i obsługuje błędy, a robienie tego surowymi wywołaniami powtarza tę samą pracę: zbudować iovec, dać hostowi miejsce na liczbę, ponowić częściowy zapis, zdekodować błąd. Listing #nr(<lst:wasi-cat>) pokazuje `cat` napisany z użyciem małej biblioteki (`examples/wasi`), która robi to raz.

#figure(
  ```wx
  package "wasi" as wasi;
  use wasi::{Fd, heap};

  func main() {
      local arena = wasi::arena();
      local buffer = arena.allocate_slice_uninit::<u8>(4096);
      loop {
          local chunk = Fd::Stdin.read(arena, buffer);
          if chunk.len() == 0 { break };
          Fd::Stdout.write(arena, chunk);
      }
  }

  export {
      main as "_start",
      heap as "memory",
  }
  ```,
  caption: [`cat` nad biblioteką WASI (`examples/wasi_cat`): kopiuje standardowe wejście na standardowe wyjście, aż się skończy.],
) <lst:wasi-cat>

Projekt podąża za tym, jak platforma dzieli pracę, a każda część jest osobnym pakietem:

- *Warstwa surowa* to importy i dwa enumy, `Fd` i `Errno`. Jest właścicielem pamięci, ponieważ sygnatury importów ją wskazują (`heap::&[u8]`), a pakiet nie może jeszcze być generyczny względem pamięci (podrozdział #nr(<sec:hosts-limits>)). Program korzystający z biblioteki eksportuje tę pamięć.
- *Deskryptor jest odbiorcą.* `Fd::Stdout.write(arena, bytes)` działa w pętli, aż każdy bajt zostanie zapisany. Każde wywołanie zwraca swój `Errno` jako `try_write`, a zwykłe `write` kończy program z tym kodem jako statusem wyjścia, dla programu, który nie ma nic lepszego do zrobienia.
- *Wywołujący jest właścicielem buforów.* `read` wypełnia dany mu bufor i zwraca widok przeczytanych bajtów, więc nic nie jest nadpisywane przez późniejsze wywołanie. Pusty widok przy sukcesie oznacza, że wejście się skończyło.
- *Pamięć robocza pochodzi z areny.* Iovec i liczba leżą w pamięci, a WX nie ma zmiennych lokalnych z adresem (podrozdział #nr(<sec:body-locals>)), więc każde wywołanie pobiera je z alokatora typu bump, wywołuje hosta i oddaje je, przywracając alokator do poprzedniego stanu. Alokator działa więc jak stos, a pamięć robocza jest ponownie używana przez następne wywołanie zamiast się gromadzić.
- *Formatowanie jest osobne.* Zamiana liczby na tekst nie jest częścią WASI. Pakiet `fmt` wypełnia bufor przekazany przez wywołującego i zwraca widok, generycznie względem pamięci, więc ta sama funkcja wypisuje przez deskryptor albo wypełnia bufor w teście.

Programy zbudowane na tej bibliotece (`cat`, `wc` i program wypisujący argumenty) działają w implementacji WASI w Node, a testy porównują `cat` z jego wejściem i `wc` z wzorcowym zliczeniem na sześciu wejściach do 300 000 bajtów. Zapis do nieistniejącego deskryptora zwraca `Badf`, a test błędu sprawdza, że program kończy się ze statusem 8 i potem nic nie wypisuje.

== Ograniczenie: pakiet nie może przyjąć pamięci <sec:hosts-limits>

Powyższa biblioteka sama deklaruje `memory heap`, a każdy program z niej korzystający musi tę pamięć eksportować. To ograniczenie obecnego kompilatora, a nie decyzja projektowa. Import WASI przyjmuje wskaźniki, a typ wskaźnika wskazuje swoją pamięć (podrozdział #nr(<sec:pointers-memory>)), więc `fd_write` można zadeklarować tylko względem istniejącej pamięci. Funkcja może być generyczna względem pamięci (`find<M: Memory>` w listingu #nr(<lst:body-search>)), ale pakiet nie może, a import jest częścią pakietu. Jedyną pamięcią widoczną w bibliotece jest ta, którą sama zadeklaruje. W rezultacie to biblioteka, a nie program, decyduje, jaką pamięć ma program, i program nie może dać WASI pamięci własnego wyboru, na przykład takiej, która ma też inny limit stron lub inny typ adresu.

Ten sam problem pojawia się przy każdym dużym i współdzielonym API hosta. Środowisko osadzające, które oferuje piętnaście importów (logowanie, argumenty i tak dalej), z których każdy przyjmuje wskaźniki do pamięci modułu, zmusiłoby każdego użytkownika do skopiowania tych deklaracji do każdego modułu, bo nie można ich przenieść do pakietu, który nie zna pamięci.

Planowana dla WX poprawka polega na uczynieniu pakietu szablonem z parametrem pamięci, który program dostarcza, włączając pakiet. Szkic zamierzonej składni (niezaimplementowanej; słowa kluczowe mogą się zmienić) jest w listingu #nr(<lst:package-parameter>).

#figure(
  ```wx
  // wasi/main.wx: pakiet deklaruje, czego potrzebuje
  package type Mem: Memory where { Size = u32 };

  import "wasi_snapshot_preview1" as sys {
      func fd_write(
          fd: Fd,
          io_vecs: Mem::&[Mem::&[u8]],
          bytes_written: Mem::*u32,
      ) -> Errno;
  }

  // program/main.wx: program wybiera pamięć
  memory heap: u32;
  package "wasi" as wasi {
      type Mem = heap;
  }
  ```,
  caption: [Pakiet sparametryzowany pamięcią (propozycja). Importy są deklarowane raz, względem `Mem`, a każdy program tworzy instancję pakietu z własną pamięcią.],
) <lst:package-parameter>

Instancja pakietu jest kompilowana dla otrzymanej pamięci, tak jak funkcja generyczna dla swoich argumentów typów, więc kod pozostaje monomorficzny. Pozwoliłoby to uczynić bibliotekę zwykłą zależnością, jak pakiety `@types/*` w TypeScripcie, a program sam deklarowałby i eksportował swoją pamięć.

== Co pokazują przykłady <sec:hosts-summary>

Do obu hostów dociera się tak samo. Moduł deklaruje, czego potrzebuje, jako typowane importy, typy mówią, w jakiej pamięci leży każdy wskaźnik, a funkcja na granicy przyjmuje parę wskaźnika i długości, którą czyta host. Nie ma osobnego generatora powiązań ani środowiska uruchomieniowego wewnątrz modułu. Różni się to, kto definiuje funkcje: strona dla `print`, środowisko uruchomieniowe dla WASI.

Widoczny jest też koszt. Język bez pamięci domyślnej zmusza program do powiedzenia, gdzie leży iovec i kto jest jego właścicielem, czego programista C czy Rusta nigdy nie pisze, bo robi to ich biblioteka uruchomieniowa. Pokazuje to `cat` z badania: w Ruście jest to wywołanie `io::copy` na standardowym wejściu i wyjściu, a w Zigu, który udostępnia `std.os.wasi`, program sam buduje wartości `iovec`, ale nad tablicą na stosie, bo Zig ma jedną pamięć domyślną #fnote("wx-study"). Biblioteka z tego rozdziału to ta sama praca wykonana raz. Pokazuje też, gdzie język nie jest skończony: biblioteka nie może przyjąć pamięci jako parametru, więc deklaruje własną (podrozdział #nr(<sec:hosts-limits>)), a nic nie zapobiega temu, by widok przeżył reset alokatora, który zwalnia pamięć za nim.

