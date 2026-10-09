# I2 Component Model — Swift: Absent (confirmed)

The Swift Wasm SDK targets wasm32-unknown-wasip1 only (see I1), and neither `swift build` nor `wit-bindgen` (0.62.0 has no Swift
backend: markdown, moonbit, rust, c, cpp, go, csharp, d) produces a component. Writing the canonical ABI by hand over a core module is
possible in principle but is not support for the Component Model, so it was not built or scored.
