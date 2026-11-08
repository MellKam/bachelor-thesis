#import "../../template.typ": todo, unnumbered

#unnumbered[Conclusion] <ch:conclusion>

The thesis set out to show that a language can take WebAssembly's own model as its starting point, so that the entities of a module, the values on its stack, its calls and its instructions are described by the type system and not hidden behind a runtime. The design was developed in the chapters on items, stack values, calls, intrinsics, bodies and hosts, implemented in a compiler (@ch:implementation) and measured with the same instruments as the languages it was compared with (@ch:evaluation).

The five research questions of the introduction can now be answered, with the limits that the evaluation found.

+ *Declared entities.* Memories, globals, imports and exports are constructs of the source, and every item has a type of its own (@ch:items). Tables and tags are designed but not implemented.
+ *Several memories.* A pointer carries the memory it points into, so a program can use several memories, and code can be generic over them. The feature probes reach multiple memories and 64-bit memories completely (@sec:coverage).
+ *No imposed model.* The standard library holds only what the language requires, and allocation is a library written in WX; the language imposes neither an allocator nor a mandatory runtime (@ch:items, @ch:hosts).
+ *Checked access to instructions.* Selected instructions are exposed as typed standard-library functions, and an intrinsic that names an entity takes the item, never an index (@ch:intrinsics). Part of the instruction set, such as the sign-extension and saturating conversions and SIMD, has not been added yet.
+ *Declared host boundary.* Imports and exports are declarations, and a WASI Preview 1 layer can be written in WX itself (@ch:hosts). It is not part of the distribution, so the integration criteria rate it as hand-written glue.

WX reaches 10 of the 30 feature groups, tying with TinyGo for the lowest reached count, and is last on the integration score (@sec:wx-comparison). Its optimized modules are among the smallest in the study. These results describe the current implementation on small programs; they do not establish whether the design can accommodate every missing feature. The compiler is tested at the boundary of each stage, and the programs of the design chapters were compiled and run with it (@sec:impl-testing).

Several things limit these conclusions. The comparison tests a sample of the specification with small programs. The compiler is a proof of concept: the language server and the browser build do not yet work with the current type checker, and the backend does not schedule for the stack (@sec:impl-state). The type system describes which memory a pointer belongs to, but linear types for managing resources, effect tracking and sum types are future work (@sec:future).

The results suggest practical uses where the layout of memory and the interface to the host matter: small modules for runtimes and plugin systems, command-line tools that call WASI directly, and libraries that are written once and used with different memories. Further work should connect the language server to the new checker, add the missing instructions and tables, and support the Component Model, which is the planned main route to hosts.
