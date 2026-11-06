# Zig toolchain for wasm-exposure-study. Starts from the shared base image
# (Debian + Node + WABT + Wasmtime, see toolchains/base/Dockerfile); build it with `make zig-image`.
# Pins looked up from https://ziglang.org/download/index.json on 2026-10-02.
FROM wasm-exposure-base

# Zig 0.16.0, latest tagged release (2026-04-13); not the 0.17.0-dev master build
ARG ZIG_VERSION=0.16.0
ARG ZIG_SHA256=70e49664a74374b48b51e6f3fdfbf437f6395d42509050588bd49abe52ba3d00

RUN set -eux; cd /tmp; \
    curl -sSfO "https://ziglang.org/download/${ZIG_VERSION}/zig-x86_64-linux-${ZIG_VERSION}.tar.xz"; \
    echo "${ZIG_SHA256}  zig-x86_64-linux-${ZIG_VERSION}.tar.xz" | sha256sum -c -; \
    mkdir -p /opt/zig; tar -xJf zig-x86_64-linux-${ZIG_VERSION}.tar.xz -C /opt/zig --strip-components=1; \
    rm /tmp/zig-*.tar.xz; \
    test "$(/opt/zig/zig version)" = "${ZIG_VERSION}"
ENV PATH=/opt/zig:$PATH

WORKDIR /study
