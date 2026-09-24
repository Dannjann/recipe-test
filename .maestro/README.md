# End-to-end flows

Maestro flows driving the real app on a simulator. Run them against a build from this
session, never whatever happens to be installed:

```bash
xcodebuild build -project RecipeTest.xcodeproj -scheme RecipeTest \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -derivedDataPath build
xcrun simctl install booted build/Build/Products/Debug-iphonesimulator/RecipeTest.app
maestro test .maestro/<flow>.yaml
```

If Maestro reports "iOS driver not ready in time", raise the startup timeout rather than
retrying blind: `MAESTRO_DRIVER_STARTUP_TIMEOUT=300000 maestro test …`.

## Selectors

Flows select on accessibility identifiers, never on visible copy — copy moves, and it moves
differently in every localisation. Identifiers read *screen, element, kind*:

| Identifier | Element |
| --- | --- |
| `home-category-tile-<category id>` | A browse tile on Home |
| `recipe-search-pill-button` | The shared search pill, on Home and on a results list |
| `recipe-list-result-count-label` | "N recipes" in the results toolbar |
| `recipe-list-view-mode-grid-button` / `-list-button` | The results view-mode toggle |
| `recipe-list-card-<recipe id>` | One result, in either presentation |
| `recipe-list-facet-chip-remove-button` | A filter chip |
| `recipe-detail-back-button` | The detail screen's floating back button |

Adding a missing identifier is part of writing a flow, not a prerequisite someone else owes
you. `maestro hierarchy` dumps what is actually on screen when one is uncertain.
