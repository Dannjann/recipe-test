# Recipe detail screen

**Date:** 2026-09-24
**Status:** Draft
**Scope:** The Recipe Details scene, the app's first `Route` case, and the Home wiring
that reaches it — no list screen, no search overlay, no favourites

## Purpose

Home landed with three callbacks wired to empty handlers and a `Route` enum with no
cases. This stage gives the recipe tap somewhere to go: the Bokkie Bites Recipe Details
screen from `B App/bokkie-bites-prototype.html` (`renderDetail`, lines 542–575).

It is also the app's first navigation of any kind, so it settles how a destination is
declared, what a route carries, and which coordinator owns a `navigationDestination`.
Those answers are the template the list and search screens will copy.

### What the screen shows

Top to bottom, on one vertical scroll:

1. A paging photo gallery with page dots, a back button floating over it, and a title bar
   that fades in once the recipe's name scrolls away.
2. A white sheet overlapping the gallery by 32pt, carrying the title and description.
3. Three pastel metric cards — Cooking time, Servings, Difficulty.
4. **Main ingredients** — a horizontal strip of photographed ingredients.
5. **Ingredients** — a tappable checklist that strikes through what has been gathered.
6. **Instructions** — numbered steps.

### Success criteria

- Tapping a card on Home pushes the detail screen and shows the recipe's photograph,
  title and metrics on the first frame, with no spinner in front of them.
- Description, ingredients and steps render from `RecipeServiceProtocol.getRecipe(id:)`
  through the real `APIClient` — no second data source.
- A failed detail fetch leaves the header intact and offers one retry.
- The layout matches the prototype at the default text size, and stays legible and
  unclipped at accessibility text sizes.
- `RecipeDetailViewModel` is unit-tested without a simulator, a network, or `URLSession`.
- The screen is reached, and left, without losing the interactive swipe-back gesture.

### Out of scope

No list screen, no search overlay, no favourites, no sharing, no "add to shopping list".
The checklist is screen-local state that dies with the screen — persistence is a separate
decision with its own storage question, and nothing in the prototype implies it.

## Architecture

### Module layout

`Modules/Recipe/` owns the recipe *contract* — DTOs, mappers, the API extension, the
service. A scene that consumes that contract gets its own module, which is the rule Home
set and the reason Home is not filed under `Modules/Recipe/`. So detail is
`Modules/RecipeDetail/`, named to sit beside the contract rather than inside it.

```
RecipeTest/Modules/RecipeDetail/UI/
  RecipeDetailViewCoordinator.swift
  RecipeDetail.xcstrings
  Scenes/
    RecipeDetailView.swift
    RecipeDetailViewModel.swift
    RecipeDetailViewModelProtocol.swift
  Components/
    RecipeGallery.swift
    RecipeGalleryDots.swift
    RecipeDetailTopBar.swift
    RecipeOverviewSection.swift
    RecipeMetricRow.swift
    RecipeMetricCard.swift
    RecipeDetailSectionHeader.swift
    MainIngredientsStrip.swift
    MainIngredientTile.swift
    IngredientChecklist.swift
    IngredientChecklistRow.swift
    RecipeInstructions.swift
    RecipeInstructionRow.swift
  Extensions/
    RecipeDifficulty+DisplayName.swift

RecipeTest/Mocks/Modules/
  Recipe/Models/DummyRecipe.swift
  RecipeDetail/UI/Scenes/RecipeDetail/MockRecipeDetailViewModel.swift

RecipeTest/Resources/Colors.xcassets/
  surfacesAccentPeach.colorset/
  surfacesAccentMint.colorset/
  surfacesAccentSky.colorset/

Tests/Modules/RecipeDetail/UI/Scenes/RecipeDetailViewModelTests.swift
```

One view per file. Everything under `RecipeTest/Mocks/` is wrapped in `#if DEBUG`, as the
existing dummies are, and so is every `#Preview` — the SwiftUI guidelines require it.

The Xcode project uses `fileSystemSynchronizedGroups`, so files added on disk join the
target automatically. Nothing in this stage edits `project.pbxproj`.

`RecipeDifficulty+DisplayName` stays in this module rather than being hoisted to Shared.
Its second consumer would be the list screen, which does not exist; moving it when that
lands is cheaper than guessing where it belongs now.

### Layers

| Layer | Type | Knows about |
|---|---|---|
| Coordinator | `RecipeDetailViewCoordinator` | the view model's construction, where callbacks lead |
| Scene | `RecipeDetailView` | its view model's outputs, its own callbacks |
| Components | `RecipeMetricCard`, … | one domain value and one callback each |
| View model | `RecipeDetailViewModel` | `RecipeServiceProtocol`, domain models |

Same shape as Home. The coordinator is a `View`; nothing below it holds a `PathRouter`.

## Navigation

This is the first route in the app, so it fills in the pattern `Route.swift` documents
but has never exercised.

```swift
enum Route {
  enum Recipe: Hashable {
    case detail(RecipeSummary)
  }
}
```

`RecipeSummary` gains `Hashable`. Every stored property is already `Hashable`, so this is
a one-word conformance with a synthesised implementation.

`AppCoordinator` owns the `NavigationStack`, so it registers the destination:

```swift
NavigationStack(path: $pathRouter.path) {
  HomeViewCoordinator()
    .navigationDestination(for: Route.Recipe.self) { route in
      switch route {
      case let .detail(summary):
        RecipeDetailViewCoordinator(summary: summary)
      }
    }
}
```

`HomeViewCoordinator` picks up `@Environment(PathRouter.self)` — deferred deliberately
when Home landed, on the grounds that a router it never read would be dead weight — and
its `handleRecipeTap` becomes a push.

### Why the route carries a `RecipeSummary`

Carrying the id alone is the smaller route, and it is what Home's callback already hands
over. It also means the screen is a spinner for as long as the fetch takes, on a tap
where the user has just looked at the photograph and the title on the card they pressed.

Carrying the summary lets the header paint from data already in memory. The photograph,
the name and all three metric values come from `RecipeSummary`; only the description, the
ingredients and the steps need the request. That is the difference between a blank screen
and a screen that is already recognisably the right recipe.

The cost is a change Home's own spec said would not be needed: its success criterion read
*"the next stage adds navigation by editing `HomeViewCoordinator` alone"*. That criterion
is knowingly spent here. `onRecipeTap` widens from `SingleResult<String>` to
`SingleResult<RecipeSummary>`, which changes four files — `HomeView`,
`LatestRecipesSection`, `LatestRecipeCarousel`, `LatestRecipeCard` — by a type annotation
and one `onTap(recipe.id)` → `onTap(recipe)`. Nothing structural moves.

The alternative that preserves the criterion — having the coordinator look the summary up
by id in `viewModel.latestRecipes.value` — was rejected. It trades a type-safe hand-off
for a lookup that can miss, and a miss needs a fallback path that widening never needs.

## State

```swift
@MainActor
protocol RecipeDetailViewModelProtocol: AnyObject {
  var summary: RecipeSummary { get }
  var detail: SectionState<Recipe> { get }
  var checkedIngredientIDs: Set<String> { get }

  var title: String { get }
  var totalTimeMinutes: Int? { get }
  var servings: Int? { get }
  var difficulty: RecipeDifficulty? { get }
  var galleryURLs: [URL] { get }

  func loadDetail() async
  func toggleIngredient(id: String)
}
```

`AnyObject`-constrained, matching `HomeViewModelProtocol`.

`summary` is a `let` on the concrete type: it arrives through `init` from the route and
never changes, so the header has data before the first request is made.

`detail` is `SectionState<Recipe>` — the vocabulary Home introduced, reused rather than
re-invented. It never produces `.empty`: a recipe either loads or fails, and there is no
zero-row case. `SectionStateView` still requires `emptyMessage`, so it is given real copy
for a case that should not arise rather than a force-unwrap or an empty string.

### The merge rule

Two sources overlap. The five getters above resolve them in one place:

```swift
var title: String {
  detail.value?.title ?? summary.title
}
```

The loaded `Recipe` wins because it is the fresher read of the same record; the summary is
the fallback until it arrives. Keeping this in a `// MARK: - Getters` extension on the
view model means each view reads exactly one property, and the rule is asserted in tests
rather than inferred from four call sites.

`galleryURLs` follows the same shape with an extra step: the loaded recipe's `gallery`
when it is non-empty, otherwise the summary's `heroImageURL` as a single-element array,
otherwise empty. In all 36 recipes in `MockData/recipes.json`, `gallery[0]` is identical
to `hero_image_url`, so the swap when the fetch lands adds photographs without changing
the one on screen.

### Loading

`loadDetail()` carries the same two protections `HomeViewModel` arrived at:

- a generation counter, so a second load in flight discards the first's result;
- an `error.isCancellation` guard that restores the previous state, because SwiftUI
  cancels `.task` on disappear and that must neither paint an error nor strand the screen
  on a spinner.

`HomeViewModel` currently holds four private helpers implementing this — `refreshing`,
`state(for:)`, `state(for:keeping:)` and `failureDetail(for:)`. Copying them into a second
view model would fork the behaviour on the next fix. They move to a `SectionState`
extension in `Modules/Shared/UI/Models/` during this stage, and `HomeViewModel` is
changed to call it with no behaviour change. They sit on `SectionState` rather than on a
shared view-model base class because each one is a pure transformation of a state value
into another state value, and none of them reads anything else the view model owns.

`toggleIngredient(id:)` inserts into or removes from `checkedIngredientIDs`, keyed on
`RecipeIngredient.id`. `RecipeMapper` synthesises that as `"\(recipeID)-\(index)"` and
guarantees it is stable across a re-fetch, which is what lets ticks survive a retry.

### Requests

| Trigger | Call |
|---|---|
| `.task` on appear, and Retry | `getRecipe(id: summary.id)` |

No `.refreshable`: the gallery owns the horizontal gesture and the sheet is not a list.
Retry is the one path back from a failure, which is what the prototype's static mock has
no equivalent of and what a real screen needs.

## Layout

Values read from the prototype's CSS. Colour tokens in `Colors.xcassets` already match
the prototype's variables, so no colour is hardcoded.

| Prototype | Token / implementation |
|---|---|
| `--bg #FFFCF3` | `surfacesBackground` |
| `--card #FFFFFF` | `surfacesBackground2` |
| `--row #F7F6F9` | `surfacesBackground3` |
| `--text #4A2B1E` | `textPrimary` |
| `--muted #6B6C6D` | `textSecondary` |
| `--line #E2E4E6` | `bordersDefault` |
| `--shadow` | `.cardShadow()`, the modifier Home installed |

### The screen

A vertical `ScrollView` on `surfacesBackground`, indicators hidden, 40pt bottom padding,
navigation bar hidden. `RecipeDetailTopBar` is an `.overlay(alignment: .top)` on the
scroll view, not a row inside it.

| Element | Prototype | Implementation |
|---|---|---|
| Gallery | `.carousel` h380, `scroll-snap x mandatory` | `ScrollView(.horizontal)` + `LazyHStack` + `.scrollTargetBehavior(.paging)` |
| Page dots | `.dots` 8pt, active 24×8, bottom 48 | `RecipeGalleryDots`, `Capsule` per photo, width animated |
| Back button | `.iconbtn` 56pt circle, top 54 left 20 | `RecipeDetailTopBar`, `surfacesBackground2` + `.cardShadow()` |
| Sticky bar | `.dbar` h104, fades in under 104pt | same bar; background, border and title fade together |
| Sheet | `.dsheet` `margin-top:-32`, radius 32 top | `.offset(y: -32)`, `.clipShape(.rect(topLeading: 32, topTrailing: 32))` |
| Title | `.ov h1` Unna 700 34 | `.title1` — Unna Bold 28 |
| Description | `.ov p` 16 muted | `.bodyRegular`, `textSecondary` |
| Metric row | `.mrow` 3 cols, gap 10 | `RecipeMetricRow` |
| Metric card | `.mitem` r24, minHeight 112, label 13 / value 18 | `RecipeMetricCard`, `.subheadlineRegular` / `.title3` |
| Section header | `.h-sec` Unna 700 26, margin 28 / 20 / 14 | `RecipeDetailSectionHeader`, `.title2` |
| Main ingredient | `.hl` 74pt image r22, label 12 bold, gap 8 | `MainIngredientTile`, `.footnoteBold` |
| Checklist row | `.ck` r20 on `--row`, pad 14/16, gap 14 | `IngredientChecklistRow` on `surfacesBackground3` |
| Checkbox | `.box` 24pt r8, 1.5pt border, fills when on | `IngredientChecklistRow`, `textPrimary` fill |
| Step | `.steps li` gap 16, badge 32pt r16 | `RecipeInstructionRow`, badge on `surfacesAccentSky` |

Photographs load through `CachedAsyncImage`, placeholdered with `surfacesBackground3` —
the same choice Home made, and the same thing the prototype shows.

### The top bar

The prototype has two separate controls: a back button that floats on the photograph, and
a sticky bar carrying its own back button plus the title, which fades in once the name
scrolls past. They never usefully coexist.

They are collapsed into one `RecipeDetailTopBar`. The button is always present; the bar's
background, bottom border and title fade in together, driven by
`onScrollGeometryChange` against the prototype's 104pt threshold. Visually identical, one
component rather than two overlapping ones, and one back affordance for VoiceOver to find
instead of two that do the same thing.

### Metric values

All three values are optional on the domain model. A nil renders an em dash, with an
accessibility label saying the value is unavailable rather than reading the dash.

Cooking time uses `Duration.UnitsFormatStyle` with `allowed: [.hours, .minutes]` and
`.abbreviated` width. That reproduces the prototype's `fmtTime` — `"1 hr 25 min"`,
`"25 min"` — and is localized without a hand-assembled string. The longest value in the
mock data is 305 minutes, which formats as `"5 hr 5 min"`.

Difficulty maps through `RecipeDifficulty+DisplayName` to localized copy. The three cases
are closed and exhaustive, so no default case is needed.

### Deviations from the prototype

Two sizes are pulled onto the theme's ramp rather than minting one-off tokens, the same
call Home made for its 26pt header:

| Element | Prototype | Token used |
|---|---|---|
| Recipe title | 34pt | `.title1` — Unna Bold 28 |
| Metric value | 18pt | `.title3` — Unna Bold 20 |
| Metric label | 13pt | `.subheadlineRegular` — Atkinson Regular 14 |
| Main ingredient label | 12pt | `.footnoteBold` — Atkinson Bold 12 |

### Colours

The three metric cards use pastels with no equivalent in the palette. They are added as
tokens rather than approximated with the semantic shades, which are close in tone but
wrong in meaning — a cooking time is not a warning, and the next reader would have to
discover that the naming is decorative.

| Token | Hex | Used by |
|---|---|---|
| `surfacesAccentPeach` | `#FADED3` | Cooking time card |
| `surfacesAccentMint` | `#DAFAD3` | Servings card |
| `surfacesAccentSky` | `#D3E2FA` | Difficulty card, step number badge |

They join `ThemeColorProtocol` and `DefaultThemeColor` under a new `// Accents` group.
Like the existing brand shades they carry one value in both appearances: the app is
light-only today.

### Dynamic Type

- Gallery height, tile sizes, the checkbox and the step badge are `@ScaledMetric`.
- `RecipeMetricRow` is three columns at default sizes and stacks vertically at
  accessibility sizes. Three 13pt labels and their icons do not fit a 110pt-wide card
  once the text scales.
- The sticky bar's title keeps `lineLimit(1)` and truncates — it mirrors a heading that
  is fully readable a scroll away, so truncating costs nothing.
- Nothing else carries a line limit. The title, the description, ingredient names and
  step text all wrap.

### Accessibility

- Each metric card is one element: *"Cooking time, 25 min"*.
- Checklist rows are `Button`s with `.isToggle` and an accessibility value reflecting
  checked state. Strikethrough alone conveys nothing to VoiceOver.
- Instruction rows read *"Step 3 of 7, …"*; the badge itself is not a separate element.
- The gallery is one element labelled with the recipe title, with an *"n of m"* value as
  the user pages. The dots are decorative and hidden.
- Every tappable thing is a `Button`, never `.onTapGesture`.

### Swipe-back

The screen hides the navigation bar, as Home does. Under UIKit that historically disabled
the interactive pop gesture, and whether `NavigationStack` on iOS 26.3 preserves it needs
to be confirmed on a simulator, not assumed — it is listed as an explicit verification
step in the implementation plan, not left to code review.

If the gesture is lost, the fallback is to keep the navigation bar in place with its
background and its back button hidden, and draw `RecipeDetailTopBar` over it. The
SwiftUI guidelines forbid `UIViewRepresentable` bridging, so a UIKit gesture-recogniser
shim is not an option and is not the fallback.

## Localization

`Modules/RecipeDetail/UI/RecipeDetail.xcstrings`, keys namespaced by module as
`Core.xcstrings`, `Shared.xcstrings` and `Home.xcstrings` are.

| Key | Value |
|---|---|
| `recipeDetail.cookingTime.title` | Cooking time |
| `recipeDetail.servings.title` | Servings |
| `recipeDetail.difficulty.title` | Difficulty |
| `recipeDetail.difficulty.easy` | Easy |
| `recipeDetail.difficulty.medium` | Medium |
| `recipeDetail.difficulty.hard` | Hard |
| `recipeDetail.mainIngredients.title` | Main ingredients |
| `recipeDetail.ingredients.title` | Ingredients |
| `recipeDetail.instructions.title` | Instructions |
| `recipeDetail.detail.empty` | This recipe has no details yet |
| `recipeDetail.back.accessibilityLabel` | Back |
| `recipeDetail.metric.unavailable` | Not available |
| `recipeDetail.gallery.photoPosition` | Photo %1$lld of %2$lld |
| `recipeDetail.ingredient.gathered` | Gathered |
| `recipeDetail.ingredient.notGathered` | Not gathered |
| `recipeDetail.step.position` | Step %1$lld of %2$lld |

## Testing

TDD is waived for this stage, as it was for Home; tests are written alongside the
implementation and land in the same series of commits.

`RecipeDetailViewModelTests` mirrors the source path, uses Swift Testing (`@Test` /
`#expect`) and separates Arrange / Act / Assert with blank lines. It drives the existing
`MockRecipeService` spy and covers:

- `loadDetail()` succeeds → `detail` is `.loaded`, and the service was asked for the
  summary's id
- `loadDetail()` fails → `detail` is `.failed`, and the four header getters still return
  the summary's values
- after a successful load, the header getters return the `Recipe`'s values rather than
  the summary's
- `galleryURLs` is the summary's hero before the load and the recipe's gallery after it
- a cancellation error leaves the previous state intact
- a second `loadDetail()` while one is in flight discards the first's result
- `toggleIngredient` adds an id, removes it on a second call, and leaves others untouched
- ticked ids survive a re-fetch, since ingredient identity is stable

`DummyRecipe` and its ingredients join `RecipeTest/Mocks/` alongside `DummyRecipeSummary`,
under `#if DEBUG`, so previews and tests share one fixture.

Views are covered by `#Preview`s rather than tests: one per component, and the scene
previewed loading, loaded, failed, without photographs, and at AX3 — through
`MockRecipeDetailViewModel`, matching Home.

Home's existing tests are unaffected by the helper lift; if any of them change, the lift
was not behaviour-preserving and the change is the bug.

## Git

Branch `feat/dan/recipe-detail`, cut from `develop` — Home merged at `791d35b`.

Commits follow `[detail] <imperative message>`, 72 characters or fewer, no trailing
period, and no `Co-Authored-By` trailer. Committed per coherent piece: accent colour
tokens, the shared section-state helpers, the route and Home's wiring, the view model,
the components, the scene, the coordinator, the tests.
