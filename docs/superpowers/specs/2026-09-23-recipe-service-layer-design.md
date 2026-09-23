# Recipe service layer and DTO models

**Date:** 2026-09-23
**Status:** Approved
**Scope:** Backend only — no UI, no search, no filter

## Purpose

`RecipeTest` is a demo app with no backend: every request is answered from
`RecipeTest/Resources/MockData/recipes.json` through `MockURLProtocol`. The app
currently has no feature module at all — `Modules/` holds only `Core` and `Shared`.

This is the first one. It adds the chain a recipe list and a recipe detail screen
will sit on:

```
ViewModel (later stage) -> RecipeService -> RecipeAPIProtocol -> APIClient -> MockURLProtocol -> recipes.json
```

The code is written as production code. Only the transport is mocked — the service
makes real requests through the real `APIClient`, and the fixture stands in for the
server. Nothing in the service or model layer knows it is talking to a mock.

### Success criteria

- `RecipeService` fetches a paginated list of recipe summaries and a single recipe detail.
- Domain models carry no knowledge of the API's JSON shape; a key rename in the
  backend stops at a mapper.
- Every piece is unit-tested without a simulator, a network, or `URLSession`.
- The module layout matches the team's established feature-module pattern, so the
  next feature module is a copy of this one.

### Out of scope

Search, filter, and the category facet those need are a later stage. Nothing here
presumes their shape. No UI, no ViewModels, no routes.

## Architecture

Four layers, each depending only on the one below it:

| Layer | Type | Knows about |
|---|---|---|
| Service | `RecipeService` | domain models, `RecipeAPIProtocol` |
| Mappers | `RecipeSummaryMapper`, `RecipeMapper` | remote DTOs and domain models — the only place both are visible |
| API client | `APIClient+Recipe` | resource paths, query parameters, remote DTOs |
| Transport | `APIClient` (Core, unchanged) | HTTP, the response envelope |

The API protocol is owned by the feature, not by Core. `APIClient` conforms to it in
an extension. This is what gives tests a seam: `RecipeService` depends on
`any RecipeAPIProtocol`, so a test injects `MockRecipeAPI` and never touches
`URLSession`.

### File layout

```
RecipeTest/Modules/Recipe/
  Clients/API/
    RecipeAPIProtocol.swift
    APIClient+Recipe.swift
  Models/
    Remote/
      RemoteRecipeSummary.swift
      RemoteRecipe.swift
    Domain/
      RecipeSummary.swift
      Recipe.swift
      RecipeListPage.swift
      RecipeDifficulty.swift
      RecipeAuthor.swift
      RecipeNutrition.swift
      RecipeMedia.swift
      RecipeIngredientGroup.swift
      RecipeStep.swift
  Services/
    RecipeServiceProtocol.swift
    RecipeService.swift
    RecipeServiceError.swift
    RecipeSummaryMapper.swift
    RecipeMapper.swift
```

Two deliberate deviations from the one-type-per-file rule: `RemoteRecipe.swift`
holds the detail payload's six nested DTOs (`RemoteRecipeAuthor`,
`RemoteRecipeNutrition`, `RemoteRecipeMedia`, `RemoteIngredientGroup`,
`RemoteIngredient`, `RemoteRecipeStep`) alongside `RemoteRecipe`. They are field
lists with no behaviour and are only ever read together. And
`RecipeIngredientGroup.swift` holds `RecipeIngredient` too, since an ingredient only
exists inside a group. Every other domain type gets its own file.

All app-target types carry an explicit `nonisolated` — the app targets build with
`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, which is why every existing Core type is
annotated. The test targets default to `nonisolated` and need no annotation.

## Models

### Remote DTOs

`APIModel, Decodable, Equatable`, every property optional. `APIModel` supplies the
snake_case-converting decoder, so no `CodingKeys` are needed. Optionality is the
house rule: one malformed or missing field must not fail a whole page.

`RemoteRecipeSummary` decodes only the fields a list row needs:

```
id, slug, title, shortDescription, heroImageUrl, totalTimeMinutes,
difficulty, rating, ratingCount, tags
```

`RemoteRecipe` decodes the whole row: the summary fields plus `fullDescription`,
`servings`, `prepTimeMinutes`, `cookTimeMinutes`, `cuisine`, `mealType`,
`dietaryAttributes`, `allergens`, `updatedAt`, `author`, `nutrition`, `gallery`,
`ingredientGroups`, `steps`.

`updatedAt` decodes as `String?` and is parsed in the mapper, not by a decoder date
strategy — the house rule for timestamps. With a decoder strategy, one unparseable
timestamp throws and costs the whole row; in the mapper it costs one field. No new
formatter is needed:
`DateFormatter.iso8601` in `Extensions/Foundation/DateFormatters` is
`yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ`, which matches the fixture's
`2026-07-01T07:07:00.000Z` exactly.

### Domain models

Non-optional wherever the app requires a value. Both are `Equatable, Identifiable`.

`RecipeSummary`: `id: String`, `title: String`, `shortDescription: String`,
`heroImageURL: URL?`, `totalTimeMinutes: Int?`, `difficulty: RecipeDifficulty?`,
`rating: Double`, `ratingCount: Int`, `tags: [String]`.

`slug` is decoded by the DTO but not carried into the domain — nothing routes or
looks up by slug, and the detail endpoint keys off `id`. It is there so the field is
already covered when a deep-link stage needs it.

`Recipe`: the summary fields plus `fullDescription: String`, `servings: Int?`,
`prepTimeMinutes: Int?`, `cookTimeMinutes: Int?`, `cuisine: String?`,
`mealType: String?`, `dietaryAttributes: [String]`, `allergens: [String]`,
`updatedAt: Date?`, `author: RecipeAuthor?`, `nutrition: RecipeNutrition?`,
`gallery: [RecipeMedia]`, `ingredientGroups: [RecipeIngredientGroup]`,
`steps: [RecipeStep]`.

`author` and `nutrition` are the only two top-level fixture fields that are ever
`null`, so they are the only two optional relations.

`RecipeListPage`: `recipes: [RecipeSummary]` and `meta: PaginationMetaInfo`. The meta
is carried through rather than flattened so a pager gets
`PaginationMetaInfo.hasLoadedAllData` for free.

Supporting domain types: `RecipeAuthor(id, name, avatarURL, profileURL)`,
`RecipeNutrition(caloriesPerServing, proteinGrams, carbohydrateGrams, fatGrams,
fibreGrams, sodiumMilligrams)`, `RecipeMedia(id, url, altText)`,
`RecipeIngredientGroup(id, title, ingredients)` with
`RecipeIngredient(id, name, quantity, unit, note, isOptional)` in the same file — the
ingredient exists only inside a group — and
`RecipeStep(id, number, text, imageURL, durationSeconds)`.

Group `title` is `String?`: a single-group recipe leaves it `null` in the fixture,
which means "this recipe has one unnamed list", not a missing value.

### Facet fields

Split deliberately:

- `difficulty` becomes `RecipeDifficulty: String` (`easy`, `medium`, `hard`). Closed,
  three values across all 36 fixture rows, and it drives a UI badge. An unrecognised
  value maps to `nil`, not a crash.
- `cuisine`, `mealType`, `tags`, `dietaryAttributes` and `allergens` stay `String`.
  These are open vocabularies. An enum would have to drop values it does not
  recognise, and silently dropping an entry from an allergen list is an actively
  harmful failure. They become enums when the filter stage lands and defines the
  facet vocabulary — that stage owns the decision, not this one.

Ingredient `unit` also stays `String` for the same reason (16 distinct values in the
fixture, and the list is open).

## One Core change

`APIClient+ModelDecoding.swift` currently exposes a single method:

```swift
func decodeRemoteModelWithMeta<RemoteModel, RemoteMetaModel, DomainModel, MetaModel>(
  _ apiResponse: APIResponse,
  thenMapUsing mapper: ...,
  metaMapper: ...
) throws -> (DomainModel, MetaModel)
```

It decodes *and* maps in one call, which puts mapping in the client layer where the
house pattern keeps it in `Services/…Mapper`. It has no callers anywhere in the
repository. Replace it with the pair the feature layer actually needs:

```swift
nonisolated extension APIClient {
  func decodeModel<T: Decodable>(_ response: APIResponse) throws -> T
  func decodeModelWithMeta<T: Decodable, M: Decodable>(_ response: APIResponse) throws -> (T, M)
}
```

Both throw `APIClientError.dataNotFound(_:)` when the payload is absent — naming the
type that was expected, which `AppError.unknown` cannot — and both route failures through
`onError` before rethrowing, matching what the existing method does.

## API layer

```swift
nonisolated protocol RecipeAPIProtocol: Sendable {
  func getRecipes(page: Int, perPage: Int) async throws -> ([RemoteRecipeSummary], RemotePaginationMetaInfo)
  func getRecipe(id: String) async throws -> RemoteRecipe
}
```

`Int` rather than `Page` at this boundary: the API layer speaks the wire's language,
and translating `Page` into `page`/`per_page` is the service's job.

`APIClient+Recipe` conforms:

- `getRecipes` — `GET recipes`, parameters `["page": page, "per_page": perPage]`,
  `URLEncoding.default`, then `decodeModelWithMeta`.
- `getRecipe` — `GET recipes/{id}`, no parameters, then `decodeModel`.

Both use the existing `httpRequestHeaders()`. There is no auth in this project.

## Service layer

```swift
nonisolated protocol RecipeServiceProtocol: AppServiceProtocol, Sendable {
  func getRecipes(page: Page) async throws -> RecipeListPage
  func getRecipe(id: String) async throws -> Recipe
}

final nonisolated class RecipeService: RecipeServiceProtocol {
  init(api: any RecipeAPIProtocol, onError: @escaping SendableErrorResult)
}
```

`getRecipes(page:)` sends `page.index` and `page.size`, then maps with
`compactMap(RecipeSummaryMapper.toDomain(from:))`. A row missing a required field is
dropped from the page, not fatal — one bad row must not cost the user the other
nine.

`getRecipe(id:)` maps with `RecipeMapper.toDomain(from:)` and throws
`RecipeServiceError.unmappableRecipe(id:)` when the row cannot be mapped. A detail screen
with no recipe has nothing to show, so there is no partial result to degrade to. The case
is named rather than `AppError.unknown` so a caller can tell a backend contract break from
every other unhandled failure, and it carries the id that broke.

Errors from the API layer propagate unchanged. `APIClient` already reports those to its
own `onError` (and so to `MonitoringService`), so the service does not report them a
second time. It does report what it raises itself: a payload that decoded cleanly but
could not be mapped never reaches the client's reporting, so without the service's own
`onError` a contract break would surface as a failed screen and no signal anywhere.

### Mappers

`enum RecipeSummaryMapper { static func toDomain(from: RemoteRecipeSummary) -> RecipeSummary? }`
and `enum RecipeMapper { static func toDomain(from: RemoteRecipe) -> Recipe? }`, each
with private helpers for the nested types. Caseless enums, static methods, no state.

Required fields are `id` and `title`; absent either, the mapper returns `nil`.
Everything else falls back: `shortDescription` to `""`, `tags`/`allergens`/`gallery`/
`ingredientGroups`/`steps` to `[]`, `rating`/`ratingCount` to `0`, optional
scalars stay optional. `steps` are sorted by `number` so display order does not
depend on the array's order in the payload.

### Container wiring

```swift
private(set) lazy var recipeService: RecipeServiceProtocol = {
  let monitoring = monitoring

  return RecipeService(
    api: api,
    onError: { error in
      monitoring.logError(error)
    }
  )
}()
```

in `AppContainer`, replacing the commented-out `catalogService` example. Lazy, as
every other service there is. `monitoring` is resolved into a local for the same reason
`api` does it: the closure is `@Sendable` and the service is nonisolated, so capturing
`self` would reach main-actor state from off the main actor.

## Demo transport

`MockEndpoint` gains two cases:

```swift
case recipes            // fixtureName "recipes", isPaginated true
case recipe(id: String) // fixtureName "recipes", isPaginated false
```

matched in `MockEndpoint.match(path:method:)`: a trailing `recipes` component is the
list; `recipes/{id}` is the detail. Detail keys off `id` (`rcp-001`), not `slug`.

`MockAPIRouter` gains a single-row lookup. Today it only slices arrays. A new
`selectsSingleRow` path finds the row whose `id` matches, envelopes it as a JSON
object rather than an array, and returns a 404 envelope when no row matches —
the same discipline the existing unmatched-path branch uses, so a wrong id fails the
way it would against a real backend.

`failureMode` continues to short-circuit both endpoints.

## Testing

Test-driven: each suite is written and seen to fail before the code it covers exists.

### The mock, and why it is shaped this way

The hand-rolled API mock this team has used elsewhere works, but its structure does
not scale: around thirty flat stored properties on one class; a `lastRequestedX`
field written by two different methods, so one call's assertion can be satisfied by
another call; a forty-line hand-maintained `reset()` that silently rots when a
property is added; a single `errorToReturn` shared by every endpoint, so one call
cannot fail while another succeeds; and per-endpoint escape hatches — a page lookup
table, a handler closure, a lock guarding one method — bolted on one at a time.

Replace all of that with one reusable recorder, one instance per endpoint:

```swift
// Tests/Mocks/Support/MockAPICall.swift
final class MockAPICall<Request, Response>: @unchecked Sendable {
  var requests: [Request] { get }        // callCount, lastRequest, wasCalled derived
  func returns(_ response: Response)
  func fails(with error: any Error)
  func responds(_ handler: @escaping (Request) async throws -> Response)
  func invoke(_ request: Request) async throws -> Response
}
```

```swift
// Tests/Mocks/Modules/Recipe/Clients/API/MockRecipeAPI.swift
final class MockRecipeAPI: RecipeAPIProtocol {
  struct RecipesRequest: Equatable { let page: Int; let perPage: Int }

  let recipes = MockAPICall<RecipesRequest, ([RemoteRecipeSummary], RemotePaginationMetaInfo)>(
    returning: ([], .dummy())
  )
  let recipe = MockAPICall<String, RemoteRecipe>(returning: .dummy())

  func getRecipes(page: Int, perPage: Int) async throws -> ([RemoteRecipeSummary], RemotePaginationMetaInfo) {
    try await recipes.invoke(RecipesRequest(page: page, perPage: perPage))
  }

  func getRecipe(id: String) async throws -> RemoteRecipe {
    try await recipe.invoke(id)
  }
}
```

What this buys: each endpoint's stub and its recorded calls live together; two
endpoints cannot overwrite each other's last request; one endpoint can fail while
another succeeds; the per-call handler is there from the start rather than
retrofitted; the one lock lives in one reusable place; and there is no `reset()` at
all, because a test builds a fresh mock. At the call site:

```swift
api.recipes.returns(([.dummy(id: "rcp-001")], .dummy(total: 1)))
#expect(api.recipes.lastRequest == .init(page: 1, perPage: 10))
```

Mocks live in `Tests/Mocks/`, not a top-level `Mocks/` folder. `Tests` is a
`PBXFileSystemSynchronizedRootGroup` in the project, so files dropped inside it join
the target automatically; a new top-level folder would belong to no group and compile
into nothing.

### Dummy factories

`.dummy(...)` static factories with defaulted parameters for `RemoteRecipeSummary`,
`RemoteRecipe`, `RecipeSummary` and `Recipe`, following
`DummyRemotePaginationMetaInfo`. In `Tests/Mocks/Modules/Recipe/Models/`.

### Suites

| Suite | Covers |
|---|---|
| `GetRecipesTests` + `GetRecipesTests_200.json` | `RemoteRecipeSummary` decoding, snake_case keys, pagination meta |
| `GetRecipeTests` + `GetRecipeTests_200.json` | full `RemoteRecipe` decoding — nested groups, steps, null author and nutrition |
| `RecipeSummaryMapperTests` | required-field drops, fallbacks, difficulty mapping, unknown difficulty to `nil` |
| `RecipeMapperTests` | nested mapping, empty gallery, missing nutrition, step ordering by `number` |
| `RecipeServiceTests` | `Page` translated to `page`/`per_page`, malformed rows dropped, unmappable detail throws, API errors propagate |
| `MockAPIRouterTests` | detail lookup by id, 404 on unknown id, a page past the end is empty |

Fixtures follow the existing convention: `<SuiteName>_<statusCode>.json`, loaded by
`Fixture.apiResponse(_:)`, living next to the suite.

No `MockRecipeService` yet. Nothing consumes `RecipeServiceProtocol` until the
ViewModel stage, and a mock with no caller is a guess at what that stage needs.

## Verification

`xcodebuild test` on the `RecipeTest` scheme, plus SwiftLint and SwiftFormat clean,
before the work is called done.
