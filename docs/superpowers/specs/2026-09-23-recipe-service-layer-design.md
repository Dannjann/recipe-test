# Recipe contract and service layer

**Date:** 2026-09-23
**Revised:** 2026-09-24 — reshaped to the Bokkie Bites prototype
**Status:** Approved
**Scope:** Backend only — no UI, no view models, no routes

## Purpose

`RecipeTest` is a demo app with no backend: every request is answered from
`RecipeTest/Resources/MockData/` through `MockURLProtocol`. The first revision of this
document specified a recipe service against a contract invented ahead of any design.
The Bokkie Bites prototype (`B App/bokkie-bites-prototype.html`) has since settled what
the app actually shows, and it is a much smaller contract than the one that shipped.

This revision reshapes the contract to the prototype and widens the service to cover
every screen the prototype has, not just a list and a detail:

```
ViewModel (later stage) -> RecipeService -> RecipeAPIProtocol -> APIClient -> MockURLProtocol -> fixtures
```

The code stays production code. Only the transport is mocked — the service makes real
requests through the real `APIClient`, and the fixtures stand in for the server.

### What changed, and why

The shipped contract carried 24 top-level fields. The prototype reads 12 of them. Nine
fields are not merely unused — nothing in the product design will ever read them:
`author`, `nutrition`, `allergens`, `tags`, `rating`, `rating_count`, `updated_at`,
`slug`, `full_description`. Carrying a field the app never displays costs a DTO
property, a domain property, a mapper branch, a fallback decision, and a test — and
invites a screen to be designed around data the backend may not really have.

Two structures also collapse. The prototype has no ingredient groups and no per-step
metadata, so `ingredient_groups` flattens to `ingredients` and `steps` becomes a list of
strings.

Against that, the prototype needs three things the shipped contract has no room for: a
`category` facet, a vegetarian flag, and real photographs.

### Success criteria

- Every screen in the prototype can be built against `RecipeServiceProtocol` without a
  second data source or a client-side filter over a fully-downloaded collection.
- Domain models carry no knowledge of the API's JSON shape; a key rename in the backend
  stops at a mapper.
- No field survives that no screen reads.
- Every piece is unit-tested without a simulator, a network, or `URLSession`.

### Out of scope

No UI, no view models, no routes. Favourites, shopping lists, and user accounts are not
in the prototype and get no contract here.

## Architecture

Unchanged in shape — four layers, each depending only on the one below it:

| Layer | Type | Knows about |
|---|---|---|
| Service | `RecipeService` | domain models, `RecipeAPIProtocol` |
| Mappers | `RecipeSummaryMapper`, `RecipeMapper`, `RecipeCategoryMapper` | remote DTOs and domain models — the only place both are visible |
| API client | `APIClient+Recipe` | resource paths, query parameters, remote DTOs |
| Transport | `APIClient` (Core, unchanged) | HTTP, the response envelope |

The API protocol stays owned by the feature. `APIClient` conforms to it in an extension,
which is what gives `RecipeService` a seam a test can substitute.

### File layout

```
RecipeTest/Modules/Recipe/
  Clients/API/
    RecipeAPIProtocol.swift
    APIClient+Recipe.swift
  Models/
    Remote/
      RemoteRecipeSummary.swift
      RemoteRecipe.swift          + RemoteRecipeIngredient
      RemoteRecipeCategory.swift
    Domain/
      RecipeSummary.swift
      Recipe.swift                + RecipeIngredient
      RecipeCategory.swift
      RecipeListPage.swift
      RecipeDifficulty.swift
      RecipeQuery.swift           + RecipeServings, RecipeSort
  Services/
    RecipeServiceProtocol.swift
    RecipeService.swift
    RecipeServiceError.swift
    RecipeSummaryMapper.swift
    RecipeMapper.swift
    RecipeCategoryMapper.swift
```

**Deleted:** `RecipeAuthor.swift`, `RecipeNutrition.swift`, `RecipeMedia.swift`,
`RecipeStep.swift`, `RecipeIngredientGroup.swift`, and the six nested DTOs inside
`RemoteRecipe.swift`.

`RecipeIngredient` lives in `Recipe.swift` and `RemoteRecipeIngredient` in
`RemoteRecipe.swift` — an ingredient exists only inside a recipe, and the pair is only
ever read together. `RecipeServings` and `RecipeSort` live in `RecipeQuery.swift` for
the same reason. Every other type gets its own file.

All app-target types carry an explicit `nonisolated`: the app target builds with
`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`.

## The recipe contract

One row of `recipes.json`, and the shape both recipe endpoints answer with:

| Field | Type | Prototype | Notes |
|---|---|---|---|
| `id` | String | `id` | |
| `title` | String | `name` | |
| `description` | String | `desc` | was `short_description`; `full_description` dropped |
| `category` | String | `cat` | new facet — see below |
| `cuisine` | String | `cui` | |
| `meal_type` | String | — | retained by explicit decision, though the prototype has no screen for it |
| `total_time_minutes` | Int | `time` | `prep_`/`cook_` dropped |
| `servings` | Int | `serv` | |
| `difficulty` | String | `diff` | `easy` / `medium` / `hard` |
| `is_vegetarian` | Bool | `veg` | replaces `dietary_attributes` |
| `hero_image_url` | String | card photo | |
| `gallery` | `[String]` | carousel | bare URLs; was `[{id,url,alt_text}]` |
| `ingredients` | `[{quantity_text, name, image_url, is_main}]` | `ing` | flattened out of `ingredient_groups` |
| `steps` | `[String]` | `steps` | was `[{id,number,text,image_url,duration_seconds}]` |

**Removed entirely:** `slug`, `full_description`, `prep_time_minutes`,
`cook_time_minutes`, `tags`, `dietary_attributes`, `allergens`, `rating`,
`rating_count`, `updated_at`, `author`, `nutrition`, every ingredient-group wrapper, and
every nested `id` / `unit` / `note` / `is_optional` / `number` / `duration_seconds` /
`alt_text`.

### Two deliberate deviations from the prototype

**`meal_type` is kept.** The prototype has no meal-type screen; the field is retained by
explicit decision so a later stage has the facet available. It is the one field in the
contract that no current screen reads.

**`image_url` sits on each ingredient.** The prototype keys a shared photo map by
ingredient name (`PH_I`) to render the "Main ingredients" carousel. Denormalising that
onto the ingredient costs one field and saves a fourth endpoint plus a join on a
free-text name — a join that silently renders nothing when a name does not match.

### Ingredients

`quantity_text` is a display string (`320 g`, `1 tsp`, `½ cup`, `to taste`), not a
number and a unit. The prototype prints it verbatim and never does arithmetic on it, and
the source data cannot support arithmetic anyway: 120 of 370 ingredients have no unit,
21 have no quantity, and the `note` column is free text ranging from `chopped` to
`/4½oz`.

This is the change that loses information. Nine recipes have titled ingredient groups
(`For the sauce`, `For the dough`, `For the béchamel`). Flattening preserves ingredient
order but discards those titles. The prototype has no grouped-ingredient UI to show them
in, so they have nowhere to go.

`is_main` marks the ingredients the detail screen's "Main ingredients" carousel shows —
substantive ingredients only, never pantry staples (salt, pepper, oil, water, sugar),
capped at six per recipe.

### Facets

`difficulty` becomes `RecipeDifficulty` (`easy`, `medium`, `hard`): closed, three values
across all 36 rows, and it drives a UI badge. An unrecognised value maps to `nil`.

`category` is the prototype's browse axis — `Meal`, `Rice`, `Snacks`, `Desserts`,
`Vegan`, `Pasta` — and stays a `String` in the domain. It looks closed, but it is a
merchandising vocabulary the content team owns, not a property of a recipe: the six
values mix dish type with diet, and the set will move. `GET categories` returns the live
vocabulary, so nothing in the app needs a compile-time case list.

`cuisine` and `meal_type` stay `String` for the same reason.

## Query model

Every list surface in the prototype — Home's "Latest", the category tiles, the cuisine
list, search results, and the search overlay's suggestions — is the same query against
the same collection. One endpoint, parameterised:

```swift
nonisolated struct RecipeQuery: APIRequestParameters, Equatable {
  var searchText: String?
  var category: String?
  var cuisine: String?
  var isVegetarian: Bool?
  var servings: RecipeServings?
  var includeIngredients: [String]
  var excludeIngredients: [String]
  var searchesSteps: Bool
  var sort: RecipeSort?
}
```

`APIRequestParameters` is the house protocol for exactly this — "methods that have more
than two non-Closure parameters" — and it supplies the snake_case-converting encoder, so
the wire names fall out of the property names with no hand-written mapping.

`RecipeQuery.empty` is the unfiltered query. A nil facet is absent from the query string
rather than sent empty, so `GET recipes` with no filters stays a bare
`recipes?page=1&per_page=10`.

```swift
nonisolated enum RecipeServings: String, Equatable, CaseIterable {
  case one = "1"
  case two = "2"
  case four = "4"
  case sixOrMore = "6+"
}
```

`servings` is an enum, not an `Int`, because the prototype's fourth option is `6+` — a
lower bound, not a value. The raw values are the wire strings, so encoding is free.

```swift
nonisolated enum RecipeSort: String, Equatable { case latest }
```

Only one ordering exists. `sort=latest` means fixture order, which the fixture stores
newest-first. Nothing else can define it — `updated_at` is gone, and the prototype's
`LATEST` is six hand-picked ids.

## API layer

```swift
nonisolated protocol RecipeAPIProtocol: Sendable {
  func getRecipes(
    query: RecipeQuery,
    page: Int,
    perPage: Int
  ) async throws -> ([RemoteRecipeSummary], RemotePaginationMetaInfo)

  func getRecipe(id: String) async throws -> RemoteRecipe

  func getCategories() async throws -> [RemoteRecipeCategory]
}
```

`Int` page numbers rather than `Page`: this layer speaks the wire's language, and
translating `Page` into `page`/`per_page` is the service's job. `RecipeQuery` crosses the
boundary unchanged because it *is* wire vocabulary — it encodes itself.

`APIClient+Recipe` conforms:

- `getRecipes` — `GET recipes`, `URLEncoding.default`, parameters built by merging the
  encoded query with `page`/`per_page`, then `decodeModelWithMeta`.
- `getRecipe` — `GET recipes/{id}`, then `decodeModel`.
- `getCategories` — `GET categories`, then `decodeModel`.

Arrays encode as repeated keys (`include_ingredients=garlic&include_ingredients=onion`)
and booleans as `true`/`false`, which the mock router reads with `queryItems.filter`.

This needs an explicit `URLEncoding(arrayEncoding: .noBrackets, boolEncoding: .literal)`.
`URLEncoding.default` is `.brackets` + `.numeric`, which would send
`include_ingredients[]=garlic` and `is_vegetarian=1` — neither of which the router
matches, so both filters would silently pass every row. The router accepts `1`/`0` as
well as `true`/`false` so the two sides cannot drift apart again.

## Service layer

```swift
nonisolated protocol RecipeServiceProtocol: AppServiceProtocol, Sendable {
  func getRecipes(query: RecipeQuery, page: Page) async throws -> RecipeListPage
  func getRecipe(id: String) async throws -> Recipe
  func getCategories() async throws -> [RecipeCategory]
}
```

`getRecipes` sends `page.index` and `page.size` and maps with
`compactMap(RecipeSummaryMapper.toDomain(from:))`. A row missing a required field is
dropped from the page, not fatal.

`getRecipe` throws `RecipeServiceError.unmappableRecipe(id:)` when the row cannot be
mapped. A detail screen with no recipe has nothing to show, so there is no partial result
to degrade to.

`getCategories` `compactMap`s, like the list: a malformed category tile is one missing
tile, not a failed Home screen.

Errors from the API layer propagate unchanged — `APIClient` already reports those to its
own `onError`. The service reports only what it raises itself: a payload that decoded
cleanly but could not be mapped never reaches the client's reporting.

### Mappers

Caseless enums with static methods, no state:
`RecipeSummaryMapper.toDomain(from:) -> RecipeSummary?`,
`RecipeMapper.toDomain(from:) -> Recipe?`,
`RecipeCategoryMapper.toDomain(from:) -> RecipeCategory?`.

Required fields are `id` and `title` (`id` and `name` for a category); absent either, the
mapper returns `nil`. Everything else falls back: `description` to `""` (detail only),
`gallery`/`ingredients`/`steps` to `[]`, `isVegetarian` and `isMain` to `false`,
`recipeCount` to `0`, optional scalars stay optional.

`RemoteRecipeSummary` decodes only what `RecipeSummary` carries — it does not decode
`description`, `gallery`, `ingredients` or `steps`, even though `GET recipes` returns
rows that contain them. The mock router serves whole fixture rows; the DTO is what
decides a list row's cost.

Step ordering is no longer the mapper's problem — steps are a string array, so payload
order *is* display order.

### Domain models

```swift
nonisolated struct RecipeSummary: Equatable, Identifiable {
  let id: String
  let title: String
  let heroImageURL: URL?
  let category: String?
  let cuisine: String?
  let mealType: String?
  let totalTimeMinutes: Int?
  let servings: Int?
  let difficulty: RecipeDifficulty?
  let isVegetarian: Bool
}
```

The split rule: **the summary carries the row's identity, its photograph and its facets;
the detail adds the prose and the three collections.** That is why `category`, `cuisine`
and `servings` are here — the prototype's list row prints `cuisine · category` and its
meta strip prints servings, and a cell that had to fetch a detail to render its own
subtitle would defeat the split. It is also why `description` is *not* here: no list
surface in the prototype renders it, and the one screen that does already fetches the
whole recipe.

```swift
nonisolated struct Recipe: Equatable, Identifiable {
  // the summary's fields, plus:
  let description: String
  let gallery: [URL]
  let ingredients: [RecipeIngredient]
  let steps: [String]
}

nonisolated struct RecipeIngredient: Equatable, Identifiable {
  let id: String        // synthesised: "\(recipeID)-\(index)"
  let quantityText: String
  let name: String
  let imageURL: URL?
  let isMain: Bool
}
```

Ingredient ids are synthesised by the mapper from the recipe id and the array index. The
contract dropped the stored ids, but a SwiftUI `ForEach` still needs stable identity, and
position within a recipe is stable.

```swift
nonisolated struct RecipeCategory: Equatable, Identifiable {
  let id: String
  let name: String
  let imageURL: URL?
  let recipeCount: Int
}
```

`recipeCount` is served rather than derived: the Home grid and the search overlay both
print "*n* recipes", and a client cannot count what pagination has not fetched.

`RecipeListPage` is unchanged — `recipes: [RecipeSummary]` and `meta: PaginationMetaInfo`.

## Images

The fixture's image URLs today point at `https://api.example.com/api/v1/images/…`, which
`MockAPIRouter` answers with a generated flat colour tile. That is the app's entire visual
identity at the moment, and it is the wrong one.

Real photographs replace it:

- **Hero** — each recipe's own photograph from TheMealDB
  (`https://www.themealdb.com/images/media/meals/….jpg`). All 36 titles match a TheMealDB
  record exactly, which is almost certainly where this fixture came from, so every recipe
  gets a photograph of the actual dish.
- **Gallery** — the hero plus two further food photographs per recipe, drawn from the
  prototype's own Unsplash pool (113 ids across `PH_R`, `PH_I` and `PH_C`). Each id is
  used at most once across the whole fixture; 72 are needed.
- **Ingredients** — the prototype's `PH_I` photograph for that ingredient where one
  exists, `null` otherwise. A missing ingredient photo is a placeholder, not a failure.

Every URL is checked to return `200` before it lands in the fixture.

This needs one change outside the feature. `AppContainer.bootstrap()` currently installs
`MockURLProtocol` into Kingfisher's downloader so that images are mocked too; with real
URLs that would intercept every photograph and 404 it. The installation is removed, and
`MockEndpoint.image(seed:)` along with `MockAPIRouter.imageData(seed:)` and
`stableHash(_:)` are deleted — after this change nothing requests a generated image, and
`MockAPIRouter` no longer needs to import `UIKit`.

Recipe data stays mocked; photographs come off the network.

## Mock transport

`MockAPIRouter` today only paginates. It now has to filter, or none of the prototype's
screens behave: browsing a category, searching, and every filter chip are all query
parameters that the router currently ignores, which would return the full collection to
every one of them.

`MockEndpoint` gains `case categories` (fixture `categories`, not paginated) and loses
`case image`.

Filtering runs against the fixture rows before pagination, in this order:

1. `category`, `cuisine` — exact, case-insensitive
2. `is_vegetarian` — when `true`, keep only rows whose flag is true; absent means no filter
3. `servings` — `1`/`2`/`4` exact, `6+` means `>= 6`
4. `include_ingredients` — every term must substring-match some ingredient name
5. `exclude_ingredients` — no term may substring-match any ingredient name
6. `q` — substring match against title, description, category, cuisine and ingredient
   names; when `search_steps=true`, step text as well

All matching is case-insensitive and diacritic-insensitive, so `pao` finds `Pão`.

`sort=latest` is fixture order, so it is a no-op the router accepts and ignores. Accepting
it matters: an unrecognised parameter must not change the result set.

Pagination then slices the filtered rows, so `meta.total` reports matches rather than the
collection size — which is what the prototype's "*n* recipes" count needs.

`failureMode` continues to short-circuit every endpoint.

## Testing

Test-driven: each suite is written and seen to fail before the code it covers exists.

The `MockAPICall` recorder and the `MockRecipeAPI` shape from the first revision are
unchanged and carry over. `MockRecipeAPI` gains a third call recorder for `getCategories`,
and `MockRecipeAPI.recipes` takes `RecipesRequest { query, page, perPage }`.

| Suite | Covers |
|---|---|
| `GetRecipesTests` | `RemoteRecipeSummary` decoding, snake_case keys, pagination meta |
| `GetRecipeTests` | full `RemoteRecipe` decoding — flat ingredients, string steps, gallery |
| `GetCategoriesTests` | `RemoteRecipeCategory` decoding |
| `RecipeQueryTests` | encodes to the expected query items; empty query encodes to nothing; `6+` survives the round trip |
| `RecipeSummaryMapperTests` | required-field drops, fallbacks, difficulty mapping, unknown difficulty to `nil` |
| `RecipeMapperTests` | ingredient mapping and synthesised ids, empty gallery, missing images |
| `RecipeCategoryMapperTests` | required-field drops, count fallback |
| `RecipeServiceTests` | `Page` translated to `page`/`per_page`, query forwarded, malformed rows dropped, unmappable detail throws, API errors propagate |
| `MockAPIRouterTests` | every filter above, filters combining, `meta.total` reflects matches, detail by id, 404 on unknown id, page past the end is empty |

`MockAPIRouterTests` carries the most new weight: the router is now the thing standing in
for the backend's query engine, and a filter that silently does nothing would look exactly
like a screen with no results.

Fixtures follow the existing convention — `<SuiteName>_<statusCode>.json`, loaded by
`Fixture.apiResponse(_:)`, living next to the suite.

No `MockRecipeService` yet. Nothing consumes `RecipeServiceProtocol` until the view model
stage, and a mock with no caller is a guess at what that stage needs.

## Verification

`xcodebuild test` on the `RecipeTest` scheme, plus SwiftLint and SwiftFormat clean, before
the work is called done.
