#!/bin/sh
# Builds every probes/<id>/rust/<variant>/ cargo project (release profile) and runs the checker on the result.
# Run inside wasm-exposure-rust from the study root:   sh probes/run-rust.sh [probe-id ...]
# Per variant: optional `toolchain` file (default = the image's stable toolchain), optional `spec` file (checker spec, default = probe id).
# A failed build is a recorded result, not a runner error. Full logs go to results/rust/<id>.<variant>.txt.
set -u
mkdir -p results/rust
want="$*"
printf '%-5s %-20s %-14s %-8s %s\n' PROBE VARIANT TOOLCHAIN BUILD CHECK
for d in probes/*/rust/*/; do
  [ -f "$d/Cargo.toml" ] || continue
  id=$(echo "$d" | cut -d/ -f2); var=$(basename "$d")
  if [ -n "$want" ]; then case " $want " in *" $id "*) ;; *) continue;; esac; fi
  tc=stable; [ -f "$d/toolchain" ] && tc=$(cat "$d/toolchain")
  spec=$id; [ -f "$d/spec" ] && spec=$(cat "$d/spec")
  log=results/rust/$id.$var.txt; tgt=/tmp/t/$id-$var; rm -rf "$d/out" "$tgt"; mkdir -p "$d/out"
  plus=""; [ "$tc" != stable ] && plus="+$tc"
  {
    echo "# $id/$var toolchain=$tc spec=$spec"; echo "\$ cargo $plus build --release --target wasm32-unknown-unknown"
    (cd "$d" && cargo $plus build --release --target wasm32-unknown-unknown --target-dir "$tgt" 2>&1)
  } > "$log"; rc=$?
  w=$(ls "$tgt"/wasm32-unknown-unknown/release/*.wasm 2>/dev/null | head -1)
  if [ -z "$w" ]; then
    printf '%-5s %-20s %-14s %-8s %s\n' "$id" "$var" "$tc" "FAILED" "-"
    echo "BUILD FAILED" >> "$log"; continue
  fi
  cp "$w" "$d/out/$var.wasm"
  # hard limit: a module whose panic handler is `loop {}` would otherwise spin forever when an export is called with the wrong signature
  timeout 20 node check/run.mjs "$spec" "$d/out/$var.wasm" >> "$log" 2>&1; crc=$?
  res=PASS; [ $crc -ne 0 ] && res=FAIL
  [ $crc -eq 124 ] && { res=HANG; echo "CHECKER TIMED OUT after 20s: calling an export never returned" >> "$log"; }
  printf '%-5s %-20s %-14s %-8s %s  (%s bytes)\n' "$id" "$var" "$tc" "ok" "$res" "$(wc -c < "$d/out/$var.wasm")"
done
