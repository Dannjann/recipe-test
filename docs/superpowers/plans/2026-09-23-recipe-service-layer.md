# Recipe Contract and Service Layer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reshape the recipe contract, fixture data, images and service layer to the Bokkie Bites prototype, so every screen the prototype has can be built against `RecipeServiceProtocol`.

**Architecture:** The four existing layers are unchanged in shape — service → API protocol → `APIClient` → `MockURLProtocol`. What changes is the contract they carry: 24 top-level fields drop to 12, ingredient groups and step objects flatten, and a `category` facet, an `is_vegetarian` flag and real photographs arrive. The service widens from list-and-detail to one parameterised recipes query plus a categories endpoint, and `MockAPIRouter` grows a filter pipeline so it can stand in for the backend's query engine.

**Tech Stack:** Swift 6, SwiftUI, Alamofire, Kingfisher, Swift Testing (`@Test` / `#expect`), Xcode 26, SwiftLint, SwiftFormat.

**Spec:** `docs/superpowers/specs/2026-09-23-recipe-service-layer-design.md`

## Global Constraints

- Every app-target type carries an explicit `nonisolated` — the app target builds with `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`. Test-target types need no annotation.
- Remote DTOs are `APIModel, Decodable, Equatable` with **every property optional**. `APIModel` supplies the snake_case-converting decoder, so no `CodingKeys`.
- Domain models are non-optional wherever the app requires a value, and `Equatable, Identifiable`.
- Mappers are caseless `enum`s with `static` methods and no state, living in `Services/`. Mapping never happens in the client layer.
- One type per file, with the three exceptions the spec names: `RecipeIngredient` in `Recipe.swift`, `RemoteRecipeIngredient` in `RemoteRecipe.swift`, `RecipeServings` and `RecipeSort` in `RecipeQuery.swift`.
- File header comment block matches every existing file: name, `RecipeTest`, `Created by Danjan ( https://github.com/Dannjann )`, `Copyright © 2026 Danjan. All rights reserved.`
- Comments explain *why*, never *what* — the project's standing rule. Self-documenting code over narration.
- Commits are Conventional Commits. **No `Co-Authored-By` trailer** (`.claude/kit-config.yaml` default is `coauthor_trailer: omit`).
- Tests live in `Tests/` mirroring the source tree; mocks in `Tests/Mocks/`. `Tests` is a `PBXFileSystemSynchronizedRootGroup`, so new files join the target automatically — never add a top-level folder.
- Category vocabulary is exactly: `Meal`, `Rice`, `Snacks`, `Desserts`, `Vegan`, `Pasta`.
- Difficulty vocabulary is exactly: `easy`, `medium`, `hard`.
- Servings wire values are exactly: `1`, `2`, `4`, `6+`.

## Review Focus

Five things the spec implies but that no single task's happy path exercises. Each has a test pinned to the task that owns the code.

1. **A filter that silently does nothing looks identical to "no results".** If `MockAPIRouter` ignores a query parameter it does not recognise, browsing a category returns all 36 recipes and nobody notices until a screen is built. → Task 7 asserts each filter *reduces* the set, and that an unknown parameter does not.
2. **`meta.total` after filtering.** Pagination that counts the collection rather than the matches makes the prototype's "*n* recipes" count wrong on every filtered screen. → Task 7.
3. **Diacritics.** `Pão de Queijo`, `Padrón`, `Gruyère` are in the data; a user typing `pao` gets nothing from a naive `contains`. → Task 7.
4. **An ingredient with no photograph.** `PH_I` covers a fraction of 370 ingredient names; `image_url` is `null` for most. A mapper that force-unwraps, or a fixture test that assumes presence, breaks the detail screen. → Task 1 asserts the fixture really contains one; Task 4 asserts the mapper keeps it.
5. **Empty `RecipeQuery` must encode to nothing.** If nil facets serialise as empty strings, every unfiltered list request carries nine junk parameters and the router filters on `""`, matching everything or nothing depending on the comparison. → Task 6.

---

## File Structure

**Fixture data**
- Modify: `RecipeTest/Resources/MockData/recipes.json` — reshaped, 36 rows
- Create: `RecipeTest/Resources/MockData/categories.json` — 6 rows

**Core (mock transport)**
- Modify: `RecipeTest/Modules/Core/Clients/API/Mock/MockEndpoint.swift` — `+ categories`, `− image`
- Modify: `RecipeTest/Modules/Core/Clients/API/Mock/MockAPIRouter.swift` — `+ filter pipeline`, `− image generation`, `− import UIKit`
- Modify: `RecipeTest/App/AppContainer.swift` — remove Kingfisher mock wiring, register nothing new

**Recipe module**
- Modify: `Models/Remote/RemoteRecipeSummary.swift`, `Models/Remote/RemoteRecipe.swift`
- Create: `Models/Remote/RemoteRecipeCategory.swift`
- Modify: `Models/Domain/Recipe.swift`, `Models/Domain/RecipeSummary.swift`
- Create: `Models/Domain/RecipeCategory.swift`, `Models/Domain/RecipeQuery.swift`
- Delete: `Models/Domain/RecipeAuthor.swift`, `RecipeNutrition.swift`, `RecipeMedia.swift`, `RecipeStep.swift`, `RecipeIngredientGroup.swift`
- Modify: `Services/RecipeSummaryMapper.swift`, `Services/RecipeMapper.swift`, `Services/RecipeService.swift`, `Services/RecipeServiceProtocol.swift`
- Create: `Services/RecipeCategoryMapper.swift`
- Modify: `Clients/API/RecipeAPIProtocol.swift`, `Clients/API/APIClient+Recipe.swift`

**Tests**
- Create: `Tests/Resources/RecipeFixtureTests.swift`, `Tests/Modules/Recipe/Models/RecipeQueryTests.swift`, `Tests/Modules/Recipe/Clients/API/GetCategories/GetCategoriesTests.swift` (+ `_200.json`), `Tests/Modules/Recipe/Services/RecipeCategoryMapperTests.swift`
- Modify: every existing recipe suite, `Tests/Mocks/Modules/Recipe/Clients/API/MockRecipeAPI.swift`, both dummy factories, `Tests/Modules/Core/Clients/API/Mock/MockEndpointTests.swift`, `MockAPIRouterTests.swift`

**Note on ordering:** Task 1 lands the new fixture before the DTOs that read it (Tasks 3–5). Most suites carry their own fixtures under `Tests/`, so they are unaffected — but **`MockAPIRouterTests` deliberately reads the shipped `recipes.json` out of the host app bundle**, so Task 1 breaks any of its assertions that name a removed field. Task 1 therefore fixes those assertions as part of its own work; Task 7 then adds the filtering tests on top. Between Task 1 and Task 9 the *running app* is ahead of its models, which is what Task 10 Step 4 exists to catch.

**House test style**, followed by every code block below:
- A suite is a bare `struct XTests` — no `@Suite` attribute.
- `@Test` sits on its own line; the behaviour is carried by the function name, in `subject_condition_result` form, with a `///` comment above it when the *why* is not obvious.
- `MockAPIRouterTests` already provides `makeSUT()`, `makeRequest(_ path: String)`, `decode(_ body: Data)` and `rows(in:)`. Reuse them; do not introduce a parallel set.
- Decoding suites use `makeSUT()` and `sut.decodedValue()`, not a bare `APIClient`.

---

### Task 1: Regenerate the recipe fixture

Reshapes `recipes.json` to the contract and writes `categories.json`. Pure data — no Swift changes — plus a test that pins the fixture to the contract so a later hand-edit cannot silently break it.

**Files:**
- Modify: `RecipeTest/Resources/MockData/recipes.json`
- Create: `RecipeTest/Resources/MockData/categories.json`
- Test: `Tests/Resources/RecipeFixtureTests.swift`

**Interfaces:**
- Consumes: nothing.
- Produces: the fixture shape every later task decodes — top-level keys `id`, `title`, `description`, `category`, `cuisine`, `meal_type`, `total_time_minutes`, `servings`, `difficulty`, `is_vegetarian`, `hero_image_url`, `gallery`, `ingredients`, `steps`; ingredient keys `quantity_text`, `name`, `image_url`, `is_main`; category keys `id`, `name`, `image_url`, `recipe_count`.

- [ ] **Step 1: Write the failing fixture-contract test**

Create `Tests/Resources/RecipeFixtureTests.swift`. It loads the shipped app fixture out of the app bundle and asserts the contract, including Review Focus item 4 (an ingredient with no photograph is allowed, and at least one really has none).

```swift
import Foundation
import Testing

@testable import RecipeTest

struct RecipeFixtureTests {
  private static let allowedTopLevelKeys: Set<String> = [
    "id", "title", "description", "category", "cuisine", "meal_type",
    "total_time_minutes", "servings", "difficulty", "is_vegetarian",
    "hero_image_url", "gallery", "ingredients", "steps",
  ]

  private static let categories: Set<String> = ["Meal", "Rice", "Snacks", "Desserts", "Vegan", "Pasta"]
  private static let difficulties: Set<String> = ["easy", "medium", "hard"]

  private func rows(_ name: String) throws -> [[String: Any]] {
    let url = try #require(Bundle(for: BundleMarker.self).url(forResource: name, withExtension: "json"))
    let data = try Data(contentsOf: url)

    return try #require(JSONSerialization.jsonObject(with: data) as? [[String: Any]])
  }

  /// every recipe carries the contract's keys and nothing else
  @Test
  func recipeKeys() throws {
    let recipes = try rows("recipes")
    #expect(recipes.count == 36)

    for recipe in recipes {
      #expect(Set(recipe.keys) == Self.allowedTopLevelKeys)
      #expect(Self.categories.contains(try #require(recipe["category"] as? String)))
      #expect(Self.difficulties.contains(try #require(recipe["difficulty"] as? String)))
      #expect(recipe["is_vegetarian"] is Bool)
      #expect(try #require(recipe["steps"] as? [String]).isEmpty == false)
      #expect(try #require(recipe["gallery"] as? [String]).count == 3)
    }
  }

  /// ingredients are flat, and a missing photograph is allowed
  @Test
  func ingredients() throws {
    let recipes = try rows("recipes")
    var sawMissingImage = false

    for recipe in recipes {
      let ingredients = try #require(recipe["ingredients"] as? [[String: Any]])
      #expect(ingredients.isEmpty == false)
      #expect(ingredients.filter { $0["is_main"] as? Bool == true }.count <= 6)

      for ingredient in ingredients {
        #expect(Set(ingredient.keys) == ["quantity_text", "name", "image_url", "is_main"])
        #expect(try #require(ingredient["name"] as? String).isEmpty == false)

        if ingredient["image_url"] is NSNull { sawMissingImage = true }
      }
    }

    #expect(sawMissingImage, "the mapper must cope with a null ingredient image")
  }

  /// every image URL is absolute and no gallery photograph repeats
  @Test
  func images() throws {
    let recipes = try rows("recipes")
    var seen = Set<String>()

    for recipe in recipes {
      let hero = try #require(recipe["hero_image_url"] as? String)
      #expect(URL(string: hero)?.scheme == "https")

      for photo in try #require(recipe["gallery"] as? [String]).dropFirst() {
        #expect(URL(string: photo)?.scheme == "https")
        #expect(seen.insert(photo).inserted, "gallery photograph reused: \(photo)")
      }
    }
  }

  /// categories cover every recipe exactly once
  @Test
  func categories() throws {
    let recipes = try rows("recipes")
    let categories = try rows("categories")

    #expect(Set(categories.compactMap { $0["name"] as? String }) == Self.categories)

    for category in categories {
      #expect(Set(category.keys) == ["id", "name", "image_url", "recipe_count"])
      let name = try #require(category["name"] as? String)
      let expected = recipes.filter { $0["category"] as? String == name }.count
      #expect(category["recipe_count"] as? Int == expected)
    }

    #expect(categories.compactMap { $0["recipe_count"] as? Int }.reduce(0, +) == recipes.count)
  }
}

/// Anchors `Bundle(for:)` on the app bundle the fixture ships in.
private final class BundleMarker {}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `xcodebuild test -scheme RecipeTest -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:RecipeTestTests/RecipeFixtureTests`
Expected: FAIL — the current fixture has `slug`, `author`, `nutrition` and grouped ingredients, so `Set(recipe.keys) == allowedTopLevelKeys` fails on row one, and `categories.json` does not exist.

- [ ] **Step 3: Write the generator script**

This is a one-off transform, not shipped code. Write it to the scratchpad, not the repository.

Create `<scratchpad>/reshape_fixture.py`:

```python
"""One-off: reshape recipes.json to the prototype contract and emit categories.json."""
import json, re, time, unicodedata, urllib.parse, urllib.request
from pathlib import Path

REPO = Path("/Users/dan/Documents/Personal/Projects/recipe-test")
PROTO = Path("/Users/dan/Documents/Personal/Projects/B App/bokkie-bites-prototype.html")
MOCK = REPO / "RecipeTest/Resources/MockData"

CATEGORY = {
    "rcp-001": "Pasta", "rcp-002": "Pasta", "rcp-003": "Meal", "rcp-004": "Meal",
    "rcp-005": "Meal", "rcp-006": "Meal", "rcp-007": "Vegan", "rcp-008": "Meal",
    "rcp-009": "Meal", "rcp-010": "Meal", "rcp-011": "Meal", "rcp-012": "Meal",
    "rcp-013": "Rice", "rcp-014": "Rice", "rcp-015": "Meal", "rcp-016": "Meal",
    "rcp-017": "Meal", "rcp-018": "Meal", "rcp-019": "Snacks", "rcp-020": "Rice",
    "rcp-021": "Snacks", "rcp-022": "Snacks", "rcp-023": "Snacks", "rcp-024": "Snacks",
    "rcp-025": "Vegan", "rcp-026": "Meal", "rcp-027": "Meal", "rcp-028": "Meal",
    "rcp-029": "Vegan", "rcp-030": "Meal", "rcp-031": "Meal", "rcp-032": "Rice",
    "rcp-033": "Desserts", "rcp-034": "Desserts", "rcp-035": "Desserts", "rcp-036": "Desserts",
}

# Abbreviated the way the prototype prints them; the plural is only used above 1.
UNITS = {
    "gram": ("g", "g"), "millilitre": ("ml", "ml"), "litre": ("l", "l"),
    "ounce": ("oz", "oz"), "pound": ("lb", "lb"),
    "tablespoon": ("tbsp", "tbsp"), "teaspoon": ("tsp", "tsp"),
    "cup": ("cup", "cups"), "clove": ("clove", "cloves"), "handful": ("handful", "handfuls"),
    "pinch": ("pinch", "pinches"), "leaf": ("leaf", "leaves"), "sprig": ("sprig", "sprigs"),
    "can": ("can", "cans"), "bunch": ("bunch", "bunches"), "slice": ("slice", "slices"),
}
FRACTIONS = {0.25: "¼", 0.3333: "⅓", 0.5: "½", 0.75: "¾"}
# Notes that describe *how much*, not *what kind* — these become the quantity text.
AMOUNT_NOTES = {"as required": "to taste", "to taste": "to taste", "to serve": "to serve",
                "sprinkling": "a sprinkling", "for frying": "for frying", "frying": "for frying"}
# Never a "main ingredient": the carousel should show what the dish is, not the pantry.
STAPLES = ("salt", "water", "oil", "black pepper", "peppercorn", "white pepper")


def strip_accents(value):
    return "".join(c for c in unicodedata.normalize("NFD", value) if unicodedata.category(c) != "Mn")


def number(value):
    whole, rest = int(value), round(value - int(value), 4)
    glyph = FRACTIONS.get(rest)
    if glyph:
        return f"{whole}{glyph}" if whole else glyph
    return str(whole) if rest == 0 else f"{value:g}"


def quantity_text(ing):
    qty, unit, note = ing["quantity"], ing["unit"], (ing["note"] or "").strip()
    amount_note = AMOUNT_NOTES.get(note.lower())
    if qty is None:
        return amount_note or "to taste"
    text = number(qty)
    if unit:
        singular, plural = UNITS[unit]
        text = f"{text} {singular if qty <= 1 else plural}"
    return text


def ingredient_name(ing):
    """Descriptor notes fold into the name, the way the prototype writes 'garlic, crushed'."""
    note = (ing["note"] or "").strip()
    if not note or note.lower() in AMOUNT_NOTES:
        return ing["name"]
    return f"{ing['name']}, {note.lower()}"


def is_main(name, taken):
    lowered = strip_accents(name).lower()
    if any(staple in lowered for staple in STAPLES):
        return False
    return taken < 6


def unsplash_pool():
    html = PROTO.read_text(encoding="utf-8", errors="replace")
    seen, pool = set(), []
    for match in re.findall(r"['\"](\d{13}-[0-9a-f]{12})['\"]", html):
        if match not in seen:
            seen.add(match)
            pool.append(match)
    return pool


def ingredient_photos():
    html = PROTO.read_text(encoding="utf-8", errors="replace")
    block = re.search(r"const PH_I\s*=\s*(\{.*?\});", html, re.S).group(1)
    return {k.lower(): v for k, v in json.loads(block).items()}


def unsplash_url(photo_id, w, h):
    return f"https://images.unsplash.com/photo-{photo_id}?auto=format&fit=crop&w={w}&h={h}&q=70"


def hero_url(title):
    endpoint = "https://www.themealdb.com/api/json/v1/1/search.php?s=" + urllib.parse.quote(title)
    meals = json.load(urllib.request.urlopen(endpoint, timeout=20))["meals"]
    return meals[0]["strMealThumb"]


recipes = json.loads((MOCK / "recipes.json").read_text())
pool, photos, cursor = unsplash_pool(), ingredient_photos(), 0
out = []

for recipe in recipes:
    flat, taken = [], 0
    for group in recipe["ingredient_groups"]:
        for ing in group["ingredients"]:
            name = ingredient_name(ing)
            main = is_main(name, taken)
            taken += main
            key = strip_accents(ing["name"]).lower()
            photo = photos.get(key)
            flat.append({
                "quantity_text": quantity_text(ing),
                "name": name,
                "image_url": unsplash_url(photo, 320, 320) if photo else None,
                "is_main": main,
            })

    hero = hero_url(recipe["title"])
    gallery = [hero] + [unsplash_url(pool[cursor + i], 780, 760) for i in range(2)]
    cursor += 2

    out.append({
        "id": recipe["id"],
        "title": recipe["title"],
        "description": recipe["short_description"],
        "category": CATEGORY[recipe["id"]],
        "cuisine": recipe["cuisine"],
        "meal_type": recipe["meal_type"],
        "total_time_minutes": recipe["total_time_minutes"],
        "servings": recipe["servings"],
        "difficulty": recipe["difficulty"],
        "is_vegetarian": bool({"vegetarian", "vegan"} & set(recipe["dietary_attributes"])),
        "hero_image_url": hero,
        "gallery": gallery,
        "ingredients": flat,
        "steps": [step["text"] for step in sorted(recipe["steps"], key=lambda s: s["number"])],
    })
    time.sleep(0.2)

(MOCK / "recipes.json").write_text(json.dumps(out, indent=2, ensure_ascii=False) + "\n")

names = ["Meal", "Rice", "Snacks", "Desserts", "Vegan", "Pasta"]
tiles = json.loads(re.search(r"const PH_C\s*=\s*(\{.*?\});", PROTO.read_text(encoding="utf-8", errors="replace"), re.S)
                   .group(1).replace("Meal:", '"Meal":').replace("Rice:", '"Rice":')
                   .replace("Snacks:", '"Snacks":').replace("Desserts:", '"Desserts":')
                   .replace("Vegan:", '"Vegan":').replace("Pasta:", '"Pasta":'))
categories = [{
    "id": f"cat-{i + 1:02d}",
    "name": name,
    "image_url": unsplash_url(tiles[name], 480, 480),
    "recipe_count": sum(1 for r in out if r["category"] == name),
} for i, name in enumerate(names)]

(MOCK / "categories.json").write_text(json.dumps(categories, indent=2, ensure_ascii=False) + "\n")
print("recipes", len(out), "categories", len(categories), "unsplash used", cursor)
```

- [ ] **Step 4: Run the generator and verify every URL resolves**

```bash
python3 <scratchpad>/reshape_fixture.py
python3 - <<'PY'
import json, urllib.request
from pathlib import Path
MOCK = Path("/Users/dan/Documents/Personal/Projects/recipe-test/RecipeTest/Resources/MockData")
urls = set()
for r in json.loads((MOCK / "recipes.json").read_text()):
    urls.update([r["hero_image_url"], *r["gallery"]])
    urls.update(i["image_url"] for i in r["ingredients"] if i["image_url"])
urls.update(c["image_url"] for c in json.loads((MOCK / "categories.json").read_text()))
bad = []
for u in sorted(urls):
    req = urllib.request.Request(u, method="HEAD")
    try:
        if urllib.request.urlopen(req, timeout=20).status != 200:
            bad.append(u)
    except Exception as e:
        bad.append(f"{u} :: {e}")
print(f"checked {len(urls)}; bad {len(bad)}")
for b in bad:
    print(" ", b)
PY
```

Expected: `bad 0`. Any URL that fails is replaced with the next unused id from the prototype pool and the check is re-run — a dead image in the fixture is a broken screen.

- [ ] **Step 5: Run the fixture test to verify it passes**

Run: `xcodebuild test -scheme RecipeTest -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:RecipeTestTests/RecipeFixtureTests`
Expected: PASS — 4 tests.

- [ ] **Step 6: Commit**

```bash
git add RecipeTest/Resources/MockData/recipes.json \
        RecipeTest/Resources/MockData/categories.json \
        Tests/Resources/RecipeFixtureTests.swift
git commit -m "feat(recipe): reshape the fixture to the prototype contract"
```

---

### Task 2: Serve real photographs

Removes the generated-placeholder image path so the fixture's real URLs reach the network.

**Files:**
- Modify: `RecipeTest/Modules/Core/Clients/API/Mock/MockEndpoint.swift`
- Modify: `RecipeTest/Modules/Core/Clients/API/Mock/MockAPIRouter.swift`
- Modify: `RecipeTest/App/AppContainer.swift:117-124`
- Test: `Tests/Modules/Core/Clients/API/Mock/MockEndpointTests.swift`

**Interfaces:**
- Consumes: nothing.
- Produces: `MockEndpoint` with no `image` case; `MockEndpoint.match(path:method:)` returns `nil` for an `/images/…` path.

- [ ] **Step 1: Write the failing test**

Replace the image-matching tests in `MockEndpointTests.swift` with:

```swift
@Test("an image path is no longer mocked, so real photographs reach the network")
func imagePathIsNotMatched() {
  #expect(MockEndpoint.match(path: "/api/v1/images/hero.png", method: "GET") == nil)
}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `xcodebuild test -scheme RecipeTest -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:RecipeTestTests/MockEndpointTests`
Expected: FAIL — `match` still returns `.image(seed: "hero")`.

- [ ] **Step 3: Delete the image path**

In `MockEndpoint.swift`: delete `case image(seed: String)`, the `components.dropLast().last == "images"` branch in `match`, and the `.image` arm of `fixtureName`, `isPaginated`, `fixtureRowID` and `contentType`.

In `MockAPIRouter.swift`: delete the `if case let .image(seed) = endpoint` branch in `response(for:)`, the whole `// MARK: - Images` extension (`imageData(seed:)` and `stableHash(_:)`), and `import UIKit`.

In `AppContainer.swift`, delete the Kingfisher block, leaving:

```swift
    if config.usesMockAPI {
      MockURLProtocol.router = MockAPIRouter(
        configuration: .init(
          latency: .milliseconds(400),
          failureMode: .none
        )
      )
    }
```

and delete `import Kingfisher` if nothing else in the file uses it.

- [ ] **Step 4: Run the Core mock suites to verify they pass**

Run: `xcodebuild test -scheme RecipeTest -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:RecipeTestTests/MockEndpointTests -only-testing:RecipeTestTests/MockAPIRouterTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add RecipeTest/Modules/Core/Clients/API/Mock/MockEndpoint.swift \
        RecipeTest/Modules/Core/Clients/API/Mock/MockAPIRouter.swift \
        RecipeTest/App/AppContainer.swift \
        Tests/Modules/Core/Clients/API/Mock/MockEndpointTests.swift
git commit -m "refactor(core): drop the generated placeholder image endpoint"
```

---

### Task 3: The summary chain

`RemoteRecipeSummary` → `RecipeSummary` → `RecipeSummaryMapper`, reshaped together because Swift will not compile a half-reshaped type graph.

**Files:**
- Modify: `RecipeTest/Modules/Recipe/Models/Remote/RemoteRecipeSummary.swift`
- Modify: `RecipeTest/Modules/Recipe/Models/Domain/RecipeSummary.swift`
- Modify: `RecipeTest/Modules/Recipe/Services/RecipeSummaryMapper.swift`
- Modify: `Tests/Mocks/Modules/Recipe/Models/DummyRemoteRecipeSummary.swift`
- Test: `Tests/Modules/Recipe/Services/RecipeSummaryMapperTests.swift`, `Tests/Modules/Recipe/Clients/API/GetRecipes/GetRecipesTests.swift` (+ `_200.json`)

**Interfaces:**
- Consumes: Task 1's fixture keys.
- Produces:
  - `RemoteRecipeSummary(id:title:category:cuisine:mealType:totalTimeMinutes:servings:difficulty:isVegetarian:heroImageUrl:)`, all optional
  - `RecipeSummary(id:title:heroImageURL:category:cuisine:mealType:totalTimeMinutes:servings:difficulty:isVegetarian:)`
  - `RecipeSummaryMapper.toDomain(from: RemoteRecipeSummary) -> RecipeSummary?`

- [ ] **Step 1: Write the failing mapper tests**

Replace the body of `RecipeSummaryMapperTests.swift`:

```swift
struct RecipeSummaryMapperTests {
  /// maps every field a list row renders
  @Test
  func mapsFields() throws {
    let remote = RemoteRecipeSummary.dummy(
      id: "rcp-001",
      title: "Spaghetti alla Carbonara",
      category: "Pasta",
      cuisine: "italian",
      mealType: "dinner",
      totalTimeMinutes: 25,
      servings: 4,
      difficulty: "medium",
      isVegetarian: false,
      heroImageUrl: "https://example.com/hero.jpg"
    )

    let summary = try #require(RecipeSummaryMapper.toDomain(from: remote))

    #expect(summary.id == "rcp-001")
    #expect(summary.title == "Spaghetti alla Carbonara")
    #expect(summary.category == "Pasta")
    #expect(summary.cuisine == "italian")
    #expect(summary.mealType == "dinner")
    #expect(summary.totalTimeMinutes == 25)
    #expect(summary.servings == 4)
    #expect(summary.difficulty == .medium)
    #expect(summary.isVegetarian == false)
    #expect(summary.heroImageURL == URL(string: "https://example.com/hero.jpg"))
  }

  /// drops a row with no id
  @Test
  func dropsRowWithoutID() {
    #expect(RecipeSummaryMapper.toDomain(from: .dummy(id: nil)) == nil)
  }

  /// drops a row with no title
  @Test
  func dropsRowWithoutTitle() {
    #expect(RecipeSummaryMapper.toDomain(from: .dummy(title: nil)) == nil)
  }

  /// an unrecognised difficulty is nil, not a dropped row
  @Test
  func unknownDifficulty() throws {
    let summary = try #require(RecipeSummaryMapper.toDomain(from: .dummy(difficulty: "impossible")))
    #expect(summary.difficulty == nil)
  }

  /// a missing vegetarian flag falls back to false
  @Test
  func missingVegetarianFlag() throws {
    let summary = try #require(RecipeSummaryMapper.toDomain(from: .dummy(isVegetarian: nil)))
    #expect(summary.isVegetarian == false)
  }

  /// a malformed hero URL is nil, not a dropped row
  @Test
  func malformedHeroURL() throws {
    let summary = try #require(RecipeSummaryMapper.toDomain(from: .dummy(heroImageUrl: "")))
    #expect(summary.heroImageURL == nil)
  }
}
```

- [ ] **Step 2: Run them to verify they fail**

Run: `xcodebuild test -scheme RecipeTest -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:RecipeTestTests/RecipeSummaryMapperTests`
Expected: FAIL to compile — `RemoteRecipeSummary.dummy` has no `category` parameter.

- [ ] **Step 3: Reshape the three types**

`RemoteRecipeSummary.swift`:

```swift
/// One row of `GET recipes`, exactly as the wire sends it.
///
/// Decodes only what `RecipeSummary` carries. The endpoint returns whole rows —
/// description, gallery, ingredients and steps included — and leaving them out here is
/// what decides a list row's cost.
///
/// Every property is optional on purpose: one malformed field must not fail a whole page.
nonisolated struct RemoteRecipeSummary: APIModel, Decodable, Equatable {
  let id: String?
  let title: String?
  let category: String?
  let cuisine: String?
  let mealType: String?
  let totalTimeMinutes: Int?
  let servings: Int?
  let difficulty: String?
  let isVegetarian: Bool?
  let heroImageUrl: String?
}
```

`RecipeSummary.swift`: replace the stored properties with the spec's list — `id`, `title`, `heroImageURL`, `category`, `cuisine`, `mealType`, `totalTimeMinutes`, `servings`, `difficulty`, `isVegetarian` — keeping the existing doc comment's explanation of why it is separate from `Recipe`, and adding the split rule:

```swift
/// One row of the recipe list, as the app uses it.
///
/// Carries the row's identity, its photograph and its facets; the prose and the three
/// collections belong to `Recipe`. A list cell that had to fetch a detail to render its
/// own subtitle would defeat the split.
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

`RecipeSummaryMapper.swift`:

```swift
/// Turns `RemoteRecipeSummary` into `RecipeSummary`.
///
/// The only place both the wire's shape and the app's shape are visible, which is what
/// keeps a backend key rename from reaching any screen.
nonisolated enum RecipeSummaryMapper {
  /// Returns `nil` when the row has no id or no title — there is no sensible stand-in for
  /// either, and a row the app cannot identify or label is not worth showing.
  static func toDomain(from remote: RemoteRecipeSummary) -> RecipeSummary? {
    guard
      let id = remote.id,
      let title = remote.title
    else { return nil }

    return RecipeSummary(
      id: id,
      title: title,
      heroImageURL: remote.heroImageUrl.flatMap(URL.init(string:)),
      category: remote.category,
      cuisine: remote.cuisine,
      mealType: remote.mealType,
      totalTimeMinutes: remote.totalTimeMinutes,
      servings: remote.servings,
      difficulty: remote.difficulty.flatMap(RecipeDifficulty.init(rawValue:)),
      isVegetarian: remote.isVegetarian ?? false
    )
  }
}
```

Update `DummyRemoteRecipeSummary.swift` so `.dummy` takes one defaulted parameter per property, in the same order, defaulting to a valid row (`id: "rcp-001"`, `title: "Spaghetti alla Carbonara"`, `category: "Pasta"`, `cuisine: "italian"`, `mealType: "dinner"`, `totalTimeMinutes: 25`, `servings: 4`, `difficulty: "medium"`, `isVegetarian: false`, `heroImageUrl: "https://example.com/hero.jpg"`).

- [ ] **Step 4: Update the decoding fixture and suite**

Rewrite `Tests/Modules/Recipe/Clients/API/GetRecipes/GetRecipesTests_200.json` so `data` holds two rows in the new shape and `meta` is unchanged, then update `GetRecipesTests` to assert `category`, `cuisine`, `servings` and `isVegetarian` decode from snake_case keys:

```swift
@Test("decodes a page of summaries, snake_case included")
func decodesPage() throws {
  let sut = try makeSUT()

  let rows: [RemoteRecipeSummary]? = try sut.decodedValue()

  #expect(rows?.count == 2)
  #expect(rows?.first?.category == "Pasta")
  #expect(rows?.first?.totalTimeMinutes == 25)
  #expect(rows?.first?.isVegetarian == false)
  #expect(rows?.first?.heroImageUrl?.hasPrefix("https://") == true)
}
```

- [ ] **Step 5: Run both suites to verify they pass**

Run: `xcodebuild test -scheme RecipeTest -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:RecipeTestTests/RecipeSummaryMapperTests -only-testing:RecipeTestTests/GetRecipesTests`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add RecipeTest/Modules/Recipe/Models/Remote/RemoteRecipeSummary.swift \
        RecipeTest/Modules/Recipe/Models/Domain/RecipeSummary.swift \
        RecipeTest/Modules/Recipe/Services/RecipeSummaryMapper.swift \
        Tests/Mocks/Modules/Recipe/Models/DummyRemoteRecipeSummary.swift \
        Tests/Modules/Recipe/Services/RecipeSummaryMapperTests.swift \
        Tests/Modules/Recipe/Clients/API/GetRecipes/
git commit -m "refactor(recipe): reshape the summary chain to the prototype contract"
```

---

### Task 4: The detail chain

`RemoteRecipe` → `Recipe` → `RecipeMapper`, and the five now-unreferenced domain types are deleted.

**Files:**
- Modify: `RecipeTest/Modules/Recipe/Models/Remote/RemoteRecipe.swift`
- Modify: `RecipeTest/Modules/Recipe/Models/Domain/Recipe.swift`
- Modify: `RecipeTest/Modules/Recipe/Services/RecipeMapper.swift`
- Delete: `Models/Domain/RecipeAuthor.swift`, `RecipeNutrition.swift`, `RecipeMedia.swift`, `RecipeStep.swift`, `RecipeIngredientGroup.swift`
- Modify: `Tests/Mocks/Modules/Recipe/Models/DummyRemoteRecipe.swift`
- Test: `Tests/Modules/Recipe/Services/RecipeMapperTests.swift`, `Tests/Modules/Recipe/Clients/API/GetRecipe/GetRecipeTests.swift` (+ both fixtures)

**Interfaces:**
- Consumes: `RecipeDifficulty`.
- Produces:
  - `RemoteRecipeIngredient(quantityText:name:imageUrl:isMain:)`, all optional
  - `RemoteRecipe(…summary fields…, description:gallery:ingredients:steps:)`, all optional
  - `RecipeIngredient(id:quantityText:name:imageURL:isMain:)`
  - `Recipe(…summary fields…, description:gallery:ingredients:steps:)`
  - `RecipeMapper.toDomain(from: RemoteRecipe) -> Recipe?`

- [ ] **Step 1: Write the failing mapper tests**

Replace the body of `RecipeMapperTests.swift`:

```swift
struct RecipeMapperTests {
  /// maps the detail's own fields
  @Test
  func mapsDetail() throws {
    let remote = RemoteRecipe.dummy(
      id: "rcp-001",
      title: "Spaghetti alla Carbonara",
      description: "Roman pasta bound with egg yolk and pecorino.",
      gallery: ["https://example.com/1.jpg", "https://example.com/2.jpg"],
      ingredients: [
        .init(quantityText: "320 g", name: "Spaghetti", imageUrl: "https://example.com/s.jpg", isMain: true),
        .init(quantityText: "to taste", name: "Salt", imageUrl: nil, isMain: false),
      ],
      steps: ["Boil the water.", "Toss off the heat."]
    )

    let recipe = try #require(RecipeMapper.toDomain(from: remote))

    #expect(recipe.description == "Roman pasta bound with egg yolk and pecorino.")
    #expect(recipe.gallery.count == 2)
    #expect(recipe.steps == ["Boil the water.", "Toss off the heat."])
    #expect(recipe.ingredients.count == 2)
    #expect(recipe.ingredients.first?.quantityText == "320 g")
    #expect(recipe.ingredients.first?.isMain == true)
  }

  /// ingredient ids are synthesised from the recipe id and position
  @Test
  func synthesisesIngredientIDs() throws {
    let recipe = try #require(RecipeMapper.toDomain(from: .dummy(
      id: "rcp-007",
      ingredients: [
        .init(name: "Tofu"),
        .init(name: "Rice paper"),
      ]
    )))

    #expect(recipe.ingredients.map(\.id) == ["rcp-007-0", "rcp-007-1"])
  }

  /// an ingredient with no photograph maps, it does not drop
  @Test
  func ingredientWithoutPhoto() throws {
    let recipe = try #require(RecipeMapper.toDomain(from: .dummy(
      ingredients: [.init(name: "Salt", imageUrl: nil)]
    )))

    #expect(recipe.ingredients.count == 1)
    #expect(recipe.ingredients.first?.imageURL == nil)
  }

  /// an ingredient with no name is dropped, the recipe is not
  @Test
  func ingredientWithoutName() throws {
    let recipe = try #require(RecipeMapper.toDomain(from: .dummy(
      ingredients: [.init(name: nil), .init(name: "Spaghetti")]
    )))

    #expect(recipe.ingredients.map(\.name) == ["Spaghetti"])
  }

  /// absent collections fall back to empty, not nil
  @Test
  func absentCollections() throws {
    let recipe = try #require(RecipeMapper.toDomain(from: .dummy(
      description: nil, gallery: nil, ingredients: nil, steps: nil
    )))

    #expect(recipe.description.isEmpty)
    #expect(recipe.gallery.isEmpty)
    #expect(recipe.ingredients.isEmpty)
    #expect(recipe.steps.isEmpty)
  }

  /// drops a row with no id
  @Test
  func dropsRowWithoutID() {
    #expect(RecipeMapper.toDomain(from: .dummy(id: nil)) == nil)
  }

  /// drops a row with no title
  @Test
  func dropsRowWithoutTitle() {
    #expect(RecipeMapper.toDomain(from: .dummy(title: nil)) == nil)
  }
}
```

- [ ] **Step 2: Run them to verify they fail**

Run: `xcodebuild test -scheme RecipeTest -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:RecipeTestTests/RecipeMapperTests`
Expected: FAIL to compile — `RemoteRecipe.dummy` has no `ingredients:` of this type.

- [ ] **Step 3: Reshape the detail types and delete the five orphans**

`RemoteRecipe.swift` — the summary's fields plus the detail's, and the one nested DTO:

```swift
nonisolated struct RemoteRecipe: APIModel, Decodable, Equatable {
  let id: String?
  let title: String?
  let description: String?
  let category: String?
  let cuisine: String?
  let mealType: String?
  let totalTimeMinutes: Int?
  let servings: Int?
  let difficulty: String?
  let isVegetarian: Bool?
  let heroImageUrl: String?
  let gallery: [String]?
  let ingredients: [RemoteRecipeIngredient]?
  let steps: [String]?
}

/// Lives here rather than in its own file: an ingredient exists only inside a recipe, and
/// the two are only ever read together.
nonisolated struct RemoteRecipeIngredient: APIModel, Decodable, Equatable {
  let quantityText: String?
  let name: String?
  let imageUrl: String?
  let isMain: Bool?
}
```

`Recipe.swift`:

```swift
/// A full recipe, as the app uses it.
///
/// Carries the summary's fields as well as the detail's, so a detail screen reached
/// without a preceding list fetch needs nothing else.
nonisolated struct Recipe: Equatable, Identifiable {
  let id: String
  let title: String
  let description: String
  let heroImageURL: URL?
  let category: String?
  let cuisine: String?
  let mealType: String?
  let totalTimeMinutes: Int?
  let servings: Int?
  let difficulty: RecipeDifficulty?
  let isVegetarian: Bool
  let gallery: [URL]
  let ingredients: [RecipeIngredient]
  let steps: [String]
}

/// One line of the ingredients checklist.
///
/// `quantityText` is a display string, not a number and a unit: the source data cannot
/// support arithmetic — a third of its ingredients have no unit — and nothing in the
/// product does arithmetic on it.
nonisolated struct RecipeIngredient: Equatable, Identifiable {
  let id: String
  let quantityText: String
  let name: String
  let imageURL: URL?
  let isMain: Bool
}
```

`RecipeMapper.swift`:

```swift
nonisolated enum RecipeMapper {
  static func toDomain(from remote: RemoteRecipe) -> Recipe? {
    guard
      let id = remote.id,
      let title = remote.title
    else { return nil }

    return Recipe(
      id: id,
      title: title,
      description: remote.description ?? "",
      heroImageURL: remote.heroImageUrl.flatMap(URL.init(string:)),
      category: remote.category,
      cuisine: remote.cuisine,
      mealType: remote.mealType,
      totalTimeMinutes: remote.totalTimeMinutes,
      servings: remote.servings,
      difficulty: remote.difficulty.flatMap(RecipeDifficulty.init(rawValue:)),
      isVegetarian: remote.isVegetarian ?? false,
      gallery: (remote.gallery ?? []).compactMap(URL.init(string:)),
      ingredients: ingredients(from: remote.ingredients ?? [], recipeID: id),
      steps: remote.steps ?? []
    )
  }
}

// MARK: - Ingredients

private nonisolated extension RecipeMapper {
  /// Identity is synthesised from the recipe id and the ingredient's position: the
  /// contract carries no ingredient ids, but a `ForEach` still needs stable identity, and
  /// position within a recipe is stable.
  ///
  /// `enumerated()` runs before the `compactMap` so a dropped ingredient does not
  /// renumber the ones after it.
  static func ingredients(from remote: [RemoteRecipeIngredient], recipeID: String) -> [RecipeIngredient] {
    remote.enumerated().compactMap { index, ingredient in
      guard let name = ingredient.name else { return nil }

      return RecipeIngredient(
        id: "\(recipeID)-\(index)",
        quantityText: ingredient.quantityText ?? "",
        name: name,
        imageURL: ingredient.imageUrl.flatMap(URL.init(string:)),
        isMain: ingredient.isMain ?? false
      )
    }
  }
}
```

Then `git rm` the five orphans: `RecipeAuthor.swift`, `RecipeNutrition.swift`, `RecipeMedia.swift`, `RecipeStep.swift`, `RecipeIngredientGroup.swift`.

Update `DummyRemoteRecipe.swift` to one defaulted parameter per property, and add a `.dummy`-style memberwise default init for `RemoteRecipeIngredient` so `.init(name: "Tofu")` compiles (every parameter defaulted to `nil`).

- [ ] **Step 4: Update the decoding fixtures and suite**

Rewrite `GetRecipeTests_200.json` as one whole row in the new shape (three gallery URLs, six flat ingredients of which one has `"image_url": null`, six string steps) and `GetRecipeTests_200_minimal.json` as `{"id": "rcp-036", "title": "Vegan Chocolate Cake"}` with everything else absent. Update the suite:

```swift
@Test("decodes a whole recipe")
func decodesDetail() throws {
  let sut = try #require(try makeSUT())

  #expect(sut.gallery?.count == 3)
  #expect(sut.steps?.count == 6)
  #expect(sut.ingredients?.count == 6)
  #expect(sut.ingredients?.contains { $0.imageUrl == nil } == true)
  #expect(sut.isVegetarian == false)
}

@Test("a row with only the required fields decodes, the rest nil")
func decodesMinimal() throws {
  let sut = try #require(try makeSUT(fixture: "GetRecipeTests_200_minimal"))

  #expect(sut.id == "rcp-036")
  #expect(sut.ingredients == nil)
  #expect(sut.steps == nil)
}
```

- [ ] **Step 5: Run both suites to verify they pass**

Run: `xcodebuild test -scheme RecipeTest -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:RecipeTestTests/RecipeMapperTests -only-testing:RecipeTestTests/GetRecipeTests`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add -A RecipeTest/Modules/Recipe/Models Tests/Modules/Recipe Tests/Mocks/Modules/Recipe \
        RecipeTest/Modules/Recipe/Services/RecipeMapper.swift
git commit -m "refactor(recipe): flatten the detail chain to the prototype contract"
```

---

### Task 5: The category chain

Purely additive — `RemoteRecipeCategory`, `RecipeCategory`, `RecipeCategoryMapper`.

**Files:**
- Create: `RecipeTest/Modules/Recipe/Models/Remote/RemoteRecipeCategory.swift`
- Create: `RecipeTest/Modules/Recipe/Models/Domain/RecipeCategory.swift`
- Create: `RecipeTest/Modules/Recipe/Services/RecipeCategoryMapper.swift`
- Test: `Tests/Modules/Recipe/Services/RecipeCategoryMapperTests.swift`

**Interfaces:**
- Consumes: nothing.
- Produces: `RemoteRecipeCategory(id:name:imageUrl:recipeCount:)`, `RecipeCategory(id:name:imageURL:recipeCount:)`, `RecipeCategoryMapper.toDomain(from:) -> RecipeCategory?`

- [ ] **Step 1: Write the failing test**

```swift
import Foundation
import Testing

@testable import RecipeTest

struct RecipeCategoryMapperTests {
  /// maps a category tile
  @Test
  func mapsTile() throws {
    let remote = RemoteRecipeCategory(
      id: "cat-01",
      name: "Meal",
      imageUrl: "https://example.com/meal.jpg",
      recipeCount: 18
    )

    let category = try #require(RecipeCategoryMapper.toDomain(from: remote))

    #expect(category.id == "cat-01")
    #expect(category.name == "Meal")
    #expect(category.imageURL == URL(string: "https://example.com/meal.jpg"))
    #expect(category.recipeCount == 18)
  }

  /// a missing count is zero, not a dropped tile
  @Test
  func missingCount() throws {
    let category = try #require(RecipeCategoryMapper.toDomain(
      from: .init(id: "cat-01", name: "Meal", imageUrl: nil, recipeCount: nil)
    ))

    #expect(category.recipeCount == 0)
    #expect(category.imageURL == nil)
  }

  /// drops a tile with no id or no name
  @Test
  func dropsIncompleteTile() {
    #expect(RecipeCategoryMapper.toDomain(from: .init(id: nil, name: "Meal", imageUrl: nil, recipeCount: 1)) == nil)
    #expect(RecipeCategoryMapper.toDomain(from: .init(id: "cat-01", name: nil, imageUrl: nil, recipeCount: 1)) == nil)
  }
}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `xcodebuild test -scheme RecipeTest -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:RecipeTestTests/RecipeCategoryMapperTests`
Expected: FAIL to compile — `RemoteRecipeCategory` does not exist.

- [ ] **Step 3: Write the three types**

```swift
nonisolated struct RemoteRecipeCategory: APIModel, Decodable, Equatable {
  let id: String?
  let name: String?
  let imageUrl: String?
  let recipeCount: Int?
}
```

```swift
/// One browse tile on the home grid.
///
/// `recipeCount` is served rather than derived: the tile prints "*n* recipes", and a
/// client cannot count what pagination has not fetched.
nonisolated struct RecipeCategory: Equatable, Identifiable {
  let id: String
  let name: String
  let imageURL: URL?
  let recipeCount: Int
}
```

```swift
nonisolated enum RecipeCategoryMapper {
  static func toDomain(from remote: RemoteRecipeCategory) -> RecipeCategory? {
    guard
      let id = remote.id,
      let name = remote.name
    else { return nil }

    return RecipeCategory(
      id: id,
      name: name,
      imageURL: remote.imageUrl.flatMap(URL.init(string:)),
      recipeCount: remote.recipeCount ?? 0
    )
  }
}
```

- [ ] **Step 4: Run it to verify it passes**

Run: `xcodebuild test -scheme RecipeTest -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:RecipeTestTests/RecipeCategoryMapperTests`
Expected: PASS — 3 tests.

- [ ] **Step 5: Commit**

```bash
git add RecipeTest/Modules/Recipe/Models/Remote/RemoteRecipeCategory.swift \
        RecipeTest/Modules/Recipe/Models/Domain/RecipeCategory.swift \
        RecipeTest/Modules/Recipe/Services/RecipeCategoryMapper.swift \
        Tests/Modules/Recipe/Services/RecipeCategoryMapperTests.swift
git commit -m "feat(recipe): add the category tile model and its mapper"
```

---

### Task 6: `RecipeQuery`

The filter value type, and the encoding that turns it into query items. Owns Review Focus item 5.

**Files:**
- Create: `RecipeTest/Modules/Recipe/Models/Domain/RecipeQuery.swift`
- Test: `Tests/Modules/Recipe/Models/RecipeQueryTests.swift`

**Interfaces:**
- Consumes: `APIRequestParameters` (Core).
- Produces: `RecipeQuery` with `.empty`, `RecipeServings`, `RecipeSort`, and `RecipeQuery.queryParameters() -> [String: Any]`.

- [ ] **Step 1: Write the failing test**

```swift
import Foundation
import Testing

@testable import RecipeTest

struct RecipeQueryTests {
  /// the empty query encodes to no parameters at all
  @Test
  func emptyEncodesToNothing() throws {
    #expect(try RecipeQuery.empty.queryParameters().isEmpty)
  }

  /// set facets encode under their snake_case wire names
  @Test
  func encodesFacets() throws {
    var query = RecipeQuery.empty
    query.searchText = "garlic"
    query.category = "Vegan"
    query.cuisine = "thai"
    query.isVegetarian = true
    query.servings = .sixOrMore
    query.includeIngredients = ["garlic", "onion"]
    query.excludeIngredients = ["peanut"]
    query.searchesSteps = true
    query.sort = .latest

    let parameters = try query.queryParameters()

    #expect(parameters["search_text"] as? String == "garlic")
    #expect(parameters["category"] as? String == "Vegan")
    #expect(parameters["cuisine"] as? String == "thai")
    #expect(parameters["is_vegetarian"] as? Bool == true)
    #expect(parameters["servings"] as? String == "6+")
    #expect(parameters["include_ingredients"] as? [String] == ["garlic", "onion"])
    #expect(parameters["exclude_ingredients"] as? [String] == ["peanut"])
    #expect(parameters["searches_steps"] as? Bool == true)
    #expect(parameters["sort"] as? String == "latest")
  }

  /// an empty ingredient list is absent, not an empty parameter
  @Test
  func emptyListsAreAbsent() throws {
    var query = RecipeQuery.empty
    query.category = "Rice"

    let parameters = try query.queryParameters()

    #expect(parameters.keys.sorted() == ["category"])
  }

  /// false is a filter, not an absence
  @Test
  func falseIsSent() throws {
    var query = RecipeQuery.empty
    query.isVegetarian = false

    #expect(try query.queryParameters()["is_vegetarian"] as? Bool == false)
  }
}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `xcodebuild test -scheme RecipeTest -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:RecipeTestTests/RecipeQueryTests`
Expected: FAIL to compile — `RecipeQuery` does not exist.

- [ ] **Step 3: Write `RecipeQuery`**

```swift
import Foundation

/// Every filter the prototype's list surfaces can apply, in one value.
///
/// A struct rather than nine parameters on `getRecipes`: `APIRequestParameters` exists for
/// exactly this case, and it supplies the snake_case-converting encoder, so the wire names
/// fall out of the property names with no hand-written mapping.
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

  /// The unfiltered query. `GET recipes` with this carries only `page` and `per_page`.
  static let empty = RecipeQuery(
    includeIngredients: [],
    excludeIngredients: [],
    searchesSteps: false
  )
}

// MARK: - Encoding

nonisolated extension RecipeQuery {
  /// Nil facets, empty lists and an un-toggled `searchesSteps` are dropped rather than
  /// sent empty: a router that receives `category=` would filter on the empty string.
  ///
  /// `false` for `isVegetarian` is kept — it is a filter the user set, not an absence.
  func queryParameters() throws -> [String: Any] {
    let data = try Self.encoder().encode(self)

    guard var parameters = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
      return [:]
    }

    for (key, value) in parameters where (value as? [String])?.isEmpty == true {
      parameters.removeValue(forKey: key)
    }

    if searchesSteps == false {
      parameters.removeValue(forKey: "searches_steps")
    }

    return parameters
  }
}

/// How many the recipe serves, as a filter.
///
/// An enum rather than an `Int` because the prototype's fourth option is `6+` — a lower
/// bound, not a value. Raw values are the wire strings, so encoding is free.
nonisolated enum RecipeServings: String, Equatable, CaseIterable, Codable {
  case one = "1"
  case two = "2"
  case four = "4"
  case sixOrMore = "6+"
}

/// The only ordering the product has. `latest` is the fixture's own order, which stores
/// newest first — nothing else can define it now that `updated_at` is gone.
nonisolated enum RecipeSort: String, Equatable, Codable {
  case latest
}
```

- [ ] **Step 4: Run it to verify it passes**

Run: `xcodebuild test -scheme RecipeTest -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:RecipeTestTests/RecipeQueryTests`
Expected: PASS — 4 tests. `Encodable` skips nil optionals by default, which is what makes the empty query encode to `{}`.

- [ ] **Step 5: Commit**

```bash
git add RecipeTest/Modules/Recipe/Models/Domain/RecipeQuery.swift \
        Tests/Modules/Recipe/Models/RecipeQueryTests.swift
git commit -m "feat(recipe): add the recipe query filter model"
```

---

### Task 7: Teach the mock router to filter

The largest task, and the one Review Focus items 1–3 belong to. Without it every filtered screen returns all 36 rows.

**Files:**
- Modify: `RecipeTest/Modules/Core/Clients/API/Mock/MockEndpoint.swift`
- Modify: `RecipeTest/Modules/Core/Clients/API/Mock/MockAPIRouter.swift`
- Test: `Tests/Modules/Core/Clients/API/Mock/MockAPIRouterTests.swift`, `MockEndpointTests.swift`

**Interfaces:**
- Consumes: Task 1's fixture, Task 6's wire names.
- Produces: `MockEndpoint.categories`; `MockAPIRouter` filtering `recipes` rows by `search_text`, `category`, `cuisine`, `is_vegetarian`, `servings`, `include_ingredients`, `exclude_ingredients`, `searches_steps` before pagination.

- [ ] **Step 1: Write the failing tests**

Add to `MockAPIRouterTests.swift`. The suite already reads the shipped `recipes.json`, so these assert against what the demo build really serves. Add two helpers next to the existing `makeSUT()` / `makeRequest(_:)` / `decode(_:)` / `rows(in:)`, so each test reads as one line:

```swift
  /// The rows a query returns, unwrapped out of the envelope.
  private func rows(forQuery query: String) throws -> [[String: Any]] {
    try rows(in: decode(makeSUT().response(for: makeRequest("/api/v1/\(query)")).body))
  }

  private func meta(forQuery query: String) throws -> [String: Any] {
    try #require(decode(makeSUT().response(for: makeRequest("/api/v1/\(query)")).body)["meta"] as? [String: Any])
  }
```

```swift
@Test("an unknown parameter does not change the result set")
func unknownParameterIsIgnored() throws {
  let all = try rows(forQuery: "recipes")
  let same = try rows(forQuery: "recipes?flavour=umami")

  #expect(all.count == same.count)
  #expect(all.isEmpty == false)
}

@Test("each filter reduces the set rather than silently passing everything")
func eachFilterReduces() throws {
  let all = try rows(forQuery: "recipes?per_page=100")

  for query in [
    "category=Pasta",
    "cuisine=italian",
    "is_vegetarian=true",
    "servings=2",
    "include_ingredients=garlic",
    "exclude_ingredients=garlic",
    "search_text=curry",
  ] {
    let filtered = try rows(forQuery: "recipes?per_page=100&\(query)")
    #expect(filtered.isEmpty == false, "\(query) matched nothing")
    #expect(filtered.count < all.count, "\(query) did not filter")
  }
}

@Test("meta.total counts matches, not the collection")
func metaCountsMatches() throws {
  let matches = try rows(forQuery: "recipes?per_page=2&category=Pasta")
  let meta = try meta(forQuery: "recipes?per_page=2&category=Pasta")

  #expect(matches.count == 2)
  #expect(meta["total"] as? Int == 2)
}

@Test("6+ means six or more, not exactly six")
func sixOrMoreIsALowerBound() throws {
  let rows = try rows(forQuery: "recipes?per_page=100&servings=6%2B")

  #expect(rows.isEmpty == false)
  #expect(rows.allSatisfy { ($0["servings"] as? Int ?? 0) >= 6 })
}

@Test("search ignores diacritics, so 'puree' finds 'purée'")
func searchIgnoresDiacritics() throws {
  let plain = try rows(forQuery: "recipes?per_page=100&search_text=puree")
  let accented = try rows(forQuery: "recipes?per_page=100&search_text=pur%C3%A9e")

  #expect(plain.isEmpty == false)
  #expect(plain.count == accented.count)
}

@Test("include_ingredients requires every term, exclude_ingredients forbids any")
func ingredientFilters() throws {
  let both = try rows(forQuery: "recipes?per_page=100&include_ingredients=garlic&include_ingredients=onion")
  let garlic = try rows(forQuery: "recipes?per_page=100&include_ingredients=garlic")

  #expect(both.count <= garlic.count)

  let without = try rows(forQuery: "recipes?per_page=100&exclude_ingredients=garlic")
  #expect(without.allSatisfy { recipe in
    let names = (recipe["ingredients"] as? [[String: Any]] ?? []).compactMap { $0["name"] as? String }
    return names.allSatisfy { $0.lowercased().contains("garlic") == false }
  })
}

@Test("searches_steps widens the search to instruction text")
func searchesSteps() throws {
  let narrow = try rows(forQuery: "recipes?per_page=100&search_text=simmer")
  let wide = try rows(forQuery: "recipes?per_page=100&search_text=simmer&searches_steps=true")

  #expect(wide.count > narrow.count)
}

@Test("the categories endpoint answers from its own fixture")
func categoriesEndpoint() throws {
  let result = try makeSUT().response(for: makeRequest("/api/v1/categories"))

  #expect(result.status == 200)
  #expect(rows(in: try decode(result.body)).count == 6)
}
```

- [ ] **Step 2: Run them to verify they fail**

Run: `xcodebuild test -scheme RecipeTest -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:RecipeTestTests/MockAPIRouterTests`
Expected: FAIL — `eachFilterReduces` fails on the first query because the router ignores every parameter, and `categoriesEndpoint` 404s.

- [ ] **Step 3: Add the categories endpoint**

In `MockEndpoint.swift`, add `case categories` with `fixtureName` `"categories"`, `isPaginated` `false`, `fixtureRowID` `nil`, `contentType` `"application/json"`, and a `case "categories": return .categories` arm in `match`.

- [ ] **Step 4: Add the filter pipeline**

In `MockAPIRouter.swift`, between loading the rows and paginating them:

```swift
    let rows = try filtered(fixtureRows(named: fixtureName), for: url)
```

and add the extension:

```swift
// MARK: - Filtering

private nonisolated extension MockAPIRouter {
  /// Stands in for the backend's query engine. A parameter this does not recognise is
  /// ignored rather than treated as "match nothing" — an unknown parameter must not
  /// silently empty a screen.
  func filtered(_ rows: [[String: Any]], for url: URL) -> [[String: Any]] {
    let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []

    func values(_ name: String) -> [String] {
      items.filter { $0.name == name }.compactMap(\.value).filter { $0.isEmpty == false }
    }

    func value(_ name: String) -> String? { values(name).first }

    var result = rows

    if let category = value("category") {
      result = result.filter { matches($0["category"], category) }
    }

    if let cuisine = value("cuisine") {
      result = result.filter { matches($0["cuisine"], cuisine) }
    }

    if let vegetarian = value("is_vegetarian").map({ $0 == "true" }) {
      result = result.filter { $0["is_vegetarian"] as? Bool == vegetarian }
    }

    if let servings = value("servings") {
      result = result.filter { row in
        let count = row["servings"] as? Int ?? 0

        // `6+` is a lower bound, not a value — the prototype's fourth serving option.
        return servings == "6+" ? count >= 6 : count == Int(servings)
      }
    }

    let included = values("include_ingredients")
    if included.isEmpty == false {
      result = result.filter { row in
        included.allSatisfy { term in ingredientNames(row).contains { $0.contains(fold(term)) } }
      }
    }

    let excluded = values("exclude_ingredients")
    if excluded.isEmpty == false {
      result = result.filter { row in
        excluded.allSatisfy { term in ingredientNames(row).contains { $0.contains(fold(term)) } == false }
      }
    }

    if let search = value("search_text").map(fold) {
      let searchesSteps = value("searches_steps") == "true"

      result = result.filter { row in
        var haystack = ["title", "description", "category", "cuisine"]
          .compactMap { row[$0] as? String }
          .map(fold)

        haystack += ingredientNames(row)

        if searchesSteps {
          haystack += (row["steps"] as? [String] ?? []).map(fold)
        }

        return haystack.contains { $0.contains(search) }
      }
    }

    return result
  }

  func ingredientNames(_ row: [String: Any]) -> [String] {
    (row["ingredients"] as? [[String: Any]] ?? [])
      .compactMap { $0["name"] as? String }
      .map(fold)
  }

  func matches(_ stored: Any?, _ wanted: String) -> Bool {
    (stored as? String).map { fold($0) == fold(wanted) } ?? false
  }

  /// Case- and diacritic-insensitive, so `pao` finds `Pão` and `puree` finds `purée`.
  func fold(_ value: String) -> String {
    value.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
  }
}
```

`sort=latest` needs no branch: fixture order is already newest-first, so accepting and ignoring it is correct.

- [ ] **Step 5: Run the suites to verify they pass**

Run: `xcodebuild test -scheme RecipeTest -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:RecipeTestTests/MockAPIRouterTests -only-testing:RecipeTestTests/MockEndpointTests`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add RecipeTest/Modules/Core/Clients/API/Mock/ Tests/Modules/Core/Clients/API/Mock/
git commit -m "feat(core): filter the mock recipe collection by query"
```

---

### Task 8: The API layer

**Files:**
- Modify: `RecipeTest/Modules/Recipe/Clients/API/RecipeAPIProtocol.swift`
- Modify: `RecipeTest/Modules/Recipe/Clients/API/APIClient+Recipe.swift`
- Create: `Tests/Modules/Recipe/Clients/API/GetCategories/GetCategoriesTests.swift` + `GetCategoriesTests_200.json`
- Test: `Tests/Modules/Recipe/Clients/API/APIClientRecipeTests.swift`

**Interfaces:**
- Consumes: `RecipeQuery.queryParameters()`, `RemoteRecipeCategory`.
- Produces: `RecipeAPIProtocol.getRecipes(query:page:perPage:)`, `.getRecipe(id:)`, `.getCategories()`.

- [ ] **Step 1: Write the failing tests**

`GetCategoriesTests.swift`:

```swift
import Foundation
import Testing

@testable import RecipeTest

struct GetCategoriesTests {
  /// decodes the category tiles
  @Test
  func decodesTiles() throws {
    let sut = try makeSUT()

    let tiles: [RemoteRecipeCategory]? = try sut.decodedValue()

    #expect(tiles?.count == 6)
    #expect(tiles?.first?.name == "Meal")
    #expect(tiles?.first?.recipeCount == 18)
  }
}

// MARK: - Helpers

private extension GetCategoriesTests {
  func makeSUT() throws -> APIResponse {
    try Fixture.apiResponse("GetCategoriesTests_200")
  }
}
```

with `GetCategoriesTests_200.json` holding the six tiles under `data`, matching Task 1's `categories.json`.

In `APIClientRecipeTests.swift`, add:

```swift
@Test("the query's parameters ride alongside page and per_page")
func sendsQueryParameters() async throws {
  var query = RecipeQuery.empty
  query.category = "Pasta"
  query.isVegetarian = true

  let parameters = try query.queryParameters()

  #expect(parameters["category"] as? String == "Pasta")
  #expect(parameters["is_vegetarian"] as? Bool == true)
  #expect(parameters["page"] == nil, "paging is the caller's, not the query's")
}
```

- [ ] **Step 2: Run them to verify they fail**

Run: `xcodebuild test -scheme RecipeTest -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:RecipeTestTests/GetCategoriesTests`
Expected: FAIL — `APIClient` has no `getCategories`, fixture missing.

- [ ] **Step 3: Widen the protocol and the conformance**

`RecipeAPIProtocol.swift`:

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

`APIClient+Recipe.swift`:

```swift
nonisolated extension APIClient: RecipeAPIProtocol {
  func getRecipes(
    query: RecipeQuery,
    page: Int,
    perPage: Int
  ) async throws -> ([RemoteRecipeSummary], RemotePaginationMetaInfo) {
    var parameters = try query.queryParameters()
    parameters["page"] = page
    parameters["per_page"] = perPage

    let response = try await request(
      "recipes",
      method: .get,
      parameters: parameters,
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

  func getCategories() async throws -> [RemoteRecipeCategory] {
    let response = try await request(
      "categories",
      method: .get,
      encoding: URLEncoding.default
    )

    return try decodeModel(response)
  }
}
```

- [ ] **Step 4: Run the API suites to verify they pass**

Run: `xcodebuild test -scheme RecipeTest -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:RecipeTestTests/GetCategoriesTests -only-testing:RecipeTestTests/APIClientRecipeTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add RecipeTest/Modules/Recipe/Clients/API/ Tests/Modules/Recipe/Clients/API/
git commit -m "feat(recipe): widen the recipe API to queries and categories"
```

---

### Task 9: The service layer

**Files:**
- Modify: `RecipeTest/Modules/Recipe/Services/RecipeServiceProtocol.swift`
- Modify: `RecipeTest/Modules/Recipe/Services/RecipeService.swift`
- Modify: `Tests/Mocks/Modules/Recipe/Clients/API/MockRecipeAPI.swift`
- Test: `Tests/Modules/Recipe/Services/RecipeServiceTests.swift`

**Interfaces:**
- Consumes: Tasks 3–8.
- Produces: `RecipeServiceProtocol.getRecipes(query:page:)`, `.getRecipe(id:)`, `.getCategories()`.

- [ ] **Step 1: Update `MockRecipeAPI`**

```swift
final class MockRecipeAPI: RecipeAPIProtocol {
  struct RecipesRequest: Equatable {
    let query: RecipeQuery
    let page: Int
    let perPage: Int
  }

  let recipes = MockAPICall<RecipesRequest, ([RemoteRecipeSummary], RemotePaginationMetaInfo)>(
    returning: ([], .dummy())
  )
  let recipe = MockAPICall<String, RemoteRecipe>(returning: .dummy())
  let categories = MockAPICall<Void, [RemoteRecipeCategory]>(returning: [])

  func getRecipes(
    query: RecipeQuery,
    page: Int,
    perPage: Int
  ) async throws -> ([RemoteRecipeSummary], RemotePaginationMetaInfo) {
    try await recipes.invoke(RecipesRequest(query: query, page: page, perPage: perPage))
  }

  func getRecipe(id: String) async throws -> RemoteRecipe {
    try await recipe.invoke(id)
  }

  func getCategories() async throws -> [RemoteRecipeCategory] {
    try await categories.invoke(())
  }
}
```

- [ ] **Step 2: Write the failing service tests**

Add to `RecipeServiceTests.swift`:

```swift
@Test("the query and the page both reach the API layer")
func forwardsQueryAndPage() async throws {
  let api = MockRecipeAPI()
  let service = RecipeService(api: api, onError: { _ in })

  var query = RecipeQuery.empty
  query.category = "Pasta"

  _ = try await service.getRecipes(query: query, page: Page(index: 2, size: 20))

  #expect(api.recipes.lastRequest == .init(query: query, page: 2, perPage: 20))
}

@Test("a malformed tile is dropped, the rest of the grid survives")
func dropsMalformedCategory() async throws {
  let api = MockRecipeAPI()
  api.categories.returns([
    .init(id: "cat-01", name: "Meal", imageUrl: nil, recipeCount: 18),
    .init(id: nil, name: "Broken", imageUrl: nil, recipeCount: 0),
  ])

  let service = RecipeService(api: api, onError: { _ in })
  let categories = try await service.getCategories()

  #expect(categories.map(\.name) == ["Meal"])
}
```

and update the existing `getRecipes` tests to pass `query: .empty`.

- [ ] **Step 3: Run them to verify they fail**

Run: `xcodebuild test -scheme RecipeTest -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:RecipeTestTests/RecipeServiceTests`
Expected: FAIL to compile — `getRecipes` takes no `query`.

- [ ] **Step 4: Widen the service**

`RecipeServiceProtocol.swift`:

```swift
nonisolated protocol RecipeServiceProtocol: AppServiceProtocol, Sendable {
  func getRecipes(query: RecipeQuery, page: Page) async throws -> RecipeListPage

  func getRecipe(id: String) async throws -> Recipe

  func getCategories() async throws -> [RecipeCategory]
}
```

In `RecipeService.swift`, change `getRecipes` to take `query` and forward it, and add:

```swift
  /// `compactMap`, like the list: a malformed tile is one missing tile on the grid, not a
  /// failed home screen.
  func getCategories() async throws -> [RecipeCategory] {
    let remote = try await api.getCategories()

    return remote.compactMap { RecipeCategoryMapper.toDomain(from: $0) }
  }
```

- [ ] **Step 5: Run the suite to verify it passes**

Run: `xcodebuild test -scheme RecipeTest -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:RecipeTestTests/RecipeServiceTests`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add RecipeTest/Modules/Recipe/Services/ Tests/Mocks/Modules/Recipe/ Tests/Modules/Recipe/Services/
git commit -m "feat(recipe): widen the service to queries and categories"
```

---

### Task 10: Verify the whole branch

**Files:** none changed unless a check fails.

- [ ] **Step 1: Full test run**

Run: `xcodebuild test -scheme RecipeTest -destination 'platform=iOS Simulator,name=iPhone 17'`
Expected: every suite passes, zero failures.

- [ ] **Step 2: Lint and format**

```bash
swiftlint --strict
swiftformat --lint .
```

Expected: both clean. Fix anything reported and re-run.

- [ ] **Step 3: Confirm nothing references a deleted type**

```bash
grep -rn "RecipeAuthor\|RecipeNutrition\|RecipeMedia\|RecipeStep\|RecipeIngredientGroup\|imageData(seed\|ingredient_groups\|dietary_attributes" RecipeTest Tests
```

Expected: no output.

- [ ] **Step 4: Run the app and look at it**

Build and run the Staging scheme on a simulator. Confirm real photographs load — that is the whole point of Task 2, and no unit test can see it.

- [ ] **Step 5: Commit any fixes**

```bash
git commit -am "chore(recipe): satisfy lint after the contract reshape"
```

---

## Done when

- `recipes.json` carries 36 rows in the contract's 14 keys, and `categories.json` carries 6 tiles whose counts sum to 36.
- Every image URL in both fixtures returns `200`, no gallery photograph is reused, and the app shows real food photographs.
- `RecipeAuthor`, `RecipeNutrition`, `RecipeMedia`, `RecipeStep` and `RecipeIngredientGroup` no longer exist.
- `RecipeServiceProtocol` exposes `getRecipes(query:page:)`, `getRecipe(id:)` and `getCategories()`.
- `MockAPIRouter` filters by every parameter in `RecipeQuery`, and `meta.total` reports matches.
- `xcodebuild test` passes, SwiftLint `--strict` and SwiftFormat `--lint` are clean.
