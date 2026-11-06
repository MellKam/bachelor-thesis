#import "../../template.typ": booktable, muted, todo
#import "../../bibliography.typ": fnote

= Programs in a Host: from the Browser to WASI <ch:hosts>

A WebAssembly module computes and nothing else. It cannot print, read a file or learn the time, because the core specification defines no such instruction. Everything that reaches outside the module is an import, supplied by the host that instantiates it (@sec:sandbox). This chapter writes two complete programs against two hosts. The first prints in a browser, with an import that the page defines. The second prints through WASI, the standard set of imports for a program that runs outside the browser. Along the way it shows what the earlier chapters bought in practice: imports as items (@sec:items-imports), pointers that name their memory (@sec:pointers-memory), and the calling convention of a boundary function (@sec:calls-abi).

== Hello, world in a browser <sec:hello-browser>

The module needs one thing from its host, a way to show text, so it declares that as an import (@lst:hello-browser).

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
  caption: [Hello, world for a browser (`examples/hello_browser`).],
) <lst:hello-browser>

`print` has no body: the page supplies it, and the module only states its signature. Its parameter is a slice in the memory `text`. The string literal `"Hello, world!"` has no address of its own (@sec:pointers-memory), but the parameter's type asks for a pointer into `text`, so the compiler places the thirteen bytes in that memory's static data and passes a pointer to them. Nothing allocates at run time, and the module needs no allocator.

At the boundary the pointer is only numbers. A slice is two values, an address and a length, so `print` has the WebAssembly type `(i32 i32) -> ()`, and the host receives an offset and a byte count (@sec:calls-abi). The compiled module shows this (the function body is shortened to its three instructions):

```wat
(import "env" "print" (func $print (param i32 i32)))
(func $main
  i32.const 0     ;; the offset of the text
  i32.const 13    ;; its length
  call $print)
(memory $text 1)
(export "memory" (memory $text))
(export "main" (func $main))
(data (memory $text) (i32.const 0) "Hello, world!")
```

The names are labels from the text format, here chosen to match the source. In the binary they are numbers, with the import first (@sec:identity-shape). The whole module is 105 bytes. A number alone says nothing to the host, which also needs the memory the offset refers to. The module therefore exports `text`, and the page reads the bytes from it (@lst:hello-host). This is the situation @sec:items-imports described: the host gets the whole memory, not just the range it was passed. Here that is intended, since the memory holds only the text.

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
  caption: [The host side of @lst:hello-browser: `env.print` receives the pair `(offset, length)` and decodes the bytes from the exported memory.],
) <lst:hello-host>

Two things in this example are worth stating because the language makes them explicit. The import is a declaration with a type, so a host function that disagrees with the module's expectation (a number where a pointer is expected, say) is a visible difference between two signatures, not a crash in a call. And the module's memory is a named item that the program exports on purpose: leaving out `text as "memory"` still compiles, and the module then has no way to show anything, which is correct.

== What WASI is <sec:wasi>

Printing through a function the page defines works for one page. A program that should run under many hosts needs a convention for the functions it imports. WASI, the WebAssembly System Interface, is that convention. Its first version, Preview 1, is a list of functions in the import namespace `wasi_snapshot_preview1`: `fd_write`, `fd_read`, `args_get`, `clock_time_get`, `path_open`, `proc_exit` and others #fnote("wasi-preview1"). The names and signatures are fixed, and each host (a command-line runtime such as Wasmtime, Node.js, a browser shim) implements them. Later WASI versions are defined on top of the Component Model #fnote("wasm-component-model"); Preview 1 needs only core WebAssembly, which is why it can be written against directly.

Four conventions matter for a program:

- *Entry point.* A command exports a function named `_start`. The host calls it, and the program ends when it returns or calls `proc_exit`.
- *Memory.* The module exports its memory as `memory`. Every pointer a WASI function takes or returns is an offset into it, and the host reads and writes the bytes through the export.
- *Descriptors.* Input and output are file descriptors, plain integers: 0, 1 and 2 are standard input, output and error. Other descriptors come from the host, for example from `path_open`.
- *Results.* A function returns an error number, 0 for success. Anything it produces besides that goes through a pointer the caller passes, so the caller must provide memory for it.

Buffers are passed as arrays of `iovec`, a pair of an address and a length in memory. `fd_write(fd, iovs, iovs_len, nwritten)` takes the address of such an array and how many elements it has, and writes the count of bytes written to the address `nwritten`.

== Hello, world through WASI <sec:hello-wasi>

@lst:hello-wasi writes the same message to standard output.

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
  caption: [Hello, world through WASI Preview 1 (`examples/hello_wasi`), shortened to the errno codes it uses. It runs with `wasmtime hello_wasi.wasm`.],
) <lst:hello-wasi>

The listing uses the types for what the integers are. The descriptor is an enum over `u32`, not a bare number, so `fd_write(7, ...)` is a type error (E2005, a literal cannot become a `FileDescriptor`) and the three standard descriptors have names. The error number is an enum over `u16`, WASI's type for it, and a `match` on the result names the codes the program knows.

The enum `Errno` ends in `..`, which makes it *open*: it names some of its values, and every `u16` is still a valid `Errno`. This matches the situation. WASI defines dozens of codes and the host may return any of them, so the program cannot list them all, and a closed enum would be wrong, because an unlisted number would be a value the type says cannot exist. With `..` the checker requires the `_` arm: a `match` with only `Success`, `Badf` and `Pipe` is rejected as non-exhaustive, and the witness it reports names the cases that are not covered. Since an enum is its integer (@sec:stack-repr), the open marker costs nothing at run time. It changes only what the checker believes about the set of values.

The iovec array is the most interesting line. A slice of slices, `heap::&[heap::&[u8]]`, is an array whose elements are each an address and a length, which is the layout of an `iovec`. The literal `["Hello, world!\n"]` is therefore already the argument WASI wants. Its static data is exactly the array followed by its text:

```wat
(data (i32.const 0) "\08\00\00\00\0e\00\00\00Hello, world!\0a")
```

Eight bytes of `(address 8, length 14)` and then the fourteen bytes of text. The program writes no iovec by hand. The count `fd_write` produces needs memory the host can write to, so the program uses the first word after the static data, `heap::DATA_END`, and passes it as a `heap::*u32`. Because that is an address the program chose, converting it to a pointer is a `transmute`: it is the one place in this program that asserts something the compiler cannot check, namely that no other data lives there.

== A library for a command <sec:wasi-library>

Writing a message needs one call, but a useful command reads input, writes output and handles failure, and doing that with raw calls repeats the same work: build the iovec, give the host a place for the count, retry a short write, decode the error. @lst:wasi-cat shows `cat` written against a small library (`examples/wasi`) that does this once.

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
  caption: [`cat` over the WASI library (`examples/wasi_cat`): copy standard input to standard output until it ends.],
) <lst:wasi-cat>

The design follows how the platform divides the work, and each part is a separate package:

- *The raw layer* is the imports and the two enums, `Fd` and `Errno`. It owns the memory, because the import signatures name it (`heap::&[u8]`) and a package cannot yet be generic over a memory (@sec:hosts-limits). A program that uses the library exports that memory.
- *The descriptor is the receiver.* `Fd::Stdout.write(arena, bytes)` loops until every byte is written. Each call returns its `Errno` as `try_write`, and the plain `write` ends the program with the code as its exit status, for a command that has nothing better to do.
- *The caller owns the buffers.* `read` fills the buffer it is given and returns a view of the bytes read, so nothing is overwritten by a later call. An empty view with success means the input has ended.
- *Scratch space comes from an arena.* The iovec and the count live in memory, and WX has no addressable locals (@sec:body-locals), so each call takes them from a bump allocator, calls the host and gives them back by resetting the allocator to where it was. The allocator therefore works as a stack, and the scratch space is reused by the next call instead of accumulating.
- *Formatting is separate.* Turning a number into text is not WASI. A package `fmt` fills a buffer the caller passes and returns a view, generic over the memory, so the same function prints through a descriptor or fills a buffer in a test.

The programs built on it (`cat`, `wc` and an argument printer) run under Node's WASI implementation, and the tests compare `cat` with its input and `wc` with a reference count on six inputs up to 300 000 bytes. A write to a descriptor that does not exist returns `Badf`, and the failure test checks that the program ends with status 8 and prints nothing afterwards.

== A limit: a package cannot take a memory <sec:hosts-limits>

The library above declares `memory heap` itself, and every program using it must export that memory. That is a limitation of the current compiler, not a design choice. A WASI import takes pointers, and a pointer type names its memory (@sec:pointers-memory), so `fd_write` can only be declared against a memory that exists. A function can be generic over a memory (`find<M: Memory>` in @lst:body-search), but a package cannot, and an import is part of a package. The only memory that is in scope inside a library is one it declares. The result is that the library, not the program, decides which memory the program has, and a program cannot give WASI a memory of its own choosing, for example one that also has a different page limit or a different address type.

The same problem appears for any host API that is large and shared. An embedding that offers fifteen imports (logging, arguments and so on), each taking pointers into the module's memory, would make every user copy those declarations into each module, because they cannot be moved into a package that does not know the memory.

The fix planned for WX is to make a package a template with a memory parameter, which the program supplies when it brings the package in. A sketch of the intended syntax (not implemented; the keywords may change) is in @lst:package-parameter.

#figure(
  ```wx
  // wasi/main.wx: the package declares what it needs
  package type Mem: Memory where { Size = u32 };

  import "wasi_snapshot_preview1" as sys {
      func fd_write(
          fd: Fd,
          io_vecs: Mem::&[Mem::&[u8]],
          bytes_written: Mem::*u32,
      ) -> Errno;
  }

  // program/main.wx: the program picks the memory
  memory heap: u32;
  package "wasi" as wasi {
      type Mem = heap;
  }
  ```,
  caption: [A package parameterised by a memory (proposed). The imports are declared once, against `Mem`, and each program instantiates the package with its own memory.],
) <lst:package-parameter>

An instance of the package is compiled for the memory it was given, as a generic function is for its type arguments, so the code stays monomorphic. This would let the library be a plain dependency, as `@types/*` packages are for TypeScript, and a program would declare and export its memory itself.

== What the examples show <sec:hosts-summary>

Both hosts are reached the same way. The module declares what it needs as typed imports, the types say which memory every pointer is in, and the boundary function takes the pointer-and-length pair that a host reads. There is no separate binding generator and no runtime inside the module. What differs is who defines the functions: a page for `print`, a runtime for WASI.

The cost is also visible. A language without an ambient memory makes the program say where the iovec lives and who owns it, which a C or Rust programmer never writes, because their runtime library does it. The `cat` of the study shows the difference: in Rust it is a call of `io::copy` over standard input and output, while in Zig, which exposes `std.os.wasi`, the program builds the `iovec` values itself, but over an array on the stack, because Zig has one ambient memory #fnote("wx-study"). The library in this chapter is the same work done once. It also shows where the language is not finished: a library cannot take a memory as a parameter, so it declares its own (@sec:hosts-limits), and nothing prevents a view from outliving the allocator reset that frees the memory behind it.

