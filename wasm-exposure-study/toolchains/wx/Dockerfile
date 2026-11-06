# WX toolchain for wasm-exposure-study. Starts from the shared base image (Debian + Node + WABT + Wasmtime + Binaryen).
# Build it with `make wx-image`. The compiler is the repository's own `wx` binary (release build of crates/wx-cli), copied in by
# the Makefile target; there is no download, so the pin is the git commit recorded in /opt/wx/COMMIT.
FROM wasm-exposure-base
ARG WX_COMMIT=unknown
COPY bin/wx /opt/wx/wx
RUN echo "${WX_COMMIT}" > /opt/wx/COMMIT && chmod +x /opt/wx/wx && /opt/wx/wx --version
ENV PATH=/opt/wx:$PATH
WORKDIR /study
