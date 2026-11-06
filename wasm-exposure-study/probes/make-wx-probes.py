#!/usr/bin/env python3
"""Writes probes/<NN>-<slug>/wx/<variant>/{main.wx,wx.json,cmd[,spec]} and ABSENT.md files for the WX column.
Run from the study root: python3 probes/make-wx-probes.py"""
import os

CMD = "wx build . -o out.wasm\n"
MANIFEST = '{ "type": "bin", "entry": "main.wx" }\n'

# (dir, variant, spec or None, source)
PROBES = [
 ("01-imports-exports", "default", None, '''import "host" as host {
    func log(value: i32);
}

func run() {
    host::log(42);
}

export {
    run,
}
'''),
 ("02-memory", "export", "02:export", '''#[memory_limits({ min_pages: 1, max_pages: 4 })]
memory heap: u32;

func touch() -> u32 {
    heap.size_bytes()
}

export {
    heap as "mem",
    touch,
}
'''),
 ("02-memory", "import", "02:import", '''import "host" as host {
    memory mem: u32;
}

func first(at: host::mem::&u8) -> u8 {
    at.*
}

export {
    first,
}
'''),
 ("06-data-segments", "default", None, '''#[memory_limits({ min_pages: 1 })]
memory heap: u32;

const MAGIC: heap::&[u8] = "WASM";

func peek(addr: u32) -> u32 {
    local at = RawPtr::<heap, u8>::from_addr(addr).as_ref();
    transmute::<u8, u32>(at.*) + MAGIC.len() * 0
}

export {
    peek,
    heap as "memory",
}
'''),
 ("08-integer-ops", "default", None, '''func i_add(a: i32, b: i32) -> i32 { a + b }
func i_sub(a: i32, b: i32) -> i32 { a - b }
func i_mul(a: i32, b: i32) -> i32 { a * b }
func i_div(a: i32, b: i32) -> i32 { a / b }
func i_rem(a: i32, b: i32) -> i32 { a % b }

export {
    i_add,
    i_sub,
    i_mul,
    i_div,
    i_rem,
}
'''),
 ("09-float-builtins", "default", None, '''func f_sqrt(x: f64) -> f64 { f64_sqrt(x) }
func f_min(a: f64, b: f64) -> f64 { f64_min(a, b) }
func f_max(a: f64, b: f64) -> f64 { f64_max(a, b) }
func f_ceil(x: f64) -> f64 { f64_ceil(x) }
func f_floor(x: f64) -> f64 { f64_floor(x) }
func f_trunc(x: f64) -> f64 { f64_trunc(x) }
func f_nearest(x: f64) -> f64 { f64_nearest(x) }
func f_copysign(a: f64, b: f64) -> f64 { f64_copysign(a, b) }
func f_abs(x: f64) -> f64 { f64_abs(x) }

export {
    f_sqrt,
    f_min,
    f_max,
    f_ceil,
    f_floor,
    f_trunc,
    f_nearest,
    f_copysign,
    f_abs,
}
'''),
 ("10-globals", "default", None, '''import "host" as host {
    global base: i32;
}

global mut counter: i32 = 0;

func bump() -> i32 {
    counter.set(host::base.get() + 1);
    counter.get()
}

export {
    counter,
    bump,
}
'''),
 ("12-bulk-memory", "default", None, '''#[memory_limits({ min_pages: 1 })]
memory heap: u32;

func bulk_test(n: u32) -> u32 {
    local src = RawPtr::<heap, u8>::from_addr(256).as_ptr();
    local dst = RawPtr::<heap, u8>::from_addr(2048).as_ptr();
    memory_fill(src, 5, n);
    memory_copy::<u32, heap, heap>(dst, src.*.&, n);
    local copy = slice_from_parts::<heap, u8>(dst.*.&, n);
    local mut sum: u32 = 0;
    local mut i: u32 = 0;
    loop {
        if i == n { break };
        sum += transmute::<u8, u32>(copy[i]);
        i += 1;
    }
    sum
}

export {
    bulk_test,
}
'''),
 ("14-multi-value", "default", None, '''func divmod(a: i32, b: i32) -> (i32, i32) {
    (a / b, a % b)
}

export {
    divmod,
}
'''),
 ("25-multiple-memories", "default", None, '''#[memory_limits({ min_pages: 1 })]
memory a: u32;
#[memory_limits({ min_pages: 1 })]
memory b: u32;

func copy_test() -> u32 {
    local from = slice_from_parts_mut::<a, u8>(RawPtr::<a, u8>::from_addr(0).as_ptr(), 4);
    from[0] = 1;
    from[1] = 2;
    from[2] = 3;
    from[3] = 4;
    local into = slice_from_parts_mut::<b, u8>(RawPtr::<b, u8>::from_addr(0).as_ptr(), 4);
    memory_copy::<u32, a, b>(
        RawPtr::<b, u8>::from_addr(0).as_ptr(),
        RawPtr::<a, u8>::from_addr(0).as_ref(),
        4,
    );
    transmute::<u8, u32>(into[0]) + transmute::<u8, u32>(into[1])
        + transmute::<u8, u32>(into[2]) + transmute::<u8, u32>(into[3])
}

export {
    copy_test,
    a as "memory_a",
    b as "memory_b",
}
'''),
 ("29-memory64", "default", None, '''#[memory_limits({ min_pages: 1 })]
memory big: u64;

func touch() -> u32 {
    local at = RawPtr::<big, u32>::from_addr(16).as_ptr();
    at.* = 42;
    at.*
}

export {
    touch,
    big as "memory",
}
'''),
]

ABSENT = {
 "03-table-indirect-call": "WX has no table declaration, no element segments and no `call_indirect`. A `func(A) -> R` value lowers to `call_ref` in the design, which needs typed function references; neither tables nor that lowering exist in the current compiler (tables are designed, not implemented: notes in the repository).",
 "04-table-import-export": "No table items in the language (see 03).",
 "05-start-function": "The language has no start-function attribute or export-block form. An export named `_start` is an ordinary export, not the start section; no source construct emits a start section.",
 "07-custom-sections": "No attribute or item emits a custom section. The only attributes are `inline`, `fixed_order` and `memory_limits`.",
 "11-conversions-sign-extension": "std has no intrinsic for `i32.trunc_sat_f64_*`, `i32.extend8_s` or `i32.extend16_s`: `i32_trunc_f64` is the trapping conversion and narrow integers are held as i32 with unchecked `transmute`.",
 "13-passive-data-segments": "Static data is always an active segment placed by the compiler; there is no source form for a passive segment, `memory.init` or `data.drop`.",
 "15-simd": "No `v128` type and no SIMD intrinsics in std.",
 "16-simd-memory-ops": "No `v128` type and no SIMD intrinsics in std (see 15).",
 "17-externref": "std has `funcref` only as the representation of `func(A) -> R`; there is no `externref` type.",
 "18-multiple-tables": "No table items in the language (see 03).",
 "19-table-operations": "No table items in the language (see 03).",
 "20-tail-calls": "No `return_call` form. The backend never emits `return_call` and does not turn mutual tail recursion into a loop, so the probe would only show stack exhaustion; none was written.",
 "21-extended-const": "A global's initializer is evaluated at compile time into a constant (`global_values`) and one that is not a constant expression is an error (E2015), so a global cannot be initialised from an imported global. The module's globals always get a plain constant initializer.",
 "22-typed-function-references": "No `ref.func` or `call_ref` is emitted by the current backend: `func(A) -> R` calls are specified to lower to `call_ref` but this path is not lowered yet.",
 "23-gc-typed-refs": "No GC types: structs and arrays are laid out in linear memory. Wasm GC is on the future-work list.",
 "24-gc-casts-subtyping": "No GC types (see 23).",
 "26-relaxed-simd": "No `v128` type and no SIMD intrinsics in std.",
 "27-exception-tags": "No exception handling: no tag items, `throw` or `try`. Effect tracking (WasmFX) and exceptions are future work.",
 "28-exnref-exceptions": "No exception handling (see 27).",
 "30-branch-hinting": "No attribute for branch hints and no `metadata.code.branch_hint` section is emitted.",
}

for d, var, spec, src in PROBES:
    p = f"probes/{d}/wx/{var}"
    os.makedirs(p, exist_ok=True)
    open(f"{p}/main.wx", "w").write(src)
    open(f"{p}/wx.json", "w").write(MANIFEST)
    open(f"{p}/cmd", "w").write(CMD)
    if spec:
        open(f"{p}/spec", "w").write(spec + "\n")

for d, why in ABSENT.items():
    p = f"probes/{d}/wx"
    os.makedirs(p, exist_ok=True)
    open(f"{p}/ABSENT.md", "w").write(f"# {d} — WX: Absent (confirmed)\n\n{why}\n")
