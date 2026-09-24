# Recipe search and filter — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the search-and-filter overlay the search pill on Home and on every results
list opens, and make a results list able to take a new query without being rebuilt.

**Architecture:** A new `RecipeSearch` module presented as a `fullScreenCover` holding its own
`NavigationStack` — level 1 edits a draft `RecipeQuery` behind a protocol-backed view model,
level 2 is a pushed typing screen offering suggestions from the existing
`RecipeServiceProtocol`. The overlay owns nothing the host screen owns: it takes a copy of the
applied query, returns a `RecipeSearchResult`, and the host decides whether to push a list or
re-query in place.

**Tech Stack:** Swift 6, SwiftUI, iOS 26.3, Swift Testing, Maestro. No new dependencies.

**Spec:** `docs/superpowers/specs/2026-09-24-recipe-search-and-filter-design.md`

## Global Constraints

- **No TDD this session, by explicit decision.** Each task implements, then tests, then runs,
  then commits. Tests are still required — they are part of the standards, not of TDD.
- Branch `feat/dan/recipe-search`. Commits read `[search] <imperative>`, 72 characters or
  fewer, no trailing period, **no `Co-Authored-By` trailer**.
- Comments only where the code cannot speak for itself — why, never what.
- Every call with two or more arguments wraps one argument per line, regardless of length.
- Constants are computed vars in a `// MARK: - Getters > Constants` extension. No literal
  colour, font, size or user-facing string anywhere in a view.
- One view per file. Every new `View` gets a `#Preview` driven by a mock under
  `RecipeTest/Mocks/`, never by a live view model.
- No view derives a rendered value. Rows, chips and options each get their own view model.
- No third-party type above the client layer.
- Test command: `xcodebuild test -project RecipeTest.xcodeproj -scheme RecipeTest
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -skipPackagePluginValidation
  CODE_SIGNING_ALLOWED=YES CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO`
- Format check: `swiftformat RecipeTest Tests UITests --lint`
- String catalog keys are dotted (`recipeSearch.footer.submit`); the generated symbol is
  `.RecipeSearch.recipeSearchFooterSubmit`.
- Xcode file-system synchronized groups: never edit `project.pbxproj`.

## Review Focus

Five things the spec implies, that no obvious happy-path test would catch, each pinned to a
test in the task that owns the code:

1. **An ingredient typed with different casing or padding** — "  Garlic " must not produce a
   second chip beside "garlic". Pinned in Task 4.
2. **An ingredient added to Include that is already in Exclude** — it must move, not exist in
   both, or the query asks the server for recipes that both contain and omit it. Pinned in
   Task 4.
3. **The overlay dismissed with the X after edits** — the screen underneath must be byte-for-
   byte what it was. Pinned in Task 9.
4. **Applying a query while a next page is in flight** — the in-flight page must not append
   onto the new result set. Pinned in Task 3.
5. **Level 2 left while a suggestion fetch is running** — cancellation must paint neither an
   error nor a stranded spinner. Pinned in Task 7.

---

### Task 1: Search models

**Files:**
- Create: `RecipeTest/Modules/RecipeSearch/Models/RecipeSearchRequest.swift`
- Create: `RecipeTest/Modules/RecipeSearch/Models/RecipeSearchResult.swift`
- Create: `RecipeTest/Modules/RecipeSearch/Models/RecipeSuggestion.swift`

**Interfaces:**
- Consumes: `RecipeQuery`, `RecipeCategory`, `RecipeSummary` (all existing).
- Produces: `RecipeSearchRequest(query:)` with `var id: RecipeQuery`; `RecipeSearchResult`
  with `.apply(RecipeQuery)` / `.openRecipe(RecipeSummary)`; `RecipeSuggestion` with
  `.query(String)` / `.recent(String)` / `.category(RecipeCategory)` / `.recipe(RecipeSummary)`.

- [ ] **Step 1: Write the three models**

```swift
/// What the overlay opens with. `Identifiable` so `fullScreenCover(item:)` can key on it;
/// the query is the identity, so reopening with a different one presents a fresh overlay.
nonisolated struct RecipeSearchRequest: Identifiable, Hashable {
  let query: RecipeQuery
}

nonisolated extension RecipeSearchRequest {
  var id: RecipeQuery {
    query
  }
}
```

```swift
/// The overlay has two exits: the Search button, and a recipe suggestion that skips the
/// results list entirely.
nonisolated enum RecipeSearchResult: Hashable {
  case apply(RecipeQuery)
  case openRecipe(RecipeSummary)
}
```

```swift
nonisolated enum RecipeSuggestion: Hashable {
  /// The typed text offered back as "Search for '…'".
  case query(String)
  case recent(String)
  case category(RecipeCategory)
  case recipe(RecipeSummary)
}
```

- [ ] **Step 2: Build**

Run the test command from Global Constraints.
Expected: builds; no tests added yet — these are three value types with no behaviour.

- [ ] **Step 3: Commit**

```bash
git add RecipeTest/Modules/RecipeSearch/Models
git commit -m "[search] Add the overlay's request, result and suggestion models"
```

---

### Task 2: Recent search store

**Files:**
- Create: `RecipeTest/Modules/RecipeSearch/Services/RecentSearchStoreProtocol.swift`
- Create: `RecipeTest/Modules/RecipeSearch/Services/RecentSearchStore.swift`
- Modify: `RecipeTest/App/AppContainer.swift`
- Create: `Tests/Modules/RecipeSearch/Services/RecentSearchStoreTests.swift`

**Interfaces:**
- Produces: `RecentSearchStoreProtocol` with `var searches: [String]`, `func record(_:)`,
  `func clear()`; `RecentSearchStore(defaults:)`; `AppContainer.shared.recentSearchStore`.

- [ ] **Step 1: Write the protocol and the store**

```swift
/// The project's first persistence, kept deliberately small: one array of strings under one
/// key, no model and no migration story.
@MainActor
protocol RecentSearchStoreProtocol: AppServiceProtocol {
  var searches: [String] { get }

  func record(_ text: String)
  func clear()
}
```

```swift
@MainActor
final class RecentSearchStore: RecentSearchStoreProtocol {
  /// Injected rather than reached for inside, which is the whole of this type's test seam.
  private let defaults: UserDefaults

  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
  }
}

// MARK: - Getters

extension RecentSearchStore {
  var searches: [String] {
    defaults.stringArray(forKey: storageKey) ?? []
  }
}

// MARK: - Inputs

extension RecentSearchStore {
  func record(_ text: String) {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

    guard !trimmed.isEmpty else { return }

    // Case-insensitively: "Adobo" typed after "adobo" is the same search, and two spellings
    // of one term would spend two of the four rows the list shows.
    var recorded = searches.filter { $0.caseInsensitiveCompare(trimmed) != .orderedSame }
    recorded.insert(
      trimmed,
      at: 0
    )

    defaults.set(
      Array(recorded.prefix(limit)),
      forKey: storageKey
    )
  }

  func clear() {
    defaults.removeObject(forKey: storageKey)
  }
}

// MARK: - Getters > Constants

private extension RecentSearchStore {
  var storageKey: String {
    "recipeSearch.recentSearches"
  }

  var limit: Int {
    10
  }
}
```

- [ ] **Step 2: Wire it into `AppContainer`**

Add below `recipeService`, inside the `// MARK: Feature services` block:

```swift
  private(set) lazy var recentSearchStore: RecentSearchStoreProtocol = RecentSearchStore()
```

- [ ] **Step 3: Write the tests**

```swift
@MainActor
struct RecentSearchStoreTests {
  @Test func recordsMostRecentFirst() {
    let store = makeStore()

    store.record("pho")
    store.record("adobo")

    #expect(store.searches == ["adobo", "pho"])
  }

  @Test func movesARepeatedTermToTheFrontWithoutDuplicating() {
    let store = makeStore()

    store.record("pho")
    store.record("adobo")
    store.record("PHO")

    #expect(store.searches == ["PHO", "adobo"])
  }

  @Test func ignoresBlankTerms() {
    let store = makeStore()

    store.record("   ")
    store.record("")

    #expect(store.searches.isEmpty)
  }

  @Test func trimsWhatItStores() {
    let store = makeStore()

    store.record("  adobo  ")

    #expect(store.searches == ["adobo"])
  }

  @Test func keepsAtMostTenTerms() {
    let store = makeStore()

    for index in 1 ... 12 {
      store.record("term-\(index)")
    }

    #expect(store.searches.count == 10)
    #expect(store.searches.first == "term-12")
    #expect(!store.searches.contains("term-1"))
  }

  @Test func clearEmptiesTheList() {
    let store = makeStore()
    store.record("adobo")

    store.clear()

    #expect(store.searches.isEmpty)
  }

  @Test func survivesANewStoreOverTheSameDefaults() {
    let defaults = makeDefaults()
    RecentSearchStore(defaults: defaults).record("adobo")

    #expect(RecentSearchStore(defaults: defaults).searches == ["adobo"])
  }
}

// MARK: - Helpers

private extension RecentSearchStoreTests {
  func makeDefaults() -> UserDefaults {
    // A suite per test: `.standard` would leak one test's terms into the next one and into
    // whatever is installed on the machine running them.
    let suiteName = "RecentSearchStoreTests.\(UUID().uuidString)"

    guard let defaults = UserDefaults(suiteName: suiteName) else {
      fatalError("Could not open a UserDefaults suite for the test")
    }

    return defaults
  }

  func makeStore() -> RecentSearchStore {
    RecentSearchStore(defaults: makeDefaults())
  }
}
```

Add `import Testing`, `import Foundation` and `@testable import RecipeTest` at the top, as
the other test files do.

- [ ] **Step 4: Run the tests**

Run the test command from Global Constraints.
Expected: all `RecentSearchStoreTests` pass.

- [ ] **Step 5: Commit**

```bash
git add RecipeTest/Modules/RecipeSearch/Services RecipeTest/App/AppContainer.swift Tests/Modules/RecipeSearch
git commit -m "[search] Remember recent searches across launches"
```

---

### Task 3: Let a results list take a new query

**Files:**
- Modify: `RecipeTest/Modules/RecipeList/UI/Scenes/RecipeListViewModel.swift`
- Modify: `RecipeTest/Modules/RecipeList/UI/Scenes/RecipeListViewModelProtocol.swift`
- Modify: `RecipeTest/Modules/RecipeList/UI/Scenes/SearchRecipeListViewModel.swift`
- Modify: `RecipeTest/Modules/RecipeList/UI/Scenes/CategoryRecipeListViewModel.swift`
- Modify: `RecipeTest/Modules/RecipeList/UI/RecipeListViewCoordinator.swift`
- Modify: `RecipeTest/Modules/RecipeList/UI/RecipeList.xcstrings`
- Modify: `RecipeTest/Mocks/Modules/RecipeList/UI/Scenes/RecipeList/MockRecipeListViewModel.swift`
- Modify: `Tests/Modules/RecipeList/UI/Scenes/RecipeListViewModelTests.swift`

**Interfaces:**
- Produces: `RecipeListViewModel.apply(query: RecipeQuery) async`, added to
  `RecipeListViewModelProtocol`; `RecipeListViewModel.query` readable by subclasses;
  `searchPlaceholder` showing the applied text quoted.

- [ ] **Step 1: Open the query to subclasses and add `apply(query:)`**

In `RecipeListViewModel`, change the stored property's access:

```swift
  /// Mutable: removing a facet or applying a new one rewrites the query and reloads, without
  /// rebuilding the screen. Readable by a subclass, which titles itself from it.
  private(set) var query: RecipeQuery
```

Add to the `// MARK: - Inputs` extension, beside `clearFacets()`:

```swift
  /// The search overlay handing back a whole new filter. `loadFirstPage` already bumps the
  /// generation, so a next page in flight is discarded rather than appended onto this one.
  func apply(query: RecipeQuery) async {
    self.query = query

    await loadFirstPage()
  }
```

- [ ] **Step 2: Title and placeholder from the query**

Replace `RecipeListViewModel.searchPlaceholder` with the scoped/quoted pair:

```swift
  /// The prototype's pill shows the applied search text back to the user, quoted, and falls
  /// back to what the list is scoped to. The filter summary the prototype puts on a second
  /// line is not reproduced: the chip row directly below already shows exactly those values.
  var searchPlaceholder: String {
    guard
      let searchText = query.searchText,
      !searchText.isEmpty
    else { return scopedSearchPlaceholder }

    return String(localized: .RecipeList.recipeListSearchPlaceholderQuery(searchText))
  }

  // MARK: - Overridables

  var title: String {
    String(localized: .RecipeList.recipeListTitleAll)
  }

  var scopedSearchPlaceholder: String {
    String(localized: .RecipeList.recipeListSearchPlaceholderAll)
  }
```

`SearchRecipeListViewModel` loses its stored text entirely:

```swift
final class SearchRecipeListViewModel: RecipeListViewModel {
  // MARK: - Overrides

  override var title: String {
    String(localized: .RecipeList.recipeListTitleSearchResults)
  }

  override var scopedSearchPlaceholder: String {
    String(localized: .RecipeList.recipeListSearchPlaceholderAll)
  }
}
```

`CategoryRecipeListViewModel` renames its override only:

```swift
  override var scopedSearchPlaceholder: String {
    String(localized: .RecipeList.recipeListSearchPlaceholderCategory(categoryName))
  }
```

In `RecipeListViewCoordinator.viewModel(for:recipeService:)`, the search case drops its
parameter:

```swift
    case .search:
      return SearchRecipeListViewModel(
        query: request.query,
        recipeService: recipeService
      )
```

- [ ] **Step 3: Add the string and the protocol method**

In `RecipeList.xcstrings`, add a key beside the existing placeholders:

```json
    "recipeList.search.placeholder.query" : {
      "comment" : "The search pill on a results list, showing the text the list was searched for.",
      "extractionState" : "manual",
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "“%@”"
          }
        }
      }
    },
```

Add to `RecipeListViewModelProtocol`, beside `clearFacets()`:

```swift
  func apply(query: RecipeQuery) async
```

And to `MockRecipeListViewModel`, in its `// MARK: - Inputs` extension:

```swift
    func apply(query: RecipeQuery) async {}
```

- [ ] **Step 4: Add the tests**

Append to `RecipeListViewModelTests`:

```swift
  @Test func applyingAQueryRequestsPageOneWithIt() async {
    let service = MockRecipeService()
    let viewModel = RecipeListViewModel(
      query: .empty,
      recipeService: service
    )
    await viewModel.loadFirstPage()

    var applied = RecipeQuery.empty
    applied.searchText = "adobo"
    applied.isVegetarian = true
    await viewModel.apply(query: applied)

    #expect(service.recipes.requests.last?.query == applied)
    #expect(service.recipes.requests.last?.page.index == 1)
  }

  @Test func applyingAQueryReplacesTheRowsRatherThanAppending() async {
    let service = MockRecipeService(recipes: RecipeListPage(
      recipes: [.dummy(id: "rcp-001")],
      meta: .dummy(total: 1)
    ))
    let viewModel = RecipeListViewModel(
      query: .empty,
      recipeService: service
    )
    await viewModel.loadFirstPage()

    service.recipes.result = .success(RecipeListPage(
      recipes: [.dummy(id: "rcp-002")],
      meta: .dummy(total: 1)
    ))
    await viewModel.apply(query: RecipeQuery(searchText: "adobo"))

    #expect(viewModel.recipes.value?.map(\.id) == ["rcp-002"])
    #expect(viewModel.resultCountText != nil)
  }

  @Test func theSearchPlaceholderFollowsTheAppliedText() async {
    let viewModel = SearchRecipeListViewModel(
      query: RecipeQuery(searchText: "pho"),
      recipeService: MockRecipeService()
    )

    #expect(viewModel.searchPlaceholder.contains("pho"))

    await viewModel.apply(query: RecipeQuery(searchText: "adobo"))

    #expect(viewModel.searchPlaceholder.contains("adobo"))
  }

  @Test func aCategoryListKeepsItsTitleWhenTextIsApplied() async {
    let viewModel = CategoryRecipeListViewModel(
      categoryName: "Desserts",
      query: RecipeQuery(category: "Desserts"),
      recipeService: MockRecipeService()
    )

    var applied = RecipeQuery(category: "Desserts")
    applied.searchText = "mango"
    await viewModel.apply(query: applied)

    #expect(viewModel.title == "Desserts")
  }
```

Check `MockAPICall`'s actual member names (`requests`, `result`) in
`Tests/Mocks/Support/MockAPICall.swift` and `DummyRecipeSummary` / `DummyRemotePaginationMetaInfo`
for the `dummy` signatures before writing these, and adjust to match — the existing tests in
this file are the reference.

Fix any existing test in this file that constructs `SearchRecipeListViewModel(searchText:…)`.

- [ ] **Step 5: Run the tests**

Run the test command from Global Constraints.
Expected: the whole suite passes, including the four new cases.

- [ ] **Step 6: Commit**

```bash
git add RecipeTest/Modules/RecipeList RecipeTest/Mocks Tests/Modules/RecipeList
git commit -m "[search] Let a results list take a new query in place"
```

---

### Task 4: Level-1 view model and its element view models

**Files:**
- Create: `RecipeTest/Modules/RecipeSearch/UI/Scenes/RecipeSearchViewModelProtocol.swift`
- Create: `RecipeTest/Modules/RecipeSearch/UI/Scenes/RecipeSearchViewModel.swift`
- Create: `RecipeTest/Modules/RecipeSearch/UI/Components/RecipeServingsPicker/RecipeServingsOptionViewModelProtocol.swift`
- Create: `RecipeTest/Modules/RecipeSearch/UI/Components/RecipeServingsPicker/RecipeServingsOptionViewModel.swift`
- Create: `RecipeTest/Modules/RecipeSearch/UI/Components/RecipeIngredientChipRow/RecipeIngredientChipViewModelProtocol.swift`
- Create: `RecipeTest/Modules/RecipeSearch/UI/Components/RecipeIngredientChipRow/RecipeIngredientChipViewModel.swift`
- Create: `RecipeTest/Modules/RecipeSearch/UI/RecipeSearch.xcstrings`
- Create: `Tests/Modules/RecipeSearch/UI/Scenes/RecipeSearchViewModelTests.swift`
- Create: `Tests/Modules/RecipeSearch/UI/Components/RecipeServingsOptionViewModelTests.swift`
- Create: `Tests/Modules/RecipeSearch/UI/Components/RecipeIngredientChipViewModelTests.swift`

**Interfaces:**
- Consumes: `RecipeSearchRequest`, `RecipeSearchResult`, `RecentSearchStoreProtocol`.
- Produces: `RecipeSearchViewModelProtocol` exactly as listed in Step 1;
  `RecipeServingsOptionViewModel(servings:isSelected:)`;
  `RecipeIngredientChipViewModel(ingredient:kind:)` with `Kind.include` / `.exclude`.

- [ ] **Step 1: Write the protocol**

```swift
/// The concrete element view models are named rather than their protocols because `ForEach`
/// needs a concrete `Identifiable`; the element *views* still depend on the protocols.
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

- [ ] **Step 2: Write the element view models**

```swift
nonisolated protocol RecipeServingsOptionViewModelProtocol: Identifiable {
  var id: RecipeServings { get }
  var label: String { get }
  var isSelected: Bool { get }
  var accessibilityLabel: String { get }

  /// Not derived from the label: an identifier a flow selects on must not move with the copy.
  var accessibilityIdentifier: String { get }
}
```

```swift
nonisolated struct RecipeServingsOptionViewModel: RecipeServingsOptionViewModelProtocol {
  let servings: RecipeServings
  let isSelected: Bool
}

// MARK: - Getters

nonisolated extension RecipeServingsOptionViewModel {
  var id: RecipeServings {
    servings
  }

  /// `RecipeServings.rawValue` is already the display string — "1", "2", "4", "6+".
  var label: String {
    servings.rawValue
  }

  var accessibilityLabel: String {
    String(localized: .RecipeSearch.recipeSearchServingsAccessibilityLabel(servings.rawValue))
  }

  var accessibilityIdentifier: String {
    "recipe-search-servings-option-\(identifierSuffix)"
  }
}

// MARK: - Getters > Private

private nonisolated extension RecipeServingsOptionViewModel {
  /// "6+" would put a character into an identifier that a selector has to escape.
  var identifierSuffix: String {
    servings == .sixOrMore ? "6-plus" : servings.rawValue
  }
}
```

```swift
nonisolated protocol RecipeIngredientChipViewModelProtocol: Identifiable {
  var id: String { get }
  var label: String { get }
  var removeAccessibilityLabel: String { get }

  var backgroundColorStyle: Color.ThemeColor { get }
  var accessibilityIdentifier: String { get }
}
```

```swift
nonisolated struct RecipeIngredientChipViewModel: RecipeIngredientChipViewModelProtocol {
  enum Kind: String {
    case include
    case exclude
  }

  let ingredient: String
  let kind: Kind
}

// MARK: - Getters

nonisolated extension RecipeIngredientChipViewModel {
  /// Both lists can hold the same word over the life of an edit, so the kind is part of the
  /// identity: two chips sharing an id would break `ForEach`'s diffing.
  var id: String {
    "\(kind.rawValue)-\(ingredient)"
  }

  var label: String {
    ingredient
  }

  var removeAccessibilityLabel: String {
    String(localized: .RecipeSearch.recipeSearchChipRemoveAccessibilityLabel(ingredient))
  }

  /// The same two colours the results list's facet chips use, so an ingredient looks the same
  /// in the overlay as it does on the list.
  var backgroundColorStyle: Color.ThemeColor {
    kind == .exclude ? .complementaryShade3 : .surfacesFieldsAndTags
  }

  var accessibilityIdentifier: String {
    "recipe-search-\(kind.rawValue)-chip-\(ingredient)-remove-button"
  }
}
```

- [ ] **Step 3: Write the view model**

```swift
@Observable
final class RecipeSearchViewModel: RecipeSearchViewModelProtocol {
  /// Every control edits this and nothing else. The applied query stays with the screen
  /// underneath until `apply()` hands a new one back, so closing changes nothing.
  private(set) var draft: RecipeQuery

  private let recentSearchStore: RecentSearchStoreProtocol

  init(
    request: RecipeSearchRequest,
    recentSearchStore: RecentSearchStoreProtocol = AppContainer.shared.recentSearchStore
  ) {
    draft = request.query
    self.recentSearchStore = recentSearchStore
  }
}

// MARK: - Getters

extension RecipeSearchViewModel {
  var fieldText: String {
    hasFieldText
      ? draft.searchText ?? ""
      : String(localized: .RecipeSearch.recipeSearchFieldPlaceholder)
  }

  var hasFieldText: Bool {
    !(draft.searchText ?? "").isEmpty
  }

  var isVegetarian: Bool {
    draft.isVegetarian ?? false
  }

  var searchesSteps: Bool {
    draft.searchesSteps
  }

  var servingsOptions: [RecipeServingsOptionViewModel] {
    RecipeServings.allCases.map {
      RecipeServingsOptionViewModel(
        servings: $0,
        isSelected: $0 == draft.servings
      )
    }
  }

  var includeChips: [RecipeIngredientChipViewModel] {
    draft.includeIngredients.map {
      RecipeIngredientChipViewModel(
        ingredient: $0,
        kind: .include
      )
    }
  }

  var excludeChips: [RecipeIngredientChipViewModel] {
    draft.excludeIngredients.map {
      RecipeIngredientChipViewModel(
        ingredient: $0,
        kind: .exclude
      )
    }
  }

  var showsClearAll: Bool {
    hasFieldText || !draft.activeFacets.isEmpty
  }
}

// MARK: - Inputs

extension RecipeSearchViewModel {
  /// Off means "no filter", not "not vegetarian": the overlay offers one switch, and
  /// `isVegetarian == false` is a filter of its own that nothing here can set.
  func toggleVegetarian() {
    draft.isVegetarian = isVegetarian ? nil : true
  }

  func toggleSearchesSteps() {
    draft.searchesSteps.toggle()
  }

  func select(servings: RecipeServings) {
    draft.servings = draft.servings == servings ? nil : servings
  }

  func addInclude(_ text: String) {
    add(
      text,
      to: \.includeIngredients,
      removingFrom: \.excludeIngredients
    )
  }

  func addExclude(_ text: String) {
    add(
      text,
      to: \.excludeIngredients,
      removingFrom: \.includeIngredients
    )
  }

  func remove(chip: RecipeIngredientChipViewModel) {
    switch chip.kind {
    case .include:
      draft.includeIngredients.removeAll { $0 == chip.ingredient }

    case .exclude:
      draft.excludeIngredients.removeAll { $0 == chip.ingredient }
    }
  }

  func set(searchText: String) {
    let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

    draft.searchText = trimmed.isEmpty ? nil : trimmed
  }

  /// Clears the text as well as the facets, unlike the results list's `clearFacets()`, which
  /// keeps what scopes the list. This button means "start again".
  func clearAll() {
    draft = draft.clearingFacets()
    draft.searchText = nil
  }

  func apply() -> RecipeSearchResult {
    if let searchText = draft.searchText {
      recentSearchStore.record(searchText)
    }

    return .apply(draft)
  }
}

// MARK: - Helpers

private extension RecipeSearchViewModel {
  /// Lower-cased and trimmed so "  Garlic " and "garlic" are one chip, and removed from the
  /// opposite list so the query never asks for a recipe that both contains and omits it.
  func add(
    _ text: String,
    to keyPath: WritableKeyPath<RecipeQuery, [String]>,
    removingFrom other: WritableKeyPath<RecipeQuery, [String]>
  ) {
    let ingredient = text
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .lowercased()

    guard
      !ingredient.isEmpty,
      !draft[keyPath: keyPath].contains(ingredient)
    else { return }

    draft[keyPath: other].removeAll { $0 == ingredient }
    draft[keyPath: keyPath].append(ingredient)
  }
}
```

- [ ] **Step 4: Create `RecipeSearch.xcstrings`**

A string catalog with `"sourceLanguage": "en"` and these keys, each shaped like the entries in
`RecipeList.xcstrings` (`extractionState: "manual"`, an `en` `stringUnit` with
`state: "translated"`):

| Key | Value |
| --- | --- |
| `recipeSearch.close.accessibilityLabel` | `Close search` |
| `recipeSearch.field.placeholder` | `Search recipes or ingredients` |
| `recipeSearch.field.clear.accessibilityLabel` | `Clear search text` |
| `recipeSearch.section.what.title` | `What's cooking?` |
| `recipeSearch.section.vegetarian.title` | `Vegetarian` |
| `recipeSearch.section.vegetarian.detail` | `Only show meat-free recipes` |
| `recipeSearch.section.servings.title` | `Servings` |
| `recipeSearch.section.include.title` | `Include ingredients` |
| `recipeSearch.section.include.placeholder` | `e.g. garlic` |
| `recipeSearch.section.exclude.title` | `Exclude ingredients` |
| `recipeSearch.section.exclude.placeholder` | `e.g. pork` |
| `recipeSearch.section.steps.title` | `Search inside instructions` |
| `recipeSearch.section.steps.detail` | `Your search also checks the recipe steps` |
| `recipeSearch.add.title` | `Add` |
| `recipeSearch.footer.clearAll` | `Clear all` |
| `recipeSearch.footer.submit` | `Search` |
| `recipeSearch.chip.remove.accessibilityLabel` | `Remove %@` |
| `recipeSearch.servings.accessibilityLabel` | `%@ servings` |

- [ ] **Step 5: Write the tests**

```swift
@MainActor
struct RecipeSearchViewModelTests {
  @Test func seedsTheDraftFromTheRequestIncludingTheCategory() {
    let viewModel = makeViewModel(query: RecipeQuery(
      searchText: "mango",
      category: "Desserts"
    ))

    #expect(viewModel.fieldText == "mango")
    #expect(viewModel.hasFieldText)
    #expect(viewModel.draft.category == "Desserts")
  }

  @Test func showsThePlaceholderWhenThereIsNoText() {
    let viewModel = makeViewModel(query: .empty)

    #expect(!viewModel.hasFieldText)
    #expect(!viewModel.fieldText.isEmpty)
  }

  @Test func togglingVegetarianOffClearsTheFilterRatherThanSettingFalse() {
    let viewModel = makeViewModel(query: .empty)

    viewModel.toggleVegetarian()
    #expect(viewModel.draft.isVegetarian == true)

    viewModel.toggleVegetarian()
    #expect(viewModel.draft.isVegetarian == nil)
  }

  @Test func reselectingTheCurrentServingsClearsIt() {
    let viewModel = makeViewModel(query: .empty)

    viewModel.select(servings: .four)
    #expect(viewModel.draft.servings == .four)

    viewModel.select(servings: .four)
    #expect(viewModel.draft.servings == nil)
  }

  @Test func addingAnIngredientTrimsAndLowercasesIt() {
    let viewModel = makeViewModel(query: .empty)

    viewModel.addInclude("  Garlic ")
    viewModel.addInclude("garlic")

    #expect(viewModel.draft.includeIngredients == ["garlic"])
  }

  @Test func addingABlankIngredientDoesNothing() {
    let viewModel = makeViewModel(query: .empty)

    viewModel.addInclude("   ")

    #expect(viewModel.draft.includeIngredients.isEmpty)
  }

  @Test func addingToIncludeRemovesItFromExclude() {
    let viewModel = makeViewModel(query: .empty)
    viewModel.addExclude("pork")

    viewModel.addInclude("pork")

    #expect(viewModel.draft.includeIngredients == ["pork"])
    #expect(viewModel.draft.excludeIngredients.isEmpty)
  }

  @Test func removingAChipRemovesOnlyItsOwnSide() {
    let viewModel = makeViewModel(query: .empty)
    viewModel.addInclude("garlic")
    viewModel.addExclude("pork")

    viewModel.remove(chip: RecipeIngredientChipViewModel(
      ingredient: "garlic",
      kind: .include
    ))

    #expect(viewModel.draft.includeIngredients.isEmpty)
    #expect(viewModel.draft.excludeIngredients == ["pork"])
  }

  @Test func clearAllClearsTheTextAndTheFacetsButKeepsTheCategory() {
    let viewModel = makeViewModel(query: RecipeQuery(
      searchText: "mango",
      category: "Desserts"
    ))
    viewModel.toggleVegetarian()
    viewModel.addInclude("garlic")

    viewModel.clearAll()

    #expect(viewModel.draft.searchText == nil)
    #expect(viewModel.draft.activeFacets.isEmpty)
    #expect(viewModel.draft.category == "Desserts")
    #expect(!viewModel.showsClearAll)
  }

  @Test func applyReturnsTheDraftAndRecordsTheSearch() {
    let store = MockRecentSearchStore()
    let viewModel = makeViewModel(
      query: RecipeQuery(searchText: "adobo"),
      store: store
    )
    viewModel.toggleVegetarian()

    guard case let .apply(query) = viewModel.apply() else {
      Issue.record("apply() did not return .apply")
      return
    }

    #expect(query == viewModel.draft)
    #expect(store.recorded == ["adobo"])
  }

  @Test func applyRecordsNothingWithoutText() {
    let store = MockRecentSearchStore()
    let viewModel = makeViewModel(
      query: .empty,
      store: store
    )
    viewModel.toggleVegetarian()

    _ = viewModel.apply()

    #expect(store.recorded.isEmpty)
  }
}

// MARK: - Helpers

private extension RecipeSearchViewModelTests {
  func makeViewModel(
    query: RecipeQuery,
    store: RecentSearchStoreProtocol = MockRecentSearchStore()
  ) -> RecipeSearchViewModel {
    RecipeSearchViewModel(
      request: RecipeSearchRequest(query: query),
      recentSearchStore: store
    )
  }
}
```

Create `Tests/Mocks/Modules/RecipeSearch/Services/MockRecentSearchStore.swift`:

```swift
@MainActor
final class MockRecentSearchStore: RecentSearchStoreProtocol {
  private(set) var recorded: [String] = []
  var searches: [String] = []

  func record(_ text: String) {
    recorded.append(text)
    searches.insert(
      text,
      at: 0
    )
  }

  func clear() {
    searches = []
  }
}
```

And the two element view-model test files:

```swift
struct RecipeServingsOptionViewModelTests {
  @Test func labelsEachOptionWithItsRawValue() {
    let options = RecipeServings.allCases.map {
      RecipeServingsOptionViewModel(
        servings: $0,
        isSelected: false
      )
    }

    #expect(options.map(\.label) == ["1", "2", "4", "6+"])
  }

  @Test func keepsThePlusOutOfTheIdentifier() {
    let option = RecipeServingsOptionViewModel(
      servings: .sixOrMore,
      isSelected: true
    )

    #expect(option.accessibilityIdentifier == "recipe-search-servings-option-6-plus")
  }
}
```

```swift
struct RecipeIngredientChipViewModelTests {
  @Test func distinguishesTheTwoSidesInItsIdentity() {
    let include = RecipeIngredientChipViewModel(
      ingredient: "pork",
      kind: .include
    )
    let exclude = RecipeIngredientChipViewModel(
      ingredient: "pork",
      kind: .exclude
    )

    #expect(include.id != exclude.id)
  }

  @Test func stylesAnExclusionDifferently() {
    let include = RecipeIngredientChipViewModel(
      ingredient: "garlic",
      kind: .include
    )
    let exclude = RecipeIngredientChipViewModel(
      ingredient: "pork",
      kind: .exclude
    )

    #expect(include.backgroundColorStyle == .surfacesFieldsAndTags)
    #expect(exclude.backgroundColorStyle == .complementaryShade3)
  }
}
```

- [ ] **Step 6: Run the tests**

Run the test command from Global Constraints.
Expected: every new test passes.

- [ ] **Step 7: Commit**

```bash
git add RecipeTest/Modules/RecipeSearch Tests/Modules/RecipeSearch Tests/Mocks/Modules/RecipeSearch
git commit -m "[search] Add the filter draft view model and its element view models"
```

---

### Task 5: Level-1 components

**Files:**
- Create: `RecipeTest/Modules/RecipeSearch/UI/Components/RecipeSearchSection/RecipeSearchSection.swift`
- Create: `RecipeTest/Modules/RecipeSearch/UI/Components/RecipeSearchFieldButton/RecipeSearchFieldButton.swift`
- Create: `RecipeTest/Modules/RecipeSearch/UI/Components/RecipeSearchToggleRow/RecipeSearchToggleRow.swift`
- Create: `RecipeTest/Modules/RecipeSearch/UI/Components/RecipeServingsPicker/RecipeServingsPicker.swift`
- Create: `RecipeTest/Modules/RecipeSearch/UI/Components/RecipeIngredientEntry/RecipeIngredientEntry.swift`
- Create: `RecipeTest/Modules/RecipeSearch/UI/Components/RecipeIngredientChipRow/RecipeIngredientChipRow.swift`
- Create: `RecipeTest/Modules/RecipeSearch/UI/Components/RecipeSearchFooter/RecipeSearchFooter.swift`
- Create: `RecipeTest/Mocks/Modules/RecipeSearch/UI/Scenes/RecipeSearch/MockRecipeSearchViewModel.swift`

**Interfaces:**
- Consumes: `RecipeSearchViewModelProtocol`, `RecipeServingsOptionViewModel`,
  `RecipeIngredientChipViewModel` from Task 4.
- Produces: the seven views above, each taking the values it renders and a callback per
  interaction, never a view model it mutates.

- [ ] **Step 1: Write `MockRecipeSearchViewModel` first**

Every preview below needs it. Shape it like `MockRecipeListViewModel`: `#if DEBUG`,
`@Observable final class`, every protocol member a stored `var` with a defaulted `init`
parameter, and the derived members in a `// MARK: - Getters` extension. The input methods are
empty bodies except `apply()`, which returns `.apply(.empty)`.

- [ ] **Step 2: Write the seven components**

Each follows the house shape exactly as `RecipeFacetChip.swift` does: a `struct … : View`
taking `let` values and `let on…: …Result` callbacks, a `body`, a private
`// MARK: - Getters` extension holding every constant as a computed var, and `#Preview`s
under `#if DEBUG`.

- `RecipeSearchSection` — the rounded card wrapper: an optional title in `.title3`, a
  `@ViewBuilder` content closure, `surfacesBackground2` background, corner radius 28,
  `cardShadow()`.
- `RecipeSearchFieldButton` — takes `text: String`, `isPlaceholder: Bool`,
  `showsClear: Bool`, `onTap: VoidResult`, `onClearTap: VoidResult`. A magnifying-glass icon,
  the text in `.bodyRegular` (`textTertiary` when `isPlaceholder`, else `textPrimary`), and a
  trailing clear button when `showsClear`. Identifiers `recipe-search-field-button` and
  `recipe-search-field-clear-button`.
- `RecipeSearchToggleRow` — `title: LocalizedStringResource`, `detail: LocalizedStringResource`,
  `isOn: Bool`, `accessibilityIdentifier: String`, `onToggle: VoidResult`. Title in
  `.bodyBold`, detail in `.footnoteRegular`/`textSecondary`, and a `Toggle` whose binding is
  `Binding(get: { isOn }, set: { _ in onToggle() })` so the view holds no state of its own.
- `RecipeServingsPicker` — `options: [RecipeServingsOptionViewModel]`,
  `onSelect: SingleResult<RecipeServings>`. An `HStack` of capsule buttons, selected ones on
  `surfacesBrandDefault` with `textInverted`, the rest on `surfacesFieldsAndTags`. Each
  carries its option's `accessibilityIdentifier`, `accessibilityLabel`, and
  `.accessibilityAddTraits(.isSelected)` when selected. Minimum 44pt target.
- `RecipeIngredientEntry` — `placeholder: LocalizedStringResource`,
  `fieldAccessibilityIdentifier: String`, `addAccessibilityIdentifier: String`,
  `onAdd: SingleResult<String>`. Owns `@State private var text = ""` and
  `@FocusState private var isFocused: Bool`; the Add button and `.onSubmit` both call
  `onAdd(text)` then clear `text`. The text is local input on its way to the view model, which
  is why it lives here and not there.
- `RecipeIngredientChipRow` — `chips: [RecipeIngredientChipViewModel]`,
  `onRemoveTap: SingleResult<RecipeIngredientChipViewModel>`. A wrapping layout of chips built
  the same way `RecipeFacetChipRow` builds its row; read that file and match it rather than
  inventing a second wrapping strategy.
- `RecipeSearchFooter` — `showsClearAll: Bool`, `onClearAllTap: VoidResult`,
  `onSubmitTap: VoidResult`. Clear all as a plain text button on the leading side, Search as a
  filled capsule on `surfacesBrandDefault` with `textInverted` and a magnifying-glass icon.
  Identifiers `recipe-search-clear-all-button` and `recipe-search-submit-button`. A
  `.ultraThinMaterial` background so content scrolling under it stays legible.

- [ ] **Step 3: Build and check previews compile**

Run the test command from Global Constraints.
Expected: builds clean; SwiftLint (a build plugin) reports nothing.

- [ ] **Step 4: Format**

```bash
swiftformat RecipeTest Tests UITests --lint
```
Expected: no violations. If it reports any, run it without `--lint` and re-check the diff.

- [ ] **Step 5: Commit**

```bash
git add RecipeTest/Modules/RecipeSearch/UI/Components RecipeTest/Mocks/Modules/RecipeSearch
git commit -m "[search] Add the filter overlay's components"
```

---

### Task 6: Level-1 scene

**Files:**
- Create: `RecipeTest/Modules/RecipeSearch/UI/Scenes/RecipeSearchView.swift`
- Create: `RecipeTest/Modules/RecipeSearch/UI/Scenes/RecipeSearchViewCoordinator.swift`

**Interfaces:**
- Consumes: every component from Task 5, `RecipeSearchViewModelProtocol` from Task 4.
- Produces: `RecipeSearchView(viewModel:onClose:onFieldTap:onSubmit:)` and
  `RecipeSearchViewCoordinator(request:onFinish:)` where
  `onFinish: SingleResult<RecipeSearchResult?>` — `nil` means the user closed without applying.

- [ ] **Step 1: Write `RecipeSearchView`**

A `ScrollView` of `RecipeSearchSection`s in the spec's order — What's cooking?, Vegetarian,
Servings, Include, Exclude, Search inside instructions — with `RecipeSearchFooter` pinned
below it outside the scroll view, and a close button in the top trailing corner
(`recipe-search-close-button`). Background `Color.themeColor(.surfacesBackground)`.

Every value comes off `viewModel`; every interaction is a callback into it or out through
`onFieldTap` / `onSubmit` / `onClose`.

Four `#Preview`s off `MockRecipeSearchViewModel`: empty draft, text only, filters only, and
everything set at once.

- [ ] **Step 2: Write `RecipeSearchViewCoordinator`**

```swift
struct RecipeSearchViewCoordinator: ViewCoordinator {
  let onFinish: SingleResult<RecipeSearchResult?>

  @State private var viewModel: RecipeSearchViewModel
  @State private var isEditingQuery = false

  @Namespace private var queryFieldNamespace

  init(
    request: RecipeSearchRequest,
    onFinish: @escaping SingleResult<RecipeSearchResult?>,
    recentSearchStore: RecentSearchStoreProtocol = AppContainer.shared.recentSearchStore
  ) {
    self.onFinish = onFinish
    _viewModel = State(initialValue: RecipeSearchViewModel(
      request: request,
      recentSearchStore: recentSearchStore
    ))
  }
}
```

Its `body` is a `NavigationStack` wrapping `RecipeSearchView`, with
`.navigationDestination(isPresented: $isEditingQuery)` presenting the Task 8 coordinator. Leave
that destination as a one-line `EmptyView()` in this task and wire it in Task 8 — the level-2
scene does not exist yet, and a task should build.

Handlers: `onClose` calls `onFinish(nil)`; `onSubmit` calls `onFinish(viewModel.apply())`;
`onFieldTap` sets `isEditingQuery = true`.

Add the transition source id as a constant, since Task 8 references it:

```swift
// MARK: - Getters > Constants

private extension RecipeSearchViewCoordinator {
  var queryFieldID: String {
    "recipe-search-query-field"
  }
}
```

- [ ] **Step 3: Build**

Run the test command from Global Constraints.
Expected: builds clean.

- [ ] **Step 4: Commit**

```bash
git add RecipeTest/Modules/RecipeSearch/UI/Scenes
git commit -m "[search] Add the filter overlay scene"
```

---

### Task 7: Level-2 view model and suggestion view models

**Files:**
- Create: `RecipeTest/Modules/RecipeSearch/UI/Scenes/RecipeSearchInputViewModelProtocol.swift`
- Create: `RecipeTest/Modules/RecipeSearch/UI/Scenes/RecipeSearchInputViewModel.swift`
- Create: `RecipeTest/Modules/RecipeSearch/UI/Components/RecipeSuggestionRow/RecipeSuggestionRowViewModelProtocol.swift`
- Create: `RecipeTest/Modules/RecipeSearch/UI/Components/RecipeSuggestionRow/RecipeSuggestionRowViewModel.swift`
- Create: `RecipeTest/Modules/RecipeSearch/UI/Components/RecipeSuggestionSection/RecipeSuggestionSectionViewModel.swift`
- Modify: `RecipeTest/Modules/RecipeSearch/UI/RecipeSearch.xcstrings`
- Create: `Tests/Modules/RecipeSearch/UI/Scenes/RecipeSearchInputViewModelTests.swift`
- Create: `Tests/Modules/RecipeSearch/UI/Components/RecipeSuggestionRowViewModelTests.swift`

**Interfaces:**
- Consumes: `RecipeSuggestion` (Task 1), `RecentSearchStoreProtocol` (Task 2),
  `RecipeServiceProtocol` (existing).
- Produces: `RecipeSearchInputViewModelProtocol` with `queryRow`, `sections`, `emptyText`,
  `update(text:) async`, `select(_:) -> RecipeSearchInputSelection`;
  `RecipeSuggestionRowViewModel(suggestion:)`;
  `RecipeSuggestionSectionViewModel(id:title:rows:)`.

- [ ] **Step 1: Write the suggestion view models**

```swift
nonisolated protocol RecipeSuggestionRowViewModelProtocol: Identifiable {
  var id: String { get }
  var title: String { get }
  var detail: String { get }
  var imageURL: URL? { get }

  /// Shown when there is no photograph — a recent search and the "search for this" row have
  /// no image of their own.
  var symbolName: String? { get }
  var accessibilityIdentifier: String { get }
}
```

```swift
nonisolated struct RecipeSuggestionRowViewModel: RecipeSuggestionRowViewModelProtocol {
  let suggestion: RecipeSuggestion
}

// MARK: - Getters

nonisolated extension RecipeSuggestionRowViewModel {
  var id: String {
    switch suggestion {
    case let .query(text):
      "query-\(text)"

    case let .recent(text):
      "recent-\(text)"

    case let .category(category):
      "category-\(category.id)"

    case let .recipe(summary):
      "recipe-\(summary.id)"
    }
  }

  var title: String {
    switch suggestion {
    case let .query(text):
      String(localized: .RecipeSearch.recipeSearchSuggestionQueryTitle(text))

    case let .recent(text):
      text

    case let .category(category):
      category.name

    case let .recipe(summary):
      summary.title
    }
  }

  var detail: String {
    switch suggestion {
    case .query:
      String(localized: .RecipeSearch.recipeSearchSuggestionQueryDetail)

    case .recent:
      String(localized: .RecipeSearch.recipeSearchSuggestionRecentDetail)

    case .category:
      String(localized: .RecipeSearch.recipeSearchSuggestionCategoryDetail)

    case let .recipe(summary):
      summary.cuisine ?? String(localized: .RecipeSearch.recipeSearchSuggestionRecipeDetail)
    }
  }

  var imageURL: URL? {
    switch suggestion {
    case let .category(category):
      category.imageURL

    case let .recipe(summary):
      summary.heroImageURL

    default:
      nil
    }
  }

  var symbolName: String? {
    switch suggestion {
    case .query:
      "magnifyingglass"

    case .recent:
      "clock"

    default:
      nil
    }
  }

  var accessibilityIdentifier: String {
    "recipe-search-suggestion-\(id)"
  }
}
```

Check `RecipeCategory` and `RecipeSummary` for the real property names (`id`, `name`,
`imageURL`, `title`, `cuisine`, `heroImageURL`) and adjust; `RecipeSummary` is used by
`RecipeCardViewModel`, which is the reference.

```swift
nonisolated struct RecipeSuggestionSectionViewModel: Identifiable, Equatable {
  let id: String
  let title: LocalizedStringResource?
  let rows: [RecipeSuggestionRowViewModel]
}
```

`RecipeSuggestionRowViewModel` needs `Equatable` for `SectionState`; add `Equatable` to its
declaration, which `RecipeSuggestion: Hashable` already supports.

- [ ] **Step 2: Write the protocol and the view model**

```swift
/// What the field's suggestion list offers, and what selecting a row means.
nonisolated enum RecipeSearchInputSelection: Equatable {
  /// Fill the field and go back to the filters.
  case text(String)
  /// Leave the overlay entirely and open this recipe.
  case recipe(RecipeSummary)
}

@MainActor
protocol RecipeSearchInputViewModelProtocol: AnyObject, Observable {
  /// Outside `sections` on purpose: this row must survive a slow fetch and a failed one,
  /// because a network problem should never stop somebody searching for what they typed.
  var queryRow: RecipeSuggestionRowViewModel? { get }
  var sections: SectionState<[RecipeSuggestionSectionViewModel]> { get }
  var emptyText: LocalizedStringResource { get }

  func update(text: String) async
  func select(_ row: RecipeSuggestionRowViewModel) -> RecipeSearchInputSelection
}
```

```swift
@Observable
final class RecipeSearchInputViewModel: RecipeSearchInputViewModelProtocol {
  private(set) var sections: SectionState<[RecipeSuggestionSectionViewModel]> = .empty

  private var text: String
  private var categories: [RecipeCategory] = []
  private var hasLoadedCategories = false

  private let recipeService: RecipeServiceProtocol
  private let recentSearchStore: RecentSearchStoreProtocol

  init(
    text: String,
    recipeService: RecipeServiceProtocol = AppContainer.shared.recipeService,
    recentSearchStore: RecentSearchStoreProtocol = AppContainer.shared.recentSearchStore
  ) {
    self.text = text.trimmingCharacters(in: .whitespacesAndNewlines)
    self.recipeService = recipeService
    self.recentSearchStore = recentSearchStore
  }
}

// MARK: - Getters

extension RecipeSearchInputViewModel {
  var queryRow: RecipeSuggestionRowViewModel? {
    guard !text.isEmpty else { return nil }

    return RecipeSuggestionRowViewModel(suggestion: .query(text))
  }

  /// Two messages, because an empty list means two different things: nothing matched what was
  /// typed, or nothing has been searched for yet.
  var emptyText: LocalizedStringResource {
    text.isEmpty
      ? .RecipeSearch.recipeSearchSuggestionEmptyIdle
      : .RecipeSearch.recipeSearchSuggestionEmptyMatches
  }
}

// MARK: - Inputs

extension RecipeSearchInputViewModel {
  /// Called from `.task(id: text)`, so SwiftUI cancels the previous call as the next
  /// keystroke lands: the sleep below is the debounce, and cancellation is what enforces it.
  func update(text: String) async {
    self.text = text.trimmingCharacters(in: .whitespacesAndNewlines)

    guard !self.text.isEmpty else {
      sections = .rows(recentSections)
      return
    }

    let previous = sections
    sections = previous.refreshing

    do {
      try await Task.sleep(for: debounce)

      await loadCategoriesIfNeeded()

      let page = try await recipeService.getRecipes(
        query: RecipeQuery(searchText: self.text),
        page: suggestionPage
      )

      try Task.checkCancellation()

      sections = .rows(matchSections(for: page.recipes))
    } catch {
      sections = previous.recovering(from: error)
    }
  }

  func select(_ row: RecipeSuggestionRowViewModel) -> RecipeSearchInputSelection {
    switch row.suggestion {
    case let .query(text), let .recent(text):
      .text(text)

    case let .category(category):
      .text(category.name)

    case let .recipe(summary):
      .recipe(summary)
    }
  }
}

// MARK: - Helpers

private extension RecipeSearchInputViewModel {
  var recentSections: [RecipeSuggestionSectionViewModel] {
    let rows = recentSearchStore.searches
      .prefix(recentLimit)
      .map { RecipeSuggestionRowViewModel(suggestion: .recent($0)) }

    guard !rows.isEmpty else { return [] }

    return [RecipeSuggestionSectionViewModel(
      id: "recent",
      title: .RecipeSearch.recipeSearchSuggestionSectionRecent,
      rows: Array(rows)
    )]
  }

  /// Fetched once and matched in memory: the list is small, and a request per keystroke for a
  /// collection that does not change between them would be traffic for nothing.
  func loadCategoriesIfNeeded() async {
    guard !hasLoadedCategories else { return }

    categories = (try? await recipeService.getCategories()) ?? []
    hasLoadedCategories = true
  }

  func matchSections(for recipes: [RecipeSummary]) -> [RecipeSuggestionSectionViewModel] {
    var sections: [RecipeSuggestionSectionViewModel] = []

    let matchedCategories = categories.filter {
      $0.name.localizedCaseInsensitiveContains(text)
    }

    if !matchedCategories.isEmpty {
      sections.append(RecipeSuggestionSectionViewModel(
        id: "categories",
        title: .RecipeSearch.recipeSearchSuggestionSectionCategories,
        rows: matchedCategories.map { RecipeSuggestionRowViewModel(suggestion: .category($0)) }
      ))
    }

    if !recipes.isEmpty {
      sections.append(RecipeSuggestionSectionViewModel(
        id: "recipes",
        title: .RecipeSearch.recipeSearchSuggestionSectionRecipes,
        rows: recipes
          .prefix(recipeLimit)
          .map { RecipeSuggestionRowViewModel(suggestion: .recipe($0)) }
      ))
    }

    return sections
  }
}

// MARK: - Getters > Constants

private extension RecipeSearchInputViewModel {
  var debounce: Duration {
    .milliseconds(300)
  }

  var recentLimit: Int {
    4
  }

  var recipeLimit: Int {
    8
  }

  var suggestionPage: Page {
    Page(
      index: 1,
      size: 8
    )
  }
}
```

- [ ] **Step 3: Add the strings**

| Key | Value |
| --- | --- |
| `recipeSearch.input.back.accessibilityLabel` | `Back` |
| `recipeSearch.suggestion.query.title` | `Search for “%@”` |
| `recipeSearch.suggestion.query.detail` | `Use this as your search` |
| `recipeSearch.suggestion.recent.detail` | `Recent search` |
| `recipeSearch.suggestion.category.detail` | `Category` |
| `recipeSearch.suggestion.recipe.detail` | `Recipe` |
| `recipeSearch.suggestion.section.recent` | `Recent searches` |
| `recipeSearch.suggestion.section.categories` | `Categories` |
| `recipeSearch.suggestion.section.recipes` | `Recipes` |
| `recipeSearch.suggestion.empty.matches` | `No recipe names match. You can still search for it.` |
| `recipeSearch.suggestion.empty.idle` | `Your recent searches will show up here.` |

- [ ] **Step 4: Write the tests**

```swift
@MainActor
struct RecipeSearchInputViewModelTests {
  @Test func emptyTextRendersRecentsAndMakesNoRequest() async {
    let service = MockRecipeService()
    let store = MockRecentSearchStore()
    store.searches = ["adobo", "pho"]
    let viewModel = makeViewModel(
      service: service,
      store: store
    )

    await viewModel.update(text: "")

    #expect(viewModel.queryRow == nil)
    #expect(viewModel.sections.value?.first?.rows.count == 2)
    #expect(service.recipes.requests.isEmpty)
  }

  @Test func offersTheTypedTextAsItsOwnRow() async {
    let viewModel = makeViewModel()

    await viewModel.update(text: "ado")

    #expect(viewModel.queryRow?.title.contains("ado") == true)
  }

  @Test func matchesCategoriesCaseInsensitively() async {
    let service = MockRecipeService(categories: [.dummy(name: "Desserts")])
    let viewModel = makeViewModel(service: service)

    await viewModel.update(text: "dess")

    let titles = viewModel.sections.value?.flatMap { $0.rows.map(\.title) } ?? []
    #expect(titles.contains("Desserts"))
  }

  @Test func rendersTheEmptyStateWhenNothingMatches() async {
    let service = MockRecipeService(
      recipes: RecipeListPage(
        recipes: [],
        meta: .dummy(total: 0)
      ),
      categories: []
    )
    let viewModel = makeViewModel(service: service)

    await viewModel.update(text: "zzzz")

    #expect(viewModel.sections == .empty)
    #expect(viewModel.queryRow != nil)
  }

  @Test func keepsTheQueryRowWhenTheFetchFails() async {
    let service = MockRecipeService()
    service.recipes.result = .failure(AppError.unknown)
    let viewModel = makeViewModel(service: service)

    await viewModel.update(text: "ado")

    #expect(viewModel.queryRow != nil)

    guard case .failed = viewModel.sections else {
      Issue.record("Expected a failed state")
      return
    }
  }

  @Test func aCancelledFetchPaintsNeitherAnErrorNorASpinner() async {
    let service = MockRecipeService()
    service.recipes.result = .failure(CancellationError())
    let viewModel = makeViewModel(service: service)

    await viewModel.update(text: "ado")

    #expect(viewModel.sections != .loading)

    guard case .failed = viewModel.sections else { return }

    Issue.record("A cancelled fetch must not paint an error")
  }

  @Test func selectingARecipeReturnsIt() async {
    let summary = RecipeSummary.dummy(id: "rcp-007")
    let viewModel = makeViewModel()

    let selection = viewModel.select(RecipeSuggestionRowViewModel(suggestion: .recipe(summary)))

    #expect(selection == .recipe(summary))
  }

  @Test func selectingACategoryFillsTheFieldWithItsName() async {
    let category = RecipeCategory.dummy(name: "Desserts")
    let viewModel = makeViewModel()

    let selection = viewModel.select(RecipeSuggestionRowViewModel(suggestion: .category(category)))

    #expect(selection == .text("Desserts"))
  }
}

// MARK: - Helpers

private extension RecipeSearchInputViewModelTests {
  func makeViewModel(
    text: String = "",
    service: MockRecipeService = MockRecipeService(),
    store: RecentSearchStoreProtocol = MockRecentSearchStore()
  ) -> RecipeSearchInputViewModel {
    RecipeSearchInputViewModel(
      text: text,
      recipeService: service,
      recentSearchStore: store
    )
  }
}
```

Check `MockAPICall`'s failure API and `AppError`'s cases before writing the two failure tests,
and use whatever the existing `RecipeListViewModelTests` cancellation test uses.

Add a small `RecipeSuggestionRowViewModelTests` covering: the query row's title splices the
text in; a recent row's symbol is the clock and its image is nil; a recipe row carries the
summary's hero image.

- [ ] **Step 5: Run the tests**

Run the test command from Global Constraints.
Expected: every new test passes. The 300 ms sleep makes these tests take about a second
each — that is the debounce doing its job, not a hang.

- [ ] **Step 6: Commit**

```bash
git add RecipeTest/Modules/RecipeSearch Tests/Modules/RecipeSearch
git commit -m "[search] Add the suggestion view model behind the search field"
```

---

### Task 8: Level-2 scene

**Files:**
- Create: `RecipeTest/Modules/RecipeSearch/UI/Components/RecipeSuggestionRow/RecipeSuggestionRow.swift`
- Create: `RecipeTest/Modules/RecipeSearch/UI/Components/RecipeSuggestionSection/RecipeSuggestionSection.swift`
- Create: `RecipeTest/Modules/RecipeSearch/UI/Scenes/RecipeSearchInputView.swift`
- Create: `RecipeTest/Modules/RecipeSearch/UI/Scenes/RecipeSearchInputViewCoordinator.swift`
- Create: `RecipeTest/Mocks/Modules/RecipeSearch/UI/Scenes/RecipeSearchInput/MockRecipeSearchInputViewModel.swift`
- Modify: `RecipeTest/Modules/RecipeSearch/UI/Scenes/RecipeSearchViewCoordinator.swift`

**Interfaces:**
- Consumes: Task 7's view model and row/section view models.
- Produces: `RecipeSearchInputViewCoordinator(text:onFinish:)` where
  `onFinish: SingleResult<RecipeSearchInputSelection?>` — `nil` means the back button.

- [ ] **Step 1: Write the two components**

- `RecipeSuggestionRow` — `viewModel: any RecipeSuggestionRowViewModelProtocol`,
  `onTap: VoidResult`. A 44×44 leading tile: `CachedAsyncImage` when `imageURL` is non-nil,
  otherwise the `symbolName` on `surfacesFieldsAndTags`. Title in `.bodyBold`, detail in
  `.footnoteRegular`/`textSecondary`. Carries the view model's `accessibilityIdentifier`.
- `RecipeSuggestionSection` — `viewModel: RecipeSuggestionSectionViewModel`,
  `onRowTap: SingleResult<RecipeSuggestionRowViewModel>`. The optional title in
  `.subheadlineSemibold`/`textSecondary`, then one `RecipeSuggestionRow` per row.

- [ ] **Step 2: Write `RecipeSearchInputView`**

A back button and a focused `TextField` in the header, then the query row, then
`SectionStateView` over `viewModel.sections` rendering a `RecipeSuggestionSection` each.

```swift
struct RecipeSearchInputView: View {
  let viewModel: any RecipeSearchInputViewModelProtocol
  let onBackTap: VoidResult
  let onSelect: SingleResult<RecipeSuggestionRowViewModel>
  let onSubmit: SingleResult<String>

  @State private var text: String
  @FocusState private var isFocused: Bool
```

The field is `TextField(…, text: $text)` with `.submitLabel(.search)` and
`.onSubmit { onSubmit(text) }`, identifier `recipe-search-input-field`, and
`.task(id: text) { await viewModel.update(text: text) }` driving the suggestions — which is
what makes SwiftUI cancel the in-flight fetch on every keystroke. `.onAppear { isFocused = true }`.

`init(…)` seeds `_text = State(initialValue: text)`.

Five `#Preview`s off `MockRecipeSearchInputViewModel`: idle with recents, idle with none,
typed with matches, loading, failed.

- [ ] **Step 3: Write `RecipeSearchInputViewCoordinator`**

Holds a `@State private var viewModel: RecipeSearchInputViewModel` built from `text`, and maps
`onSelect` through `viewModel.select(_:)` into `onFinish(...)`. `onSubmit` calls
`onFinish(.text(submitted))` directly — typing a term and hitting return is the same act as
picking the "Search for '…'" row.

- [ ] **Step 4: Wire it into `RecipeSearchViewCoordinator`**

Replace the `EmptyView()` destination from Task 6:

```swift
      .navigationDestination(isPresented: $isEditingQuery) {
        RecipeSearchInputViewCoordinator(
          text: viewModel.hasFieldText ? viewModel.fieldText : "",
          onFinish: handleInputFinish()
        )
        .navigationTransition(.zoom(
          sourceID: queryFieldID,
          in: queryFieldNamespace
        ))
        .toolbarVisibility(
          .hidden,
          for: .navigationBar
        )
      }
```

with the field button carrying `.matchedTransitionSource(id: queryFieldID, in: queryFieldNamespace)`,
and:

```swift
  func handleInputFinish() -> SingleResult<RecipeSearchInputSelection?> {
    { selection in
      isEditingQuery = false

      switch selection {
      case let .text(text):
        viewModel.set(searchText: text)

      case let .recipe(summary):
        onFinish(.openRecipe(summary))

      case nil:
        break
      }
    }
  }
```

If `.navigationTransition(.zoom(...))` fights the `fullScreenCover`, drop the modifier — the
push still works, and a missing flourish is not worth a broken screen. Note it in the commit
message if you do.

- [ ] **Step 5: Build and run the tests**

Run the test command from Global Constraints.
Expected: builds clean, suite green.

- [ ] **Step 6: Commit**

```bash
git add RecipeTest/Modules/RecipeSearch RecipeTest/Mocks/Modules/RecipeSearch
git commit -m "[search] Add the typing screen and its suggestions"
```

---

### Task 9: Open the overlay from Home and from a results list

**Files:**
- Modify: `RecipeTest/Coordinators/HomeViewCoordinator.swift`
- Modify: `RecipeTest/Modules/RecipeList/UI/RecipeListViewCoordinator.swift`
- Create: `Tests/Modules/RecipeSearch/UI/Scenes/RecipeSearchApplyTests.swift`

**Interfaces:**
- Consumes: `RecipeSearchViewCoordinator(request:onFinish:)`, `RecipeSearchRequest`,
  `RecipeSearchResult`, `RecipeListViewModel.apply(query:)`.
- Produces: nothing new. Both `// TODO` handlers are gone after this task.

- [ ] **Step 1: Wire Home**

```swift
  @State private var searchRequest: RecipeSearchRequest?
```

```swift
    HomeView(...)
      .fullScreenCover(item: $searchRequest) { request in
        RecipeSearchViewCoordinator(
          request: request,
          onFinish: handleSearchFinish
        )
      }
```

```swift
  var handleSearchTap: VoidResult {
    { searchRequest = RecipeSearchRequest(query: .empty) }
  }

  var handleSearchFinish: SingleResult<RecipeSearchResult?> {
    { result in
      searchRequest = nil

      switch result {
      case let .apply(query):
        let searchText = query.searchText ?? ""

        pathRouter.push(Route.Recipe.list(
          searchText.isEmpty
            ? .all(query: query)
            : .search(
                searchText,
                query: query
              )
        ))

      case let .openRecipe(summary):
        pathRouter.push(Route.Recipe.detail(summary))

      case nil:
        break
      }
    }
  }
```

- [ ] **Step 2: Wire the results list**

The same `@State` and cover, opened with the *applied* query so the overlay comes up showing
what the list is already filtered by:

```swift
  func handleSearchTap() -> VoidResult {
    { searchRequest = RecipeSearchRequest(query: viewModel.query) }
  }

  func handleSearchFinish() -> SingleResult<RecipeSearchResult?> {
    { result in
      searchRequest = nil

      switch result {
      case let .apply(query):
        Task { await viewModel.apply(query: query) }

      case let .openRecipe(summary):
        pathRouter.push(Route.Recipe.detail(summary))

      case nil:
        break
      }
    }
  }
```

`viewModel.query` is readable after Task 3. Add `var query: RecipeQuery { get }` to
`RecipeListViewModelProtocol` and to `MockRecipeListViewModel` — the coordinator holds the
concrete `RecipeListViewModel`, so this is only needed if the coordinator's type is the
existential; check before adding, and do not add a protocol member nothing reads.

- [ ] **Step 3: Pin the discard behaviour**

```swift
@MainActor
struct RecipeSearchApplyTests {
  @Test func closingWithoutApplyingLeavesTheListUntouched() async {
    let service = MockRecipeService()
    let list = RecipeListViewModel(
      query: RecipeQuery(category: "Desserts"),
      recipeService: service
    )
    await list.loadFirstPage()
    let requestsBefore = service.recipes.requests.count

    // What the overlay does when it is opened, edited and closed with the X: it hands back
    // nothing, and the list is never asked for a new query.
    let overlay = RecipeSearchViewModel(
      request: RecipeSearchRequest(query: list.query),
      recentSearchStore: MockRecentSearchStore()
    )
    overlay.toggleVegetarian()
    overlay.addInclude("garlic")

    #expect(service.recipes.requests.count == requestsBefore)
    #expect(list.facetChips.isEmpty)
  }

  @Test func applyingCarriesTheCategoryThrough() async {
    let service = MockRecipeService()
    let list = CategoryRecipeListViewModel(
      categoryName: "Desserts",
      query: RecipeQuery(category: "Desserts"),
      recipeService: service
    )
    let overlay = RecipeSearchViewModel(
      request: RecipeSearchRequest(query: list.query),
      recentSearchStore: MockRecentSearchStore()
    )
    overlay.toggleVegetarian()

    guard case let .apply(query) = overlay.apply() else {
      Issue.record("apply() did not return .apply")
      return
    }
    await list.apply(query: query)

    #expect(service.recipes.requests.last?.query.category == "Desserts")
    #expect(service.recipes.requests.last?.query.isVegetarian == true)
    #expect(list.title == "Desserts")
  }
}
```

- [ ] **Step 4: Build, test, and run it on the simulator**

Run the test command from Global Constraints, then launch the app and walk the journey by
hand: open the overlay from Home, set a filter, apply, reopen from the list, change it, apply
again, and confirm the back button returns to Home rather than to another list.

- [ ] **Step 5: Commit**

```bash
git add RecipeTest Tests
git commit -m "[search] Open the overlay from Home and from a results list"
```

---

### Task 10: End-to-end flow and the final pass

**Files:**
- Create: `.maestro/search-and-filter.yaml`
- Modify: `.maestro/README.md`

**Interfaces:**
- Consumes: every accessibility identifier added in Tasks 5, 6 and 8.

- [ ] **Step 1: Write the flow**

```yaml
# Home -> the search overlay -> a filtered results list -> the overlay again, in place.
# The journey the overlay exists for: the draft, the apply, and the refresh that must not
# push a second list.
appId: com.danjan.recipe
---
- launchApp

- assertVisible:
    id: "recipe-search-pill-button"
- tapOn:
    id: "recipe-search-pill-button"

# The overlay is up, showing an untouched draft.
- assertVisible:
    id: "recipe-search-field-button"
- assertVisible:
    id: "recipe-search-submit-button"

# A filter, then a search.
- tapOn:
    id: "recipe-search-vegetarian-toggle"
- tapOn:
    id: "recipe-search-include-field"
- inputText: "garlic"
- tapOn:
    id: "recipe-search-include-add-button"
- assertVisible:
    id: "recipe-search-include-chip-garlic-remove-button"
- tapOn:
    id: "recipe-search-submit-button"

# The results list is showing, carrying the filters as chips.
- assertVisible:
    id: "recipe-list-result-count-label"
- assertVisible:
    id: "recipe-search-pill-button"

# Reopening from the list refreshes in place: one back tap reaches Home.
- tapOn:
    id: "recipe-search-pill-button"
- tapOn:
    id: "recipe-search-clear-all-button"
- tapOn:
    id: "recipe-search-submit-button"
- assertVisible:
    id: "recipe-list-result-count-label"
- back
- assertVisible:
    id: "home-category-tile-cat-04"
```

- [ ] **Step 2: Run it**

```bash
xcodebuild build -project RecipeTest.xcodeproj -scheme RecipeTest \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -derivedDataPath build
xcrun simctl install booted build/Build/Products/Debug-iphonesimulator/RecipeTest.app
maestro test .maestro/search-and-filter.yaml
```

Expected: the flow reaches the end. The scheme is `RecipeTest`, not `RecipeTest-Staging` —
building the wrong one tests a stale app.

- [ ] **Step 3: Add the new identifiers to the README's selector table**

One row each for `recipe-search-field-button`, `recipe-search-vegetarian-toggle`,
`recipe-search-servings-option-<n>`, `recipe-search-include-chip-<ingredient>-remove-button`,
`recipe-search-submit-button`, `recipe-search-clear-all-button`,
`recipe-search-input-field`, `recipe-search-suggestion-<kind>-<value>`.

- [ ] **Step 4: Full pass**

```bash
swiftformat RecipeTest Tests UITests --lint
```
then the test command from Global Constraints, then the three existing flows
(`browse-a-category`, `switch-result-layout`, `leave-a-results-list`) to prove the pill change
did not break them.

Expected: format clean, suite green, four flows green.

- [ ] **Step 5: Commit**

```bash
git add .maestro
git commit -m "[search] Add an end-to-end flow for the search journey"
```
