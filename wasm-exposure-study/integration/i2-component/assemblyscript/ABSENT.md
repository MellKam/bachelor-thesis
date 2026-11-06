# I2 Component Model — AssemblyScript: Absent (confirmed)

No component target and no WIT generator. `hand-abi-wasm-tools/` shows a hand-written canonical ABI also works (1174 bytes), but export
names are identifiers in AssemblyScript, so the required name `study:words/words@0.1.0#analyse` cannot even be written in source: `cmd`
renames the export in the text form of the module with `sed`. Evidence only, not scored.
