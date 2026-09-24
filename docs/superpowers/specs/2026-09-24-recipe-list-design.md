# Recipe list screen

**Date:** 2026-09-24
**Status:** Draft
**Scope:** The results list reached by tapping a category on Home — the screen, its route,
its paging, and the view-model-per-subview pattern it trials. No search overlay, no filter
sheet.

## Purpose

Home has shipped with `handleCategoryTap` wired to an empty handler. This stage gives the
category tap somewhere to go: the Bokkie Bites list screen from
`B App/bokkie-bites-prototype.html` (`renderList` / `refreshList`, lines 466–540).

The screen is built once and reused three ways. A category tap opens it today; the search
overlay and the filter sheet will open the same screen with a different `RecipeQuery` and a
different title, adding no route case and no second view model. The screen never learns why
it was opened.

It is also the app's first paginated surface. `RecipeServiceProtocol.getRecipes(query:page:)`
and `RecipeListPage.hasLoadedAllData` have existed since the service layer landed with no
caller that pages; this screen is that caller, and settles how a pager is shaped.

Finally, it trials a stricter presentation rule (see *The view-model rule* below). If the
rule holds up here, Home and Recipe Details are converted to it in a later session.

### What the screen shows

Top to bottom:

1. A system navigation bar carrying the list's title, large and collapsing to inline on
   scroll, with the system back button.
2. The shared search pill, its placeholder scoped to the list ("Search Desserts"). Inert at
   this stage.
3. A row of active filter chips, each removable, with "Clear all" once more than one is
   present. Hidden when the request carries no facets.
4. A toolbar: the result count on the left, a grid/list segmented control on the right.
5. The results — a two-column grid of cards, or a single column of full-width rows.
6. Below the last page, a paging spinner or a paging retry, as required.

### Success criteria

- Tapping a category on Home pushes the list, and the list shows only that category's
  recipes, fetched through `RecipeServiceProtocol` — no second data source and no client-side
  filtering.
- The count reads the total the server reported, not the number of rows fetched so far.
- Scrolling to the bottom loads the next page and appends it; the pager stops asking once
  `hasLoadedAllData` is true, and never has two pages in flight at once.
- A failed *next* page leaves every row already on screen untouched and offers one retry.
- A failed *first* page shows the error treatment and offers one retry.
- Leaving the screen mid-request paints neither an error nor a stranded spinner.
- Removing a facet chip re-fetches from page 1 with that facet dropped.
- Switching between grid and list keeps the scroll position and animates rather than jumps.
- The screen is reached and left with the interactive swipe-back gesture intact.
- Every value any view renders comes from a view model behind a protocol; no view formats a
  duration, joins two fields, or pluralises a noun.
- `RecipeListViewModel`, `RecipeCardViewModel`, `RecipeFacetChipViewModel` and the
  `RecipeQuery` facet helpers are unit-tested without a simulator, a network, or `URLSession`.
- The layout matches the prototype at the default text size, and stays legible and unclipped
  at accessibility text sizes.

### Out of scope

No search overlay and no filter sheet — the search pill's tap is a `// TODO` handler, exactly
as Home's is today. No cuisine lists (the prototype's `kind: 'cui'`), no "All recipes" entry
point, no favourites, no sort control, no pull-to-refresh. The grid/list choice is screen-local
and dies with the screen; remembering it across launches is a separate decision with its own
storage question.

## The view-model rule

This screen trials a rule the rest of the app does not yet follow:

> Every value a view renders is exposed by a view model behind a protocol. A view may lay out,
> style and animate. It may not derive.

Concretely, `RecipeRow` does not build `"\(cuisine) · \(category)"`, and no view turns `90`
into `"1 hr 30 min"` or `12` into `"12 recipes"`. Those are properties on a view model, which
means they are testable with `#expect` instead of by eye.

Repeated, data-driven elements — a card, a chip — get their **own** view model and protocol,
created once per fetch by the screen's view model. Chrome that exists once on the screen — the
toolbar, the empty state, the footer — reads from the screen's view model rather than inventing
another one.

Two consequences worth stating, because they are the point of the trial:

- `SectionState` on this screen carries `[RecipeCardViewModel]`, not `[RecipeSummary]`. Domain-to-presentation mapping happens once per page inside the view
  model, not on every `body` evaluation — which is what keeps a `LazyVGrid` of several hundred
  cards cheap.
- A card view model is a **`nonisolated struct`**, not an `@Observable` class. `SectionState`
  constrains its value to `Equatable`, and a struct over a `Hashable` `RecipeSummary` gets that
  synthesised — which also gives SwiftUI a correct diff and allocates nothing per row. There is
  no mutable state here to observe; when a card gains a favourite toggle, that is when it earns
  the macro and the reference type.

## Architecture

### Module layout

`Modules/RecipeList/`, beside the `Modules/Recipe/` contract rather than inside it — the rule
Home set and Recipe Details followed.

```
RecipeTest/Modules/RecipeList/
  Models/
    RecipeListRequest.swift
    RecipeListViewMode.swift
  UI/
    RecipeListViewCoordinator.swift
    RecipeList.xcstrings
    Scenes/
      RecipeListView.swift
      RecipeListViewModel.swift
      RecipeListViewModelProtocol.swift
    Components/
      RecipeListResults.swift
      RecipeListToolbar.swift
      RecipeListViewModeToggle.swift
      RecipeListEmptyState.swift
      RecipeListFooter.swift
      RecipeCard.swift
      RecipeRow.swift
      RecipeCardMetadata.swift
      RecipeCardViewModel.swift
      RecipeCardViewModelProtocol.swift
      RecipeFacetChipRow.swift
      RecipeFacetChip.swift
      RecipeFacetChipViewModel.swift
      RecipeFacetChipViewModelProtocol.swift
```

Two types land in `Modules/Recipe/Models/Domain/` instead, because they are query logic rather
than screen logic and earn their own tests:

```
RecipeTest/Modules/Recipe/Models/Domain/
  RecipeQueryFacet.swift          // the facet enum + RecipeQuery derivation and removal
```

One type moves. `HomeSearchPill` becomes
`Modules/Shared/UI/Components/RecipeSearchPill.swift`, taking its placeholder as a `String`
instead of hardcoding Home's. A `String` and not a `LocalizedStringResource`, because under
the view-model rule the placeholder is a value a view model produced — the list passes
`viewModel.searchPlaceholder`. Home is not converted to the rule yet, so it localizes at its
call site and is converted with the rest of Home in a later session. The move is a separate
commit from the list screen, so the diff that touches Home is reviewable on its own.

Mocks, per project convention, live under `RecipeTest/Mocks/Modules/RecipeList/` — a
`MockRecipeListViewModel`, a `MockRecipeCardViewModel` and a `MockRecipeFacetChipViewModel`,
all inside `#if DEBUG`, shared by every `#Preview` on the screen.

### Layers

```
RecipeListViewCoordinator  owns the view model, wires taps to PathRouter
  RecipeListView           layout only
    RecipeListViewModel    query state, paging, mapping to card view models
      RecipeServiceProtocol
```

The coordinator stays pure wiring, as `RecipeDetailViewCoordinator` is. The mutable query
lives on the view model, not the coordinator: a facet removal must keep the screen alive and
re-fetch, not rebuild the screen.

## Navigation

### The route

```swift
enum Route {
  enum Recipe: Hashable {
    case detail(RecipeSummary)
    case list(RecipeListRequest)
  }
}
```

`AppCoordinator` gains the second case on the `navigationDestination` it already owns for
`.detail`. A row tap inside the list pushes `.detail`, so the list and the detail screen sit on
the same stack with no extra plumbing.

### The payload

```swift
nonisolated struct RecipeListRequest: Hashable {
  let query: RecipeQuery
  let title: Title

  enum Title: Hashable {
    case category(String)
    case search(String)
    case all
  }
}
```

`query` and `title` are set together by a static factory per entry point, so the two cannot
drift — a request titled "Desserts" whose query filters on "Snacks" is not constructible:

```swift
extension RecipeListRequest {
  static func category(_ category: RecipeCategory) -> Self
  static func search(_ text: String, query: RecipeQuery = .empty) -> Self
  static func all(query: RecipeQuery = .empty) -> Self
}
```

Home calls `.category(category)`. The search overlay will call `.search(text, query:)` and the
filter sheet `.all(query:)`, both reaching the same screen.

### Why the title is a case and not a `String`

The title is *what the list is of*, not the words on the bar. The view model turns it into
localized copy — `.category("Desserts")` renders the category's name verbatim, `.search("pho")`
renders "Search results", `.all` renders "All recipes" — and the same case also decides the
search pill's placeholder ("Search Desserts" versus "Search recipes or ingredients"). A
`String` would force the caller to localize, and force the pill to re-derive.

### Why the query, and not a `RecipeCategory`

A category-only route would need a second case the moment search lands, and the view model
would grow a second init to match. `RecipeQuery` already carries every facet the product has;
pushing one is the whole reuse story.

## State

### The view model surface

```swift
@MainActor
protocol RecipeListViewModelProtocol: AnyObject, Observable {
  var title: String { get }
  var searchPlaceholder: String { get }

  var recipes: SectionState<[RecipeCardViewModel]> { get }
  var resultCountText: String? { get }

  var facetChips: [RecipeFacetChipViewModel] { get }
  var showsClearAllChips: Bool { get }

  var emptyTitle: LocalizedStringResource { get }
  var emptyDetail: LocalizedStringResource? { get }
  var showsClearFiltersButton: Bool { get }

  var isLoadingNextPage: Bool { get }
  var nextPageError: String? { get }

  var viewMode: RecipeListViewMode { get }

  func loadFirstPage() async
  func loadNextPageIfNeeded(after cardID: String) async
  func retryNextPage() async
  func remove(facet: RecipeQueryFacet) async
  func clearFacets() async
  func select(viewMode: RecipeListViewMode)
}
```

Private alongside: the mutable `request`, `nextPage: Page?`, the last `PaginationMetaInfo`,
and a generation counter — the same cancellation guard `HomeViewModel` and
`RecipeDetailViewModel` already use.

The concrete `RecipeCardViewModel` and `RecipeFacetChipViewModel` appear here rather than
their protocols because `SectionState` requires `Equatable` and an array of existentials is
not. Nothing is lost: the card and chip *views* still depend on the protocols, so each previews
against a mock of its own.

`viewMode` is read-only with a `select(viewMode:)` input rather than a settable property. That
keeps the screen on the project's callback style and spares every view a `@Bindable` over an
existential. It is not persisted — leaving the list forgets it.

### Paging

Page size is 20.

Worth stating plainly: the mock data holds 36 recipes across six categories, so a category
tap returns about six rows and never reaches a second page. The pager is therefore proven by
its tests and by the later "All recipes" and search entry points, not by tapping a category
today. Nothing here is tuned to make the pager visible in a demo — a page size chosen to show
off scrolling would be the product bending to the fixture.

- `loadFirstPage()` requests `Page(index: 1, size: 20)`, replaces the rows, stores the meta,
  and sets `nextPage` to `meta.hasLoadedAllData ? nil : page.next`.
- `loadNextPageIfNeeded(after:)` is called from every card's `.onAppear`. The **view model**
  decides: it returns immediately unless `cardID` is the last loaded card, `nextPage` is
  non-nil, and no page is already in flight. The view reports an event; it does not decide
  what the event means.
- A successful next page appends and advances the cursor. A failed one sets `nextPageError`
  and leaves both the rows and the cursor alone, so `retryNextPage()` asks for the same page
  again.
- `remove(facet:)` and `clearFacets()` rewrite the query, reset the cursor, and run
  `loadFirstPage()`. Rows are discarded; the count and chips are recomputed from the response.
- The screen's `.task` calls `loadFirstPageIfNeeded()`, which is a no-op once a first page has
  landed. SwiftUI cancels that task when a pushed recipe covers the list and restarts it on the
  way back; reloading there would throw away every page after the first along with the user's
  place. A failed or cancelled first load does retry on return.
- A page that appends nothing — every row already held — stops the pager instead of advancing
  the cursor. The trigger is the tail row appearing, so with no new tail row nothing would ever
  ask again and the cursor would sit there unpolled.

### Cancellation

`isCancellation` already exists and `SectionState.recovering(from:)` already honours it, so a
cancelled first page keeps whatever state preceded it. The pager needs the same care by hand:
a cancelled next page clears `isLoadingNextPage` and sets **no** `nextPageError`, otherwise
walking away from the screen leaves a failure message behind for the next visit.

### The count

`resultCountText` is derived from `meta.total`, not from `recipes.count`. With paging those
two disagree on every screen but the last, and the prototype's count is the size of the result
set, not of what has loaded. It is `nil` until the first page resolves, so the toolbar renders
the toggle alone rather than a flickering "0 recipes".

### The card and chip view models

```swift
nonisolated protocol RecipeCardViewModelProtocol: Identifiable {
  var id: String { get }
  var title: String { get }
  var imageURL: URL? { get }
  var cuisineAndCategory: String? { get }
  var cookingTimeText: String? { get }
  var servingsText: String? { get }
  var accessibilityLabel: String { get }
  var summary: RecipeSummary { get }
}

nonisolated protocol RecipeFacetChipViewModelProtocol: Identifiable {
  var id: RecipeQueryFacet { get }
  var label: String { get }
  var removeAccessibilityLabel: String { get }
  var isExclusion: Bool { get }
}
```

`summary` is the one domain value a card view model exposes, because tapping a row pushes
`Route.Recipe.detail(RecipeSummary)` and the detail screen paints its header from it. It is a
navigation payload, not something the card renders — no view reads it.

`isExclusion` exists because the prototype tints an "Exclude:" chip differently. It is a
presentation fact the view model owns, so the chip view branches on a boolean rather than
inspecting the facet itself.

`RecipeListViewMode` is `enum RecipeListViewMode: CaseIterable { case grid, list }`, with its
label and symbol name supplied by the toggle's own getters.

## Facets

```swift
nonisolated enum RecipeQueryFacet: Hashable {
  case vegetarian(Bool)
  case servings(RecipeServings)
  case include(String)
  case exclude(String)
  case searchesSteps
}
```

with three pure helpers on `RecipeQuery`: `activeFacets`, `removing(_:)`, `clearingFacets()`.

.vegetarian carries its value because `isVegetarian` is `Bool?` and the encoder deliberately
keeps `false` — "a filter the user set, not an absence". A bare case could not tell a
vegetarian-only list from a non-vegetarian-only one, and would label one of the two wrongly.

`category` and `searchText` are deliberately **not** facets. Both are already the screen's
title, and a chip that removes the category would leave the list showing everything under a
heading that says "Desserts". `sort` is not a facet either — it is not user-set.

Today Home pushes a category-only query, so the chip row is empty and hidden. The code is
still reachable and tested, because `activeFacets` is a pure function over a value the tests
construct directly.

## Layout

### The screen

```
NavigationStack (owned by AppCoordinator)
  RecipeListView
    ScrollView
      RecipeSearchPill(placeholder:)
      RecipeFacetChipRow            // hidden when empty
      RecipeListToolbar             // count + RecipeListViewModeToggle
      RecipeListResults             // switches on SectionState
        LazyVGrid(columns: 1 or 2)
          RecipeCard / RecipeRow
      RecipeListFooter              // spinner, retry, or nothing
  .navigationTitle(viewModel.title)
  .navigationBarTitleDisplayMode(.large)
```

### The navigation bar

Recipe Details hides the navigation bar and draws its own floating back button, and pays for
it with the interactive pop gesture (see that spec's *Swipe-back*). This screen does not. The
system large title collapsing to inline **is** the prototype's sticky `dbar`, and the system
back button keeps edge-swipe-back working. The prototype's custom bar is reproduced by the
platform, for free, with no `UIViewRepresentable` shim.

Home continues to hide its own bar; `.toolbarVisibility` is per-destination, so pushing from a
bar-less screen onto this one is not a conflict.

### Grid and list

One `LazyVGrid` whose column count flips between two and one. The two presentations differ,
matching the prototype:

- `RecipeCard` (grid) — square photograph, name, then time and servings.
- `RecipeRow` (list) — thumbnail on the leading edge, name, `cuisine · category`, then time
  and servings. The fixture stores cuisine lowercased (`"italian"`) and category title-cased
  (`"Pasta"`), while the prototype prints both capitalised, so `cuisineAndCategory` applies
  `localizedCapitalized` to the cuisine. That is exactly the kind of derivation the view-model
  rule exists to move out of a view and under a test.

Both read from the same `RecipeCardViewModelProtocol`; the grid simply does not draw
`cuisineAndCategory`.

The prototype morphs each card from its old box to its new one. **The fallback shipped: a
crossfade plus the animated column change.**

`matchedGeometryEffect` was tried first and removed, because it cannot work at this seam.
The effect interpolates between two views sharing an id in one transaction; here the
`ForEach` element identity is stable across the toggle, so exactly one view ever holds each
id and the modifier resolves to a no-op. The swap that actually happens is one level below
it — `row(for:)` is a `@ViewBuilder` switch, so changing mode tears down the `RecipeCard`
subtree and builds a `RecipeRow` at the same identity, beneath the effect that was supposed
to observe it. Moving the effect inside both branches puts two `isSource: true` views in the
group during the transition, which SwiftUI warns about. So the cell frame animates with the
column change and the two presentations cross-fade.

### Empty and failed

`.empty` is rendered by `RecipeListEmptyState`, not `SectionStateView`. The prototype's empty
state offers "Clear filters" and `SectionStateView` models only a retry; bending the shared
component to carry an optional second action for one caller is worse than one small
screen-local view.

The copy depends on whether anything is actually filtering. With facets set, it is the
prototype's — "No recipes match your filters" plus "Try removing a filter or searching for
something else." and the Clear filters button. With no facets, that sentence would blame a
filter the user never set, so an empty category reads "No recipes here yet" with no button.
This is the only state the category entry point can reach today, so it is the one the tests
cover first.

`.failed` uses `SectionStateView`'s existing failed treatment unchanged.

### Colours, type and spacing

No literal colours, fonts or copy. Surfaces are `surfacesBackground` for the screen and
`surfacesBackground2` for the cards, chips use `surfacesFieldsAndTags`, text uses
`textPrimary` / `textSecondary`, the toggle's selected capsule uses `surfacesBrandDefault`
with `textInverted`. Card names are `subheadlineSemibold`, metadata `captionRegular`, the
count `footnoteRegular`.

Every numeric constant is a computed `var` in a `// MARK: - Getters` extension. Anything tied
to text size — the pill's height, the row's thumbnail — is `@ScaledMetric`, and the
thumbnail is clamped: at AX5 the raw scale takes 88pt past 270pt and leaves the title about
two characters of width on a 393pt screen. The chip sizes from its padding rather than a
scaled height, so it grows with its own text.
At accessibility sizes both modes render a single column — grid mode keeps the card
presentation and simply stops being two-up, so the toggle still visibly changes something —
and the row's metadata wraps instead of truncating.

### Accessibility

Each card and row is one combined element labelled by the card view model, with `.isButton`
— the grid card by `accessibilityLabel`, the row by `rowAccessibilityLabel`, which also
speaks the `cuisine · category` line only the row prints. That label is the card's non-nil parts joined with
", " — title, cooking time, then `recipeList.card.servings.accessibilityLabel` — giving
"Chicken Adobo, 45 min, serves 4", or just "Chicken Adobo" for a recipe carrying neither
metric. The visible servings text is the bare number beside an icon; only the spoken form
says "serves". Each chip is a
button labelled "Remove Vegetarian". The toggle is an accessibility-grouped pair with the
selected state announced. The footer's spinner is announced as "Loading more recipes".

## Localization

A new `RecipeList.xcstrings`, keys in the project's dotted style:

| Key | English |
| --- | --- |
| `recipeList.title.searchResults` | Search results |
| `recipeList.title.all` | All recipes |
| `recipeList.searchPlaceholder.category` | Search %@ |
| `recipeList.searchPlaceholder.search` | “%@” |
| `recipeList.searchPlaceholder.all` | Search recipes or ingredients |
| `recipeList.resultCount` | %lld recipes *(plural: one → %lld recipe)* |
| `recipeList.empty.title` | No recipes match your filters |
| `recipeList.empty.noResults.title` | No recipes here yet |
| `recipeList.empty.detail` | Try removing a filter or searching for something else. |
| `recipeList.empty.clearFilters` | Clear filters |
| `recipeList.facets.clearAll` | Clear all |
| `recipeList.facet.vegetarian` | Vegetarian |
| `recipeList.facet.servings` | %@ servings |
| `recipeList.facet.include` | Include: %@ |
| `recipeList.facet.exclude` | Exclude: %@ |
| `recipeList.facet.searchesSteps` | Search in steps |
| `recipeList.facet.remove.accessibilityLabel` | Remove %@ |
| `recipeList.card.servings.accessibilityLabel` | serves %lld |
| `recipeList.viewMode.grid` | Grid |
| `recipeList.viewMode.list` | List |
| `recipeList.footer.loading.accessibilityLabel` | Loading more recipes |

`recipeList.resultCount` is a plural variation in the catalog, not an `if count == 1` in Swift.

Cooking time has no keys of its own. `RecipeDetailViewModel.cookingTimeText` already renders
the prototype's `fmtTime` through `Duration.seconds(_:).formatted(.units(allowed: [.hours,
.minutes], width: .abbreviated))`, which localizes the units itself; the card view model uses
the same expression. Two formatters for one value, differing only in which strings a
translator sees, is the failure this avoids.

### `String` or `LocalizedStringResource`

The project's rule, set by `RecipeDetailViewModel`: a value that is *pure copy* stays a
`LocalizedStringResource`, so the view resolves it in its own environment and follows a locale
override. A value that interpolates server data is resolved to a `String` in the view model,
because the data is already fixed by the time the view model holds it.

So `title`, `searchPlaceholder` and `resultCountText` are `String` — each splices in a category
name, a search term or a count. The empty state's heading and detail, the toggle's two labels
and "Clear all" are `LocalizedStringResource`.

## Testing

All Swift Testing, all without a simulator, all against `MockRecipeService`.

**`RecipeQueryFacetTests`** — `activeFacets` derives a chip per set facet and none for an
unset one; `isVegetarian == false` still produces a chip, because that is a filter the user
set; `category`, `searchText` and `sort` never produce chips; `removing(_:)` clears exactly one
facet and leaves the rest; `clearingFacets()` keeps `category` and `searchText`.

**`RecipeListViewModelTests`** — the first page loads and maps to card view models; zero results
become `.empty`, never `.loaded([])`; the second page appends rather than replaces;
`hasLoadedAllData` stops the pager, and a further `loadNextPageIfNeeded` makes no request; a
second call while a page is in flight makes no request; `loadNextPageIfNeeded(after:)` for a
card that is not the last makes no request; a failed next page keeps its rows and sets
`nextPageError`; `retryNextPage()` re-requests the same page index; a cancelled first page
leaves the previous state; a cancelled next page sets no error; `remove(facet:)` re-requests
page 1 with the facet dropped; `resultCountText` follows `meta.total` and not row count, and
reads "1 recipe" for a total of one.

**`RecipeCardViewModelTests`** — 25 → "25 min", 60 → "1 hr", 90 → "1 hr 30 min", nil → nil;
`cuisineAndCategory` joins both, returns the single non-nil one, and is nil when both are;
the accessibility label omits the parts that are nil.

**`RecipeFacetChipViewModelTests`** — one label per facet case, and the facet is carried back
out unchanged on removal.

The views themselves are covered by `#Preview`s, not tests: every new `View` gets one, driven
by the `MockRecipeListViewModel`, including a loading preview, an empty preview, a failed
preview, a paging-error preview, a chips-populated preview, and both view modes.

## Git

Branch `feat/dan/recipe-list`, cut from `feat/dan/recipe-detail` at `4fdfef0` — **not** from
`develop`. The list's rows push `Route.Recipe.detail`, which exists only on the detail branch;
detail has not merged. Rebase onto `develop` once it does.

Commits follow `[list] <imperative message>`, 72 characters or fewer, no trailing period, and
no `Co-Authored-By` trailer. Committed per coherent piece: the facet helpers, the shared
search pill move, the route and Home's wiring, the card and chip view models, the view model,
the components, the scene, the coordinator, the tests.
