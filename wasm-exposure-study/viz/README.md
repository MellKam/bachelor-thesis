# Rating visualisation

A single-page D3 (v7) view of `results/rating/rating.json`. No build step beyond inlining the data.

```
node viz/build-data.mjs      # rating.json -> viz/data.js (re-run after `make rating`)
open viz/index.html          # works from file://; D3 is loaded from jsDelivr
```

| File | Role |
|---|---|
| `index.html` | page shell, theme tokens (light/dark/auto), section scaffolding |
| `app.js` | all chart code; every number and every numeric headline is computed from the data |
| `data.js` | generated: `window.RATING = {...}` |
| `build-data.mjs` | generator for `data.js` |

Sections: coverage counts (no weights) → score and rank stability → where the points are lost → trade-offs → spec versions → feature × language matrix → obstacles → method caveats.

Every chart has a "View as table" twin, tooltips work on keyboard focus, the matrix supports arrow-key navigation, and the "Highlight" chips emphasise one language across all charts.
