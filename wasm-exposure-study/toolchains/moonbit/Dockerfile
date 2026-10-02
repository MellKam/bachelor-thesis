# MoonBit toolchain for wasm-exposure-study. Starts from the shared base image
# (Debian + Node + WABT + Wasmtime, see toolchains/base/Dockerfile); build it with `make moonbit-image`.
#
# CAVEAT: MoonBit publishes only a moving `latest` (and `nightly`) download; every versioned URL
# we tried returns 403 (checked 2026-10-02). So the URL below is NOT stable. We pin by SHA-256
# instead: when MoonBit publishes a new release this build FAILS the checksum, on purpose.
# The tarballs recorded here were the `latest` on 2026-10-02:
#   moon    0.1.20260920 (914d7da 2026-09-20)
#   moonc   v0.10.14+7d59c7ec9 (2026-09-18)
# To reproduce later without upstream, use the archived image (see README, Reproducibility).
FROM wasm-exposure-base

ARG MOONBIT_SHA256=9226694de9ff978db1ecf820b7710c4224e84ec7a76b19a222d96f0cd4e31b6a
ARG MOONBIT_CORE_SHA256=6f18b8fdea18f85e628a75e4a1bd3977c5a5c9c6a836fd8824192b0e6bd91b14

ENV MOON_HOME=/opt/moon
# Mirrors the steps of https://cli.moonbitlang.com/install/unix.sh, with checksum verification added.
RUN set -eux; cd /tmp; mkdir -p "${MOON_HOME}/lib"; \
    curl -sSfL -o moonbit.tar.gz https://cli.moonbitlang.com/binaries/latest/moonbit-linux-x86_64.tar.gz; \
    echo "${MOONBIT_SHA256}  moonbit.tar.gz" | sha256sum -c -; \
    curl -sSfL -o core.tar.gz https://cli.moonbitlang.com/cores/core-latest.tar.gz; \
    echo "${MOONBIT_CORE_SHA256}  core.tar.gz" | sha256sum -c -; \
    tar xf moonbit.tar.gz --directory="${MOON_HOME}"; \
    ln -sfn moon "${MOON_HOME}/bin/moonx"; \
    (cd "${MOON_HOME}/bin" && for i in *; do chmod +x "$i"; done && chmod +x ./internal/tcc); \
    tar xf core.tar.gz --directory="${MOON_HOME}/lib"; \
    PATH="${MOON_HOME}/bin" moon -C "${MOON_HOME}/lib/core" bundle --warn-list -a --all; \
    PATH="${MOON_HOME}/bin" moon -C "${MOON_HOME}/lib/core" bundle --warn-list -a --target wasm-gc --quiet; \
    rm -f /tmp/*.tar.gz
ENV PATH=${MOON_HOME}/bin:$PATH

WORKDIR /study
