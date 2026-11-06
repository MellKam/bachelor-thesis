#!/bin/sh
# Builds every integration/i<n>-<slug>/<lang>/<variant>/ (build command in its `cmd` file) and runs the criterion's checker on out.wasm.
# Run inside the language's container, from the study root:   sh integration/run.sh <lang> [I1 I2 ...]
# Mirrors probes/run.sh. Outputs: results/integration/<lang>/I<n>.<variant>.{txt,json}.
set -u
lang=$1; shift; want="$*"
mkdir -p "results/integration/$lang"
for f in results/integration/"$lang"/*.txt results/integration/"$lang"/*.json; do
  [ -e "$f" ] || continue; cid=$(basename "$f" | cut -d. -f1)
  [ "$cid" = I6 ] && continue # I6 is measured by measure-i6.sh, not by this runner
  if [ -z "$want" ]; then rm -f "$f"; else case " $want " in *" $cid "*) rm -f "$f";; esac; fi
done
printf '%-4s %-26s %-8s %s\n' CRIT VARIANT BUILD CHECK
for d in integration/i[1234]*/"$lang"/*/; do
  [ -f "$d/cmd" ] || continue
  dir=$(echo "$d" | cut -d/ -f2); cid=$(echo "${dir%%-*}" | tr 'i' 'I'); var=$(basename "$d")
  if [ -n "$want" ]; then case " $want " in *" $cid "*) ;; *) continue;; esac; fi
  base="results/integration/$lang/$cid.$var"; rm -f "$d/out.wasm" "$base.json"
  { echo "# $dir/$lang/$var"; echo "\$ $(cat "$d/cmd")"; (cd "$d" && sh -c "$(cat cmd)" 2>&1); } > "$base.txt"
  if [ ! -f "$d/out.wasm" ]; then
    printf '{"criterion":"%s","variant":"%s","build":"failed"}\n' "$cid" "$var" > "$base.json"
    printf '%-4s %-26s %-8s %s\n' "$cid" "$var" FAILED -; echo "BUILD FAILED" >> "$base.txt"; chmod -R a+rwX "$d" 2>/dev/null; continue
  fi
  timeout 120 node check/integration.mjs "$cid" "$d/out.wasm" --json > "$base.json" 2>> "$base.txt"; crc=$?
  timeout 120 node check/integration.mjs "$cid" "$d/out.wasm" >> "$base.txt" 2>&1
  res=PASS; [ $crc -ne 0 ] && res=FAIL
  [ $crc -eq 124 ] && { res=HANG; echo "CHECKER TIMED OUT" >> "$base.txt"; printf '{"criterion":"%s","variant":"%s","build":"ok","pass":false,"hang":true}\n' "$cid" "$var" > "$base.json"; }
  printf '%-4s %-26s %-8s %s  (%s bytes)\n' "$cid" "$var" ok "$res" "$(wc -c < "$d/out.wasm")"
done
# I5 (size) has one more level: integration/i5-size/<program>/<lang>/<variant>/ ; verdicts are I5.<program>.<variant>
for d in integration/i5-size/*/"$lang"/*/; do
  [ -f "$d/cmd" ] || continue
  if [ -n "$want" ]; then case " $want " in *" I5 "*) ;; *) continue;; esac; fi
  prog=$(echo "$d" | cut -d/ -f3); var=$(basename "$d")
  base="results/integration/$lang/I5.$prog.$var"; rm -f "$d/out.wasm" "$base.json"
  { echo "# i5-size/$prog/$lang/$var"; echo "\$ $(cat "$d/cmd")"; (cd "$d" && sh -c "$(cat cmd)" 2>&1); } > "$base.txt"
  if [ ! -f "$d/out.wasm" ]; then
    printf '{"criterion":"I5","program":"%s","variant":"%s","build":"failed"}\n' "$prog" "$var" > "$base.json"
    printf '%-4s %-26s %-8s %s\n' "I5" "$prog/$var" FAILED -; echo "BUILD FAILED" >> "$base.txt"; chmod -R a+rwX "$d" 2>/dev/null; continue
  fi
  timeout 900 node check/integration.mjs "I5:$prog" "$d/out.wasm" --json > "$base.json" 2>> "$base.txt"; crc=$?
  timeout 900 node check/integration.mjs "I5:$prog" "$d/out.wasm" >> "$base.txt" 2>&1
  res=PASS; [ $crc -ne 0 ] && res=FAIL
  printf '%-4s %-26s %-8s %s  (%s bytes)\n' "I5" "$prog/$var" ok "$res" "$(wc -c < "$d/out.wasm")"
done
chmod -R a+rwX integration results 2>/dev/null
