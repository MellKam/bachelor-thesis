# Grain toolchain for wasm-exposure-study. Starts from the shared base image
# (Debian + Node + WABT + Wasmtime, see toolchains/base/Dockerfile); build it with `make grain-image`.
# Pins looked up from the GitHub releases API on 2026-10-02.
FROM wasm-exposure-base

# Grain 0.7.2 (release tag grain-v0.7.2, 2026-02-08), the latest stable release.
# SHA-256 is the digest GitHub publishes for the release asset.
ARG GRAIN_VERSION=0.7.2
ARG GRAIN_SHA256=82658891d33f5431e7bd260f0c00b8e86c43eb9182c5327f41db25d60b54dadd

RUN set -eux; \
    curl -sSfL -o /usr/local/bin/grain \
      "https://github.com/grain-lang/grain/releases/download/grain-v${GRAIN_VERSION}/grain-linux-x64"; \
    echo "${GRAIN_SHA256}  /usr/local/bin/grain" | sha256sum -c -; \
    chmod +x /usr/local/bin/grain; \
    test "$(grain --version)" = "${GRAIN_VERSION}"

WORKDIR /study
