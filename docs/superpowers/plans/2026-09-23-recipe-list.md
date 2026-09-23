# Recipe List Screen Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the app's first screen — a recipe list that renders as a single-column list or a two-column grid, pulls to refresh, and lazily loads the next page — on top of the `RecipeService` that already ships.

**Architecture:** One `LazyVGrid` inside one `ScrollView`; the list/grid toggle changes the column count rather than swapping containers, so scroll position survives and there is exactly one implementation of refresh, paging, empty and error. A protocol-backed `@Observable` view model owns all state and is driven in tests through a `MockRecipeService`; the views hold `any RecipeListViewModelProtocol` and contain no logic worth testing.

**Tech Stack:** Swift 6, SwiftUI, Observation (`@Observable`), Kingfisher (via the existing `CachedAsyncImage`), Swift Testing (`import Testing`, `@Test`, `#expect`), SwiftFormat + SwiftLint (SwiftLint runs as a build-tool plugin).

**Spec:** `docs/superpowers/specs/2026-09-23-recipe-list-design.md`

## Global Constraints

- **Branch:** all work lands on `feat/recipe-list`. Never commit on `develop` or `main`.
- **Commits:** conventional style (`feat(recipe): ...`), header ≤72 chars. **No `Co-Authored-By` trailer** — this project omits attribution trailers.
- **Swift 6.** App targets build with `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, so a type in `RecipeTest/` is main-actor **unless** it carries an explicit `nonisolated`. Views and the view model are main-actor and need no annotation; plain value types that the service layer might touch get `nonisolated`, matching every existing domain type. The `Tests` target defaults to `nonisolated`.
- **Indentation:** 2 spaces. Line length: 120 warning / 180 error, `RecipeTest/` only (`Tests/` is excluded from SwiftLint).
- **File headers:** every new file starts with the project header block. App files use `//  RecipeTest` on line 3, test files use `//  Tests`:
  ```swift
  //
  //  FileName.swift
  //  RecipeTest
  //
  //  Created by Danjan ( https://github.com/Dannjann )
  //  Copyright © 2026 Danjan. All rights reserved.
  //
  ```
- **Formatting before every commit:** run `swiftformat RecipeTest Tests UITests`, then `swiftformat RecipeTest Tests UITests --lint` to confirm it is clean. The config requires `// MARK:` comments on types and extensions (`--marktypes always`, `--markextensions always`, `--organizationmode visibility`); let the formatter insert them rather than hand-writing them. CI fails on a lint diff.
- **No string literals in `String(localized:)`** — a custom SwiftLint rule rejects them. Every piece of user-facing copy goes into `Recipe.xcstrings` (Task 5) **before** a view references it.
- **Xcode project:** `RecipeTest`, `Tests` and `UITests` are `PBXFileSystemSynchronizedRootGroup`s. Files dropped anywhere inside those folders join the target automatically — **never edit `project.pbxproj`**.
- **Previews are required** on every new SwiftUI view, per the team standard.
- **Comments: only where the code cannot speak for itself.** The code is the documentation —
  clear names, small functions, obvious structure. Keep a comment only where a reader would
  otherwise undo a deliberate choice, and keep it to one line. Delete anything that restates
  what a line does, narrates the obvious, or argues against an alternative that was never
  written. **The code blocks in the tasks below were written before this constraint and carry
  extensive doc comments: they are illustrative of structure and behaviour, not of comment
  density. Transcribe the code, not the prose around it.** This overrides the comment-heavy
  style in the repo's older files.
- **Running tests.** Resolve a simulator id once and reuse it for every task:
  ```bash
  xcodebuild -showdestinations -project RecipeTest.xcodeproj -scheme RecipeTest \
    -skipPackagePluginValidation 2>/dev/null \
    | grep 'platform:iOS Simulator' | grep -v 'error:' | grep -v 'placeholder' \
    | grep 'name:iPhone' | head -1
  ```
  Then, for each task:
  ```bash
  xcodebuild test -project RecipeTest.xcodeproj -scheme RecipeTest \
    -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
    -only-testing:Tests/<SuiteName> \
    -skipPackagePluginValidation CODE_SIGNING_ALLOWED=NO
  ```
  The `ios:simulator-actions` skill wraps build/run/test for this project and may be used instead of raw `xcodebuild`.
- **Working tree note:** `RecipeTest.xcodeproj/project.pbxproj` and two `.xcscheme` files were already modified before this branch was cut. They are unrelated to this work — **never stage them.** Stage files by name, never `git add -A`.

## Review Focus

Five conditions the spec implies that no task's happy-path tests would reach. Each one has its test added to the task that owns the code.

1. **A `.task` cancelled mid-flight** — SwiftUI cancels `.task` when the view disappears, so navigating away during the first load throws `CancellationError`. Rendering that as a failed screen shows the user "cancelled" as if it were a server fault, and leaves `.failed` stuck so returning never retries. Cancellation must leave no error and return the screen to `.idle`. → Task 2.
2. **A refresh started while the first page is still in flight** — the user pulls down during initial load. Two page-1 requests are then outstanding and whichever returns last wins, which may be the older one. The refresh must win regardless of arrival order. → Task 4.
3. **An error that is not `LocalizedError`** — the service can propagate anything. `errorDescription` is nil for a plain `struct E: Error`, and a view model that reads `(error as? LocalizedError)?.errorDescription` would show an empty error state. The message must always be non-empty. → Task 2.
4. **A short page that is not the last page** — the backend returns 7 rows for a `perPage` of 10 while `currentPage < lastPage`. A pager that infers "done" from `rows.count < perPage` stops early and silently hides the rest of the catalogue. Only `meta` decides. → Task 3.
5. **Toggling layout while a next page is in flight** — `select(layout:)` must not touch paging state. Resetting `nextPage` or `isLoadingNextPage` there either double-requests a page or wedges the footer permanently. → Task 3.

---

## File Structure

**Created under `RecipeTest/Modules/Recipe/UI/`:**

| File | Responsibility |
|---|---|
| `Recipe.xcstrings` | This module's string catalog |
| `RecipeViewCoordinator.swift` | Roots the flow, owns the view model, handles `Route.Recipe` |
| `List/RecipeListLayout.swift` | `enum { list, grid }` and its `columns: [GridItem]` |
| `List/RecipeListLoadState.swift` | `enum { idle, loading, loaded, failed(String) }` |
| `List/RecipeListViewModelProtocol.swift` | The contract the view depends on |
| `List/RecipeListViewModel.swift` | Paging, refresh, error handling |
| `List/RecipeListView.swift` | The screen: search bar, state switch, scroller |
| `List/Mock/MockRecipeListViewModel.swift` | `#if DEBUG` double for previews |
| `List/Mock/DummyRecipeSummary.swift` | `#if DEBUG` sample row |
| `List/Mock/DummyRecipeListPage.swift` | `#if DEBUG` sample page |
| `Detail/RecipeDetailPlaceholderView.swift` | Stands in until the detail stage |
| `Components/RecipeCard.swift` | One row or one cell, axis switched by layout |
| `Components/RecipeSearchBar.swift` | Presentational; `onTap` defaulted, hit-testing off |
| `Components/RecipeLayoutToggle.swift` | Value plus `onSelect`, no binding |

**Created under `Tests/`:**

| File | Responsibility |
|---|---|
| `Mocks/Modules/Recipe/Services/MockRecipeService.swift` | `RecipeServiceProtocol` double |
| `Modules/Recipe/UI/List/RecipeListLayoutTests.swift` | Column shape |
| `Modules/Recipe/UI/List/RecipeListViewModelTests.swift` | Every view model behaviour |

**Modified:**

| File | Change |
|---|---|
| `Navigation/Route.swift` | Add `enum Recipe: Hashable { case detail(RecipeSummary) }` |
| `Modules/Recipe/Models/Domain/RecipeSummary.swift` | Add `Hashable` conformance |
| `App/AppCoordinator.swift` | Replace `placeholder` with `RecipeViewCoordinator()` |

The spec listed one dummy file; this plan splits it into `DummyRecipeSummary` and `DummyRecipeListPage` so each extends one type, matching how `DummyRemoteRecipeSummary` and `DummyRemotePaginationMetaInfo` are already split in `Tests/Mocks/`.

---

### Task 1: Value types

The two view-layer enums, plus the `Hashable` conformance `Route` will need. Nothing here depends on anything else in the plan, and everything later depends on this.

**Files:**
- Create: `RecipeTest/Modules/Recipe/UI/List/RecipeListLayout.swift`
- Create: `RecipeTest/Modules/Recipe/UI/List/RecipeListLoadState.swift`
- Modify: `RecipeTest/Modules/Recipe/Models/Domain/RecipeSummary.swift`
- Test: `Tests/Modules/Recipe/UI/List/RecipeListLayoutTests.swift`

**Interfaces:**
- Consumes: `RecipeSummary` (exists).
- Produces: `RecipeListLayout.list` / `.grid`, `RecipeListLayout.columns -> [GridItem]`, `RecipeListLayout.toggled -> RecipeListLayout`; `RecipeListLoadState.idle` / `.loading` / `.loaded` / `.failed(String)`; `RecipeSummary: Hashable`.

- [ ] **Step 1: Write the failing test**

Create `Tests/Modules/Recipe/UI/List/RecipeListLayoutTests.swift`:

```swift
//
//  RecipeListLayoutTests.swift
//  Tests
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation
@testable import RecipeTest
import Testing

struct RecipeListLayoutTests {
  @Test
  func list_isASingleColumn() {
    #expect(RecipeListLayout.list.columns.count == 1)
  }

  @Test
  func grid_isTwoColumns() {
    #expect(RecipeListLayout.grid.columns.count == 2)
  }

  /// The toolbar button shows the layout you would switch *to*, so this has to be an
  /// involution — toggling twice is the identity.
  @Test
  func toggled_roundTripsBackToItself() {
    #expect(RecipeListLayout.list.toggled == .grid)
    #expect(RecipeListLayout.grid.toggled == .list)
    #expect(RecipeListLayout.list.toggled.toggled == .list)
  }

  @Test
  func loadState_distinguishesFailureMessages() {
    #expect(RecipeListLoadState.failed("a") != RecipeListLoadState.failed("b"))
    #expect(RecipeListLoadState.loaded == RecipeListLoadState.loaded)
  }
}
```

- [ ] **Step 2: Run the test and watch it fail**

Run the test command from Global Constraints with `-only-testing:Tests/RecipeListLayoutTests`.
Expected: FAIL to compile — `cannot find 'RecipeListLayout' in scope`.

- [ ] **Step 3: Write the two enums**

Create `RecipeTest/Modules/Recipe/UI/List/RecipeListLayout.swift`:

```swift
//
//  RecipeListLayout.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

/// How the recipe list arranges its cards.
///
/// A view concern, deliberately not a domain model: nothing in the service or model layer
/// has any reason to know the screen has two modes.
///
/// Both modes are the same `LazyVGrid` with a different column count, which is what lets
/// the screen keep its scroll position across a toggle — swapping in a structurally
/// different container would rebuild the scroll view and lose it.
nonisolated enum RecipeListLayout: CaseIterable, Equatable {
  case list
  case grid
}

// MARK: - Getters

nonisolated extension RecipeListLayout {
  var columns: [GridItem] {
    switch self {
    case .list:
      [GridItem(.flexible(), spacing: Self.spacing)]
    case .grid:
      [
        GridItem(.flexible(), spacing: Self.spacing),
        GridItem(.flexible(), spacing: Self.spacing),
      ]
    }
  }

  /// The mode this one switches to. The toolbar button is labelled for its destination,
  /// not its current state.
  var toggled: Self {
    switch self {
    case .list: .grid
    case .grid: .list
    }
  }

  static var spacing: CGFloat { 12 }
}
```

Create `RecipeTest/Modules/Recipe/UI/List/RecipeListLoadState.swift`:

```swift
//
//  RecipeListLoadState.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

/// What occupies the recipe list screen.
///
/// There is deliberately no `empty` case. Empty is `.loaded` with no rows, which keeps one
/// source of truth for what is on screen — with a separate case, `loadState` and `recipes`
/// can disagree and the screen has two contradictory answers about what to draw.
///
/// This enum covers the *screen*. What happens at the bottom edge of an already-loaded
/// list is carried separately by `isLoadingNextPage` and `nextPageError`, because a failed
/// next page must not take the screen away from the rows the user already has.
nonisolated enum RecipeListLoadState: Equatable {
  /// Nothing attempted yet.
  case idle
  /// The first page is in flight and the screen is empty.
  case loading
  /// Rows are the source of truth; `recipes.isEmpty` is the empty state.
  case loaded
  /// The first page failed and the screen is empty. Carries the message to show.
  case failed(String)
}
```

- [ ] **Step 4: Add `Hashable` to `RecipeSummary`**

In `RecipeTest/Modules/Recipe/Models/Domain/RecipeSummary.swift`, change the declaration line:

```swift
nonisolated struct RecipeSummary: Equatable, Hashable, Identifiable {
```

Every stored property (`String`, `URL?`, `Int?`, `RecipeDifficulty?`, `Double`, `[String]`) is already `Hashable`, so the synthesised conformance compiles with no other change. `Route.Recipe.detail(RecipeSummary)` in Task 9 requires it.

If `RecipeDifficulty` does not already conform, add `Hashable` to it the same way.

- [ ] **Step 5: Run the test and watch it pass**

Run with `-only-testing:Tests/RecipeListLayoutTests`.
Expected: PASS, 4 tests.

- [ ] **Step 6: Format and commit**

```bash
swiftformat RecipeTest Tests UITests
swiftformat RecipeTest Tests UITests --lint
git add RecipeTest/Modules/Recipe/UI/List/RecipeListLayout.swift \
        RecipeTest/Modules/Recipe/UI/List/RecipeListLoadState.swift \
        RecipeTest/Modules/Recipe/Models/Domain/RecipeSummary.swift \
        Tests/Modules/Recipe/UI/List/RecipeListLayoutTests.swift
git commit -m "feat(recipe): add the recipe list's layout and load state"
```

---

### Task 2: View model — first page

Introduces the protocol, the view model, and the service double. First-page loading, the empty page, and failure — including the two failure modes from Review Focus that live here.

**Files:**
- Create: `RecipeTest/Modules/Recipe/UI/List/RecipeListViewModelProtocol.swift`
- Create: `RecipeTest/Modules/Recipe/UI/List/RecipeListViewModel.swift`
- Create: `RecipeTest/Modules/Recipe/UI/List/Mock/DummyRecipeSummary.swift`
- Create: `RecipeTest/Modules/Recipe/UI/List/Mock/DummyRecipeListPage.swift`
- Create: `Tests/Mocks/Modules/Recipe/Services/MockRecipeService.swift`
- Test: `Tests/Modules/Recipe/UI/List/RecipeListViewModelTests.swift`

**Interfaces:**
- Consumes: `RecipeListLoadState`, `RecipeListLayout` (Task 1); `RecipeServiceProtocol.getRecipes(page:) async throws -> RecipeListPage`, `Page(index:size:)`, `Page.next`, `RecipeListPage.recipes`, `RecipeListPage.hasLoadedAllData` (all existing).
- Produces: `RecipeListViewModelProtocol` (outputs `recipes`, `layout`, `loadState`, `isLoadingNextPage`, `nextPageError`, `hasLoadedAllData`; inputs `loadFirstPage()`, `refresh()`, `loadNextPage()`, `select(layout:)`); `RecipeListViewModel(service:pageSize:)`; `RecipeSummary.dummy(id:title:)`; `RecipeListPage.dummy(ids:total:perPage:currentPage:lastPage:)`; `MockRecipeService(page:)` exposing `recipes: MockAPICall<Page, RecipeListPage>`.

- [ ] **Step 1: Write the dummies**

These live in the **app target** under `#if DEBUG`, because previews (Task 6 onward) cannot import the test target. The `Tests` target reaches them through `@testable import RecipeTest`, so there is one set of sample data rather than two.

Create `RecipeTest/Modules/Recipe/UI/List/Mock/DummyRecipeSummary.swift`:

```swift
//
//  DummyRecipeSummary.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

#if DEBUG

  /// Sample rows for previews and tests.
  ///
  /// In the app target rather than `Tests/` because a SwiftUI preview cannot import the
  /// test target — the same reason `MockURLProtocol` and `MockAPIRouter` are app-target
  /// types. `#if DEBUG` keeps all of it out of a release build.
  nonisolated extension RecipeSummary {
    static func dummy(
      id: String = "rcp-001",
      title: String = "Spaghetti alla Carbonara",
      shortDescription: String = "Roman pasta bound with egg yolk and pecorino — never cream.",
      heroImageURL: URL? = URL(string: "https://api.example.com/api/v1/images/carbonara.png"),
      totalTimeMinutes: Int? = 25,
      difficulty: RecipeDifficulty? = .medium,
      rating: Double = 4.8,
      ratingCount: Int = 2147,
      tags: [String] = ["quick", "classic"]
    ) -> Self {
      RecipeSummary(
        id: id,
        title: title,
        shortDescription: shortDescription,
        heroImageURL: heroImageURL,
        totalTimeMinutes: totalTimeMinutes,
        difficulty: difficulty,
        rating: rating,
        ratingCount: ratingCount,
        tags: tags
      )
    }
  }

#endif
```

If `RecipeDifficulty` has no `.medium` case, use whichever case it defines — check `RecipeTest/Modules/Recipe/Models/Domain/RecipeDifficulty.swift` and substitute.

Create `RecipeTest/Modules/Recipe/UI/List/Mock/DummyRecipeListPage.swift`:

```swift
//
//  DummyRecipeListPage.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

#if DEBUG

  nonisolated extension RecipeListPage {
    /// Builds a page from ids alone, with the meta a real backend would send alongside
    /// them. `total` and `lastPage` default to "this is the only page".
    static func dummy(
      ids: [String] = ["rcp-001", "rcp-002", "rcp-003"],
      total: Int? = nil,
      perPage: Int = 10,
      currentPage: Int = 1,
      lastPage: Int = 1
    ) -> Self {
      RecipeListPage(
        recipes: ids.map { RecipeSummary.dummy(id: $0, title: "Recipe \($0)") },
        meta: PaginationMetaInfo(
          total: total ?? ids.count,
          perPage: perPage,
          from: ids.isEmpty ? nil : (currentPage - 1) * perPage + 1,
          to: ids.isEmpty ? nil : (currentPage - 1) * perPage + ids.count,
          currentPage: currentPage,
          lastPage: lastPage
        )
      )
    }
  }

#endif
```

- [ ] **Step 2: Write the service double**

Create `Tests/Mocks/Modules/Recipe/Services/MockRecipeService.swift`:

```swift
//
//  MockRecipeService.swift
//  Tests
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation
@testable import RecipeTest

/// A `RecipeServiceProtocol` double, built the same way as `MockRecipeAPI`: one
/// `MockAPICall` per endpoint, so a test can stub per-request answers with `responds` and
/// assert on `requests` without a bag of loose properties.
final class MockRecipeService: RecipeServiceProtocol {
  enum MockError: Error {
    /// `getRecipe(id:)` has no caller until the detail stage. Throwing beats returning a
    /// hand-built `Recipe`, which would mean constructing a dozen nested domain types
    /// that nothing in this stage reads.
    case notStubbed
  }

  let recipes: MockAPICall<Page, RecipeListPage>

  init(page: RecipeListPage = .dummy()) {
    recipes = MockAPICall(returning: page)
  }
}

// MARK: - RecipeServiceProtocol

extension MockRecipeService {
  func getRecipes(page: Page) async throws -> RecipeListPage {
    try await recipes.invoke(page)
  }

  func getRecipe(id _: String) async throws -> Recipe {
    throw MockError.notStubbed
  }
}
```

- [ ] **Step 3: Write the failing tests**

Create `Tests/Modules/Recipe/UI/List/RecipeListViewModelTests.swift`:

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
  func loadFirstPage_populatesTheRowsAndLoads() async {
    let service = MockRecipeService(page: .dummy(ids: ["rcp-001", "rcp-002"]))
    let sut = makeSUT(service: service)

    await sut.loadFirstPage()

    #expect(sut.recipes.map(\.id) == ["rcp-001", "rcp-002"])
    #expect(sut.loadState == .loaded)
  }

  @Test
  func loadFirstPage_asksForPageOneAtTheConfiguredSize() async {
    let service = MockRecipeService()
    let sut = makeSUT(service: service, pageSize: 10)

    await sut.loadFirstPage()

    #expect(service.recipes.lastRequest == Page(index: 1, size: 10))
  }

  /// No rows is a legitimate answer, not a failure. It has to land on `.loaded` so the
  /// screen shows the empty state rather than an error with a Retry button.
  @Test
  func loadFirstPage_withNoRows_isLoadedAndEmpty() async {
    let service = MockRecipeService(page: .dummy(ids: []))
    let sut = makeSUT(service: service)

    await sut.loadFirstPage()

    #expect(sut.recipes.isEmpty)
    #expect(sut.loadState == .loaded)
  }

  @Test
  func loadFirstPage_whenTheServiceThrows_failsWithAMessage() async {
    let service = MockRecipeService()
    service.recipes.fails(with: AppError.noInternetConnection)
    let sut = makeSUT(service: service)

    await sut.loadFirstPage()

    #expect(sut.recipes.isEmpty)
    #expect(sut.loadState == .failed(AppError.noInternetConnection.localizedDescription))
  }

  /// REVIEW FOCUS 3. The service can propagate anything. A plain `Error` has no
  /// `errorDescription`, and a view model reading that directly would put an empty string
  /// on screen — an error state with no error in it.
  @Test
  func loadFirstPage_whenTheErrorIsNotLocalized_stillShowsSomething() async {
    struct Unhelpful: Error {}

    let service = MockRecipeService()
    service.recipes.fails(with: Unhelpful())
    let sut = makeSUT(service: service)

    await sut.loadFirstPage()

    guard case let .failed(message) = sut.loadState else {
      Issue.record("expected .failed, got \(sut.loadState)")
      return
    }

    #expect(!message.isEmpty)
  }

  /// REVIEW FOCUS 1. SwiftUI cancels a `.task` when the view disappears, so navigating
  /// away mid-load throws. Showing that as a server failure is wrong, and leaving
  /// `.failed` behind means coming back never retries — `.task` re-fires but
  /// `loadFirstPage` would see a state it treats as terminal.
  @Test
  func loadFirstPage_whenCancelled_reportsNoErrorAndStaysRetryable() async {
    let service = MockRecipeService()
    service.recipes.fails(with: CancellationError())
    let sut = makeSUT(service: service)

    await sut.loadFirstPage()

    #expect(sut.loadState == .idle)
    #expect(sut.recipes.isEmpty)
  }

  /// `.task` fires again every time the view reappears — returning from the detail push,
  /// for instance. A second call must not refetch, because that would also reset the
  /// user's scroll position to the top of a freshly replaced array.
  @Test
  func loadFirstPage_calledTwice_onlyFetchesOnce() async {
    let service = MockRecipeService()
    let sut = makeSUT(service: service)

    await sut.loadFirstPage()
    await sut.loadFirstPage()

    #expect(service.recipes.callCount == 1)
  }

  /// ...but a *failed* first load must stay retryable, which is what the error state's
  /// Retry button calls.
  @Test
  func loadFirstPage_afterAFailure_fetchesAgain() async {
    let service = MockRecipeService()
    service.recipes.fails(with: AppError.noInternetConnection)
    let sut = makeSUT(service: service)

    await sut.loadFirstPage()
    service.recipes.returns(.dummy(ids: ["rcp-001"]))
    await sut.loadFirstPage()

    #expect(service.recipes.callCount == 2)
    #expect(sut.recipes.map(\.id) == ["rcp-001"])
    #expect(sut.loadState == .loaded)
  }
}

// MARK: - Helpers

@MainActor
private extension RecipeListViewModelTests {
  func makeSUT(
    service: MockRecipeService,
    pageSize: Int = 10
  ) -> RecipeListViewModel {
    RecipeListViewModel(service: service, pageSize: pageSize)
  }
}
```

- [ ] **Step 4: Run the tests and watch them fail**

Run with `-only-testing:Tests/RecipeListViewModelTests`.
Expected: FAIL to compile — `cannot find 'RecipeListViewModel' in scope`.

- [ ] **Step 5: Write the protocol**

Create `RecipeTest/Modules/Recipe/UI/List/RecipeListViewModelProtocol.swift`:

```swift
//
//  RecipeListViewModelProtocol.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

/// What `RecipeListView` depends on, so the screen can be previewed and tested against a
/// double instead of a service.
///
/// Inherits `Observable` so a conformer that forgot the `@Observable` macro fails to
/// compile rather than silently never updating the view.
///
/// Held by the view as `any RecipeListViewModelProtocol`. Reading through the existential
/// tracks correctly — the protocol witness dispatches to the macro-generated accessor,
/// which registers with the current observation context exactly as a concrete call would.
/// What does *not* work is `@Bindable` on an existential; `Observable` has no
/// self-conformance, so `$viewModel.layout` will not compile. That costs nothing here
/// because inputs are methods and outputs are read-only, per the team's MVVM standard —
/// which is why `select(layout:)` exists instead of a settable `layout`.
@MainActor
protocol RecipeListViewModelProtocol: Observable, AnyObject {
  // MARK: Outputs

  var recipes: [RecipeSummary] { get }
  var layout: RecipeListLayout { get }
  var loadState: RecipeListLoadState { get }
  /// A page beyond the first is in flight. Drives the footer, never the screen.
  var isLoadingNextPage: Bool { get }
  /// A page beyond the first failed. Drives the footer's retry, never the screen.
  var nextPageError: String? { get }
  var hasLoadedAllData: Bool { get }

  // MARK: Inputs

  func loadFirstPage() async
  func refresh() async
  func loadNextPage() async
  func select(layout: RecipeListLayout)
}
```

- [ ] **Step 6: Write the view model**

Create `RecipeTest/Modules/Recipe/UI/List/RecipeListViewModel.swift`. Tasks 3 and 4 fill in `loadNextPage()` and `refresh()`; they are declared here so the type conforms.

```swift
//
//  RecipeListViewModel.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

/// Owns everything the recipe list screen shows.
///
/// Main-actor by default (`SWIFT_DEFAULT_ACTOR_ISOLATION`), so every mutation below is
/// already serialised — the guards here are about request ordering, not data races.
@Observable
final class RecipeListViewModel: RecipeListViewModelProtocol {
  private(set) var recipes: [RecipeSummary] = []
  private(set) var layout: RecipeListLayout = .list
  private(set) var loadState: RecipeListLoadState = .idle
  private(set) var isLoadingNextPage = false
  private(set) var nextPageError: String?
  private(set) var hasLoadedAllData = false

  private let service: any RecipeServiceProtocol
  private let pageSize: Int

  /// The page `loadNextPage()` will ask for.
  private var nextPage: Page

  /// Bumped every time a page-one sequence starts. A result carrying a stale generation
  /// is discarded — see `refresh()` in Task 4, which is what this exists for.
  private var generation = 0

  init(
    service: any RecipeServiceProtocol,
    pageSize: Int = 10
  ) {
    self.service = service
    self.pageSize = pageSize
    nextPage = Page(index: 1, size: pageSize)
  }
}

// MARK: - Inputs

extension RecipeListViewModel {
  /// Called from the view's `.task`, which re-fires on every reappearance. A load that
  /// already succeeded or is already running is therefore a no-op; only `.idle` and
  /// `.failed` are worth acting on. Reloading on demand is `refresh()`'s job.
  func loadFirstPage() async {
    switch loadState {
    case .idle, .failed:
      break
    case .loading, .loaded:
      return
    }

    loadState = .loading

    await loadPageOne(token: startNewGeneration(), keepingRowsOnFailure: false)
  }

  func select(layout: RecipeListLayout) {
    guard layout != self.layout else { return }

    self.layout = layout
  }
}

// MARK: - Loading

private extension RecipeListViewModel {
  /// The one place page one is fetched, shared by the first load and by a refresh. They
  /// differ only in what a failure is allowed to do to the screen.
  func loadPageOne(token: Int, keepingRowsOnFailure: Bool) async {
    do {
      let page = try await service.getRecipes(page: Page(index: 1, size: pageSize))
      guard token == generation else { return }

      recipes = page.recipes
      hasLoadedAllData = page.hasLoadedAllData
      nextPage = Page(index: 2, size: pageSize)
      nextPageError = nil
      loadState = .loaded
    } catch {
      guard token == generation else { return }

      // A cancelled `.task` is not a failure the user should read about. Returning to
      // `.idle` also leaves the screen retryable, so reappearing re-runs the load.
      guard !error.isCancellation else {
        if loadState == .loading {
          loadState = .idle
        }

        return
      }

      guard !keepingRowsOnFailure || recipes.isEmpty else { return }

      loadState = .failed(error.displayMessage)
    }
  }

  /// Invalidates every request currently in flight and returns the token the new one
  /// carries.
  func startNewGeneration() -> Int {
    generation += 1

    return generation
  }
}
```

Add a small shared extension for the two error helpers. Create it at
`RecipeTest/Modules/Shared/Models/Error+Presentation.swift`:

```swift
//
//  Error+Presentation.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

nonisolated extension Error {
  /// Text safe to put in front of a user.
  ///
  /// `localizedDescription` rather than `(self as? LocalizedError)?.errorDescription`:
  /// the latter is nil for any error that does not conform, which would put an empty
  /// string in an error state. `AppError` and `RecipeServiceError` both conform, so their
  /// catalogued copy is what comes back; anything else degrades to Foundation's generic
  /// sentence instead of to nothing.
  var displayMessage: String {
    localizedDescription
  }

  /// Whether this error means "the caller went away", rather than "the request failed".
  ///
  /// SwiftUI cancels a `.task` when its view disappears, and `URLSession` reports that as
  /// `URLError.cancelled` rather than as `CancellationError` — both have to be caught, or
  /// navigating away mid-load leaves a failure on screen for the user to come back to.
  var isCancellation: Bool {
    self is CancellationError || (self as? URLError)?.code == .cancelled
  }
}
```

- [ ] **Step 7: Add the stubs Tasks 3 and 4 will fill**

Still in `RecipeListViewModel.swift`, inside the `// MARK: - Inputs` extension, so the type conforms to its protocol now:

```swift
  func refresh() async {
    // Task 4.
  }

  func loadNextPage() async {
    // Task 3.
  }
```

- [ ] **Step 8: Run the tests and watch them pass**

Run with `-only-testing:Tests/RecipeListViewModelTests`.
Expected: PASS, 8 tests.

- [ ] **Step 9: Format and commit**

```bash
swiftformat RecipeTest Tests UITests
swiftformat RecipeTest Tests UITests --lint
git add RecipeTest/Modules/Recipe/UI/List/RecipeListViewModelProtocol.swift \
        RecipeTest/Modules/Recipe/UI/List/RecipeListViewModel.swift \
        RecipeTest/Modules/Recipe/UI/List/Mock/DummyRecipeSummary.swift \
        RecipeTest/Modules/Recipe/UI/List/Mock/DummyRecipeListPage.swift \
        RecipeTest/Modules/Shared/Models/Error+Presentation.swift \
        Tests/Mocks/Modules/Recipe/Services/MockRecipeService.swift \
        Tests/Modules/Recipe/UI/List/RecipeListViewModelTests.swift
git commit -m "feat(recipe): load the recipe list's first page"
```

---

### Task 3: View model — pagination

Appending the next page, stopping at the end, and surviving a failure at the bottom edge. Carries Review Focus 4 and 5.

**Files:**
- Modify: `RecipeTest/Modules/Recipe/UI/List/RecipeListViewModel.swift`
- Test: `Tests/Modules/Recipe/UI/List/RecipeListViewModelTests.swift`

**Interfaces:**
- Consumes: everything Task 2 produced.
- Produces: a working `loadNextPage()`; `nextPage` advancing via `Page.next`.

- [ ] **Step 1: Write the failing tests**

Append these to the `RecipeListViewModelTests` struct, above the `// MARK: - Helpers` extension:

```swift
  @Test
  func loadNextPage_appendsAfterTheExistingRows() async {
    let service = MockRecipeService()
    service.recipes.responds { page in
      page.index == 1
        ? .dummy(ids: ["rcp-001", "rcp-002"], total: 4, perPage: 2, currentPage: 1, lastPage: 2)
        : .dummy(ids: ["rcp-003", "rcp-004"], total: 4, perPage: 2, currentPage: 2, lastPage: 2)
    }
    let sut = makeSUT(service: service, pageSize: 2)

    await sut.loadFirstPage()
    await sut.loadNextPage()

    #expect(sut.recipes.map(\.id) == ["rcp-001", "rcp-002", "rcp-003", "rcp-004"])
    #expect(service.recipes.requests.map(\.index) == [1, 2])
  }

  /// Without this the pager asks for page 5, page 6, page 7... forever, because a real
  /// backend answers a page past the end with an empty slice rather than an error.
  @Test
  func loadNextPage_onTheLastPage_doesNotAsk() async {
    let service = MockRecipeService(page: .dummy(ids: ["rcp-001"], total: 1, perPage: 10, currentPage: 1, lastPage: 1))
    let sut = makeSUT(service: service)

    await sut.loadFirstPage()
    await sut.loadNextPage()

    #expect(sut.hasLoadedAllData)
    #expect(service.recipes.callCount == 1)
  }

  /// REVIEW FOCUS 4. Seven rows for a `perPage` of ten, but `currentPage` is still below
  /// `lastPage`. Inferring "done" from a short page stops here and silently hides the
  /// rest of the catalogue — only the meta gets to decide.
  @Test
  func loadNextPage_afterAShortPageThatIsNotTheLast_keepsGoing() async {
    let service = MockRecipeService(
      page: .dummy(
        ids: ["rcp-001", "rcp-002", "rcp-003", "rcp-004", "rcp-005", "rcp-006", "rcp-007"],
        total: 30,
        perPage: 10,
        currentPage: 1,
        lastPage: 3
      )
    )
    let sut = makeSUT(service: service)

    await sut.loadFirstPage()

    #expect(sut.hasLoadedAllData == false)

    await sut.loadNextPage()

    #expect(service.recipes.requests.map(\.index) == [1, 2])
  }

  /// A failed page three leaves the user's rows alone. Taking the screen away because the
  /// bottom edge failed would be a far worse trade than a retry button in the footer.
  @Test
  func loadNextPage_whenItFails_keepsTheRowsAndReportsInTheFooter() async {
    let service = MockRecipeService()
    service.recipes.responds { page in
      guard page.index == 1 else { throw AppError.noInternetConnection }

      return .dummy(ids: ["rcp-001"], total: 4, perPage: 1, currentPage: 1, lastPage: 4)
    }
    let sut = makeSUT(service: service, pageSize: 1)

    await sut.loadFirstPage()
    await sut.loadNextPage()

    #expect(sut.recipes.map(\.id) == ["rcp-001"])
    #expect(sut.loadState == .loaded)
    #expect(sut.nextPageError == AppError.noInternetConnection.localizedDescription)
    #expect(sut.isLoadingNextPage == false)
  }

  @Test
  func loadNextPage_afterAFailure_canRetryAndClearsTheFooterError() async {
    let service = MockRecipeService()
    service.recipes.responds { page in
      guard page.index == 1 else { throw AppError.noInternetConnection }

      return .dummy(ids: ["rcp-001"], total: 2, perPage: 1, currentPage: 1, lastPage: 2)
    }
    let sut = makeSUT(service: service, pageSize: 1)

    await sut.loadFirstPage()
    await sut.loadNextPage()

    service.recipes.returns(.dummy(ids: ["rcp-002"], total: 2, perPage: 1, currentPage: 2, lastPage: 2))
    await sut.loadNextPage()

    #expect(sut.recipes.map(\.id) == ["rcp-001", "rcp-002"])
    #expect(sut.nextPageError == nil)
  }

  /// A `ForEach` over duplicated `Identifiable` ids misbehaves visibly. The mock backend
  /// cannot produce one, but a real paginated backend whose underlying rows shift between
  /// requests absolutely can.
  @Test
  func loadNextPage_withARepeatedId_keepsOnlyTheFirst() async {
    let service = MockRecipeService()
    service.recipes.responds { page in
      page.index == 1
        ? .dummy(ids: ["rcp-001", "rcp-002"], total: 4, perPage: 2, currentPage: 1, lastPage: 2)
        : .dummy(ids: ["rcp-002", "rcp-003"], total: 4, perPage: 2, currentPage: 2, lastPage: 2)
    }
    let sut = makeSUT(service: service, pageSize: 2)

    await sut.loadFirstPage()
    await sut.loadNextPage()

    #expect(sut.recipes.map(\.id) == ["rcp-001", "rcp-002", "rcp-003"])
  }

  @Test
  func loadNextPage_beforeTheFirstPageLoaded_doesNothing() async {
    let service = MockRecipeService()
    let sut = makeSUT(service: service)

    await sut.loadNextPage()

    #expect(service.recipes.wasCalled == false)
  }

  /// REVIEW FOCUS 5. The toggle is a pure view concern. Touching paging state here either
  /// double-requests a page or wedges the footer's spinner on forever.
  @Test
  func select_doesNotDisturbPaging() async {
    let service = MockRecipeService(page: .dummy(ids: ["rcp-001"], total: 4, perPage: 1, currentPage: 1, lastPage: 4))
    let sut = makeSUT(service: service, pageSize: 1)

    await sut.loadFirstPage()
    sut.select(layout: .grid)

    #expect(sut.layout == .grid)
    #expect(sut.isLoadingNextPage == false)
    #expect(sut.hasLoadedAllData == false)

    service.recipes.returns(.dummy(ids: ["rcp-002"], total: 4, perPage: 1, currentPage: 2, lastPage: 4))
    await sut.loadNextPage()

    #expect(service.recipes.requests.map(\.index) == [1, 2])
  }
```

- [ ] **Step 2: Run the tests and watch them fail**

Run with `-only-testing:Tests/RecipeListViewModelTests`.
Expected: FAIL — the append and last-page tests fail because `loadNextPage()` is an empty stub, so `service.recipes.callCount` stays at 1 and `sut.recipes` never grows.

- [ ] **Step 3: Implement `loadNextPage()`**

Replace the Task 2 stub in `RecipeListViewModel.swift`:

```swift
  /// Called by the footer's `onAppear`, which only fires once the user has scrolled to
  /// the end of the content.
  ///
  /// Guarded three ways: the screen must already be showing rows, there must be more to
  /// fetch, and one request at a time. Without the third, a footer that flickers in and
  /// out of view fires several overlapping requests for the same page.
  func loadNextPage() async {
    guard
      loadState == .loaded,
      !hasLoadedAllData,
      !isLoadingNextPage
    else { return }

    isLoadingNextPage = true
    nextPageError = nil

    let token = generation
    let requested = nextPage

    do {
      let page = try await service.getRecipes(page: requested)
      guard token == generation else { return }

      append(page.recipes)
      hasLoadedAllData = page.hasLoadedAllData
      nextPage = requested.next
      isLoadingNextPage = false
    } catch {
      guard token == generation else { return }

      isLoadingNextPage = false

      guard !error.isCancellation else { return }

      nextPageError = error.displayMessage
    }
  }
```

Add to the `// MARK: - Loading` private extension:

```swift
  /// Filters ids already on screen. A `ForEach` keyed on a duplicated `Identifiable` id
  /// drops rows and animates wrongly, and a paginated backend whose rows shift between
  /// requests will hand you the same recipe on two pages.
  func append(_ newRecipes: [RecipeSummary]) {
    let existing = Set(recipes.map(\.id))

    recipes += newRecipes.filter { !existing.contains($0.id) }
  }
```

Note there is no `hasLoadedAllData` inference from `page.recipes.count` — `RecipeListPage.hasLoadedAllData` reads the meta (`total <= perPage || currentPage >= lastPage`), which is the only thing that knows whether a short page is the last one.

- [ ] **Step 4: Run the tests and watch them pass**

Run with `-only-testing:Tests/RecipeListViewModelTests`.
Expected: PASS, 16 tests.

- [ ] **Step 5: Format and commit**

```bash
swiftformat RecipeTest Tests UITests
swiftformat RecipeTest Tests UITests --lint
git add RecipeTest/Modules/Recipe/UI/List/RecipeListViewModel.swift \
        Tests/Modules/Recipe/UI/List/RecipeListViewModelTests.swift
git commit -m "feat(recipe): page the recipe list as the user scrolls"
```

---

### Task 4: View model — refresh

Pull-to-refresh, and the race it creates with a page already in flight. Carries Review Focus 2.

**Files:**
- Modify: `RecipeTest/Modules/Recipe/UI/List/RecipeListViewModel.swift`
- Test: `Tests/Modules/Recipe/UI/List/RecipeListViewModelTests.swift`

**Interfaces:**
- Consumes: everything Tasks 2 and 3 produced.
- Produces: a working `refresh()`.

- [ ] **Step 1: Write the failing tests**

Append to the `RecipeListViewModelTests` struct:

```swift
  @Test
  func refresh_replacesTheRowsRatherThanAppending() async {
    let service = MockRecipeService(page: .dummy(ids: ["rcp-001", "rcp-002"]))
    let sut = makeSUT(service: service)

    await sut.loadFirstPage()
    service.recipes.returns(.dummy(ids: ["rcp-009"]))
    await sut.refresh()

    #expect(sut.recipes.map(\.id) == ["rcp-009"])
  }

  @Test
  func refresh_startsAgainFromPageOne() async {
    let service = MockRecipeService()
    service.recipes.responds { page in
      .dummy(ids: ["rcp-00\(page.index)"], total: 9, perPage: 1, currentPage: page.index, lastPage: 9)
    }
    let sut = makeSUT(service: service, pageSize: 1)

    await sut.loadFirstPage()
    await sut.loadNextPage()
    await sut.refresh()
    await sut.loadNextPage()

    #expect(service.recipes.requests.map(\.index) == [1, 2, 1, 2])
  }

  /// Clearing the rows first would flash an empty list on every pull, and a refresh that
  /// then failed would have destroyed content the user still had.
  @Test
  func refresh_whenItFails_keepsTheRowsAndTheLoadedState() async {
    let service = MockRecipeService(page: .dummy(ids: ["rcp-001"]))
    let sut = makeSUT(service: service)

    await sut.loadFirstPage()
    service.recipes.fails(with: AppError.noInternetConnection)
    await sut.refresh()

    #expect(sut.recipes.map(\.id) == ["rcp-001"])
    #expect(sut.loadState == .loaded)
  }

  /// REVIEW FOCUS 2. The user pulls to refresh while the first load is still running.
  /// Two page-one requests are outstanding; if the older one is allowed to land last, the
  /// user sees stale content they explicitly asked to replace.
  @Test
  func refresh_duringAnInFlightFirstLoad_winsRegardlessOfOrder() async {
    let service = MockRecipeService()
    let sut = makeSUT(service: service)

    // Call one is the initial load and is held open; call two is the refresh and returns
    // at once. The gate is what makes the ordering a fact rather than a hope — swapping
    // the stub after launching the task would race the task's own start, and the test
    // could pass without the stale result ever being in flight.
    let gate = CallGate()
    service.recipes.responds { _ in
      guard await gate.arrive() == 1 else { return .dummy(ids: ["fresh"]) }

      await gate.waitUntilOpen()

      return .dummy(ids: ["stale"])
    }

    async let firstLoad: Void = sut.loadFirstPage()
    await gate.waitForArrivals(1)

    await sut.refresh()
    await gate.open()
    await firstLoad

    #expect(sut.recipes.map(\.id) == ["fresh"])
  }

  /// A next page that returns after a refresh belongs to a list that no longer exists.
  /// Appending it produces duplicated and out-of-order rows.
  @Test
  func refresh_discardsANextPageThatWasAlreadyInFlight() async {
    let service = MockRecipeService()
    let sut = makeSUT(service: service, pageSize: 1)

    service.recipes.returns(.dummy(ids: ["rcp-001"], total: 9, perPage: 1, currentPage: 1, lastPage: 9))
    await sut.loadFirstPage()

    // Same gate, same reason: call one is the next page and is held open, call two is the
    // refresh's page one and returns immediately.
    let gate = CallGate()
    service.recipes.responds { _ in
      guard await gate.arrive() == 1 else {
        return .dummy(ids: ["rcp-999"], total: 9, perPage: 1, currentPage: 1, lastPage: 9)
      }

      await gate.waitUntilOpen()

      return .dummy(ids: ["late"], total: 9, perPage: 1, currentPage: 2, lastPage: 9)
    }

    async let nextPage: Void = sut.loadNextPage()
    await gate.waitForArrivals(1)

    await sut.refresh()
    await gate.open()
    await nextPage

    #expect(sut.recipes.map(\.id) == ["rcp-999"])
  }

  @Test
  func loadNextPage_startedDuringARefresh_isRefused() async {
    let service = MockRecipeService()
    let sut = makeSUT(service: service, pageSize: 1)

    service.recipes.returns(.dummy(ids: ["rcp-001"], total: 9, perPage: 1, currentPage: 1, lastPage: 9))
    await sut.loadFirstPage()

    let gate = CallGate()
    service.recipes.responds { _ in
      guard await gate.arrive() == 1 else {
        return .dummy(ids: ["late"], total: 9, perPage: 1, currentPage: 7, lastPage: 9)
      }

      await gate.waitUntilOpen()

      return .dummy(ids: ["rcp-999"], total: 9, perPage: 1, currentPage: 1, lastPage: 9)
    }

    async let refresh: Void = sut.refresh()
    await gate.waitForArrivals(1)

    await sut.loadNextPage()
    await gate.open()
    await refresh

    #expect(service.recipes.callCount == 2)
    #expect(sut.recipes.map(\.id) == ["rcp-999"])
  }

  /// Pins the `!isLoadingNextPage` guard. Without it a footer flickering in and out of
  /// view fires overlapping requests for the same page.
  @Test
  func loadNextPage_whileOneIsAlreadyInFlight_doesNotDoubleRequest() async {
    let service = MockRecipeService()
    let sut = makeSUT(service: service, pageSize: 1)

    service.recipes.returns(.dummy(ids: ["rcp-001"], total: 9, perPage: 1, currentPage: 1, lastPage: 9))
    await sut.loadFirstPage()

    let gate = CallGate()
    service.recipes.responds { _ in
      _ = await gate.arrive()
      await gate.waitUntilOpen()

      return .dummy(ids: ["rcp-002"], total: 9, perPage: 1, currentPage: 2, lastPage: 9)
    }

    async let inFlight: Void = sut.loadNextPage()
    await gate.waitForArrivals(1)

    await sut.loadNextPage()
    await gate.open()
    await inFlight

    #expect(service.recipes.requests.map(\.index) == [1, 2])
  }
```

Add the gate helper to the same file, below the `// MARK: - Helpers` extension:

```swift
// MARK: - Helpers > Ordering

/// Orders two concurrent calls to the same stub, so "this result arrives last" is
/// arranged rather than hoped for — no sleeps, and no dependence on when a child task
/// happens to start.
///
/// `waitForArrivals` is the part that matters: without it a test can swap the stub before
/// the task under test has even entered it, and then passes while never exercising the
/// race it was written for.
private actor CallGate {
  private var arrivals = 0
  private var isOpen = false
  private var openWaiters: [CheckedContinuation<Void, Never>] = []
  private var arrivalWaiters: [CheckedContinuation<Void, Never>] = []

  /// Called from inside the stub. Returns this call's 1-based ordinal.
  func arrive() -> Int {
    arrivals += 1

    for continuation in arrivalWaiters {
      continuation.resume()
    }

    arrivalWaiters = []

    return arrivals
  }

  /// Called from inside the stub: suspends this call until the test opens the gate.
  func waitUntilOpen() async {
    guard !isOpen else { return }

    await withCheckedContinuation { continuation in
      openWaiters.append(continuation)
    }
  }

  /// Called from the test: suspends until at least `count` calls have entered the stub.
  func waitForArrivals(_ count: Int) async {
    while arrivals < count {
      await withCheckedContinuation { continuation in
        arrivalWaiters.append(continuation)
      }
    }
  }

  func open() {
    isOpen = true

    for continuation in openWaiters {
      continuation.resume()
    }

    openWaiters = []
  }
}
```

- [ ] **Step 2: Run the tests and watch them fail**

Run with `-only-testing:Tests/RecipeListViewModelTests`.
Expected: FAIL — `refresh()` is an empty stub, so `sut.recipes` still reads `["rcp-001", "rcp-002"]` where `["rcp-009"]` was expected.

- [ ] **Step 3: Implement `refresh()`**

Replace the Task 2 stub in `RecipeListViewModel.swift`:

```swift
  /// Does not set `.loading`: that would blank a screen the user is looking at, and
  /// `.refreshable` draws its own indicator.
  func refresh() async {
    let token = startNewGeneration()

    isRefreshing = true
    defer { isRefreshing = false }

    nextPage = Page(index: 1, size: pageSize)
    isLoadingNextPage = false
    nextPageError = nil

    await loadPageOne(token: token, keepingRowsOnFailure: true)
  }
```

Add the flag alongside the other private state in `RecipeListViewModel`:

```swift
  private var isRefreshing = false
```

And add it to `loadNextPage()`'s guard list, from Task 3:

```swift
    guard
      loadState == .loaded,
      !isRefreshing,
      !hasLoadedAllData,
      !isLoadingNextPage
    else { return }
```

**Why the flag is needed, and why the generation counter is not enough.** The generation counter invalidates requests started *before* a refresh. It cannot invalidate one started *during* it, and that case is reachable: `refresh()` sets `nextPageError = nil` synchronously, which flips the footer from its error branch to its `ProgressView` branch — a structurally different view, so SwiftUI fires the new one's `.task`. That calls `loadNextPage()` while refresh's page-one request is still in flight. All of Task 3's guards pass (`loadState` is still `.loaded`, `isLoadingNextPage` was just reset), it captures the *new* generation so it is not stale, and it reads the pre-refresh `nextPage` because `loadPageOne` only resets that after its own await. If refresh lands first, page 7's rows get appended onto refreshed page-1 rows and `nextPage` jumps to 8 — pages 2 through 7 silently skipped.

`keepingRowsOnFailure: true` is read by `loadPageOne`'s `catch` from Task 2: it returns early when rows are already on screen, leaving `loadState` at `.loaded`. A refresh that fails with an *empty* screen — a retry after a failed first load — still surfaces the error, because `recipes.isEmpty` is then true.

- [ ] **Step 4: Run the tests and watch them pass**

Run with `-only-testing:Tests/RecipeListViewModelTests`.
Expected: PASS, 23 tests.

- [ ] **Step 5: Run the whole suite**

Run the test command with no `-only-testing` filter.
Expected: PASS — every pre-existing suite plus the two new ones. Nothing in this plan has changed service-layer behaviour, so a failure anywhere else is a real regression.

- [ ] **Step 6: Format and commit**

```bash
swiftformat RecipeTest Tests UITests
swiftformat RecipeTest Tests UITests --lint
git add RecipeTest/Modules/Recipe/UI/List/RecipeListViewModel.swift \
        Tests/Modules/Recipe/UI/List/RecipeListViewModelTests.swift
git commit -m "feat(recipe): refresh the recipe list without blanking it"
```

---

### Task 5: Copy and the preview double

Everything the views need before any view exists: the string catalog and the view model double the previews are built on. No unit test — a string catalog and a double have no behaviour of their own; the deliverable is verified by a clean build.

**Files:**
- Create: `RecipeTest/Modules/Recipe/UI/Recipe.xcstrings`
- Create: `RecipeTest/Modules/Recipe/UI/List/Mock/MockRecipeListViewModel.swift`

**Interfaces:**
- Consumes: `RecipeListViewModelProtocol`, `RecipeListLoadState`, `RecipeListLayout`, `RecipeSummary.dummy(...)`.
- Produces: the `.Recipe.*` string symbols listed below; `MockRecipeListViewModel(recipes:layout:loadState:isLoadingNextPage:nextPageError:hasLoadedAllData:)` with `loadFirstPageCallCount`, `refreshCallCount`, `loadNextPageCallCount`, `selectedLayouts`.

- [ ] **Step 1: Create the string catalog**

Create `RecipeTest/Modules/Recipe/UI/Recipe.xcstrings` with this exact content. The filename decides the generated symbol namespace, so `Recipe.xcstrings` yields `.Recipe.recipeListTitle` for the key `recipe.list.title` — the same derivation `Core.xcstrings` and `Shared.xcstrings` already use.

```json
{
  "sourceLanguage" : "en",
  "strings" : {
    "recipe.detail.placeholder.message" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "The full recipe lands in a later stage."
          }
        }
      }
    },
    "recipe.list.empty.message" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Pull down to try again."
          }
        }
      }
    },
    "recipe.list.empty.title" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "No recipes yet"
          }
        }
      }
    },
    "recipe.list.error.retry" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Try again"
          }
        }
      }
    },
    "recipe.list.layout.grid" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Show as grid"
          }
        }
      }
    },
    "recipe.list.layout.list" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Show as list"
          }
        }
      }
    },
    "recipe.list.search.placeholder" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Search recipes"
          }
        }
      }
    },
    "recipe.list.title" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Recipes"
          }
        }
      }
    }
  },
  "version" : "1.0"
}
```

- [ ] **Step 2: Verify the symbols generate**

Build the app target (`xcodebuild build -project RecipeTest.xcodeproj -scheme RecipeTest -destination "platform=iOS Simulator,id=$SIMULATOR_ID" -skipPackagePluginValidation CODE_SIGNING_ALLOWED=NO`), then confirm in Xcode that `String(localized: .Recipe.recipeListTitle)` resolves.

If the generated namespace is not `.Recipe`, check the actual symbol Xcode emits and use that spelling consistently in Tasks 6–9 rather than renaming the catalog.

- [ ] **Step 3: Write the preview double**

Create `RecipeTest/Modules/Recipe/UI/List/Mock/MockRecipeListViewModel.swift`:

```swift
//
//  MockRecipeListViewModel.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

#if DEBUG

  /// A `RecipeListViewModelProtocol` double whose every output is set at construction, so
  /// a preview can pin the screen to one exact state — loading, empty, failed, last page —
  /// without a service, a network, or a simulator.
  ///
  /// In the app target rather than `Tests/` because previews cannot import the test
  /// target. `#if DEBUG` keeps it out of a release build. The `Tests` target can reach it
  /// through `@testable import RecipeTest` if a view-level test ever wants it; the view
  /// model tests do not, because they exercise the real `RecipeListViewModel`.
  @Observable
  final class MockRecipeListViewModel: RecipeListViewModelProtocol {
    private(set) var recipes: [RecipeSummary]
    private(set) var layout: RecipeListLayout
    private(set) var loadState: RecipeListLoadState
    private(set) var isLoadingNextPage: Bool
    private(set) var nextPageError: String?
    private(set) var hasLoadedAllData: Bool

    private(set) var loadFirstPageCallCount = 0
    private(set) var refreshCallCount = 0
    private(set) var loadNextPageCallCount = 0
    private(set) var selectedLayouts: [RecipeListLayout] = []

    init(
      recipes: [RecipeSummary] = RecipeSummary.dummyList(),
      layout: RecipeListLayout = .list,
      loadState: RecipeListLoadState = .loaded,
      isLoadingNextPage: Bool = false,
      nextPageError: String? = nil,
      hasLoadedAllData: Bool = true
    ) {
      self.recipes = recipes
      self.layout = layout
      self.loadState = loadState
      self.isLoadingNextPage = isLoadingNextPage
      self.nextPageError = nextPageError
      self.hasLoadedAllData = hasLoadedAllData
    }
  }

  // MARK: - RecipeListViewModelProtocol

  extension MockRecipeListViewModel {
    func loadFirstPage() async {
      loadFirstPageCallCount += 1
    }

    func refresh() async {
      refreshCallCount += 1
    }

    func loadNextPage() async {
      loadNextPageCallCount += 1
    }

    func select(layout: RecipeListLayout) {
      selectedLayouts.append(layout)
      self.layout = layout
    }
  }

#endif
```

- [ ] **Step 4: Add the row-list helper the double defaults to**

Append to `RecipeTest/Modules/Recipe/UI/List/Mock/DummyRecipeSummary.swift`, inside the existing `#if DEBUG` block and the existing extension:

```swift
    /// Six rows with distinct titles and hero URLs, so a grid preview shows variety
    /// rather than the same card six times.
    static func dummyList(count: Int = 6) -> [Self] {
      let titles = [
        "Spaghetti alla Carbonara",
        "Miso-Glazed Aubergine",
        "Shakshuka with Feta",
        "Lemon and Herb Roast Chicken",
        "Black Bean and Sweetcorn Tacos",
        "Dark Chocolate and Olive Oil Cake",
      ]

      return (0 ..< count).map { index in
        .dummy(
          id: String(format: "rcp-%03d", index + 1),
          title: titles[index % titles.count],
          heroImageURL: URL(string: "https://api.example.com/api/v1/images/dummy-\(index).png")
        )
      }
    }
```

- [ ] **Step 5: Build and confirm it compiles**

Run the build command from Step 2.
Expected: BUILD SUCCEEDED. `MockRecipeListViewModel` conforming to the protocol is what proves the protocol is actually satisfiable by something other than the real view model — if `@Observable` and the protocol disagree, it fails here rather than in a preview.

- [ ] **Step 6: Format and commit**

```bash
swiftformat RecipeTest Tests UITests
swiftformat RecipeTest Tests UITests --lint
git add RecipeTest/Modules/Recipe/UI/Recipe.xcstrings \
        RecipeTest/Modules/Recipe/UI/List/Mock/MockRecipeListViewModel.swift \
        RecipeTest/Modules/Recipe/UI/List/Mock/DummyRecipeSummary.swift
git commit -m "feat(recipe): add the recipe list's copy and preview double"
```

---

### Task 6: `RecipeCard`

The card, in both axes. The only component whose shape changes with the layout.

**Files:**
- Create: `RecipeTest/Modules/Recipe/UI/Components/RecipeCard.swift`

**Interfaces:**
- Consumes: `RecipeSummary`, `RecipeListLayout`, `CachedAsyncImage(url:)`, `RecipeSummary.dummy(...)`.
- Produces: `RecipeCard(recipe: RecipeSummary, layout: RecipeListLayout)`.

- [ ] **Step 1: Write the card**

Create `RecipeTest/Modules/Recipe/UI/Components/RecipeCard.swift`:

```swift
//
//  RecipeCard.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

/// One recipe, as a list row or as a grid cell.
///
/// One type rather than two, because both carry exactly the same three pieces of content
/// and differ only in axis — two types would mean every content change made twice.
struct RecipeCard: View {
  let recipe: RecipeSummary
  let layout: RecipeListLayout

  var body: some View {
    content
      .padding(Self.padding)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(Color.themeColor(.surfacesBackground2))
      .clipShape(RoundedRectangle(cornerRadius: Self.cornerRadius))
      .overlay {
        RoundedRectangle(cornerRadius: Self.cornerRadius)
          .stroke(Color.themeColor(.bordersDefault), lineWidth: 1)
      }
      // One element, not three. Without this, VoiceOver stops on the image, the title and
      // the description separately for every card in a 36-row list.
      .accessibilityElement(children: .combine)
      .accessibilityIdentifier("recipeList.card.\(recipe.id)")
  }
}

// MARK: - Subviews

private extension RecipeCard {
  @ViewBuilder
  var content: some View {
    switch layout {
    case .list:
      HStack(alignment: .top, spacing: Self.padding) {
        image
          .frame(width: Self.listImageSide, height: Self.listImageSide)

        text
      }

    case .grid:
      VStack(alignment: .leading, spacing: Self.padding) {
        image
          .frame(height: Self.gridImageHeight)
          .frame(maxWidth: .infinity)

        text
      }
    }
  }

  /// Fixed frames in both axes, applied by the caller above: an image that sizes itself
  /// from what downloads would reflow the whole grid as each one resolves.
  var image: some View {
    CachedAsyncImage(url: recipe.heroImageURL)
      .aspectRatio(contentMode: .fill)
      .clipped()
      .clipShape(RoundedRectangle(cornerRadius: Self.imageCornerRadius))
  }

  var text: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(recipe.title)
        .themeTextStyle(.bodySemibold)
        .themeColor(.textPrimary)
        .lineLimit(2)

      Text(recipe.shortDescription)
        .themeTextStyle(.subheadlineRegular)
        .themeColor(.textSecondary)
        // Line-limited so one verbose row cannot set the height of every cell beside it.
        .lineLimit(layout == .list ? 2 : 3)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

// MARK: - Constants

private extension RecipeCard {
  static var padding: CGFloat { 12 }
  static var cornerRadius: CGFloat { 12 }
  static var imageCornerRadius: CGFloat { 8 }
  static var listImageSide: CGFloat { 96 }
  static var gridImageHeight: CGFloat { 120 }
}

// MARK: - Previews

#Preview("List") {
  RecipeCard(recipe: .dummy(), layout: .list)
    .padding()
    .background(Color.themeColor(.surfacesBackground))
}

#Preview("Grid") {
  HStack(spacing: RecipeListLayout.spacing) {
    RecipeCard(recipe: .dummy(), layout: .grid)
    RecipeCard(recipe: .dummy(id: "rcp-002", title: "Miso-Glazed Aubergine"), layout: .grid)
  }
  .padding()
  .background(Color.themeColor(.surfacesBackground))
}

#Preview("Long title and description") {
  RecipeCard(
    recipe: .dummy(
      title: "Slow-Braised Beef Short Rib with Gremolata and Soft Polenta",
      shortDescription: String(repeating: "A very long description that must not be allowed to run away. ", count: 4)
    ),
    layout: .list
  )
  .padding()
  .background(Color.themeColor(.surfacesBackground))
}
```

The previews are not decoration: the third one is the only check that `lineLimit` actually holds a card to a sane height, which no unit test in this plan covers.

- [ ] **Step 2: Build and inspect the previews**

Build the app target. Open `RecipeCard.swift` in Xcode and confirm all three previews render: the list row is image-left with text beside it, the grid pair is image-on-top and the two cards are the same height, and the long-title card is clipped rather than tall.

- [ ] **Step 3: Format and commit**

```bash
swiftformat RecipeTest Tests UITests
swiftformat RecipeTest Tests UITests --lint
git add RecipeTest/Modules/Recipe/UI/Components/RecipeCard.swift
git commit -m "feat(recipe): add the recipe card in list and grid axes"
```

---

### Task 7: `RecipeSearchBar` and `RecipeLayoutToggle`

The two fixed chrome components. Neither has state.

**Files:**
- Create: `RecipeTest/Modules/Recipe/UI/Components/RecipeSearchBar.swift`
- Create: `RecipeTest/Modules/Recipe/UI/Components/RecipeLayoutToggle.swift`

**Interfaces:**
- Consumes: `RecipeListLayout`, `VoidResult`, `DefaultClosure.voidResult()`, `SingleResult<RecipeListLayout>`, `.Recipe.recipeListSearchPlaceholder`, `.Recipe.recipeListLayoutList`, `.Recipe.recipeListLayoutGrid`.
- Produces: `RecipeSearchBar(onTap:)` with `onTap` defaulted; `RecipeLayoutToggle(layout:onSelect:)`.

- [ ] **Step 1: Write the search bar**

Create `RecipeTest/Modules/Recipe/UI/Components/RecipeSearchBar.swift`:

```swift
//
//  RecipeSearchBar.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

/// The bar above the recipe list.
///
/// Deliberately not a `TextField` and holding no query: tapping it will eventually push a
/// dedicated filter page rather than filter in place, so there is nothing for the user to
/// type into here even once it works.
///
/// Inert this stage. `onTap` is declared and defaulted so the search stage supplies a
/// closure and removes the `allowsHitTesting(false)` below — no other change to this
/// component or to the screen that hosts it. It is rendered non-interactive rather than
/// merely unwired, so nothing on screen looks tappable and does nothing.
struct RecipeSearchBar: View {
  var onTap: VoidResult = DefaultClosure.voidResult()

  var body: some View {
    Button(action: onTap) {
      HStack(spacing: 8) {
        Image(systemName: "magnifyingglass")
          .foregroundStyle(Color.themeColor(.iconsSecondary))

        Text(String(localized: .Recipe.recipeListSearchPlaceholder))
          .themeTextStyle(.bodyRegular)
          .themeColor(.textTertiary)

        Spacer(minLength: 0)
      }
      .padding(.horizontal, 12)
      .frame(height: 44)
      .background(Color.themeColor(.surfacesFieldsAndTags))
      .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    .buttonStyle(.plain)
    .allowsHitTesting(false)
    .accessibilityIdentifier("recipeList.searchBar")
  }
}

// MARK: - Previews

#Preview {
  RecipeSearchBar()
    .padding()
    .background(Color.themeColor(.surfacesBackground))
}
```

- [ ] **Step 2: Write the layout toggle**

Create `RecipeTest/Modules/Recipe/UI/Components/RecipeLayoutToggle.swift`:

```swift
//
//  RecipeLayoutToggle.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

/// Switches the recipe list between its two layouts.
///
/// Takes a value and a closure rather than a `Binding`, for two reasons that point the
/// same way: `@Bindable` does not work through `any RecipeListViewModelProtocol`, and the
/// team's MVVM standard wants view model inputs to be methods anyway.
///
/// One button, labelled for where it takes you — not a segmented control. There are only
/// two states, so a control showing both wastes a toolbar slot to say what one icon says.
struct RecipeLayoutToggle: View {
  let layout: RecipeListLayout
  let onSelect: SingleResult<RecipeListLayout>

  var body: some View {
    Button {
      onSelect(layout.toggled)
    } label: {
      Image(systemName: iconName)
        .foregroundStyle(Color.themeColor(.iconsDefault))
    }
    .accessibilityLabel(Text(accessibilityLabel))
    .accessibilityIdentifier("recipeList.layoutToggle")
  }
}

// MARK: - Getters

private extension RecipeLayoutToggle {
  /// Shows the layout the button switches *to*, matching its label.
  var iconName: String {
    switch layout.toggled {
    case .list: "list.bullet"
    case .grid: "square.grid.2x2"
    }
  }

  var accessibilityLabel: String {
    switch layout.toggled {
    case .list: String(localized: .Recipe.recipeListLayoutList)
    case .grid: String(localized: .Recipe.recipeListLayoutGrid)
    }
  }
}

// MARK: - Previews

#Preview("Currently list") {
  RecipeLayoutToggle(layout: .list, onSelect: { _ in })
}

#Preview("Currently grid") {
  RecipeLayoutToggle(layout: .grid, onSelect: { _ in })
}
```

- [ ] **Step 3: Build and inspect the previews**

Build the app target and confirm both components render, and that the toggle's icon in the "Currently list" preview is the *grid* icon — it is labelled for its destination.

- [ ] **Step 4: Format and commit**

```bash
swiftformat RecipeTest Tests UITests
swiftformat RecipeTest Tests UITests --lint
git add RecipeTest/Modules/Recipe/UI/Components/RecipeSearchBar.swift \
        RecipeTest/Modules/Recipe/UI/Components/RecipeLayoutToggle.swift
git commit -m "feat(recipe): add the recipe list's search bar and layout toggle"
```

---

### Task 8: `RecipeListView`

The screen. Every state, the scroller, and the footer that is both the next-page indicator and its trigger.

**Files:**
- Create: `RecipeTest/Modules/Recipe/UI/List/RecipeListView.swift`

**Interfaces:**
- Consumes: `RecipeListViewModelProtocol`, `RecipeListLoadState`, `RecipeListLayout.columns`, `RecipeListLayout.spacing`, `RecipeCard(recipe:layout:)`, `RecipeSearchBar()`, `RecipeLayoutToggle(layout:onSelect:)`, `MockRecipeListViewModel(...)`, `SingleResult<RecipeSummary>`, the `.Recipe.*` symbols.
- Produces: `RecipeListView(viewModel:onRecipeTap:)`.

- [ ] **Step 1: Write the screen**

Create `RecipeTest/Modules/Recipe/UI/List/RecipeListView.swift`:

```swift
//
//  RecipeListView.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

/// The recipe list.
///
/// Holds its view model as an existential so a preview can pin the screen to any state.
/// Reading through it tracks correctly; `@Bindable` would not compile, which is why every
/// interaction below calls a method instead of writing through a binding.
struct RecipeListView: View {
  let viewModel: any RecipeListViewModelProtocol
  var onRecipeTap: SingleResult<RecipeSummary> = DefaultClosure.singleResult()

  var body: some View {
    VStack(spacing: 0) {
      // Outside the scroll view on purpose: the bar stays put in both layouts and in
      // every state, rather than scrolling away with the content.
      RecipeSearchBar()
        .padding(.horizontal, RecipeListLayout.spacing)
        .padding(.bottom, RecipeListLayout.spacing)

      content
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.themeColor(.surfacesBackground))
    .navigationTitle(Text(String(localized: .Recipe.recipeListTitle)))
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        RecipeLayoutToggle(layout: viewModel.layout) { layout in
          viewModel.select(layout: layout)
        }
      }
    }
    .task {
      await viewModel.loadFirstPage()
    }
  }
}

// MARK: - Subviews

private extension RecipeListView {
  @ViewBuilder
  var content: some View {
    switch viewModel.loadState {
    case .idle, .loading:
      ProgressView()
        .frame(maxWidth: .infinity, maxHeight: .infinity)

    case let .failed(message):
      messageState(
        title: message,
        detail: nil,
        retry: { await viewModel.loadFirstPage() }
      )

    case .loaded:
      if viewModel.recipes.isEmpty {
        messageState(
          title: String(localized: .Recipe.recipeListEmptyTitle),
          detail: String(localized: .Recipe.recipeListEmptyMessage),
          retry: nil
        )
      } else {
        scroller
      }
    }
  }

  /// The grid and the footer share one scroll view, and that is load-bearing twice over.
  /// `LazyVGrid` has no viewport of its own — outside a scroll view it builds every child
  /// eagerly and there is no laziness left. And the footer's `onAppear` only means "the
  /// user reached the end" because it scrolls with the content; pinned outside, it would
  /// be on screen from launch and fire on the first frame.
  var scroller: some View {
    ScrollView {
      LazyVGrid(
        columns: viewModel.layout.columns,
        spacing: RecipeListLayout.spacing
      ) {
        ForEach(viewModel.recipes) { recipe in
          RecipeCard(recipe: recipe, layout: viewModel.layout)
            .onTapGesture {
              onRecipeTap(recipe)
            }
        }
      }
      .animation(.snappy, value: viewModel.layout)

      // Outside the grid so it spans both columns instead of taking one cell.
      footer
    }
    .padding(.horizontal, RecipeListLayout.spacing)
    .refreshable {
      await viewModel.refresh()
    }
  }

  @ViewBuilder
  var footer: some View {
    if viewModel.hasLoadedAllData {
      // Nothing: the trigger goes away with the indicator.
      EmptyView()
    } else if let nextPageError = viewModel.nextPageError {
      VStack(spacing: 8) {
        Text(nextPageError)
          .themeTextStyle(.footnoteRegular)
          .themeColor(.textSecondary)
          .multilineTextAlignment(.center)

        Button(String(localized: .Recipe.recipeListErrorRetry)) {
          Task { await viewModel.loadNextPage() }
        }
        .themeTextStyle(.bodySemibold)
      }
      .padding(.vertical, RecipeListLayout.spacing)
    } else {
      ProgressView()
        .padding(.vertical, RecipeListLayout.spacing)
        .task {
          await viewModel.loadNextPage()
        }
    }
  }

  func messageState(
    title: String,
    detail: String?,
    retry: (() async -> Void)?
  ) -> some View {
    VStack(spacing: 8) {
      Text(title)
        .themeTextStyle(.bodySemibold)
        .themeColor(.textPrimary)
        .multilineTextAlignment(.center)

      if let detail {
        Text(detail)
          .themeTextStyle(.subheadlineRegular)
          .themeColor(.textSecondary)
          .multilineTextAlignment(.center)
      }

      if let retry {
        Button(String(localized: .Recipe.recipeListErrorRetry)) {
          Task { await retry() }
        }
        .themeTextStyle(.bodySemibold)
        .padding(.top, 4)
      }
    }
    .padding(RecipeListLayout.spacing * 2)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

// MARK: - Previews

#Preview("Loaded — list") {
  NavigationStack {
    RecipeListView(viewModel: MockRecipeListViewModel())
  }
}

#Preview("Loaded — grid") {
  NavigationStack {
    RecipeListView(viewModel: MockRecipeListViewModel(layout: .grid))
  }
}

#Preview("Loading next page") {
  NavigationStack {
    RecipeListView(
      viewModel: MockRecipeListViewModel(isLoadingNextPage: true, hasLoadedAllData: false)
    )
  }
}

#Preview("Next page failed") {
  NavigationStack {
    RecipeListView(
      viewModel: MockRecipeListViewModel(
        nextPageError: AppError.noInternetConnection.localizedDescription,
        hasLoadedAllData: false
      )
    )
  }
}

#Preview("Empty") {
  NavigationStack {
    RecipeListView(viewModel: MockRecipeListViewModel(recipes: []))
  }
}

#Preview("Failed") {
  NavigationStack {
    RecipeListView(
      viewModel: MockRecipeListViewModel(
        recipes: [],
        loadState: .failed(AppError.noInternetConnection.localizedDescription)
      )
    )
  }
}

#Preview("Loading") {
  NavigationStack {
    RecipeListView(viewModel: MockRecipeListViewModel(recipes: [], loadState: .loading))
  }
}
```

The footer's trigger is `.task` rather than `.onAppear` so the call is structured-concurrency-scoped: scrolling the footer back off screen cancels the in-flight request instead of leaving it running, and `loadNextPage()` already treats cancellation as "not an error".

- [ ] **Step 2: Build and walk every preview**

Build the app target, then step through all seven previews in Xcode. Confirm:
- Loaded–list is one column, Loaded–grid is two, and the cards are the same content in both.
- Loading-next-page shows a spinner under the last card; next-page-failed shows a message and Try again under it, with the rows still there.
- Empty, Failed and Loading each own the whole screen — and the search bar is still visible above all three.

- [ ] **Step 3: Format and commit**

```bash
swiftformat RecipeTest Tests UITests
swiftformat RecipeTest Tests UITests --lint
git add RecipeTest/Modules/Recipe/UI/List/RecipeListView.swift
git commit -m "feat(recipe): add the recipe list screen"
```

---

### Task 9: Route, placeholder detail, and app wiring

Connects the screen to the app. After this task the feature is reachable by running the app.

**Files:**
- Create: `RecipeTest/Modules/Recipe/UI/Detail/RecipeDetailPlaceholderView.swift`
- Create: `RecipeTest/Modules/Recipe/UI/RecipeViewCoordinator.swift`
- Modify: `RecipeTest/Navigation/Route.swift`
- Modify: `RecipeTest/App/AppCoordinator.swift`

**Interfaces:**
- Consumes: `RecipeListView(viewModel:onRecipeTap:)`, `RecipeListViewModel(service:pageSize:)`, `RecipeSummary: Hashable`, `PathRouter`, `AppContainer.shared.recipeService`, `.Recipe.recipeDetailPlaceholderMessage`.
- Produces: `Route.Recipe.detail(RecipeSummary)`; `RecipeViewCoordinator(service:)`.

- [ ] **Step 1: Add the route**

In `RecipeTest/Navigation/Route.swift`, replace `enum Route {}` with:

```swift
enum Route {
  /// The recipe module's destinations.
  ///
  /// Carries the whole `RecipeSummary` rather than an id: the detail screen fetches by id,
  /// which takes time, and having the summary lets it paint its title and hero image
  /// immediately instead of opening blank.
  enum Recipe: Hashable {
    case detail(RecipeSummary)
  }
}
```

Leave the existing doc comment above `enum Route` in place; it documents the pattern this is the first instance of.

- [ ] **Step 2: Write the placeholder detail screen**

Create `RecipeTest/Modules/Recipe/UI/Detail/RecipeDetailPlaceholderView.swift`:

```swift
//
//  RecipeDetailPlaceholderView.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

/// Stands in until the detail stage.
///
/// Exists so the routing seam is proved end to end now — a tap really does push, and the
/// summary really does arrive — rather than being written blind later. It shows only what
/// the summary already carries and calls no service.
struct RecipeDetailPlaceholderView: View {
  let recipe: RecipeSummary

  var body: some View {
    VStack(spacing: 12) {
      Text(recipe.title)
        .themeTextStyle(.title2)
        .themeColor(.textPrimary)
        .multilineTextAlignment(.center)

      Text(String(localized: .Recipe.recipeDetailPlaceholderMessage))
        .themeTextStyle(.bodyRegular)
        .themeColor(.textSecondary)
        .multilineTextAlignment(.center)
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.themeColor(.surfacesBackground))
    .navigationTitle(Text(recipe.title))
    .navigationBarTitleDisplayMode(.inline)
  }
}

// MARK: - Previews

#Preview {
  NavigationStack {
    RecipeDetailPlaceholderView(recipe: .dummy())
  }
}
```

- [ ] **Step 3: Write the coordinator**

Create `RecipeTest/Modules/Recipe/UI/RecipeViewCoordinator.swift`:

```swift
//
//  RecipeViewCoordinator.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

/// The recipe flow: the list, and every destination reachable from it.
///
/// Owns the view model rather than the screen doing so, which is what keeps navigation out
/// of the view — `RecipeListView` reports a tap and knows nothing about what happens next.
///
/// The service arrives as a defaulted initializer parameter, the pattern `AppContainer`
/// documents for itself, so a test or a preview substitutes a double without touching the
/// container.
struct RecipeViewCoordinator: ViewCoordinator {
  @Environment(PathRouter.self) private var pathRouter

  @State private var viewModel: RecipeListViewModel

  init(service: any RecipeServiceProtocol = AppContainer.shared.recipeService) {
    _viewModel = State(wrappedValue: RecipeListViewModel(service: service))
  }

  var body: some View {
    RecipeListView(viewModel: viewModel) { recipe in
      pathRouter.push(Route.Recipe.detail(recipe))
    }
    .navigationDestination(for: Route.Recipe.self) { route in
      switch route {
      case let .detail(recipe):
        RecipeDetailPlaceholderView(recipe: recipe)
      }
    }
  }
}
```

`State(wrappedValue:)` rather than a property initialiser, because the service comes from the initialiser — this is the supported way to seed `@State` from an init parameter, and it is evaluated only on the first render rather than on every re-init of the struct.

- [ ] **Step 4: Root the app on it**

In `RecipeTest/App/AppCoordinator.swift`, replace `placeholder` in the `NavigationStack` body:

```swift
    NavigationStack(path: $pathRouter.path) {
      RecipeViewCoordinator()
    }
    .environment(pathRouter)
```

Then delete the now-unused `// MARK: - Subviews` extension containing `placeholder`, and update the type's doc comment — it currently says the base project has no feature modules and roots on a placeholder, which stops being true here:

```swift
/// The root of the SwiftUI coordinator tree. Owns the `PathRouter` backing the
/// `NavigationStack` and decides which flow is shown.
///
/// One flow today: the recipe list. Branch here on session state once the app has
/// accounts.
```

- [ ] **Step 5: Build, run, and walk the feature**

Build and launch on the simulator. `AppConfig.usesMockAPI` routes every request to `Resources/MockData/recipes.json` (36 rows) through `MockAPIRouter`, so this exercises the real client against the fixture. Confirm:
- The list loads 10 rows after the router's 400 ms latency.
- Scrolling to the bottom loads the next page, and it stops after four pages — the footer disappears rather than spinning forever.
- The toolbar toggle switches to two columns and back, **keeping scroll position**.
- Pull-to-refresh returns to page 1 without the list ever going blank.
- Tapping a card pushes the placeholder showing that recipe's title; back returns to the list at the same scroll position, and does not refetch.
- The search bar is visible above the list in both layouts and does not respond to taps.

- [ ] **Step 6: Demonstrate the error and empty states against the real app**

In `AppContainer.bootstrap()`, temporarily change the router's `failureMode` to `.serverError`, run, and confirm the screen shows the error state with a working Try again. Then `.empty`, run, and confirm the empty state. **Set it back to `.none` and confirm the diff is clean before committing** — this is a throwaway edit, not part of the change.

- [ ] **Step 7: Run the whole test suite**

Run the test command with no `-only-testing` filter.
Expected: PASS.

- [ ] **Step 8: Format and commit**

```bash
swiftformat RecipeTest Tests UITests
swiftformat RecipeTest Tests UITests --lint
git add RecipeTest/Modules/Recipe/UI/Detail/RecipeDetailPlaceholderView.swift \
        RecipeTest/Modules/Recipe/UI/RecipeViewCoordinator.swift \
        RecipeTest/Navigation/Route.swift \
        RecipeTest/App/AppCoordinator.swift
git commit -m "feat(recipe): root the app on the recipe list"
```

- [ ] **Step 9: Confirm the unrelated files are still unstaged**

```bash
git status --short
```
Expected: only the three pre-existing modifications (`project.pbxproj` and the two `.xcscheme` files) remain, unstaged. If anything else appears, it was missed by a commit above.
