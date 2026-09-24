# Home Screen Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace `AppCoordinator`'s placeholder with the Bokkie Bites Home screen — logo, search pill, a Latest Recipes carousel and an Explore by Category grid — fed by the existing `RecipeService`, with tap callbacks wired to empty coordinator handlers.

**Architecture:** A new `Modules/Home/` module holds the scene (`HomeView` + `HomeViewModel` + protocol), its components, and `HomeViewCoordinator`. The two sections load independently through a generic `SectionState` added to `Modules/Shared/`, so one request failing degrades only its own section. The coordinator is the sole owner of what a tap leads to; in this stage every handler is empty.

**Tech Stack:** Swift 6, SwiftUI, iOS 26.3 deployment target, `@Observable`, Swift Testing (`@Test`/`#expect`), Kingfisher via the project's `CachedAsyncImage`, string catalogs (`.xcstrings`).

**Spec:** `docs/superpowers/specs/2026-09-24-home-screen-design.md`

## Global Constraints

- Indentation is 2 spaces. Max line length 120.
- Every new app-target type is declared `nonisolated` unless it must be main-actor. The app target sets `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`; the test target sets `nonisolated`.
- Every file opens with the project's header comment block: filename, `RecipeTest` (or `Tests`), `Created by Danjan ( https://github.com/Dannjann )`, `Copyright © 2026 Danjan. All rights reserved.`
- `// MARK: - Type` before a type, `// MARK: Section` inside one. Members grouped into MARK'd extensions, not one long body.
- No colour, font size or text literal is hardcoded. Colours go through `Color.themeColor(_:)` / `.themeColor(_:)`, fonts through `.themeTextStyle(_:)`, copy through `String(localized:)` or `LocalizedStringResource` against a string catalog.
- Every tappable element is a `Button`. Never `.onTapGesture`.
- Never `AnyView`. Never split a screen into `private var someSection: some View` — extract a real `View` type instead.
- Every new `View` type gets a `#Preview`.
- The Xcode project uses `fileSystemSynchronizedGroups`. Never edit `RecipeTest.xcodeproj/project.pbxproj`.
- Commit messages: `[home] <imperative message>`, ≤72 characters, no trailing period. No `Co-Authored-By` trailer.
- Branch is `feat/dan/home-screen`, already created off `develop`.

**Build and test command** (used by every verification step; substitute the simulator name if that device is absent):

```bash
xcodebuild test -project RecipeTest.xcodeproj -scheme RecipeTest \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:Tests 2>&1 | tail -40
```

To find a destination `xcodebuild` will actually accept:

```bash
xcodebuild -showdestinations -project RecipeTest.xcodeproj -scheme RecipeTest 2>&1 | grep -v error:
```

## Review Focus

Five conditions the spec implies that a naive implementation gets wrong. Each has a test in the task that owns the code, noted inline.

1. **A cancelled `.task` must not render as an error.** SwiftUI cancels `.task` when the view disappears; the in-flight request throws `CancellationError` (or `URLError.cancelled`). Rendering that as a red "cancelled" section is wrong — the section keeps whatever it had. *Tested in Task 2.*
2. **Pull-to-refresh must not blank the screen.** `loadContent()` resetting a `.loaded` section to `.loading` replaces content the user is looking at with a spinner, while the refresh control is already spinning. A section that has content keeps it during a refresh. *Tested in Task 2.*
3. **Retry from a failed section must clear the error first.** Tapping Retry while `.failed` must move to `.loading`, not sit on the stale message until the new response lands. *Tested in Task 2.*
4. **A recipe or category with no image URL must still render.** `heroImageURL` and `imageURL` are both `URL?`. The card and tile must show the placeholder fill and the title, not an empty or collapsed frame. *Covered by a dedicated `#Preview` in Task 4, and by the card's frame being set independently of the image.*
5. **A long title at an accessibility text size must not clip or overflow the card.** The prototype's 170×240 card is a fixed mock. *Covered by `@ScaledMetric` sizing plus a Dynamic Type `#Preview` in Task 4.*

---

### Task 1: Shared section state

The four-case vocabulary both Home sections use, and the view that renders three of them.

**Files:**
- Create: `RecipeTest/Modules/Shared/UI/Models/SectionState.swift`
- Create: `RecipeTest/Modules/Shared/UI/Components/SectionStateView.swift`
- Modify: `RecipeTest/Modules/Shared/UI/Shared.xcstrings`
- Test: none — an enum with no logic and a view covered by previews

**Interfaces:**
- Consumes: `VoidResult` from `RecipeTest/Helpers/Closures.swift`; `.themeTextStyle(_:)`, `.themeColor(_:)`; the `shared.error.somethingWentWrong` key already in `Shared.xcstrings`.
- Produces: `SectionState<Value>` with cases `.loading`, `.loaded(Value)`, `.empty`, `.failed(String)` and getters `value: Value?` / `isLoaded: Bool`; `SectionStateView<Value, Content>` initialised as `SectionStateView(state:minHeight:emptyMessage:onRetryTap:content:)`.

- [ ] **Step 1: Add the retry string to `Shared.xcstrings`**

Add one entry to the `strings` object, keeping the file's existing shape (`"extractionState": "manual"`, `"state": "translated"`):

```json
"shared.retry" : {
  "extractionState" : "manual",
  "localizations" : {
    "en" : {
      "stringUnit" : {
        "state" : "translated",
        "value" : "Try again"
      }
    }
  }
}
```

Keys in this file are sorted alphabetically — `shared.retry` goes after the `shared.error.*` entries.

- [ ] **Step 2: Create `SectionState.swift`**

```swift
//
//  SectionState.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

/// What one section of a screen currently has to show.
///
/// A screen whose sections are fed by separate requests needs this per section rather
/// than once for the whole screen: a categories outage should cost the categories grid
/// and nothing else.
///
/// `.empty` is deliberately distinct from `.loaded([])`. Zero rows is a legitimate answer
/// with its own copy, and a view that has to ask `isEmpty` to decide which of two things
/// to draw has the state machine in the wrong place.
///
/// `failed` carries the message rather than the `Error` so the enum stays `Equatable` and
/// a test can assert on what the reader is actually shown.
nonisolated enum SectionState<Value: Equatable>: Equatable {
  case loading
  case loaded(Value)
  case empty
  case failed(String)
}

// MARK: - Getters

nonisolated extension SectionState {
  var value: Value? {
    guard case let .loaded(value) = self else { return nil }

    return value
  }

  var isLoaded: Bool {
    value != nil
  }
}
```

- [ ] **Step 3: Create `SectionStateView.swift`**

```swift
//
//  SectionStateView.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

/// Renders the three states a section can be in that are not its content, and hands the
/// fourth to its caller.
///
/// `minHeight` holds the section's footprint across all four cases, so the page below it
/// does not jump as each section resolves at its own pace.
struct SectionStateView<Value: Equatable, Content: View>: View {
  let state: SectionState<Value>
  let minHeight: CGFloat
  let emptyMessage: LocalizedStringResource
  let onRetryTap: VoidResult

  @ViewBuilder let content: (Value) -> Content

  var body: some View {
    switch state {
    case .loading:
      ProgressView()
        .tint(.themeColor(.iconsBrandDefault))
        .frame(maxWidth: .infinity, minHeight: minHeight)

    case let .loaded(value):
      content(value)

    case .empty:
      message(title: Text(emptyMessage), description: nil, showsRetry: false)

    case let .failed(description):
      message(
        title: Text(String(localized: .Shared.sharedErrorSomethingWentWrong)),
        description: Text(description),
        showsRetry: true
      )
    }
  }
}

// MARK: - Subviews

private extension SectionStateView {
  func message(title: Text, description: Text?, showsRetry: Bool) -> some View {
    VStack(spacing: 12) {
      title
        .themeTextStyle(.bodyBold)
        .themeColor(.textPrimary)

      if let description {
        description
          .themeTextStyle(.subheadlineRegular)
          .themeColor(.textSecondary)
          .multilineTextAlignment(.center)
      }

      if showsRetry {
        Button(String(localized: .Shared.sharedRetry), action: onRetryTap)
          .themeTextStyle(.bodyBold)
          .foregroundStyle(.themeColor(.textBrandDefault))
      }
    }
    .frame(maxWidth: .infinity, minHeight: minHeight)
    .padding(.horizontal, 20)
  }
}

#Preview("Loading") {
  SectionStateView(
    state: SectionState<[String]>.loading,
    minHeight: 240,
    emptyMessage: "Nothing here yet",
    onRetryTap: {},
    content: { Text($0.joined()) }
  )
}

#Preview("Empty") {
  SectionStateView(
    state: SectionState<[String]>.empty,
    minHeight: 240,
    emptyMessage: "Nothing here yet",
    onRetryTap: {},
    content: { Text($0.joined()) }
  )
}

#Preview("Failed") {
  SectionStateView(
    state: SectionState<[String]>.failed("The request timed out."),
    minHeight: 240,
    emptyMessage: "Nothing here yet",
    onRetryTap: {},
    content: { Text($0.joined()) }
  )
}
```

- [ ] **Step 4: Build to verify it compiles**

Run:

```bash
xcodebuild build -project RecipeTest.xcodeproj -scheme RecipeTest \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -20
```

Expected: `BUILD SUCCEEDED`. If `.Shared.sharedRetry` does not resolve, the JSON edit in Step 1 is malformed — validate it with `python3 -m json.tool RecipeTest/Modules/Shared/UI/Shared.xcstrings > /dev/null`.

- [ ] **Step 5: Commit**

```bash
git add RecipeTest/Modules/Shared
git commit -m "[home] Add a per-section loading state and its view"
```

---

### Task 2: Home view model

The unit that turns two service calls into two independent section states. This task carries the plan's real test coverage.

**Files:**
- Create: `RecipeTest/Modules/Home/UI/Scenes/HomeViewModelProtocol.swift`
- Create: `RecipeTest/Modules/Home/UI/Scenes/HomeViewModel.swift`
- Create: `Tests/Mocks/Modules/Recipe/Models/DummyRecipeSummary.swift`
- Create: `Tests/Mocks/Modules/Recipe/Models/DummyRecipeCategory.swift`
- Create: `Tests/Mocks/Modules/Recipe/Services/MockRecipeService.swift`
- Test: `Tests/Modules/Home/UI/Scenes/HomeViewModelTests.swift`

**Interfaces:**
- Consumes: `SectionState<Value>` (Task 1); `RecipeServiceProtocol.getRecipes(query:page:)` returning `RecipeListPage` and `.getCategories()` returning `[RecipeCategory]`; `RecipeQuery(sort:)`; `Page(index:size:)`; `AppContainer.shared.recipeService`; `MockAPICall<Request, Response>` from `Tests/Mocks/Support/`.
- Produces: `HomeViewModelProtocol` with `latestRecipes: SectionState<[RecipeSummary]>`, `categories: SectionState<[RecipeCategory]>`, `loadContent() async`, `loadLatestRecipes() async`, `loadCategories() async`; `HomeViewModel(recipeService:)`; `HomeViewModel.latestRecipesPageSize` (`6`); `RecipeSummary.dummy(...)`, `RecipeCategory.dummy(...)`, `MockRecipeService(recipes:recipe:categories:)` exposing `recipes`, `recipe`, `categories` as `MockAPICall`s.

- [ ] **Step 1: Create the domain dummies**

`Tests/Mocks/Modules/Recipe/Models/DummyRecipeSummary.swift`:

```swift
//
//  DummyRecipeSummary.swift
//  Tests
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation
@testable import RecipeTest

extension RecipeSummary {
  static func dummy(
    id: String = "rcp-001",
    title: String = "Spaghetti alla Carbonara",
    heroImageURL: URL? = URL(string: "https://example.com/carbonara.jpg"),
    category: String? = "Pasta",
    cuisine: String? = "italian",
    mealType: String? = "dinner",
    totalTimeMinutes: Int? = 25,
    servings: Int? = 4,
    difficulty: RecipeDifficulty? = .medium,
    isVegetarian: Bool = false
  ) -> RecipeSummary {
    RecipeSummary(
      id: id,
      title: title,
      heroImageURL: heroImageURL,
      category: category,
      cuisine: cuisine,
      mealType: mealType,
      totalTimeMinutes: totalTimeMinutes,
      servings: servings,
      difficulty: difficulty,
      isVegetarian: isVegetarian
    )
  }
}
```

`Tests/Mocks/Modules/Recipe/Models/DummyRecipeCategory.swift`:

```swift
//
//  DummyRecipeCategory.swift
//  Tests
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation
@testable import RecipeTest

extension RecipeCategory {
  static func dummy(
    id: String = "cat-01",
    name: String = "Meal",
    imageURL: URL? = URL(string: "https://example.com/meal.jpg"),
    recipeCount: Int = 18
  ) -> RecipeCategory {
    RecipeCategory(
      id: id,
      name: name,
      imageURL: imageURL,
      recipeCount: recipeCount
    )
  }
}
```

If either initialiser's parameter labels differ, read the domain model and match it — do not change the model.

- [ ] **Step 2: Create `MockRecipeService`**

`Tests/Mocks/Modules/Recipe/Services/MockRecipeService.swift`:

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

/// A `RecipeServiceProtocol` double, shaped like `MockRecipeAPI`: one `MockAPICall` per
/// method, so one endpoint can be made to fail while its neighbours keep answering —
/// which is the whole point of the screen this doubles for.
final class MockRecipeService: RecipeServiceProtocol {
  /// Named rather than a tuple so `lastRequest` can be compared in one `#expect`.
  struct RecipesRequest: Equatable {
    let query: RecipeQuery
    let page: Page
  }

  let recipes: MockAPICall<RecipesRequest, RecipeListPage>
  let recipe: MockAPICall<String, Recipe>
  let categories: MockAPICall<Void, [RecipeCategory]>

  init(
    recipes: RecipeListPage = RecipeListPage(recipes: [.dummy()], meta: .dummy()),
    recipe: Recipe? = nil,
    categories: [RecipeCategory] = [.dummy()]
  ) {
    self.recipes = MockAPICall(returning: recipes)
    self.categories = MockAPICall(returning: categories)

    // `Recipe` has no dummy yet — no screen in this stage fetches one. A test that needs
    // the detail call stubs it itself rather than paying for a factory nothing reads.
    self.recipe = MockAPICall(
      returning: recipe ?? Recipe(
        id: "rcp-001",
        title: "Spaghetti alla Carbonara",
        description: "",
        heroImageURL: nil,
        category: nil,
        cuisine: nil,
        mealType: nil,
        totalTimeMinutes: nil,
        servings: nil,
        difficulty: nil,
        isVegetarian: false,
        gallery: [],
        ingredients: [],
        steps: []
      )
    )
  }
}

// MARK: - RecipeServiceProtocol

extension MockRecipeService {
  func getRecipes(query: RecipeQuery, page: Page) async throws -> RecipeListPage {
    try await recipes.invoke(RecipesRequest(query: query, page: page))
  }

  func getRecipe(id: String) async throws -> Recipe {
    try await recipe.invoke(id)
  }

  func getCategories() async throws -> [RecipeCategory] {
    try await categories.invoke(())
  }
}
```

`RemotePaginationMetaInfo.dummy()` already exists and `PaginationMetaInfo` is a typealias for it, so `.dummy()` resolves for the `meta` argument.

- [ ] **Step 3: Write the failing tests**

`Tests/Modules/Home/UI/Scenes/HomeViewModelTests.swift`:

```swift
//
//  HomeViewModelTests.swift
//  Tests
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation
@testable import RecipeTest
import Testing

@MainActor
struct HomeViewModelTests {
  @Test
  func loadContent_bothSucceed_loadsBothSections() async {
    let service = MockRecipeService(
      recipes: RecipeListPage(recipes: [.dummy(id: "rcp-001")], meta: .dummy()),
      categories: [.dummy(id: "cat-01")]
    )
    let sut = HomeViewModel(recipeService: service)

    await sut.loadContent()

    #expect(sut.latestRecipes.value?.map(\.id) == ["rcp-001"])
    #expect(sut.categories.value?.map(\.id) == ["cat-01"])
  }

  @Test
  func loadContent_asksForTheSixLatestRecipes() async {
    let service = MockRecipeService()
    let sut = HomeViewModel(recipeService: service)

    await sut.loadContent()

    #expect(service.recipes.lastRequest?.query.sort == .latest)
    #expect(service.recipes.lastRequest?.page == Page(index: 1, size: 6))
  }

  /// The point of per-section state: one outage costs one section.
  @Test
  func loadContent_categoriesFails_leavesTheRecipesSectionLoaded() async {
    let service = MockRecipeService()
    service.categories.fails(with: AppError.unknown)
    let sut = HomeViewModel(recipeService: service)

    await sut.loadContent()

    #expect(sut.latestRecipes.isLoaded)
    #expect(sut.categories.isLoaded == false)
  }

  @Test
  func loadContent_recipesFails_leavesTheCategoriesSectionLoaded() async {
    let service = MockRecipeService()
    service.recipes.fails(with: AppError.unknown)
    let sut = HomeViewModel(recipeService: service)

    await sut.loadContent()

    #expect(sut.categories.isLoaded)
    #expect(sut.latestRecipes.isLoaded == false)
  }

  @Test
  func loadContent_noRows_reportsEmptyRatherThanAnEmptyLoad() async {
    let service = MockRecipeService(
      recipes: RecipeListPage(recipes: [], meta: .dummy()),
      categories: []
    )
    let sut = HomeViewModel(recipeService: service)

    await sut.loadContent()

    #expect(sut.latestRecipes == .empty)
    #expect(sut.categories == .empty)
  }

  @Test
  func loadLatestRecipes_afterAFailure_recoversTheSection() async {
    let service = MockRecipeService()
    service.recipes.fails(with: AppError.unknown)
    let sut = HomeViewModel(recipeService: service)
    await sut.loadContent()

    service.recipes.returns(RecipeListPage(recipes: [.dummy(id: "rcp-002")], meta: .dummy()))
    await sut.loadLatestRecipes()

    #expect(sut.latestRecipes.value?.map(\.id) == ["rcp-002"])
  }

  /// Review Focus 3. Retry has to clear the stale message before the new answer lands,
  /// or the section sits on an error while it is already refetching.
  @Test
  func loadLatestRecipes_fromFailed_clearsTheErrorBeforeTheResponseArrives() async {
    let service = MockRecipeService()
    service.recipes.fails(with: AppError.unknown)
    let sut = HomeViewModel(recipeService: service)
    await sut.loadContent()

    let observed = StateBox()
    service.recipes.responds { _ in
      await observed.record(sut.latestRecipes)

      return RecipeListPage(recipes: [.dummy()], meta: .dummy())
    }
    await sut.loadLatestRecipes()

    #expect(observed.value == .loading)
  }

  /// Review Focus 2. A refresh keeps what the reader is already looking at; replacing it
  /// with a spinner blanks the screen underneath a refresh control that is already
  /// spinning.
  @Test
  func loadContent_whenAlreadyLoaded_keepsTheContentVisibleWhileRefreshing() async {
    let service = MockRecipeService()
    let sut = HomeViewModel(recipeService: service)
    await sut.loadContent()

    let observed = StateBox()
    service.recipes.responds { _ in
      await observed.record(sut.latestRecipes)

      return RecipeListPage(recipes: [.dummy()], meta: .dummy())
    }
    await sut.loadContent()

    #expect(observed.value?.isLoaded == true)
  }

  /// Review Focus 1. SwiftUI cancels `.task` on disappear; that must not paint an error.
  @Test
  func loadLatestRecipes_whenCancelled_keepsTheSectionItAlreadyHad() async {
    let service = MockRecipeService()
    let sut = HomeViewModel(recipeService: service)
    await sut.loadContent()
    let loaded = sut.latestRecipes

    service.recipes.fails(with: CancellationError())
    await sut.loadLatestRecipes()

    #expect(sut.latestRecipes == loaded)
  }

  @Test
  func loadLatestRecipes_whenTheURLLoadIsCancelled_keepsTheSectionItAlreadyHad() async {
    let service = MockRecipeService()
    let sut = HomeViewModel(recipeService: service)
    await sut.loadContent()
    let loaded = sut.latestRecipes

    service.recipes.fails(with: URLError(.cancelled))
    await sut.loadLatestRecipes()

    #expect(sut.latestRecipes == loaded)
  }

  @Test
  func loadCategories_whenItFails_showsTheErrorDescription() async {
    let service = MockRecipeService()
    service.categories.fails(with: RecipeServiceError.unmappableRecipe(id: "rcp-001"))
    let sut = HomeViewModel(recipeService: service)

    await sut.loadCategories()

    #expect(sut.categories == .failed(RecipeServiceError.unmappableRecipe(id: "rcp-001").localizedDescription))
  }
}

// MARK: - Helpers

/// Lets a stubbed response read the state the view model is in *while* that response is
/// still in flight. A captured `var` cannot be written from the stub's closure — it
/// escapes into `MockAPICall` and runs off the test's isolation — so the observation goes
/// through a reference instead.
private final class StateBox: @unchecked Sendable {
  private let lock = NSLock()
  private var recorded: SectionState<[RecipeSummary]>?

  var value: SectionState<[RecipeSummary]>? {
    lock.withLock { recorded }
  }

  func record(_ state: SectionState<[RecipeSummary]>) {
    lock.withLock { recorded = state }
  }
}
```

- [ ] **Step 4: Run the tests to verify they fail**

Run the build-and-test command from Global Constraints.
Expected: compile failure — `cannot find 'HomeViewModel' in scope`.

- [ ] **Step 5: Create `HomeViewModelProtocol.swift`**

```swift
//
//  HomeViewModelProtocol.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

/// What `HomeView` reads and calls.
///
/// Inputs are the three `load*` methods, outputs the two section states — the MVVM shape
/// the team standards ask for. The protocol is what lets a preview drive the screen into
/// any state without a service behind it.
@MainActor
protocol HomeViewModelProtocol {
  var latestRecipes: SectionState<[RecipeSummary]> { get }
  var categories: SectionState<[RecipeCategory]> { get }

  func loadContent() async
  func loadLatestRecipes() async
  func loadCategories() async
}
```

- [ ] **Step 6: Create `HomeViewModel.swift`**

```swift
//
//  HomeViewModel.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

@Observable
final class HomeViewModel: HomeViewModelProtocol {
  /// The prototype's carousel length. A teaser, not a page — "see all" belongs to the
  /// list screen a later stage adds, so nothing here paginates.
  static let latestRecipesPageSize = 6

  private(set) var latestRecipes: SectionState<[RecipeSummary]> = .loading
  private(set) var categories: SectionState<[RecipeCategory]> = .loading

  private let recipeService: RecipeServiceProtocol

  init(recipeService: RecipeServiceProtocol = AppContainer.shared.recipeService) {
    self.recipeService = recipeService
  }
}

// MARK: - Inputs

extension HomeViewModel {
  /// Both sections at once, and neither can cancel the other: the two `await`s sit in
  /// their own `do`/`catch` inside the methods below, so a thrown error never leaves this
  /// scope.
  func loadContent() async {
    async let recipes: Void = loadLatestRecipes()
    async let categories: Void = loadCategories()

    _ = await (recipes, categories)
  }

  func loadLatestRecipes() async {
    latestRecipes = refreshing(latestRecipes)

    do {
      let page = try await recipeService.getRecipes(
        query: RecipeQuery(sort: .latest),
        page: Page(index: 1, size: Self.latestRecipesPageSize)
      )

      latestRecipes = state(for: page.recipes)
    } catch {
      latestRecipes = state(for: error, keeping: latestRecipes)
    }
  }

  func loadCategories() async {
    categories = refreshing(categories)

    do {
      categories = try await state(for: recipeService.getCategories())
    } catch {
      categories = state(for: error, keeping: categories)
    }
  }
}

// MARK: - Helpers

private extension HomeViewModel {
  /// A refresh keeps what is already on screen. Only a section with nothing to show
  /// becomes a spinner — which is also what makes Retry clear a stale error message.
  func refreshing<Value>(_ current: SectionState<Value>) -> SectionState<Value> {
    current.isLoaded ? current : .loading
  }

  /// Zero rows is `.empty`, never `.loaded([])` — the two have different copy, and a view
  /// that has to ask `isEmpty` is deciding something this type already decided.
  func state<Value: Collection & Equatable>(for value: Value) -> SectionState<Value> {
    value.isEmpty ? .empty : .loaded(value)
  }

  /// Cancellation is not a failure. SwiftUI cancels a `.task` every time the view
  /// disappears, and painting "cancelled" across a section the reader is walking away
  /// from — then leaving it there when they come back — is worse than showing nothing
  /// new.
  func state<Value>(for error: any Error, keeping current: SectionState<Value>) -> SectionState<Value> {
    guard !isCancellation(error) else { return current }

    let description = error.localizedDescription

    return .failed(description.isEmpty ? String(localized: .Shared.sharedErrorSomethingWentWrong) : description)
  }

  func isCancellation(_ error: any Error) -> Bool {
    error is CancellationError || (error as? URLError)?.code == .cancelled
  }
}
```

- [ ] **Step 7: Run the tests to verify they pass**

Run the build-and-test command from Global Constraints.
Expected: all `HomeViewModelTests` pass, and the existing suites still pass.

If `refreshing` is reported as unreachable for the `.failed` → `.loading` test, check that `SectionState.isLoaded` returns `false` for `.failed` — that is what makes Retry clear the message.

- [ ] **Step 8: Commit**

```bash
git add RecipeTest/Modules/Home Tests/Mocks Tests/Modules/Home
git commit -m "[home] Add the Home view model and its tests"
```

---

### Task 3: Brand asset, copy, and the two text-only components

**Files:**
- Create: `RecipeTest/Resources/Assets.xcassets/BokkieBitesLogo.imageset/Contents.json`
- Create: `RecipeTest/Resources/Assets.xcassets/BokkieBitesLogo.imageset/BokkieBitesLogo.svg`
- Create: `RecipeTest/Modules/Home/UI/Home.xcstrings`
- Create: `RecipeTest/Extensions/SwiftUI/ViewModifiers/View+CardShadow.swift`
- Create: `RecipeTest/Modules/Home/UI/Components/HomeSectionHeader.swift`
- Create: `RecipeTest/Modules/Home/UI/Components/HomeSearchPill.swift`

**Interfaces:**
- Consumes: `.themeTextStyle(_:)`, `.themeColor(_:)`, `VoidResult`.
- Produces: `ImageResource.bokkieBitesLogo`; `View.cardShadow()`; `HomeSectionHeader(title:)` taking a `LocalizedStringResource`; `HomeSearchPill(onTap:)`; the `Home` string table with keys `home.searchPlaceholder`, `home.latestRecipes.title`, `home.latestRecipes.empty`, `home.categories.title`, `home.categories.empty`, `home.logo.accessibilityLabel`.

- [ ] **Step 1: Import the logo**

```bash
mkdir -p RecipeTest/Resources/Assets.xcassets/BokkieBitesLogo.imageset
cp "/Users/dan/Documents/Personal/Projects/B App/Bokkie-Bites-Logo.svg" \
   RecipeTest/Resources/Assets.xcassets/BokkieBitesLogo.imageset/BokkieBitesLogo.svg
```

Then write `RecipeTest/Resources/Assets.xcassets/BokkieBitesLogo.imageset/Contents.json`:

```json
{
  "images" : [
    {
      "filename" : "BokkieBitesLogo.svg",
      "idiom" : "universal"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  },
  "properties" : {
    "preserves-vector-representation" : true
  }
}
```

No `"template-rendering-intent"`: the mark is two colours (`#4A2B1E` and `#4C80D1`) and a template would flatten the blue.

- [ ] **Step 2: Create `Home.xcstrings`**

`RecipeTest/Modules/Home/UI/Home.xcstrings`, matching the shape of `Shared.xcstrings`:

```json
{
  "sourceLanguage" : "en",
  "strings" : {
    "home.categories.empty" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "No categories yet" } }
      }
    },
    "home.categories.title" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Explore by Category" } }
      }
    },
    "home.latestRecipes.empty" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "No recipes yet" } }
      }
    },
    "home.latestRecipes.title" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Latest Recipes" } }
      }
    },
    "home.logo.accessibilityLabel" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Bokkie Bites" } }
      }
    },
    "home.searchPlaceholder" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Search recipes or ingredients" } }
      }
    }
  },
  "version" : "1.0"
}
```

These resolve as `.Home.homeSearchPlaceholder`, `.Home.homeLatestRecipesTitle`, and so on — the same generation `.Core.coreErrorParseFailed` already relies on.

- [ ] **Step 3: Create the shadow modifier**

`RecipeTest/Extensions/SwiftUI/ViewModifiers/View+CardShadow.swift`:

```swift
//
//  View+CardShadow.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

extension View {
  /// The prototype's one elevation, used by every raised surface on Home — the search
  /// pill, the carousel cards and the category tiles.
  ///
  /// Two layers, because the CSS it comes from has two:
  /// `0 1px 3px rgba(74,43,30,.08), 0 10px 28px rgba(74,43,30,.12)`. A CSS blur radius is
  /// roughly twice SwiftUI's, which is where 3 → 1.5 and 28 → 14 come from. The colour is
  /// the brand brown rather than black: a neutral shadow on a cream ground reads grey.
  func cardShadow() -> some View {
    shadow(color: .themeColor(.textPrimary).opacity(0.08), radius: 1.5, y: 1)
      .shadow(color: .themeColor(.textPrimary).opacity(0.12), radius: 14, y: 10)
  }
}
```

- [ ] **Step 4: Create `HomeSectionHeader`**

`RecipeTest/Modules/Home/UI/Components/HomeSectionHeader.swift`:

```swift
//
//  HomeSectionHeader.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

/// "Latest Recipes" and "Explore by Category".
///
/// The prototype sets these at 26pt; `.title2` is the theme's nearest rung at 24. Minting
/// a one-off token for a 2pt difference on one screen costs more than the difference.
struct HomeSectionHeader: View {
  let title: LocalizedStringResource

  var body: some View {
    Text(title)
      .themeTextStyle(.title2)
      .themeColor(.textPrimary)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal, 20)
      .padding(.top, 30)
      .padding(.bottom, 14)
      .accessibilityAddTraits(.isHeader)
  }
}

#Preview {
  VStack(spacing: 0) {
    HomeSectionHeader(title: .Home.homeLatestRecipesTitle)
    HomeSectionHeader(title: .Home.homeCategoriesTitle)
  }
  .frame(maxWidth: .infinity, maxHeight: .infinity)
  .background(Color.themeColor(.surfacesBackground))
}
```

- [ ] **Step 5: Create `HomeSearchPill`**

`RecipeTest/Modules/Home/UI/Components/HomeSearchPill.swift`:

```swift
//
//  HomeSearchPill.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

/// The search affordance at the top of Home.
///
/// A `Button` rather than a `TextField`: tapping it opens the search overlay in a later
/// stage; nothing is typed into it here. It is not a Liquid Glass surface on purpose —
/// the prototype is a flat cream sheet with soft brown shadows, and glass would read as a
/// different product.
struct HomeSearchPill: View {
  let onTap: VoidResult

  @ScaledMetric(relativeTo: .body) private var height: CGFloat = 56

  var body: some View {
    Button(action: onTap) {
      HStack(spacing: 10) {
        Image(systemName: "magnifyingglass")
          .foregroundStyle(.themeColor(.iconsDefault))

        Text(.Home.homeSearchPlaceholder)
          .themeTextStyle(.bodyRegular)
          .themeColor(.textPrimary)
          .lineLimit(1)
      }
      .frame(maxWidth: .infinity, minHeight: height)
      .padding(.horizontal, 20)
      .background(Color.themeColor(.surfacesBackground2), in: .capsule)
    }
    .buttonStyle(.plain)
    .cardShadow()
    .padding(.horizontal, 20)
  }
}

#Preview {
  HomeSearchPill(onTap: {})
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.themeColor(.surfacesBackground))
}
```

- [ ] **Step 6: Build and verify the previews render**

Run:

```bash
xcodebuild build -project RecipeTest.xcodeproj -scheme RecipeTest \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -20
```

Expected: `BUILD SUCCEEDED`, and `Image(.bokkieBitesLogo)` resolves (it is used in Task 5; if the symbol is missing here, the imageset JSON is wrong).

Open `HomeSearchPill.swift` in Xcode and confirm the preview shows a white capsule on cream with a soft brown shadow.

- [ ] **Step 7: Commit**

```bash
git add RecipeTest/Resources/Assets.xcassets/BokkieBitesLogo.imageset \
        RecipeTest/Modules/Home/UI/Home.xcstrings \
        RecipeTest/Extensions/SwiftUI/ViewModifiers/View+CardShadow.swift \
        RecipeTest/Modules/Home/UI/Components
git commit -m "[home] Add the logo, copy and the header and search pill"
```

---

### Task 4: The two photographic components

**Files:**
- Create: `RecipeTest/Modules/Home/UI/Components/LatestRecipeCard.swift`
- Create: `RecipeTest/Modules/Home/UI/Components/RecipeCategoryTile.swift`

**Interfaces:**
- Consumes: `RecipeSummary` (`id`, `title`, `heroImageURL`), `RecipeCategory` (`id`, `name`, `imageURL`), `CachedAsyncImage(url:placeholder:)`, `View.cardShadow()`, `SingleResult<T>`.
- Produces: `LatestRecipeCard(recipe:onTap:)`, `RecipeCategoryTile(category:onTap:)`, `LatestRecipeCard.baseHeight` (`240`) and `RecipeCategoryTile.baseWidth` (`104`) for the grid and carousel to size their sections by.

- [ ] **Step 1: Create `LatestRecipeCard`**

```swift
//
//  LatestRecipeCard.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

/// One card in Home's Latest Recipes carousel: the photograph, a bottom gradient, and the
/// title over it.
///
/// The prototype's 170×240 is a fixed mock. Here both dimensions scale with the reader's
/// text size, because the title lives inside the card — a fixed box would clip the very
/// text somebody enlarged it to read.
struct LatestRecipeCard: View {
  static let baseWidth: CGFloat = 170
  static let baseHeight: CGFloat = 240

  let recipe: RecipeSummary
  let onTap: SingleResult<String>

  @Environment(\.dynamicTypeSize) private var dynamicTypeSize

  @ScaledMetric(relativeTo: .body) private var width: CGFloat = LatestRecipeCard.baseWidth
  @ScaledMetric(relativeTo: .body) private var height: CGFloat = LatestRecipeCard.baseHeight

  var body: some View {
    Button {
      onTap(recipe.id)
    } label: {
      photograph
        .frame(width: width, height: height)
        .overlay(alignment: .bottom) { gradient }
        .overlay(alignment: .bottomLeading) { title }
        .clipShape(.rect(cornerRadius: 28))
    }
    .buttonStyle(.plain)
    .cardShadow()
    .accessibilityElement(children: .combine)
    .accessibilityLabel(Text(recipe.title))
    .accessibilityAddTraits(.isButton)
  }
}

// MARK: - Subviews

private extension LatestRecipeCard {
  var photograph: some View {
    CachedAsyncImage(url: recipe.heroImageURL) {
      Color.themeColor(.surfacesBackground3)
    }
    .aspectRatio(contentMode: .fill)
    .frame(width: width, height: height)
    .clipped()
  }

  /// The prototype's gradient verbatim: opaque enough at the foot to carry white text,
  /// gone by two thirds up so the photograph is not dimmed for nothing.
  var gradient: some View {
    LinearGradient(
      stops: [
        .init(color: .black.opacity(0), location: 0.35),
        .init(color: .black.opacity(0.3), location: 0.6),
        .init(color: .black.opacity(0.8), location: 1)
      ],
      startPoint: .top,
      endPoint: .bottom
    )
    .frame(height: height)
    .allowsHitTesting(false)
  }

  var title: some View {
    Text(recipe.title)
      .themeTextStyle(.bodyBold)
      .themeColor(.textWhite)
      .multilineTextAlignment(.leading)
      // Truncating is the thing a reader raised the text size to avoid.
      .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)
      .padding(16)
  }
}

#Preview("Card") {
  LatestRecipeCard(recipe: .init(
    id: "rcp-001",
    title: "Spaghetti alla Carbonara",
    heroImageURL: URL(string: "https://www.themealdb.com/images/media/meals/llcbn01574260722.jpg"),
    category: "Pasta",
    cuisine: "italian",
    mealType: "dinner",
    totalTimeMinutes: 25,
    servings: 4,
    difficulty: .medium,
    isVegetarian: false
  ), onTap: { _ in })
  .frame(maxWidth: .infinity, maxHeight: .infinity)
  .background(Color.themeColor(.surfacesBackground))
}

/// Review Focus 4: the row has no photograph. The card keeps its shape and its title.
#Preview("Card — no photograph") {
  LatestRecipeCard(recipe: .init(
    id: "rcp-002",
    title: "Pão de Queijo",
    heroImageURL: nil,
    category: "Snacks",
    cuisine: "brazilian",
    mealType: "snack",
    totalTimeMinutes: 40,
    servings: 6,
    difficulty: .easy,
    isVegetarian: true
  ), onTap: { _ in })
  .frame(maxWidth: .infinity, maxHeight: .infinity)
  .background(Color.themeColor(.surfacesBackground))
}

/// Review Focus 5: a long title at the largest accessibility size.
#Preview("Card — long title, AX5") {
  LatestRecipeCard(recipe: .init(
    id: "rcp-003",
    title: "Slow-Braised Beef Short Rib with Gremolata and Soft Polenta",
    heroImageURL: nil,
    category: "Meal",
    cuisine: "italian",
    mealType: "dinner",
    totalTimeMinutes: 240,
    servings: 4,
    difficulty: .hard,
    isVegetarian: false
  ), onTap: { _ in })
  .environment(\.dynamicTypeSize, .accessibility5)
  .frame(maxWidth: .infinity, maxHeight: .infinity)
  .background(Color.themeColor(.surfacesBackground))
}
```

- [ ] **Step 2: Create `RecipeCategoryTile`**

```swift
//
//  RecipeCategoryTile.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

/// One tile in Home's Explore by Category grid: a square photograph with the category
/// name beneath it.
///
/// `baseWidth` is what three columns, 20pt page margins and 14pt gutters leave on the
/// narrowest phone the app supports. The grid scales it and adapts its column count
/// rather than squashing the label.
struct RecipeCategoryTile: View {
  static let baseWidth: CGFloat = 104

  let category: RecipeCategory
  let onTap: SingleResult<RecipeCategory>

  var body: some View {
    Button {
      onTap(category)
    } label: {
      VStack(spacing: 8) {
        photograph

        Text(category.name)
          .themeTextStyle(.subheadlineSemibold)
          .themeColor(.textPrimary)
          .multilineTextAlignment(.center)
      }
    }
    .buttonStyle(.plain)
    .accessibilityElement(children: .combine)
    .accessibilityLabel(Text(category.name))
    .accessibilityAddTraits(.isButton)
  }
}

// MARK: - Subviews

private extension RecipeCategoryTile {
  var photograph: some View {
    CachedAsyncImage(url: category.imageURL) {
      Color.themeColor(.surfacesBackground3)
    }
    .aspectRatio(contentMode: .fill)
    .frame(maxWidth: .infinity)
    .aspectRatio(1, contentMode: .fit)
    .clipShape(.rect(cornerRadius: 24))
    .cardShadow()
  }
}

#Preview("Tile") {
  RecipeCategoryTile(
    category: .init(
      id: "cat-01",
      name: "Meal",
      imageURL: URL(string: "https://images.unsplash.com/photo-1668971259423-c9f71fb6b7b4?w=480"),
      recipeCount: 18
    ),
    onTap: { _ in }
  )
  .frame(width: RecipeCategoryTile.baseWidth)
  .frame(maxWidth: .infinity, maxHeight: .infinity)
  .background(Color.themeColor(.surfacesBackground))
}

/// Review Focus 4: no photograph, and Review Focus 5: a name that does not fit one line.
#Preview("Tile — no photograph, long name") {
  RecipeCategoryTile(
    category: .init(id: "cat-07", name: "Slow Cooker Dinners", imageURL: nil, recipeCount: 3),
    onTap: { _ in }
  )
  .frame(width: RecipeCategoryTile.baseWidth)
  .frame(maxWidth: .infinity, maxHeight: .infinity)
  .background(Color.themeColor(.surfacesBackground))
}
```

- [ ] **Step 3: Build**

Run:

```bash
xcodebuild build -project RecipeTest.xcodeproj -scheme RecipeTest \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -20
```

Expected: `BUILD SUCCEEDED`.

If `CachedAsyncImage(url:placeholder:)` rejects the trailing closure, check its signature — the generic `Placeholder` init takes `@ViewBuilder placeholder: () -> Placeholder`, so `CachedAsyncImage(url: x) { Color... }` is correct and the two-argument `init(url:forceRefresh:)` overload is the one to avoid here.

- [ ] **Step 4: Check every preview in Xcode**

Open both files and step through all five previews. Confirm: the card's title sits over a readable gradient; the no-photograph card is a plain `surfacesBackground3` rectangle with the title still legible; the AX5 card has grown rather than clipped; the long category name wraps rather than truncating.

- [ ] **Step 5: Commit**

```bash
git add RecipeTest/Modules/Home/UI/Components
git commit -m "[home] Add the recipe carousel card and category tile"
```

---

### Task 5: The Home scene

**Files:**
- Create: `RecipeTest/Modules/Home/UI/Scenes/HomeView.swift`

**Interfaces:**
- Consumes: `HomeViewModelProtocol` (Task 2), `SectionStateView` (Task 1), `HomeSectionHeader` / `HomeSearchPill` (Task 3), `LatestRecipeCard` / `RecipeCategoryTile` (Task 4), `ImageResource.bokkieBitesLogo`, `VoidResult` / `SingleResult<T>`.
- Produces: `HomeView(viewModel:onSearchTap:onRecipeTap:onCategoryTap:)`.

- [ ] **Step 1: Create `HomeView.swift`**

```swift
//
//  HomeView.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

/// Home: the logo, a search affordance, the six newest recipes, and the category grid.
///
/// The view model arrives as a `let` rather than `@State` — `HomeViewCoordinator` owns
/// its lifetime, and Observation tracks a handed-over `@Observable` just the same.
///
/// The three callbacks are the whole of this screen's relationship with navigation. It
/// does not know a `PathRouter` exists.
struct HomeView: View {
  let viewModel: any HomeViewModelProtocol
  let onSearchTap: VoidResult
  let onRecipeTap: SingleResult<String>
  let onCategoryTap: SingleResult<RecipeCategory>

  var body: some View {
    ScrollView(.vertical) {
      VStack(alignment: .leading, spacing: 0) {
        logo

        HomeSearchPill(onTap: onSearchTap)

        HomeSectionHeader(title: .Home.homeLatestRecipesTitle)
        latestRecipes

        HomeSectionHeader(title: .Home.homeCategoriesTitle)
        categories
      }
      .padding(.bottom, 40)
    }
    .scrollIndicators(.hidden)
    .background(Color.themeColor(.surfacesBackground))
    .toolbarVisibility(.hidden, for: .navigationBar)
    .refreshable { await viewModel.loadContent() }
    .task { await viewModel.loadContent() }
  }
}

// MARK: - Subviews

private extension HomeView {
  var logo: some View {
    Image(.bokkieBitesLogo)
      .resizable()
      .scaledToFit()
      .frame(width: 112)
      .padding(.leading, 20)
      .padding(.top, 8)
      .padding(.bottom, 20)
      .accessibilityLabel(Text(.Home.homeLogoAccessibilityLabel))
      .accessibilityAddTraits(.isHeader)
  }

  var latestRecipes: some View {
    SectionStateView(
      state: viewModel.latestRecipes,
      minHeight: LatestRecipeCard.baseHeight,
      emptyMessage: .Home.homeLatestRecipesEmpty,
      onRetryTap: { Task { await viewModel.loadLatestRecipes() } }
    ) { recipes in
      LatestRecipeCarousel(recipes: recipes, onRecipeTap: onRecipeTap)
    }
  }

  var categories: some View {
    SectionStateView(
      state: viewModel.categories,
      minHeight: RecipeCategoryTile.baseWidth,
      emptyMessage: .Home.homeCategoriesEmpty,
      onRetryTap: { Task { await viewModel.loadCategories() } }
    ) { categories in
      RecipeCategoryGrid(categories: categories, onCategoryTap: onCategoryTap)
    }
  }
}

// MARK: - LatestRecipeCarousel

/// A real `View` rather than a computed property on `HomeView`: it is the unit SwiftUI
/// invalidates, and it reads only the recipes — so a change to the categories section
/// does not re-evaluate it.
private struct LatestRecipeCarousel: View {
  let recipes: [RecipeSummary]
  let onRecipeTap: SingleResult<String>

  var body: some View {
    ScrollView(.horizontal) {
      LazyHStack(spacing: 14) {
        ForEach(recipes) { recipe in
          LatestRecipeCard(recipe: recipe, onTap: onRecipeTap)
        }
      }
      .scrollTargetLayout()
      // The carousel runs edge to edge; the page margin is content inset, so the last
      // card can scroll clear of the screen edge instead of stopping short of it.
      .padding(.horizontal, 20)
      // Room for `cardShadow`'s 14pt blur, which a scroll view otherwise clips.
      .padding(.vertical, 16)
    }
    .scrollIndicators(.hidden)
    .scrollTargetBehavior(.viewAligned)
    .padding(.vertical, -16)
    .accessibilityLabel(Text(.Home.homeLatestRecipesTitle))
  }
}

// MARK: - RecipeCategoryGrid

private struct RecipeCategoryGrid: View {
  let categories: [RecipeCategory]
  let onCategoryTap: SingleResult<RecipeCategory>

  @ScaledMetric(relativeTo: .body) private var tileWidth: CGFloat = RecipeCategoryTile.baseWidth

  /// Adaptive rather than a fixed three: at an accessibility text size a 14pt label does
  /// not fit a 104pt tile, and the grid should drop to two columns and then one rather
  /// than squash it.
  private var columns: [GridItem] {
    [GridItem(.adaptive(minimum: tileWidth), spacing: 14)]
  }

  var body: some View {
    LazyVGrid(columns: columns, spacing: 18) {
      ForEach(categories) { category in
        RecipeCategoryTile(category: category, onTap: onCategoryTap)
      }
    }
    .padding(.horizontal, 20)
  }
}
```

- [ ] **Step 2: Add the preview stub view model and previews**

Append to `HomeView.swift`:

```swift
// MARK: - Previews

/// Drives the screen into any pair of states without a service behind it. `#if DEBUG` so
/// it cannot be reached from a release build.
#if DEBUG
  @Observable
  private final class PreviewHomeViewModel: HomeViewModelProtocol {
    var latestRecipes: SectionState<[RecipeSummary]>
    var categories: SectionState<[RecipeCategory]>

    init(
      latestRecipes: SectionState<[RecipeSummary]>,
      categories: SectionState<[RecipeCategory]>
    ) {
      self.latestRecipes = latestRecipes
      self.categories = categories
    }

    func loadContent() async {}
    func loadLatestRecipes() async {}
    func loadCategories() async {}
  }

  private extension RecipeSummary {
    static func preview(_ id: String, _ title: String) -> RecipeSummary {
      RecipeSummary(
        id: id,
        title: title,
        heroImageURL: nil,
        category: "Meal",
        cuisine: "filipino",
        mealType: "dinner",
        totalTimeMinutes: 45,
        servings: 4,
        difficulty: .easy,
        isVegetarian: false
      )
    }
  }

  private extension RecipeCategory {
    static func preview(_ id: String, _ name: String) -> RecipeCategory {
      RecipeCategory(id: id, name: name, imageURL: nil, recipeCount: 4)
    }
  }

  private let previewRecipes: [RecipeSummary] = [
    .preview("rcp-001", "Chicken Adobo"),
    .preview("rcp-002", "Pavlova"),
    .preview("rcp-003", "Gỏi Cuốn"),
    .preview("rcp-004", "Pão de Queijo"),
    .preview("rcp-005", "Pad Thai"),
    .preview("rcp-006", "Leche Flan")
  ]

  private let previewCategories: [RecipeCategory] = [
    .preview("cat-01", "Meal"),
    .preview("cat-02", "Rice"),
    .preview("cat-03", "Snacks"),
    .preview("cat-04", "Desserts"),
    .preview("cat-05", "Vegan"),
    .preview("cat-06", "Pasta")
  ]

  private func previewHome(
    latestRecipes: SectionState<[RecipeSummary]>,
    categories: SectionState<[RecipeCategory]>
  ) -> some View {
    NavigationStack {
      HomeView(
        viewModel: PreviewHomeViewModel(latestRecipes: latestRecipes, categories: categories),
        onSearchTap: {},
        onRecipeTap: { _ in },
        onCategoryTap: { _ in }
      )
    }
  }

  #Preview("Loaded") {
    previewHome(latestRecipes: .loaded(previewRecipes), categories: .loaded(previewCategories))
  }

  #Preview("Loading") {
    previewHome(latestRecipes: .loading, categories: .loading)
  }

  #Preview("Recipes failed, categories loaded") {
    previewHome(
      latestRecipes: .failed("The Internet connection appears to be offline."),
      categories: .loaded(previewCategories)
    )
  }

  #Preview("Empty") {
    previewHome(latestRecipes: .empty, categories: .empty)
  }

  #Preview("Loaded — AX3") {
    previewHome(latestRecipes: .loaded(previewRecipes), categories: .loaded(previewCategories))
      .environment(\.dynamicTypeSize, .accessibility3)
  }
#endif
```

- [ ] **Step 3: Build**

Run:

```bash
xcodebuild build -project RecipeTest.xcodeproj -scheme RecipeTest \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -20
```

Expected: `BUILD SUCCEEDED`.

If SwiftLint fails on file length, split the preview block into `HomeView+Previews.swift` in the same folder rather than shortening the previews.

- [ ] **Step 4: Check the previews**

Open `HomeView.swift` in Xcode and step through all five. Confirm against the prototype: logo top-left, centred search pill, a carousel that scrolls horizontally and snaps, a three-column category grid at default size that becomes two columns at AX3, and — in "Recipes failed, categories loaded" — an error with a Retry button where the carousel was, with the category grid below it intact.

- [ ] **Step 5: Commit**

```bash
git add RecipeTest/Modules/Home/UI/Scenes/HomeView.swift
git commit -m "[home] Add the Home scene"
```

---

### Task 6: Coordinator and app wiring

**Files:**
- Create: `RecipeTest/Modules/Home/UI/HomeViewCoordinator.swift`
- Modify: `RecipeTest/App/AppCoordinator.swift`

**Interfaces:**
- Consumes: `HomeView` (Task 5), `HomeViewModel` (Task 2), `AppContainer.shared.recipeService`, `ViewCoordinator`.
- Produces: `HomeViewCoordinator(recipeService:)`.

- [ ] **Step 1: Create `HomeViewCoordinator.swift`**

```swift
//
//  HomeViewCoordinator.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

/// Owns the Home flow: it constructs the scene's view model and is the only type that
/// decides where a tap on Home leads.
///
/// Every handler below is empty in this stage — the search overlay, the recipe list and
/// the recipe detail do not exist yet. They are wired anyway so that adding them is an
/// edit to this file and nothing else.
///
/// No `PathRouter` yet, deliberately. `AppCoordinator` already publishes one into the
/// environment; this coordinator picks it up with `@Environment(PathRouter.self)` when it
/// has a destination to push, rather than storing one it never reads.
struct HomeViewCoordinator: ViewCoordinator {
  @State private var viewModel: HomeViewModel

  init(recipeService: RecipeServiceProtocol = AppContainer.shared.recipeService) {
    _viewModel = State(initialValue: HomeViewModel(recipeService: recipeService))
  }

  var body: some View {
    HomeView(
      viewModel: viewModel,
      onSearchTap: handleSearchTap(),
      onRecipeTap: handleRecipeTap(),
      onCategoryTap: handleCategoryTap()
    )
  }
}

// MARK: - Handlers

private extension HomeViewCoordinator {
  /// Next stage: presents the search and filter overlay.
  func handleSearchTap() -> VoidResult {
    {}
  }

  /// Next stage: pushes `Route.Home.recipeDetail(id)`.
  func handleRecipeTap() -> SingleResult<String> {
    { _ in }
  }

  /// Next stage: pushes `Route.Home.recipeList(category)`.
  func handleCategoryTap() -> SingleResult<RecipeCategory> {
    { _ in }
  }
}

#Preview {
  NavigationStack {
    HomeViewCoordinator()
  }
}
```

- [ ] **Step 2: Root the app on Home**

Replace the whole of `RecipeTest/App/AppCoordinator.swift` with:

```swift
//
//  AppCoordinator.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

/// The root of the SwiftUI coordinator tree. Owns the `PathRouter` backing the
/// `NavigationStack` and decides which flow is shown.
///
/// One flow today. Branch here on session state once the app has accounts.
struct AppCoordinator: ViewCoordinator {
  @State private var pathRouter: PathRouter = .init()

  var body: some View {
    NavigationStack(path: $pathRouter.path) {
      HomeViewCoordinator()
    }
    .environment(pathRouter)
  }
}
```

The `placeholder` subview and its `private extension` go away entirely.

- [ ] **Step 3: Run the full test suite**

Run the build-and-test command from Global Constraints.
Expected: every suite passes, including the pre-existing ones.

- [ ] **Step 4: Run the app on a simulator and compare it to the prototype**

```bash
xcodebuild build -project RecipeTest.xcodeproj -scheme RecipeTest \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -5
xcrun simctl boot 'iPhone 17 Pro' 2>/dev/null || true
open -a Simulator
```

Install and launch the built `.app` (its path is in the build output under `Products/Debug-iphonesimulator`), then:

```bash
xcrun simctl install booted "<path>/RecipeTest.app"
xcrun simctl launch booted com.danjan.recipe
```

`com.danjan.recipe` is the Release/Production bundle id; a Debug build of the
`RecipeTest` scheme uses it too — `com.danjan.recipe-dev` belongs to the Staging target.

Confirm against `B App/bokkie-bites-prototype.html` opened in a browser at 390pt wide:
- cream background, logo top-left, centred search pill
- a 400ms spinner in each section, then content
- six cards in the carousel, photographs loading in
- a three-column category grid

Then exercise the error path by setting `failureMode: .serverError` in `AppContainer.bootstrap()`, relaunching, and confirming both sections show a Retry button. **Revert that edit before committing.**

- [ ] **Step 5: Commit**

```bash
git add RecipeTest/Modules/Home/UI/HomeViewCoordinator.swift RecipeTest/App/AppCoordinator.swift
git commit -m "[home] Root the app on the Home coordinator"
```

- [ ] **Step 6: Verify the working tree is clean and the branch is complete**

```bash
git status --short
git log --oneline develop..HEAD
```

Expected: no output from `status`; seven commits from `log` (the spec plus this plan, then the six task commits).
