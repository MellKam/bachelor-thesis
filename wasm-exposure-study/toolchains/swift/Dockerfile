# Swift toolchain for wasm-exposure-study. Starts from the shared base image
# (Debian + Node + WABT + Wasmtime, see toolchains/base/Dockerfile); build it with `make swift-image`.
# Pins looked up from https://www.swift.org/api/v1/install/releases.json on 2026-10-09.
FROM wasm-exposure-base

# Swift's Linux runtime dependencies for Debian 13 (the toolchain itself ships clang, lld, swift-driver, SwiftPM)
RUN apt-get update \
 && apt-get install -y --no-install-recommends binutils git libc6-dev libcurl4 libedit2 libgcc-14-dev libpython3.13 \
    libncurses6 libsqlite3-0 libstdc++-14-dev libxml2 tzdata zlib1g unzip \
 && rm -rf /var/lib/apt/lists/*

# Swift 6.4.0, latest stable release (2026-09-14). Toolchain = swift.org's debian13 tarball; sha256 computed from the download
# (swift.org publishes only a detached .sig for it).
ARG SWIFT_VERSION=6.4.0
ARG SWIFT_SHA256=b623947404e7ea9843cfc315ed8624e85410fae571eb353339780ed222243737
# The official Swift SDK for WebAssembly (wasm32-unknown-wasip1, wasm32-unknown-wasip1-threads, Embedded Swift for
# wasm32-unknown-none-wasm). Its checksum is the one swift.org's releases.json publishes for 6.4.0.
ARG WASM_SDK_SHA256=f07b7be3c586d92d7a07051fc6d303b87ebea67eadc40640ba59d5a8b79aa86d

RUN set -eux; cd /tmp; \
    curl -sSfLO "https://download.swift.org/swift-${SWIFT_VERSION}-release/debian13/swift-${SWIFT_VERSION}-RELEASE/swift-${SWIFT_VERSION}-RELEASE-debian13.tar.gz"; \
    echo "${SWIFT_SHA256}  swift-${SWIFT_VERSION}-RELEASE-debian13.tar.gz" | sha256sum -c -; \
    mkdir -p /opt/swift && tar -xzf swift-${SWIFT_VERSION}-RELEASE-debian13.tar.gz -C /opt/swift --strip-components=1; \
    curl -sSfLO "https://download.swift.org/swift-${SWIFT_VERSION}-release/wasm-sdk/swift-${SWIFT_VERSION}-RELEASE/swift-${SWIFT_VERSION}-RELEASE_wasm.artifactbundle.tar.gz"; \
    rm -f /tmp/swift-*-debian13.tar.gz
ENV PATH=/opt/swift/usr/bin:$PATH
RUN set -eux; cd /tmp; \
    swift sdk install "swift-${SWIFT_VERSION}-RELEASE_wasm.artifactbundle.tar.gz" --checksum "${WASM_SDK_SHA256}"; \
    rm -f /tmp/*.artifactbundle.tar.gz; \
    swift --version; swift sdk list

WORKDIR /study
