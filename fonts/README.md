# Fonts

Fonts that Typst does not bundle, vendored so the PDF builds identically on any machine.
Compile with `--font-path fonts` (the `Makefile` does). If a font is missing Typst falls back
with a warning, so the document still builds, just without the intended look.

| Family | Use | Source | Licence |
|---|---|---|---|
| Inter 4.1 (static TTF: Regular, Italic, Medium, SemiBold, Bold) | headings, captions, table headers, chart labels | https://github.com/rsms/inter/releases/tag/v4.1 (`Inter-4.1.zip`, SHA-256 `9883fdd4a49d4fb66bd8177ba6625ef9a64aa45899767dde3d36aa425756b11e`, files from `extras/ttf/`) | SIL OFL 1.1 (`inter/LICENSE.txt`) |
| Liberation 2.1.5 (Serif, Sans, Mono: Regular, Italic, Bold, Bold Italic) | classic theme: metric-compatible with Times New Roman, Arial and Courier New | https://github.com/liberationfonts/liberation-fonts/releases/tag/2.1.5 (`liberation-fonts-ttf-2.1.5.tar.gz`, linked from the release notes, SHA-256 `7191c669bf38899f73a2094ed00f7b800553364f90e2637010a69c0e268f25d0`) | SIL OFL 1.1 (`liberation/LICENSE`) |


Liberation is used by the default `template.typ`; Inter only by `template-modern.typ`, whose body text (Libertinus Serif) and code (DejaVu Sans Mono) ship with the Typst compiler.
