#!/bin/sh
# Runs on the HOST (not in a container): the wx compiler used here is the prebuilt `wx 0.5.0` binary at
# /home/melkam/wx/target/release/wx (built 2026-09-11, after tag v0.5.0, exact commit unknown). The repo HEAD is mid-refactor
# and is deliberately not used. Needs node + wabt on the PATH.   Usage: sh probes/run-wx.sh [probe-id ...]
set -u
mkdir -p results/wx
want="$*"
printf '%-5s %-10s %-8s %s\n' PROBE VARIANT BUILD CHECK
for d in probes/*/wx/*/; do
  [ -f "$d/cmd" ] || continue
  id=$(echo "$d" | cut -d/ -f2); var=$(basename "$d")
  if [ -n "$want" ]; then case " $want " in *" $id "*) ;; *) continue;; esac; fi
  spec=$id; [ -f "$d/spec" ] && spec=$(cat "$d/spec")
  log=results/wx/$id.$var.txt; rm -f "$d/out.wasm"
  { echo "# $id/$var spec=$spec"; echo "\$ $(cat "$d/cmd")"; (cd "$d" && sh -c "$(cat cmd)" 2>&1 | sed 's/\x1b\[[0-9;]*m//g'); } > "$log"
  if [ ! -f "$d/out.wasm" ]; then printf '%-5s %-10s %-8s %s\n' "$id" "$var" FAILED -; echo "BUILD FAILED" >> "$log"; continue; fi
  timeout 20 node check/run.mjs "$spec" "$d/out.wasm" >> "$log" 2>&1; crc=$?
  res=PASS; [ $crc -ne 0 ] && res=FAIL; [ $crc -eq 124 ] && res=HANG
  printf '%-5s %-10s %-8s %s  (%s bytes)\n' "$id" "$var" ok "$res" "$(wc -c < "$d/out.wasm")"
done
