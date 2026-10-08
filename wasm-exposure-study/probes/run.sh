#!/bin/sh
# Builds every probes/<NN>-<slug>/<lang>/<variant>/ (build command in its `cmd` file) and runs the checker on out.wasm.
# Run inside the language's container, from the study root:   sh probes/run.sh <lang> [feature-id ...]      e.g.  sh probes/run.sh rust 01 02
# <lang> is the directory name under each feature (rust, zig, c, moonbit, moonbit-gc, assemblyscript, tinygo, kotlin).
# Per variant: `cmd` (the exact build command, run in that directory; must produce out.wasm), optional `spec` (checker spec,
# default = the feature id; e.g. "02:import"). A failed build is a recorded result, not a runner error.
# Outputs: results/<lang>/<id>.<variant>.txt (build log + checker verdict) and .json (the checker's structured verdict).
set -u
lang=$1; shift; want="$*"
mkdir -p "results/$lang"
# drop stale results of the features about to be re-run, so a renamed or removed variant leaves nothing behind
for f in results/"$lang"/*.txt results/"$lang"/*.json; do
  [ -e "$f" ] || continue; fid=$(basename "$f" | cut -d. -f1)
  if [ -z "$want" ]; then rm -f "$f"; else case " $want " in *" $fid "*) rm -f "$f";; esac; fi
done
printf '%-4s %-22s %-8s %s\n' FEAT VARIANT BUILD CHECK
for d in probes/*/"$lang"/*/; do
  [ -f "$d/cmd" ] || continue
  dir=$(echo "$d" | cut -d/ -f2); id=${dir%%-*}; var=$(basename "$d")
  if [ -n "$want" ]; then case " $want " in *" $id "*) ;; *) continue;; esac; fi
  spec=$id; [ -f "$d/spec" ] && spec=$(cat "$d/spec")
  base="results/$lang/$id.$var"; rm -f "$d/out.wasm" "$base.json"
  { echo "# $dir/$lang/$var spec=$spec"; echo "\$ $(cat "$d/cmd")"; (cd "$d" && sh -c "$(cat cmd)" 2>&1); } > "$base.txt"
  if [ ! -f "$d/out.wasm" ]; then
    printf '{"feature":"%s","variant":"%s","build":"failed"}\n' "$spec" "$var" > "$base.json"
    printf '%-4s %-22s %-8s %s\n' "$id" "$var" FAILED -; echo "BUILD FAILED" >> "$base.txt"; chmod -R a+rwX "$d" 2>/dev/null; continue
  fi
  # hard limit: a module that never returns from an export would otherwise hang the run
  timeout 20 node check/run.mjs "$spec" "$d/out.wasm" --json > "$base.json" 2>> "$base.txt"; crc=$?
  timeout 20 node check/run.mjs "$spec" "$d/out.wasm" >> "$base.txt" 2>&1
  res=PASS; [ $crc -ne 0 ] && res=FAIL
  [ $crc -eq 124 ] && { res=HANG; echo "CHECKER TIMED OUT after 20s" >> "$base.txt"; printf '{"feature":"%s","variant":"%s","build":"ok","pass":false,"hang":true}\n' "$spec" "$var" > "$base.json"; }
  printf '%-4s %-22s %-8s %s  (%s bytes)\n' "$id" "$var" ok "$res" "$(wc -c < "$d/out.wasm")"
done
# the container runs as root: make everything it wrote removable by the host user
chmod -R a+rwX probes results 2>/dev/null
