# Recipe list screen

**Date:** 2026-09-23
**Status:** Draft — awaiting review
**Scope:** The recipe list screen and the navigation scaffolding it needs. No search behaviour, no filter page, no real detail screen.
**Builds on:** `docs/superpowers/specs/2026-09-23-recipe-service-layer-design.md`

## Purpose

The service layer shipped in `f4966af`. `RecipeService.getRecipes(page:)` already returns a
paginated `RecipeListPage` of `RecipeSummary` with the pagination meta attached, and
`MockAPIRouter` already slices `Resources/MockData/recipes.json` (36 rows) into real pages at
request time. Nothing consumes any of it: `AppCoordinator` still roots the `NavigationStack`
on a hard-coded placeholder, and `Modules/Recipe/` has no `UI/` folder at all.

This is the app's first screen. It adds the layer above the service:

```
RecipeListView -> RecipeListViewModel -> RecipeService -> RecipeAPIProtocol -> APIClient -> MockURLProtocol
```

It is also the template the next feature screen is copied from, which is why the view model
contract, the state modelling and the mock/preview arrangement are specified here in more
detail than one screen alone would justify.

### Success criteria

- A user sees recipes — hero image, title, short description — fetched through the real
  service and the real client.
- The same screen renders as a single-column list or a two-column grid, toggled by the user,
  without losing scroll position.
- Pulling down refreshes the list without blanking it.
- Reaching the end of the content loads the next page, and stops cleanly at the last page
  rather than requesting empty pages forever.
- A search bar sits above the list in both layouts.
- Every state the screen can occupy — loading, loaded, empty, failed, loading-next-page,
  next-page-failed — is reachable in a SwiftUI preview without a service or a network.
- The view model's behaviour is unit-tested without a simulator.

### Out of scope

- **Search behaviour.** The bar is presentational this stage. Tapping it will eventually push
  a dedicated filter page; that page, its route and its query plumbing are a later stage, and
  nothing here presumes their shape.
- **The real detail screen.** A placeholder stands in, so the routing seam is proved end to
  end. `RecipeService.getRecipe(id:)` stays unused.
- **Persisting the layout choice.** Session-only, by decision — see below.
- **Snapshot or UI tests.** The project has no snapshot infrastructure, and the views are
  kept thin enough that the view model carries the behaviour worth pinning.

## Decisions

Each of these was taken deliberately; the reasoning matters more than the choice, because
the next screen will inherit it.

### One `LazyVGrid` whose column count is the toggle

List mode is a `LazyVGrid` with one column; grid mode is the same grid with two. `RecipeCard`
switches its own internal axis off the same value.

The alternative — `List` for list mode, `LazyVGrid` for grid mode — uses the container each
layout was designed for, and gets separators and swipe actions for free. It was rejected
because toggling then swaps one container for a structurally different one: scroll position
is lost on every toggle, and pull-to-refresh, the pagination trigger, the empty state and the
error state each need two implementations for a screen whose two modes must behave
identically. Neither separators nor swipe actions are in scope.

A third option — two sibling layout views over one view model — carries the same duplication
plus another file.

### The grid and the pagination footer live inside one `ScrollView`

`LazyVGrid` is not a scrolling container and has no viewport of its own. Outside one it has
no visible rect to reason about and materialises every child eagerly, which removes the
laziness the feature is named for.

The footer is inside the *same* scroll container so that "the footer appeared" means "the user
reached the end of the content". Pinned outside it instead, it would be on screen from launch,
its `onAppear` would fire on the first frame, and page 2 would load before the user scrolled
anything.

It sits outside the `LazyVGrid` but inside the `ScrollView`, so that it spans both columns
rather than occupying one grid cell.

### The view model is protocol-backed

`RecipeListViewModelProtocol`, per the team standard that every class gets a protocol. This
was initially specified as a concrete type on the belief that `@Observable` tracking does not
survive an existential. That belief is wrong and was checked:

- Reading a property through `any RecipeListViewModelProtocol` **does** track. The protocol
  witness dispatches to the macro-generated accessor, which calls `access(keyPath:)` against
  the current tracking context exactly as a concrete call would. A `withObservationTracking`
  probe through an existential fires its `onChange`.
- The one thing that genuinely does not compile is `@Bindable` on an existential:
  `'init(wrappedValue:)' is unavailable: The wrapped value must be an object that conforms to
  Observable`. Existentials do not self-conform to `Observable`.

That constraint costs nothing, because the standard already rules bindings out: view model
inputs are non-private methods, outputs are gettable properties or `on*` closures. So
`RecipeLayoutToggle` takes a value and an `onSelect` closure rather than a `Binding`. Should
the later search stage need a bound field, a manual `Binding(get:set:)` over the protocol
works; only the `@Bindable` sugar is unavailable.

### The layout choice is session-only

It resets to `.list` on every launch. Persisting it would mean a protocol-backed store
injected into the view model so the view model stays testable — a type, a dependency and a
test for a preference on a demo app's first screen.

### The route carries the whole `RecipeSummary`

`Route.Recipe.detail(RecipeSummary)` rather than `detail(id: String)`. The real detail stage
calls `getRecipe(id:)`, which takes time; carrying the summary lets that screen paint its
title and hero image immediately instead of opening blank. `RecipeSummary` gains `Hashable`,
which every one of its stored properties already satisfies.

### The mock view model lives in the app target

`MockRecipeListViewModel` is in `RecipeTest/`, not `Tests/`, guarded by `#if DEBUG`. This
mirrors the precedent already in the codebase — `MockURLProtocol`, `MockAPIRouter` and
`MockEndpoint` are all app-target types under `Modules/Core/Clients/API/Mock/`.

Previews need a double and cannot import the test target, which is what decides the placement.
A side benefit rather than a justification: the `Tests` target can reach it through
`@testable import RecipeTest` if a view-level test ever wants it, so a second near-identical
double never has to be written. `#if DEBUG` keeps it out of a release build.

## Architecture

| Layer | Type | Knows about |
|---|---|---|
| Coordinator | `RecipeViewCoordinator` | routes, the view model's construction, `PathRouter` |
| Screen | `RecipeListView` | `any RecipeListViewModelProtocol`, its own components |
| View model | `RecipeListViewModel` | `RecipeServiceProtocol`, domain models, load state |
| Components | `RecipeCard`, `RecipeSearchBar`, `RecipeLayoutToggle` | one `RecipeSummary` or one value each |

Dependencies point downward only. The view model never sees a view; the components never see
the view model.

```
AppCoordinator (owns PathRouter)
 └─ RecipeViewCoordinator
      init(service: RecipeServiceProtocol = AppContainer.shared.recipeService)
      @State viewModel: RecipeListViewModel
      ├─ RecipeListView(viewModel:, onRecipeTap:)
      └─ .navigationDestination(for: Route.Recipe.self)
           └─ RecipeDetailPlaceholderView(recipe:)
```

The coordinator resolves the service through a defaulted initializer parameter — the pattern
`AppContainer` documents for itself — so a test or a preview substitutes a mock without
touching the container.

### File layout

**Created under `RecipeTest/Modules/Recipe/UI/`:**

| File | Responsibility |
|---|---|
| `Recipe.xcstrings` | This module's string catalog |
| `RecipeViewCoordinator.swift` | Roots the flow, owns the view model, handles `Route.Recipe` |
| `List/RecipeListView.swift` | The screen: search bar, state switch, scroller |
| `List/RecipeListLayout.swift` | `enum { list, grid }` and its `columns: [GridItem]` |
| `List/RecipeListLoadState.swift` | `enum { idle, loading, loaded, failed(String) }` |
| `List/RecipeListViewModelProtocol.swift` | The contract the view depends on |
| `List/RecipeListViewModel.swift` | Paging, refresh, error handling |
| `List/Mock/MockRecipeListViewModel.swift` | `#if DEBUG` double for previews and tests |
| `List/Mock/DummyRecipeSummary.swift` | `#if DEBUG` sample rows for previews |
| `Detail/RecipeDetailPlaceholderView.swift` | Stands in until the detail stage |
| `Components/RecipeCard.swift` | One row or one cell, axis switched by layout |
| `Components/RecipeSearchBar.swift` | Presentational; `onTap` declared, unwired |
| `Components/RecipeLayoutToggle.swift` | Value plus `onSelect`, no binding |

**Modified:**

| File | Change |
|---|---|
| `Navigation/Route.swift` | Add `enum Recipe: Hashable { case detail(RecipeSummary) }` |
| `Modules/Recipe/Models/Domain/RecipeSummary.swift` | Add `Hashable` conformance |
| `App/AppCoordinator.swift` | Replace `placeholder` with `RecipeViewCoordinator()` |

`RecipeListLayout` is a view concern and lives under `UI/`, not in `Models/Domain/`. Nothing
in the domain or service layer has any reason to know the screen has two modes.

## The view model

```swift
@MainActor
protocol RecipeListViewModelProtocol: Observable, AnyObject {
  // Outputs
  var recipes: [RecipeSummary] { get }
  var layout: RecipeListLayout { get }
  var loadState: RecipeListLoadState { get }
  var isLoadingNextPage: Bool { get }
  var nextPageError: String? { get }
  var hasLoadedAllData: Bool { get }

  // Inputs
  func loadFirstPage() async
  func refresh() async
  func loadNextPage() async
  func select(layout: RecipeListLayout)
}
```

### Load state

```swift
nonisolated enum RecipeListLoadState: Equatable {
  case idle                 // nothing attempted yet
  case loading              // first page in flight, screen is empty
  case loaded               // rows are the source of truth
  case failed(String)       // first page failed, screen is empty, retry offered
}
```

Empty is deliberately not its own case. `.loaded` with `recipes.isEmpty` drives the empty
state, which keeps one source of truth for what is on screen and makes it impossible for
`loadState` and `recipes` to disagree.

### Paging

`private var nextPage: Page = .init(index: 1, size: 10)`. Ten rows against the 36-row fixture
gives four real pages, and matches `MockAPIRouter`'s own default so a missing `per_page` and a
present one behave alike.

`hasLoadedAllData` is taken from the page the service just returned —
`RecipeListPage.meta.hasLoadedAllData`, which is `total <= perPage || currentPage >= lastPage`.
It is already correct for a page past the end, which is what stops a pager from requesting
empty pages forever.

`loadNextPage()` returns immediately unless all of: `loadState == .loaded`,
`!hasLoadedAllData`, `!isLoadingNextPage`.

### The failure modes this design exists to prevent

1. **A refresh that blanks the screen.** `refresh()` resets `nextPage` to index 1 but leaves
   `recipes` in place, replacing them only once the new first page arrives. Clearing on start
   would make every pull-to-refresh flash an empty list, and a failed refresh would destroy
   content the user still had.

2. **A refresh racing an in-flight next page.** The user pulls down while page 3 is loading;
   page 3 returns afterwards and is appended onto a freshly reset list, producing duplicated
   and out-of-order rows. A generation counter guards this: `refresh()` increments it, and any
   in-flight result carrying a stale generation is discarded rather than applied.

3. **Duplicate ids breaking `ForEach` identity.** Appends filter out ids already present. The
   mock cannot produce a duplicate, but a `ForEach` over a duplicated `Identifiable` id
   misbehaves visibly, and the guard is three lines.

4. **A failed next page taking over the screen.** A failed page 3 leaves `loadState == .loaded`
   and the existing rows untouched, setting `nextPageError` so the footer offers a retry. Only
   a failed *first* page occupies the screen.

Errors reach the view as `String`, not as `Error`. `RecipeService` has already reported to
monitoring, and both `AppError` and `RecipeServiceError` are `LocalizedError`, so the view
model stores `error.localizedDescription` and the view has no error handling of its own.

## The screen

```
VStack(spacing: 0) {
  RecipeSearchBar()                     // inert; pinned, does not scroll away
  content                               // switches on loadState
}
.toolbar { RecipeLayoutToggle(layout:, onSelect:) }
.task { await viewModel.loadFirstPage() }
```

`.task` runs again whenever the view reappears — returning from the detail screen, for
instance. `loadFirstPage()` therefore returns immediately unless `loadState` is `.idle` or
`.failed`, so coming back from a push neither refetches nor resets the user's scroll position.
Reloading on demand is what `refresh()` is for.

`content` resolves to one of four things:

| `loadState` | Shown |
|---|---|
| `.idle`, `.loading` | Centred `ProgressView` |
| `.failed(message)` | Message and a Retry that calls `loadFirstPage()` |
| `.loaded`, no rows | Empty state |
| `.loaded`, rows | The scroller below |

```
ScrollView {
  LazyVGrid(columns: viewModel.layout.columns, spacing: 12) {
    ForEach(viewModel.recipes) { RecipeCard(recipe:, layout:) }
  }
  .animation(.snappy, value: viewModel.layout)

  footer     // spinner, retry, or nothing once hasLoadedAllData
}
.refreshable { await viewModel.refresh() }
```

The footer has exactly three renderings, in this precedence:

| Condition | Footer |
|---|---|
| `hasLoadedAllData` | Nothing — the trigger is removed along with the indicator |
| `nextPageError != nil` | Message and a Retry calling `loadNextPage()` |
| otherwise | A `ProgressView`, whose `onAppear` calls `loadNextPage()` |

The third row is both the indicator and the trigger. There is no separate invisible sentinel:
the thing that says "loading more" is the same thing whose appearance means "the user got
here".

### Components

**`RecipeCard(recipe:layout:)`** — `HStack` for list (96x96 leading image, title and
description trailing), `VStack` for grid (4:3 image on top). Images go through the existing
`CachedAsyncImage`, which is Kingfisher-backed and already has the mock transport installed for
demo builds. Both modes use fixed image frames so nothing reflows as images resolve. Title and
description are line-limited so a long row cannot break the grid's rhythm.

**`RecipeSearchBar(onTap:)`** — a themed bar with a magnifying-glass icon and placeholder
copy. `onTap` defaults to `DefaultClosure.voidResult()`, so this stage constructs it as
`RecipeSearchBar()` and the bar is additionally rendered non-interactive
(`.allowsHitTesting(false)`), leaving nothing that can appear tappable but do nothing. The
search stage drops the hit-testing guard and passes a closure; no other change to this screen.
It is not a `TextField` and holds no query state, because the destination is a filter page
rather than inline filtering.

**`RecipeLayoutToggle(layout:onSelect:)`** — two mutually exclusive icon buttons in the
toolbar's trailing position.

### Theming and copy

Colours and type come from the theme only — `.themeTextStyle(.bodySemibold)` for titles,
`.subheadlineRegular` for descriptions, `.themeColor(.textPrimary)` and `.textSecondary`,
cards on `.surfacesBackground2` over a `.surfacesBackground` screen. No literal colours, no
system fonts.

All user-facing copy goes into `Recipe.xcstrings` **before** any view references it: the
project's custom SwiftLint rule rejects string literals inside `String(localized:)`. Keys
needed: screen title, search placeholder, empty title and message, error retry, both toggle
labels, and the placeholder detail copy.

### Accessibility

Each card is a single combined accessibility element rather than three separately focusable
children. Accessibility identifiers go on the cards, the toggle and the search bar now, so the
later Maestro stage has something to target instead of retrofitting them across the screen.

## Testing

`MockRecipeService` is added under `Tests/Mocks/Modules/Recipe/Services/`, conforming to
`RecipeServiceProtocol`, with per-page canned results and injectable failures. The view model
tests exercise the real `RecipeListViewModel` against it; `MockRecipeListViewModel` is a
preview double and is not used by this suite.

A `@MainActor` Swift Testing suite over `RecipeListViewModel`:

| Case | Asserts |
|---|---|
| First page succeeds | rows populated, `loadState == .loaded` |
| First page is empty | `.loaded` with no rows — the empty state, not an error |
| First page fails | `.failed`, rows still empty |
| Next page appends | page 2 rows follow page 1's, order preserved |
| Last page reached | `hasLoadedAllData`, and `loadNextPage()` makes no further call |
| Next page fails | rows preserved, `loadState` still `.loaded`, `nextPageError` set |
| Refresh replaces | page 1 refetched, rows replaced not appended |
| Refresh does not clear | rows remain non-empty throughout a refresh |
| Stale append discarded | a next-page result returning after a refresh is dropped |
| Duplicate ids filtered | a repeated id appears once |
| Layout selection | `select(layout:)` updates `layout` |

Previews cover the states instead: loaded list, loaded grid, empty, error, loading, and
last-page-reached, each constructed from `MockRecipeListViewModel`.

## Constraints

- **Branch:** `feat/recipe-list`. Never commit on `develop` or `main`.
- **Swift 6**, app target builds with `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`. Types that
  must be off the main actor carry an explicit `nonisolated`; the view model and views are
  main-actor by default and need no annotation.
- **2-space indent**, 120-char warning / 180 error, `// MARK:` via SwiftFormat rather than by
  hand. Run `swiftformat RecipeTest Tests UITests` then `--lint` before every commit.
- **Never edit `project.pbxproj`.** `RecipeTest`, `Tests` and `UITests` are
  `PBXFileSystemSynchronizedRootGroup`s; files dropped inside them join the target.
- **Previews are required** on every new SwiftUI view, per the team standard.
