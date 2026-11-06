# TinyGo toolchain for wasm-exposure-study. Starts from the shared base image
# (Debian + Node + WABT + Wasmtime, see toolchains/base/Dockerfile); build it with `make tinygo-image`.
# Pins looked up from the GitHub releases API and go.dev/dl on 2026-10-08.
FROM wasm-exposure-base

# TinyGo 0.42.0, latest release (2026-09-01). The tarball bundles clang/wasm-ld support and wasm-opt, but TinyGo
# also needs a Go toolchain (GOROOT) to supply the standard library. It supports Go 1.25 through 1.27.
ARG TINYGO_VERSION=0.42.0
# sha256 of the release asset; matches the digest GitHub publishes for it
ARG TINYGO_SHA256=b87688fa2e19cee7d813cad7fd7dadb71dff3198e47125aba66ba4af5e490438
# Go 1.27.1, latest stable. The TinyGo 0.42.0 binary itself was built with Go 1.27.0, so this is the same minor version.
ARG GO_VERSION=1.27.1
ARG GO_SHA256=63d339f0da5ab53635a56f2490a7984dfe12dfcff22ad749f63edaf590168445

RUN set -eux; cd /tmp; \
    curl -sSfLO "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz"; \
    echo "${GO_SHA256}  go${GO_VERSION}.linux-amd64.tar.gz" | sha256sum -c -; \
    mkdir -p /opt/go && tar -xzf go${GO_VERSION}.linux-amd64.tar.gz -C /opt/go --strip-components=1; \
    curl -sSfLO "https://github.com/tinygo-org/tinygo/releases/download/v${TINYGO_VERSION}/tinygo${TINYGO_VERSION}.linux-amd64.tar.gz"; \
    echo "${TINYGO_SHA256}  tinygo${TINYGO_VERSION}.linux-amd64.tar.gz" | sha256sum -c -; \
    mkdir -p /opt/tinygo && tar -xzf tinygo${TINYGO_VERSION}.linux-amd64.tar.gz -C /opt/tinygo --strip-components=1; \
    rm -f /tmp/*.tar.gz
# GOFLAGS=-buildvcs=false: no git repository inside the container; GOCACHE/GOPATH kept off the mounted /study tree
ENV GOROOT=/opt/go GOPATH=/opt/gopath GOCACHE=/opt/gocache GOFLAGS=-buildvcs=false \
    PATH=/opt/go/bin:/opt/tinygo/bin:$PATH
RUN tinygo version | grep -q "tinygo version ${TINYGO_VERSION} " \
 && tinygo version | grep -q "using go version go${GO_VERSION} "

WORKDIR /study
