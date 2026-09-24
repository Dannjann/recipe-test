# Recipe List Screen Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the Bokkie Bites results list — a paginated grid/list of recipes with a result count, removable filter chips and an inert search pill — reached by tapping a category on Home, and reusable unchanged by the search overlay and filter sheet that come later.

**Architecture:** A new `Modules/RecipeList/` module. `Route.Recipe.list(RecipeListRequest)` carries a `RecipeQuery` plus what the list is *of*, so the screen never learns why it was opened. `RecipeListViewModel` owns the mutable query, the page cursor and the paging flags, and maps each fetched page into `RecipeCardViewModel` values once. Every value a view renders comes from a view model behind a protocol — no view derives, formats or pluralises anything.

**Tech Stack:** Swift 6, SwiftUI, iOS 26.3 deployment target, `@Observable`, Swift Testing (`@Test`/`#expect`), Kingfisher via the project's `CachedAsyncImage`, string catalogs (`.xcstrings`).

**Spec:** `docs/superpowers/specs/2026-09-24-recipe-list-design.md`

## Global Constraints

- Indentation is 2 spaces. Max line length 120.
- Every new app-target type is declared `nonisolated` unless it must be main-actor. The app target sets `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`; the test target sets `nonisolated`.
- Every file opens with the project's header comment block: filename, `RecipeTest` (or `Tests`), `Created by Danjan ( https://github.com/Dannjann )`, `Copyright © 2026 Danjan. All rights reserved.`
- `// MARK: - Type` before a type, `// MARK: Section` inside one. Members grouped into MARK'd extensions, not one long body.
- No colour, font size or text literal is hardcoded. Colours go through `Color.themeColor(_:)` / `.themeColor(_:)`, fonts through `.themeTextStyle(_:)`, copy through `String(localized:)` or `LocalizedStringResource` against a string catalog.
- Every numeric constant a view uses is a computed `var` in a `// MARK: - Getters` extension, never a literal at the call site.
- Every call with two or more arguments wraps one argument per line, regardless of length.
- Comments explain only what the code cannot say itself. No narration.
- Every tappable element is a `Button`. Never `.onTapGesture`.
- Never `AnyView`. `AnyLayout` is permitted. Never split a screen into `private var someSection: some View` — extract a real `View` type. Small chrome (a logo, a badge) may stay a computed property.
- Every new `View` type gets a `#Preview`, and every `#Preview` and everything under `RecipeTest/Mocks/` is wrapped in `#if DEBUG`.
- The Xcode project uses `fileSystemSynchronizedGroups`. Never edit `RecipeTest.xcodeproj/project.pbxproj`.
- Commit messages: `[list] <imperative message>`, ≤72 characters, no trailing period. No `Co-Authored-By` trailer.
- Branch is `feat/dan/recipe-list`, already created off `feat/dan/recipe-detail` at `4fdfef0`.

**Build and test command** (used by every verification step; substitute the simulator name if that device is absent):

```bash
xcodebuild test -project RecipeTest.xcodeproj -scheme RecipeTest \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:Tests 2>&1 | tail -40
```

To run one suite while iterating:

```bash
xcodebuild test -project RecipeTest.xcodeproj -scheme RecipeTest \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:Tests/RecipeListViewModelTests 2>&1 | tail -40
```

To find a destination `xcodebuild` will actually accept:

```bash
xcodebuild -showdestinations -project RecipeTest.xcodeproj -scheme RecipeTest 2>&1 | grep -v error:
```

To build without running tests, when a task changes only views:

```bash
xcodebuild build -project RecipeTest.xcodeproj -scheme RecipeTest \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -20
```

## Review Focus

Five conditions the spec implies that a naive implementation gets wrong. Each has a test in the task that owns the code, noted inline.

1. **Two pages must never be in flight at once, and a page must never be appended twice.** `.onAppear` on the tail card fires again when the user scrolls it back into view, and again when the next page's rows push it around. Without an `isLoadingNextPage` guard the same page is requested repeatedly; without an id filter on append, a server that repeats a row puts a duplicate id into a `ForEach` and SwiftUI's diffing goes wrong. *Tested in Task 8.*
2. **A facet removed while a page is in flight must not have that page land on the new result set.** `remove(facet:)` re-queries from page 1, but the in-flight next page for the *old* query resolves afterwards and would append rows that no longer match. The generation counter has to cover the pager, not just the first load. *Tested in Task 9.*
3. **A cancelled next page must leave no error and no spinner.** SwiftUI cancels the `.task` on disappear; the in-flight `getRecipes` throws `CancellationError` or `URLError.cancelled`. `isLoadingNextPage` must clear, `nextPageError` must stay nil, and the cursor must not advance — otherwise walking away from the screen leaves a failure waiting for the next visit. *Tested in Task 8.*
4. **A result set that fits in one page must never ask for a second.** `hasLoadedAllData` is `total <= perPage || currentPage >= lastPage`. Every category in the fixture returns about six of the thirty-six recipes, so this is the *only* path the category entry point exercises — if `nextPage` is set anyway, the screen requests empty pages forever on the one flow that ships today. *Tested in Task 8.*
5. **A recipe carrying neither a time nor a servings count must still render and still announce something.** `totalTimeMinutes` and `servings` are both `Int?`, and `cuisine` and `category` are both `String?`. Every derived string must be `nil` rather than empty or `"nil"`, the metadata row must collapse rather than draw stray separators, and the accessibility label must fall back to the title alone. *Tested in Task 5, previewed in Task 10.*

---

## File Structure

**Created:**

| File | Responsibility |
| --- | --- |
| `RecipeTest/Modules/Recipe/Models/Domain/RecipeQueryFacet.swift` | The facet enum, plus `RecipeQuery.activeFacets` / `removing(_:)` / `clearingFacets()` |
| `RecipeTest/Modules/RecipeList/Models/RecipeListRequest.swift` | The route payload: a query plus what the list is of |
| `RecipeTest/Modules/RecipeList/Models/RecipeListViewMode.swift` | `.grid` / `.list` |
| `RecipeTest/Modules/RecipeList/UI/RecipeList.xcstrings` | Every string the module renders |
| `RecipeTest/Modules/RecipeList/UI/Scenes/RecipeListViewModel.swift` | Query state, paging, mapping to card view models |
| `RecipeTest/Modules/RecipeList/UI/Scenes/RecipeListViewModelProtocol.swift` | What the scene and its chrome depend on |
| `RecipeTest/Modules/RecipeList/UI/Scenes/RecipeListView.swift` | Screen layout |
| `RecipeTest/Modules/RecipeList/UI/RecipeListViewCoordinator.swift` | Owns the view model, wires taps to `PathRouter` |
| `RecipeTest/Modules/RecipeList/UI/Components/RecipeCardViewModel.swift` | One row's presentation values |
| `RecipeTest/Modules/RecipeList/UI/Components/RecipeCardViewModelProtocol.swift` | What `RecipeCard` and `RecipeRow` depend on |
| `RecipeTest/Modules/RecipeList/UI/Components/RecipeCardMetadata.swift` | The clock-and-servings strip both presentations draw |
| `RecipeTest/Modules/RecipeList/UI/Components/RecipeCard.swift` | Grid presentation |
| `RecipeTest/Modules/RecipeList/UI/Components/RecipeRow.swift` | List presentation |
| `RecipeTest/Modules/RecipeList/UI/Components/RecipeFacetChipViewModel.swift` | One chip's label and identity |
| `RecipeTest/Modules/RecipeList/UI/Components/RecipeFacetChipViewModelProtocol.swift` | What `RecipeFacetChip` depends on |
| `RecipeTest/Modules/RecipeList/UI/Components/RecipeFacetChip.swift` | One removable chip |
| `RecipeTest/Modules/RecipeList/UI/Components/RecipeFacetChipRow.swift` | The wrapping row of chips plus "Clear all" |
| `RecipeTest/Modules/RecipeList/UI/Components/RecipeListToolbar.swift` | Count on the leading edge, view-mode toggle on the trailing |
| `RecipeTest/Modules/RecipeList/UI/Components/RecipeListViewModeToggle.swift` | The segmented grid/list control |
| `RecipeTest/Modules/RecipeList/UI/Components/RecipeListResults.swift` | Switches on `SectionState`, owns the grid/list morph |
| `RecipeTest/Modules/RecipeList/UI/Components/RecipeListEmptyState.swift` | Empty copy plus the optional Clear filters action |
| `RecipeTest/Modules/RecipeList/UI/Components/RecipeListFooter.swift` | Paging spinner, paging retry, or nothing |
| `RecipeTest/Modules/Shared/UI/Components/RecipeSearchPill.swift` | `HomeSearchPill`, moved, with the placeholder as a parameter |
| `RecipeTest/Mocks/Modules/RecipeList/UI/Scenes/RecipeList/MockRecipeListViewModel.swift` | Preview scenarios for the whole screen |
| `Tests/Modules/Recipe/Models/RecipeQueryFacetTests.swift` | Facet derivation and removal |
| `Tests/Modules/RecipeList/Models/RecipeListRequestTests.swift` | The factories keep query and title in step |
| `Tests/Modules/RecipeList/UI/Components/RecipeCardViewModelTests.swift` | Duration, cuisine·category, accessibility label |
| `Tests/Modules/RecipeList/UI/Components/RecipeFacetChipViewModelTests.swift` | One label per facet |
| `Tests/Modules/RecipeList/UI/Scenes/RecipeListViewModelTests.swift` | Loading, paging, facets, counts |

**Modified:**

| File | Change |
| --- | --- |
| `RecipeTest/Modules/Recipe/Models/Domain/RecipeQuery.swift` | `Equatable` → `Hashable`, so it can ride a `NavigationPath` |
| `RecipeTest/Navigation/Route.swift` | Add `case list(RecipeListRequest)` |
| `RecipeTest/Coordinators/AppCoordinator.swift` | Handle the new route case |
| `RecipeTest/Coordinators/HomeViewCoordinator.swift` | `handleCategoryTap` pushes the list |
| `RecipeTest/Modules/Home/UI/Scenes/HomeView.swift` | `HomeSearchPill` → `RecipeSearchPill(placeholder:onTap:)` |
| `RecipeTest/Modules/Home/UI/Components/HomeSearchPill.swift` | Deleted — moved to Shared |

---

## Task 1: Recipe query facets

**Files:**
- Create: `RecipeTest/Modules/Recipe/Models/Domain/RecipeQueryFacet.swift`
- Modify: `RecipeTest/Modules/Recipe/Models/Domain/RecipeQuery.swift` (the type declaration line only)
- Test: `Tests/Modules/Recipe/Models/RecipeQueryFacetTests.swift`

**Interfaces:**
- Consumes: `RecipeQuery`, `RecipeServings` (both already exist in `Modules/Recipe/Models/Domain/RecipeQuery.swift`).
- Produces: `RecipeQueryFacet` with cases `.vegetarian(Bool)`, `.servings(RecipeServings)`, `.include(String)`, `.exclude(String)`, `.searchesSteps`; and on `RecipeQuery`: `var activeFacets: [RecipeQueryFacet]`, `func removing(_ facet: RecipeQueryFacet) -> RecipeQuery`, `func clearingFacets() -> RecipeQuery`. `RecipeQuery` becomes `Hashable`.

`.vegetarian` carries a `Bool` rather than being a bare case because `RecipeQuery.isVegetarian` is `Bool?` and the encoder deliberately keeps `false` — "that is a filter the user set, not an absence". A bare case could not tell a vegetarian-only list from a non-vegetarian-only one.

- [ ] **Step 1: Write the failing tests**

Create `Tests/Modules/Recipe/Models/RecipeQueryFacetTests.swift`:

```swift
//
//  RecipeQueryFacetTests.swift
//  Tests
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation
@testable import RecipeTest
import Testing

struct RecipeQueryFacetTests {
  @Test
  func activeFacets_emptyQuery_isEmpty() {
    #expect(RecipeQuery.empty.activeFacets.isEmpty)
  }

  @Test
  func activeFacets_vegetarianFalse_isStillAFacet() {
    let query = RecipeQuery(isVegetarian: false)

    #expect(query.activeFacets == [.vegetarian(false)])
  }

  @Test
  func activeFacets_everyFacetSet_listsThemInDisplayOrder() {
    let query = RecipeQuery(
      isVegetarian: true,
      servings: .four,
      includeIngredients: ["garlic"],
      excludeIngredients: ["peanuts"],
      searchesSteps: true
    )

    #expect(query.activeFacets == [
      .vegetarian(true),
      .servings(.four),
      .include("garlic"),
      .exclude("peanuts"),
      .searchesSteps,
    ])
  }

  @Test
  func activeFacets_categorySearchTextAndSort_areNotFacets() {
    let query = RecipeQuery(
      searchText: "adobo",
      category: "Desserts",
      sort: .latest
    )

    #expect(query.activeFacets.isEmpty)
  }

  @Test
  func removing_dropsOnlyTheNamedFacet() {
    let query = RecipeQuery(
      isVegetarian: true,
      servings: .two
    )

    let result = query.removing(.vegetarian(true))

    #expect(result.isVegetarian == nil)
    #expect(result.servings == .two)
  }

  @Test
  func removing_anIngredient_leavesItsSiblings() {
    let query = RecipeQuery(includeIngredients: [
      "garlic",
      "onion",
    ])

    let result = query.removing(.include("garlic"))

    #expect(result.includeIngredients == ["onion"])
  }

  @Test
  func removing_keepsTheCategoryAndSearchText() {
    let query = RecipeQuery(
      searchText: "adobo",
      category: "Meal",
      isVegetarian: true
    )

    let result = query.removing(.vegetarian(true))

    #expect(result.searchText == "adobo")
    #expect(result.category == "Meal")
  }

  @Test
  func clearingFacets_dropsEveryFacetAndKeepsTheScope() {
    let query = RecipeQuery(
      searchText: "adobo",
      category: "Meal",
      isVegetarian: false,
      servings: .sixOrMore,
      includeIngredients: ["garlic"],
      excludeIngredients: ["peanuts"],
      searchesSteps: true
    )

    let result = query.clearingFacets()

    #expect(result.activeFacets.isEmpty)
    #expect(result.searchText == "adobo")
    #expect(result.category == "Meal")
  }
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run the single-suite command with `-only-testing:Tests/RecipeQueryFacetTests`.
Expected: FAIL to compile — "value of type 'RecipeQuery' has no member 'activeFacets'".

- [ ] **Step 3: Make `RecipeQuery` hashable**

In `RecipeTest/Modules/Recipe/Models/Domain/RecipeQuery.swift`, change only the type declaration:

```swift
nonisolated struct RecipeQuery: APIRequestParameters, Hashable {
```

A `NavigationPath` value must be `Hashable`, and `RecipeQuery` now rides one inside `RecipeListRequest`. `Hashable` refines `Equatable`, so nothing that compared two queries changes.

- [ ] **Step 4: Write the facet enum and the three helpers**

Create `RecipeTest/Modules/Recipe/Models/Domain/RecipeQueryFacet.swift`:

```swift
//
//  RecipeQueryFacet.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

/// One filter a results list shows as a removable chip.
///
/// `category` and `searchText` are deliberately absent: both are already the list's title,
/// and a chip that removed the category would leave the list showing everything under a
/// heading that still said "Desserts". `sort` is absent because the user never sets it.
nonisolated enum RecipeQueryFacet: Hashable {
  case vegetarian(Bool)
  case servings(RecipeServings)
  case include(String)
  case exclude(String)
  case searchesSteps
}

// MARK: - Getters

nonisolated extension RecipeQuery {
  /// Ordered as the prototype's chip row orders them, so the row is stable across reloads.
  var activeFacets: [RecipeQueryFacet] {
    var facets: [RecipeQueryFacet] = []

    if let isVegetarian {
      facets.append(.vegetarian(isVegetarian))
    }

    if let servings {
      facets.append(.servings(servings))
    }

    facets.append(contentsOf: includeIngredients.map(RecipeQueryFacet.include))
    facets.append(contentsOf: excludeIngredients.map(RecipeQueryFacet.exclude))

    if searchesSteps {
      facets.append(.searchesSteps)
    }

    return facets
  }
}

// MARK: - Removal

nonisolated extension RecipeQuery {
  func removing(_ facet: RecipeQueryFacet) -> RecipeQuery {
    var query = self

    switch facet {
    case .vegetarian:
      query.isVegetarian = nil

    case .servings:
      query.servings = nil

    case let .include(ingredient):
      query.includeIngredients.removeAll { $0 == ingredient }

    case let .exclude(ingredient):
      query.excludeIngredients.removeAll { $0 == ingredient }

    case .searchesSteps:
      query.searchesSteps = false
    }

    return query
  }

  /// Drops every facet and keeps what scopes the list — its category and its search text.
  func clearingFacets() -> RecipeQuery {
    var query = self
    query.isVegetarian = nil
    query.servings = nil
    query.includeIngredients = []
    query.excludeIngredients = []
    query.searchesSteps = false

    return query
  }
}
```

- [ ] **Step 5: Run the tests to verify they pass**

Run the single-suite command with `-only-testing:Tests/RecipeQueryFacetTests`.
Expected: PASS, 8 tests.

- [ ] **Step 6: Run the whole suite**

Run the full test command. Expected: PASS — the `Hashable` change must not have broken `RecipeQueryTests`.

- [ ] **Step 7: Commit**

```bash
git add RecipeTest/Modules/Recipe/Models/Domain/RecipeQueryFacet.swift \
  RecipeTest/Modules/Recipe/Models/Domain/RecipeQuery.swift \
  Tests/Modules/Recipe/Models/RecipeQueryFacetTests.swift
git commit -m "[list] Derive removable facets from a recipe query"
```

---

## Task 2: The route payload

**Files:**
- Create: `RecipeTest/Modules/RecipeList/Models/RecipeListRequest.swift`
- Create: `RecipeTest/Modules/RecipeList/Models/RecipeListViewMode.swift`
- Test: `Tests/Modules/RecipeList/Models/RecipeListRequestTests.swift`

**Interfaces:**
- Consumes: `RecipeQuery` (now `Hashable`), `RecipeCategory`, `RecipeQueryFacet` from Task 1.
- Produces: `RecipeListRequest` with `let query: RecipeQuery`, `let title: Title`, nested `enum Title: Hashable { case category(String), search(String), all }`; factories `static func category(_: RecipeCategory) -> Self`, `static func search(_: String, query: RecipeQuery) -> Self`, `static func all(query: RecipeQuery) -> Self`; and `func replacingQuery(_: RecipeQuery) -> Self`. Also `RecipeListViewMode` with `.grid` and `.list`.

- [ ] **Step 1: Write the failing tests**

Create `Tests/Modules/RecipeList/Models/RecipeListRequestTests.swift`:

```swift
//
//  RecipeListRequestTests.swift
//  Tests
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation
@testable import RecipeTest
import Testing

struct RecipeListRequestTests {
  @Test
  func category_filtersOnTheCategoryItIsTitledWith() {
    let request = RecipeListRequest.category(.dummy(name: "Desserts"))

    #expect(request.query.category == "Desserts")
    #expect(request.title == .category("Desserts"))
  }

  @Test
  func search_carriesTheTextIntoBothTheQueryAndTheTitle() {
    let request = RecipeListRequest.search(
      "adobo",
      query: RecipeQuery(isVegetarian: true)
    )

    #expect(request.query.searchText == "adobo")
    #expect(request.query.isVegetarian == true)
    #expect(request.title == .search("adobo"))
  }

  @Test
  func all_keepsTheFacetsItWasGivenAndIsTitledForEverything() {
    let request = RecipeListRequest.all(query: RecipeQuery(servings: .two))

    #expect(request.query.servings == .two)
    #expect(request.query.category == nil)
    #expect(request.title == .all)
  }

  @Test
  func replacingQuery_keepsTheTitle() {
    let request = RecipeListRequest
      .category(.dummy(name: "Vegan"))
      .replacingQuery(RecipeQuery(category: "Vegan"))

    #expect(request.title == .category("Vegan"))
  }

  @Test
  func isHashable_soItCanRideANavigationPath() {
    let request = RecipeListRequest.category(.dummy(name: "Rice"))

    #expect(Set([request, request]).count == 1)
  }
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run the single-suite command with `-only-testing:Tests/RecipeListRequestTests`.
Expected: FAIL to compile — "cannot find 'RecipeListRequest' in scope".

- [ ] **Step 3: Write the request**

Create `RecipeTest/Modules/RecipeList/Models/RecipeListRequest.swift`:

```swift
//
//  RecipeListRequest.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

/// What a results list was asked for: the filter to run, and what the list is *of*.
///
/// The screen reads both and never learns which entry point built them, which is what lets
/// a category tap, a search and a filter sheet all push the same route.
nonisolated struct RecipeListRequest: Hashable {
  /// What the list is of, not the words on the bar — the view model turns this into copy,
  /// and the same value also decides the search pill's placeholder.
  enum Title: Hashable {
    case category(String)
    case search(String)
    case all
  }

  let query: RecipeQuery
  let title: Title
}

// MARK: - Entry points

nonisolated extension RecipeListRequest {
  /// Sets the filter and the heading from one value, so a list titled "Desserts" that
  /// filters on "Snacks" is not constructible.
  static func category(_ category: RecipeCategory) -> Self {
    RecipeListRequest(
      query: RecipeQuery(category: category.name),
      title: .category(category.name)
    )
  }

  static func search(
    _ text: String,
    query: RecipeQuery = .empty
  ) -> Self {
    var searched = query
    searched.searchText = text

    return RecipeListRequest(
      query: searched,
      title: .search(text)
    )
  }

  static func all(query: RecipeQuery = .empty) -> Self {
    RecipeListRequest(
      query: query,
      title: .all
    )
  }
}

// MARK: - Methods

nonisolated extension RecipeListRequest {
  /// Used when a facet is removed: the filter changes, what the list is of does not.
  func replacingQuery(_ query: RecipeQuery) -> Self {
    RecipeListRequest(
      query: query,
      title: title
    )
  }
}
```

- [ ] **Step 4: Write the view mode**

Create `RecipeTest/Modules/RecipeList/Models/RecipeListViewMode.swift`:

```swift
//
//  RecipeListViewMode.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

/// How the results are laid out. Screen-local and not persisted — leaving the list forgets it.
nonisolated enum RecipeListViewMode: Hashable, CaseIterable {
  case grid
  case list
}
```

- [ ] **Step 5: Run the tests to verify they pass**

Run the single-suite command with `-only-testing:Tests/RecipeListRequestTests`.
Expected: PASS, 5 tests.

- [ ] **Step 6: Commit**

```bash
git add RecipeTest/Modules/RecipeList/Models/ \
  Tests/Modules/RecipeList/Models/RecipeListRequestTests.swift
git commit -m "[list] Add the results list route payload"
```

---

## Task 3: The string catalog

**Files:**
- Create: `RecipeTest/Modules/RecipeList/UI/RecipeList.xcstrings`

**Interfaces:**
- Produces: the `LocalizedStringResource` symbols every later task uses. Xcode derives a symbol from each key by dropping the dots and camel-casing, so `recipeList.empty.title` becomes `.RecipeList.recipeListEmptyTitle`, and a key with arguments becomes a function — `recipeList.resultCount` becomes `.RecipeList.recipeListResultCount(_:)`.

No test. The catalog is verified by the build in Task 5, which is the first task to reference a symbol from it.

- [ ] **Step 1: Write the catalog**

Create `RecipeTest/Modules/RecipeList/UI/RecipeList.xcstrings`:

```json
{
  "sourceLanguage" : "en",
  "strings" : {
    "recipeList.card.servings.accessibilityLabel" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "serves %lld"
          }
        }
      }
    },
    "recipeList.empty.clearFilters" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Clear filters"
          }
        }
      }
    },
    "recipeList.empty.detail" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Try removing a filter or searching for something else."
          }
        }
      }
    },
    "recipeList.empty.noResults.title" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "No recipes here yet"
          }
        }
      }
    },
    "recipeList.empty.title" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "No recipes match your filters"
          }
        }
      }
    },
    "recipeList.facet.exclude" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Exclude: %@"
          }
        }
      }
    },
    "recipeList.facet.include" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Include: %@"
          }
        }
      }
    },
    "recipeList.facet.notVegetarian" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Not vegetarian"
          }
        }
      }
    },
    "recipeList.facet.remove.accessibilityLabel" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Remove %@"
          }
        }
      }
    },
    "recipeList.facet.searchesSteps" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Search in steps"
          }
        }
      }
    },
    "recipeList.facet.servings" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "%@ servings"
          }
        }
      }
    },
    "recipeList.facet.vegetarian" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Vegetarian"
          }
        }
      }
    },
    "recipeList.facets.clearAll" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Clear all"
          }
        }
      }
    },
    "recipeList.footer.loading.accessibilityLabel" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Loading more recipes"
          }
        }
      }
    },
    "recipeList.resultCount" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : {
          "variations" : {
            "plural" : {
              "one" : {
                "stringUnit" : {
                  "state" : "translated",
                  "value" : "%lld recipe"
                }
              },
              "other" : {
                "stringUnit" : {
                  "state" : "translated",
                  "value" : "%lld recipes"
                }
              }
            }
          }
        }
      }
    },
    "recipeList.searchPlaceholder.all" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Search recipes or ingredients"
          }
        }
      }
    },
    "recipeList.searchPlaceholder.category" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Search %@"
          }
        }
      }
    },
    "recipeList.searchPlaceholder.search" : {
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
    "recipeList.title.all" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "All recipes"
          }
        }
      }
    },
    "recipeList.title.searchResults" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Search results"
          }
        }
      }
    },
    "recipeList.viewMode.grid" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Grid"
          }
        }
      }
    },
    "recipeList.viewMode.list" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "List"
          }
        }
      }
    }
  },
  "version" : "1.0"
}
```

There is no cooking-time key. `RecipeDetailViewModel.cookingTimeText` already renders a duration through `Duration.seconds(_:).formatted(.units(...))`, which localizes "hr" and "min" itself; the card view model uses the same expression in Task 5.

- [ ] **Step 2: Verify the catalog parses**

```bash
python3 -c "import json; json.load(open('RecipeTest/Modules/RecipeList/UI/RecipeList.xcstrings')); print('ok')"
```

Expected: `ok`.

- [ ] **Step 3: Build**

Run the build-only command. Expected: BUILD SUCCEEDED — the catalog is picked up by the synchronized group with no project file edit.

- [ ] **Step 4: Commit**

```bash
git add RecipeTest/Modules/RecipeList/UI/RecipeList.xcstrings
git commit -m "[list] Add the recipe list strings"
```

---

## Task 4: Move the search pill into Shared

**Files:**
- Create: `RecipeTest/Modules/Shared/UI/Components/RecipeSearchPill.swift`
- Delete: `RecipeTest/Modules/Home/UI/Components/HomeSearchPill.swift`
- Modify: `RecipeTest/Modules/Home/UI/Scenes/HomeView.swift` (the `HomeSearchPill(onTap:)` call)

**Interfaces:**
- Produces: `RecipeSearchPill(placeholder: String, onTap: VoidResult)`, with `static var baseHeight: CGFloat` unchanged.

The placeholder is a `String` rather than a `LocalizedStringResource` because under the view-model rule it is a value a view model produced — the list passes `viewModel.searchPlaceholder`, which splices in a category name. Home is not converted to that rule yet, so it localizes at its call site.

- [ ] **Step 1: Create the moved component**

Create `RecipeTest/Modules/Shared/UI/Components/RecipeSearchPill.swift` with the full body of `HomeSearchPill`, changed in exactly three places — the type name, the new stored property, and the `Text`:

```swift
//
//  RecipeSearchPill.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

/// A `Button`, not a `TextField`: it opens the search overlay rather than accepting input.
struct RecipeSearchPill: View {
  let placeholder: String
  let onTap: VoidResult

  @Environment(\.dynamicTypeSize) private var dynamicTypeSize

  @ScaledMetric(relativeTo: .body) private var height: CGFloat = RecipeSearchPill.baseHeight

  var body: some View {
    Button(
      action: onTap,
      label: {
        HStack(spacing: contentSpacing) {
          Image(systemName: searchSymbolName)
            .foregroundStyle(.themeColor(.iconsDefault))

          Text(placeholder)
            .themeTextStyle(.bodyRegular)
            .themeColor(.textPrimary)
            .lineLimit(placeholderLineLimit)
        }
        .frame(
          maxWidth: .infinity,
          minHeight: height
        )
        .padding(
          .horizontal,
          horizontalGutter
        )
        .background(
          Color.themeColor(.surfacesBackground2),
          in: .capsule
        )
      }
    )
    .buttonStyle(.plain)
    .cardShadow()
    .padding(
      .horizontal,
      horizontalGutter
    )
  }
}

// MARK: - Getters

extension RecipeSearchPill {
  static var baseHeight: CGFloat {
    56
  }
}

private extension RecipeSearchPill {
  var contentSpacing: CGFloat {
    10
  }

  var horizontalGutter: CGFloat {
    20
  }

  var searchSymbolName: String {
    "magnifyingglass"
  }

  var placeholderLineLimit: Int? {
    dynamicTypeSize.isAccessibilitySize ? nil : 1
  }
}

#if DEBUG
  #Preview("Home placeholder") {
    RecipeSearchPill(
      placeholder: String(localized: .Home.homeSearchPlaceholder),
      onTap: {}
    )
    .frame(
      maxWidth: .infinity,
      maxHeight: .infinity
    )
    .background(Color.themeColor(.surfacesBackground))
  }

  #Preview("Scoped to a category") {
    RecipeSearchPill(
      placeholder: "Search Desserts",
      onTap: {}
    )
    .frame(
      maxWidth: .infinity,
      maxHeight: .infinity
    )
    .background(Color.themeColor(.surfacesBackground))
  }
#endif
```

- [ ] **Step 2: Delete the old component**

```bash
git rm RecipeTest/Modules/Home/UI/Components/HomeSearchPill.swift
```

- [ ] **Step 3: Update Home's call site**

In `RecipeTest/Modules/Home/UI/Scenes/HomeView.swift`, replace `HomeSearchPill(onTap: onSearchTap)` with:

```swift
        RecipeSearchPill(
          placeholder: String(localized: .Home.homeSearchPlaceholder),
          onTap: onSearchTap
        )
```

- [ ] **Step 4: Build**

Run the build-only command.
Expected: BUILD SUCCEEDED. A failure naming `HomeSearchPill` means a reference was missed — `grep -rn HomeSearchPill RecipeTest/` finds it.

- [ ] **Step 5: Run the whole suite**

Run the full test command. Expected: PASS, unchanged count.

- [ ] **Step 6: Commit**

```bash
git add RecipeTest/Modules/Shared/UI/Components/RecipeSearchPill.swift \
  RecipeTest/Modules/Home/UI/Scenes/HomeView.swift \
  RecipeTest/Modules/Home/UI/Components/HomeSearchPill.swift
git commit -m "[list] Share the search pill and parameterise its placeholder"
```

---

## Task 5: The card view model

**Files:**
- Create: `RecipeTest/Modules/RecipeList/UI/Components/RecipeCardViewModelProtocol.swift`
- Create: `RecipeTest/Modules/RecipeList/UI/Components/RecipeCardViewModel.swift`
- Test: `Tests/Modules/RecipeList/UI/Components/RecipeCardViewModelTests.swift`

**Interfaces:**
- Consumes: `RecipeSummary`, and `.RecipeList.recipeListCardServingsAccessibilityLabel(_:)` from Task 3.
- Produces: `RecipeCardViewModelProtocol` with `id: String`, `title: String`, `imageURL: URL?`, `cuisineAndCategory: String?`, `cookingTimeText: String?`, `servingsText: String?`, `accessibilityLabel: String`, `summary: RecipeSummary`; and `RecipeCardViewModel(summary:)`, a `nonisolated struct` conforming to it.

**Why a struct and not an `@Observable` class.** `SectionState<Value>` constrains `Value` to `Equatable`, and the list's state carries an array of these. A struct over a `Hashable` `RecipeSummary` gets `Equatable` synthesised, which also gives SwiftUI a correct diff; a class would need `==` written by hand and would allocate once per row. There is no mutable state here to observe — when a card gains a favourite toggle, that is when it earns the macro.

**Why `summary` is on the protocol.** Tapping a row pushes `Route.Recipe.detail(RecipeSummary)`. It is a navigation payload, not something a card renders, and no view reads it.

- [ ] **Step 1: Write the failing tests**

Create `Tests/Modules/RecipeList/UI/Components/RecipeCardViewModelTests.swift`:

```swift
//
//  RecipeCardViewModelTests.swift
//  Tests
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation
@testable import RecipeTest
import Testing

struct RecipeCardViewModelTests {
  @Test
  func cookingTimeText_underAnHour_readsInMinutes() {
    let sut = RecipeCardViewModel(summary: .dummy(totalTimeMinutes: 25))

    #expect(sut.cookingTimeText == "25 min")
  }

  @Test
  func cookingTimeText_awholeHour_omitsTheMinutes() {
    let sut = RecipeCardViewModel(summary: .dummy(totalTimeMinutes: 60))

    #expect(sut.cookingTimeText == "1 hr")
  }

  @Test
  func cookingTimeText_overAnHour_readsBothUnits() {
    let sut = RecipeCardViewModel(summary: .dummy(totalTimeMinutes: 90))

    #expect(sut.cookingTimeText == "1 hr 30 min")
  }

  @Test
  func cookingTimeText_noTime_isNil() {
    let sut = RecipeCardViewModel(summary: .dummy(totalTimeMinutes: nil))

    #expect(sut.cookingTimeText == nil)
  }

  @Test
  func cuisineAndCategory_bothPresent_joinsThemCapitalised() {
    let sut = RecipeCardViewModel(summary: .dummy(
      category: "Pasta",
      cuisine: "italian"
    ))

    #expect(sut.cuisineAndCategory == "Italian · Pasta")
  }

  @Test
  func cuisineAndCategory_onlyOnePresent_isThatOneAlone() {
    let sut = RecipeCardViewModel(summary: .dummy(
      category: nil,
      cuisine: "thai"
    ))

    #expect(sut.cuisineAndCategory == "Thai")
  }

  @Test
  func cuisineAndCategory_neitherPresent_isNil() {
    let sut = RecipeCardViewModel(summary: .dummy(
      category: nil,
      cuisine: nil
    ))

    #expect(sut.cuisineAndCategory == nil)
  }

  @Test
  func servingsText_isTheBareNumber() {
    let sut = RecipeCardViewModel(summary: .dummy(servings: 4))

    #expect(sut.servingsText == "4")
  }

  @Test
  func servingsText_noServings_isNil() {
    let sut = RecipeCardViewModel(summary: .dummy(servings: nil))

    #expect(sut.servingsText == nil)
  }

  @Test
  func accessibilityLabel_everythingPresent_readsTitleThenMetrics() {
    let sut = RecipeCardViewModel(summary: .dummy(
      title: "Chicken Adobo",
      totalTimeMinutes: 45,
      servings: 4
    ))

    #expect(sut.accessibilityLabel == "Chicken Adobo, 45 min, serves 4")
  }

  @Test
  func accessibilityLabel_noMetrics_isTheTitleAlone() {
    let sut = RecipeCardViewModel(summary: .dummy(
      title: "Chicken Adobo",
      totalTimeMinutes: nil,
      servings: nil
    ))

    #expect(sut.accessibilityLabel == "Chicken Adobo")
  }

  @Test
  func identity_isTheRecipeID() {
    let sut = RecipeCardViewModel(summary: .dummy(id: "rcp-042"))

    #expect(sut.id == "rcp-042")
  }
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run the single-suite command with `-only-testing:Tests/RecipeCardViewModelTests`.
Expected: FAIL to compile — "cannot find 'RecipeCardViewModel' in scope".

- [ ] **Step 3: Write the protocol**

Create `RecipeTest/Modules/RecipeList/UI/Components/RecipeCardViewModelProtocol.swift`:

```swift
//
//  RecipeCardViewModelProtocol.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

/// Everything a results row draws, already derived. A card view formats nothing.
///
/// Not `Equatable`: the views hold this as `any RecipeCardViewModelProtocol`, and a `Self`
/// requirement buys nothing there. `RecipeCardViewModel` is `Equatable` as a struct, which is
/// what `SectionState` needs.
nonisolated protocol RecipeCardViewModelProtocol: Identifiable {
  var id: String { get }
  var title: String { get }
  var imageURL: URL? { get }
  var cuisineAndCategory: String? { get }
  var cookingTimeText: String? { get }
  var servingsText: String? { get }
  var accessibilityLabel: String { get }

  /// The payload a row tap pushes. Not rendered by anything.
  var summary: RecipeSummary { get }
}
```

- [ ] **Step 4: Write the view model**

Create `RecipeTest/Modules/RecipeList/UI/Components/RecipeCardViewModel.swift`:

```swift
//
//  RecipeCardViewModel.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

nonisolated struct RecipeCardViewModel: RecipeCardViewModelProtocol {
  let summary: RecipeSummary
}

// MARK: - Getters

nonisolated extension RecipeCardViewModel {
  var id: String {
    summary.id
  }

  var title: String {
    summary.title
  }

  var imageURL: URL? {
    summary.heroImageURL
  }

  /// The API stores cuisine lower-cased ("italian") and category title-cased ("Pasta"),
  /// while the prototype prints both capitalised.
  var cuisineAndCategory: String? {
    let parts = [
      summary.cuisine?.localizedCapitalized,
      summary.category,
    ].compactMap(\.self)

    guard !parts.isEmpty else { return nil }

    return parts.joined(separator: metadataSeparator)
  }

  /// The same expression `RecipeDetailViewModel` uses, so one duration is never spelled two
  /// ways — the units localize themselves rather than coming from a catalog.
  var cookingTimeText: String? {
    guard let totalTimeMinutes = summary.totalTimeMinutes else { return nil }

    return Duration
      .seconds(totalTimeMinutes * 60)
      .formatted(.units(
        allowed: [.hours, .minutes],
        width: .abbreviated
      ))
  }

  var servingsText: String? {
    summary.servings.map { String($0) }
  }

  /// The visible servings text is a bare number beside an icon; only the spoken form says
  /// "serves".
  var accessibilityLabel: String {
    var parts = [title]

    if let cookingTimeText {
      parts.append(cookingTimeText)
    }

    if let servings = summary.servings {
      parts.append(String(localized: .RecipeList.recipeListCardServingsAccessibilityLabel(servings)))
    }

    return parts.joined(separator: accessibilitySeparator)
  }
}

// MARK: - Getters > Constants

private nonisolated extension RecipeCardViewModel {
  var metadataSeparator: String {
    " · "
  }

  var accessibilitySeparator: String {
    ", "
  }
}
```

- [ ] **Step 5: Run the tests to verify they pass**

Run the single-suite command with `-only-testing:Tests/RecipeCardViewModelTests`.
Expected: PASS, 12 tests. If `cookingTimeText` comes back as "25min" rather than "25 min", the abbreviated width differs on this OS — change the expectations to match what `Duration` actually produces and note it, rather than hand-assembling the string.

- [ ] **Step 6: Commit**

```bash
git add RecipeTest/Modules/RecipeList/UI/Components/RecipeCardViewModel.swift \
  RecipeTest/Modules/RecipeList/UI/Components/RecipeCardViewModelProtocol.swift \
  Tests/Modules/RecipeList/UI/Components/RecipeCardViewModelTests.swift
git commit -m "[list] Derive a results row's values in a view model"
```

---

## Task 6: The facet chip view model

**Files:**
- Create: `RecipeTest/Modules/RecipeList/UI/Components/RecipeFacetChipViewModelProtocol.swift`
- Create: `RecipeTest/Modules/RecipeList/UI/Components/RecipeFacetChipViewModel.swift`
- Test: `Tests/Modules/RecipeList/UI/Components/RecipeFacetChipViewModelTests.swift`

**Interfaces:**
- Consumes: `RecipeQueryFacet` from Task 1; the `recipeList.facet.*` symbols from Task 3.
- Produces: `RecipeFacetChipViewModelProtocol` with `id: RecipeQueryFacet`, `label: String`, `removeAccessibilityLabel: String`, `isExclusion: Bool`; and `RecipeFacetChipViewModel(facet:)`, a `nonisolated struct` conforming to it.

- [ ] **Step 1: Write the failing tests**

Create `Tests/Modules/RecipeList/UI/Components/RecipeFacetChipViewModelTests.swift`:

```swift
//
//  RecipeFacetChipViewModelTests.swift
//  Tests
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation
@testable import RecipeTest
import Testing

struct RecipeFacetChipViewModelTests {
  @Test
  func label_vegetarianTrue_readsVegetarian() {
    let sut = RecipeFacetChipViewModel(facet: .vegetarian(true))

    #expect(sut.label == "Vegetarian")
  }

  @Test
  func label_vegetarianFalse_saysSoRatherThanRepeatingTheOppositeFilter() {
    let sut = RecipeFacetChipViewModel(facet: .vegetarian(false))

    #expect(sut.label == "Not vegetarian")
  }

  @Test
  func label_servings_usesTheWireValueIncludingTheOpenEndedOne() {
    #expect(RecipeFacetChipViewModel(facet: .servings(.four)).label == "4 servings")
    #expect(RecipeFacetChipViewModel(facet: .servings(.sixOrMore)).label == "6+ servings")
  }

  @Test
  func label_includeAndExclude_namePrefixTheIngredient() {
    #expect(RecipeFacetChipViewModel(facet: .include("garlic")).label == "Include: garlic")
    #expect(RecipeFacetChipViewModel(facet: .exclude("peanuts")).label == "Exclude: peanuts")
  }

  @Test
  func label_searchesSteps_readsSearchInSteps() {
    let sut = RecipeFacetChipViewModel(facet: .searchesSteps)

    #expect(sut.label == "Search in steps")
  }

  @Test
  func removeAccessibilityLabel_namesWhatItRemoves() {
    let sut = RecipeFacetChipViewModel(facet: .vegetarian(true))

    #expect(sut.removeAccessibilityLabel == "Remove Vegetarian")
  }

  @Test
  func isExclusion_isTrueOnlyForAnExcludedIngredient() {
    #expect(RecipeFacetChipViewModel(facet: .exclude("peanuts")).isExclusion)
    #expect(RecipeFacetChipViewModel(facet: .include("garlic")).isExclusion == false)
    #expect(RecipeFacetChipViewModel(facet: .vegetarian(true)).isExclusion == false)
  }

  @Test
  func identity_isTheFacetItself() {
    let sut = RecipeFacetChipViewModel(facet: .include("garlic"))

    #expect(sut.id == .include("garlic"))
  }
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run the single-suite command with `-only-testing:Tests/RecipeFacetChipViewModelTests`.
Expected: FAIL to compile — "cannot find 'RecipeFacetChipViewModel' in scope".

- [ ] **Step 3: Write the protocol**

Create `RecipeTest/Modules/RecipeList/UI/Components/RecipeFacetChipViewModelProtocol.swift`:

```swift
//
//  RecipeFacetChipViewModelProtocol.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

nonisolated protocol RecipeFacetChipViewModelProtocol: Identifiable {
  var id: RecipeQueryFacet { get }
  var label: String { get }
  var removeAccessibilityLabel: String { get }

  /// The prototype tints an excluded ingredient differently. A presentation fact the view
  /// model owns, so the chip branches on a flag rather than inspecting the facet.
  var isExclusion: Bool { get }
}
```

- [ ] **Step 4: Write the view model**

Create `RecipeTest/Modules/RecipeList/UI/Components/RecipeFacetChipViewModel.swift`:

```swift
//
//  RecipeFacetChipViewModel.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

nonisolated struct RecipeFacetChipViewModel: RecipeFacetChipViewModelProtocol {
  let facet: RecipeQueryFacet
}

// MARK: - Getters

nonisolated extension RecipeFacetChipViewModel {
  var id: RecipeQueryFacet {
    facet
  }

  var label: String {
    switch facet {
    case let .vegetarian(isVegetarian):
      isVegetarian
        ? String(localized: .RecipeList.recipeListFacetVegetarian)
        : String(localized: .RecipeList.recipeListFacetNotVegetarian)

    case let .servings(servings):
      String(localized: .RecipeList.recipeListFacetServings(servings.rawValue))

    case let .include(ingredient):
      String(localized: .RecipeList.recipeListFacetInclude(ingredient))

    case let .exclude(ingredient):
      String(localized: .RecipeList.recipeListFacetExclude(ingredient))

    case .searchesSteps:
      String(localized: .RecipeList.recipeListFacetSearchesSteps)
    }
  }

  var removeAccessibilityLabel: String {
    String(localized: .RecipeList.recipeListFacetRemoveAccessibilityLabel(label))
  }

  var isExclusion: Bool {
    if case .exclude = facet {
      return true
    }

    return false
  }
}
```

`RecipeServings.rawValue` is already the display string the prototype shows — "1", "2", "4", "6+" — which is why the fourth option is an enum and not an `Int`.

- [ ] **Step 5: Run the tests to verify they pass**

Run the single-suite command with `-only-testing:Tests/RecipeFacetChipViewModelTests`.
Expected: PASS, 8 tests.

- [ ] **Step 6: Commit**

```bash
git add RecipeTest/Modules/RecipeList/UI/Components/RecipeFacetChipViewModel.swift \
  RecipeTest/Modules/RecipeList/UI/Components/RecipeFacetChipViewModelProtocol.swift \
  Tests/Modules/RecipeList/UI/Components/RecipeFacetChipViewModelTests.swift
git commit -m "[list] Label a filter chip from its facet"
```

---
## Task 7: The list view model — first page

**Files:**
- Create: `RecipeTest/Modules/RecipeList/UI/Scenes/RecipeListViewModelProtocol.swift`
- Create: `RecipeTest/Modules/RecipeList/UI/Scenes/RecipeListViewModel.swift`
- Test: `Tests/Modules/RecipeList/UI/Scenes/RecipeListViewModelTests.swift`

**Interfaces:**
- Consumes: `RecipeListRequest`, `RecipeListViewMode` (Task 2), `RecipeCardViewModel` (Task 5), `RecipeFacetChipViewModel` (Task 6), `RecipeServiceProtocol`, `SectionState`, `Page`.
- Produces: `RecipeListViewModelProtocol` (full listing in Step 3) and `RecipeListViewModel(request:recipeService:)`. Tasks 8 and 9 extend the same two files; Tasks 10–16 consume the protocol.

**Why the protocol names concrete view-model types.** `SectionState<Value>` constrains `Value` to `Equatable`, and `[any RecipeCardViewModelProtocol]` is not `Equatable`. The screen's protocol therefore says `SectionState<[RecipeCardViewModel]>`. Nothing is lost: the card *views* still depend on `any RecipeCardViewModelProtocol`, so a card previews against a mock, and a mock screen builds real card view models from `.dummy()` summaries in one line.

- [ ] **Step 1: Write the failing tests**

Create `Tests/Modules/RecipeList/UI/Scenes/RecipeListViewModelTests.swift`:

```swift
//
//  RecipeListViewModelTests.swift
//  Tests
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation
@testable import RecipeTest
import Testing

@MainActor
struct RecipeListViewModelTests {
  @Test
  func loadFirstPage_succeeds_mapsEveryRecipeToACard() async {
    let service = MockRecipeService(recipes: Self.page(ids: [
      "rcp-001",
      "rcp-002",
    ]))
    let sut = Self.makeSUT(service: service)

    await sut.loadFirstPage()

    #expect(sut.recipes.value?.map(\.id) == ["rcp-001", "rcp-002"])
  }

  @Test
  func loadFirstPage_asksForTwentyRowsOfTheRequestsOwnQuery() async {
    let service = MockRecipeService()
    let sut = Self.makeSUT(
      request: .category(.dummy(name: "Desserts")),
      service: service
    )

    await sut.loadFirstPage()

    #expect(service.recipes.lastRequest?.query.category == "Desserts")
    #expect(service.recipes.lastRequest?.page == Page(
      index: 1,
      size: 20
    ))
  }

  @Test
  func loadFirstPage_noRows_isEmptyRatherThanLoadedWithNothing() async {
    let service = MockRecipeService(recipes: Self.page(ids: []))
    let sut = Self.makeSUT(service: service)

    await sut.loadFirstPage()

    #expect(sut.recipes == .empty)
  }

  @Test
  func loadFirstPage_fails_reportsTheFailure() async {
    let service = MockRecipeService()
    service.recipes.fails(with: AppError.unknown)
    let sut = Self.makeSUT(service: service)

    await sut.loadFirstPage()

    #expect(sut.recipes.isLoaded == false)
  }

  @Test
  func loadFirstPage_cancelled_keepsThePreviousState() async {
    let service = MockRecipeService(recipes: Self.page(ids: ["rcp-001"]))
    let sut = Self.makeSUT(service: service)
    await sut.loadFirstPage()
    let loaded = sut.recipes
    service.recipes.fails(with: CancellationError())

    await sut.loadFirstPage()

    #expect(sut.recipes == loaded)
  }

  @Test
  func resultCountText_followsTheServersTotalAndNotTheRowsLoaded() async {
    let service = MockRecipeService(recipes: Self.page(
      ids: ["rcp-001"],
      total: 36,
      lastPage: 2
    ))
    let sut = Self.makeSUT(service: service)

    await sut.loadFirstPage()

    #expect(sut.resultCountText == "36 recipes")
  }

  @Test
  func resultCountText_oneResult_isSingular() async {
    let service = MockRecipeService(recipes: Self.page(
      ids: ["rcp-001"],
      total: 1
    ))
    let sut = Self.makeSUT(service: service)

    await sut.loadFirstPage()

    #expect(sut.resultCountText == "1 recipe")
  }

  @Test
  func resultCountText_beforeAnythingLoads_isNil() {
    #expect(Self.makeSUT().resultCountText == nil)
  }

  @Test
  func resultCountText_afterAFailure_isNil() async {
    let service = MockRecipeService()
    service.recipes.fails(with: AppError.unknown)
    let sut = Self.makeSUT(service: service)

    await sut.loadFirstPage()

    #expect(sut.resultCountText == nil)
  }

  @Test
  func title_aCategory_isTheCategorysOwnName() {
    let sut = Self.makeSUT(request: .category(.dummy(name: "Desserts")))

    #expect(sut.title == "Desserts")
  }

  @Test
  func title_aSearch_readsSearchResults() {
    let sut = Self.makeSUT(request: .search("adobo"))

    #expect(sut.title == "Search results")
  }

  @Test
  func title_everything_readsAllRecipes() {
    #expect(Self.makeSUT(request: .all()).title == "All recipes")
  }

  @Test
  func searchPlaceholder_scopesItselfToWhatTheListIsOf() {
    #expect(Self.makeSUT(request: .category(.dummy(name: "Desserts"))).searchPlaceholder == "Search Desserts")
    #expect(Self.makeSUT(request: .search("pho")).searchPlaceholder == "“pho”")
    #expect(Self.makeSUT(request: .all()).searchPlaceholder == "Search recipes or ingredients")
  }

  @Test
  func viewMode_startsOnTheGridAndFollowsTheToggle() {
    let sut = Self.makeSUT()

    #expect(sut.viewMode == .grid)

    sut.select(viewMode: .list)

    #expect(sut.viewMode == .list)
  }
}

// MARK: - Helpers

private extension RecipeListViewModelTests {
  static func makeSUT(
    request: RecipeListRequest = .all(),
    service: RecipeServiceProtocol = MockRecipeService()
  ) -> RecipeListViewModel {
    RecipeListViewModel(
      request: request,
      recipeService: service
    )
  }

  static func page(
    ids: [String],
    total: Int? = nil,
    currentPage: Int = 1,
    lastPage: Int = 1
  ) -> RecipeListPage {
    RecipeListPage(
      recipes: ids.map { .dummy(id: $0) },
      meta: .dummy(
        total: total ?? ids.count,
        perPage: 20,
        from: 1,
        to: ids.count,
        currentPage: currentPage,
        lastPage: lastPage
      )
    )
  }
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run the single-suite command with `-only-testing:Tests/RecipeListViewModelTests`.
Expected: FAIL to compile — "cannot find 'RecipeListViewModel' in scope".

- [ ] **Step 3: Write the protocol**

Create `RecipeTest/Modules/RecipeList/UI/Scenes/RecipeListViewModelProtocol.swift`:

```swift
//
//  RecipeListViewModelProtocol.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

/// The concrete `RecipeCardViewModel` and `RecipeFacetChipViewModel` are named here rather
/// than their protocols because `SectionState` constrains its value to `Equatable`, which an
/// array of existentials is not. The card and chip *views* still depend on the protocols.
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

`viewMode` is read-only with a `select` input rather than a settable property, so the screen keeps the project's callback style and no view needs `@Bindable` over an existential.

- [ ] **Step 4: Write the view model**

Create `RecipeTest/Modules/RecipeList/UI/Scenes/RecipeListViewModel.swift`. Tasks 8 and 9 add to this file; write only what the tests above need:

```swift
//
//  RecipeListViewModel.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

@Observable
final class RecipeListViewModel: RecipeListViewModelProtocol {
  private(set) var recipes: SectionState<[RecipeCardViewModel]> = .loading
  private(set) var isLoadingNextPage = false
  private(set) var nextPageError: String?
  private(set) var viewMode: RecipeListViewMode = .grid

  /// Mutable: removing a facet rewrites the query and reloads, without rebuilding the screen.
  private var request: RecipeListRequest

  /// `nil` once the last page has landed — the pager reads this as "stop asking".
  private var nextPage: Page?
  private var resultTotal: Int?
  private var generation = 0

  private let recipeService: RecipeServiceProtocol

  init(
    request: RecipeListRequest,
    recipeService: RecipeServiceProtocol
  ) {
    self.request = request
    self.recipeService = recipeService
  }
}

// MARK: - Getters

extension RecipeListViewModel {
  var title: String {
    switch request.title {
    case let .category(name):
      name

    case .search:
      String(localized: .RecipeList.recipeListTitleSearchResults)

    case .all:
      String(localized: .RecipeList.recipeListTitleAll)
    }
  }

  var searchPlaceholder: String {
    switch request.title {
    case let .category(name):
      String(localized: .RecipeList.recipeListSearchPlaceholderCategory(name))

    case let .search(text):
      String(localized: .RecipeList.recipeListSearchPlaceholderSearch(text))

    case .all:
      String(localized: .RecipeList.recipeListSearchPlaceholderAll)
    }
  }

  /// Gated on `isLoaded` rather than cleared by hand on every failure: a count only means
  /// something beside the rows it counts.
  var resultCountText: String? {
    guard
      recipes.isLoaded,
      let resultTotal
    else { return nil }

    return String(localized: .RecipeList.recipeListResultCount(resultTotal))
  }
}

// MARK: - Getters > Constants

private extension RecipeListViewModel {
  var pageSize: Int {
    20
  }

  var firstPage: Page {
    Page(
      index: 1,
      size: pageSize
    )
  }
}

// MARK: - Inputs

extension RecipeListViewModel {
  func loadFirstPage() async {
    generation += 1
    let generation = self.generation
    let previous = recipes
    recipes = previous.refreshing
    isLoadingNextPage = false
    nextPageError = nil
    nextPage = nil

    do {
      let page = try await recipeService.getRecipes(
        query: request.query,
        page: firstPage
      )

      guard generation == self.generation else { return }

      resultTotal = page.meta.total
      recipes = .rows(page.recipes.map(RecipeCardViewModel.init))
      nextPage = page.hasLoadedAllData ? nil : firstPage.next
    } catch {
      guard generation == self.generation else { return }

      recipes = previous.recovering(from: error)
    }
  }

  func select(viewMode: RecipeListViewMode) {
    self.viewMode = viewMode
  }
}
```

The remaining protocol members land in Tasks 8 and 9; the file will not compile against the protocol until Task 9 finishes, so **conform to the protocol only at the end of Task 9**. For this task declare the type as `final class RecipeListViewModel` with no conformance, and add `: RecipeListViewModelProtocol` in Task 9, Step 5.

- [ ] **Step 5: Run the tests to verify they pass**

Run the single-suite command with `-only-testing:Tests/RecipeListViewModelTests`.
Expected: PASS, 13 tests.

- [ ] **Step 6: Commit**

```bash
git add RecipeTest/Modules/RecipeList/UI/Scenes/ \
  Tests/Modules/RecipeList/UI/Scenes/RecipeListViewModelTests.swift
git commit -m "[list] Load the first page of a results list"
```

---

## Task 8: The list view model — the pager

**Files:**
- Create: `RecipeTest/Modules/Shared/Services/ErrorHandling/Error+FailureDetail.swift`
- Modify: `RecipeTest/Modules/Shared/UI/Models/SectionState.swift` (replace the private helper with the shared one)
- Modify: `RecipeTest/Modules/RecipeList/UI/Scenes/RecipeListViewModel.swift` (add the paging inputs)
- Test: `Tests/Modules/RecipeList/UI/Scenes/RecipeListViewModelTests.swift` (add a second suite)

**Interfaces:**
- Consumes: everything from Task 7.
- Produces: `Error.failureDetail: String?`; and on `RecipeListViewModel`, `func loadNextPageIfNeeded(after cardID: String) async` and `func retryNextPage() async`.

`nextPageError` needs the same rule `SectionState` already applies — suppress a detail that merely repeats the generic heading. Rather than write that rule twice, it moves onto `Error` and `SectionState` calls it.

- [ ] **Step 1: Write the failing tests**

Append a second suite to `Tests/Modules/RecipeList/UI/Scenes/RecipeListViewModelTests.swift`:

```swift
// MARK: - Paging

@MainActor
struct RecipeListViewModelPagingTests {
  @Test
  func loadFirstPage_oneFullResultSet_neverAsksForASecondPage() async {
    let service = MockRecipeService(recipes: Self.page(
      ids: ["rcp-001"],
      total: 6,
      lastPage: 1
    ))
    let sut = Self.makeSUT(service: service)
    await sut.loadFirstPage()

    await sut.loadNextPageIfNeeded(after: "rcp-001")

    #expect(service.recipes.callCount == 1)
  }

  @Test
  func loadNextPageIfNeeded_atTheTail_appendsTheNextPage() async {
    let service = Self.twoPageService()
    let sut = Self.makeSUT(service: service)
    await sut.loadFirstPage()

    await sut.loadNextPageIfNeeded(after: "rcp-001")

    #expect(sut.recipes.value?.map(\.id) == ["rcp-001", "rcp-002"])
  }

  @Test
  func loadNextPageIfNeeded_notAtTheTail_makesNoRequest() async {
    let service = Self.twoPageService(firstPageIDs: [
      "rcp-001",
      "rcp-009",
    ])
    let sut = Self.makeSUT(service: service)
    await sut.loadFirstPage()

    await sut.loadNextPageIfNeeded(after: "rcp-001")

    #expect(service.recipes.callCount == 1)
  }

  @Test
  func loadNextPageIfNeeded_aPageRepeatingARowAlreadyHeld_doesNotDuplicateIt() async {
    let service = Self.twoPageService(secondPageIDs: [
      "rcp-001",
      "rcp-002",
    ])
    let sut = Self.makeSUT(service: service)
    await sut.loadFirstPage()

    await sut.loadNextPageIfNeeded(after: "rcp-001")

    #expect(sut.recipes.value?.map(\.id) == ["rcp-001", "rcp-002"])
  }

  @Test
  func loadNextPageIfNeeded_whileAPageIsInFlight_makesNoSecondRequest() async {
    let service = Self.twoPageService()
    let sut = Self.makeSUT(service: service)
    await sut.loadFirstPage()
    let reentry = Reentry()

    service.recipes.responds { request in
      if request.page.index == 2, await reentry.isFirstTime() {
        await sut.loadNextPageIfNeeded(after: "rcp-001")
      }

      return Self.page(
        ids: ["rcp-002"],
        total: 40,
        currentPage: 2,
        lastPage: 2
      )
    }

    await sut.loadNextPageIfNeeded(after: "rcp-001")

    #expect(service.recipes.requests.count { $0.page.index == 2 } == 1)
  }

  @Test
  func loadNextPageIfNeeded_fails_keepsTheRowsAndReportsTheFailure() async {
    let service = Self.twoPageService()
    let sut = Self.makeSUT(service: service)
    await sut.loadFirstPage()
    service.recipes.fails(with: AppError.noInternetConnection)

    await sut.loadNextPageIfNeeded(after: "rcp-001")

    #expect(sut.recipes.value?.map(\.id) == ["rcp-001"])
    #expect(sut.nextPageError != nil)
    #expect(sut.isLoadingNextPage == false)
  }

  @Test
  func loadNextPageIfNeeded_afterAFailure_doesNotRetryByItself() async {
    let service = Self.twoPageService()
    let sut = Self.makeSUT(service: service)
    await sut.loadFirstPage()
    service.recipes.fails(with: AppError.noInternetConnection)
    await sut.loadNextPageIfNeeded(after: "rcp-001")
    let callsAfterTheFailure = service.recipes.callCount

    await sut.loadNextPageIfNeeded(after: "rcp-001")

    #expect(service.recipes.callCount == callsAfterTheFailure)
  }

  @Test
  func retryNextPage_asksForTheSamePageAgainAndClearsTheError() async {
    let service = Self.twoPageService()
    let sut = Self.makeSUT(service: service)
    await sut.loadFirstPage()
    service.recipes.fails(with: AppError.noInternetConnection)
    await sut.loadNextPageIfNeeded(after: "rcp-001")
    service.recipes.returns(Self.page(
      ids: ["rcp-002"],
      total: 40,
      currentPage: 2,
      lastPage: 2
    ))

    await sut.retryNextPage()

    #expect(service.recipes.lastRequest?.page.index == 2)
    #expect(sut.nextPageError == nil)
    #expect(sut.recipes.value?.map(\.id) == ["rcp-001", "rcp-002"])
  }

  @Test
  func loadNextPageIfNeeded_cancelled_leavesNoErrorAndNoSpinner() async {
    let service = Self.twoPageService()
    let sut = Self.makeSUT(service: service)
    await sut.loadFirstPage()
    service.recipes.fails(with: CancellationError())

    await sut.loadNextPageIfNeeded(after: "rcp-001")

    #expect(sut.nextPageError == nil)
    #expect(sut.isLoadingNextPage == false)
    #expect(sut.recipes.value?.map(\.id) == ["rcp-001"])
  }

  @Test
  func loadNextPageIfNeeded_theLastPage_stopsThePager() async {
    let service = Self.twoPageService()
    let sut = Self.makeSUT(service: service)
    await sut.loadFirstPage()
    await sut.loadNextPageIfNeeded(after: "rcp-001")
    let callsAfterPageTwo = service.recipes.callCount

    await sut.loadNextPageIfNeeded(after: "rcp-002")

    #expect(service.recipes.callCount == callsAfterPageTwo)
  }
}

/// Lets one stubbed response re-enter the view model exactly once, to prove the in-flight
/// guard holds without a sleep or a continuation.
actor Reentry {
  private var hasRun = false

  func isFirstTime() -> Bool {
    defer { hasRun = true }

    return !hasRun
  }
}

// MARK: - Helpers

private extension RecipeListViewModelPagingTests {
  static func makeSUT(
    request: RecipeListRequest = .all(),
    service: RecipeServiceProtocol = MockRecipeService()
  ) -> RecipeListViewModel {
    RecipeListViewModel(
      request: request,
      recipeService: service
    )
  }

  static func page(
    ids: [String],
    total: Int? = nil,
    currentPage: Int = 1,
    lastPage: Int = 1
  ) -> RecipeListPage {
    RecipeListPage(
      recipes: ids.map { .dummy(id: $0) },
      meta: .dummy(
        total: total ?? ids.count,
        perPage: 20,
        from: 1,
        to: ids.count,
        currentPage: currentPage,
        lastPage: lastPage
      )
    )
  }

  /// Two pages of one row each, so the tail row's id is predictable.
  static func twoPageService(
    firstPageIDs: [String] = ["rcp-001"],
    secondPageIDs: [String] = ["rcp-002"]
  ) -> MockRecipeService {
    let service = MockRecipeService()

    service.recipes.responds { request in
      request.page.index == 1
        ? page(
          ids: firstPageIDs,
          total: 40,
          currentPage: 1,
          lastPage: 2
        )
        : page(
          ids: secondPageIDs,
          total: 40,
          currentPage: 2,
          lastPage: 2
        )
    }

    return service
  }
}
```

If the compiler rejects capturing `sut` inside the `responds` closure, write the closure as `service.recipes.responds { @MainActor request in` — the closure is non-`Sendable`, so it inherits the suite's isolation and the capture is legal.

- [ ] **Step 2: Run the tests to verify they fail**

Run the single-suite command with `-only-testing:Tests/RecipeListViewModelPagingTests`.
Expected: FAIL to compile — "value of type 'RecipeListViewModel' has no member 'loadNextPageIfNeeded'".

- [ ] **Step 3: Move the failure-detail rule onto `Error`**

Create `RecipeTest/Modules/Shared/Services/ErrorHandling/Error+FailureDetail.swift`:

```swift
//
//  Error+FailureDetail.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

nonisolated extension Error {
  /// What to add beneath the generic failure heading, or `nil` when this error describes
  /// itself with that same sentence and would print it twice.
  var failureDetail: String? {
    let description = localizedDescription

    guard description != String(localized: .Shared.sharedErrorSomethingWentWrong) else {
      return nil
    }

    return description
  }
}
```

Then in `RecipeTest/Modules/Shared/UI/Models/SectionState.swift`, delete the whole `// MARK: - Helpers` extension holding `failureDetail(for:)`, and change the one call site inside `recovering(from:)`:

```swift
    return .failed(error.failureDetail)
```

- [ ] **Step 4: Add the pager**

In `RecipeTest/Modules/RecipeList/UI/Scenes/RecipeListViewModel.swift`, append to the `// MARK: - Inputs` extension:

```swift
  /// The view reports which row appeared; this decides whether that means anything. Guards
  /// against a tail row reappearing, a page already in flight, and a failure the user has
  /// not retried yet.
  func loadNextPageIfNeeded(after cardID: String) async {
    guard
      let nextPage,
      !isLoadingNextPage,
      nextPageError == nil,
      recipes.value?.last?.id == cardID
    else { return }

    await loadNextPage(nextPage)
  }

  func retryNextPage() async {
    guard
      let nextPage,
      !isLoadingNextPage
    else { return }

    nextPageError = nil

    await loadNextPage(nextPage)
  }
```

and add a new extension below it:

```swift
// MARK: - Helpers

private extension RecipeListViewModel {
  func loadNextPage(_ page: Page) async {
    let generation = self.generation
    isLoadingNextPage = true

    do {
      let loaded = try await recipeService.getRecipes(
        query: request.query,
        page: page
      )

      // A facet was removed while this was in flight: it answers a query the screen no
      // longer shows, and appending it would mix two result sets.
      guard generation == self.generation else { return }

      resultTotal = loaded.meta.total
      append(loaded.recipes)
      nextPage = loaded.hasLoadedAllData ? nil : page.next
      isLoadingNextPage = false
    } catch {
      guard generation == self.generation else { return }

      isLoadingNextPage = false

      // Leaving the screen must not leave a failure waiting for the next visit.
      guard !error.isCancellation else { return }

      nextPageError = error.failureDetail ?? String(localized: .Shared.sharedErrorSomethingWentWrong)
    }
  }

  /// Ids already held are dropped rather than appended: a repeated row would put a duplicate
  /// id into a `ForEach`, and SwiftUI's diffing stops being able to tell the rows apart.
  func append(_ summaries: [RecipeSummary]) {
    let current = recipes.value ?? []
    let known = Set(current.map(\.id))
    let appended = summaries
      .filter { !known.contains($0.id) }
      .map(RecipeCardViewModel.init)

    recipes = .rows(current + appended)
  }
}
```

- [ ] **Step 5: Run the tests to verify they pass**

Run the single-suite command with `-only-testing:Tests/RecipeListViewModelPagingTests`.
Expected: PASS, 10 tests.

- [ ] **Step 6: Run the whole suite**

Run the full test command. Expected: PASS — `SectionStateTests` must still pass after the helper moved.

- [ ] **Step 7: Commit**

```bash
git add RecipeTest/Modules/Shared/Services/ErrorHandling/Error+FailureDetail.swift \
  RecipeTest/Modules/Shared/UI/Models/SectionState.swift \
  RecipeTest/Modules/RecipeList/UI/Scenes/RecipeListViewModel.swift \
  Tests/Modules/RecipeList/UI/Scenes/RecipeListViewModelTests.swift
git commit -m "[list] Page through a results list one page at a time"
```

---

## Task 9: The list view model — facets and empty copy

**Files:**
- Modify: `RecipeTest/Modules/RecipeList/UI/Scenes/RecipeListViewModel.swift`
- Test: `Tests/Modules/RecipeList/UI/Scenes/RecipeListViewModelTests.swift` (add a third suite)

**Interfaces:**
- Produces: `facetChips`, `showsClearAllChips`, `emptyTitle`, `emptyDetail`, `showsClearFiltersButton`, `remove(facet:)`, `clearFacets()`. At the end of this task `RecipeListViewModel` conforms to `RecipeListViewModelProtocol`.

- [ ] **Step 1: Write the failing tests**

Append a third suite to `Tests/Modules/RecipeList/UI/Scenes/RecipeListViewModelTests.swift`:

```swift
// MARK: - Facets

@MainActor
struct RecipeListViewModelFacetTests {
  @Test
  func facetChips_areDerivedFromTheRequestsQuery() {
    let sut = Self.makeSUT(request: .all(query: RecipeQuery(
      isVegetarian: true,
      servings: .four
    )))

    #expect(sut.facetChips.map(\.label) == ["Vegetarian", "4 servings"])
  }

  @Test
  func facetChips_aCategoryOnlyRequest_hasNone() {
    let sut = Self.makeSUT(request: .category(.dummy(name: "Desserts")))

    #expect(sut.facetChips.isEmpty)
  }

  @Test
  func showsClearAllChips_onlyOnceMoreThanOneFacetIsSet() {
    #expect(Self.makeSUT(request: .all(query: RecipeQuery(isVegetarian: true)))
      .showsClearAllChips == false)
    #expect(Self.makeSUT(request: .all(query: RecipeQuery(
      isVegetarian: true,
      servings: .two
    ))).showsClearAllChips)
  }

  @Test
  func remove_reloadsFromPageOneWithoutThatFacet() async {
    let service = MockRecipeService()
    let sut = Self.makeSUT(
      request: .all(query: RecipeQuery(
        isVegetarian: true,
        servings: .two
      )),
      service: service
    )
    await sut.loadFirstPage()

    await sut.remove(facet: .vegetarian(true))

    #expect(service.recipes.lastRequest?.query.isVegetarian == nil)
    #expect(service.recipes.lastRequest?.query.servings == .two)
    #expect(service.recipes.lastRequest?.page.index == 1)
    #expect(sut.facetChips.map(\.label) == ["2 servings"])
  }

  @Test
  func clearFacets_dropsThemAllAndKeepsTheCategory() async {
    let service = MockRecipeService()
    var query = RecipeQuery(category: "Vegan")
    query.isVegetarian = true
    query.servings = .two
    let sut = Self.makeSUT(
      request: .all(query: query),
      service: service
    )
    await sut.loadFirstPage()

    await sut.clearFacets()

    #expect(sut.facetChips.isEmpty)
    #expect(service.recipes.lastRequest?.query.category == "Vegan")
  }

  @Test
  func remove_whileAPageIsInFlight_discardsThatPage() async {
    let service = MockRecipeService()
    service.recipes.responds { request in
      RecipeListPage(
        recipes: [.dummy(id: request.page.index == 1 ? "rcp-001" : "rcp-002")],
        meta: .dummy(
          total: 40,
          perPage: 20,
          from: 1,
          to: 1,
          currentPage: request.page.index,
          lastPage: 2
        )
      )
    }
    let sut = Self.makeSUT(
      request: .all(query: RecipeQuery(isVegetarian: true)),
      service: service
    )
    await sut.loadFirstPage()

    async let paging: Void = sut.loadNextPageIfNeeded(after: "rcp-001")
    await sut.remove(facet: .vegetarian(true))
    await paging

    #expect(sut.recipes.value?.map(\.id) == ["rcp-001"])
    #expect(sut.recipes.value?.count == 1)
  }

  @Test
  func emptyCopy_withFacetsSet_blamesTheFilters() {
    let sut = Self.makeSUT(request: .all(query: RecipeQuery(isVegetarian: true)))

    #expect(String(localized: sut.emptyTitle) == "No recipes match your filters")
    #expect(sut.emptyDetail != nil)
    #expect(sut.showsClearFiltersButton)
  }

  @Test
  func emptyCopy_withNoFacets_doesNotBlameAFilterNobodySet() {
    let sut = Self.makeSUT(request: .category(.dummy(name: "Desserts")))

    #expect(String(localized: sut.emptyTitle) == "No recipes here yet")
    #expect(sut.emptyDetail == nil)
    #expect(sut.showsClearFiltersButton == false)
  }
}

// MARK: - Helpers

private extension RecipeListViewModelFacetTests {
  static func makeSUT(
    request: RecipeListRequest = .all(),
    service: RecipeServiceProtocol = MockRecipeService()
  ) -> RecipeListViewModel {
    RecipeListViewModel(
      request: request,
      recipeService: service
    )
  }
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run the single-suite command with `-only-testing:Tests/RecipeListViewModelFacetTests`.
Expected: FAIL to compile — "value of type 'RecipeListViewModel' has no member 'facetChips'".

- [ ] **Step 3: Add the facet getters**

Append to the `// MARK: - Getters` extension in `RecipeListViewModel.swift`:

```swift
  var facetChips: [RecipeFacetChipViewModel] {
    request.query.activeFacets.map(RecipeFacetChipViewModel.init)
  }

  /// One chip removes itself; "Clear all" only earns its place once there are several.
  var showsClearAllChips: Bool {
    facetChips.count > 1
  }

  /// "No recipes match your filters" is a lie when the user set no filter — which is every
  /// empty category, the only empty state the category entry point can reach today.
  var emptyTitle: LocalizedStringResource {
    hasFacets
      ? .RecipeList.recipeListEmptyTitle
      : .RecipeList.recipeListEmptyNoResultsTitle
  }

  var emptyDetail: LocalizedStringResource? {
    hasFacets ? .RecipeList.recipeListEmptyDetail : nil
  }

  var showsClearFiltersButton: Bool {
    hasFacets
  }
```

and add to the private getters extension:

```swift
  var hasFacets: Bool {
    !request.query.activeFacets.isEmpty
  }
```

- [ ] **Step 4: Add the facet inputs**

Append to the `// MARK: - Inputs` extension:

```swift
  func remove(facet: RecipeQueryFacet) async {
    request = request.replacingQuery(request.query.removing(facet))

    await loadFirstPage()
  }

  func clearFacets() async {
    request = request.replacingQuery(request.query.clearingFacets())

    await loadFirstPage()
  }
```

- [ ] **Step 5: Conform to the protocol**

Change the type declaration to:

```swift
final class RecipeListViewModel: RecipeListViewModelProtocol {
```

- [ ] **Step 6: Run the tests to verify they pass**

Run the single-suite command with `-only-testing:Tests/RecipeListViewModelFacetTests`.
Expected: PASS, 8 tests.

- [ ] **Step 7: Run the whole suite**

Run the full test command. Expected: PASS, all three list suites plus everything that existed before.

- [ ] **Step 8: Commit**

```bash
git add RecipeTest/Modules/RecipeList/UI/Scenes/RecipeListViewModel.swift \
  Tests/Modules/RecipeList/UI/Scenes/RecipeListViewModelTests.swift
git commit -m "[list] Remove a facet and reload the results"
```

---
## Task 10: The row presentations

**Files:**
- Create: `RecipeTest/Mocks/Modules/RecipeList/UI/Scenes/RecipeList/MockRecipeListViewModel.swift`
- Create: `RecipeTest/Modules/RecipeList/UI/Components/RecipeCardMetadata.swift`
- Create: `RecipeTest/Modules/RecipeList/UI/Components/RecipeCard.swift`
- Create: `RecipeTest/Modules/RecipeList/UI/Components/RecipeRow.swift`

`RecipeCardMetadata` exists because the clock-and-servings strip is drawn identically by the grid card and the list row, and duplicating it in both is the one thing that would let them drift.

**Interfaces:**
- Consumes: `RecipeCardViewModelProtocol` (Task 5), `RecipeListViewModelProtocol` (Tasks 7–9), `CachedAsyncImage`, `SingleResult<RecipeSummary>`.
- Produces: `RecipeCard(viewModel:onTap:)`, `RecipeRow(viewModel:onTap:)`, `RecipeCardMetadata(viewModel:)`, and `MockRecipeListViewModel` with the scenario factories Tasks 11–16 preview against.

No unit tests — these are views. They are verified by the build and by their previews.

- [ ] **Step 1: Write the mock screen view model**

Create `RecipeTest/Mocks/Modules/RecipeList/UI/Scenes/RecipeList/MockRecipeListViewModel.swift`:

```swift
//
//  MockRecipeListViewModel.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

#if DEBUG
  @Observable
  final class MockRecipeListViewModel: RecipeListViewModelProtocol {
    var title: String
    var searchPlaceholder: String
    var recipes: SectionState<[RecipeCardViewModel]>
    var resultCountText: String?
    var facetChips: [RecipeFacetChipViewModel]
    var emptyTitle: LocalizedStringResource
    var emptyDetail: LocalizedStringResource?
    var showsClearFiltersButton: Bool
    var isLoadingNextPage: Bool
    var nextPageError: String?
    var viewMode: RecipeListViewMode

    init(
      title: String = "Desserts",
      searchPlaceholder: String = "Search Desserts",
      recipes: SectionState<[RecipeCardViewModel]> = .loading,
      resultCountText: String? = nil,
      facetChips: [RecipeFacetChipViewModel] = [],
      emptyTitle: LocalizedStringResource = .RecipeList.recipeListEmptyNoResultsTitle,
      emptyDetail: LocalizedStringResource? = nil,
      showsClearFiltersButton: Bool = false,
      isLoadingNextPage: Bool = false,
      nextPageError: String? = nil,
      viewMode: RecipeListViewMode = .grid
    ) {
      self.title = title
      self.searchPlaceholder = searchPlaceholder
      self.recipes = recipes
      self.resultCountText = resultCountText
      self.facetChips = facetChips
      self.emptyTitle = emptyTitle
      self.emptyDetail = emptyDetail
      self.showsClearFiltersButton = showsClearFiltersButton
      self.isLoadingNextPage = isLoadingNextPage
      self.nextPageError = nextPageError
      self.viewMode = viewMode
    }

    var showsClearAllChips: Bool {
      facetChips.count > 1
    }

    func loadFirstPage() async {}

    func loadNextPageIfNeeded(after cardID: String) async {}

    func retryNextPage() async {}

    func remove(facet: RecipeQueryFacet) async {}

    func clearFacets() async {}

    func select(viewMode: RecipeListViewMode) {
      self.viewMode = viewMode
    }
  }

  // MARK: - Scenarios

  extension MockRecipeListViewModel {
    static func loaded(viewMode: RecipeListViewMode = .grid) -> MockRecipeListViewModel {
      MockRecipeListViewModel(
        recipes: .loaded(sampleCards),
        resultCountText: "6 recipes",
        viewMode: viewMode
      )
    }

    static func loading() -> MockRecipeListViewModel {
      MockRecipeListViewModel(recipes: .loading)
    }

    static func filtered() -> MockRecipeListViewModel {
      MockRecipeListViewModel(
        recipes: .loaded(sampleCards),
        resultCountText: "2 recipes",
        facetChips: [
          RecipeFacetChipViewModel(facet: .vegetarian(true)),
          RecipeFacetChipViewModel(facet: .servings(.four)),
          RecipeFacetChipViewModel(facet: .exclude("peanuts")),
        ]
      )
    }

    static func emptyCategory() -> MockRecipeListViewModel {
      MockRecipeListViewModel(recipes: .empty)
    }

    static func emptyFiltered() -> MockRecipeListViewModel {
      MockRecipeListViewModel(
        recipes: .empty,
        facetChips: [RecipeFacetChipViewModel(facet: .vegetarian(true))],
        emptyTitle: .RecipeList.recipeListEmptyTitle,
        emptyDetail: .RecipeList.recipeListEmptyDetail,
        showsClearFiltersButton: true
      )
    }

    static func failed() -> MockRecipeListViewModel {
      MockRecipeListViewModel(recipes: .failed("The Internet connection appears to be offline."))
    }

    static func paging() -> MockRecipeListViewModel {
      MockRecipeListViewModel(
        recipes: .loaded(sampleCards),
        resultCountText: "36 recipes",
        isLoadingNextPage: true
      )
    }

    static func pagingFailed() -> MockRecipeListViewModel {
      MockRecipeListViewModel(
        recipes: .loaded(sampleCards),
        resultCountText: "36 recipes",
        nextPageError: "The Internet connection appears to be offline."
      )
    }
  }

  // MARK: - Getters

  extension MockRecipeListViewModel {
    static var sampleCards: [RecipeCardViewModel] {
      [
        sampleCard(
          id: "rcp-001",
          title: "Chicken Adobo",
          cuisine: "filipino",
          category: "Meal"
        ),
        sampleCard(
          id: "rcp-002",
          title: "Pavlova",
          cuisine: "australian",
          category: "Desserts"
        ),
        sampleCard(
          id: "rcp-003",
          title: "Gỏi Cuốn",
          cuisine: "vietnamese",
          category: "Snacks"
        ),
        sampleCard(
          id: "rcp-004",
          title: "Pão de Queijo",
          cuisine: "brazilian",
          category: "Snacks"
        ),
      ]
    }

    /// No cooking time and no servings — the row must still draw, and still announce.
    static var bareCard: RecipeCardViewModel {
      RecipeCardViewModel(summary: .dummy(
        id: "rcp-099",
        title: "Sinangag",
        heroImageURL: nil,
        category: nil,
        cuisine: nil,
        totalTimeMinutes: nil,
        servings: nil
      ))
    }

    private static func sampleCard(
      id: String,
      title: String,
      cuisine: String,
      category: String
    ) -> RecipeCardViewModel {
      RecipeCardViewModel(summary: .dummy(
        id: id,
        title: title,
        heroImageURL: nil,
        category: category,
        cuisine: cuisine
      ))
    }
  }
#endif
```

- [ ] **Step 2: Write the shared metadata strip**

Create `RecipeTest/Modules/RecipeList/UI/Components/RecipeCardMetadata.swift`:

```swift
//
//  RecipeCardMetadata.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

/// The clock-and-servings strip both row presentations draw. Renders nothing at all when the
/// recipe carries neither metric, rather than leaving a stray separator behind.
struct RecipeCardMetadata: View {
  let viewModel: any RecipeCardViewModelProtocol

  @Environment(\.dynamicTypeSize) private var dynamicTypeSize

  var body: some View {
    layout {
      if let cookingTimeText = viewModel.cookingTimeText {
        metric(
          symbolName: clockSymbolName,
          text: cookingTimeText
        )
      }

      if let servingsText = viewModel.servingsText {
        metric(
          symbolName: servingsSymbolName,
          text: servingsText
        )
      }
    }
  }
}

// MARK: - Getters

private extension RecipeCardMetadata {
  var layout: AnyLayout {
    dynamicTypeSize.isAccessibilitySize
      ? AnyLayout(VStackLayout(
        alignment: .leading,
        spacing: itemSpacing
      ))
      : AnyLayout(HStackLayout(spacing: itemSpacing))
  }

  var itemSpacing: CGFloat {
    12
  }

  var contentSpacing: CGFloat {
    4
  }

  var clockSymbolName: String {
    "clock"
  }

  var servingsSymbolName: String {
    "person.2"
  }
}

// MARK: - Subviews

private extension RecipeCardMetadata {
  func metric(
    symbolName: String,
    text: String
  ) -> some View {
    HStack(spacing: contentSpacing) {
      Image(systemName: symbolName)
        .foregroundStyle(.themeColor(.iconsSecondary))

      Text(text)
        .themeTextStyle(.captionRegular)
        .themeColor(.textSecondary)
    }
  }
}

#if DEBUG
  #Preview("Both metrics") {
    RecipeCardMetadata(viewModel: MockRecipeListViewModel.sampleCards[0])
  }

  #Preview("Neither metric") {
    RecipeCardMetadata(viewModel: MockRecipeListViewModel.bareCard)
      .border(Color.themeColor(.bordersDefault))
  }
#endif
```

- [ ] **Step 3: Write the grid card**

Create `RecipeTest/Modules/RecipeList/UI/Components/RecipeCard.swift`:

```swift
//
//  RecipeCard.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

/// The grid presentation of one result: a square photograph above the name and metrics.
struct RecipeCard: View {
  let viewModel: any RecipeCardViewModelProtocol
  let onTap: SingleResult<RecipeSummary>

  var body: some View {
    Button(
      action: { onTap(viewModel.summary) },
      label: {
        VStack(
          alignment: .leading,
          spacing: contentSpacing
        ) {
          photograph

          VStack(
            alignment: .leading,
            spacing: contentSpacing
          ) {
            Text(viewModel.title)
              .themeTextStyle(.subheadlineSemibold)
              .themeColor(.textPrimary)
              .multilineTextAlignment(.leading)

            RecipeCardMetadata(viewModel: viewModel)
          }
          .frame(
            maxWidth: .infinity,
            alignment: .leading
          )
          .padding(
            .horizontal,
            textGutter
          )
          .padding(
            .bottom,
            textGutter
          )
        }
        .background(
          Color.themeColor(.surfacesBackground2),
          in: .rect(cornerRadius: cornerRadius)
        )
      }
    )
    .buttonStyle(.plain)
    .cardShadow()
    .accessibilityElement(children: .combine)
    .accessibilityLabel(Text(viewModel.accessibilityLabel))
    .accessibilityAddTraits(.isButton)
  }
}

// MARK: - Getters

private extension RecipeCard {
  var contentSpacing: CGFloat {
    8
  }

  var textGutter: CGFloat {
    12
  }

  var cornerRadius: CGFloat {
    20
  }
}

// MARK: - Subviews

private extension RecipeCard {
  var photograph: some View {
    CachedAsyncImage(url: viewModel.imageURL) {
      Color.themeColor(.surfacesBackground3)
    }
    .aspectRatio(contentMode: .fill)
    .frame(maxWidth: .infinity)
    .aspectRatio(
      1,
      contentMode: .fit
    )
    .clipShape(.rect(
      topLeadingRadius: cornerRadius,
      bottomLeadingRadius: 0,
      bottomTrailingRadius: 0,
      topTrailingRadius: cornerRadius
    ))
  }
}

#if DEBUG
  #Preview("Card") {
    RecipeCard(
      viewModel: MockRecipeListViewModel.sampleCards[0],
      onTap: { _ in }
    )
    .frame(width: 180)
    .frame(
      maxWidth: .infinity,
      maxHeight: .infinity
    )
    .background(Color.themeColor(.surfacesBackground))
  }

  #Preview("No photograph, no metrics") {
    RecipeCard(
      viewModel: MockRecipeListViewModel.bareCard,
      onTap: { _ in }
    )
    .frame(width: 180)
    .frame(
      maxWidth: .infinity,
      maxHeight: .infinity
    )
    .background(Color.themeColor(.surfacesBackground))
  }
#endif
```

- [ ] **Step 4: Write the list row**

Create `RecipeTest/Modules/RecipeList/UI/Components/RecipeRow.swift`:

```swift
//
//  RecipeRow.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

/// The list presentation of one result: a thumbnail beside the name, its cuisine and
/// category, and the same metrics the grid card draws.
struct RecipeRow: View {
  let viewModel: any RecipeCardViewModelProtocol
  let onTap: SingleResult<RecipeSummary>

  @ScaledMetric(relativeTo: .body) private var thumbnailSize: CGFloat = RecipeRow.baseThumbnailSize

  var body: some View {
    Button(
      action: { onTap(viewModel.summary) },
      label: {
        HStack(spacing: contentSpacing) {
          photograph

          VStack(
            alignment: .leading,
            spacing: textSpacing
          ) {
            Text(viewModel.title)
              .themeTextStyle(.subheadlineSemibold)
              .themeColor(.textPrimary)
              .multilineTextAlignment(.leading)

            if let cuisineAndCategory = viewModel.cuisineAndCategory {
              Text(cuisineAndCategory)
                .themeTextStyle(.captionRegular)
                .themeColor(.textSecondary)
            }

            RecipeCardMetadata(viewModel: viewModel)
          }

          Spacer(minLength: 0)
        }
        .padding(contentGutter)
        .background(
          Color.themeColor(.surfacesBackground2),
          in: .rect(cornerRadius: cornerRadius)
        )
      }
    )
    .buttonStyle(.plain)
    .cardShadow()
    .accessibilityElement(children: .combine)
    .accessibilityLabel(Text(viewModel.accessibilityLabel))
    .accessibilityAddTraits(.isButton)
  }
}

// MARK: - Getters

extension RecipeRow {
  static var baseThumbnailSize: CGFloat {
    88
  }
}

private extension RecipeRow {
  var contentSpacing: CGFloat {
    12
  }

  var textSpacing: CGFloat {
    4
  }

  var contentGutter: CGFloat {
    12
  }

  var cornerRadius: CGFloat {
    20
  }

  var thumbnailCornerRadius: CGFloat {
    14
  }
}

// MARK: - Subviews

private extension RecipeRow {
  var photograph: some View {
    CachedAsyncImage(url: viewModel.imageURL) {
      Color.themeColor(.surfacesBackground3)
    }
    .aspectRatio(contentMode: .fill)
    .frame(
      width: thumbnailSize,
      height: thumbnailSize
    )
    .clipShape(.rect(cornerRadius: thumbnailCornerRadius))
  }
}

#if DEBUG
  #Preview("Row") {
    RecipeRow(
      viewModel: MockRecipeListViewModel.sampleCards[0],
      onTap: { _ in }
    )
    .padding()
    .frame(
      maxWidth: .infinity,
      maxHeight: .infinity
    )
    .background(Color.themeColor(.surfacesBackground))
  }

  #Preview("No photograph, no metrics") {
    RecipeRow(
      viewModel: MockRecipeListViewModel.bareCard,
      onTap: { _ in }
    )
    .padding()
    .frame(
      maxWidth: .infinity,
      maxHeight: .infinity
    )
    .background(Color.themeColor(.surfacesBackground))
  }
#endif
```

- [ ] **Step 5: Build**

Run the build-only command. Expected: BUILD SUCCEEDED.

- [ ] **Step 6: Commit**

```bash
git add RecipeTest/Mocks/Modules/RecipeList/ \
  RecipeTest/Modules/RecipeList/UI/Components/RecipeCardMetadata.swift \
  RecipeTest/Modules/RecipeList/UI/Components/RecipeCard.swift \
  RecipeTest/Modules/RecipeList/UI/Components/RecipeRow.swift
git commit -m "[list] Add the grid card and the list row"
```

---

## Task 11: The filter chips

**Files:**
- Create: `RecipeTest/Modules/RecipeList/UI/Components/RecipeFacetChip.swift`
- Create: `RecipeTest/Modules/RecipeList/UI/Components/RecipeFacetChipRow.swift`

**Interfaces:**
- Consumes: `RecipeFacetChipViewModelProtocol` (Task 6), `RecipeListViewModelProtocol` (Tasks 7–9).
- Produces: `RecipeFacetChip(viewModel:onRemoveTap:)` and `RecipeFacetChipRow(viewModel:onRemoveTap:onClearAllTap:)`, where the removal closure is `SingleResult<RecipeQueryFacet>`.

- [ ] **Step 1: Write the chip**

Create `RecipeTest/Modules/RecipeList/UI/Components/RecipeFacetChip.swift`:

```swift
//
//  RecipeFacetChip.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

struct RecipeFacetChip: View {
  let viewModel: any RecipeFacetChipViewModelProtocol
  let onRemoveTap: SingleResult<RecipeQueryFacet>

  var body: some View {
    HStack(spacing: contentSpacing) {
      Text(viewModel.label)
        .themeTextStyle(.captionRegular)
        .themeColor(.textPrimary)

      Button(
        action: { onRemoveTap(viewModel.id) },
        label: {
          Image(systemName: removeSymbolName)
            .foregroundStyle(.themeColor(.iconsSecondary))
        }
      )
      .buttonStyle(.plain)
      .accessibilityLabel(Text(viewModel.removeAccessibilityLabel))
    }
    .padding(
      .horizontal,
      horizontalGutter
    )
    .padding(
      .vertical,
      verticalGutter
    )
    .background(
      Color.themeColor(background),
      in: .capsule
    )
  }
}

// MARK: - Getters

private extension RecipeFacetChip {
  var background: Color.ThemeColor {
    viewModel.isExclusion ? .complementaryShade3 : .surfacesFieldsAndTags
  }

  var contentSpacing: CGFloat {
    6
  }

  var horizontalGutter: CGFloat {
    12
  }

  var verticalGutter: CGFloat {
    6
  }

  var removeSymbolName: String {
    "xmark"
  }
}

#if DEBUG
  #Preview("Included") {
    RecipeFacetChip(
      viewModel: RecipeFacetChipViewModel(facet: .include("garlic")),
      onRemoveTap: { _ in }
    )
  }

  #Preview("Excluded") {
    RecipeFacetChip(
      viewModel: RecipeFacetChipViewModel(facet: .exclude("peanuts")),
      onRemoveTap: { _ in }
    )
  }
#endif
```

- [ ] **Step 2: Write the chip row**

Create `RecipeTest/Modules/RecipeList/UI/Components/RecipeFacetChipRow.swift`:

```swift
//
//  RecipeFacetChipRow.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

/// Renders nothing when the request carries no facets, which is every category tap today.
struct RecipeFacetChipRow: View {
  let viewModel: any RecipeListViewModelProtocol
  let onRemoveTap: SingleResult<RecipeQueryFacet>
  let onClearAllTap: VoidResult

  var body: some View {
    if !viewModel.facetChips.isEmpty {
      ScrollView(.horizontal) {
        HStack(spacing: contentSpacing) {
          ForEach(viewModel.facetChips) { chip in
            RecipeFacetChip(
              viewModel: chip,
              onRemoveTap: onRemoveTap
            )
          }

          if viewModel.showsClearAllChips {
            Button(
              action: onClearAllTap,
              label: { Text(.RecipeList.recipeListFacetsClearAll) }
            )
            .buttonStyle(.plain)
            .themeTextStyle(.captionBold)
            .foregroundStyle(.themeColor(.textBrandDefault))
          }
        }
        .padding(
          .horizontal,
          horizontalGutter
        )
      }
      .scrollIndicators(.hidden)
    }
  }
}

// MARK: - Getters

private extension RecipeFacetChipRow {
  var contentSpacing: CGFloat {
    8
  }

  var horizontalGutter: CGFloat {
    20
  }
}

#if DEBUG
  #Preview("Several facets") {
    RecipeFacetChipRow(
      viewModel: MockRecipeListViewModel.filtered(),
      onRemoveTap: { _ in },
      onClearAllTap: {}
    )
  }

  #Preview("No facets") {
    RecipeFacetChipRow(
      viewModel: MockRecipeListViewModel.loaded(),
      onRemoveTap: { _ in },
      onClearAllTap: {}
    )
    .border(Color.themeColor(.bordersDefault))
  }
#endif
```

- [ ] **Step 3: Build**

Run the build-only command. Expected: BUILD SUCCEEDED.

- [ ] **Step 4: Commit**

```bash
git add RecipeTest/Modules/RecipeList/UI/Components/RecipeFacetChip.swift \
  RecipeTest/Modules/RecipeList/UI/Components/RecipeFacetChipRow.swift
git commit -m "[list] Show the active filters as removable chips"
```

---

## Task 12: The toolbar

**Files:**
- Create: `RecipeTest/Modules/RecipeList/UI/Components/RecipeListViewModeToggle.swift`
- Create: `RecipeTest/Modules/RecipeList/UI/Components/RecipeListToolbar.swift`

**Interfaces:**
- Produces: `RecipeListViewModeToggle(selected:onSelect:)` and `RecipeListToolbar(viewModel:onViewModeSelect:)`, where `onSelect` is `SingleResult<RecipeListViewMode>`.

- [ ] **Step 1: Write the toggle**

Create `RecipeTest/Modules/RecipeList/UI/Components/RecipeListViewModeToggle.swift`:

```swift
//
//  RecipeListViewModeToggle.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

/// The prototype's segmented control, indicator and all. A pair of `Button`s rather than a
/// `Picker`, because the selected capsule slides between them.
struct RecipeListViewModeToggle: View {
  let selected: RecipeListViewMode
  let onSelect: SingleResult<RecipeListViewMode>

  @Namespace private var indicator

  var body: some View {
    HStack(spacing: 0) {
      ForEach(RecipeListViewMode.allCases, id: \.self) { mode in
        segment(for: mode)
      }
    }
    .padding(trackInset)
    .background(
      Color.themeColor(.surfacesFieldsAndTags),
      in: .capsule
    )
    .accessibilityElement(children: .contain)
  }
}

// MARK: - Getters

private extension RecipeListViewModeToggle {
  var contentSpacing: CGFloat {
    6
  }

  var trackInset: CGFloat {
    4
  }

  var horizontalGutter: CGFloat {
    12
  }

  var verticalGutter: CGFloat {
    6
  }

  var indicatorID: String {
    "selected"
  }

  func label(for mode: RecipeListViewMode) -> LocalizedStringResource {
    switch mode {
    case .grid:
      .RecipeList.recipeListViewModeGrid

    case .list:
      .RecipeList.recipeListViewModeList
    }
  }

  func symbolName(for mode: RecipeListViewMode) -> String {
    switch mode {
    case .grid:
      "square.grid.2x2"

    case .list:
      "list.bullet"
    }
  }
}

// MARK: - Subviews

private extension RecipeListViewModeToggle {
  func segment(for mode: RecipeListViewMode) -> some View {
    let isSelected = mode == selected

    return Button(
      action: { onSelect(mode) },
      label: {
        HStack(spacing: contentSpacing) {
          Image(systemName: symbolName(for: mode))

          Text(label(for: mode))
            .themeTextStyle(.captionBold)
        }
        .foregroundStyle(.themeColor(isSelected ? .textInverted : .textPrimary))
        .padding(
          .horizontal,
          horizontalGutter
        )
        .padding(
          .vertical,
          verticalGutter
        )
        .background {
          if isSelected {
            Capsule()
              .fill(Color.themeColor(.surfacesBrandDefault))
              .matchedGeometryEffect(
                id: indicatorID,
                in: indicator
              )
          }
        }
      }
    )
    .buttonStyle(.plain)
    .accessibilityLabel(Text(label(for: mode)))
    .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
  }
}

#if DEBUG
  #Preview("Grid selected") {
    RecipeListViewModeToggle(
      selected: .grid,
      onSelect: { _ in }
    )
  }

  #Preview("List selected") {
    RecipeListViewModeToggle(
      selected: .list,
      onSelect: { _ in }
    )
  }
#endif
```

- [ ] **Step 2: Write the toolbar**

Create `RecipeTest/Modules/RecipeList/UI/Components/RecipeListToolbar.swift`:

```swift
//
//  RecipeListToolbar.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

struct RecipeListToolbar: View {
  let viewModel: any RecipeListViewModelProtocol
  let onViewModeSelect: SingleResult<RecipeListViewMode>

  var body: some View {
    HStack(spacing: contentSpacing) {
      if let resultCountText = viewModel.resultCountText {
        Text(resultCountText)
          .themeTextStyle(.footnoteRegular)
          .themeColor(.textSecondary)
      }

      Spacer(minLength: 0)

      RecipeListViewModeToggle(
        selected: viewModel.viewMode,
        onSelect: onViewModeSelect
      )
    }
    .padding(
      .horizontal,
      horizontalGutter
    )
  }
}

// MARK: - Getters

private extension RecipeListToolbar {
  var contentSpacing: CGFloat {
    12
  }

  var horizontalGutter: CGFloat {
    20
  }
}

#if DEBUG
  #Preview("With a count") {
    RecipeListToolbar(
      viewModel: MockRecipeListViewModel.loaded(),
      onViewModeSelect: { _ in }
    )
  }

  #Preview("Before the count lands") {
    RecipeListToolbar(
      viewModel: MockRecipeListViewModel.loading(),
      onViewModeSelect: { _ in }
    )
  }
#endif
```

- [ ] **Step 3: Build**

Run the build-only command. Expected: BUILD SUCCEEDED.

- [ ] **Step 4: Commit**

```bash
git add RecipeTest/Modules/RecipeList/UI/Components/RecipeListViewModeToggle.swift \
  RecipeTest/Modules/RecipeList/UI/Components/RecipeListToolbar.swift
git commit -m "[list] Add the result count and the view mode toggle"
```

---

## Task 13: The empty state and the paging footer

**Files:**
- Create: `RecipeTest/Modules/RecipeList/UI/Components/RecipeListEmptyState.swift`
- Create: `RecipeTest/Modules/RecipeList/UI/Components/RecipeListFooter.swift`

**Interfaces:**
- Produces: `RecipeListEmptyState(viewModel:onClearFiltersTap:)` and `RecipeListFooter(viewModel:onRetryTap:)`.

- [ ] **Step 1: Write the empty state**

Create `RecipeTest/Modules/RecipeList/UI/Components/RecipeListEmptyState.swift`:

```swift
//
//  RecipeListEmptyState.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

/// Not `SectionStateView`: that models a retry, and an empty results list offers to clear the
/// filters instead. Which copy it shows is the view model's decision, not this view's.
struct RecipeListEmptyState: View {
  let viewModel: any RecipeListViewModelProtocol
  let onClearFiltersTap: VoidResult

  var body: some View {
    VStack(spacing: contentSpacing) {
      Text(viewModel.emptyTitle)
        .themeTextStyle(.bodyBold)
        .themeColor(.textPrimary)
        .multilineTextAlignment(.center)

      if let emptyDetail = viewModel.emptyDetail {
        Text(emptyDetail)
          .themeTextStyle(.subheadlineRegular)
          .themeColor(.textSecondary)
          .multilineTextAlignment(.center)
      }

      if viewModel.showsClearFiltersButton {
        Button(
          action: onClearFiltersTap,
          label: { Text(.RecipeList.recipeListEmptyClearFilters) }
        )
        .buttonStyle(.plain)
        .themeTextStyle(.bodyBold)
        .foregroundStyle(.themeColor(.textBrandDefault))
      }
    }
    .frame(
      maxWidth: .infinity,
      minHeight: minHeight
    )
    .padding(
      .horizontal,
      horizontalGutter
    )
  }
}

// MARK: - Getters

private extension RecipeListEmptyState {
  var contentSpacing: CGFloat {
    12
  }

  var minHeight: CGFloat {
    240
  }

  var horizontalGutter: CGFloat {
    20
  }
}

#if DEBUG
  #Preview("An empty category") {
    RecipeListEmptyState(
      viewModel: MockRecipeListViewModel.emptyCategory(),
      onClearFiltersTap: {}
    )
  }

  #Preview("Filtered to nothing") {
    RecipeListEmptyState(
      viewModel: MockRecipeListViewModel.emptyFiltered(),
      onClearFiltersTap: {}
    )
  }
#endif
```

- [ ] **Step 2: Write the footer**

Create `RecipeTest/Modules/RecipeList/UI/Components/RecipeListFooter.swift`:

```swift
//
//  RecipeListFooter.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

/// Sits below the last loaded row. A failed page is reported here and never over the rows the
/// user already has.
struct RecipeListFooter: View {
  let viewModel: any RecipeListViewModelProtocol
  let onRetryTap: VoidResult

  var body: some View {
    if viewModel.isLoadingNextPage {
      ProgressView()
        .tint(.themeColor(.iconsBrandDefault))
        .frame(
          maxWidth: .infinity,
          minHeight: minHeight
        )
        .accessibilityLabel(Text(.RecipeList.recipeListFooterLoadingAccessibilityLabel))
    } else if let nextPageError = viewModel.nextPageError {
      VStack(spacing: contentSpacing) {
        Text(nextPageError)
          .themeTextStyle(.subheadlineRegular)
          .themeColor(.textSecondary)
          .multilineTextAlignment(.center)

        Button(
          action: onRetryTap,
          label: { Text(.Shared.sharedRetry) }
        )
        .buttonStyle(.plain)
        .themeTextStyle(.bodyBold)
        .foregroundStyle(.themeColor(.textBrandDefault))
      }
      .frame(
        maxWidth: .infinity,
        minHeight: minHeight
      )
      .padding(
        .horizontal,
        horizontalGutter
      )
    }
  }
}

// MARK: - Getters

private extension RecipeListFooter {
  var contentSpacing: CGFloat {
    8
  }

  var minHeight: CGFloat {
    64
  }

  var horizontalGutter: CGFloat {
    20
  }
}

#if DEBUG
  #Preview("Loading a page") {
    RecipeListFooter(
      viewModel: MockRecipeListViewModel.paging(),
      onRetryTap: {}
    )
  }

  #Preview("A page failed") {
    RecipeListFooter(
      viewModel: MockRecipeListViewModel.pagingFailed(),
      onRetryTap: {}
    )
  }
#endif
```

- [ ] **Step 3: Build**

Run the build-only command. Expected: BUILD SUCCEEDED.

- [ ] **Step 4: Commit**

```bash
git add RecipeTest/Modules/RecipeList/UI/Components/RecipeListEmptyState.swift \
  RecipeTest/Modules/RecipeList/UI/Components/RecipeListFooter.swift
git commit -m "[list] Add the empty state and the paging footer"
```

---
## Task 14: The results

**Files:**
- Create: `RecipeTest/Modules/RecipeList/UI/Components/RecipeListResults.swift`

**Interfaces:**
- Consumes: `RecipeCard`, `RecipeRow` (Task 10), `RecipeListEmptyState` (Task 13), `SectionStateView`.
- Produces: `RecipeListResults(viewModel:onRecipeTap:)`.

This view owns three things: which of the four section states is on screen, the grid-to-list morph, and the signal that a row reached the tail.

- [ ] **Step 1: Write the results view**

Create `RecipeTest/Modules/RecipeList/UI/Components/RecipeListResults.swift`:

```swift
//
//  RecipeListResults.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

struct RecipeListResults: View {
  let viewModel: any RecipeListViewModelProtocol
  let onRecipeTap: SingleResult<RecipeSummary>

  @Environment(\.dynamicTypeSize) private var dynamicTypeSize

  @Namespace private var cards

  var body: some View {
    if case .empty = viewModel.recipes {
      RecipeListEmptyState(
        viewModel: viewModel,
        onClearFiltersTap: { Task { await viewModel.clearFacets() } }
      )
    } else {
      SectionStateView(
        state: viewModel.recipes,
        minHeight: minHeight,
        // Never reached: `.empty` is answered above, because this list's empty state offers
        // to clear the filters and `SectionStateView` only models a retry.
        emptyMessage: viewModel.emptyTitle,
        onRetryTap: { Task { await viewModel.loadFirstPage() } },
        content: grid
      )
    }
  }
}

// MARK: - Getters

private extension RecipeListResults {
  /// One column in list mode, and one at accessibility sizes whatever the toggle says — a
  /// two-up grid at those sizes clips the name off every card.
  var columns: [GridItem] {
    Array(
      repeating: GridItem(
        .flexible(),
        spacing: itemSpacing
      ),
      count: columnCount
    )
  }

  var columnCount: Int {
    guard
      viewModel.viewMode == .grid,
      !dynamicTypeSize.isAccessibilitySize
    else { return 1 }

    return 2
  }

  var itemSpacing: CGFloat {
    16
  }

  var horizontalGutter: CGFloat {
    20
  }

  var minHeight: CGFloat {
    240
  }
}

// MARK: - Subviews

private extension RecipeListResults {
  func grid(_ loaded: [RecipeCardViewModel]) -> some View {
    LazyVGrid(
      columns: columns,
      spacing: itemSpacing
    ) {
      ForEach(loaded) { card in
        row(for: card)
          .matchedGeometryEffect(
            id: card.id,
            in: cards
          )
          .task { await viewModel.loadNextPageIfNeeded(after: card.id) }
      }
    }
    .padding(
      .horizontal,
      horizontalGutter
    )
    .animation(
      .snappy,
      value: viewModel.viewMode
    )
  }

  @ViewBuilder
  func row(for card: RecipeCardViewModel) -> some View {
    switch viewModel.viewMode {
    case .grid:
      RecipeCard(
        viewModel: card,
        onTap: onRecipeTap
      )

    case .list:
      RecipeRow(
        viewModel: card,
        onTap: onRecipeTap
      )
    }
  }
}

#if DEBUG
  #Preview("Grid") {
    ScrollView {
      RecipeListResults(
        viewModel: MockRecipeListViewModel.loaded(),
        onRecipeTap: { _ in }
      )
    }
    .background(Color.themeColor(.surfacesBackground))
  }

  #Preview("List") {
    ScrollView {
      RecipeListResults(
        viewModel: MockRecipeListViewModel.loaded(viewMode: .list),
        onRecipeTap: { _ in }
      )
    }
    .background(Color.themeColor(.surfacesBackground))
  }

  #Preview("Loading") {
    RecipeListResults(
      viewModel: MockRecipeListViewModel.loading(),
      onRecipeTap: { _ in }
    )
  }

  #Preview("Failed") {
    RecipeListResults(
      viewModel: MockRecipeListViewModel.failed(),
      onRecipeTap: { _ in }
    )
  }

  #Preview("Filtered to nothing") {
    RecipeListResults(
      viewModel: MockRecipeListViewModel.emptyFiltered(),
      onRecipeTap: { _ in }
    )
  }
#endif
```

- [ ] **Step 2: Build**

Run the build-only command. Expected: BUILD SUCCEEDED.

If the compiler rejects `content: grid` as a trailing-argument mismatch, pass it as a closure instead — `content: { grid($0) }`.

- [ ] **Step 3: Check the morph in the preview**

Open the "Grid" preview, switch the mock to `.loaded(viewMode: .list)` and back, and watch the cards. Expected: each card slides and resizes into its new box rather than disappearing and reappearing.

If `matchedGeometryEffect` across the two card types flickers or snaps, replace the two modifiers on `row(for:)` with a crossfade and keep the column animation:

```swift
        row(for: card)
          .transition(.opacity)
          .task { await viewModel.loadNextPageIfNeeded(after: card.id) }
```

Record in the commit message which of the two shipped.

- [ ] **Step 4: Commit**

```bash
git add RecipeTest/Modules/RecipeList/UI/Components/RecipeListResults.swift
git commit -m "[list] Lay the results out as a grid or a list"
```

---

## Task 15: The scene

**Files:**
- Create: `RecipeTest/Modules/RecipeList/UI/Scenes/RecipeListView.swift`

**Interfaces:**
- Consumes: every component from Tasks 10–14, plus `RecipeSearchPill` (Task 4).
- Produces: `RecipeListView(viewModel:onSearchTap:onRecipeTap:)`.

- [ ] **Step 1: Write the scene**

Create `RecipeTest/Modules/RecipeList/UI/Scenes/RecipeListView.swift`:

```swift
//
//  RecipeListView.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

struct RecipeListView: View {
  let viewModel: any RecipeListViewModelProtocol
  let onSearchTap: VoidResult
  let onRecipeTap: SingleResult<RecipeSummary>

  var body: some View {
    ScrollView(.vertical) {
      VStack(
        alignment: .leading,
        spacing: sectionSpacing
      ) {
        RecipeSearchPill(
          placeholder: viewModel.searchPlaceholder,
          onTap: onSearchTap
        )

        RecipeFacetChipRow(
          viewModel: viewModel,
          onRemoveTap: { facet in Task { await viewModel.remove(facet: facet) } },
          onClearAllTap: { Task { await viewModel.clearFacets() } }
        )

        RecipeListToolbar(
          viewModel: viewModel,
          onViewModeSelect: { viewModel.select(viewMode: $0) }
        )

        RecipeListResults(
          viewModel: viewModel,
          onRecipeTap: onRecipeTap
        )

        RecipeListFooter(
          viewModel: viewModel,
          onRetryTap: { Task { await viewModel.retryNextPage() } }
        )
      }
      .padding(
        .vertical,
        contentInset
      )
    }
    .scrollIndicators(.hidden)
    .background(Color.themeColor(.surfacesBackground))
    .navigationTitle(viewModel.title)
    // The large title collapsing to inline is the prototype's sticky bar, and keeping the
    // system back button is what keeps the interactive swipe-back the detail screen lost.
    .navigationBarTitleDisplayMode(.large)
    .toolbarVisibility(
      .visible,
      for: .navigationBar
    )
    .task { await viewModel.loadFirstPage() }
  }
}

// MARK: - Getters

private extension RecipeListView {
  var sectionSpacing: CGFloat {
    16
  }

  var contentInset: CGFloat {
    12
  }
}

#if DEBUG
  #Preview("Loaded") {
    NavigationStack {
      RecipeListView(
        viewModel: MockRecipeListViewModel.loaded(),
        onSearchTap: {},
        onRecipeTap: { _ in }
      )
    }
  }

  #Preview("Filtered") {
    NavigationStack {
      RecipeListView(
        viewModel: MockRecipeListViewModel.filtered(),
        onSearchTap: {},
        onRecipeTap: { _ in }
      )
    }
  }

  #Preview("An empty category") {
    NavigationStack {
      RecipeListView(
        viewModel: MockRecipeListViewModel.emptyCategory(),
        onSearchTap: {},
        onRecipeTap: { _ in }
      )
    }
  }

  #Preview("A page failed") {
    NavigationStack {
      RecipeListView(
        viewModel: MockRecipeListViewModel.pagingFailed(),
        onSearchTap: {},
        onRecipeTap: { _ in }
      )
    }
  }
#endif
```

- [ ] **Step 2: Build**

Run the build-only command. Expected: BUILD SUCCEEDED.

- [ ] **Step 3: Check the previews at an accessibility text size**

Open the "Loaded" preview and raise Dynamic Type to AX3. Expected: one column, the metadata stacked rather than clipped, and nothing running off the leading or trailing edge.

- [ ] **Step 4: Commit**

```bash
git add RecipeTest/Modules/RecipeList/UI/Scenes/RecipeListView.swift
git commit -m "[list] Assemble the results list scene"
```

---

## Task 16: Wire the category tap through

**Files:**
- Create: `RecipeTest/Modules/RecipeList/UI/RecipeListViewCoordinator.swift`
- Modify: `RecipeTest/Navigation/Route.swift`
- Modify: `RecipeTest/Coordinators/AppCoordinator.swift`
- Modify: `RecipeTest/Coordinators/HomeViewCoordinator.swift`

**Interfaces:**
- Consumes: `RecipeListView` (Task 15), `RecipeListRequest` (Task 2), `AppContainer.shared.recipeService`, `PathRouter`.
- Produces: `RecipeListViewCoordinator(request:recipeService:)` and `Route.Recipe.list(RecipeListRequest)`.

- [ ] **Step 1: Write the coordinator**

Create `RecipeTest/Modules/RecipeList/UI/RecipeListViewCoordinator.swift`:

```swift
//
//  RecipeListViewCoordinator.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

struct RecipeListViewCoordinator: ViewCoordinator {
  @Environment(PathRouter.self) private var pathRouter

  @State private var viewModel: RecipeListViewModel

  init(
    request: RecipeListRequest,
    recipeService: RecipeServiceProtocol = AppContainer.shared.recipeService
  ) {
    _viewModel = State(initialValue: RecipeListViewModel(
      request: request,
      recipeService: recipeService
    ))
  }

  var body: some View {
    RecipeListView(
      viewModel: viewModel,
      onSearchTap: handleSearchTap(),
      onRecipeTap: handleRecipeTap()
    )
  }
}

// MARK: - Handlers

private extension RecipeListViewCoordinator {
  func handleSearchTap() -> VoidResult {
    {
      // TODO: Push the search overlay once it exists
    }
  }

  func handleRecipeTap() -> SingleResult<RecipeSummary> {
    { pathRouter.push(Route.Recipe.detail($0)) }
  }
}

#if DEBUG
  #Preview {
    NavigationStack {
      RecipeListViewCoordinator(request: .category(.dummy(name: "Desserts")))
    }
    .environment(PathRouter())
  }
#endif
```

- [ ] **Step 2: Add the route case**

In `RecipeTest/Navigation/Route.swift`:

```swift
enum Route {
  enum Recipe: Hashable {
    case detail(RecipeSummary)
    case list(RecipeListRequest)
  }
}
```

- [ ] **Step 3: Handle the route**

In `RecipeTest/Coordinators/AppCoordinator.swift`, extend the existing `switch`:

```swift
        .navigationDestination(for: Route.Recipe.self) { route in
          switch route {
          case let .detail(summary):
            RecipeDetailViewCoordinator(summary: summary)

          case let .list(request):
            RecipeListViewCoordinator(request: request)
          }
        }
```

- [ ] **Step 4: Push it from Home**

In `RecipeTest/Coordinators/HomeViewCoordinator.swift`, replace the empty `handleCategoryTap`:

```swift
  var handleCategoryTap: SingleResult<RecipeCategory> {
    { pathRouter.push(Route.Recipe.list(.category($0))) }
  }
```

- [ ] **Step 5: Run the whole suite**

Run the full test command. Expected: PASS, every suite.

- [ ] **Step 6: Run it on a simulator and check the flow by hand**

Build and launch the app, then:

1. Tap **Desserts** on Home. Expected: the list pushes, the large title reads "Desserts", and the count reads the number of dessert recipes the fixture holds.
2. Scroll down. Expected: the title collapses into the navigation bar.
3. Tap **List**, then **Grid**. Expected: the cards morph between the two layouts and the scroll position holds.
4. Swipe from the left edge. Expected: the screen pops — this is the gesture the detail screen had to give up.
5. Tap a card. Expected: the recipe detail screen pushes, showing that recipe.
6. Tap back twice. Expected: Home, unchanged.

Every one of those must hold before the task is done. If step 4 fails, the navigation bar is being hidden somewhere — check that nothing in `RecipeListView` reintroduces `.toolbarVisibility(.hidden, ...)`.

- [ ] **Step 7: Commit**

```bash
git add RecipeTest/Modules/RecipeList/UI/RecipeListViewCoordinator.swift \
  RecipeTest/Navigation/Route.swift \
  RecipeTest/Coordinators/AppCoordinator.swift \
  RecipeTest/Coordinators/HomeViewCoordinator.swift
git commit -m "[list] Route a category tap through to the results list"
```

---

## Done

At this point the category tap reaches a paginated, filterable results list, and the search overlay and filter sheet can be built against a screen that already exists: both construct a `RecipeQuery`, wrap it in a `RecipeListRequest`, and push `Route.Recipe.list`.

Before opening a change request, run `core:code-review` over the branch as the previous two screens did.
