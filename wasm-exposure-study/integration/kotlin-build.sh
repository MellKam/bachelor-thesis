#!/bin/sh
# Builds ./main.kt with kotlinc-wasm into ./out.wasm. Usage (from a variant directory): sh ../../../kotlin-build.sh <wasm-wasi|wasm-js> [extra kotlinc-wasm flags]
# Two steps, as the compiler requires: sources -> klib, then klib -> wasm. Not tuned: default optimisation, no -Xwasm-* options unless a variant passes some.
set -e
target=$1; shift
case "$target" in wasm-wasi) std=kotlin-stdlib-wasm-wasi.klib;; wasm-js) std=kotlin-stdlib-wasm-js.klib;; *) echo "unknown target $target"; exit 2;; esac
L=/opt/kotlinc/lib/$std
rm -rf lib out
kotlinc-wasm -Xwasm-target=$target -Xir-module-name=app -ir-output-dir lib -ir-output-name app -libraries "$L" "$@" main.kt
kotlinc-wasm -Xwasm-target=$target -Xir-produce-js -Xinclude=lib/app.klib -ir-output-dir out -ir-output-name app -libraries "$L" "$@"
cp out/app.wasm out.wasm
