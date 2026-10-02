# AssemblyScript toolchain for wasm-exposure-study. Starts from the shared base image
# (Debian + Node + WABT + Wasmtime, see toolchains/base/Dockerfile); build it with `make assemblyscript-image`.
# Pins looked up from the npm registry on 2026-10-02.
FROM wasm-exposure-base

# assemblyscript 0.28.20 (npm `latest`, published 2026-07-22). package.json pins the exact version and
# package-lock.json pins every transitive dependency by integrity hash (notably binaryen
# 131.0.0-nightly.20260721, which asc uses to emit and optimise the module). `npm ci` fails on any mismatch.
COPY package.json package-lock.json /opt/asc/
RUN cd /opt/asc && npm ci --ignore-scripts
ENV PATH=/opt/asc/node_modules/.bin:$PATH
RUN test "$(asc --version)" = "Version 0.28.20"

WORKDIR /study
