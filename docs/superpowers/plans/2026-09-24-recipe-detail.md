# Recipe Detail Screen Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the Bokkie Bites Recipe Details screen — photo gallery, sticky title bar, overview, three metric cards, a main-ingredients strip, a tappable ingredient checklist and numbered instructions — reachable by tapping a card on Home, with the header painting from the tapped `RecipeSummary` before the detail request lands.

**Architecture:** A new `Modules/RecipeDetail/` module holds the scene, its components and its coordinator. `RecipeDetailViewModel` holds the tapped `RecipeSummary` as a `let` and the fetched `Recipe` as a `SectionState`, resolving the two through five getters so the header never waits on the network. `Route.Recipe.detail(RecipeSummary)` is the app's first route; `AppCoordinator` owns its `navigationDestination` and `HomeViewCoordinator` pushes it.

**Tech Stack:** Swift 6, SwiftUI, iOS 26.3 deployment target, `@Observable`, Swift Testing (`@Test`/`#expect`), Kingfisher via the project's `CachedAsyncImage`, string catalogs (`.xcstrings`).

**Spec:** `docs/superpowers/specs/2026-09-24-recipe-detail-design.md`

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
- Commit messages: `[detail] <imperative message>`, ≤72 characters, no trailing period. No `Co-Authored-By` trailer.
- Branch is `feat/dan/recipe-detail`, already created off `develop`.

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

To build without running tests, when a task changes only views:

```bash
xcodebuild build -project RecipeTest.xcodeproj -scheme RecipeTest \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -20
```

## Review Focus

Five conditions the spec implies that a naive implementation gets wrong. Each has a test in the task that owns the code, noted inline.

1. **A cancelled `.task` must not render as an error, and must not strand the screen on a spinner.** SwiftUI cancels `.task` on disappear; the in-flight `getRecipe` throws `CancellationError` or `URLError.cancelled`. The screen keeps whatever state it had before the load began — which means the pre-refresh state has to be captured *before* `refreshing` overwrites it. *Tested in Tasks 2 and 4.*
2. **Retrying after a failure must clear the error before the new response lands.** Tapping Retry while `.failed` must move to `.loading` immediately, not sit on the stale message. *Tested in Tasks 2 and 4.*
3. **A recipe with no photographs anywhere must still render.** `RecipeSummary.heroImageURL` is `URL?` and `Recipe.gallery` can be empty. `galleryURLs` must return an empty array rather than `[nil]`, and the gallery must draw its placeholder fill at full height rather than collapsing. *Tested in Task 4, previewed in Task 5.*
4. **A nil metric must not render as an empty card or the word "nil".** All three of `totalTimeMinutes`, `servings` and `difficulty` are optional. Each renders an em dash visually and announces "Not available" to VoiceOver. *Tested in Task 6 via the formatter getters, previewed in Task 6.*
5. **Ticked ingredients must survive a re-fetch.** `RecipeIngredient.id` is `"\(recipeID)-\(index)"`, so a retry that returns the same payload returns the same ids. A checklist keyed on array position instead would silently move the ticks. *Tested in Task 4.*

---

### Task 1: Accent colour tokens

The three pastels the metric cards and the step badge need. Adding a token touches five places; missing one produces a compile error, not a silent fallback.

**Files:**
- Create: `RecipeTest/Resources/Colors.xcassets/surfacesAccentPeach.colorset/Contents.json`
- Create: `RecipeTest/Resources/Colors.xcassets/surfacesAccentMint.colorset/Contents.json`
- Create: `RecipeTest/Resources/Colors.xcassets/surfacesAccentSky.colorset/Contents.json`
- Modify: `RecipeTest/Modules/Core/UI/Theme/Protocols/ThemeColorProtocol.swift`
- Modify: `RecipeTest/Modules/Core/UI/Theme/DefaultThemeColor.swift`
- Modify: `RecipeTest/Extensions/SwiftUI/ThemeColorStyle/Color+ThemeColorStyle.swift`
- Test: none — asset plumbing, verified by the build

**Interfaces:**
- Consumes: `ColorResource` and its `.color` helper in `RecipeTest/Extensions/Foundation/ColorResource/ColorResource+helper.swift`.
- Produces: `Color.ThemeColor.surfacesAccentPeach`, `.surfacesAccentMint`, `.surfacesAccentSky`, usable as `Color.themeColor(.surfacesAccentSky)` and `.themeColor(.surfacesAccentSky)`.

- [ ] **Step 1: Create the three colorsets**

Each carries the same value in both appearances — the app is light-only. Create `RecipeTest/Resources/Colors.xcassets/surfacesAccentPeach.colorset/Contents.json` with `#FADED3`:

```json
{
  "colors" : [
    {
      "color" : {
        "color-space" : "srgb",
        "components" : {
          "alpha" : "1.000",
          "blue" : "0xD3",
          "green" : "0xDE",
          "red" : "0xFA"
        }
      },
      "idiom" : "universal"
    },
    {
      "appearances" : [
        {
          "appearance" : "luminosity",
          "value" : "dark"
        }
      ],
      "color" : {
        "color-space" : "srgb",
        "components" : {
          "alpha" : "1.000",
          "blue" : "0xD3",
          "green" : "0xDE",
          "red" : "0xFA"
        }
      },
      "idiom" : "universal"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

`surfacesAccentMint.colorset/Contents.json` is the same file with `#DAFAD3` — `"red" : "0xDA"`, `"green" : "0xFA"`, `"blue" : "0xD3"` in both colour entries.

`surfacesAccentSky.colorset/Contents.json` is the same file with `#D3E2FA` — `"red" : "0xD3"`, `"green" : "0xE2"`, `"blue" : "0xFA"` in both colour entries.

- [ ] **Step 2: Add the tokens to `ThemeColorProtocol`**

Append a new group after the `// Semantics` block, before the closing brace:

```swift
  // Accents
  var surfacesAccentPeach: ColorResource { get }
  var surfacesAccentMint: ColorResource { get }
  var surfacesAccentSky: ColorResource { get }
```

- [ ] **Step 3: Add the tokens to `DefaultThemeColor`**

Append after the `// Semantics` block, before the closing brace:

```swift
  // Accents
  let surfacesAccentPeach: ColorResource = .surfacesAccentPeach
  let surfacesAccentMint: ColorResource = .surfacesAccentMint
  let surfacesAccentSky: ColorResource = .surfacesAccentSky
```

- [ ] **Step 4: Add the cases to `Color.ThemeColor`**

In `Color+ThemeColorStyle.swift`, append to the enum after the `// Semantics` cases:

```swift
    // Accents
    case surfacesAccentPeach
    case surfacesAccentMint
    case surfacesAccentSky
```

and append to the `switch` in `themeColor(_:)` after the `.semanticsErrorShade` case:

```swift
    // Accents
    case .surfacesAccentPeach:
      return theme.surfacesAccentPeach.color
    case .surfacesAccentMint:
      return theme.surfacesAccentMint.color
    case .surfacesAccentSky:
      return theme.surfacesAccentSky.color
```

- [ ] **Step 5: Build to verify the tokens resolve**

Run:

```bash
xcodebuild build -project RecipeTest.xcodeproj -scheme RecipeTest \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -20
```

Expected: BUILD SUCCEEDED. A failure naming `surfacesAccentPeach` as an unknown `ColorResource` member means the colorset directory name does not match the token name exactly — Xcode generates the symbol from the folder name.

- [ ] **Step 6: Commit**

```bash
git add RecipeTest/Resources/Colors.xcassets RecipeTest/Modules/Core/UI/Theme RecipeTest/Extensions/SwiftUI/ThemeColorStyle
git commit -m "[detail] Add the accent colour tokens"
```

---

### Task 2: Shared section-state helpers

`HomeViewModel` holds four private helpers that turn a value or an error into a `SectionState`. The detail view model needs two of them. Copying would fork the behaviour on the next fix, so they move onto `SectionState` itself — each is a pure transformation of a state value into another state value and reads nothing else a view model owns.

This task is a refactor with no behaviour change. Home's existing tests are the regression net: if any of them change, the move was not behaviour-preserving and the change is the bug.

**Files:**
- Modify: `RecipeTest/Modules/Shared/UI/Models/SectionState.swift`
- Modify: `RecipeTest/Modules/Home/UI/Scenes/HomeViewModel.swift`
- Test: `Tests/Modules/Shared/UI/Models/SectionStateTests.swift` (create)

**Interfaces:**
- Consumes: `Error.isCancellation` from `RecipeTest/Modules/Core/Clients/API/Extensions/`; `.Shared.sharedErrorSomethingWentWrong` from `Shared.xcstrings`.
- Produces: on `SectionState<Value>` — `var refreshing: SectionState`, `func recovering(from error: any Error) -> SectionState`, and `static func rows(_ value: Value) -> SectionState` where `Value: Collection`.

- [ ] **Step 1: Write the failing tests**

Create `Tests/Modules/Shared/UI/Models/SectionStateTests.swift`:

```swift
//
//  SectionStateTests.swift
//  Tests
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation
@testable import RecipeTest
import Testing

struct SectionStateTests {
  @Test
  func refreshing_onALoadedSection_keepsItsContent() {
    let state = SectionState<[String]>.loaded(["a"])

    let refreshed = state.refreshing

    #expect(refreshed == .loaded(["a"]))
  }

  @Test
  func refreshing_onAFailedSection_becomesLoading() {
    let state = SectionState<[String]>.failed("The request timed out.")

    let refreshed = state.refreshing

    #expect(refreshed == .loading)
  }

  @Test
  func rows_withNoRows_isEmptyRatherThanAnEmptyLoad() {
    let state = SectionState<[String]>.rows([])

    #expect(state == .empty)
  }

  @Test
  func rows_withRows_isLoaded() {
    let state = SectionState<[String]>.rows(["a"])

    #expect(state == .loaded(["a"]))
  }

  @Test
  func recovering_fromACancellation_keepsThePreviousState() {
    let previous = SectionState<[String]>.loaded(["a"])

    let recovered = previous.recovering(from: CancellationError())

    #expect(recovered == .loaded(["a"]))
  }

  @Test
  func recovering_fromACancelledURLError_keepsThePreviousState() {
    let previous = SectionState<[String]>.loaded(["a"])
    let error = URLError(.cancelled)

    let recovered = previous.recovering(from: error)

    #expect(recovered == .loaded(["a"]))
  }

  @Test
  func recovering_fromARealError_failsWithItsDescription() {
    let previous = SectionState<[String]>.loading
    let error = URLError(.notConnectedToInternet)

    let recovered = previous.recovering(from: error)

    #expect(recovered == .failed(error.localizedDescription))
  }

  @Test
  func recovering_fromAnErrorDescribedByTheGenericHeading_carriesNoDetail() {
    let previous = SectionState<[String]>.loading

    let recovered = previous.recovering(from: AppError.unknown)

    #expect(recovered == .failed(nil))
  }
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run:

```bash
xcodebuild test -project RecipeTest.xcodeproj -scheme RecipeTest \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:Tests/SectionStateTests 2>&1 | tail -40
```

Expected: compilation failure — `value of type 'SectionState<[String]>' has no member 'refreshing'`.

- [ ] **Step 3: Add the helpers to `SectionState`**

Append to `RecipeTest/Modules/Shared/UI/Models/SectionState.swift`, after the existing `// MARK: - Getters` extension:

```swift
// MARK: - Transitions

nonisolated extension SectionState {
  /// A refresh keeps its content; only a section with nothing to show becomes a spinner.
  var refreshing: SectionState {
    isLoaded ? self : .loading
  }

  /// Applied to the state as it was *before* the load began.
  ///
  /// SwiftUI cancels `.task` on disappear; that must not paint an error, and must not
  /// strand the section on the spinner `refreshing` just put there either.
  func recovering(from error: any Error) -> SectionState {
    guard !error.isCancellation else { return self }

    return .failed(Self.failureDetail(for: error))
  }
}

// MARK: - Helpers

private nonisolated extension SectionState {
  /// `AppError.unknown` describes itself with the generic heading, so passing it on as a
  /// detail would print the same sentence twice.
  static func failureDetail(for error: any Error) -> String? {
    let description = error.localizedDescription

    guard description != String(localized: .Shared.sharedErrorSomethingWentWrong) else {
      return nil
    }

    return description
  }
}

// MARK: - Collections

nonisolated extension SectionState where Value: Collection {
  /// Zero rows is `.empty`, never `.loaded([])`.
  static func rows(_ value: Value) -> SectionState {
    value.isEmpty ? .empty : .loaded(value)
  }
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run:

```bash
xcodebuild test -project RecipeTest.xcodeproj -scheme RecipeTest \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:Tests/SectionStateTests 2>&1 | tail -40
```

Expected: PASS, 8 tests.

- [ ] **Step 5: Point `HomeViewModel` at the shared helpers**

In `RecipeTest/Modules/Home/UI/Scenes/HomeViewModel.swift`, delete the whole `// MARK: - Helpers` private extension (the four functions `refreshing`, `state(for:)`, `state(for:keeping:)` and `failureDetail(for:)`) and delete the `genericFailureText` getter from the `// MARK: - Getters` extension. `latestRecipesPageSize` stays.

Then rewrite the two load methods' bodies to call the shared helpers. `loadLatestRecipes()` becomes:

```swift
  func loadLatestRecipes() async {
    latestRecipesGeneration += 1
    let generation = latestRecipesGeneration
    let previous = latestRecipes
    latestRecipes = latestRecipes.refreshing

    do {
      let page = try await recipeService.getRecipes(
        query: RecipeQuery(sort: .latest),
        page: Page(
          index: 1,
          size: latestRecipesPageSize
        )
      )

      guard generation == latestRecipesGeneration else { return }

      latestRecipes = .rows(page.recipes)
    } catch {
      guard generation == latestRecipesGeneration else { return }

      latestRecipes = previous.recovering(from: error)
    }
  }
```

`loadCategories()` becomes the same shape:

```swift
  func loadCategories() async {
    categoriesGeneration += 1
    let generation = categoriesGeneration
    let previous = categories
    categories = categories.refreshing

    do {
      let loaded = try await recipeService.getCategories()

      guard generation == categoriesGeneration else { return }

      categories = .rows(loaded)
    } catch {
      guard generation == categoriesGeneration else { return }

      categories = previous.recovering(from: error)
    }
  }
```

- [ ] **Step 6: Run the whole suite to verify Home is unchanged**

Run:

```bash
xcodebuild test -project RecipeTest.xcodeproj -scheme RecipeTest \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:Tests 2>&1 | tail -40
```

Expected: PASS, including every existing `HomeViewModelTests` case. If a Home test now fails, the move changed behaviour — fix the helper, do not edit the Home test.

- [ ] **Step 7: Commit**

```bash
git add RecipeTest/Modules/Shared/UI/Models/SectionState.swift RecipeTest/Modules/Home/UI/Scenes/HomeViewModel.swift Tests/Modules/Shared/UI/Models/SectionStateTests.swift
git commit -m "[detail] Move the section state transitions onto SectionState"
```

---

### Task 3: Strings, difficulty names, and the recipe fixture

Everything later tasks quote. Doing it first means no task has to invent a key and come back to add it.

**Files:**
- Create: `RecipeTest/Modules/RecipeDetail/UI/RecipeDetail.xcstrings`
- Create: `RecipeTest/Modules/RecipeDetail/UI/Extensions/RecipeDifficulty+DisplayName.swift`
- Create: `RecipeTest/Mocks/Modules/Recipe/Models/DummyRecipe.swift`
- Test: none — a catalog, a total mapping over three cases, and a fixture; all exercised by later tasks

**Interfaces:**
- Consumes: `RecipeDifficulty` from `Modules/Recipe/Models/Domain/`; `Recipe` and `RecipeIngredient` from the same folder.
- Produces: the `.RecipeDetail.*` localized symbols listed below; `RecipeDifficulty.displayName: LocalizedStringResource`; `Recipe.dummy(...)` and `RecipeIngredient.dummy(...)`.

- [ ] **Step 1: Create `RecipeDetail.xcstrings`**

Keys are sorted alphabetically, matching `Home.xcstrings`. Create `RecipeTest/Modules/RecipeDetail/UI/RecipeDetail.xcstrings`:

```json
{
  "sourceLanguage" : "en",
  "strings" : {
    "recipeDetail.back.accessibilityLabel" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Back" } }
      }
    },
    "recipeDetail.cookingTime.title" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Cooking time" } }
      }
    },
    "recipeDetail.detail.empty" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "This recipe has no details yet" } }
      }
    },
    "recipeDetail.difficulty.easy" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Easy" } }
      }
    },
    "recipeDetail.difficulty.hard" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Hard" } }
      }
    },
    "recipeDetail.difficulty.medium" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Medium" } }
      }
    },
    "recipeDetail.difficulty.title" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Difficulty" } }
      }
    },
    "recipeDetail.gallery.photoPosition" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Photo %1$lld of %2$lld" } }
      }
    },
    "recipeDetail.ingredient.gathered" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Gathered" } }
      }
    },
    "recipeDetail.ingredient.notGathered" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Not gathered" } }
      }
    },
    "recipeDetail.ingredients.title" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Ingredients" } }
      }
    },
    "recipeDetail.instructions.title" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Instructions" } }
      }
    },
    "recipeDetail.mainIngredients.title" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Main ingredients" } }
      }
    },
    "recipeDetail.metric.unavailable" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Not available" } }
      }
    },
    "recipeDetail.servings.title" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Servings" } }
      }
    },
    "recipeDetail.step.position" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Step %1$lld of %2$lld" } }
      }
    }
  },
  "version" : "1.0"
}
```

Xcode generates the symbol namespace from the file name, so these are reached as `.RecipeDetail.recipeDetailCookingTimeTitle` and so on — the same shape as `.Home.homeLatestRecipesTitle`. The two keys with format specifiers generate functions: `.RecipeDetail.recipeDetailGalleryPhotoPosition(_:_:)` and `.RecipeDetail.recipeDetailStepPosition(_:_:)`, each taking two `Int`s.

- [ ] **Step 2: Create `RecipeDifficulty+DisplayName.swift`**

```swift
//
//  RecipeDifficulty+DisplayName.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

nonisolated extension RecipeDifficulty {
  var displayName: LocalizedStringResource {
    switch self {
    case .easy:
      .RecipeDetail.recipeDetailDifficultyEasy

    case .medium:
      .RecipeDetail.recipeDetailDifficultyMedium

    case .hard:
      .RecipeDetail.recipeDetailDifficultyHard
    }
  }
}
```

- [ ] **Step 3: Create `DummyRecipe.swift`**

Mirrors `DummyRecipeSummary.swift` — app target, `#if DEBUG`, so previews and tests share one fixture.

```swift
//
//  DummyRecipe.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

#if DEBUG
  nonisolated extension Recipe {
    static func dummy(
      id: String = "rcp-001",
      title: String = "Spaghetti alla Carbonara",
      description: String = "Roman pasta bound with egg yolk and pecorino — never cream.",
      heroImageURL: URL? = URL(string: "https://example.com/carbonara.jpg"),
      category: String? = "Pasta",
      cuisine: String? = "italian",
      mealType: String? = "dinner",
      totalTimeMinutes: Int? = 25,
      servings: Int? = 4,
      difficulty: RecipeDifficulty? = .medium,
      isVegetarian: Bool = false,
      gallery: [URL] = [
        URL(string: "https://example.com/carbonara.jpg"),
        URL(string: "https://example.com/carbonara-2.jpg"),
        URL(string: "https://example.com/carbonara-3.jpg"),
      ].compactMap { $0 },
      ingredients: [RecipeIngredient] = RecipeIngredient.dummyList(),
      steps: [String] = [
        "Bring a large pan of well-salted water to the boil and drop in the spaghetti.",
        "Dice the bacon and fry it gently until the fat runs and the edges crisp.",
        "Beat the egg yolks with the grated pecorino and a great deal of black pepper.",
        "Drain the pasta, keeping a cup of its water, and tip it into the bacon pan.",
        "Off the heat, stir through the egg mixture, loosening with pasta water.",
      ]
    ) -> Recipe {
      Recipe(
        id: id,
        title: title,
        description: description,
        heroImageURL: heroImageURL,
        category: category,
        cuisine: cuisine,
        mealType: mealType,
        totalTimeMinutes: totalTimeMinutes,
        servings: servings,
        difficulty: difficulty,
        isVegetarian: isVegetarian,
        gallery: gallery,
        ingredients: ingredients,
        steps: steps
      )
    }
  }

  nonisolated extension RecipeIngredient {
    static func dummy(
      id: String = "rcp-001-0",
      quantityText: String = "320 g",
      name: String = "Spaghetti",
      imageURL: URL? = nil,
      isMain: Bool = true
    ) -> RecipeIngredient {
      RecipeIngredient(
        id: id,
        quantityText: quantityText,
        name: name,
        imageURL: imageURL,
        isMain: isMain
      )
    }

    /// Four main ingredients and two supporting ones, so a strip and a checklist built
    /// from the same fixture differ the way they do against real data.
    static func dummyList() -> [RecipeIngredient] {
      [
        .dummy(
          id: "rcp-001-0",
          quantityText: "320 g",
          name: "Spaghetti"
        ),
        .dummy(
          id: "rcp-001-1",
          quantityText: "6",
          name: "Egg Yolks"
        ),
        .dummy(
          id: "rcp-001-2",
          quantityText: "150 g",
          name: "Bacon"
        ),
        .dummy(
          id: "rcp-001-3",
          quantityText: "50 g",
          name: "Pecorino"
        ),
        .dummy(
          id: "rcp-001-4",
          quantityText: "to taste",
          name: "Salt",
          isMain: false
        ),
        .dummy(
          id: "rcp-001-5",
          quantityText: "to taste",
          name: "Black Pepper",
          isMain: false
        ),
      ]
    }
  }
#endif
```

- [ ] **Step 4: Build to verify the generated symbols resolve**

Run:

```bash
xcodebuild build -project RecipeTest.xcodeproj -scheme RecipeTest \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -20
```

Expected: BUILD SUCCEEDED. An error on `.RecipeDetail.recipeDetailDifficultyEasy` means the catalog's file name or a key's spelling does not match — Xcode derives both the namespace and the symbol from them.

- [ ] **Step 5: Commit**

```bash
git add RecipeTest/Modules/RecipeDetail RecipeTest/Mocks/Modules/Recipe/Models/DummyRecipe.swift
git commit -m "[detail] Add the detail strings, difficulty names and fixture"
```

---

### Task 4: The view model

Where the two sources of truth are reconciled and every Review Focus item but the layout ones is settled.

**Files:**
- Create: `RecipeTest/Modules/RecipeDetail/UI/Scenes/RecipeDetailViewModelProtocol.swift`
- Create: `RecipeTest/Modules/RecipeDetail/UI/Scenes/RecipeDetailViewModel.swift`
- Create: `RecipeTest/Mocks/Modules/RecipeDetail/UI/Scenes/RecipeDetail/MockRecipeDetailViewModel.swift`
- Test: `Tests/Modules/RecipeDetail/UI/Scenes/RecipeDetailViewModelTests.swift` (create)

**Interfaces:**
- Consumes: `RecipeServiceProtocol.getRecipe(id:)`; `SectionState.refreshing` / `.recovering(from:)` from Task 2; `Recipe.dummy(...)` from Task 3; `MockRecipeService` and `MockAPICall` from `Tests/Mocks/`.
- Produces: `RecipeDetailViewModelProtocol` with `summary`, `detail`, `checkedIngredientIDs`, `title`, `totalTimeMinutes`, `servings`, `difficulty`, `galleryURLs`, `loadDetail()` and `toggleIngredient(id:)`; `RecipeDetailViewModel(summary:recipeService:)`; `MockRecipeDetailViewModel.loaded()` / `.loading()` / `.failed()` / `.noPhotographs()` / `.partiallyChecked()` / `.missingMetrics()`.

- [ ] **Step 1: Write the failing tests**

Create `Tests/Modules/RecipeDetail/UI/Scenes/RecipeDetailViewModelTests.swift`:

```swift
//
//  RecipeDetailViewModelTests.swift
//  Tests
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation
@testable import RecipeTest
import Testing

@MainActor
struct RecipeDetailViewModelTests {
  @Test
  func loadDetail_succeeds_fetchesTheSummarysRecipe() async {
    let service = MockRecipeService(recipe: .dummy(id: "rcp-007"))
    let sut = RecipeDetailViewModel(
      summary: .dummy(id: "rcp-007"),
      recipeService: service
    )

    await sut.loadDetail()

    #expect(service.recipe.lastRequest == "rcp-007")
    #expect(sut.detail.value?.id == "rcp-007")
  }

  @Test
  func headerGetters_beforeTheDetailLands_readTheSummary() {
    let sut = RecipeDetailViewModel(
      summary: .dummy(
        title: "Pad Thai",
        totalTimeMinutes: 20,
        servings: 2,
        difficulty: .easy
      ),
      recipeService: MockRecipeService()
    )

    #expect(sut.title == "Pad Thai")
    #expect(sut.totalTimeMinutes == 20)
    #expect(sut.servings == 2)
    #expect(sut.difficulty == .easy)
  }

  @Test
  func headerGetters_afterTheDetailLands_readTheRecipe() async {
    let service = MockRecipeService(recipe: .dummy(
      title: "Pad Thai, revised",
      totalTimeMinutes: 35,
      servings: 6,
      difficulty: .hard
    ))
    let sut = RecipeDetailViewModel(
      summary: .dummy(
        title: "Pad Thai",
        totalTimeMinutes: 20,
        servings: 2,
        difficulty: .easy
      ),
      recipeService: service
    )

    await sut.loadDetail()

    #expect(sut.title == "Pad Thai, revised")
    #expect(sut.totalTimeMinutes == 35)
    #expect(sut.servings == 6)
    #expect(sut.difficulty == .hard)
  }

  @Test
  func loadDetail_fails_leavesTheHeaderOnTheSummary() async {
    let service = MockRecipeService()
    service.recipe.fails(with: AppError.unknown)
    let sut = RecipeDetailViewModel(
      summary: .dummy(title: "Pad Thai"),
      recipeService: service
    )

    await sut.loadDetail()

    #expect(sut.detail.isLoaded == false)
    #expect(sut.title == "Pad Thai")
  }

  @Test
  func loadDetail_cancelled_keepsThePreviousState() async {
    let service = MockRecipeService()
    let sut = RecipeDetailViewModel(
      summary: .dummy(),
      recipeService: service
    )
    await sut.loadDetail()
    let loaded = sut.detail
    service.recipe.fails(with: CancellationError())

    await sut.loadDetail()

    #expect(sut.detail == loaded)
  }

  @Test
  func loadDetail_retryingAfterAFailure_clearsTheErrorBeforeTheResponse() async {
    let service = MockRecipeService()
    service.recipe.fails(with: AppError.unknown)
    let sut = RecipeDetailViewModel(
      summary: .dummy(),
      recipeService: service
    )
    await sut.loadDetail()
    service.recipe.responds { _ in
      try await Task.sleep(for: .milliseconds(80))

      return .dummy()
    }

    async let retry: Void = sut.loadDetail()
    try? await Task.sleep(for: .milliseconds(20))
    let midFlight = sut.detail
    await retry

    #expect(midFlight == .loading)
    #expect(sut.detail.isLoaded)
  }

  @Test
  func loadDetail_supersededByASecondLoad_keepsOnlyTheSecondResult() async {
    let counter = CallCounter()
    let service = MockRecipeService()
    service.recipe.responds { _ in
      guard counter.next() > 1 else {
        try await Task.sleep(for: .milliseconds(120))

        return .dummy(id: "stale")
      }

      return .dummy(id: "fresh")
    }
    let sut = RecipeDetailViewModel(
      summary: .dummy(),
      recipeService: service
    )

    async let first: Void = sut.loadDetail()
    try? await Task.sleep(for: .milliseconds(20))
    async let second: Void = sut.loadDetail()
    _ = await (first, second)

    #expect(sut.detail.value?.id == "fresh")
  }

  @Test
  func galleryURLs_beforeTheDetailLands_isTheSummarysPhotograph() {
    let hero = URL(string: "https://example.com/hero.jpg")
    let sut = RecipeDetailViewModel(
      summary: .dummy(heroImageURL: hero),
      recipeService: MockRecipeService()
    )

    #expect(sut.galleryURLs == [hero].compactMap { $0 })
  }

  @Test
  func galleryURLs_afterTheDetailLands_isTheRecipesGallery() async {
    let gallery = [
      URL(string: "https://example.com/1.jpg"),
      URL(string: "https://example.com/2.jpg"),
    ].compactMap { $0 }
    let service = MockRecipeService(recipe: .dummy(gallery: gallery))
    let sut = RecipeDetailViewModel(
      summary: .dummy(),
      recipeService: service
    )

    await sut.loadDetail()

    #expect(sut.galleryURLs == gallery)
  }

  @Test
  func galleryURLs_withNoPhotographsAnywhere_isEmpty() async {
    let service = MockRecipeService(recipe: .dummy(
      heroImageURL: nil,
      gallery: []
    ))
    let sut = RecipeDetailViewModel(
      summary: .dummy(heroImageURL: nil),
      recipeService: service
    )

    await sut.loadDetail()

    #expect(sut.galleryURLs.isEmpty)
  }

  @Test
  func toggleIngredient_addsThenRemovesTheID() {
    let sut = RecipeDetailViewModel(
      summary: .dummy(),
      recipeService: MockRecipeService()
    )

    sut.toggleIngredient(id: "rcp-001-0")
    let afterFirst = sut.checkedIngredientIDs
    sut.toggleIngredient(id: "rcp-001-0")

    #expect(afterFirst == ["rcp-001-0"])
    #expect(sut.checkedIngredientIDs.isEmpty)
  }

  @Test
  func toggleIngredient_leavesTheOtherIngredientsUntouched() {
    let sut = RecipeDetailViewModel(
      summary: .dummy(),
      recipeService: MockRecipeService()
    )

    sut.toggleIngredient(id: "rcp-001-0")
    sut.toggleIngredient(id: "rcp-001-1")
    sut.toggleIngredient(id: "rcp-001-0")

    #expect(sut.checkedIngredientIDs == ["rcp-001-1"])
  }

  @Test
  func checkedIngredients_surviveAReFetch() async {
    let service = MockRecipeService(recipe: .dummy())
    let sut = RecipeDetailViewModel(
      summary: .dummy(),
      recipeService: service
    )
    await sut.loadDetail()
    sut.toggleIngredient(id: "rcp-001-2")

    await sut.loadDetail()

    #expect(sut.checkedIngredientIDs == ["rcp-001-2"])
    #expect(sut.detail.value?.ingredients.contains { $0.id == "rcp-001-2" } == true)
  }
}

// MARK: - Support

/// `responds` takes a `@Sendable` closure, so a plain captured `var` will not compile.
private final class CallCounter: @unchecked Sendable {
  private let lock = NSLock()
  private var value = 0

  func next() -> Int {
    lock.withLock {
      value += 1

      return value
    }
  }
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run:

```bash
xcodebuild test -project RecipeTest.xcodeproj -scheme RecipeTest \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:Tests/RecipeDetailViewModelTests 2>&1 | tail -40
```

Expected: compilation failure — `cannot find 'RecipeDetailViewModel' in scope`.

- [ ] **Step 3: Create `RecipeDetailViewModelProtocol.swift`**

```swift
//
//  RecipeDetailViewModelProtocol.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

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

- [ ] **Step 4: Create `RecipeDetailViewModel.swift`**

```swift
//
//  RecipeDetailViewModel.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

@Observable
final class RecipeDetailViewModel: RecipeDetailViewModelProtocol {
  let summary: RecipeSummary

  private(set) var detail: SectionState<Recipe> = .loading
  private(set) var checkedIngredientIDs: Set<String> = []

  private var detailGeneration = 0

  private let recipeService: RecipeServiceProtocol

  init(
    summary: RecipeSummary,
    recipeService: RecipeServiceProtocol = AppContainer.shared.recipeService
  ) {
    self.summary = summary
    self.recipeService = recipeService
  }
}

// MARK: - Getters

extension RecipeDetailViewModel {
  /// The loaded recipe is the fresher read of the same record; the summary stands in
  /// until it arrives, which is what lets the header paint on the first frame.
  var title: String {
    detail.value?.title ?? summary.title
  }

  var totalTimeMinutes: Int? {
    detail.value?.totalTimeMinutes ?? summary.totalTimeMinutes
  }

  var servings: Int? {
    detail.value?.servings ?? summary.servings
  }

  var difficulty: RecipeDifficulty? {
    detail.value?.difficulty ?? summary.difficulty
  }

  /// The summary carries one photograph, the recipe the whole set. `gallery[0]` is the
  /// hero in every record the API serves, so the swap adds photographs rather than
  /// replacing the one already on screen.
  var galleryURLs: [URL] {
    if let gallery = detail.value?.gallery, !gallery.isEmpty {
      return gallery
    }

    return [summary.heroImageURL].compactMap { $0 }
  }
}

// MARK: - Inputs

extension RecipeDetailViewModel {
  func loadDetail() async {
    detailGeneration += 1
    let generation = detailGeneration
    let previous = detail
    detail = detail.refreshing

    do {
      let recipe = try await recipeService.getRecipe(id: summary.id)

      guard generation == detailGeneration else { return }

      detail = .loaded(recipe)
    } catch {
      guard generation == detailGeneration else { return }

      detail = previous.recovering(from: error)
    }
  }

  func toggleIngredient(id: String) {
    if checkedIngredientIDs.contains(id) {
      checkedIngredientIDs.remove(id)
    } else {
      checkedIngredientIDs.insert(id)
    }
  }
}
```

- [ ] **Step 5: Run the tests to verify they pass**

Run:

```bash
xcodebuild test -project RecipeTest.xcodeproj -scheme RecipeTest \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:Tests/RecipeDetailViewModelTests 2>&1 | tail -40
```

Expected: PASS, 13 tests.

- [ ] **Step 6: Create `MockRecipeDetailViewModel.swift`**

The preview double every component and the scene use. App target, `#if DEBUG`.

```swift
//
//  MockRecipeDetailViewModel.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

#if DEBUG
  @Observable
  final class MockRecipeDetailViewModel: RecipeDetailViewModelProtocol {
    let summary: RecipeSummary

    var detail: SectionState<Recipe>
    var checkedIngredientIDs: Set<String>

    init(
      summary: RecipeSummary = .dummy(),
      detail: SectionState<Recipe> = .loading,
      checkedIngredientIDs: Set<String> = []
    ) {
      self.summary = summary
      self.detail = detail
      self.checkedIngredientIDs = checkedIngredientIDs
    }

    func loadDetail() async {}

    func toggleIngredient(id: String) {
      if checkedIngredientIDs.contains(id) {
        checkedIngredientIDs.remove(id)
      } else {
        checkedIngredientIDs.insert(id)
      }
    }
  }

  // MARK: - Getters

  extension MockRecipeDetailViewModel {
    var title: String {
      detail.value?.title ?? summary.title
    }

    var totalTimeMinutes: Int? {
      detail.value?.totalTimeMinutes ?? summary.totalTimeMinutes
    }

    var servings: Int? {
      detail.value?.servings ?? summary.servings
    }

    var difficulty: RecipeDifficulty? {
      detail.value?.difficulty ?? summary.difficulty
    }

    var galleryURLs: [URL] {
      if let gallery = detail.value?.gallery, !gallery.isEmpty {
        return gallery
      }

      return [summary.heroImageURL].compactMap { $0 }
    }
  }

  // MARK: - Scenarios

  extension MockRecipeDetailViewModel {
    static func loaded() -> MockRecipeDetailViewModel {
      MockRecipeDetailViewModel(detail: .loaded(.dummy()))
    }

    static func loading() -> MockRecipeDetailViewModel {
      MockRecipeDetailViewModel(detail: .loading)
    }

    static func failed() -> MockRecipeDetailViewModel {
      MockRecipeDetailViewModel(detail: .failed("The Internet connection appears to be offline."))
    }

    /// No photograph on the summary and none on the recipe — the case a card with a nil
    /// `heroImageURL` leads to.
    static func noPhotographs() -> MockRecipeDetailViewModel {
      MockRecipeDetailViewModel(
        summary: .dummy(heroImageURL: nil),
        detail: .loaded(.dummy(
          heroImageURL: nil,
          gallery: []
        ))
      )
    }

    static func partiallyChecked() -> MockRecipeDetailViewModel {
      MockRecipeDetailViewModel(
        detail: .loaded(.dummy()),
        checkedIngredientIDs: ["rcp-001-0", "rcp-001-3"]
      )
    }

    /// Every optional metric absent, so the em dash and its VoiceOver copy are visible.
    static func missingMetrics() -> MockRecipeDetailViewModel {
      MockRecipeDetailViewModel(
        summary: .dummy(
          totalTimeMinutes: nil,
          servings: nil,
          difficulty: nil
        ),
        detail: .loaded(.dummy(
          totalTimeMinutes: nil,
          servings: nil,
          difficulty: nil
        ))
      )
    }
  }
#endif
```

- [ ] **Step 7: Run the whole suite**

Run:

```bash
xcodebuild test -project RecipeTest.xcodeproj -scheme RecipeTest \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:Tests 2>&1 | tail -40
```

Expected: PASS, everything green.

- [ ] **Step 8: Commit**

```bash
git add RecipeTest/Modules/RecipeDetail/UI/Scenes RecipeTest/Mocks/Modules/RecipeDetail Tests/Modules/RecipeDetail
git commit -m "[detail] Add the recipe detail view model"
```

---

### Task 5: Gallery and top bar

The two components that sit above the sheet. Both are pure views driven by values; neither knows the view model.

**Files:**
- Create: `RecipeTest/Modules/RecipeDetail/UI/Components/RecipeGallery.swift`
- Create: `RecipeTest/Modules/RecipeDetail/UI/Components/RecipeGalleryDots.swift`
- Create: `RecipeTest/Modules/RecipeDetail/UI/Components/RecipeDetailTopBar.swift`
- Test: none — views, covered by previews

**Interfaces:**
- Consumes: `CachedAsyncImage`; `.cardShadow()`; `VoidResult`; `.RecipeDetail.recipeDetailGalleryPhotoPosition(_:_:)` and `.recipeDetailBackAccessibilityLabel`.
- Produces: `RecipeGallery(urls:accessibilityTitle:)` with `static var baseHeight: CGFloat` (380); `RecipeGalleryDots(count:activeIndex:)`; `RecipeDetailTopBar(title:isTitleOffscreen:onBackTap:)`.

- [ ] **Step 1: Create `RecipeGalleryDots.swift`**

```swift
//
//  RecipeGalleryDots.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

struct RecipeGalleryDots: View {
  let count: Int
  let activeIndex: Int

  var body: some View {
    HStack(spacing: spacing) {
      ForEach(0 ..< count, id: \.self) { index in
        Capsule()
          .fill(Color.themeColor(.textWhite).opacity(index == activeIndex ? 1 : inactiveOpacity))
          .frame(
            width: index == activeIndex ? activeWidth : size,
            height: size
          )
      }
    }
    .animation(
      .snappy(duration: 0.2),
      value: activeIndex
    )
    .accessibilityHidden(true)
  }
}

// MARK: - Getters

private extension RecipeGalleryDots {
  var size: CGFloat {
    8
  }

  var activeWidth: CGFloat {
    24
  }

  var spacing: CGFloat {
    6
  }

  var inactiveOpacity: CGFloat {
    0.55
  }
}

#if DEBUG
  #Preview {
    RecipeGalleryDots(
      count: 3,
      activeIndex: 1
    )
    .padding(20)
    .background(Color.themeColor(.textPrimary))
  }
#endif
```

- [ ] **Step 2: Create `RecipeGallery.swift`**

```swift
//
//  RecipeGallery.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

/// Pages one photograph at a time. `urls` is allowed to be empty: a recipe with no
/// photograph anywhere shows the placeholder fill at full height rather than collapsing
/// and pulling the sheet up over the top bar.
struct RecipeGallery: View {
  let urls: [URL]
  let accessibilityTitle: String

  @ScaledMetric(relativeTo: .body) private var height: CGFloat = RecipeGallery.baseHeight

  @State private var scrolledIndex: Int?

  var body: some View {
    content
      .frame(height: height)
      .overlay(alignment: .bottom) { dots }
      .accessibilityElement(children: .ignore)
      .accessibilityLabel(Text(accessibilityTitle))
      .accessibilityValue(Text(.RecipeDetail.recipeDetailGalleryPhotoPosition(
        activeIndex + 1,
        max(urls.count, 1)
      )))
  }
}

// MARK: - Getters

extension RecipeGallery {
  static var baseHeight: CGFloat {
    380
  }
}

private extension RecipeGallery {
  var activeIndex: Int {
    scrolledIndex ?? 0
  }

  var dotsBottomInset: CGFloat {
    48
  }
}

// MARK: - Subviews

private extension RecipeGallery {
  @ViewBuilder
  var content: some View {
    if urls.isEmpty {
      Color.themeColor(.surfacesBackground3)
    } else {
      photographs
    }
  }

  var photographs: some View {
    ScrollView(.horizontal) {
      LazyHStack(spacing: 0) {
        ForEach(Array(urls.enumerated()), id: \.offset) { index, url in
          CachedAsyncImage(url: url) {
            Color.themeColor(.surfacesBackground3)
          }
          .aspectRatio(contentMode: .fill)
          .containerRelativeFrame(.horizontal)
          .frame(height: height)
          .clipped()
          .id(index)
        }
      }
      .scrollTargetLayout()
    }
    .scrollIndicators(.hidden)
    .scrollTargetBehavior(.paging)
    .scrollPosition(id: $scrolledIndex)
  }

  @ViewBuilder
  var dots: some View {
    if urls.count > 1 {
      RecipeGalleryDots(
        count: urls.count,
        activeIndex: activeIndex
      )
      .padding(
        .bottom,
        dotsBottomInset
      )
    }
  }
}

#if DEBUG
  #Preview("Three photographs") {
    RecipeGallery(
      urls: Recipe.dummy().gallery,
      accessibilityTitle: "Spaghetti alla Carbonara"
    )
  }

  #Preview("No photographs") {
    RecipeGallery(
      urls: [],
      accessibilityTitle: "Spaghetti alla Carbonara"
    )
  }
#endif
```

- [ ] **Step 3: Create `RecipeDetailTopBar.swift`**

```swift
//
//  RecipeDetailTopBar.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

/// The prototype draws a floating back button and a separate sticky title bar. They never
/// usefully coexist, so this is one control: the button is always present, and the bar's
/// background, border and title fade in together once the recipe's name scrolls away.
struct RecipeDetailTopBar: View {
  let title: String
  let isTitleOffscreen: Bool
  let onBackTap: VoidResult

  @ScaledMetric(relativeTo: .body) private var buttonSize: CGFloat = RecipeDetailTopBar.baseButtonSize

  var body: some View {
    HStack(spacing: spacing) {
      backButton

      if isTitleOffscreen {
        Text(title)
          .themeTextStyle(.title2)
          .themeColor(.textPrimary)
          .lineLimit(1)
          .truncationMode(.tail)
      }

      Spacer(minLength: 0)
    }
    .padding(
      .horizontal,
      horizontalPadding
    )
    .padding(
      .vertical,
      verticalPadding
    )
    .frame(
      maxWidth: .infinity,
      alignment: .leading
    )
    .background(background)
    .animation(
      .easeOut(duration: 0.25),
      value: isTitleOffscreen
    )
  }
}

// MARK: - Getters

extension RecipeDetailTopBar {
  static var baseButtonSize: CGFloat {
    56
  }
}

private extension RecipeDetailTopBar {
  var spacing: CGFloat {
    12
  }

  var horizontalPadding: CGFloat {
    20
  }

  var verticalPadding: CGFloat {
    10
  }
}

// MARK: - Subviews

private extension RecipeDetailTopBar {
  var backButton: some View {
    Button(action: onBackTap) {
      Image(systemName: "chevron.left")
        .themeTextStyle(.bodyBold)
        .foregroundStyle(.themeColor(.iconsDefault))
        .frame(
          width: buttonSize,
          height: buttonSize
        )
        .background(
          Color.themeColor(.surfacesBackground2),
          in: .circle
        )
    }
    .buttonStyle(.plain)
    .cardShadow()
    .accessibilityLabel(Text(.RecipeDetail.recipeDetailBackAccessibilityLabel))
  }

  var background: some View {
    Color.themeColor(.surfacesBackground2)
      .opacity(isTitleOffscreen ? 1 : 0)
      .overlay(alignment: .bottom) {
        Rectangle()
          .fill(.themeColor(.bordersDefault))
          .frame(height: isTitleOffscreen ? 1 : 0)
      }
      .ignoresSafeArea(edges: .top)
  }
}

#if DEBUG
  #Preview("Over a photograph") {
    RecipeDetailTopBar(
      title: "Spaghetti alla Carbonara",
      isTitleOffscreen: false,
      onBackTap: {}
    )
    .frame(
      maxWidth: .infinity,
      maxHeight: .infinity,
      alignment: .top
    )
    .background(Color.themeColor(.surfacesBackground3))
  }

  #Preview("Title scrolled away") {
    RecipeDetailTopBar(
      title: "Slow-Braised Beef Short Rib with Gremolata and Soft Polenta",
      isTitleOffscreen: true,
      onBackTap: {}
    )
    .frame(
      maxWidth: .infinity,
      maxHeight: .infinity,
      alignment: .top
    )
    .background(Color.themeColor(.surfacesBackground))
  }
#endif
```

- [ ] **Step 4: Build and check both gallery previews**

Run:

```bash
xcodebuild build -project RecipeTest.xcodeproj -scheme RecipeTest \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -20
```

Expected: BUILD SUCCEEDED. Then open `RecipeGallery.swift` in Xcode and confirm in the canvas that the "No photographs" preview still draws a full-height grey block — Review Focus item 3.

- [ ] **Step 5: Commit**

```bash
git add RecipeTest/Modules/RecipeDetail/UI/Components
git commit -m "[detail] Add the gallery and the top bar"
```

---

### Task 6: Overview and metric cards

The header content. This task owns Review Focus item 4 — the nil metric.

**Files:**
- Create: `RecipeTest/Modules/RecipeDetail/UI/Components/RecipeOverviewSection.swift`
- Create: `RecipeTest/Modules/RecipeDetail/UI/Components/RecipeMetricCard.swift`
- Create: `RecipeTest/Modules/RecipeDetail/UI/Components/RecipeMetricRow.swift`
- Create: `RecipeTest/Modules/RecipeDetail/UI/Components/RecipeDetailSectionHeader.swift`
- Test: none — views; the formatting getters are exercised through the previews listed below

**Interfaces:**
- Consumes: `RecipeDifficulty.displayName` from Task 3; `Color.ThemeColor.surfacesAccentPeach` / `.surfacesAccentMint` / `.surfacesAccentSky` from Task 1.
- Produces: `RecipeOverviewSection(title:description:)`; `RecipeMetricCard(title:systemImage:value:background:)`; `RecipeMetricRow(totalTimeMinutes:servings:difficulty:)`; `RecipeDetailSectionHeader(title:)`.

- [ ] **Step 1: Create `RecipeDetailSectionHeader.swift`**

```swift
//
//  RecipeDetailSectionHeader.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

struct RecipeDetailSectionHeader: View {
  let title: LocalizedStringResource

  var body: some View {
    Text(title)
      .themeTextStyle(.title2)
      .themeColor(.textPrimary)
      .frame(
        maxWidth: .infinity,
        alignment: .leading
      )
      .padding(
        .horizontal,
        horizontalPadding
      )
      .padding(
        .top,
        topPadding
      )
      .padding(
        .bottom,
        bottomPadding
      )
      .accessibilityAddTraits(.isHeader)
  }
}

// MARK: - Getters

private extension RecipeDetailSectionHeader {
  var horizontalPadding: CGFloat {
    20
  }

  var topPadding: CGFloat {
    28
  }

  var bottomPadding: CGFloat {
    14
  }
}

#if DEBUG
  #Preview {
    VStack(spacing: 0) {
      RecipeDetailSectionHeader(title: .RecipeDetail.recipeDetailMainIngredientsTitle)
      RecipeDetailSectionHeader(title: .RecipeDetail.recipeDetailIngredientsTitle)
      RecipeDetailSectionHeader(title: .RecipeDetail.recipeDetailInstructionsTitle)
    }
    .frame(
      maxWidth: .infinity,
      maxHeight: .infinity
    )
    .background(Color.themeColor(.surfacesBackground2))
  }
#endif
```

- [ ] **Step 2: Create `RecipeOverviewSection.swift`**

```swift
//
//  RecipeOverviewSection.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

struct RecipeOverviewSection: View {
  let title: String
  let description: String

  var body: some View {
    VStack(
      alignment: .leading,
      spacing: spacing
    ) {
      Text(title)
        .themeTextStyle(.title1)
        .themeColor(.textPrimary)
        .accessibilityAddTraits(.isHeader)

      if !description.isEmpty {
        Text(description)
          .themeTextStyle(.bodyRegular)
          .themeColor(.textSecondary)
      }
    }
    .frame(
      maxWidth: .infinity,
      alignment: .leading
    )
    .padding(
      .horizontal,
      horizontalPadding
    )
    .padding(
      .top,
      topPadding
    )
  }
}

// MARK: - Getters

private extension RecipeOverviewSection {
  var spacing: CGFloat {
    10
  }

  var horizontalPadding: CGFloat {
    20
  }

  var topPadding: CGFloat {
    20
  }
}

#if DEBUG
  #Preview("With a description") {
    RecipeOverviewSection(
      title: "Spaghetti alla Carbonara",
      description: "Roman pasta bound with egg yolk and pecorino — never cream."
    )
    .frame(
      maxWidth: .infinity,
      maxHeight: .infinity,
      alignment: .top
    )
    .background(Color.themeColor(.surfacesBackground2))
  }

  #Preview("Title only") {
    RecipeOverviewSection(
      title: "Spaghetti alla Carbonara",
      description: ""
    )
    .frame(
      maxWidth: .infinity,
      maxHeight: .infinity,
      alignment: .top
    )
    .background(Color.themeColor(.surfacesBackground2))
  }
#endif
```

- [ ] **Step 3: Create `RecipeMetricCard.swift`**

```swift
//
//  RecipeMetricCard.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

/// `value` is optional because all three metrics are optional on the domain model. A nil
/// shows an em dash and announces the unavailable copy, rather than an empty card.
struct RecipeMetricCard: View {
  let title: LocalizedStringResource
  let systemImage: String
  let value: String?
  let background: Color.ThemeColor

  @ScaledMetric(relativeTo: .body) private var minHeight: CGFloat = RecipeMetricCard.baseMinHeight

  var body: some View {
    VStack(
      alignment: .leading,
      spacing: spacing
    ) {
      header

      Spacer(minLength: 0)

      Text(value ?? unavailableSymbol)
        .themeTextStyle(.title3)
        .themeColor(.textPrimary)
    }
    .padding(
      .horizontal,
      horizontalPadding
    )
    .padding(
      .vertical,
      verticalPadding
    )
    .frame(
      maxWidth: .infinity,
      minHeight: minHeight,
      alignment: .leading
    )
    .background(
      Color.themeColor(background),
      in: .rect(cornerRadius: cornerRadius)
    )
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(Text(title))
    .accessibilityValue(accessibilityValue)
  }
}

// MARK: - Getters

extension RecipeMetricCard {
  static var baseMinHeight: CGFloat {
    112
  }
}

private extension RecipeMetricCard {
  var spacing: CGFloat {
    12
  }

  var horizontalPadding: CGFloat {
    14
  }

  var verticalPadding: CGFloat {
    14
  }

  var cornerRadius: CGFloat {
    24
  }

  var unavailableSymbol: String {
    "—"
  }

  var accessibilityValue: Text {
    guard let value else {
      return Text(.RecipeDetail.recipeDetailMetricUnavailable)
    }

    return Text(value)
  }
}

// MARK: - Subviews

private extension RecipeMetricCard {
  var header: some View {
    HStack(
      alignment: .top,
      spacing: spacing
    ) {
      Text(title)
        .themeTextStyle(.subheadlineRegular)
        .themeColor(.textPrimary)
        .multilineTextAlignment(.leading)

      Spacer(minLength: 0)

      Image(systemName: systemImage)
        .foregroundStyle(.themeColor(.iconsDefault))
    }
  }
}

#if DEBUG
  #Preview("With a value") {
    RecipeMetricCard(
      title: .RecipeDetail.recipeDetailCookingTimeTitle,
      systemImage: "clock",
      value: "25 min",
      background: .surfacesAccentPeach
    )
    .padding(20)
    .background(Color.themeColor(.surfacesBackground2))
  }

  #Preview("Value unavailable") {
    RecipeMetricCard(
      title: .RecipeDetail.recipeDetailDifficultyTitle,
      systemImage: "chart.bar",
      value: nil,
      background: .surfacesAccentSky
    )
    .padding(20)
    .background(Color.themeColor(.surfacesBackground2))
  }
#endif
```

- [ ] **Step 4: Create `RecipeMetricRow.swift`**

```swift
//
//  RecipeMetricRow.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

/// Three columns at default text sizes, one column at accessibility sizes: three scaled
/// labels and their icons do not fit a card a third of the screen wide.
struct RecipeMetricRow: View {
  let totalTimeMinutes: Int?
  let servings: Int?
  let difficulty: RecipeDifficulty?

  @Environment(\.dynamicTypeSize) private var dynamicTypeSize

  var body: some View {
    layout {
      RecipeMetricCard(
        title: .RecipeDetail.recipeDetailCookingTimeTitle,
        systemImage: "clock",
        value: timeText,
        background: .surfacesAccentPeach
      )

      RecipeMetricCard(
        title: .RecipeDetail.recipeDetailServingsTitle,
        systemImage: "person.2",
        value: servingsText,
        background: .surfacesAccentMint
      )

      RecipeMetricCard(
        title: .RecipeDetail.recipeDetailDifficultyTitle,
        systemImage: "chart.bar",
        value: difficultyText,
        background: .surfacesAccentSky
      )
    }
    .padding(
      .horizontal,
      horizontalPadding
    )
    .padding(
      .top,
      topPadding
    )
  }
}

// MARK: - Getters

private extension RecipeMetricRow {
  var layout: AnyLayout {
    dynamicTypeSize.isAccessibilitySize
      ? AnyLayout(VStackLayout(spacing: spacing))
      : AnyLayout(HStackLayout(spacing: spacing))
  }

  var spacing: CGFloat {
    10
  }

  var horizontalPadding: CGFloat {
    20
  }

  var topPadding: CGFloat {
    20
  }

  /// Reproduces the prototype's `fmtTime` — "25 min", "1 hr 25 min" — and localizes the
  /// units rather than assembling them by hand.
  var timeText: String? {
    guard let totalTimeMinutes else { return nil }

    return Duration
      .seconds(totalTimeMinutes * 60)
      .formatted(.units(
        allowed: [.hours, .minutes],
        width: .abbreviated
      ))
  }

  var servingsText: String? {
    servings.map { String($0) }
  }

  var difficultyText: String? {
    difficulty.map { String(localized: $0.displayName) }
  }
}

#if DEBUG
  #Preview("All three present") {
    RecipeMetricRow(
      totalTimeMinutes: 25,
      servings: 4,
      difficulty: .medium
    )
    .frame(
      maxWidth: .infinity,
      maxHeight: .infinity,
      alignment: .top
    )
    .background(Color.themeColor(.surfacesBackground2))
  }

  #Preview("Over an hour") {
    RecipeMetricRow(
      totalTimeMinutes: 305,
      servings: 8,
      difficulty: .hard
    )
    .frame(
      maxWidth: .infinity,
      maxHeight: .infinity,
      alignment: .top
    )
    .background(Color.themeColor(.surfacesBackground2))
  }

  #Preview("All three missing") {
    RecipeMetricRow(
      totalTimeMinutes: nil,
      servings: nil,
      difficulty: nil
    )
    .frame(
      maxWidth: .infinity,
      maxHeight: .infinity,
      alignment: .top
    )
    .background(Color.themeColor(.surfacesBackground2))
  }

  #Preview("AX3") {
    RecipeMetricRow(
      totalTimeMinutes: 25,
      servings: 4,
      difficulty: .medium
    )
    .frame(
      maxWidth: .infinity,
      maxHeight: .infinity,
      alignment: .top
    )
    .background(Color.themeColor(.surfacesBackground2))
    .environment(
      \.dynamicTypeSize,
      .accessibility3
    )
  }
#endif
```

- [ ] **Step 5: Build and check the previews**

Run:

```bash
xcodebuild build -project RecipeTest.xcodeproj -scheme RecipeTest \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -20
```

Expected: BUILD SUCCEEDED. Then open `RecipeMetricRow.swift` in Xcode and confirm in the canvas: "Over an hour" reads `5 hr 5 min`; "All three missing" shows three em dashes rather than blank cards; "AX3" stacks into one column with nothing clipped.

- [ ] **Step 6: Commit**

```bash
git add RecipeTest/Modules/RecipeDetail/UI/Components
git commit -m "[detail] Add the overview and the metric cards"
```

---

### Task 7: Main ingredients and the checklist

**Files:**
- Create: `RecipeTest/Modules/RecipeDetail/UI/Components/MainIngredientTile.swift`
- Create: `RecipeTest/Modules/RecipeDetail/UI/Components/MainIngredientsStrip.swift`
- Create: `RecipeTest/Modules/RecipeDetail/UI/Components/IngredientChecklistRow.swift`
- Create: `RecipeTest/Modules/RecipeDetail/UI/Components/IngredientChecklist.swift`
- Test: none — views, covered by previews

**Interfaces:**
- Consumes: `RecipeIngredient`; `CachedAsyncImage`; `SingleResult<String>`; `.RecipeDetail.recipeDetailIngredientGathered` / `.recipeDetailIngredientNotGathered`.
- Produces: `MainIngredientTile(ingredient:)`; `MainIngredientsStrip(ingredients:)`; `IngredientChecklistRow(ingredient:isChecked:onTap:)`; `IngredientChecklist(ingredients:checkedIngredientIDs:onIngredientTap:)`.

- [ ] **Step 1: Create `MainIngredientTile.swift`**

```swift
//
//  MainIngredientTile.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

struct MainIngredientTile: View {
  let ingredient: RecipeIngredient

  @ScaledMetric(relativeTo: .footnote) private var imageSize: CGFloat = MainIngredientTile.baseImageSize
  @ScaledMetric(relativeTo: .footnote) private var width: CGFloat = MainIngredientTile.baseWidth

  var body: some View {
    VStack(spacing: spacing) {
      CachedAsyncImage(url: ingredient.imageURL) {
        Color.themeColor(.surfacesBackground3)
      }
      .aspectRatio(contentMode: .fill)
      .frame(
        width: imageSize,
        height: imageSize
      )
      .clipShape(.rect(cornerRadius: cornerRadius))

      Text(ingredient.name)
        .themeTextStyle(.footnoteBold)
        .themeColor(.textPrimary)
        .multilineTextAlignment(.center)
    }
    .frame(width: width)
    .accessibilityElement(children: .combine)
  }
}

// MARK: - Getters

extension MainIngredientTile {
  static var baseImageSize: CGFloat {
    74
  }

  static var baseWidth: CGFloat {
    78
  }
}

private extension MainIngredientTile {
  var spacing: CGFloat {
    8
  }

  var cornerRadius: CGFloat {
    22
  }
}

#if DEBUG
  #Preview("No photograph") {
    MainIngredientTile(ingredient: .dummy())
      .padding(20)
      .background(Color.themeColor(.surfacesBackground2))
  }

  #Preview("Long name, AX3") {
    MainIngredientTile(ingredient: .dummy(name: "Flat-Leaf Parsley"))
      .padding(20)
      .background(Color.themeColor(.surfacesBackground2))
      .environment(
        \.dynamicTypeSize,
        .accessibility3
      )
  }
#endif
```

- [ ] **Step 2: Create `MainIngredientsStrip.swift`**

```swift
//
//  MainIngredientsStrip.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

struct MainIngredientsStrip: View {
  let ingredients: [RecipeIngredient]

  var body: some View {
    ScrollView(.horizontal) {
      LazyHStack(
        alignment: .top,
        spacing: spacing
      ) {
        ForEach(ingredients) { ingredient in
          MainIngredientTile(ingredient: ingredient)
        }
      }
      .scrollTargetLayout()
    }
    .scrollIndicators(.hidden)
    .contentMargins(
      .horizontal,
      horizontalGutter,
      for: .scrollContent
    )
    .accessibilityLabel(Text(.RecipeDetail.recipeDetailMainIngredientsTitle))
  }
}

// MARK: - Getters

private extension MainIngredientsStrip {
  var spacing: CGFloat {
    14
  }

  var horizontalGutter: CGFloat {
    20
  }
}

#if DEBUG
  #Preview {
    MainIngredientsStrip(ingredients: Recipe.dummy().ingredients.filter(\.isMain))
      .frame(
        maxWidth: .infinity,
        maxHeight: .infinity,
        alignment: .top
      )
      .background(Color.themeColor(.surfacesBackground2))
  }
#endif
```

- [ ] **Step 3: Create `IngredientChecklistRow.swift`**

```swift
//
//  IngredientChecklistRow.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

/// The strikethrough is decoration; `.isToggle` and the accessibility value are what
/// actually tell a VoiceOver reader whether the ingredient has been gathered.
struct IngredientChecklistRow: View {
  let ingredient: RecipeIngredient
  let isChecked: Bool
  let onTap: SingleResult<String>

  @ScaledMetric(relativeTo: .body) private var boxSize: CGFloat = IngredientChecklistRow.baseBoxSize

  var body: some View {
    Button {
      onTap(ingredient.id)
    } label: {
      HStack(
        alignment: .top,
        spacing: spacing
      ) {
        checkbox

        label

        Spacer(minLength: 0)
      }
      .padding(
        .horizontal,
        horizontalPadding
      )
      .padding(
        .vertical,
        verticalPadding
      )
      .frame(
        maxWidth: .infinity,
        alignment: .leading
      )
      .background(
        Color.themeColor(.surfacesBackground3),
        in: .rect(cornerRadius: cornerRadius)
      )
    }
    .buttonStyle(.plain)
    .accessibilityAddTraits(.isToggle)
    .accessibilityValue(Text(
      isChecked
        ? .RecipeDetail.recipeDetailIngredientGathered
        : .RecipeDetail.recipeDetailIngredientNotGathered
    ))
  }
}

// MARK: - Getters

extension IngredientChecklistRow {
  static var baseBoxSize: CGFloat {
    24
  }
}

private extension IngredientChecklistRow {
  var spacing: CGFloat {
    14
  }

  var horizontalPadding: CGFloat {
    16
  }

  var verticalPadding: CGFloat {
    14
  }

  var cornerRadius: CGFloat {
    20
  }

  var boxCornerRadius: CGFloat {
    8
  }

  var borderWidth: CGFloat {
    1.5
  }
}

// MARK: - Subviews

private extension IngredientChecklistRow {
  var checkbox: some View {
    RoundedRectangle(cornerRadius: boxCornerRadius)
      .fill(Color.themeColor(isChecked ? .textPrimary : .surfacesBackground2))
      .overlay {
        RoundedRectangle(cornerRadius: boxCornerRadius)
          .strokeBorder(
            Color.themeColor(.textPrimary),
            lineWidth: borderWidth
          )
      }
      .overlay {
        Image(systemName: "checkmark")
          .themeTextStyle(.captionBold)
          .foregroundStyle(.themeColor(.textWhite))
          .opacity(isChecked ? 1 : 0)
      }
      .frame(
        width: boxSize,
        height: boxSize
      )
  }

  var label: some View {
    quantity
      .themeColor(isChecked ? .textSecondary : .textPrimary)
      .strikethrough(isChecked)
      .multilineTextAlignment(.leading)
  }

  /// One concatenated `Text` rather than two views: the quantity and the name have to
  /// wrap as a single paragraph, which an `HStack` of two `Text`s will not do.
  var quantity: Text {
    guard !ingredient.quantityText.isEmpty else {
      return Text(ingredient.name)
        .font(.themeTextStyle(.bodyRegular))
    }

    return Text(ingredient.quantityText)
      .font(.themeTextStyle(.bodyBold))
      + Text(" ")
      + Text(ingredient.name)
      .font(.themeTextStyle(.bodyRegular))
  }
}

#if DEBUG
  #Preview("Not gathered") {
    IngredientChecklistRow(
      ingredient: .dummy(),
      isChecked: false,
      onTap: { _ in }
    )
    .padding(20)
    .background(Color.themeColor(.surfacesBackground2))
  }

  #Preview("Gathered") {
    IngredientChecklistRow(
      ingredient: .dummy(),
      isChecked: true,
      onTap: { _ in }
    )
    .padding(20)
    .background(Color.themeColor(.surfacesBackground2))
  }

  #Preview("No quantity") {
    IngredientChecklistRow(
      ingredient: .dummy(
        quantityText: "",
        name: "Black Pepper"
      ),
      isChecked: false,
      onTap: { _ in }
    )
    .padding(20)
    .background(Color.themeColor(.surfacesBackground2))
  }
#endif
```

- [ ] **Step 4: Create `IngredientChecklist.swift`**

```swift
//
//  IngredientChecklist.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

struct IngredientChecklist: View {
  let ingredients: [RecipeIngredient]
  let checkedIngredientIDs: Set<String>
  let onIngredientTap: SingleResult<String>

  var body: some View {
    VStack(spacing: spacing) {
      ForEach(ingredients) { ingredient in
        IngredientChecklistRow(
          ingredient: ingredient,
          isChecked: checkedIngredientIDs.contains(ingredient.id),
          onTap: onIngredientTap
        )
      }
    }
    .padding(
      .horizontal,
      horizontalPadding
    )
  }
}

// MARK: - Getters

private extension IngredientChecklist {
  var spacing: CGFloat {
    8
  }

  var horizontalPadding: CGFloat {
    20
  }
}

#if DEBUG
  #Preview {
    IngredientChecklist(
      ingredients: Recipe.dummy().ingredients,
      checkedIngredientIDs: ["rcp-001-0", "rcp-001-3"],
      onIngredientTap: { _ in }
    )
    .frame(
      maxWidth: .infinity,
      maxHeight: .infinity,
      alignment: .top
    )
    .background(Color.themeColor(.surfacesBackground2))
  }
#endif
```

- [ ] **Step 5: Build**

Run:

```bash
xcodebuild build -project RecipeTest.xcodeproj -scheme RecipeTest \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -20
```

Expected: BUILD SUCCEEDED.

- [ ] **Step 6: Commit**

```bash
git add RecipeTest/Modules/RecipeDetail/UI/Components
git commit -m "[detail] Add the ingredients strip and the checklist"
```

---

### Task 8: Instructions

**Files:**
- Create: `RecipeTest/Modules/RecipeDetail/UI/Components/RecipeInstructionRow.swift`
- Create: `RecipeTest/Modules/RecipeDetail/UI/Components/RecipeInstructions.swift`
- Test: none — views, covered by previews

**Interfaces:**
- Consumes: `Color.ThemeColor.surfacesAccentSky` from Task 1; `.RecipeDetail.recipeDetailStepPosition(_:_:)` from Task 3.
- Produces: `RecipeInstructionRow(number:total:text:)`; `RecipeInstructions(steps:)`.

- [ ] **Step 1: Create `RecipeInstructionRow.swift`**

```swift
//
//  RecipeInstructionRow.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

struct RecipeInstructionRow: View {
  let number: Int
  let total: Int
  let text: String

  @ScaledMetric(relativeTo: .body) private var badgeSize: CGFloat = RecipeInstructionRow.baseBadgeSize

  var body: some View {
    HStack(
      alignment: .top,
      spacing: spacing
    ) {
      badge

      Text(text)
        .themeTextStyle(.bodyRegular)
        .themeColor(.textPrimary)
        .frame(
          maxWidth: .infinity,
          alignment: .leading
        )
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(Text(.RecipeDetail.recipeDetailStepPosition(
      number,
      total
    )))
    .accessibilityValue(Text(text))
  }
}

// MARK: - Getters

extension RecipeInstructionRow {
  static var baseBadgeSize: CGFloat {
    32
  }
}

private extension RecipeInstructionRow {
  var spacing: CGFloat {
    14
  }
}

// MARK: - Subviews

private extension RecipeInstructionRow {
  var badge: some View {
    Text(String(number))
      .themeTextStyle(.subheadlineSemibold)
      .themeColor(.textPrimary)
      .frame(
        width: badgeSize,
        height: badgeSize
      )
      .background(
        Color.themeColor(.surfacesAccentSky),
        in: .circle
      )
  }
}

#if DEBUG
  #Preview {
    RecipeInstructionRow(
      number: 3,
      total: 5,
      text: "Beat the egg yolks with the grated pecorino and a great deal of black pepper."
    )
    .padding(20)
    .background(Color.themeColor(.surfacesBackground2))
  }
#endif
```

- [ ] **Step 2: Create `RecipeInstructions.swift`**

```swift
//
//  RecipeInstructions.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

struct RecipeInstructions: View {
  let steps: [String]

  var body: some View {
    VStack(
      alignment: .leading,
      spacing: spacing
    ) {
      ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
        RecipeInstructionRow(
          number: index + 1,
          total: steps.count,
          text: step
        )
      }
    }
    .padding(
      .horizontal,
      horizontalPadding
    )
  }
}

// MARK: - Getters

private extension RecipeInstructions {
  var spacing: CGFloat {
    16
  }

  var horizontalPadding: CGFloat {
    20
  }
}

#if DEBUG
  #Preview {
    RecipeInstructions(steps: Recipe.dummy().steps)
      .frame(
        maxWidth: .infinity,
        maxHeight: .infinity,
        alignment: .top
      )
      .background(Color.themeColor(.surfacesBackground2))
  }
#endif
```

- [ ] **Step 3: Build**

Run:

```bash
xcodebuild build -project RecipeTest.xcodeproj -scheme RecipeTest \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -20
```

Expected: BUILD SUCCEEDED.

- [ ] **Step 4: Commit**

```bash
git add RecipeTest/Modules/RecipeDetail/UI/Components
git commit -m "[detail] Add the instruction steps"
```

---

### Task 9: The sheet and the scene

Assembles the components. `RecipeDetailBody` and `RecipeDetailSheet` are two component files the spec's file list did not name — they exist because the standards forbid splitting a screen into `private var someSection: some View`, and the sheet is a real unit with its own rounded clip and negative offset.

**Files:**
- Create: `RecipeTest/Modules/RecipeDetail/UI/Components/RecipeDetailBody.swift`
- Create: `RecipeTest/Modules/RecipeDetail/UI/Components/RecipeDetailSheet.swift`
- Create: `RecipeTest/Modules/RecipeDetail/UI/Scenes/RecipeDetailView.swift`
- Test: none — views, covered by previews

**Interfaces:**
- Consumes: every component from Tasks 5–8; `SectionStateView`; `RecipeDetailViewModelProtocol` from Task 4; `MockRecipeDetailViewModel` scenarios from Task 4.
- Produces: `RecipeDetailBody(recipe:checkedIngredientIDs:onIngredientTap:)`; `RecipeDetailSheet(viewModel:)`; `RecipeDetailView(viewModel:onBackTap:)`.

- [ ] **Step 1: Create `RecipeDetailBody.swift`**

```swift
//
//  RecipeDetailBody.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

/// Everything below the metric cards — the part that has to wait for `getRecipe`.
struct RecipeDetailBody: View {
  let recipe: Recipe
  let checkedIngredientIDs: Set<String>
  let onIngredientTap: SingleResult<String>

  var body: some View {
    VStack(
      alignment: .leading,
      spacing: 0
    ) {
      if !mainIngredients.isEmpty {
        RecipeDetailSectionHeader(title: .RecipeDetail.recipeDetailMainIngredientsTitle)
        MainIngredientsStrip(ingredients: mainIngredients)
      }

      if !recipe.ingredients.isEmpty {
        RecipeDetailSectionHeader(title: .RecipeDetail.recipeDetailIngredientsTitle)

        IngredientChecklist(
          ingredients: recipe.ingredients,
          checkedIngredientIDs: checkedIngredientIDs,
          onIngredientTap: onIngredientTap
        )
      }

      if !recipe.steps.isEmpty {
        RecipeDetailSectionHeader(title: .RecipeDetail.recipeDetailInstructionsTitle)
        RecipeInstructions(steps: recipe.steps)
      }
    }
    .frame(
      maxWidth: .infinity,
      alignment: .leading
    )
  }
}

// MARK: - Getters

private extension RecipeDetailBody {
  var mainIngredients: [RecipeIngredient] {
    recipe.ingredients.filter(\.isMain)
  }
}

#if DEBUG
  #Preview {
    ScrollView {
      RecipeDetailBody(
        recipe: .dummy(),
        checkedIngredientIDs: ["rcp-001-0"],
        onIngredientTap: { _ in }
      )
    }
    .background(Color.themeColor(.surfacesBackground2))
  }
#endif
```

- [ ] **Step 2: Create `RecipeDetailSheet.swift`**

```swift
//
//  RecipeDetailSheet.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

/// The white panel that rides up over the gallery. The overview and the metric row come
/// from the summary and are always present; only the body waits on the request.
struct RecipeDetailSheet: View {
  let viewModel: any RecipeDetailViewModelProtocol

  var body: some View {
    VStack(
      alignment: .leading,
      spacing: 0
    ) {
      RecipeOverviewSection(
        title: viewModel.title,
        description: viewModel.detail.value?.description ?? ""
      )

      RecipeMetricRow(
        totalTimeMinutes: viewModel.totalTimeMinutes,
        servings: viewModel.servings,
        difficulty: viewModel.difficulty
      )

      body(for: viewModel.detail)
    }
    .padding(
      .top,
      topPadding
    )
    .frame(
      maxWidth: .infinity,
      alignment: .leading
    )
    .background(Color.themeColor(.surfacesBackground2))
    .clipShape(.rect(
      topLeadingRadius: cornerRadius,
      topTrailingRadius: cornerRadius
    ))
    .offset(y: -overlap)
  }
}

// MARK: - Getters

private extension RecipeDetailSheet {
  var topPadding: CGFloat {
    8
  }

  var cornerRadius: CGFloat {
    32
  }

  /// How far the sheet rides up over the gallery.
  var overlap: CGFloat {
    32
  }

  var bodyMinHeight: CGFloat {
    240
  }
}

// MARK: - Subviews

private extension RecipeDetailSheet {
  func body(for state: SectionState<Recipe>) -> some View {
    SectionStateView(
      state: state,
      minHeight: bodyMinHeight,
      emptyMessage: .RecipeDetail.recipeDetailDetailEmpty,
      onRetryTap: { Task { await viewModel.loadDetail() } }
    ) { recipe in
      RecipeDetailBody(
        recipe: recipe,
        checkedIngredientIDs: viewModel.checkedIngredientIDs,
        onIngredientTap: viewModel.toggleIngredient(id:)
      )
    }
  }
}

#if DEBUG
  #Preview("Loaded") {
    ScrollView {
      RecipeDetailSheet(viewModel: MockRecipeDetailViewModel.loaded())
    }
    .background(Color.themeColor(.surfacesBackground))
  }

  #Preview("Loading") {
    ScrollView {
      RecipeDetailSheet(viewModel: MockRecipeDetailViewModel.loading())
    }
    .background(Color.themeColor(.surfacesBackground))
  }

  #Preview("Failed") {
    ScrollView {
      RecipeDetailSheet(viewModel: MockRecipeDetailViewModel.failed())
    }
    .background(Color.themeColor(.surfacesBackground))
  }
#endif
```

- [ ] **Step 3: Create `RecipeDetailView.swift`**

```swift
//
//  RecipeDetailView.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

struct RecipeDetailView: View {
  let viewModel: any RecipeDetailViewModelProtocol
  let onBackTap: VoidResult

  @ScaledMetric(relativeTo: .body) private var galleryHeight: CGFloat = RecipeGallery.baseHeight

  @State private var isTitleOffscreen = false

  /// A `ZStack`, not an `.overlay` on the scroll view. The scroll view ignores the top
  /// safe area so the gallery runs behind the status bar; the stack itself respects it,
  /// which is what puts the back button below the clock instead of under it. The bar's
  /// own background reaches back up over the status bar.
  var body: some View {
    ZStack(alignment: .top) {
      scrollView

      topBar
    }
    .background(Color.themeColor(.surfacesBackground))
    .toolbarVisibility(
      .hidden,
      for: .navigationBar
    )
    .task { await viewModel.loadDetail() }
  }
}

// MARK: - Getters

private extension RecipeDetailView {
  var bottomPadding: CGFloat {
    40
  }

  /// The prototype turns the bar on once the recipe's name is within 104pt of the top.
  /// The name sits 78pt below the gallery, so the trigger is the gallery's height less 78.
  var stickyBarThreshold: CGFloat {
    galleryHeight - 78
  }
}

// MARK: - Subviews

private extension RecipeDetailView {
  var scrollView: some View {
    ScrollView(.vertical) {
      VStack(
        alignment: .leading,
        spacing: 0
      ) {
        RecipeGallery(
          urls: viewModel.galleryURLs,
          accessibilityTitle: viewModel.title
        )

        RecipeDetailSheet(viewModel: viewModel)
      }
      .padding(
        .bottom,
        bottomPadding
      )
    }
    .scrollIndicators(.hidden)
    .ignoresSafeArea(edges: .top)
    .onScrollGeometryChange(for: Bool.self) { geometry in
      geometry.contentOffset.y > stickyBarThreshold
    } action: { _, isOffscreen in
      isTitleOffscreen = isOffscreen
    }
  }

  var topBar: some View {
    RecipeDetailTopBar(
      title: viewModel.title,
      isTitleOffscreen: isTitleOffscreen,
      onBackTap: onBackTap
    )
  }
}

#if DEBUG
  #Preview("Loaded") {
    NavigationStack {
      RecipeDetailView(
        viewModel: MockRecipeDetailViewModel.loaded(),
        onBackTap: {}
      )
    }
  }

  #Preview("Loading") {
    NavigationStack {
      RecipeDetailView(
        viewModel: MockRecipeDetailViewModel.loading(),
        onBackTap: {}
      )
    }
  }

  #Preview("Failed") {
    NavigationStack {
      RecipeDetailView(
        viewModel: MockRecipeDetailViewModel.failed(),
        onBackTap: {}
      )
    }
  }

  #Preview("No photographs") {
    NavigationStack {
      RecipeDetailView(
        viewModel: MockRecipeDetailViewModel.noPhotographs(),
        onBackTap: {}
      )
    }
  }

  #Preview("Metrics missing") {
    NavigationStack {
      RecipeDetailView(
        viewModel: MockRecipeDetailViewModel.missingMetrics(),
        onBackTap: {}
      )
    }
  }

  #Preview("Loaded — AX3") {
    NavigationStack {
      RecipeDetailView(
        viewModel: MockRecipeDetailViewModel.partiallyChecked(),
        onBackTap: {}
      )
    }
    .environment(
      \.dynamicTypeSize,
      .accessibility3
    )
  }
#endif
```

- [ ] **Step 4: Build and walk every scene preview**

Run:

```bash
xcodebuild build -project RecipeTest.xcodeproj -scheme RecipeTest \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -20
```

Expected: BUILD SUCCEEDED. Then open `RecipeDetailView.swift` in Xcode and confirm in the canvas, for each preview: the sheet's rounded top overlaps the gallery; the back button sits clear of the status bar; "Loading" shows the header with a spinner only below the metric cards; "Failed" shows the header plus a Retry; "No photographs" does not collapse the gallery; "AX3" stacks the metric row and clips nothing.

- [ ] **Step 5: Commit**

```bash
git add RecipeTest/Modules/RecipeDetail/UI
git commit -m "[detail] Add the recipe detail sheet and scene"
```

---

### Task 10: The coordinator

**Files:**
- Create: `RecipeTest/Modules/RecipeDetail/UI/RecipeDetailViewCoordinator.swift`
- Test: none — wiring, covered by its preview and by Task 11's manual pass

**Interfaces:**
- Consumes: `PathRouter` from the environment; `RecipeDetailViewModel(summary:recipeService:)`; `AppContainer.shared.recipeService`.
- Produces: `RecipeDetailViewCoordinator(summary:)`, and `RecipeDetailViewCoordinator(summary:recipeService:)` for previews and tests.

- [ ] **Step 1: Create `RecipeDetailViewCoordinator.swift`**

```swift
//
//  RecipeDetailViewCoordinator.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

struct RecipeDetailViewCoordinator: ViewCoordinator {
  @Environment(PathRouter.self) private var pathRouter

  @State private var viewModel: RecipeDetailViewModel

  init(
    summary: RecipeSummary,
    recipeService: RecipeServiceProtocol = AppContainer.shared.recipeService
  ) {
    _viewModel = State(initialValue: RecipeDetailViewModel(
      summary: summary,
      recipeService: recipeService
    ))
  }

  var body: some View {
    RecipeDetailView(
      viewModel: viewModel,
      onBackTap: handleBackTap()
    )
  }
}

// MARK: - Handlers

private extension RecipeDetailViewCoordinator {
  func handleBackTap() -> VoidResult {
    { pathRouter.pop() }
  }
}

#if DEBUG
  #Preview {
    NavigationStack {
      RecipeDetailViewCoordinator(summary: .dummy())
    }
    .environment(PathRouter())
  }
#endif
```

- [ ] **Step 2: Build**

Run:

```bash
xcodebuild build -project RecipeTest.xcodeproj -scheme RecipeTest \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -20
```

Expected: BUILD SUCCEEDED. The preview must carry `.environment(PathRouter())` — `@Environment(PathRouter.self)` traps at runtime when nothing supplied it, so a preview without it crashes the canvas rather than failing to compile.

- [ ] **Step 3: Commit**

```bash
git add RecipeTest/Modules/RecipeDetail/UI/RecipeDetailViewCoordinator.swift
git commit -m "[detail] Add the recipe detail coordinator"
```

---

### Task 11: Route and Home wiring

The app's first navigation. Everything it needs now exists, so this is the last code task.

**Files:**
- Modify: `RecipeTest/Modules/Recipe/Models/Domain/RecipeSummary.swift`
- Modify: `RecipeTest/Navigation/Route.swift`
- Modify: `RecipeTest/Coordinators/AppCoordinator.swift`
- Modify: `RecipeTest/Coordinators/HomeViewCoordinator.swift`
- Modify: `RecipeTest/Modules/Home/UI/Scenes/HomeView.swift`
- Modify: `RecipeTest/Modules/Home/UI/Components/LatestRecipesSection.swift`
- Modify: `RecipeTest/Modules/Home/UI/Components/LatestRecipeCarousel.swift`
- Modify: `RecipeTest/Modules/Home/UI/Components/LatestRecipeCard.swift`
- Test: none — the existing suite is the regression net

**Interfaces:**
- Consumes: `RecipeDetailViewCoordinator(summary:)` from Task 10; `PathRouter.push(_:)`.
- Produces: `Route.Recipe.detail(RecipeSummary)`; `HomeView.onRecipeTap: SingleResult<RecipeSummary>`.

- [ ] **Step 1: Make `RecipeSummary` hashable**

In `RecipeSummary.swift`, change the declaration line. `Hashable` refines `Equatable`, and every stored property is already `Hashable`, so the conformance is synthesised:

```swift
nonisolated struct RecipeSummary: Hashable, Identifiable {
```

- [ ] **Step 2: Add the route**

Replace `enum Route {}` at the bottom of `Route.swift` with the first real case. Leave the file's existing doc comment above it untouched:

```swift
enum Route {
  enum Recipe: Hashable {
    case detail(RecipeSummary)
  }
}
```

- [ ] **Step 3: Register the destination on `AppCoordinator`**

Replace the `body` in `AppCoordinator.swift`:

```swift
  var body: some View {
    NavigationStack(path: $pathRouter.path) {
      HomeViewCoordinator()
        .navigationDestination(for: Route.Recipe.self) { route in
          switch route {
          case let .detail(summary):
            RecipeDetailViewCoordinator(summary: summary)
          }
        }
    }
    .environment(pathRouter)
  }
```

- [ ] **Step 4: Widen Home's recipe callback**

In `LatestRecipeCard.swift`, change the property and the button action:

```swift
  let onTap: SingleResult<RecipeSummary>
```

```swift
    Button {
      onTap(recipe)
    } label: {
```

In `LatestRecipeCarousel.swift` and `LatestRecipesSection.swift`, change the declaration only — both just forward it:

```swift
  let onRecipeTap: SingleResult<RecipeSummary>
```

In `HomeView.swift`, change the declaration:

```swift
  let onRecipeTap: SingleResult<RecipeSummary>
```

No preview in these four files passes an id — each uses `{ _ in }`, which still compiles unchanged.

- [ ] **Step 5: Push the route from `HomeViewCoordinator`**

Add the environment property above `viewModel`:

```swift
  @Environment(PathRouter.self) private var pathRouter
```

Change the handler's return type and body:

```swift
  func handleRecipeTap() -> SingleResult<RecipeSummary> {
    { pathRouter.push(Route.Recipe.detail($0)) }
  }
```

Delete the type's `/// The handlers are empty on purpose…` doc comment — two of the three handlers are still empty, but the recipe one is not, and the comment now describes something untrue.

Add the router to its preview, which otherwise traps at runtime:

```swift
#if DEBUG
  #Preview {
    NavigationStack {
      HomeViewCoordinator()
    }
    .environment(PathRouter())
  }
#endif
```

- [ ] **Step 6: Run the whole suite**

Run:

```bash
xcodebuild test -project RecipeTest.xcodeproj -scheme RecipeTest \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:Tests 2>&1 | tail -40
```

Expected: PASS. No test asserts on the callback's type, so the widening should be invisible to the suite.

- [ ] **Step 7: Commit**

```bash
git add RecipeTest/Navigation/Route.swift RecipeTest/Coordinators RecipeTest/Modules/Home RecipeTest/Modules/Recipe/Models/Domain/RecipeSummary.swift
git commit -m "[detail] Route a recipe tap through to the detail screen"
```

---

### Task 12: Verify on a simulator

The plan's open question and the things a preview cannot answer. Nothing here is optional — the spec's last success criterion is about the back gesture, and no test covers it.

**Files:**
- Modify: `RecipeTest/Modules/RecipeDetail/UI/Scenes/RecipeDetailView.swift` (only if the fallback in Step 3 is needed)
- Test: none — manual verification

**Interfaces:**
- Consumes: everything built above.
- Produces: nothing; a confirmed build or one narrow fix.

- [ ] **Step 1: Run the app and walk the screen**

Run:

```bash
xcodebuild build -project RecipeTest.xcodeproj -scheme RecipeTest \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -20
```

Then launch it on the simulator from Xcode and check, in order:

1. Tapping a card on Home pushes the detail screen, and the photograph, title and three metric cards are visible immediately — no spinner in front of them.
2. The rest of the screen fills in a moment later without the header moving.
3. Swiping the gallery pages one photograph at a time and the dots follow.
4. Scrolling down fades in the title bar; scrolling back up fades it out.
5. Tapping an ingredient strikes it through; tapping again clears it.
6. The back button returns to Home.

- [ ] **Step 2: Verify the swipe-back gesture**

On the detail screen, drag from the very left edge of the screen rightwards.

Expected: the screen pops, exactly as the back button does.

If it does not pop, `toolbarVisibility(.hidden, for: .navigationBar)` has disabled the interactive pop gesture and Step 3 applies. If it does pop, tick Step 3 as not needed and move on.

- [ ] **Step 3: Apply the fallback only if Step 2 failed**

Do nothing if the gesture works. If it does not, keep the bar in the hierarchy and hide only its chrome. In `RecipeDetailView.swift`, replace the `.toolbarVisibility(...)` modifier with:

```swift
    .navigationBarBackButtonHidden(true)
    .toolbarBackgroundVisibility(
      .hidden,
      for: .navigationBar
    )
    .toolbarTitleDisplayMode(.inline)
```

Do not reach for `UIViewRepresentable` or a UIKit gesture-recogniser shim — the team's SwiftUI guidelines forbid bridging UIKit components.

Re-run Step 1's build and repeat Step 2 to confirm the gesture is back and the custom bar still draws over the top.

- [ ] **Step 4: Run the whole suite one more time**

Run:

```bash
xcodebuild test -project RecipeTest.xcodeproj -scheme RecipeTest \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:Tests 2>&1 | tail -40
```

Expected: PASS.

- [ ] **Step 5: Commit only if Step 3 changed a file**

```bash
git add RecipeTest/Modules/RecipeDetail/UI/Scenes/RecipeDetailView.swift
git commit -m "[detail] Keep the swipe-back gesture on the detail screen"
```

If Step 3 was not needed there is nothing to commit; the branch is complete.
