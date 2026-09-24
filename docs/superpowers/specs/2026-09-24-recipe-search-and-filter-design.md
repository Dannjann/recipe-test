# Recipe search and filter

**Date:** 2026-09-24
**Status:** Draft
**Scope:** The search-and-filter overlay reached from the search pill on Home and on any
results list — its two levels, the draft it edits, the suggestions it offers, the recent
searches it remembers, and what applying it does to the screen underneath. No new filters
beyond the ones `RecipeQuery` already models.

## Purpose

Two screens ship with a search pill wired to nothing: `HomeViewCoordinator.handleSearchTap`
and `RecipeListViewCoordinator.handleSearchTap` are both a bare `// TODO`. This stage gives
those taps somewhere to go — the overlay from `B App/bokkie-bites-prototype.html`
(`openSearch` / `paintSO` / `sugList` / `runSearch`, lines 690–800).

Almost nothing new is modelled. `RecipeQuery` already carries every facet the overlay sets;
`RecipeQueryFacet` already renders them as removable chips on the list;
`RecipeListRequest.search(_:query:)` already exists as an entry point. What is missing is the
overlay itself, the suggestion list behind its field, somewhere to keep recent searches, and
the one thing the results list cannot do today: take a new query without being rebuilt.

### What the overlay shows

Level 1, top to bottom, over a dimmed and blurred backdrop:

1. A close button, discarding the draft.
2. **What's cooking?** — a field-shaped *button* carrying the draft's search text, with a
   clear button once there is text. Tapping it opens level 2.
3. **Vegetarian** — a toggle, with the subtitle "Only show meat-free recipes".
4. **Servings** — 1 / 2 / 4 / 6+, single-select, re-tapping the selected one clears it.
5. **Include ingredients** — a text field with an Add button, and a chip per ingredient.
6. **Exclude ingredients** — the same, styled as exclusions.
7. **Search inside instructions** — a toggle, with the subtitle "Your search also checks the
   recipe steps".
8. A pinned footer: **Clear all** on the left, **Search** on the right.

Level 2 replaces the screen: a back button, a focused text field, and a suggestion list —
recent searches when the field is empty; a "Search for 'q'" row, matching categories and
matching recipes once it is not.

### Success criteria

- The pill on Home and on every results list opens the overlay; neither handler is a `TODO`.
- Opening from a category list keeps the category: the list stays titled "Desserts", and the
  overlay shows no category control.
- Every control edits a draft only. Closing the overlay leaves the screen underneath exactly
  as it was, whatever was toggled.
- Applying from Home pushes a results list. Applying from a results list re-queries that same
  list in place — the back stack does not grow.
- Typing offers suggestions from the real service, debounced, with no more than one fetch in
  flight; a failed fetch still leaves "Search for 'q'" usable.
- Picking a recipe suggestion dismisses the whole overlay and opens that recipe.
- Recent searches survive a cold launch, hold no duplicates, and are capped.
- Every value any view renders comes from a view model behind a protocol.
- The overlay's view models are unit-tested without a simulator, a network, or `URLSession`.
- The layout matches the prototype at the default text size, and stays legible and unclipped
  at accessibility text sizes.

### Out of scope

No cuisine filter, no sort control, no time or difficulty filters — `RecipeQuery.sort` stays
the value nobody sets. No "Browse categories" block in the idle suggestion state: it is
deliberately dropped, so an empty field with no history shows nothing. No server-side
suggestion endpoint; suggestions reuse `getRecipes`. No saved searches, no search analytics.

## Architecture

### Module layout

```
RecipeTest/Modules/RecipeSearch/
  Models/
    RecipeSearchRequest.swift
    RecipeSearchResult.swift
    RecipeSuggestion.swift
  Services/
    RecentSearchStoreProtocol.swift
    RecentSearchStore.swift
  UI/
    RecipeSearch.xcstrings
    Scenes/
      RecipeSearchViewCoordinator.swift
      RecipeSearchView.swift
      RecipeSearchViewModel.swift
      RecipeSearchViewModelProtocol.swift
      RecipeSearchInputViewCoordinator.swift
      RecipeSearchInputView.swift
      RecipeSearchInputViewModel.swift
      RecipeSearchInputViewModelProtocol.swift
    Components/
      RecipeSearchFieldButton/RecipeSearchFieldButton.swift
      RecipeSearchSection/RecipeSearchSection.swift
      RecipeSearchToggleRow/RecipeSearchToggleRow.swift
      RecipeServingsPicker/RecipeServingsPicker.swift
      RecipeServingsPicker/RecipeServingsOptionViewModel.swift
      RecipeServingsPicker/RecipeServingsOptionViewModelProtocol.swift
      RecipeIngredientEntry/RecipeIngredientEntry.swift
      RecipeIngredientChipRow/RecipeIngredientChipRow.swift
      RecipeIngredientChipRow/RecipeIngredientChipViewModel.swift
      RecipeIngredientChipRow/RecipeIngredientChipViewModelProtocol.swift
      RecipeSearchFooter/RecipeSearchFooter.swift
      RecipeSuggestionRow/RecipeSuggestionRow.swift
      RecipeSuggestionRow/RecipeSuggestionRowViewModel.swift
      RecipeSuggestionRow/RecipeSuggestionRowViewModelProtocol.swift
      RecipeSuggestionSection/RecipeSuggestionSection.swift
      RecipeSuggestionSection/RecipeSuggestionSectionViewModel.swift

RecipeTest/Mocks/Modules/RecipeSearch/UI/Scenes/RecipeSearch/MockRecipeSearchViewModel.swift
RecipeTest/Mocks/Modules/RecipeSearch/UI/Scenes/RecipeSearchInput/MockRecipeSearchInputViewModel.swift
```

The target uses Xcode's file-system synchronized groups, so no `project.pbxproj` edit is
needed for any of it.

### Layers

Unchanged from the rest of the app. Views render what a protocol hands them; view models own
state and formatting; `RecipeServiceProtocol` is the only way to data; nothing above the
client layer names a third-party type. `RecentSearchStore` takes `UserDefaults` through its
`init` rather than reaching for `.standard` inside, which is the whole of its test seam.

### No new service for suggestions

`RecipeSearchInputViewModel` depends on `RecipeServiceProtocol` directly, the way
`HomeViewModel` does. A suggestion is a `getRecipes(query:page:)` with `searchText` set and
the first page taken, plus a `getCategories()` filtered in memory. A `RecipeSuggestionService`
wrapping two calls it does not change would be a layer that only forwards.

## Presentation

### Why a full-screen cover with its own stack

The host screen presents a `fullScreenCover` holding its own `NavigationStack`. Level 2 is a
push inside that stack with `.navigationTransition(.zoom)`, sourced from the field button, so
it grows out of the field the way the prototype's `openFull` does — and keeps the interactive
swipe back that a hand-rolled phase crossfade would have to re-implement.

Each level is a scene with its own coordinator, view and view model, which is the shape every
other screen in this project already has.

### The two levels

```
HomeViewCoordinator / RecipeListViewCoordinator
  @State searchRequest: RecipeSearchRequest?
  .fullScreenCover(item: $searchRequest) { request in
      RecipeSearchViewCoordinator(request: request, onFinish: ...)
  }
      │
      └ NavigationStack
          ├ level 1  RecipeSearchView         (filters, footer)
          └ level 2  RecipeSearchInputView    (field, suggestions)
```

`RecipeSearchRequest` is `Identifiable` so `fullScreenCover(item:)` can key on it; its id is
the query it carries.

## State

### The draft

`RecipeSearchViewModel` holds `private(set) var draft: RecipeQuery`, seeded from
`request.query`. Every control edits the draft and nothing else. The applied query lives where
it already lives — `RecipeListViewModel.query`, and nothing at all on Home — and is replaced
only when the overlay returns a result.

Closing with the X discards the draft by simply not returning one.

### The result

```swift
nonisolated enum RecipeSearchResult {
  case apply(RecipeQuery)
  case openRecipe(RecipeSummary)
}
```

Two cases because the overlay has two exits: the Search button, and a recipe suggestion that
skips the results list entirely.

### The level-1 view-model surface

```swift
@MainActor
protocol RecipeSearchViewModelProtocol: AnyObject, Observable {
  var fieldText: String { get }
  var hasFieldText: Bool { get }
  var isVegetarian: Bool { get }
  var searchesSteps: Bool { get }
  var servingsOptions: [RecipeServingsOptionViewModel] { get }
  var includeChips: [RecipeIngredientChipViewModel] { get }
  var excludeChips: [RecipeIngredientChipViewModel] { get }
  var showsClearAll: Bool { get }

  func toggleVegetarian()
  func toggleSearchesSteps()
  func select(servings: RecipeServings)
  func addInclude(_ text: String)
  func addExclude(_ text: String)
  func remove(chip: RecipeIngredientChipViewModel)
  func set(searchText: String)
  func clearAll()
  func apply() -> RecipeSearchResult
}
```

`fieldText` is the draft's text when there is one and the placeholder when there is not;
`hasFieldText` is what the view uses to style it as a placeholder and to show the clear
button, so no view asks whether a string is empty.

Rules the view model enforces, all of them the prototype's:

- An added ingredient is trimmed and lowercased; a blank one is ignored; a duplicate is
  ignored; adding to Include removes it from Exclude, and the reverse.
- `select(servings:)` on the already-selected value clears it.
- `clearAll()` clears the search text **as well as** the facets — which is not what the
  results list's `clearFacets()` does, and deliberately so: `clearFacets()` keeps what scopes
  the list, while the overlay's button means "start again".
- `apply()` records the draft's text as a recent search when it is non-empty, then returns
  `.apply(draft)`.

`category` and `sort` ride through the draft untouched. There is no control for either.

The two ingredient entry fields own their own `@State` text and call `onAdd(String)`: that
text is local input on its way to the view model, not a value the view model renders, and
keeping it out avoids a `@Bindable` over an existential.

### The level-2 view-model surface

```swift
@MainActor
protocol RecipeSearchInputViewModelProtocol: AnyObject, Observable {
  var queryRow: RecipeSuggestionRowViewModel? { get }
  var sections: SectionState<[RecipeSuggestionSectionViewModel]> { get }
  var emptyText: LocalizedStringResource { get }

  func update(text: String) async
  func select(_ row: RecipeSuggestionRowViewModel)
}
```

`queryRow` — "Search for 'ado'" — sits outside the `SectionState` on purpose: it is the one
row that must survive a slow fetch and a failed one, because a network problem should never
stop somebody searching for what they typed.

```swift
nonisolated enum RecipeSuggestion: Hashable {
  case query(String)
  case recent(String)
  case category(RecipeCategory)
  case recipe(RecipeSummary)
}
```

Selecting `.query`, `.recent` or `.category` fills the field and pops to level 1 — a category
suggestion is a shortcut to its name as search text, not a navigation. Selecting `.recipe`
dismisses the whole overlay and opens that recipe, and records no recent, exactly as
`pickRecipe` does.

### Suggestions and debounce

`RecipeSearchInputView` drives the fetch from `.task(id: text)`, so SwiftUI cancels the
previous one as the next keystroke lands. `update(text:)` sleeps 300 ms before it requests
anything, which makes the cancellation do the debouncing with no task bookkeeping in the view
model.

- Empty text: recent searches only, no request.
- Non-empty: `getRecipes` with `searchText` set, first page, capped at 8 rows for display;
  categories from a single `getCategories()` cached on first appearance and matched in memory,
  case-insensitively.
- No matches at all: `.empty`, rendering "No recipe names match. You can still search for it."
- A failure: `.failed`, rendering the detail, with `queryRow` intact.
- Cancellation paints neither an error nor a stranded spinner — `SectionState.recovering(from:)`
  already handles that and is reused as-is.

### Recent searches

```swift
@MainActor
protocol RecentSearchStoreProtocol: AppServiceProtocol {
  var searches: [String] { get }
  func record(_ text: String)
  func clear()
}
```

`RecentSearchStore` is backed by `UserDefaults`, injected through `init` and defaulting to
`.standard`, and held by `AppContainer` as a lazy `recentSearchStore`. This is the project's
first persistence of any kind; it is deliberately the smallest possible amount of it — one
array of strings under one key, no model, no migration story.

`record` trims, ignores blanks, removes any case-insensitive duplicate, inserts at the front,
and truncates to 10. The suggestion list shows the first 4.

## Applying

### From Home

```swift
case let .apply(query):
  let searchText = query.searchText ?? ""

  pathRouter.push(Route.Recipe.list(
    searchText.isEmpty
      ? .all(query: query)
      : .search(searchText, query: query)
  ))
```

Filters with no text give "All recipes"; text gives "Search results". Both are existing
`RecipeListRequest` entry points and neither needs a new route case.

### From a results list

`await viewModel.apply(query:)`, and the screen re-queries in place. No push, so tapping the
pill five times leaves one list on the stack rather than five.

### What this changes in `RecipeList`

Three small edits to code that already exists:

1. `RecipeListViewModel.query` becomes `private(set)` rather than `private`, so a subclass can
   read it.
2. `RecipeListViewModel` gains `func apply(query: RecipeQuery) async` — assigns the query,
   clears `hasLoadedOnce`, and calls `loadFirstPage()`, which already bumps `generation` and
   so already discards anything in flight.
3. `SearchRecipeListViewModel` drops its stored `searchText` and reads `query.searchText`
   instead. Without that, applying a new search to a list opened by search would leave the
   pill advertising the previous one. Its `init` loses the parameter, and
   `RecipeListViewCoordinator` stops passing it.

`searchPlaceholder` also picks up the prototype's `searchRow` behaviour: when the applied
query carries search text, the pill shows that text quoted; otherwise it shows the scoped
placeholder the subclass supplies. The prototype's second pill line — the filter summary —
is **not** reproduced, because the facet chip row directly beneath the pill already shows
exactly those values, and a second copy would be two places to keep honest.

A category list stays a category list after applying text to it: `CategoryRecipeListViewModel`
keeps its title, and the query carries both the category and the text. That is what the
prototype does, and it is why the overlay needs no category control.

## Layout

Level 1 is a `ScrollView` of rounded cards on `surfacesBackground`, over the host screen
dimmed and blurred by a `.ultraThinMaterial` backdrop. The footer is pinned outside the scroll
view so Search is always reachable. Level 2 is a plain list on the same background.

Colours and type come from the theme tokens only — `surfacesBackground2` for cards,
`surfacesFieldsAndTags` for the field and the include chips, `complementaryShade3` for the
exclude chips (matching `RecipeFacetChipViewModel.backgroundColorStyle`, so an ingredient
looks the same in the overlay as it does on the list), `surfacesBrandDefault` for the Search
button, `title3` for section headings, `bodyRegular` for values, `footnoteRegular` for the
subtitles under the two toggles. No literal colour, font or size anywhere.

Every constant is a computed var in a private `// MARK: - Getters > Constants` extension.
Calls with two or more arguments wrap one per line.

### Accessibility

Identifiers follow the existing `recipe-search-pill-button` convention, so the Maestro flows
have stable hooks:

`recipe-search-close-button`, `recipe-search-field-button`, `recipe-search-field-clear-button`,
`recipe-search-vegetarian-toggle`, `recipe-search-servings-option-{1,2,4,6-plus}`,
`recipe-search-include-field`, `recipe-search-include-add-button`,
`recipe-search-include-chip-{ingredient}-remove-button`, the same four for `exclude`,
`recipe-search-steps-toggle`, `recipe-search-clear-all-button`, `recipe-search-submit-button`,
`recipe-search-input-field`, `recipe-search-input-back-button`,
`recipe-search-suggestion-{kind}-{value}`.

Toggles and servings options carry `accessibilityAddTraits(.isSelected)` and a spoken label
rather than relying on colour. Chip remove buttons carry "Remove {ingredient}", the way the
facet chips already do. Level 2's field takes focus on appear and submits on return.

## Localization

A new `RecipeSearch.xcstrings`, keys prefixed `recipeSearch`, reached through the generated
`.RecipeSearch.` accessor. `String(localized:)` in view models; `LocalizedStringResource` for
anything a view holds as a constant. Nothing user-visible is a Swift string literal.

## Testing

Swift Testing, no simulator, against `MockRecipeService` and a suite-named `UserDefaults`.
Written alongside each piece rather than test-first, by explicit decision this session.

**`RecentSearchStoreTests`** — most-recent-first ordering; a re-recorded term moves to the
front rather than duplicating; matching is case-insensitive; blanks and whitespace-only terms
are ignored; the list truncates to 10; `clear()` empties it; a second store over the same
suite reads back what the first wrote.

**`RecipeSearchViewModelTests`** — the draft is seeded from the request, category included;
toggling flips one value and leaves the rest; re-selecting the current servings clears it;
adding to Include removes from Exclude and the reverse; adds are trimmed, lowercased and
de-duplicated, and a blank add is a no-op; `clearAll()` clears the text as well as the facets
but keeps the category; `apply()` returns the draft unchanged and records a recent only when
there is text.

**`RecipeSearchInputViewModelTests`** — empty text makes no request and renders recents;
non-empty text renders the query row before the fetch resolves; categories match
case-insensitively; no matches yields `.empty`; a service error yields `.failed` with the
query row still present; a cancelled fetch leaves the previous state; selecting a recipe row
returns `.openRecipe` and records no recent.

**`RecipeListViewModelTests` additions** — `apply(query:)` re-requests page 1 with the new
query, replaces the rows rather than appending, and resets the result total; a next page in
flight when it lands is discarded; `SearchRecipeListViewModel.searchPlaceholder` follows the
applied text.

**Component view-model tests** — `RecipeServingsOptionViewModelTests` (label per case,
selection), `RecipeIngredientChipViewModelTests` (label, exclusion styling, identifier),
`RecipeSuggestionRowViewModelTests` (title, subtitle and image per suggestion case).

Views are covered by `#Preview`s driven by `MockRecipeSearchViewModel` and
`MockRecipeSearchInputViewModel` — an empty draft, a fully populated draft, idle suggestions,
typed suggestions, loading, empty and failed.

**Maestro** — one flow for the search journey, built against the `RecipeTest` production
scheme: open the overlay from Home, type, pick a suggestion, set a filter, apply, and assert
the results list and its chips; then reopen from that list and assert it refreshes in place
without a new screen.

## Git

Branch `feat/dan/recipe-search`, cut from `feat/dan/recipe-list` — **not** from `develop`.
The overlay edits `RecipeListViewModel` and `SearchRecipeListViewModel`, neither of which has
merged. Rebase onto `develop` once the list branch lands.

Commits follow `[search] <imperative message>`, 72 characters or fewer, no trailing period,
and no `Co-Authored-By` trailer. Committed per coherent piece: the models, the recent search
store and its container wiring, the level-1 view model, the level-1 components, the level-1
scene, the level-2 view model, the level-2 components and scene, the `RecipeList` changes,
the host wiring, the strings, the tests, the flow.
