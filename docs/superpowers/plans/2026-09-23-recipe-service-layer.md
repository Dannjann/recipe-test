# Recipe Service Layer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the first feature module in `RecipeTest` — remote DTOs, domain models, mappers and a `RecipeService` that fetches a paginated recipe list and a single recipe detail, all under test, with no UI.

**Architecture:** Four layers, each depending only on the one below: `RecipeService` → `RecipeAPIProtocol` (a feature-owned protocol that `APIClient` conforms to in an extension) → `APIClient` → `MockURLProtocol`. Mapping between remote DTOs and domain models happens in caseless-enum mappers, so a change to the API's JSON shape stops there and never reaches a view model. The API protocol is what gives tests their seam: `RecipeService` is tested against `MockRecipeAPI` and never touches `URLSession`.

**Tech Stack:** Swift 6, SwiftUI app target, Alamofire (transport), Swift Testing (`import Testing`, `@Test`, `#expect`, `#require`), SwiftFormat + SwiftLint (SwiftLint runs as a build-tool plugin).

**Spec:** `docs/superpowers/specs/2026-09-23-recipe-service-layer-design.md`

> **This plan is a record of the work as it was executed, not a description of the code
> as it now stands.** Two things changed after it ran, in response to code review — see
> the spec, which is kept current, for the shape that shipped:
>
> - `RecipeService.getRecipe(id:)` throws `RecipeServiceError.unmappableRecipe(id:)`, not
>   `AppError.unknown`, and reports it through the service's own `onError`.
> - `RecipeService.init` therefore takes `onError:` alongside `api:`.
>
> The code listings below still show the pre-review shape. Follow the spec, not this file,
> when copying the layout for the next feature module.

## Global Constraints

- **Branch:** all work lands on `feat/recipe-service-layer`. Never commit on `develop` or `main`.
- **Swift version:** 6.0. App targets build with `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, so **every new type in `RecipeTest/` carries an explicit `nonisolated`**. The `Tests` target defaults to `nonisolated` and needs no annotation.
- **Indentation:** 2 spaces. Line length: 120 warning / 180 error, `RecipeTest/` only (`Tests/` is excluded from SwiftLint).
- **File headers:** every new file starts with the project's header block. App files use `//  RecipeTest` on the second line, test files use `//  Tests`:
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
- **No string literals in `String(localized:)`** — a custom SwiftLint rule rejects them. Nothing in this plan adds user-facing copy; if you need one, add it to a `.xcstrings` catalog first.
- **Xcode project:** `RecipeTest`, `Tests` and `UITests` are `PBXFileSystemSynchronizedRootGroup`s. Files dropped anywhere inside those folders join the target automatically — **never edit `project.pbxproj`**.
- **No UI, no ViewModels, no routes, no search, no filter.** Those are later stages.

## Review Focus

These are the failure modes the spec implies. Each is pinned by a test in the task named.

1. **A page past the last page** — the router answers a real page number with an empty slice, so the service must return an empty `RecipeListPage` whose `meta.hasLoadedAllData` is `true`. Getting this wrong makes a pager request empty pages forever. → Task 5 (router) and Task 7 (service).
2. **An unknown recipe id** — must surface as `APIClientError.failedRequest` carrying a 404, not as a decoding failure on an error body. → Task 5 and Task 6.
3. **The production decode path uses `GenericAPIModel.decoder()`, not `RemoteRecipe.decoder()`.** `APIResponse.decodedValue()` ignores the conforming type's own decoder. A DTO whose snake_case mapping only works under its own decoder would pass Task 2's tests and still fail in the app. → Task 6's integration test goes through the real client.
4. **`MockURLProtocol.router` is process-global and Swift Testing runs suites in parallel.** Any suite that *sets* it must be marked `@Suite(.serialized)` or it will flake against another suite's configuration. → Task 6, which is the only suite that does; Task 5's router tests construct their own instance and touch nothing global.
5. **A malformed row inside a good page** — one row missing `id` or `title` must be dropped from the page, not fail the other nine; and `steps` must be ordered by `number` rather than by their order in the payload. → Task 4 and Task 7.

---

## File Structure

**Created under `RecipeTest/Modules/Recipe/`:**

| File | Responsibility |
|---|---|
| `Clients/API/RecipeAPIProtocol.swift` | The two calls the feature needs, in the wire's vocabulary (`Int` pages, remote DTOs) |
| `Clients/API/APIClient+Recipe.swift` | Resource paths, query parameters, decode — `APIClient`'s conformance |
| `Models/Remote/RemoteRecipeSummary.swift` | List-row DTO |
| `Models/Remote/RemoteRecipe.swift` | Detail DTO and its six nested DTOs |
| `Models/Domain/RecipeDifficulty.swift` | `easy` / `medium` / `hard` |
| `Models/Domain/RecipeSummary.swift` | List-facing domain model |
| `Models/Domain/Recipe.swift` | Detail-facing domain model |
| `Models/Domain/RecipeAuthor.swift`, `RecipeNutrition.swift`, `RecipeMedia.swift`, `RecipeStep.swift` | Detail relations, one per file |
| `Models/Domain/RecipeIngredientGroup.swift` | The group and its `RecipeIngredient` — an ingredient only exists inside a group |
| `Models/Domain/RecipeListPage.swift` | `[RecipeSummary]` plus the pagination meta |
| `Services/RecipeSummaryMapper.swift` | `RemoteRecipeSummary` → `RecipeSummary?` |
| `Services/RecipeMapper.swift` | `RemoteRecipe` → `Recipe?`, including the nested types |
| `Services/RecipeServiceProtocol.swift` | The seam a view model will depend on |
| `Services/RecipeService.swift` | Translates `Page`, maps, decides what a failure means |

**Modified:**

| File | Change |
|---|---|
| `RecipeTest/Modules/Core/Clients/API/Extensions/APIClient+ModelDecoding.swift` | Replace the unused `decodeRemoteModelWithMeta` with `decodeModel` / `decodeModelWithMeta` |
| `RecipeTest/Modules/Core/Clients/API/Mock/MockEndpoint.swift` | Add `.recipes` and `.recipe(id:)` |
| `RecipeTest/Modules/Core/Clients/API/Mock/MockAPIRouter.swift` | Single-row lookup for a detail endpoint |
| `RecipeTest/Modules/Core/Models/Meta/Remote/RemotePaginationMetaInfo.swift` | Add `Equatable` |
| `RecipeTest/App/AppContainer.swift` | Register `recipeService` |

**Created under `Tests/`:**

| File | Responsibility |
|---|---|
| `Support/ErrorRecorder.swift` | Captures what a client's `onError` was handed |
| `Mocks/Support/MockAPICall.swift` | One reusable per-endpoint recorder + stub |
| `Mocks/Modules/Recipe/Clients/API/MockRecipeAPI.swift` | `RecipeAPIProtocol` double built from `MockAPICall` |
| `Mocks/Modules/Core/Models/DummyRemotePaginationMetaInfo.swift` | `.dummy()` factory |
| `Mocks/Modules/Recipe/Models/DummyRemoteRecipeSummary.swift`, `DummyRemoteRecipe.swift` | `.dummy()` factories |
| `Modules/Core/Clients/API/Extensions/APIClientModelDecodingTests.swift` | Task 1 |
| `Modules/Core/Clients/API/Mock/MockEndpointTests.swift`, `MockAPIRouterTests.swift` | Task 5 |
| `Modules/Recipe/Clients/API/GetRecipes/…`, `GetRecipe/…` | Tasks 2 and 6 |
| `Modules/Recipe/Services/RecipeSummaryMapperTests.swift`, `RecipeMapperTests.swift`, `RecipeServiceTests.swift` | Tasks 3, 4, 7 |

---

## Prerequisite: be on the branch

- [ ] **Step 0: Confirm the working branch**

```bash
git rev-parse --abbrev-ref HEAD   # must print: feat/recipe-service-layer
```

If it prints `develop` or `main`, stop and create the branch before touching anything:
`git checkout -b feat/recipe-service-layer`.

**Running the tests.** Prefer the `ios:simulator-actions` skill, which picks and boots a
simulator for you. The raw equivalent, for reference:

```bash
xcodebuild test -project RecipeTest.xcodeproj -scheme RecipeTest \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -skipPackagePluginValidation \
  CODE_SIGNING_ALLOWED=YES CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO
```

To run one suite, append `-only-testing:Tests/<SuiteName>`.

---

### Task 1: Core decoding helpers

The current `decodeRemoteModelWithMeta` decodes *and* maps in one call, which puts
mapping in the client layer. It has no callers anywhere in the repository. Replace it
with two helpers that only decode.

**Files:**
- Modify: `RecipeTest/Modules/Core/Clients/API/Extensions/APIClient+ModelDecoding.swift` (full rewrite)
- Create: `Tests/Support/ErrorRecorder.swift`
- Test: `Tests/Modules/Core/Clients/API/Extensions/APIClientModelDecodingTests.swift`

**Interfaces:**
- Consumes: `APIResponse.decodedValue(forKeyPath:decoder:)`, `APIResponse.decodeMeta(decoder:)`, `APIClientError.dataNotFound(_:)`, `APIClient.onError` — all existing.
- Produces: `APIClient.decodeModel<T: Decodable>(_ response: APIResponse) throws -> T` and `APIClient.decodeModelWithMeta<T: Decodable, M: Decodable>(_ response: APIResponse) throws -> (T, M)`. Task 6 calls both. `ErrorRecorder` is reused by Task 6.

- [ ] **Step 1: Write the failing test**

Create `Tests/Support/ErrorRecorder.swift`:

```swift
//
//  ErrorRecorder.swift
//  Tests
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

/// Captures what an `APIClient`'s `onError` closure was handed.
///
/// `@unchecked Sendable` with a lock rather than a plain array: `onError` is
/// `@Sendable` and Alamofire may call it off the test's own thread.
final class ErrorRecorder: @unchecked Sendable {
  private let lock = NSLock()
  private var recorded: [any Error] = []

  var errors: [any Error] {
    lock.withLock { recorded }
  }

  var count: Int {
    errors.count
  }

  func record(_ error: any Error) {
    lock.withLock { recorded.append(error) }
  }
}
```

Create `Tests/Modules/Core/Clients/API/Extensions/APIClientModelDecodingTests.swift`:

```swift
//
//  APIClientModelDecodingTests.swift
//  Tests
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation
@testable import RecipeTest
import Testing

struct APIClientModelDecodingTests {
  /// A stand-in remote model. `display_name` proves the snake_case decoder is the one
  /// being used.
  struct Item: APIModel, Decodable, Equatable {
    let id: String?
    let displayName: String?
  }

  @Test
  func decodeModel_decodesTheDataPayload() throws {
    let sut = makeSUT()
    let response = try makeResponse(data: #"{"id": "1", "display_name": "First"}"#)

    let item: Item = try sut.decodeModel(response)

    #expect(item == Item(id: "1", displayName: "First"))
  }

  @Test
  func decodeModel_decodesAnArrayPayload() throws {
    let sut = makeSUT()
    let response = try makeResponse(data: #"[{"id": "1"}, {"id": "2"}]"#)

    let items: [Item] = try sut.decodeModel(response)

    #expect(items.map(\.id) == ["1", "2"])
  }

  @Test
  func decodeModel_withNoData_throwsAndReportsTheError() throws {
    let recorder = ErrorRecorder()
    let sut = makeSUT(onError: recorder.record)
    let response = try makeResponse(data: "null")

    #expect(throws: APIClientError.self) {
      let _: Item = try sut.decodeModel(response)
    }

    #expect(recorder.count == 1)
  }

  @Test
  func decodeModelWithMeta_decodesBothPayloadAndMeta() throws {
    let sut = makeSUT()
    let response = try makeResponse(
      data: #"[{"id": "1"}]"#,
      meta: #"{"total": 25, "per_page": 10, "from": 1, "to": 10, "current_page": 1, "last_page": 3}"#
    )

    let (items, meta): ([Item], RemotePaginationMetaInfo) = try sut.decodeModelWithMeta(response)

    #expect(items.map(\.id) == ["1"])
    #expect(meta.total == 25)
    #expect(meta.lastPage == 3)
  }

  @Test
  func decodeModelWithMeta_withNoMeta_throwsAndReportsTheError() throws {
    let recorder = ErrorRecorder()
    let sut = makeSUT(onError: recorder.record)
    let response = try makeResponse(data: #"[{"id": "1"}]"#)

    #expect(throws: APIClientError.self) {
      let _: ([Item], RemotePaginationMetaInfo) = try sut.decodeModelWithMeta(response)
    }

    #expect(recorder.count == 1)
  }
}

// MARK: - Helpers

private extension APIClientModelDecodingTests {
  func makeSUT(onError: @escaping SendableErrorResult = { _ in }) -> APIClient {
    APIClient(
      baseURL: URL(string: "https://api.example.com/api")!,
      version: "v1",
      onError: onError
    )
  }

  func makeResponse(data: String, meta: String? = nil) throws -> APIResponse {
    var json = #"{"http_status": 200, "message": "OK", "data": \#(data)"#

    if let meta {
      json += #", "meta": \#(meta)"#
    }

    json += "}"

    return try JSONDecoder().decode(APIResponse.self, from: Data(json.utf8))
  }
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run the `Tests/APIClientModelDecodingTests` suite.
Expected: compile failure — `value of type 'APIClient' has no member 'decodeModel'`.

- [ ] **Step 3: Write the implementation**

Replace the whole of `RecipeTest/Modules/Core/Clients/API/Extensions/APIClient+ModelDecoding.swift`:

```swift
//
//  APIClient+ModelDecoding.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2024 Danjan. All rights reserved.
//

import Foundation

nonisolated extension APIClient {
  /// Decodes an `APIResponse`'s `data` payload into a remote model.
  ///
  /// Decoding only. Turning a remote model into a domain one is a mapper's job, in the
  /// feature's own `Services` folder — that boundary is what keeps a change in the
  /// API's JSON shape from reaching a view model.
  ///
  /// Every failure is reported through `onError` before it is rethrown, so a decoding
  /// break shows up in monitoring rather than only at the call site.
  func decodeModel<T: Decodable>(_ response: APIResponse) throws -> T {
    do {
      guard let model: T = try response.decodedValue() else {
        throw APIClientError.dataNotFound(T.self)
      }

      return model
    } catch {
      onError(error)
      throw error
    }
  }

  /// Decodes an `APIResponse`'s `data` payload and its `meta` block together.
  ///
  /// A missing `meta` is an error rather than a defaulted value: a caller asking for
  /// meta is paginating, and inventing `currentPage: 1, lastPage: 1` for a response
  /// that carried no pagination would silently stop the pager at the first page.
  func decodeModelWithMeta<T: Decodable, M: Decodable>(_ response: APIResponse) throws -> (T, M) {
    do {
      guard let model: T = try response.decodedValue() else {
        throw APIClientError.dataNotFound(T.self)
      }

      guard let meta: M = try response.decodeMeta() else {
        throw APIClientError.dataNotFound(M.self)
      }

      return (model, meta)
    } catch {
      onError(error)
      throw error
    }
  }
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run the `Tests/APIClientModelDecodingTests` suite. Expected: 5 tests pass.

- [ ] **Step 5: Format, then commit**

```bash
swiftformat RecipeTest Tests UITests && swiftformat RecipeTest Tests UITests --lint
git add RecipeTest/Modules/Core/Clients/API/Extensions/APIClient+ModelDecoding.swift \
        Tests/Support/ErrorRecorder.swift \
        Tests/Modules/Core/Clients/API/Extensions/APIClientModelDecodingTests.swift
git commit -m "refactor(core): split model decoding from mapping

decodeRemoteModelWithMeta decoded and mapped in one call, putting mapping in
the client layer. It had no callers. decodeModel and decodeModelWithMeta only
decode; mapping moves to each feature's own mappers."
```

---

### Task 2: Remote DTOs

**Files:**
- Create: `RecipeTest/Modules/Recipe/Models/Remote/RemoteRecipeSummary.swift`
- Create: `RecipeTest/Modules/Recipe/Models/Remote/RemoteRecipe.swift`
- Test: `Tests/Modules/Recipe/Clients/API/GetRecipes/GetRecipesTests.swift` + `GetRecipesTests_200.json`
- Test: `Tests/Modules/Recipe/Clients/API/GetRecipe/GetRecipeTests.swift` + `GetRecipeTests_200.json` + `GetRecipeTests_200_minimal.json`

**Interfaces:**
- Consumes: `APIModel` (supplies the snake_case decoder — no `CodingKeys` needed anywhere in this task), `Fixture.apiResponse(_:)` from `Tests/Support/FixtureLoader.swift`.
- Produces: `RemoteRecipeSummary`, `RemoteRecipe`, `RemoteRecipeAuthor`, `RemoteRecipeNutrition`, `RemoteRecipeMedia`, `RemoteIngredientGroup`, `RemoteIngredient`, `RemoteRecipeStep` — all with every property optional, all `Equatable`. Tasks 3, 4, 6 and 7 consume them.

- [ ] **Step 1: Generate the fixtures**

They are derived from the shipped fixture rather than hand-written, so they cannot drift
from what the app actually serves.

```bash
python3 - <<'PY'
import json, pathlib

rows = json.load(open('RecipeTest/Resources/MockData/recipes.json'))
base = pathlib.Path('Tests/Modules/Recipe/Clients/API')

summary_keys = [
    'id', 'slug', 'title', 'short_description', 'hero_image_url',
    'total_time_minutes', 'difficulty', 'rating', 'rating_count', 'tags',
]

def write(path, payload):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + '\n')

write(base / 'GetRecipes/GetRecipesTests_200.json', {
    'http_status': 200,
    'message': 'OK',
    'data': [{k: r[k] for k in summary_keys} for r in rows[:3]],
    'meta': {'total': 36, 'per_page': 3, 'from': 1, 'to': 3,
             'current_page': 1, 'last_page': 12},
})

def row(recipe_id):
    return next(r for r in rows if r['id'] == recipe_id)

# rcp-001: one ingredient group, author and nutrition present.
write(base / 'GetRecipe/GetRecipeTests_200.json',
      {'http_status': 200, 'message': 'OK', 'data': row('rcp-001')})

# rcp-021: the only kind of row where author AND nutrition are both null.
write(base / 'GetRecipe/GetRecipeTests_200_minimal.json',
      {'http_status': 200, 'message': 'OK', 'data': row('rcp-021')})

print('wrote 3 fixtures')
PY
```

Then note the values the tests below assert against:

```bash
python3 -c "
import json
d = json.load(open('Tests/Modules/Recipe/Clients/API/GetRecipe/GetRecipeTests_200.json'))['data']
print('groups', len(d['ingredient_groups']), 'steps', len(d['steps']), 'gallery', len(d['gallery']))
print('first ingredient', d['ingredient_groups'][0]['ingredients'][0])
print('author', d['author']['name'], '| calories', d['nutrition']['calories_per_serving'])
"
```

- [ ] **Step 2: Write the failing tests**

Create `Tests/Modules/Recipe/Clients/API/GetRecipes/GetRecipesTests.swift`:

```swift
//
//  GetRecipesTests.swift
//  Tests
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation
@testable import RecipeTest
import Testing

struct GetRecipesTests {
  @Test
  func response200_decodesTheSummaries() throws {
    let sut = try makeSUT()

    let data: [RemoteRecipeSummary]? = try sut.decodedValue()

    #expect(data?.count == 3)

    let first = try #require(data?.first)
    #expect(first.id == "rcp-001")
    #expect(first.slug == "spaghetti-alla-carbonara")
    #expect(first.title == "Spaghetti alla Carbonara")
    #expect(first.shortDescription?.hasPrefix("Roman pasta") == true)
    #expect(first.totalTimeMinutes == 25)
    #expect(first.difficulty == "medium")
    #expect(first.rating == 4.8)
    #expect(first.ratingCount == 2147)
    #expect(first.tags == ["quick", "classic", "five-ingredient"])
  }

  /// `hero_image_url` reaching `heroImageUrl` is the whole snake_case contract. If the
  /// property were named `heroImageURL`, the converting decoder would leave it nil.
  @Test
  func response200_mapsSnakeCaseKeys() throws {
    let sut = try makeSUT()

    let data: [RemoteRecipeSummary]? = try sut.decodedValue()
    let first = try #require(data?.first)

    #expect(first.heroImageUrl?.hasSuffix("spaghetti-alla-carbonara.png") == true)
  }

  @Test
  func response200_decodesPaginationMeta() throws {
    let sut = try makeSUT()

    let meta: RemotePaginationMetaInfo? = try sut.decodeMeta()

    #expect(meta?.total == 36)
    #expect(meta?.perPage == 3)
    #expect(meta?.currentPage == 1)
    #expect(meta?.lastPage == 12)
  }
}

// MARK: - Helpers

private extension GetRecipesTests {
  func makeSUT() throws -> APIResponse {
    try Fixture.apiResponse("GetRecipesTests_200")
  }
}
```

Create `Tests/Modules/Recipe/Clients/API/GetRecipe/GetRecipeTests.swift`:

```swift
//
//  GetRecipeTests.swift
//  Tests
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation
@testable import RecipeTest
import Testing

struct GetRecipeTests {
  @Test
  func response200_decodesTheDetailFields() throws {
    let sut = try #require(try makeSUT())

    #expect(sut.id == "rcp-001")
    #expect(sut.title == "Spaghetti alla Carbonara")
    #expect(sut.fullDescription?.isEmpty == false)
    #expect(sut.servings == 4)
    #expect(sut.prepTimeMinutes == 10)
    #expect(sut.cookTimeMinutes == 15)
    #expect(sut.cuisine == "italian")
    #expect(sut.mealType == "dinner")
    #expect(sut.allergens == ["gluten", "eggs", "dairy"])
    #expect(sut.dietaryAttributes == [])
    #expect(sut.updatedAt == "2026-07-01T07:07:00.000Z")
  }

  @Test
  func response200_decodesTheAuthorAndNutrition() throws {
    let sut = try #require(try makeSUT())

    let author = try #require(sut.author)
    #expect(author.id == "aut-02")
    #expect(author.name == "Tobias Lindqvist")
    #expect(author.avatarUrl?.hasSuffix("author-aut-02.png") == true)

    let nutrition = try #require(sut.nutrition)
    #expect(nutrition.caloriesPerServing == 712)
    #expect(nutrition.proteinGrams == 29.4)
    #expect(nutrition.sodiumMilligrams == 980.0)
  }

  @Test
  func response200_decodesTheGallery() throws {
    let sut = try #require(try makeSUT())

    let gallery = try #require(sut.gallery)
    #expect(gallery.count == 2)
    #expect(gallery.first?.id == "med-001-1")
    #expect(gallery.first?.altText?.isEmpty == false)
  }

  @Test
  func response200_decodesIngredientGroupsAndTheirIngredients() throws {
    let sut = try #require(try makeSUT())

    let groups = try #require(sut.ingredientGroups)
    #expect(groups.count == 1)

    let group = try #require(groups.first)
    #expect(group.id == "grp-001-1")
    // A single unnamed list: null means "this recipe has one list", not a missing value.
    #expect(group.title == nil)

    let ingredients = try #require(group.ingredients)
    #expect(ingredients.count == 6)

    let first = try #require(ingredients.first)
    #expect(first.name == "Spaghetti")
    #expect(first.quantity == 320.0)
    #expect(first.unit == "gram")
    #expect(first.isOptional == false)

    let optional = try #require(ingredients.first { $0.name == "Black Pepper" })
    #expect(optional.isOptional == true)
    #expect(optional.quantity == nil)
    #expect(optional.note == "as required")
  }

  @Test
  func response200_decodesSteps() throws {
    let sut = try #require(try makeSUT())

    let steps = try #require(sut.steps)
    #expect(steps.count == 6)
    #expect(steps.map(\.number) == [1, 2, 3, 4, 5, 6])

    let first = try #require(steps.first)
    #expect(first.id == "stp-001-1")
    #expect(first.durationSeconds == 600)
    #expect(first.imageUrl?.hasSuffix("step-1.png") == true)
    #expect(steps.dropFirst().first?.imageUrl == nil)
  }

  /// `author` and `nutrition` are the only two top-level fields the fixture ever sends
  /// as null. A row that omits both must still decode.
  @Test
  func response200Minimal_decodesWithNoAuthorOrNutrition() throws {
    let sut = try #require(try makeSUT(fixture: "GetRecipeTests_200_minimal"))

    #expect(sut.id == "rcp-021")
    #expect(sut.author == nil)
    #expect(sut.nutrition == nil)
    #expect(sut.title?.isEmpty == false)
  }
}

// MARK: - Helpers

private extension GetRecipeTests {
  func makeSUT(fixture: String = "GetRecipeTests_200") throws -> RemoteRecipe? {
    try Fixture.apiResponse(fixture).decodedValue()
  }
}
```

- [ ] **Step 3: Run the tests to verify they fail**

Run the `Tests/GetRecipesTests` and `Tests/GetRecipeTests` suites.
Expected: compile failure — `cannot find type 'RemoteRecipeSummary' in scope`.

- [ ] **Step 4: Write the implementation**

Create `RecipeTest/Modules/Recipe/Models/Remote/RemoteRecipeSummary.swift`:

```swift
//
//  RemoteRecipeSummary.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

/// One row of the recipe list, as the API sends it.
///
/// Every property is optional on purpose: a single missing or retyped field must cost
/// one value, not the whole page. What the app actually requires is decided in
/// `RecipeSummaryMapper`, which is the only place a `nil` here turns into a dropped row.
///
/// Property names are the camelCase of the wire's snake_case — `hero_image_url` becomes
/// `heroImageUrl`, not `heroImageURL`. `APIModel`'s decoder converts the keys, so
/// renaming one of these to a nicer acronym casing would silently decode it as nil.
nonisolated struct RemoteRecipeSummary: APIModel, Decodable, Equatable {
  let id: String?
  let slug: String?
  let title: String?
  let shortDescription: String?
  let heroImageUrl: String?
  let totalTimeMinutes: Int?
  let difficulty: String?
  let rating: Double?
  let ratingCount: Int?
  let tags: [String]?
}
```

Create `RecipeTest/Modules/Recipe/Models/Remote/RemoteRecipe.swift`:

```swift
//
//  RemoteRecipe.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

/// A full recipe, as the API sends it.
///
/// The nested types live in this file rather than one each: they are field lists with
/// no behaviour and are only ever read as part of a recipe.
///
/// `updatedAt` stays a `String` here and is parsed in `RecipeMapper`. Handing it to a
/// decoder date strategy would make one unparseable timestamp throw away the entire
/// recipe; in the mapper it costs that one field.
nonisolated struct RemoteRecipe: APIModel, Decodable, Equatable {
  let id: String?
  let slug: String?
  let title: String?
  let shortDescription: String?
  let fullDescription: String?
  let heroImageUrl: String?
  let servings: Int?
  let prepTimeMinutes: Int?
  let cookTimeMinutes: Int?
  let totalTimeMinutes: Int?
  let difficulty: String?
  let cuisine: String?
  let mealType: String?
  let tags: [String]?
  let dietaryAttributes: [String]?
  let allergens: [String]?
  let rating: Double?
  let ratingCount: Int?
  let updatedAt: String?
  let author: RemoteRecipeAuthor?
  let nutrition: RemoteRecipeNutrition?
  let gallery: [RemoteRecipeMedia]?
  let ingredientGroups: [RemoteIngredientGroup]?
  let steps: [RemoteRecipeStep]?
}

nonisolated struct RemoteRecipeAuthor: APIModel, Decodable, Equatable {
  let id: String?
  let name: String?
  let avatarUrl: String?
  let profileUrl: String?
}

nonisolated struct RemoteRecipeNutrition: APIModel, Decodable, Equatable {
  let caloriesPerServing: Int?
  let proteinGrams: Double?
  let carbohydrateGrams: Double?
  let fatGrams: Double?
  let fibreGrams: Double?
  let sodiumMilligrams: Double?
}

nonisolated struct RemoteRecipeMedia: APIModel, Decodable, Equatable {
  let id: String?
  let url: String?
  let altText: String?
}

nonisolated struct RemoteIngredientGroup: APIModel, Decodable, Equatable {
  let id: String?
  let title: String?
  let ingredients: [RemoteIngredient]?
}

nonisolated struct RemoteIngredient: APIModel, Decodable, Equatable {
  let id: String?
  let name: String?
  let quantity: Double?
  let unit: String?
  let note: String?
  let isOptional: Bool?
}

nonisolated struct RemoteRecipeStep: APIModel, Decodable, Equatable {
  let id: String?
  let number: Int?
  let text: String?
  let imageUrl: String?
  let durationSeconds: Int?
}
```

- [ ] **Step 5: Run the tests to verify they pass**

Run both suites. Expected: 9 tests pass.

- [ ] **Step 6: Format, then commit**

```bash
swiftformat RecipeTest Tests UITests && swiftformat RecipeTest Tests UITests --lint
git add RecipeTest/Modules/Recipe/Models/Remote Tests/Modules/Recipe/Clients/API
git commit -m "feat(recipe): add the remote recipe DTOs

Every property is optional so one retyped field costs one value rather than a
whole page; what the app requires is decided in the mappers. Fixtures are sliced
from the shipped recipes.json so they cannot drift from what the app serves."
```

---

### Task 3: Summary domain model and its mapper

**Files:**
- Create: `RecipeTest/Modules/Recipe/Models/Domain/RecipeDifficulty.swift`
- Create: `RecipeTest/Modules/Recipe/Models/Domain/RecipeSummary.swift`
- Create: `RecipeTest/Modules/Recipe/Services/RecipeSummaryMapper.swift`
- Create: `Tests/Mocks/Modules/Recipe/Models/DummyRemoteRecipeSummary.swift`
- Test: `Tests/Modules/Recipe/Services/RecipeSummaryMapperTests.swift`

**Interfaces:**
- Consumes: `RemoteRecipeSummary` (Task 2).
- Produces: `RecipeDifficulty` (`.easy` / `.medium` / `.hard`), `RecipeSummary`, `RecipeSummaryMapper.toDomain(from: RemoteRecipeSummary) -> RecipeSummary?`, and `RemoteRecipeSummary.dummy(...)`. Tasks 4 and 7 consume all four.

- [ ] **Step 1: Write the failing test**

Create `Tests/Mocks/Modules/Recipe/Models/DummyRemoteRecipeSummary.swift`:

```swift
//
//  DummyRemoteRecipeSummary.swift
//  Tests
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation
@testable import RecipeTest

extension RemoteRecipeSummary {
  static func dummy(
    id: String? = "rcp-001",
    slug: String? = "spaghetti-alla-carbonara",
    title: String? = "Spaghetti alla Carbonara",
    shortDescription: String? = "Roman pasta bound with egg yolk and pecorino.",
    heroImageUrl: String? = "https://api.example.com/api/v1/images/carbonara.png",
    totalTimeMinutes: Int? = 25,
    difficulty: String? = "medium",
    rating: Double? = 4.8,
    ratingCount: Int? = 2147,
    tags: [String]? = ["quick", "classic"]
  ) -> RemoteRecipeSummary {
    RemoteRecipeSummary(
      id: id,
      slug: slug,
      title: title,
      shortDescription: shortDescription,
      heroImageUrl: heroImageUrl,
      totalTimeMinutes: totalTimeMinutes,
      difficulty: difficulty,
      rating: rating,
      ratingCount: ratingCount,
      tags: tags
    )
  }
}
```

Create `Tests/Modules/Recipe/Services/RecipeSummaryMapperTests.swift`:

```swift
//
//  RecipeSummaryMapperTests.swift
//  Tests
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation
@testable import RecipeTest
import Testing

struct RecipeSummaryMapperTests {
  @Test
  func toDomain_mapsACompleteRow() throws {
    let sut = try #require(RecipeSummaryMapper.toDomain(from: .dummy()))

    #expect(sut.id == "rcp-001")
    #expect(sut.title == "Spaghetti alla Carbonara")
    #expect(sut.shortDescription == "Roman pasta bound with egg yolk and pecorino.")
    #expect(sut.heroImageURL?.absoluteString == "https://api.example.com/api/v1/images/carbonara.png")
    #expect(sut.totalTimeMinutes == 25)
    #expect(sut.difficulty == .medium)
    #expect(sut.rating == 4.8)
    #expect(sut.ratingCount == 2147)
    #expect(sut.tags == ["quick", "classic"])
  }

  @Test
  func toDomain_withoutAnID_returnsNil() {
    #expect(RecipeSummaryMapper.toDomain(from: .dummy(id: nil)) == nil)
  }

  @Test
  func toDomain_withAnEmptyID_returnsNil() {
    #expect(RecipeSummaryMapper.toDomain(from: .dummy(id: "")) == nil)
  }

  @Test
  func toDomain_withoutATitle_returnsNil() {
    #expect(RecipeSummaryMapper.toDomain(from: .dummy(title: nil)) == nil)
  }

  @Test
  func toDomain_withAnEmptyTitle_returnsNil() {
    #expect(RecipeSummaryMapper.toDomain(from: .dummy(title: "")) == nil)
  }

  /// Everything except id and title has a defined fallback. A row that carries only the
  /// two required fields is still a usable list row.
  @Test
  func toDomain_withOnlyTheRequiredFields_fillsTheRest() throws {
    let remote = RemoteRecipeSummary.dummy(
      shortDescription: nil,
      heroImageUrl: nil,
      totalTimeMinutes: nil,
      difficulty: nil,
      rating: nil,
      ratingCount: nil,
      tags: nil
    )

    let sut = try #require(RecipeSummaryMapper.toDomain(from: remote))

    #expect(sut.shortDescription == "")
    #expect(sut.heroImageURL == nil)
    #expect(sut.totalTimeMinutes == nil)
    #expect(sut.difficulty == nil)
    #expect(sut.rating == 0)
    #expect(sut.ratingCount == 0)
    #expect(sut.tags == [])
  }

  /// A difficulty the app has no case for must not cost the row. Today the fixture only
  /// sends easy/medium/hard; a backend adding "expert" must degrade, not break.
  @Test
  func toDomain_withAnUnknownDifficulty_keepsTheRowAndDropsTheValue() throws {
    let sut = try #require(RecipeSummaryMapper.toDomain(from: .dummy(difficulty: "expert")))

    #expect(sut.difficulty == nil)
    #expect(sut.id == "rcp-001")
  }

  @Test
  func toDomain_withAnUnparseableHeroImageURL_keepsTheRow() throws {
    let sut = try #require(RecipeSummaryMapper.toDomain(from: .dummy(heroImageUrl: "")))

    #expect(sut.heroImageURL == nil)
    #expect(sut.id == "rcp-001")
  }

  @Test(arguments: [("easy", RecipeDifficulty.easy), ("medium", .medium), ("hard", .hard)])
  func toDomain_mapsEveryKnownDifficulty(raw: String, expected: RecipeDifficulty) throws {
    let sut = try #require(RecipeSummaryMapper.toDomain(from: .dummy(difficulty: raw)))

    #expect(sut.difficulty == expected)
  }
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run the `Tests/RecipeSummaryMapperTests` suite.
Expected: compile failure — `cannot find 'RecipeSummaryMapper' in scope`.

- [ ] **Step 3: Write the implementation**

Create `RecipeTest/Modules/Recipe/Models/Domain/RecipeDifficulty.swift`:

```swift
//
//  RecipeDifficulty.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

/// How hard a recipe is to cook.
///
/// An enum rather than a raw string because the set is closed and small, and a badge in
/// the UI has to switch on it. An unrecognised value maps to `nil` in the mapper rather
/// than failing the row — see `RecipeSummaryMapper`.
///
/// The open-ended facets — cuisine, meal type, tags, dietary attributes, allergens —
/// deliberately stay `String`. An enum would have to drop a value it has no case for,
/// and silently dropping an entry from an allergen list is worse than showing a word the
/// app does not recognise.
nonisolated enum RecipeDifficulty: String, Equatable, CaseIterable {
  case easy
  case medium
  case hard
}
```

Create `RecipeTest/Modules/Recipe/Models/Domain/RecipeSummary.swift`:

```swift
//
//  RecipeSummary.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

/// One row of the recipe list, as the app uses it.
///
/// Separate from `Recipe` rather than one type with the detail fields left optional: a
/// list cell then cannot reach for steps that were never fetched, and `Recipe` has no
/// optionals that are "only nil in list context".
nonisolated struct RecipeSummary: Equatable, Identifiable {
  let id: String
  let title: String
  let shortDescription: String
  let heroImageURL: URL?
  let totalTimeMinutes: Int?
  let difficulty: RecipeDifficulty?
  let rating: Double
  let ratingCount: Int
  let tags: [String]
}
```

Create `RecipeTest/Modules/Recipe/Services/RecipeSummaryMapper.swift`:

```swift
//
//  RecipeSummaryMapper.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

/// Turns a `RemoteRecipeSummary` into a `RecipeSummary`.
///
/// The only place both the wire's shape and the app's shape are visible. Returning nil
/// is how a row says it is not usable; the service `compactMap`s, so one bad row costs
/// itself and not the page around it.
nonisolated enum RecipeSummaryMapper {
  /// Requires `id` and `title`. Everything else has a fallback — a row that carries only
  /// those two still renders.
  static func toDomain(from remote: RemoteRecipeSummary) -> RecipeSummary? {
    guard
      let id = remote.id, !id.isEmpty,
      let title = remote.title, !title.isEmpty
    else {
      return nil
    }

    return RecipeSummary(
      id: id,
      title: title,
      shortDescription: remote.shortDescription ?? "",
      heroImageURL: remote.heroImageUrl.flatMap { URL(string: $0) },
      totalTimeMinutes: remote.totalTimeMinutes,
      difficulty: remote.difficulty.flatMap { RecipeDifficulty(rawValue: $0) },
      rating: remote.rating ?? 0,
      ratingCount: remote.ratingCount ?? 0,
      tags: remote.tags ?? []
    )
  }
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run the `Tests/RecipeSummaryMapperTests` suite. Expected: 11 tests pass (the parameterised one counts as 3).

- [ ] **Step 5: Format, then commit**

```bash
swiftformat RecipeTest Tests UITests && swiftformat RecipeTest Tests UITests --lint
git add RecipeTest/Modules/Recipe/Models/Domain RecipeTest/Modules/Recipe/Services \
        Tests/Mocks/Modules/Recipe/Models Tests/Modules/Recipe/Services
git commit -m "feat(recipe): add RecipeSummary and its mapper

difficulty is an enum because the set is closed and the UI switches on it;
cuisine, tags, dietary attributes and allergens stay strings, since an enum
would have to drop values it has no case for."
```

---

### Task 4: Detail domain models and their mapper

**Files:**
- Create: `RecipeTest/Modules/Recipe/Models/Domain/RecipeAuthor.swift`, `RecipeNutrition.swift`, `RecipeMedia.swift`, `RecipeStep.swift`, `RecipeIngredientGroup.swift`, `Recipe.swift`
- Create: `RecipeTest/Modules/Recipe/Services/RecipeMapper.swift`
- Create: `Tests/Mocks/Modules/Recipe/Models/DummyRemoteRecipe.swift`
- Test: `Tests/Modules/Recipe/Services/RecipeMapperTests.swift`

**Interfaces:**
- Consumes: `RemoteRecipe` and its nested DTOs (Task 2), `RecipeDifficulty` (Task 3), `DateFormatter.iso8601` (existing, in `Extensions/Foundation/DateFormatters`).
- Produces: `Recipe`, `RecipeAuthor`, `RecipeNutrition`, `RecipeMedia`, `RecipeIngredientGroup`, `RecipeIngredient`, `RecipeStep`, `RecipeMapper.toDomain(from: RemoteRecipe) -> Recipe?`, and `RemoteRecipe.dummy(...)` plus a `.dummy(...)` on each nested remote type. Task 7 consumes `Recipe`, `RecipeMapper` and `RemoteRecipe.dummy`.

- [ ] **Step 1: Write the failing test**

Create `Tests/Mocks/Modules/Recipe/Models/DummyRemoteRecipe.swift`:

```swift
//
//  DummyRemoteRecipe.swift
//  Tests
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation
@testable import RecipeTest

extension RemoteRecipe {
  static func dummy(
    id: String? = "rcp-001",
    slug: String? = "spaghetti-alla-carbonara",
    title: String? = "Spaghetti alla Carbonara",
    shortDescription: String? = "Roman pasta bound with egg yolk and pecorino.",
    fullDescription: String? = "The whole dish turns on one trick.",
    heroImageUrl: String? = "https://api.example.com/api/v1/images/carbonara.png",
    servings: Int? = 4,
    prepTimeMinutes: Int? = 10,
    cookTimeMinutes: Int? = 15,
    totalTimeMinutes: Int? = 25,
    difficulty: String? = "medium",
    cuisine: String? = "italian",
    mealType: String? = "dinner",
    tags: [String]? = ["quick"],
    dietaryAttributes: [String]? = [],
    allergens: [String]? = ["gluten", "eggs"],
    rating: Double? = 4.8,
    ratingCount: Int? = 2147,
    updatedAt: String? = "2026-07-01T07:07:00.000Z",
    author: RemoteRecipeAuthor? = .dummy(),
    nutrition: RemoteRecipeNutrition? = .dummy(),
    gallery: [RemoteRecipeMedia]? = [.dummy()],
    ingredientGroups: [RemoteIngredientGroup]? = [.dummy()],
    steps: [RemoteRecipeStep]? = [.dummy(id: "stp-1", number: 1), .dummy(id: "stp-2", number: 2)]
  ) -> RemoteRecipe {
    RemoteRecipe(
      id: id,
      slug: slug,
      title: title,
      shortDescription: shortDescription,
      fullDescription: fullDescription,
      heroImageUrl: heroImageUrl,
      servings: servings,
      prepTimeMinutes: prepTimeMinutes,
      cookTimeMinutes: cookTimeMinutes,
      totalTimeMinutes: totalTimeMinutes,
      difficulty: difficulty,
      cuisine: cuisine,
      mealType: mealType,
      tags: tags,
      dietaryAttributes: dietaryAttributes,
      allergens: allergens,
      rating: rating,
      ratingCount: ratingCount,
      updatedAt: updatedAt,
      author: author,
      nutrition: nutrition,
      gallery: gallery,
      ingredientGroups: ingredientGroups,
      steps: steps
    )
  }
}

extension RemoteRecipeAuthor {
  static func dummy(
    id: String? = "aut-02",
    name: String? = "Tobias Lindqvist",
    avatarUrl: String? = "https://api.example.com/api/v1/images/author-aut-02.png",
    profileUrl: String? = "https://example.com/cooks/tobias-lindqvist"
  ) -> RemoteRecipeAuthor {
    RemoteRecipeAuthor(id: id, name: name, avatarUrl: avatarUrl, profileUrl: profileUrl)
  }
}

extension RemoteRecipeNutrition {
  static func dummy(
    caloriesPerServing: Int? = 712,
    proteinGrams: Double? = 29.4,
    carbohydrateGrams: Double? = 63.8,
    fatGrams: Double? = 36.2,
    fibreGrams: Double? = 3.1,
    sodiumMilligrams: Double? = 980.0
  ) -> RemoteRecipeNutrition {
    RemoteRecipeNutrition(
      caloriesPerServing: caloriesPerServing,
      proteinGrams: proteinGrams,
      carbohydrateGrams: carbohydrateGrams,
      fatGrams: fatGrams,
      fibreGrams: fibreGrams,
      sodiumMilligrams: sodiumMilligrams
    )
  }
}

extension RemoteRecipeMedia {
  static func dummy(
    id: String? = "med-001-1",
    url: String? = "https://api.example.com/api/v1/images/carbonara-1.png",
    altText: String? = "Spaghetti alla Carbonara, photograph 1"
  ) -> RemoteRecipeMedia {
    RemoteRecipeMedia(id: id, url: url, altText: altText)
  }
}

extension RemoteIngredientGroup {
  static func dummy(
    id: String? = "grp-001-1",
    title: String? = nil,
    ingredients: [RemoteIngredient]? = [.dummy()]
  ) -> RemoteIngredientGroup {
    RemoteIngredientGroup(id: id, title: title, ingredients: ingredients)
  }
}

extension RemoteIngredient {
  static func dummy(
    id: String? = "ing-001-1-1",
    name: String? = "Spaghetti",
    quantity: Double? = 320.0,
    unit: String? = "gram",
    note: String? = nil,
    isOptional: Bool? = false
  ) -> RemoteIngredient {
    RemoteIngredient(id: id, name: name, quantity: quantity, unit: unit, note: note, isOptional: isOptional)
  }
}

extension RemoteRecipeStep {
  static func dummy(
    id: String? = "stp-001-1",
    number: Int? = 1,
    text: String? = "Bring a large pan of well-salted water to the boil.",
    imageUrl: String? = nil,
    durationSeconds: Int? = 600
  ) -> RemoteRecipeStep {
    RemoteRecipeStep(id: id, number: number, text: text, imageUrl: imageUrl, durationSeconds: durationSeconds)
  }
}
```

Create `Tests/Modules/Recipe/Services/RecipeMapperTests.swift`:

```swift
//
//  RecipeMapperTests.swift
//  Tests
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation
@testable import RecipeTest
import Testing

struct RecipeMapperTests {
  @Test
  func toDomain_mapsACompleteRecipe() throws {
    let sut = try #require(RecipeMapper.toDomain(from: .dummy()))

    #expect(sut.id == "rcp-001")
    #expect(sut.title == "Spaghetti alla Carbonara")
    #expect(sut.fullDescription == "The whole dish turns on one trick.")
    #expect(sut.servings == 4)
    #expect(sut.prepTimeMinutes == 10)
    #expect(sut.cookTimeMinutes == 15)
    #expect(sut.totalTimeMinutes == 25)
    #expect(sut.difficulty == .medium)
    #expect(sut.cuisine == "italian")
    #expect(sut.mealType == "dinner")
    #expect(sut.allergens == ["gluten", "eggs"])
    #expect(sut.dietaryAttributes == [])
  }

  @Test
  func toDomain_withoutAnID_returnsNil() {
    #expect(RecipeMapper.toDomain(from: .dummy(id: nil)) == nil)
  }

  @Test
  func toDomain_withoutATitle_returnsNil() {
    #expect(RecipeMapper.toDomain(from: .dummy(title: nil)) == nil)
  }

  @Test
  func toDomain_mapsTheAuthor() throws {
    let sut = try #require(RecipeMapper.toDomain(from: .dummy()))
    let author = try #require(sut.author)

    #expect(author.id == "aut-02")
    #expect(author.name == "Tobias Lindqvist")
    #expect(author.avatarURL?.absoluteString.hasSuffix("author-aut-02.png") == true)
  }

  /// Author and nutrition are the only relations the API ever sends as null.
  @Test
  func toDomain_withoutAuthorOrNutrition_keepsTheRecipe() throws {
    let sut = try #require(RecipeMapper.toDomain(from: .dummy(author: nil, nutrition: nil)))

    #expect(sut.author == nil)
    #expect(sut.nutrition == nil)
    #expect(sut.id == "rcp-001")
  }

  /// An author row with no name is not an author. The recipe survives without one.
  @Test
  func toDomain_withAnUnusableAuthor_keepsTheRecipe() throws {
    let sut = try #require(RecipeMapper.toDomain(from: .dummy(author: .dummy(name: nil))))

    #expect(sut.author == nil)
    #expect(sut.id == "rcp-001")
  }

  @Test
  func toDomain_mapsNutrition() throws {
    let sut = try #require(RecipeMapper.toDomain(from: .dummy()))
    let nutrition = try #require(sut.nutrition)

    #expect(nutrition.caloriesPerServing == 712)
    #expect(nutrition.proteinGrams == 29.4)
    #expect(nutrition.sodiumMilligrams == 980.0)
  }

  @Test
  func toDomain_dropsGalleryEntriesWithAnUnusableURL() throws {
    let gallery: [RemoteRecipeMedia] = [.dummy(id: "med-1"), .dummy(id: "med-2", url: nil)]

    let sut = try #require(RecipeMapper.toDomain(from: .dummy(gallery: gallery)))

    #expect(sut.gallery.map(\.id) == ["med-1"])
  }

  @Test
  func toDomain_mapsIngredientGroupsAndTheirIngredients() throws {
    let group = RemoteIngredientGroup.dummy(
      title: "For the sauce",
      ingredients: [.dummy(id: "ing-1", name: "Spaghetti"), .dummy(id: "ing-2", name: "Pecorino", unit: nil)]
    )

    let sut = try #require(RecipeMapper.toDomain(from: .dummy(ingredientGroups: [group])))

    #expect(sut.ingredientGroups.count == 1)
    #expect(sut.ingredientGroups.first?.title == "For the sauce")
    #expect(sut.ingredientGroups.first?.ingredients.map(\.name) == ["Spaghetti", "Pecorino"])
    #expect(sut.ingredientGroups.first?.ingredients.last?.unit == nil)
  }

  @Test
  func toDomain_dropsIngredientsWithNoName() throws {
    let group = RemoteIngredientGroup.dummy(
      ingredients: [.dummy(id: "ing-1", name: "Spaghetti"), .dummy(id: "ing-2", name: nil)]
    )

    let sut = try #require(RecipeMapper.toDomain(from: .dummy(ingredientGroups: [group])))

    #expect(sut.ingredientGroups.first?.ingredients.map(\.id) == ["ing-1"])
  }

  /// A group whose ingredients all failed would render as a bare heading with nothing
  /// under it. Drop it instead.
  @Test
  func toDomain_dropsAGroupLeftWithNoIngredients() throws {
    let empty = RemoteIngredientGroup.dummy(id: "grp-empty", ingredients: [.dummy(name: nil)])
    let good = RemoteIngredientGroup.dummy(id: "grp-good")

    let sut = try #require(RecipeMapper.toDomain(from: .dummy(ingredientGroups: [empty, good])))

    #expect(sut.ingredientGroups.map(\.id) == ["grp-good"])
  }

  /// Display order must come from `number`, not from the order the payload happens to
  /// list them in.
  @Test
  func toDomain_ordersStepsByNumber() throws {
    let steps: [RemoteRecipeStep] = [
      .dummy(id: "stp-3", number: 3),
      .dummy(id: "stp-1", number: 1),
      .dummy(id: "stp-2", number: 2),
    ]

    let sut = try #require(RecipeMapper.toDomain(from: .dummy(steps: steps)))

    #expect(sut.steps.map(\.id) == ["stp-1", "stp-2", "stp-3"])
  }

  @Test
  func toDomain_dropsStepsMissingTheirNumberOrText() throws {
    let steps: [RemoteRecipeStep] = [
      .dummy(id: "stp-1", number: 1),
      .dummy(id: "stp-2", number: nil),
      .dummy(id: "stp-3", number: 3, text: nil),
    ]

    let sut = try #require(RecipeMapper.toDomain(from: .dummy(steps: steps)))

    #expect(sut.steps.map(\.id) == ["stp-1"])
  }

  @Test
  func toDomain_parsesTheUpdatedAtTimestamp() throws {
    let sut = try #require(RecipeMapper.toDomain(from: .dummy()))
    let updatedAt = try #require(sut.updatedAt)

    #expect(updatedAt == DateFormatter.iso8601.date(from: "2026-07-01T07:07:00.000Z"))
  }

  /// One unparseable timestamp costs that field, not the recipe. This is the reason the
  /// DTO keeps it as a String instead of using a decoder date strategy.
  @Test
  func toDomain_withAnUnparseableTimestamp_keepsTheRecipe() throws {
    let sut = try #require(RecipeMapper.toDomain(from: .dummy(updatedAt: "last Tuesday")))

    #expect(sut.updatedAt == nil)
    #expect(sut.id == "rcp-001")
  }

  @Test
  func toDomain_withEveryOptionalRelationAbsent_fillsWithEmptyCollections() throws {
    let remote = RemoteRecipe.dummy(
      shortDescription: nil,
      fullDescription: nil,
      tags: nil,
      dietaryAttributes: nil,
      allergens: nil,
      author: nil,
      nutrition: nil,
      gallery: nil,
      ingredientGroups: nil,
      steps: nil
    )

    let sut = try #require(RecipeMapper.toDomain(from: remote))

    #expect(sut.shortDescription == "")
    #expect(sut.fullDescription == "")
    #expect(sut.tags == [])
    #expect(sut.dietaryAttributes == [])
    #expect(sut.allergens == [])
    #expect(sut.gallery == [])
    #expect(sut.ingredientGroups == [])
    #expect(sut.steps == [])
  }
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run the `Tests/RecipeMapperTests` suite.
Expected: compile failure — `cannot find 'RecipeMapper' in scope`.

- [ ] **Step 3: Write the domain models**

Create `RecipeTest/Modules/Recipe/Models/Domain/RecipeAuthor.swift`:

```swift
//
//  RecipeAuthor.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

nonisolated struct RecipeAuthor: Equatable, Identifiable {
  let id: String
  let name: String
  let avatarURL: URL?
  let profileURL: URL?
}
```

Create `RecipeTest/Modules/Recipe/Models/Domain/RecipeNutrition.swift`:

```swift
//
//  RecipeNutrition.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

/// Every figure is optional: the API sends the block or omits it, and a partial block
/// is a real shape — a recipe can carry calories without a fibre figure.
nonisolated struct RecipeNutrition: Equatable {
  let caloriesPerServing: Int?
  let proteinGrams: Double?
  let carbohydrateGrams: Double?
  let fatGrams: Double?
  let fibreGrams: Double?
  let sodiumMilligrams: Double?
}
```

Create `RecipeTest/Modules/Recipe/Models/Domain/RecipeMedia.swift`:

```swift
//
//  RecipeMedia.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

/// A gallery photograph. `url` is non-optional — an image with nowhere to load from is
/// not a gallery entry, so the mapper drops it rather than carrying an empty slot.
nonisolated struct RecipeMedia: Equatable, Identifiable {
  let id: String
  let url: URL
  let altText: String?
}
```

Create `RecipeTest/Modules/Recipe/Models/Domain/RecipeStep.swift`:

```swift
//
//  RecipeStep.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

/// One instruction. `number` drives display order — the mapper sorts on it rather than
/// trusting the order the payload arrived in.
nonisolated struct RecipeStep: Equatable, Identifiable {
  let id: String
  let number: Int
  let text: String
  let imageURL: URL?
  let durationSeconds: Int?
}
```

Create `RecipeTest/Modules/Recipe/Models/Domain/RecipeIngredientGroup.swift`:

```swift
//
//  RecipeIngredientGroup.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

/// A named section of an ingredient list — "For the béchamel", and so on.
///
/// `title` is optional because a recipe with a single list leaves it null: that means
/// "one unnamed list", not a missing value.
nonisolated struct RecipeIngredientGroup: Equatable, Identifiable {
  let id: String
  let title: String?
  let ingredients: [RecipeIngredient]
}

/// Lives with the group because an ingredient only exists inside one.
///
/// `quantity` and `unit` are both optional and independent: "6 egg yolks" has a quantity
/// and no unit, "salt, as required" has neither.
nonisolated struct RecipeIngredient: Equatable, Identifiable {
  let id: String
  let name: String
  let quantity: Double?
  let unit: String?
  let note: String?
  let isOptional: Bool
}
```

Create `RecipeTest/Modules/Recipe/Models/Domain/Recipe.swift`:

```swift
//
//  Recipe.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

/// A full recipe, as the app uses it.
///
/// Carries the summary's fields as well as the detail's, so a detail screen reached
/// without a preceding list fetch needs nothing else.
nonisolated struct Recipe: Equatable, Identifiable {
  let id: String
  let title: String
  let shortDescription: String
  let fullDescription: String
  let heroImageURL: URL?
  let totalTimeMinutes: Int?
  let prepTimeMinutes: Int?
  let cookTimeMinutes: Int?
  let servings: Int?
  let difficulty: RecipeDifficulty?
  let cuisine: String?
  let mealType: String?
  let tags: [String]
  let dietaryAttributes: [String]
  let allergens: [String]
  let rating: Double
  let ratingCount: Int
  let updatedAt: Date?
  let author: RecipeAuthor?
  let nutrition: RecipeNutrition?
  let gallery: [RecipeMedia]
  let ingredientGroups: [RecipeIngredientGroup]
  let steps: [RecipeStep]
}
```

- [ ] **Step 4: Write the mapper**

Create `RecipeTest/Modules/Recipe/Services/RecipeMapper.swift`:

```swift
//
//  RecipeMapper.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

/// Turns a `RemoteRecipe` into a `Recipe`.
///
/// Each nested relation gets its own helper below with its own idea of what makes an
/// entry unusable. The rule throughout: drop the smallest thing that is broken. A
/// gallery photo with no URL costs that photo, an ingredient with no name costs that
/// ingredient, and only a missing id or title costs the whole recipe.
nonisolated enum RecipeMapper {
  static func toDomain(from remote: RemoteRecipe) -> Recipe? {
    guard
      let id = remote.id, !id.isEmpty,
      let title = remote.title, !title.isEmpty
    else {
      return nil
    }

    return Recipe(
      id: id,
      title: title,
      shortDescription: remote.shortDescription ?? "",
      fullDescription: remote.fullDescription ?? "",
      heroImageURL: parseURL(remote.heroImageUrl),
      totalTimeMinutes: remote.totalTimeMinutes,
      prepTimeMinutes: remote.prepTimeMinutes,
      cookTimeMinutes: remote.cookTimeMinutes,
      servings: remote.servings,
      difficulty: remote.difficulty.flatMap { RecipeDifficulty(rawValue: $0) },
      cuisine: remote.cuisine,
      mealType: remote.mealType,
      tags: remote.tags ?? [],
      dietaryAttributes: remote.dietaryAttributes ?? [],
      allergens: remote.allergens ?? [],
      rating: remote.rating ?? 0,
      ratingCount: remote.ratingCount ?? 0,
      updatedAt: remote.updatedAt.flatMap { DateFormatter.iso8601.date(from: $0) },
      author: remote.author.flatMap { mapAuthor(from: $0) },
      nutrition: remote.nutrition.map { mapNutrition(from: $0) },
      gallery: (remote.gallery ?? []).compactMap { mapMedia(from: $0) },
      ingredientGroups: (remote.ingredientGroups ?? []).compactMap { mapGroup(from: $0) },
      steps: (remote.steps ?? [])
        .compactMap { mapStep(from: $0) }
        .sorted { $0.number < $1.number }
    )
  }
}

// MARK: - Relations

private nonisolated extension RecipeMapper {
  static func parseURL(_ string: String?) -> URL? {
    string.flatMap { URL(string: $0) }
  }

  /// An author with no name has nothing to show, so the recipe goes out without one.
  static func mapAuthor(from remote: RemoteRecipeAuthor) -> RecipeAuthor? {
    guard
      let id = remote.id, !id.isEmpty,
      let name = remote.name, !name.isEmpty
    else {
      return nil
    }

    return RecipeAuthor(
      id: id,
      name: name,
      avatarURL: parseURL(remote.avatarUrl),
      profileURL: parseURL(remote.profileUrl)
    )
  }

  /// Never fails: every figure is independently optional, and a block with only some of
  /// them filled in is a shape the API really sends.
  static func mapNutrition(from remote: RemoteRecipeNutrition) -> RecipeNutrition {
    RecipeNutrition(
      caloriesPerServing: remote.caloriesPerServing,
      proteinGrams: remote.proteinGrams,
      carbohydrateGrams: remote.carbohydrateGrams,
      fatGrams: remote.fatGrams,
      fibreGrams: remote.fibreGrams,
      sodiumMilligrams: remote.sodiumMilligrams
    )
  }

  static func mapMedia(from remote: RemoteRecipeMedia) -> RecipeMedia? {
    guard
      let id = remote.id, !id.isEmpty,
      let url = parseURL(remote.url)
    else {
      return nil
    }

    return RecipeMedia(id: id, url: url, altText: remote.altText)
  }

  /// A group left with no usable ingredients would render as a heading with nothing
  /// under it, so it is dropped rather than shown empty.
  static func mapGroup(from remote: RemoteIngredientGroup) -> RecipeIngredientGroup? {
    guard let id = remote.id, !id.isEmpty else { return nil }

    let ingredients = (remote.ingredients ?? []).compactMap { mapIngredient(from: $0) }

    guard !ingredients.isEmpty else { return nil }

    return RecipeIngredientGroup(id: id, title: remote.title, ingredients: ingredients)
  }

  static func mapIngredient(from remote: RemoteIngredient) -> RecipeIngredient? {
    guard
      let id = remote.id, !id.isEmpty,
      let name = remote.name, !name.isEmpty
    else {
      return nil
    }

    return RecipeIngredient(
      id: id,
      name: name,
      quantity: remote.quantity,
      unit: remote.unit,
      note: remote.note,
      isOptional: remote.isOptional ?? false
    )
  }

  /// A step with no number cannot be placed in the sequence, and one with no text has
  /// nothing to instruct. Either way it is not a step.
  static func mapStep(from remote: RemoteRecipeStep) -> RecipeStep? {
    guard
      let id = remote.id, !id.isEmpty,
      let number = remote.number,
      let text = remote.text, !text.isEmpty
    else {
      return nil
    }

    return RecipeStep(
      id: id,
      number: number,
      text: text,
      imageURL: parseURL(remote.imageUrl),
      durationSeconds: remote.durationSeconds
    )
  }
}
```

- [ ] **Step 5: Run the tests to verify they pass**

Run the `Tests/RecipeMapperTests` suite. Expected: 16 tests pass.

- [ ] **Step 6: Format, then commit**

```bash
swiftformat RecipeTest Tests UITests && swiftformat RecipeTest Tests UITests --lint
git add RecipeTest/Modules/Recipe Tests/Mocks Tests/Modules/Recipe
git commit -m "feat(recipe): add the Recipe detail model and its mapper

Each relation decides for itself what is unusable, so the smallest broken thing
is what gets dropped: a photo with no URL costs that photo, an ingredient with
no name costs that ingredient, and only a missing id or title costs the recipe.
Steps are ordered by number rather than by payload order."
```

---

### Task 5: Teach the mock transport about recipes

The router only slices arrays today. A detail endpoint needs to pull one row out of the
collection fixture and answer with an object.

**Files:**
- Modify: `RecipeTest/Modules/Core/Clients/API/Mock/MockEndpoint.swift` (full rewrite)
- Modify: `RecipeTest/Modules/Core/Clients/API/Mock/MockAPIRouter.swift:62-115` (the `response(for:)` body — the `.empty` branch around line 85, and the block after `fixtureRows` around line 99)
- Test: `Tests/Modules/Core/Clients/API/Mock/MockEndpointTests.swift`
- Test: `Tests/Modules/Core/Clients/API/Mock/MockAPIRouterTests.swift`

**Interfaces:**
- Consumes: the shipped `RecipeTest/Resources/MockData/recipes.json` (36 rows, ids `rcp-001` … `rcp-036`).
- Produces: `MockEndpoint.recipes`, `MockEndpoint.recipe(id:)`, `MockEndpoint.fixtureRowID`. Task 6 drives both endpoints through a real `APIClient`.

> **Bundle note.** `MockAPIRouter`'s default bundle is `.main`. The `Tests` target is hosted by the app (`TEST_HOST` / `BUNDLE_LOADER` are set), so `Bundle.main` inside a unit test *is* the app bundle and `recipes.json` resolves. If a test ever fails with `RouterError.missingFixture("recipes")`, that assumption broke — pass a bundle explicitly rather than copying the fixture.

- [ ] **Step 1: Write the failing tests**

Create `Tests/Modules/Core/Clients/API/Mock/MockEndpointTests.swift`:

```swift
//
//  MockEndpointTests.swift
//  Tests
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation
@testable import RecipeTest
import Testing

struct MockEndpointTests {
  @Test
  func match_theRecipesCollection() {
    #expect(MockEndpoint.match(path: "/api/v1/recipes", method: "GET") == .recipes)
  }

  @Test
  func match_aRecipeByID() {
    #expect(MockEndpoint.match(path: "/api/v1/recipes/rcp-001", method: "GET") == .recipe(id: "rcp-001"))
  }

  @Test
  func match_anImage() {
    #expect(MockEndpoint.match(path: "/api/v1/images/carbonara.png", method: "GET") == .image(seed: "carbonara"))
  }

  /// An unregistered path is a 404 rather than a silent success, so a typo in a resource
  /// path fails the way it would against a real backend.
  @Test
  func match_anUnknownPath_returnsNil() {
    #expect(MockEndpoint.match(path: "/api/v1/authors", method: "GET") == nil)
  }

  @Test
  func match_aNonGETRequest_returnsNil() {
    #expect(MockEndpoint.match(path: "/api/v1/recipes", method: "POST") == nil)
  }

  @Test
  func fixtureRowID_isSetOnlyForADetailEndpoint() {
    #expect(MockEndpoint.recipe(id: "rcp-001").fixtureRowID == "rcp-001")
    #expect(MockEndpoint.recipes.fixtureRowID == nil)
  }

  @Test
  func isPaginated_isTrueOnlyForTheCollection() {
    #expect(MockEndpoint.recipes.isPaginated)
    #expect(MockEndpoint.recipe(id: "rcp-001").isPaginated == false)
  }

  @Test
  func fixtureName_isTheSharedCollectionForBothRecipeEndpoints() {
    #expect(MockEndpoint.recipes.fixtureName == "recipes")
    #expect(MockEndpoint.recipe(id: "rcp-001").fixtureName == "recipes")
  }
}
```

Create `Tests/Modules/Core/Clients/API/Mock/MockAPIRouterTests.swift`:

```swift
//
//  MockAPIRouterTests.swift
//  Tests
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation
@testable import RecipeTest
import Testing

/// Reads the shipped `recipes.json` out of the host app bundle, so these assertions are
/// against what the demo build actually serves.
struct MockAPIRouterTests {
  @Test
  func recipes_returnsAPageOfRows() throws {
    let result = try makeSUT().response(for: makeRequest("/api/v1/recipes?page=1&per_page=5"))

    #expect(result.status == 200)

    let envelope = try decode(result.body)
    #expect(rows(in: envelope).count == 5)
    #expect(rows(in: envelope).first?["id"] as? String == "rcp-001")

    let meta = try #require(envelope["meta"] as? [String: Any])
    #expect(meta["total"] as? Int == 36)
    #expect(meta["current_page"] as? Int == 1)
    #expect(meta["last_page"] as? Int == 8)
  }

  @Test
  func recipes_secondPage_startsAfterTheFirst() throws {
    let result = try makeSUT().response(for: makeRequest("/api/v1/recipes?page=2&per_page=5"))

    let envelope = try decode(result.body)
    #expect(rows(in: envelope).first?["id"] as? String == "rcp-006")
  }

  /// A page past the end is an empty page, not an error — which is what a real paginated
  /// API does. The meta still reports the page that was asked for, so `hasLoadedAllData`
  /// is what has to stop the pager.
  @Test
  func recipes_pastTheLastPage_returnsAnEmptyPage() throws {
    let result = try makeSUT().response(for: makeRequest("/api/v1/recipes?page=99&per_page=5"))

    #expect(result.status == 200)

    let envelope = try decode(result.body)
    #expect(rows(in: envelope).isEmpty)

    let meta = try #require(envelope["meta"] as? [String: Any])
    #expect(meta["current_page"] as? Int == 99)
    #expect(meta["last_page"] as? Int == 8)
  }

  @Test
  func recipe_returnsTheMatchingRowAsAnObject() throws {
    let result = try makeSUT().response(for: makeRequest("/api/v1/recipes/rcp-007"))

    #expect(result.status == 200)

    let envelope = try decode(result.body)
    let data = try #require(envelope["data"] as? [String: Any])
    #expect(data["id"] as? String == "rcp-007")
    #expect(data["steps"] != nil)
    // A single resource carries no pagination.
    #expect(envelope.keys.contains("meta") == false)
  }

  /// A 404, not an empty array the caller would then fail to decode into a recipe.
  @Test
  func recipe_withAnUnknownID_returns404() throws {
    let result = try makeSUT().response(for: makeRequest("/api/v1/recipes/rcp-999"))

    #expect(result.status == 404)

    let envelope = try decode(result.body)
    #expect(envelope["http_status"] as? Int == 404)
  }

  @Test
  func recipe_inEmptyFailureMode_returns404() throws {
    let result = try makeSUT(failureMode: .empty).response(for: makeRequest("/api/v1/recipes/rcp-001"))

    #expect(result.status == 404)
  }

  @Test
  func recipes_inEmptyFailureMode_returnsZeroRows() throws {
    let result = try makeSUT(failureMode: .empty).response(for: makeRequest("/api/v1/recipes?per_page=5"))

    #expect(result.status == 200)

    let envelope = try decode(result.body)
    #expect(rows(in: envelope).isEmpty)
    #expect((envelope["meta"] as? [String: Any])?["total"] as? Int == 0)
  }

  @Test
  func recipes_inServerErrorMode_returns500() throws {
    let result = try makeSUT(failureMode: .serverError).response(for: makeRequest("/api/v1/recipes"))

    #expect(result.status == 500)
  }

  @Test
  func anUnregisteredPath_returns404() throws {
    let result = try makeSUT().response(for: makeRequest("/api/v1/authors"))

    #expect(result.status == 404)
  }
}

// MARK: - Helpers

private extension MockAPIRouterTests {
  func makeSUT(failureMode: MockAPIRouter.FailureMode = .none) -> MockAPIRouter {
    MockAPIRouter(configuration: .init(latency: .zero, failureMode: failureMode))
  }

  func makeRequest(_ path: String) -> URLRequest {
    URLRequest(url: URL(string: "https://api.example.com\(path)")!)
  }

  func decode(_ body: Data) throws -> [String: Any] {
    try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
  }

  func rows(in envelope: [String: Any]) -> [[String: Any]] {
    envelope["data"] as? [[String: Any]] ?? []
  }
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run the `Tests/MockEndpointTests` and `Tests/MockAPIRouterTests` suites.
Expected: compile failure — `type 'MockEndpoint' has no member 'recipes'`.

- [ ] **Step 3: Rewrite `MockEndpoint`**

Replace the whole of `RecipeTest/Modules/Core/Clients/API/Mock/MockEndpoint.swift`:

```swift
//
//  MockEndpoint.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

/// One case per endpoint the mock transport knows how to answer.
///
/// Add a case and a fixture file when you add an endpoint; an unmatched path deliberately
/// produces a 404 rather than silently succeeding, so a typo in a resource path fails the
/// same way it would against a real backend.
nonisolated enum MockEndpoint: Equatable {
  /// A placeholder photo. The seed is the filename, so a given URL gets a stable image.
  case image(seed: String)

  /// `GET recipes` — a page of the recipe list.
  case recipes

  /// `GET recipes/{id}` — one recipe, sliced out of the same fixture the list uses.
  case recipe(id: String)

  /// Matches on the trailing path components, so the versioned prefix (`/api/v1/...`)
  /// does not have to be repeated here.
  static func match(path: String, method: String) -> MockEndpoint? {
    let components = path.split(separator: "/").map(String.init)
    let resource = components.last ?? ""

    guard method.uppercased() == "GET" else { return nil }

    if components.dropLast().last == "images" {
      return .image(seed: (resource as NSString).deletingPathExtension)
    }

    // Checked before the collection below: `recipes/rcp-001` and `recipes` differ only
    // in whether a resource name sits in front of the last component.
    if components.dropLast().last == "recipes" {
      return .recipe(id: resource)
    }

    switch resource {
    case "recipes":
      return .recipes

    default:
      return nil
    }
  }

  /// Both recipe endpoints read the same file — a detail is one row of the collection,
  /// not a second copy of it.
  var fixtureName: String? {
    switch self {
    case .image:
      nil

    case .recipes,
         .recipe:
      "recipes"
    }
  }

  var isPaginated: Bool {
    switch self {
    case .recipes:
      true

    case .image,
         .recipe:
      false
    }
  }

  /// The id of the single row this endpoint answers with, when it addresses one resource
  /// rather than a collection. Nil for a collection endpoint.
  var fixtureRowID: String? {
    switch self {
    case let .recipe(id):
      id

    case .image,
         .recipes:
      nil
    }
  }

  var contentType: String {
    switch self {
    case .image:
      "image/png"

    case .recipes,
         .recipe:
      "application/json"
    }
  }
}
```

- [ ] **Step 4: Add the single-row lookup to `MockAPIRouter`**

Two edits inside `response(for:)`. First, in the `.empty` branch of the `failureMode`
switch, insert this **before** the existing `let perPage = intQuery(...)` line:

```swift
      // "No rows" for a request that addresses one resource means that resource is not
      // there. An empty array would hand the caller something it cannot decode.
      if let rowID = endpoint.fixtureRowID {
        let body = try envelope(status: 404, message: "No recipe with id \(rowID)", data: nil, meta: nil)
        return (404, body, endpoint.contentType)
      }
```

Second, immediately after `let rows = try fixtureRows(named: fixtureName)` and **before**
the existing `guard endpoint.isPaginated else { ... }`, insert:

```swift
    // A detail endpoint: one row out of the collection fixture, enveloped as an object
    // rather than an array. An id nothing matches is a 404, exactly as a real backend
    // would answer it.
    if let rowID = endpoint.fixtureRowID {
      guard let row = rows.first(where: { $0["id"] as? String == rowID }) else {
        let body = try envelope(status: 404, message: "No recipe with id \(rowID)", data: nil, meta: nil)
        return (404, body, endpoint.contentType)
      }

      return try (200, envelope(status: 200, message: "OK", data: row, meta: nil), endpoint.contentType)
    }
```

Nothing else in the file changes.

- [ ] **Step 5: Run the tests to verify they pass**

Run both suites. Expected: 17 tests pass.

- [ ] **Step 6: Format, then commit**

```bash
swiftformat RecipeTest Tests UITests && swiftformat RecipeTest Tests UITests --lint
git add RecipeTest/Modules/Core/Clients/API/Mock Tests/Modules/Core/Clients/API/Mock
git commit -m "feat(core): answer recipe list and detail from the mock transport

The router only sliced arrays. A detail endpoint now pulls its row out of the
same collection fixture and envelopes it as an object; an id nothing matches is
a 404, so a wrong id fails the way it would against a real backend."
```

---

### Task 6: The recipe API client

**Files:**
- Create: `RecipeTest/Modules/Recipe/Clients/API/RecipeAPIProtocol.swift`
- Create: `RecipeTest/Modules/Recipe/Clients/API/APIClient+Recipe.swift`
- Test: `Tests/Modules/Recipe/Clients/API/APIClientRecipeTests.swift`

**Interfaces:**
- Consumes: `APIClient.request(_:method:version:parameters:encoding:headers:)`, `decodeModel` / `decodeModelWithMeta` (Task 1), `MockEndpoint` (Task 5), `RemoteRecipeSummary` / `RemoteRecipe` (Task 2).
- Produces: `RecipeAPIProtocol` with `getRecipes(page: Int, perPage: Int) async throws -> ([RemoteRecipeSummary], RemotePaginationMetaInfo)` and `getRecipe(id: String) async throws -> RemoteRecipe`, plus `APIClient`'s conformance. Task 7 depends on the protocol only.

These tests go through the real client, so they are the ones that prove the production
decode path — `APIResponse.decodedValue()` uses `GenericAPIModel.decoder()`, not
`RemoteRecipe.decoder()`, and Task 2's tests would not have caught a difference.

- [ ] **Step 1: Write the failing test**

Create `Tests/Modules/Recipe/Clients/API/APIClientRecipeTests.swift`:

```swift
//
//  APIClientRecipeTests.swift
//  Tests
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation
@testable import RecipeTest
import Testing

/// Serialized: `MockURLProtocol.router` is process-global, and Swift Testing runs suites
/// in parallel. Two suites configuring it at once would flake against each other.
@Suite(.serialized)
struct APIClientRecipeTests {
  @Test
  func getRecipes_returnsThePageAndItsMeta() async throws {
    let sut = makeSUT()

    let (recipes, meta) = try await sut.getRecipes(page: 1, perPage: 5)

    #expect(recipes.count == 5)
    #expect(recipes.first?.id == "rcp-001")
    #expect(meta.currentPage == 1)
    #expect(meta.perPage == 5)
    #expect(meta.total == 36)
    #expect(meta.hasLoadedAllData == false)
  }

  /// The production path decodes through `GenericAPIModel.decoder()`, not through
  /// `RemoteRecipeSummary.decoder()`. This is what proves the snake_case keys survive it.
  @Test
  func getRecipes_decodesSnakeCaseKeysThroughTheClient() async throws {
    let sut = makeSUT()

    let (recipes, _) = try await sut.getRecipes(page: 1, perPage: 1)
    let first = try #require(recipes.first)

    #expect(first.heroImageUrl?.hasSuffix("spaghetti-alla-carbonara.png") == true)
    #expect(first.totalTimeMinutes == 25)
    #expect(first.ratingCount == 2147)
  }

  /// Proves `page` and `per_page` actually reach the query string — the router slices on
  /// them, so a wrong parameter name would come back as page 1 every time.
  @Test
  func getRecipes_sendsThePageParameters() async throws {
    let sut = makeSUT()

    let (recipes, meta) = try await sut.getRecipes(page: 2, perPage: 5)

    #expect(recipes.first?.id == "rcp-006")
    #expect(meta.currentPage == 2)
  }

  @Test
  func getRecipes_pastTheLastPage_returnsAnEmptyPage() async throws {
    let sut = makeSUT()

    let (recipes, meta) = try await sut.getRecipes(page: 99, perPage: 5)

    #expect(recipes.isEmpty)
    #expect(meta.hasLoadedAllData)
  }

  @Test
  func getRecipe_returnsTheFullRecipe() async throws {
    let sut = makeSUT()

    let recipe = try await sut.getRecipe(id: "rcp-001")

    #expect(recipe.id == "rcp-001")
    #expect(recipe.title == "Spaghetti alla Carbonara")
    #expect(recipe.steps?.isEmpty == false)
    #expect(recipe.ingredientGroups?.isEmpty == false)
    #expect(recipe.author?.name == "Tobias Lindqvist")
  }

  /// A 404 must arrive as a typed request failure carrying the status, not as a decoding
  /// error on the error body.
  @Test
  func getRecipe_withAnUnknownID_throwsAFailedRequest() async throws {
    let sut = makeSUT()

    await #expect(throws: APIClientError.self) {
      _ = try await sut.getRecipe(id: "rcp-999")
    }
  }

  @Test
  func getRecipes_inServerErrorMode_throwsAndReportsTheError() async throws {
    let recorder = ErrorRecorder()
    let sut = makeSUT(failureMode: .serverError, onError: recorder.record)

    await #expect(throws: APIClientError.self) {
      _ = try await sut.getRecipes(page: 1, perPage: 5)
    }

    #expect(recorder.count > 0)
  }
}

// MARK: - Helpers

private extension APIClientRecipeTests {
  func makeSUT(
    failureMode: MockAPIRouter.FailureMode = .none,
    onError: @escaping SendableErrorResult = { _ in }
  ) -> APIClient {
    MockURLProtocol.router = MockAPIRouter(
      configuration: .init(latency: .zero, failureMode: failureMode)
    )

    return APIClient(
      sessionManager: .mocked(),
      baseURL: URL(string: "https://api.example.com/api")!,
      version: "v1",
      onError: onError
    )
  }
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run the `Tests/APIClientRecipeTests` suite.
Expected: compile failure — `value of type 'APIClient' has no member 'getRecipes'`.

- [ ] **Step 3: Write the protocol**

Create `RecipeTest/Modules/Recipe/Clients/API/RecipeAPIProtocol.swift`:

```swift
//
//  RecipeAPIProtocol.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

/// The recipe endpoints, owned by this feature rather than by Core.
///
/// `APIClient` conforms to it in `APIClient+Recipe`. That indirection is what gives the
/// service a seam: `RecipeService` depends on this protocol, so a test substitutes
/// `MockRecipeAPI` and never goes near `URLSession`.
///
/// Speaks the wire's vocabulary — `Int` page numbers and remote DTOs. Translating the
/// app's `Page` into `page` and `per_page` is the service's job, not this layer's.
nonisolated protocol RecipeAPIProtocol: Sendable {
  func getRecipes(page: Int, perPage: Int) async throws -> ([RemoteRecipeSummary], RemotePaginationMetaInfo)

  func getRecipe(id: String) async throws -> RemoteRecipe
}
```

- [ ] **Step 4: Write the conformance**

Create `RecipeTest/Modules/Recipe/Clients/API/APIClient+Recipe.swift`:

```swift
//
//  APIClient+Recipe.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Alamofire
import Foundation

nonisolated extension APIClient: RecipeAPIProtocol {
  func getRecipes(page: Int, perPage: Int) async throws -> ([RemoteRecipeSummary], RemotePaginationMetaInfo) {
    let response = try await request(
      "recipes",
      method: .get,
      parameters: [
        "page": page,
        "per_page": perPage,
      ],
      encoding: URLEncoding.default
    )

    return try decodeModelWithMeta(response)
  }

  func getRecipe(id: String) async throws -> RemoteRecipe {
    let response = try await request(
      "recipes/\(id)",
      method: .get,
      encoding: URLEncoding.default
    )

    return try decodeModel(response)
  }
}
```

- [ ] **Step 5: Run the tests to verify they pass**

Run the `Tests/APIClientRecipeTests` suite. Expected: 7 tests pass.

- [ ] **Step 6: Format, then commit**

```bash
swiftformat RecipeTest Tests UITests && swiftformat RecipeTest Tests UITests --lint
git add RecipeTest/Modules/Recipe/Clients Tests/Modules/Recipe/Clients
git commit -m "feat(recipe): add the recipe API client

The protocol is owned by the feature and APIClient conforms to it in an
extension, so the service can depend on the protocol rather than the class.
Tests drive it through the mock transport, which is what exercises the real
decode path: APIResponse decodes through GenericAPIModel's decoder, not the
DTO's own."
```

---

### Task 7: The service, and the test doubles it needs

The mock is scaffolding for this task's deliverable, so it is built here rather than in a
task of its own.

**Files:**
- Create: `Tests/Mocks/Support/MockAPICall.swift`
- Create: `Tests/Mocks/Modules/Recipe/Clients/API/MockRecipeAPI.swift`
- Create: `Tests/Mocks/Modules/Core/Models/DummyRemotePaginationMetaInfo.swift`
- Modify: `RecipeTest/Modules/Core/Models/Meta/Remote/RemotePaginationMetaInfo.swift` (add `Equatable`)
- Create: `RecipeTest/Modules/Recipe/Models/Domain/RecipeListPage.swift`
- Create: `RecipeTest/Modules/Recipe/Services/RecipeServiceProtocol.swift`
- Create: `RecipeTest/Modules/Recipe/Services/RecipeService.swift`
- Test: `Tests/Modules/Recipe/Services/RecipeServiceTests.swift`

**Interfaces:**
- Consumes: `RecipeAPIProtocol` (Task 6), `RecipeSummaryMapper` (Task 3), `RecipeMapper` (Task 4), `Page` and `PaginationMetaInfo` (existing Core), `AppServiceProtocol` (existing Core), `AppError` (existing Shared).
- Produces: `RecipeListPage(recipes:meta:)` with a forwarded `hasLoadedAllData`, `RecipeServiceProtocol` with `getRecipes(page: Page) async throws -> RecipeListPage` and `getRecipe(id: String) async throws -> Recipe`, `RecipeService(api:)`, and the reusable `MockAPICall`. Task 8 registers `RecipeService` in `AppContainer`.

- [ ] **Step 1: Build the reusable call recorder**

Create `Tests/Mocks/Support/MockAPICall.swift`:

```swift
//
//  MockAPICall.swift
//  Tests
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

/// Records the calls made to one endpoint of a mock API, and decides what it answers.
///
/// One of these per endpoint, rather than a flat bag of `xToReturn`, `xCallCount` and
/// `lastRequestedX` properties spread across the mock. That shape buys four things:
///
/// - each endpoint's stub and its recorded calls stay together, so two endpoints cannot
///   overwrite each other's "last requested" state;
/// - one endpoint can be made to fail while its neighbours keep answering;
/// - `responds` is here from the start, so a test needing page 2 to differ from page 1
///   does not get a lookup table bolted onto the mock;
/// - there is no `reset()` to keep in sync — a test builds a fresh mock.
///
/// `@unchecked Sendable` with one lock: the mock conforms to a `Sendable` protocol, and
/// an `async` call may resume on a different thread than it started on.
final class MockAPICall<Request, Response>: @unchecked Sendable {
  private enum Outcome {
    case success(Response)
    case failure(any Error)
    case handler((Request) async throws -> Response)
  }

  private let lock = NSLock()
  private var recorded: [Request] = []
  private var outcome: Outcome

  init(returning response: Response) {
    outcome = .success(response)
  }
}

// MARK: - Recorded calls

extension MockAPICall {
  var requests: [Request] {
    lock.withLock { recorded }
  }

  var callCount: Int {
    requests.count
  }

  var lastRequest: Request? {
    requests.last
  }

  var wasCalled: Bool {
    callCount > 0
  }
}

// MARK: - Stubbing

extension MockAPICall {
  /// Answer every call with this value.
  func returns(_ response: Response) {
    setOutcome(.success(response))
  }

  /// Fail every call with this error. Scoped to this endpoint — a sibling endpoint on the
  /// same mock goes on answering normally.
  func fails(with error: any Error) {
    setOutcome(.failure(error))
  }

  /// Answer each call from the request itself, for a test where the second page has to
  /// differ from the first.
  func responds(_ handler: @escaping (Request) async throws -> Response) {
    setOutcome(.handler(handler))
  }

  private func setOutcome(_ newValue: Outcome) {
    lock.withLock { outcome = newValue }
  }
}

// MARK: - Invocation

extension MockAPICall {
  /// Called by the mock's protocol method: records the request, then answers with
  /// whatever the test stubbed.
  func invoke(_ request: Request) async throws -> Response {
    let current: Outcome = lock.withLock {
      recorded.append(request)

      return outcome
    }

    switch current {
    case let .success(response):
      return response

    case let .failure(error):
      throw error

    case let .handler(handler):
      return try await handler(request)
    }
  }
}
```

- [ ] **Step 2: Build the mock API and the meta dummy**

Create `Tests/Mocks/Modules/Core/Models/DummyRemotePaginationMetaInfo.swift`:

```swift
//
//  DummyRemotePaginationMetaInfo.swift
//  Tests
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation
@testable import RecipeTest

extension RemotePaginationMetaInfo {
  static func dummy(
    total: Int = 1,
    perPage: Int = 10,
    from: Int? = 1,
    to: Int? = 1,
    currentPage: Int = 1,
    lastPage: Int = 1
  ) -> RemotePaginationMetaInfo {
    RemotePaginationMetaInfo(
      total: total,
      perPage: perPage,
      from: from,
      to: to,
      currentPage: currentPage,
      lastPage: lastPage
    )
  }
}
```

Create `Tests/Mocks/Modules/Recipe/Clients/API/MockRecipeAPI.swift`:

```swift
//
//  MockRecipeAPI.swift
//  Tests
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation
@testable import RecipeTest

/// A `RecipeAPIProtocol` double.
///
/// The class itself holds nothing but one `MockAPICall` per endpoint; everything a test
/// stubs or asserts goes through those. Immutable `let` properties of `Sendable` type, so
/// the `Sendable` conformance the protocol requires is checked rather than asserted.
final class MockRecipeAPI: RecipeAPIProtocol {
  /// Named rather than a tuple so `lastRequest` can be compared in one `#expect`.
  struct RecipesRequest: Equatable {
    let page: Int
    let perPage: Int
  }

  let recipes: MockAPICall<RecipesRequest, ([RemoteRecipeSummary], RemotePaginationMetaInfo)>
  let recipe: MockAPICall<String, RemoteRecipe>

  init(
    recipes: [RemoteRecipeSummary] = [.dummy()],
    meta: RemotePaginationMetaInfo = .dummy(),
    recipe: RemoteRecipe = .dummy()
  ) {
    self.recipes = MockAPICall(returning: (recipes, meta))
    self.recipe = MockAPICall(returning: recipe)
  }
}

// MARK: - RecipeAPIProtocol

extension MockRecipeAPI {
  func getRecipes(page: Int, perPage: Int) async throws -> ([RemoteRecipeSummary], RemotePaginationMetaInfo) {
    try await recipes.invoke(RecipesRequest(page: page, perPage: perPage))
  }

  func getRecipe(id: String) async throws -> RemoteRecipe {
    try await recipe.invoke(id)
  }
}
```

- [ ] **Step 3: Write the failing test**

Create `Tests/Modules/Recipe/Services/RecipeServiceTests.swift`:

```swift
//
//  RecipeServiceTests.swift
//  Tests
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation
@testable import RecipeTest
import Testing

struct RecipeServiceTests {
  @Test
  func getRecipes_translatesThePageIntoPageAndPerPage() async throws {
    let api = MockRecipeAPI()
    let sut = RecipeService(api: api)

    _ = try await sut.getRecipes(page: Page(index: 3, size: 20))

    #expect(api.recipes.callCount == 1)
    #expect(api.recipes.lastRequest == MockRecipeAPI.RecipesRequest(page: 3, perPage: 20))
  }

  @Test
  func getRecipes_mapsTheRowsIntoSummaries() async throws {
    let api = MockRecipeAPI(recipes: [.dummy(id: "rcp-001"), .dummy(id: "rcp-002")])
    let sut = RecipeService(api: api)

    let page = try await sut.getRecipes(page: Page(size: 10))

    #expect(page.recipes.map(\.id) == ["rcp-001", "rcp-002"])
    #expect(page.recipes.first?.title == "Spaghetti alla Carbonara")
  }

  /// One unusable row costs itself, not the nine good rows around it.
  @Test
  func getRecipes_dropsUnmappableRowsAndKeepsTheRest() async throws {
    let api = MockRecipeAPI(recipes: [.dummy(id: "rcp-001"), .dummy(id: nil), .dummy(id: "rcp-003")])
    let sut = RecipeService(api: api)

    let page = try await sut.getRecipes(page: Page(size: 10))

    #expect(page.recipes.map(\.id) == ["rcp-001", "rcp-003"])
  }

  @Test
  func getRecipes_carriesThePaginationMetaThrough() async throws {
    let api = MockRecipeAPI(meta: .dummy(total: 36, perPage: 5, currentPage: 2, lastPage: 8))
    let sut = RecipeService(api: api)

    let page = try await sut.getRecipes(page: Page(index: 2, size: 5))

    #expect(page.meta.currentPage == 2)
    #expect(page.meta.lastPage == 8)
    #expect(page.hasLoadedAllData == false)
  }

  /// A page past the end comes back empty with the page number that was asked for. A
  /// pager reading `hasLoadedAllData` must stop here rather than request page 100.
  @Test
  func getRecipes_pastTheLastPage_reportsEverythingLoaded() async throws {
    let api = MockRecipeAPI(
      recipes: [],
      meta: .dummy(total: 36, perPage: 5, from: nil, to: nil, currentPage: 99, lastPage: 8)
    )
    let sut = RecipeService(api: api)

    let page = try await sut.getRecipes(page: Page(index: 99, size: 5))

    #expect(page.recipes.isEmpty)
    #expect(page.hasLoadedAllData)
  }

  @Test
  func getRecipes_propagatesAnAPIError() async throws {
    let api = MockRecipeAPI()
    api.recipes.fails(with: AppError.noInternetConnection)
    let sut = RecipeService(api: api)

    await #expect(throws: AppError.self) {
      _ = try await sut.getRecipes(page: Page(size: 10))
    }
  }

  /// `responds` answers from the request, so page 2 differs from page 1 without a second
  /// mock or a lookup table.
  @Test
  func getRecipes_canBeStubbedPerPage() async throws {
    let api = MockRecipeAPI()
    api.recipes.responds { request in
      ([.dummy(id: "rcp-\(request.page)")], .dummy(currentPage: request.page))
    }
    let sut = RecipeService(api: api)

    let first = try await sut.getRecipes(page: Page(index: 1, size: 10))
    let second = try await sut.getRecipes(page: Page(index: 2, size: 10))

    #expect(first.recipes.first?.id == "rcp-1")
    #expect(second.recipes.first?.id == "rcp-2")
    #expect(api.recipes.requests.map(\.page) == [1, 2])
  }

  @Test
  func getRecipe_sendsTheID() async throws {
    let api = MockRecipeAPI()
    let sut = RecipeService(api: api)

    _ = try await sut.getRecipe(id: "rcp-007")

    #expect(api.recipe.lastRequest == "rcp-007")
    #expect(api.recipe.callCount == 1)
  }

  @Test
  func getRecipe_mapsTheRecipe() async throws {
    let api = MockRecipeAPI(recipe: .dummy(id: "rcp-007", title: "Chicken Katsu Curry"))
    let sut = RecipeService(api: api)

    let recipe = try await sut.getRecipe(id: "rcp-007")

    #expect(recipe.id == "rcp-007")
    #expect(recipe.title == "Chicken Katsu Curry")
    #expect(recipe.steps.isEmpty == false)
  }

  /// A detail screen with no recipe has nothing to show, so there is no partial result to
  /// degrade to — unlike a list, where a bad row is simply dropped.
  @Test
  func getRecipe_withAnUnmappableRow_throws() async throws {
    let api = MockRecipeAPI(recipe: .dummy(title: nil))
    let sut = RecipeService(api: api)

    await #expect(throws: AppError.self) {
      _ = try await sut.getRecipe(id: "rcp-001")
    }
  }

  @Test
  func getRecipe_propagatesAnAPIError() async throws {
    let api = MockRecipeAPI()
    api.recipe.fails(with: AppError.noInternetConnection)
    let sut = RecipeService(api: api)

    await #expect(throws: AppError.self) {
      _ = try await sut.getRecipe(id: "rcp-001")
    }
  }

  /// Stubs are per endpoint: a failing list must not take the detail call down with it.
  @Test
  func getRecipe_succeedsWhileTheListEndpointIsFailing() async throws {
    let api = MockRecipeAPI()
    api.recipes.fails(with: AppError.noInternetConnection)
    let sut = RecipeService(api: api)

    let recipe = try await sut.getRecipe(id: "rcp-001")

    #expect(recipe.id == "rcp-001")
    #expect(api.recipes.wasCalled == false)
  }
}
```

- [ ] **Step 4: Run the tests to verify they fail**

Run the `Tests/RecipeServiceTests` suite.
Expected: compile failure — `cannot find 'RecipeService' in scope`.

- [ ] **Step 5: Make `RemotePaginationMetaInfo` equatable**

In `RecipeTest/Modules/Core/Models/Meta/Remote/RemotePaginationMetaInfo.swift`, change the
declaration line only:

```swift
nonisolated struct RemotePaginationMetaInfo: APIModel, Codable, Equatable {
```

Every stored property is already `Equatable`, so the conformance is synthesised. This is
what lets `RecipeListPage` be `Equatable` and a whole page be compared in one assertion.

- [ ] **Step 6: Write the domain page and the service**

Create `RecipeTest/Modules/Recipe/Models/Domain/RecipeListPage.swift`:

```swift
//
//  RecipeListPage.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

/// One page of the recipe list.
///
/// The pagination meta is carried through rather than flattened into a couple of `Int`s,
/// so a pager gets `hasLoadedAllData` without the service having to re-derive it.
nonisolated struct RecipeListPage: Equatable {
  let recipes: [RecipeSummary]
  let meta: PaginationMetaInfo
}

// MARK: - Getters

nonisolated extension RecipeListPage {
  /// Forwarded so a pager reads it off the page it was just handed, rather than reaching
  /// into the meta block itself.
  var hasLoadedAllData: Bool {
    meta.hasLoadedAllData
  }
}
```

Create `RecipeTest/Modules/Recipe/Services/RecipeServiceProtocol.swift`:

```swift
//
//  RecipeServiceProtocol.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

/// What a view model will depend on. Domain types only — nothing above this line has any
/// reason to know the API's JSON shape.
nonisolated protocol RecipeServiceProtocol: AppServiceProtocol, Sendable {
  func getRecipes(page: Page) async throws -> RecipeListPage

  func getRecipe(id: String) async throws -> Recipe
}
```

Create `RecipeTest/Modules/Recipe/Services/RecipeService.swift`:

```swift
//
//  RecipeService.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

/// Fetches recipes and hands back domain models.
///
/// Depends on `RecipeAPIProtocol` rather than on `APIClient`, which is what lets a test
/// substitute `MockRecipeAPI` and run without a network or a simulator.
///
/// Errors from the API layer propagate unchanged. `APIClient` has already reported them
/// through `onError`, so there is nothing useful to add here.
final nonisolated class RecipeService: RecipeServiceProtocol {
  private let api: any RecipeAPIProtocol

  init(api: any RecipeAPIProtocol) {
    self.api = api
  }
}

// MARK: - Methods

nonisolated extension RecipeService {
  /// A row that cannot be mapped is dropped from the page rather than failing it — one
  /// bad row must not cost the user the other nine.
  func getRecipes(page: Page) async throws -> RecipeListPage {
    let (remote, meta) = try await api.getRecipes(page: page.index, perPage: page.size)

    return RecipeListPage(
      recipes: remote.compactMap { RecipeSummaryMapper.toDomain(from: $0) },
      meta: meta
    )
  }

  /// Unlike a list page, there is no partial result to degrade to: a detail screen with
  /// no recipe has nothing to show.
  func getRecipe(id: String) async throws -> Recipe {
    let remote = try await api.getRecipe(id: id)

    guard let recipe = RecipeMapper.toDomain(from: remote) else {
      throw AppError.unknown
    }

    return recipe
  }
}
```

- [ ] **Step 7: Run the tests to verify they pass**

Run the `Tests/RecipeServiceTests` suite. Expected: 13 tests pass.

- [ ] **Step 8: Format, then commit**

```bash
swiftformat RecipeTest Tests UITests && swiftformat RecipeTest Tests UITests --lint
git add RecipeTest/Modules Tests/Mocks Tests/Modules/Recipe/Services
git commit -m "feat(recipe): add RecipeService

Depends on RecipeAPIProtocol rather than APIClient, so tests run against
MockRecipeAPI with no network. A list row that cannot be mapped is dropped from
the page; an unmappable detail throws, since a detail screen has no partial
result to degrade to.

MockAPICall gives each endpoint its own recorder and stub, so two endpoints
cannot overwrite each other's recorded calls, one can fail while another
succeeds, and there is no reset() to keep in sync."
```

---

### Task 8: Register the service and verify the whole branch

**Files:**
- Modify: `RecipeTest/App/AppContainer.swift:70-77` (the `// MARK: Feature services` block, above `private init()`)

**Interfaces:**
- Consumes: `RecipeService(api:)` (Task 7), the existing `AppContainer.api`.
- Produces: `AppContainer.recipeService` — what the ViewModel stage will inject.

- [ ] **Step 1: Register the service**

In `RecipeTest/App/AppContainer.swift`, replace the commented-out example under
`// MARK: Feature services` with the real registration:

```swift
  // MARK: Feature services

  private(set) lazy var recipeService: RecipeServiceProtocol = RecipeService(api: api)
```

Lazy, like every other service on the container: nothing is constructed until the first
screen that needs it asks.

- [ ] **Step 2: Build both schemes**

The container is the one file nothing in the test suite touches, so a build is the check.

```bash
xcodebuild build -project RecipeTest.xcodeproj -scheme RecipeTest \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -skipPackagePluginValidation CODE_SIGNING_ALLOWED=NO
```

Expected: `BUILD SUCCEEDED`. Repeat with `-scheme RecipeTest-Staging`.

- [ ] **Step 3: Run the whole suite**

```bash
xcodebuild test -project RecipeTest.xcodeproj -scheme RecipeTest \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -skipPackagePluginValidation \
  CODE_SIGNING_ALLOWED=YES CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO
```

Expected: every suite passes — the six that existed before this branch
(`PageTests`, `RemotePaginationMetaInfoTests`, `AppErrorTests`,
`UTF8ConversionErrorTests`, `APIResponseTests`, `APIClientParseTests`) and the nine
added by it (`APIClientModelDecodingTests`, `GetRecipesTests`, `GetRecipeTests`,
`RecipeSummaryMapperTests`, `RecipeMapperTests`, `MockEndpointTests`,
`MockAPIRouterTests`, `APIClientRecipeTests`, `RecipeServiceTests`).

Record the actual pass/fail counts. Do not claim the branch is done on a build that was
not run.

- [ ] **Step 4: Confirm formatting is clean**

```bash
swiftformat RecipeTest Tests UITests --lint
```

Expected: `0/N files require formatting`.

- [ ] **Step 5: Commit**

```bash
git add RecipeTest/App/AppContainer.swift
git commit -m "feat(app): register RecipeService on the container"
```

- [ ] **Step 6: Review the branch before opening anything**

Run `core:code-review` over the branch diff against `develop`. It attaches
`ios:swift-conventions` for the Swift portion. Address what it finds before the branch
goes any further.

---

## Done when

- Every task's tests pass, and the full suite passes in one run.
- Both schemes build.
- `swiftformat --lint` is clean.
- `AppContainer.recipeService` resolves, and nothing in `RecipeTest/Modules/Recipe/Models/Domain` imports or mentions a `Remote` type.
- No UI, ViewModel, route, search or filter code was added.
