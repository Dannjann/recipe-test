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
| `BackButton` | The detail screen's back item. UIKit's own identifier for the system back button, not one this project sets |
| `recipe-search-field-button` | The overlay's search field, which opens the typing screen |
| `recipe-search-field-clear-button` | Clears the text held in that field |
| `recipe-search-close-button` | Dismisses the overlay, discarding the draft |
| `recipe-search-vegetarian-toggle` / `-steps-toggle` | The overlay's two switches |
| `recipe-search-servings-option-<1\|2\|4\|6-plus>` | One servings option |
| `recipe-search-include-field` / `recipe-search-exclude-field` | An ingredient entry field |
| `recipe-search-include-add-button` / `recipe-search-exclude-add-button` | Commits that ingredient |
| `recipe-search-<include\|exclude>-chip-<ingredient>-remove-button` | One ingredient chip |
| `recipe-search-clear-all-button` | Clears the overlay's text and filters |
| `recipe-search-submit-button` | Runs the search and closes the overlay |
| `recipe-search-input-field` | The typing screen's text field |
| `recipe-search-input-back-button` | Returns from the typing screen to the filters |
| `recipe-search-suggestion-<kind>-<value>` | One suggestion row |

Adding a missing identifier is part of writing a flow, not a prerequisite someone else owes
you. `maestro hierarchy` dumps what is actually on screen when one is uncertain.
