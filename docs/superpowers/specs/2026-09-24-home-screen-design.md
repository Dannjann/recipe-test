# Home screen

**Date:** 2026-09-24
**Status:** Draft
**Scope:** The Home scene only — no navigation destinations, no search overlay, no list
or detail screens

## Purpose

`RecipeTest` has a complete recipe service layer and a themed app shell, but no feature
UI: `AppCoordinator` roots its `NavigationStack` on a two-line
placeholder. This stage replaces that placeholder with the Bokkie Bites Home screen from
`B App/bokkie-bites-prototype.html`.

Home is the first feature UI in the project, so this document settles more than one
screen. The module layout, the view-model shape, the coordinator's role and the
section-state vocabulary it introduces are the template every later scene copies.

### What Home shows

Four things, in order, on one vertical scroll:

1. The Bokkie Bites logo.
2. A search pill reading "Search recipes or ingredients".
3. **Latest Recipes** — a horizontally scrolling carousel of six recipe cards, each a
   photograph with the title over a bottom gradient.
4. **Explore by Category** — a grid of category tiles, each a square photograph with the
   category name beneath.

### Success criteria

- Home renders from `RecipeServiceProtocol` through the real `APIClient` and the mock
  transport — no second data source, no hardcoded recipe list.
- The layout matches the prototype at the default text size, and stays legible and
  unclipped at accessibility text sizes.
- A failure in one of the two requests degrades only its own section.
- The next stage adds navigation by editing `HomeViewCoordinator` alone. No change to
  `HomeView`, its components, or `HomeViewModel`.
- `HomeViewModel` is unit-tested without a simulator, a network, or `URLSession`.

### Out of scope

No navigation, no `Route` cases, no search overlay, no list screen, no detail screen, no
favourites. The three callbacks Home raises are wired to empty handlers on purpose — see
*Interactions*.

## Architecture

### Module layout

Home is its own module rather than a folder inside `Modules/Recipe/`. `Modules/Recipe/`
owns the recipe *contract* — DTOs, mappers, the API extension, the service. Home is a
*scene* that consumes that contract, and the next scenes to land (list, detail, search)
will consume it too. Filing scenes under the contract that feeds them would put every
screen in the app inside `Modules/Recipe/`.

```
RecipeTest/Modules/Home/UI/
  HomeViewCoordinator.swift
  Home.xcstrings
  Scenes/
    HomeView.swift
    HomeViewModel.swift
    HomeViewModelProtocol.swift
  Components/
    HomeSearchPill.swift
    HomeSectionHeader.swift
    LatestRecipeCard.swift
    RecipeCategoryTile.swift

RecipeTest/Modules/Shared/UI/
  Models/SectionState.swift
  Components/SectionStateView.swift

RecipeTest/Resources/Assets.xcassets/
  BokkieBitesLogo.imageset/
```

`AppCoordinator`'s `placeholder` is deleted and the stack roots on
`HomeViewCoordinator()`.

The Xcode project uses `fileSystemSynchronizedGroups`, so files added on disk join the
target automatically. Nothing in this stage edits `project.pbxproj`.

Names carry no `SU` suffix. That convention exists to tell a SwiftUI scene apart from a
UIKit one in a mixed app; this app is SwiftUI end to end, so the distinction has nothing
to mark.

### Layers

| Layer | Type | Knows about |
|---|---|---|
| Coordinator | `HomeViewCoordinator` | the view model's construction, where callbacks lead |
| Scene | `HomeView` | its view model's outputs, its own callbacks |
| Components | `LatestRecipeCard`, … | one domain value and one callback each |
| View model | `HomeViewModel` | `RecipeServiceProtocol`, domain models |

The coordinator is a `View` (`ViewCoordinator` is the project's alias for it) and is the
only type that knows what a tap leads to. Nothing below it holds a `PathRouter`.

`HomeViewCoordinator` takes **no** `PathRouter` in this stage. `AppCoordinator` already
publishes one into the environment, and the Home coordinator has no destination to push;
storing a router it never reads would be dead weight. It picks one up with
`@Environment(PathRouter.self)` when the first route lands.

For the same reason this stage adds **no** `Route.Home` enum. An empty enum with no
cases documents nothing the file's existing docblock does not already describe.

## State

The two sections load independently. A categories outage leaves the Latest carousel
usable, and each section carries its own retry.

```swift
nonisolated enum SectionState<Value: Equatable>: Equatable {
  case loading
  case loaded(Value)
  case empty
  case failed(String)
}
```

Generic and in `Modules/Shared/UI/Models/` because Home uses it twice immediately and
every list surface in the prototype needs the same four cases. `failed` carries the
message rather than the `Error` so the enum stays `Equatable` and a test can assert on
what the user is shown.

`.empty` is distinct from `.loaded([])`: the mapper can legitimately return zero rows,
and the screen has different copy for it. The view model never produces `.loaded` with
an empty collection.

```swift
@MainActor
@Observable
final class HomeViewModel: HomeViewModelProtocol {
  private(set) var latestRecipes: SectionState<[RecipeSummary]> = .loading
  private(set) var categories: SectionState<[RecipeCategory]> = .loading

  init(recipeService: RecipeServiceProtocol = AppContainer.shared.recipeService)

  func loadContent() async
  func loadLatestRecipes() async
  func loadCategories() async
}
```

Inputs are the three non-private methods; outputs are the two `private(set)`
properties — the MVVM shape the standards require. The service arrives through `init`
behind its protocol, defaulted to the container so the coordinator reads cleanly and a
test can substitute a spy.

`loadContent()` runs both requests concurrently with `async let` and awaits them in
separate `do`/`catch` blocks, so neither failure can cancel the other. It is driven by
`HomeView`'s `.task` and by `.refreshable`. `loadLatestRecipes()` and `loadCategories()`
are what a section's Retry button calls.

### Requests

| Section | Call |
|---|---|
| Latest Recipes | `getRecipes(query: RecipeQuery(sort: .latest), page: Page(index: 1, size: 6))` |
| Explore by Category | `getCategories()` |

Six is the prototype's carousel length. The carousel does not paginate — it is a
fixed-length teaser, and "see all" belongs to the list screen a later stage adds.

Error copy comes from the thrown error's `localizedDescription` — `AppError` and
`RecipeServiceError` both conform to `LocalizedError` — falling back to
`shared.error.somethingWentWrong` when it is empty.

## Layout

Values are read from the prototype's CSS. The colour tokens already installed in
`Colors.xcassets` match the prototype's CSS variables exactly, so no colour is
hardcoded.

| Prototype | Token / implementation |
|---|---|
| `--bg #FFFCF3` | `surfacesBackground` |
| `--card #FFFFFF` | `surfacesBackground2` |
| `--row #F7F6F9` (image placeholder) | `surfacesBackground3` |
| `--text #4A2B1E` | `textPrimary` |
| `--muted #6B6C6D` | `textSecondary` |
| `--white` on photographs | `textWhite` |
| `--shadow` (two layers) | two `.shadow()` modifiers, `textPrimary` at 8% and 12% |

`--shadow` is `0 1px 3px rgba(74,43,30,.08), 0 10px 28px rgba(74,43,30,.12)`. CSS blur
radius is roughly twice SwiftUI's, so it becomes `.shadow(radius: 1.5, y: 1)` at 8% plus
`.shadow(radius: 14, y: 10)` at 12%. It appears on the search pill, the carousel cards
and the category tiles, so it lands in one `View` extension rather than three call
sites.

### The screen

A vertical `ScrollView` on `surfacesBackground`, indicators hidden, 40pt bottom padding.
The 20pt horizontal page margin is applied per element, not to the scroll content as a
whole: the carousel's own `ScrollView` runs edge to edge and carries the 20pt as content
padding, so a card can scroll past the screen edge instead of stopping short of it. `.refreshable` re-runs `loadContent()`. The navigation bar
is hidden: the logo is the screen's title.

| Element | Prototype | Implementation |
|---|---|---|
| Logo | `.logo` 112w, margin 8 / 20 / 20 | `Image(.bokkieBitesLogo)`, `.scaledToFit()`, width 112 |
| Search pill | `.search` h56, r28, centred, 16px | `Button` + `.buttonStyle(.plain)`, `Capsule`, `.bodyRegular` |
| Section header | `.h-sec` Unna 700 26px, margin 30 / 20 / 14 | `HomeSectionHeader`, `.title2` |
| Carousel | `.hscroll` gap 14, pad 20 | horizontal `ScrollView` + `LazyHStack`, `.scrollTargetBehavior(.viewAligned)` |
| Card | `.lcard` 170×240, r28, gradient, 17px bold | `LatestRecipeCard`, `.bodyBold`, `textWhite` |
| Category grid | `.catgrid` 3 cols, gap 18 row / 14 column, pad 20 | `LazyVGrid`, adaptive columns |
| Tile | `.cat` square r24 + 13px bold label, gap 8 | `RecipeCategoryTile`, `.subheadlineSemibold` |

The card's gradient is the prototype's verbatim: black at 80% opacity at the bottom, 30%
at 40% height, clear at 65%.

Photographs load through `CachedAsyncImage` (Kingfisher), placeholdered with
`surfacesBackground3` rather than a `ProgressView` — a spinner inside each of six cards
and six tiles is noise, and the flat fill is what the prototype shows.

### Deviations from the prototype

Two type sizes are pulled onto the theme's ramp rather than minting one-off tokens for
one screen:

| Element | Prototype | Token used |
|---|---|---|
| Section header | 26pt | `.title2` — Unna Bold 24 |
| Category label | 13pt | `.subheadlineSemibold` — Atkinson Bold 14 |

Liquid Glass is deliberately not used on the search pill. The prototype is a flat cream
surface with soft brown shadows, and a glass pill would read as a different product.

### Dynamic Type

The prototype is a fixed 390×844 mock and has no concept of text scaling. Two additions
are required by the team's SwiftUI guidance, which calls out fixed sizes beside text and
line limits at accessibility sizes:

- Card and tile dimensions are `@ScaledMetric`, so a card grows with the title inside
  it instead of clipping it.
- The category grid uses `GridItem(.adaptive(minimum:))` driven by a scaled metric, so
  it degrades from three columns to two to one rather than squashing 14pt labels into a
  107pt tile.

Card titles keep `lineLimit(2)` at default sizes and drop the limit at accessibility
sizes — truncating is the thing a reader raised the text size to avoid.

### Accessibility

- The logo is one `Image` with the label "Bokkie Bites" and the `.isHeader` trait.
- Every tappable thing is a `Button`, never `.onTapGesture` — press state, activation
  behaviour and the button trait come free.
- Each card and tile is a single accessibility element combining its photograph and
  label, so VoiceOver reads "Chicken Adobo, button" rather than an image and a label
  separately.
- The carousel's `ScrollView` carries a label naming the section.

## Section states

`SectionStateView` renders the three non-content cases and is handed the content
builder for the fourth:

```swift
struct SectionStateView<Value: Equatable, Content: View>: View {
  let state: SectionState<Value>
  let minHeight: CGFloat
  let emptyMessage: LocalizedStringResource
  let onRetryTap: VoidResult
  @ViewBuilder let content: (Value) -> Content
}
```

- `.loading` — a centred `ProgressView` at `minHeight`.
- `.empty` — `ContentUnavailableView` with the section's copy.
- `.failed` — `ContentUnavailableView` with the message and a Retry button.
- `.loaded` — `content(value)`.

`minHeight` holds the section's height across all four cases, so the page below does not
jump as each section resolves. It is the carousel's scaled card height for Latest, and
one scaled tile row for the grid. Both sections use it; Home never shows a whole-screen
spinner or a whole-screen error.

## Localization

`Modules/Home/UI/Home.xcstrings`, following the existing `Core.xcstrings` /
`Shared.xcstrings` pattern — keys namespaced by module, generated symbols read as
`String(localized: .Home.homeLatestRecipesTitle)`.

| Key | Value |
|---|---|
| `home.searchPlaceholder` | Search recipes or ingredients |
| `home.latestRecipes.title` | Latest Recipes |
| `home.latestRecipes.empty` | No recipes yet |
| `home.categories.title` | Explore by Category |
| `home.categories.empty` | No categories yet |
| `home.retry` | Try again |
| `home.logo.accessibilityLabel` | Bokkie Bites |

## Assets

`Bokkie-Bites-Logo.svg` (1019×268, two colours — `#4A2B1E` and `#4C80D1`) is imported
into `Assets.xcassets` as `BokkieBitesLogo` with vector representation preserved and
rendered as Original. Not a template image: a template would flatten the blue.

## Interactions

`HomeView` raises three callbacks using the project's `Closures.swift` typealiases:

```swift
let onSearchTap: VoidResult
let onRecipeTap: SingleResult<String>          // recipe id
let onCategoryTap: SingleResult<RecipeCategory>
```

`HomeViewCoordinator` supplies all three from a `// MARK: - Handlers` private extension,
per the standards' rule about returning closures from `handle*` methods rather than
growing inline bodies. Each body is empty in this stage, with a comment naming the
destination the next stage gives it.

This is the seam that satisfies the success criterion above: adding navigation later
touches the coordinator and nothing else.

## Testing

TDD is waived for this stage; tests are written alongside the implementation and land in
the same series of commits.

A `MockRecipeService` spy under `Tests/Mocks/Modules/Recipe/Services/`, recording calls
and returning injected results or errors. `HomeViewModelTests` mirrors the source path
and covers:

- both requests succeed → both sections `.loaded`
- categories fails, recipes succeeds → `categories` is `.failed`, `latestRecipes` is
  `.loaded` (the point of per-section state)
- recipes fails, categories succeeds → the mirror of the above
- either returns zero rows → that section is `.empty`, not `.loaded([])`
- `loadLatestRecipes()` after a failure → the section returns to `.loaded`
- the Latest request carries `sort: .latest` and a page size of 6

Swift Testing (`@Test` / `#expect`), Arrange / Act / Assert separated by blank lines.

Views are covered by `#Preview`s rather than tests: one per component, and Home itself
previewed in each of the four section states through a stub view model.

## Git

Branch `feat/dan/home-screen` off `develop`. Commits follow
`[<feature>] <imperative message>`, ≤72 characters, committed per coherent piece:
shared section state, assets, components, scene, view model, coordinator wiring, tests.
