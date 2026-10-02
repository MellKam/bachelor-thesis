### 1.2 Problem statement

Most languages that target WebAssembly were not designed around it. Instead, they bring an existing programming model to the platform and translate that model into Wasm. This works well for portability, but it also means that a language usually exposes only the parts of WebAssembly that fit naturally into its existing design.

The issue is therefore not that existing languages cannot compile to WebAssembly, but that they usually expose it through a programming model chosen in advance. WebAssembly itself leaves considerably more room for choice. Linear memory and garbage-collected references can coexist, multiple memories can serve different purposes, and extensions can introduce new forms of control flow or interaction without requiring every program to adopt them.

WebAssembly is mostly recognized as compilation target, which indeed was a main reason of it, allowing developers to use familiar languages and tools while benefiting from Wasm's portability and sandboxing. It allows many langauges to bring their programming model and translate it to wasm primitives, but often this limits things you can actaully do and makes the actaul integration with platform awkward, requiring codegeneration and other tools to patch it. 

But if we abstract away from specific langauges we can see that WebAssembly gives consideable more root for choice. Linear memory and garbage-collected references can coexist, multiple memories can serve different purposes, and extensions can introduce new forms of control flow or interaction without requiring every program to adopt them.

Wasm itself is already a well-designed platform. It's already structured enough to reason about directly. What it lacks is just ergonomics: a syntax that isn't verbose WAT, and types system that will catch mistakes at compile time. A language designed around the platform, to treat WebAssembly not merely as a compilation target, but as the model from which its own abstractions are derived.


Languages that target WebAssembly serve different purposes. Many bring an existing programming model to the platform, allowing developers to use familiar languages and tools while benefiting from Wasm's portability and sandboxing. This is a reasonable approach, and it is not the aim of this thesis to replace it.

However, it leaves room for a different approach: a language designed around WebAssembly's own execution model. Wasm provides capabilities such as linear memories, garbage-collected references, and multiple memories, while its extension model allows programs to use additional features as they become available. These capabilities offer considerable flexibility, but using them directly often requires working with low-level instructions, compiler-specific mechanisms, or additional glue code.

The opportunity is to make this flexibility accessible through a language that provides more direct control over WebAssembly while streamlining the development experience. Rather than imposing a separate runtime or hiding the platform behind an existing programming model, such a language could expose Wasm's concepts through a coherent type system, concise syntax, and higher-level abstractions.

The goal is to explore how a language built around WebAssembly could make its capabilities easier to use without sacrificing control over the platform.


### 1.2 Problem statement

WebAssembly was designed as a portable compilation target for different programming languages, allowing developers to bring their existing tools and programming models to the platform while benefiting from its portability and sandboxing. Each language, however, exposes the platform through its own abstractions and runtime, so the capabilities a developer can reach depend as much on the language's design as on WebAssembly itself.

This is not inherently a problem. Different languages make different trade-offs, and no single language needs to expose every capability of the platform. However, WebAssembly provides a broader set of building blocks than any one programming model necessarily requires. Linear memory and garbage-collected references can coexist, multiple memories can serve different purposes, and extensions can introduce additional capabilities such as new control-flow mechanisms. These features create a space of possible language designs, with existing languages each covering a different part of it.

This creates an opportunity for a language designed around WebAssembly itself. Rather than committing to a particular runtime or memory-management model, it could allow developers to combine the platform's capabilities according to their needs. The challenge is to make this practical without requiring developers to write raw WAT or work around the assumptions built into their language's runtime.

The aim is therefore not to replace existing languages or expose every Wasm feature. It is to explore a language that provides typed, compile-time-checked constructs over WebAssembly's own execution model, giving developers direct control over the platform without an intervening layer of runtime decisions.