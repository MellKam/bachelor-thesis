# results/

| Path | What it is | Written by |
|---|---|---|
| `<lang>/<NN>.<variant>.{json,txt}` | The checker's verdict for one probe variant (`.json`) and its build log (`.txt`) | `make probe-<lang>` |
| `coding.json` | The classification of every cell: **the one hand-authored file** | by hand |
| `matrix.md` | The language × feature matrix with the evidence behind each cell | `make matrix` |
| `rating/weights.json` | The coefficients of the score: reach, obstacle factors, feature importance | by hand |
| `rating/rating.json` | The same numbers as data for charts: support, checked, directness and score per language, per spec version and per cell | `make rating` |
| `rating/rating.md` | Tallies per language, a 0–1 score from `weights.json`, and which orderings survive changing the coefficients | `make rating` |

`check/cells.mjs` loads `coding.json`, checks it against the evidence (probe directories, `ABSENT.md` files, verdicts) and derives
what the two reports need. Neither report keeps data of its own, so there is nothing to keep in sync.

## integration.json

Hand coding of the integration axis (`INTEGRATION.md`), one cell per language and criterion `I1`-`I4` in the same shape as
`coding.json`: `variants` (each `{ route, support, tools?, needs?, missing?, probes?, verdict? }`) or `absent`, plus a `note`.
`route` is `builtin`, `official-tool`, `community-tool` or `hand-written`; `tools` names the extra tools (the toolchain-cost record);
`needs` is the same closed list as for exposure; `verdict` points a variant at a verdict that lives elsewhere (`I5.words/floor`).
`I5` has no variants: `{ cat: { floor, default } }` names the I1 builds whose sizes stand for `cat`; `life` and `words` come from
their own builds. Verdicts are `integration/<lang>/I<n>.<variant>.{txt,json}` (`I5.<program>.<variant>` for size). `make
integration-matrix` cross-checks the coding against them.

## coding.json

`coding.json[lang][feature]` is one of three kinds of cell.

```jsonc
// a feature the language can produce, by one or more probe variants
"03": {
  "variants": {
    "default": { "expressed_as": "native", "support": "full" }
  },
  "flags": ["implicit table"],            // optional: only what the categories cannot say
  "note": "The table must be a non-const global."   // optional
}

// a feature it cannot produce; rests_on lists the probes that failed (none: then probes/<NN>-<slug>/<lang>/ABSENT.md must exist)
"05": { "absent": "not found", "rests_on": ["stable-ctor"], "flags": ["constructor only"], "note": "..." }

// specified in PROBES.md but not probed yet
"31": { "pending": true }
```

`coding.json` also has a top-level `"caveats": { "<lang>": ["text"] }` for facts about every probe of a language (for example that the host must call
`_initialize` first). They are printed in both reports and count for nothing; a nuance that belongs to one feature goes in that cell's
`needs`, `flags` or `note` instead.

A **variant record** describes one probe variant with categories only:

| Field | Required | Values |
|---|---|---|
| `expressed_as` | yes | `native` (language construct or typed intrinsic), `annotation` (attribute on an ordinary construct), `config` (build flag, config file, linker argument), `inline_asm` (assembly or Wasm text written by hand: Rust `global_asm!`, Zig `asm`, C `__asm__`, MoonBit `extern "wasm"`) |
| `checked` | no, only with `inline_asm` | `true` or `false`: whether the language's own compiler relates the hand-written block to the surrounding program (typed operands or constraints, a declared signature verified against the body), shown by a negative probe that breaks the types on purpose and is rejected by the language's compiler (the probes are in `negative/inline-asm/`; none of the four routes passed, so no cell is checked). Rejection only by the assembler, the linker or the engine's validator is `false`. Default: `native` and `annotation` are checked, `config` and `inline_asm` are not. It changes the Checked count and the figures, never the score |
| `support` | yes | `full`, or `partial` (then `missing` says what is not produced) |
| `missing` | with `partial` | free text |
| `needs` | no | what else the developer has to accept, from a **closed list**; each kind counts once, however it is worded. `nightly-compiler`: the whole project needs a nightly, unsupported compiler. `experimental-api`: an API, flag or target feature marked experimental or unstable, on a supported compiler. `extra-runtime`: a runtime or library shipped in every module. `restricted-host`: the module only runs on certain hosts (it imports WASI functions or JS glue). `other-backend`: the other backend of the same language (only for variants named `wasm:…` or `wasm-gc:…`). A construct whose compiled form is the feature counts as `native` even when the compiler picks the encoding (a function value that becomes `call_indirect` or `call_ref`, a cast in a class hierarchy that becomes `ref.cast`). A mechanism that only imitates the feature with different semantics (Rust's panic unwinding is not an exception construct) is not a route at all: it goes in the cell's note and the cell is judged by the routes that remain. An obstacle is never recorded for optimiser behaviour: if the optimiser drops an instruction, write a better probe, and if that makes it appear reliably there is no obstacle |
| `probes` | no, default `[the variant's name]` | probe directories the record rests on, when it needs more than one (for example memory export and import) |

`probes` entries are probe names. A language with several probe directories (MoonBit: `moonbit/` for the `wasm` backend,
`moonbit-gc/` for `wasm-gc`) writes a probe of the first directory as `name` and of another as `moonbit-gc/name`; the variants of such a
language are named after their backend (`wasm:closure`, `wasm-gc:closure`). The directories are listed in `LANG_DIRS` in `check/cells.mjs`.

Failed and build-failed variants are not records; they stay in `<lang>/*.json` as evidence of absence and are listed as "other
attempts" in `matrix.md`. Opt-in compiler flags (`-msimd128`, `--enable simd`) are not recorded as categories, because every
language needs one for post-MVP features; write them under `flags` if they help the reader.

### What is derived

- **The cell's result** (Native, Annotation, Config, Inline asm) is the `expressed_as` of the variant that stands for the cell: the most
  complete first (`support`), then the one the compiler checks, then the one with the fewest obstacles. The
  other variants are listed in `rating/rating.md` with their obstacle counts.
- **Obstacles** of a variant: one if `expressed_as` is `config` or `inline_asm` (whether or not the block is checked), plus one per entry of `needs`. There are no weights.
- **The phrases** `partial: <missing>` and one per `needs` kind (`needs an unstable toolchain`, ...) come
  from the record. Free text about *why* goes in the cell's `note`; nothing reads it.
- **The evidence line** in `matrix.md`: the probes of that variant with their verdicts, then every other directory as "other attempts".

`make matrix` and `make rating` stop with an error on a missing cell, an unknown field or value, a partial record without
`missing`, a probe without a directory or a verdict, or an absent cell with neither `rests_on` nor an `ABSENT.md`. They warn when
a record says `full` while the checker failed the probe, or `partial` while every probe passes.
