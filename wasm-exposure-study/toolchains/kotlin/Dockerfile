# Kotlin/Wasm toolchain for wasm-exposure-study. Starts from the shared base image
# (Debian + Node + WABT + Wasmtime, see toolchains/base/Dockerfile); build it with `make kotlin-image`.
# Pins looked up from the GitHub releases API and the Adoptium API on 2026-10-08.
FROM wasm-exposure-base

RUN apt-get update \
 && apt-get install -y --no-install-recommends unzip \
 && rm -rf /var/lib/apt/lists/*

# Eclipse Temurin JDK 25.0.4.1 (LTS), needed to run the Kotlin compiler (which is a JVM program); sha256 from the Adoptium API
ARG JDK_URL=https://github.com/adoptium/temurin25-binaries/releases/download/jdk-25.0.4.1%2B1/OpenJDK25U-jdk_x64_linux_hotspot_25.0.4.1_1.tar.gz
ARG JDK_SHA256=dbb698396d478e7fa2b1e50f4103324b2a99b90569ee27c33f2261f9215cf41e
# Kotlin 2.4.21, latest stable release (published 2026-10-08, a patch on the 2.4.0 line of 2026-06-03).
# The standalone compiler is used (`kotlinc-wasm`), not the Gradle plugin, so no dependency downloads happen at build time.
ARG KOTLIN_VERSION=2.4.21
# sha256 of kotlin-compiler-2.4.21.zip; matches the digest GitHub publishes for it
ARG KOTLIN_SHA256=7cc140e76daf416a0424a5557f99afd7ca89ebd463ea1101261e3e01c33e75cd

RUN set -eux; cd /tmp; \
    curl -sSfL -o jdk.tar.gz "${JDK_URL}"; \
    echo "${JDK_SHA256}  jdk.tar.gz" | sha256sum -c -; \
    mkdir -p /opt/jdk && tar -xzf jdk.tar.gz -C /opt/jdk --strip-components=1; \
    curl -sSfLO "https://github.com/JetBrains/kotlin/releases/download/v${KOTLIN_VERSION}/kotlin-compiler-${KOTLIN_VERSION}.zip"; \
    echo "${KOTLIN_SHA256}  kotlin-compiler-${KOTLIN_VERSION}.zip" | sha256sum -c -; \
    unzip -q kotlin-compiler-${KOTLIN_VERSION}.zip -d /opt; \
    rm -f /tmp/jdk.tar.gz /tmp/kotlin-compiler-*.zip
ENV JAVA_HOME=/opt/jdk PATH=/opt/jdk/bin:/opt/kotlinc/bin:$PATH
RUN kotlinc-wasm -version 2>&1 | grep -q "kotlinc-wasm ${KOTLIN_VERSION} "

# How to build a module with this toolchain (verified in this image on 2026-10-08): two steps, source -> klib -> wasm.
#   L=/opt/kotlinc/lib/kotlin-stdlib-wasm-js.klib      # or kotlin-stdlib-wasm-wasi.klib with -Xwasm-target=wasm-wasi
#   kotlinc-wasm -Xwasm-target=wasm-js -Xir-module-name=app -ir-output-dir lib -ir-output-name app -libraries $L main.kt
#   kotlinc-wasm -Xwasm-target=wasm-js -Xir-produce-js -Xinclude=lib/app.klib -ir-output-dir out -ir-output-name app -libraries $L
# `@WasmExport` needs `@file:OptIn(kotlin.wasm.ExperimentalWasmInterop::class)`. A one-function module came out at 623,139 bytes.

WORKDIR /study
