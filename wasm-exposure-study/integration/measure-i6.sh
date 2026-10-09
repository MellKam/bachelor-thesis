#!/bin/sh
# I6 toolchain cost (reported, not scored), measured inside the language's container:
#   footprintMB  size of the official toolchain directories needed to build to Wasm (compiler, std library/sysroot/SDK, and the runtime
#                the compiler itself needs: Node for AssemblyScript, Go for TinyGo, a JDK for Kotlin). Stable toolchain only; the shared
#                inspection tools in the base image and the pinned Rust nightly (used only by some exposure probes) are not counted.
#   buildSeconds cold build of the `words` floor build.
# Usage: sh integration/measure-i6.sh <lang>      Writes results/integration/<lang>/I6.json
set -u
lang=$1; d=integration/i5-size/words/$lang/floor; out=results/integration/$lang/I6.json
case $lang in
  rust) dirs="/opt/rust/rustup/toolchains/1.99.0-x86_64-unknown-linux-gnu /opt/rust/cargo";;
  zig) dirs="/opt/zig";;
  c) dirs="/opt/wasi-sdk";;
  moonbit) dirs="/opt/moon";;
  assemblyscript) dirs="/opt/asc /opt/node";;
  tinygo) dirs="/opt/tinygo /opt/go";;
  kotlin) dirs="/opt/kotlinc /opt/jdk";;
  swift) dirs="/opt/swift /root/.swiftpm/swift-sdks";;
esac
mb=$(du -smc $dirs 2>/dev/null | tail -1 | cut -f1)
mkdir -p "results/integration/$lang"
rm -rf "$d/out.wasm" "$d/_build" "$d/target" "$d/lib" "$d/out" /tmp/sb-words-floor /tmp/i5-words-floor
s=$(date +%s.%N)
(cd "$d" && sh -c "$(cat cmd)" >/dev/null 2>&1)
e=$(date +%s.%N)
ok=false; [ -f "$d/out.wasm" ] && ok=true
printf '{"program":"words/floor","footprintMB":%s,"buildSeconds":%s,"ok":%s}\n' "$mb" "$(echo "$e $s" | awk '{printf "%.1f", $1-$2}')" "$ok" > "$out"
chmod -R a+rwX results integration 2>/dev/null
cat "$out"
