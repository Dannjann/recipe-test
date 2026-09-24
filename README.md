# Recipe Test
A recipe browser built as a coding exercise. It loads a bundled JSON catalogue through a real
networking stack, presents it as a home feed with browsable categories and a paginated results
list, and lets you narrow things down with a filter overlay covering text, diet, servings,
included and excluded ingredients, and instruction content.

The data ships inside the app, but everything above the socket is written as though a real API
sat behind it: request building, pagination, status code handling, envelope decoding and error
mapping. One flag swaps the fixture transport for a live one.

---

## Setup

**Requirements**

| | |
| --- | --- |
| Xcode | 26 (the project targets iOS 26 and builds in Swift 6 language mode) |
| Simulator | Any iPhone running iOS 26 or newer |
| Dependencies | Resolved by SPM on first open, nothing to install by hand |

**Run it**

```bash
git clone <repo-url>
cd recipe-test
open RecipeTest.xcodeproj
```

Pick the **RecipeTest** scheme and an iPhone simulator, then run. On the first build Xcode asks
you to trust the SwiftLint build tool plugin, so choose *Trust & Enable*. There is no
`pod install`, no `.xcworkspace` and no API key to set up: `Config/Secrets.xcconfig` is optional
and `#include?`-ed, so a missing copy will not fail the build.

**Schemes**

- `RecipeTest`: production configuration, bundle id `com.danjan.recipe`. This is the scheme the
  UI tests and the Maestro flows expect.
- `RecipeTest-Staging`: the same app against the staging configuration, installed alongside it
  as `com.danjan.recipe-dev`.

**Tests**

```bash
# Unit tests (Swift Testing) plus the launch UI test
xcodebuild test -project RecipeTest.xcodeproj -scheme RecipeTest \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

End-to-end flows live in `.maestro/` and drive the real app on a booted simulator. See
[`.maestro/README.md`](.maestro/README.md) for the build, install and run sequence, plus the
accessibility identifiers the flows select on.

**Seeing the error and empty states**

Both are wired to real state rather than a preview-only branch. `AppContainer.bootstrap()`
configures the mock transport:

```swift
MockURLProtocol.router = MockAPIRouter(
  configuration: .init(
    latency: .milliseconds(400),
    failureMode: .none      // .serverError -> every request 500s
  )                         // .empty       -> every request returns zero rows
)
```

Switching `failureMode` demonstrates both without touching any feature code, and `latency` is
what keeps the loading states visible.

---

## Features

### Home

- A six item "latest recipes" carousel and a category grid with served recipe counts. Both
  requests go out together with `async let`, so a slow one does not hold up the other.
- Pull to refresh reloads both.
- Each section settles into loading, loaded, empty or failed on its own. If the carousel fails
  you still get a working category grid.

### Search overlay

Tapping the search pill, on Home or on any results list, presents a full screen overlay that
edits a draft query. Nothing downstream changes until you tap Search, so closing the overlay
always cancels cleanly.

- **What**: a field that pushes a dedicated typing screen with a zoom transition.
- **Vegetarian**: a switch, where off means "no filter" rather than "not vegetarian".
- **Servings**: 1, 2, 4 or 6+, tap to toggle. The last option is a lower bound rather than a
  value, so servings is modelled as an enum instead of an `Int`.
- **Include and exclude ingredients**: free text entry that commits to removable chips. Adding
  a term to one side removes it from the other, so a query can never ask for a recipe that both
  contains and omits garlic.
- **Also search instructions**: widens the text match to cover the method steps.
- **Clear all**: resets the text and every filter at once.

### Typing screen

- Suggestions are debounced at 300 ms, and each keystroke cancels the request in flight.
- Rows come in three kinds: recent searches (persisted, most recent first), matching categories
  (fetched once, then matched in memory) and matching recipes (up to eight).
- Picking a recipe closes the overlay and opens that recipe directly, skipping the results list.
  You already found what you were looking for.
- The empty state has two messages: nothing matched what you typed, or nothing has been searched
  for yet.

### Results list

- Infinite scroll at 20 per page, triggered by the last visible card. A failed page shows a retry
  footer instead of an alert, and the pager does not get stuck.
- A result count, a grid and list toggle, and a chip row of the active filters. Removing a chip,
  or clearing them all, re-runs the search straight away.
- The title and the search pill's placeholder are scoped to how you got there: a category name, a
  quoted search term, or everything.
- The empty state tells "no recipes here" apart from "your filters excluded everything", and only
  offers a clear filters button in the second case.

### Recipe detail

- Photo gallery with paging dots, a metric row (time, servings, difficulty), a main ingredients
  strip, a tappable ingredient checklist and numbered instructions.
- The row you tapped paints the header on the first frame, and the full recipe swaps in underneath
  once it arrives. No blank screen and no layout jump.

### Throughout

- String catalogues per module (`.xcstrings`), with no hard coded user facing copy.
- Dynamic Type, VoiceOver labels and values, and accessibility identifiers on anything a test flow
  needs to reach.
- Remote images cached to disk by Kingfisher, with retry.

---

## Architecture

MVVM plus Coordinator, organised by feature module rather than by type. Each layer has one job,
and the boundary between any two of them is a protocol.

### What each layer is for

**View: displays, and nothing else.**
A view holds no logic. It does not format values, derive them, branch on business rules or decide
what anything means. Every string, colour and flag it draws is handed to it by a view model. Views
take their dependencies as plain `let` properties and send their outputs back as closures, so each
one previews in isolation. Small components that render a derived value get their own view model
too: a facet chip, a servings option, a suggestion row.

**ViewModel: presentation.**
`@Observable` classes that hold screen state and turn domain models into what the view draws. They
handle loading, pagination, debouncing, cancellation, and empty or error resolution. They depend on
service protocols instead of concrete services, so all of them can be tested without a simulator or
a network. Each one has a matching `…ViewModelProtocol`, and that protocol is what the view accepts,
so previews and tests can pass a mock.

**Coordinator: injection and routing.**
In SwiftUI a coordinator is itself a view (`typealias ViewCoordinator = View`). It builds the
screen's view model, pulls services out of `AppContainer` through defaulted init parameters, and
connects each of the screen's callbacks to a navigation action. Scenes stay unaware of where they
sit in the app: `HomeView` does not know that a category tile pushes a list, only that a tile was
tapped. `RecipeSearchViewCoordinator` owns the overlay's own `NavigationStack`, so the typing screen
is a real push with a real back gesture instead of a second state inside one view.

**Router: the navigation stack.**
`PathRouter` is an `@Observable` wrapper around `NavigationPath`, passed down through the
environment. `Route` is a namespace of nested `Hashable` enums, one per module, so route names
cannot collide as the app grows, and `View+RecipeRoutes` registers the destinations in one place.
`NavigationPath` cannot be read back, so the router keeps a mirror of what it pushed and re-syncs
before every operation. A user swiping back degrades `pop(to:)` instead of trapping.

**Service: the domain boundary.**
`RecipeService` speaks domain types only, and it decides policy. A list row that cannot be mapped
gets dropped, so one bad record does not cost the user the other nine. A detail that cannot be
mapped throws instead, because a detail screen with no recipe has nothing to show. It depends on
`RecipeAPIProtocol`, not on `APIClient`.

**Client: the outside world.**
`APIClient` (Alamofire) builds URLs, encodes parameters, decodes the `APIResponse` envelope and
maps transport failures. `UserDefaultsClient` does the same job for storage. Clients know nothing
about recipes: the recipe endpoints are declared by the feature that needs them, in
`APIClient+Recipe`, and typed by `RecipeAPIProtocol`, which is the seam a test replaces.

**Models: two shapes on purpose.**
`Remote*` types mirror the wire and are entirely optional, since a payload is a promise rather than
a guarantee. `Recipe`, `RecipeSummary` and `RecipeCategory` are what the app works with:
non-optional where a value is required, enums where the set is closed.

**Mapper: the one place both shapes meet.**
A mapper returns `nil` to say a record is not usable. `id` and `title` are required, everything else
has a fallback, so a sparse record still renders.

**Theme: tokens, not literals.**
Colours, fonts and text styles resolve through `ThemeManager.activeTheme`, backed by an asset
catalogue of semantic tokens such as `surfacesBackground`, `textSecondary` and `bordersDefault`
rather than named colours. Views reference tokens, so restyling the app is a palette swap.

### A request, end to end

```
RecipeListView
  └─ RecipeListViewModel          loading state, pagination, cancellation
       └─ RecipeServiceProtocol   domain types in, domain types out
            └─ RecipeAPIProtocol  page/per_page, remote DTOs
                 └─ APIClient     URL, parameters, envelope, status codes
                      └─ URLSession -> MockURLProtocol -> MockAPIRouter -> recipes.json
```

Only the bottom right corner is fake. Set `usesMockAPI` to `false` and the same code path talks to
a server.

### Where things live

```
RecipeTest/
  App/              Entry point, AppContainer (service graph, bootstrap)
  Coordinators/     App and Home coordinators
  Navigation/       PathRouter, Route, destination registration
  Config/           Per-environment configuration (Production, Staging)
  Modules/
    Core/           API client, mock transport, storage client, theme, Page
    Recipe/         Domain and remote models, mappers, RecipeService, endpoints
    Home/           Home scene and its sections
    RecipeList/     Results list, cards, facet chips, view-mode toggle, pager
    RecipeDetail/   Detail scene, gallery, checklist, instructions
    RecipeSearch/   Filter overlay, typing screen, suggestions, recent searches
    Shared/         AppError, SectionState, shared components
  Mocks/            Mock view models powering #Preview (ships in DEBUG only)
  Resources/        MockData/, Colors.xcassets, Assets.xcassets, Fonts
Tests/              Swift Testing suites, mirroring the module tree
UITests/            Launch test
.maestro/           End-to-end flows
```

---

## The search endpoint

The app talks to `GET {baseUrl}/api/v1/recipes`. `RecipeQuery` is the single value carrying every
filter, and it encodes itself to snake_case query parameters, so adding a filter means adding a
property instead of threading another argument through four layers.

| Parameter | Type | Meaning |
| --- | --- | --- |
| `search_text` | string | Matches title, description, category, cuisine and ingredient names |
| `searches_steps` | bool | Widens `search_text` to cover the instruction steps |
| `is_vegetarian` | bool | Diet filter. Absent means no filter |
| `servings` | `1` \| `2` \| `4` \| `6+` | Exact match, or a lower bound for `6+` |
| `include_ingredients` | repeated string | Every term must appear |
| `exclude_ingredients` | repeated string | No term may appear |
| `category` | string | Set by a category tile |
| `cuisine` | string | Supported by the query engine |
| `sort` | `latest` | The fixture's own order, newest first |
| `page`, `per_page` | int | 1-based pagination |

Filters that are not set get dropped from the request rather than sent empty, because a router
handed `category=` would filter on the empty string. `is_vegetarian=false` is kept, since that is a
filter someone chose rather than an absence.

Array parameters go out as repeated keys, for example
`include_ingredients=garlic&include_ingredients=basil`, and booleans as literals. That is why the
client sets its encoding explicitly instead of inheriting Alamofire's bracketed and numeric
defaults.

The mock router filters the fixture before it paginates, so `meta.total` reports the number of
matches rather than the size of the catalogue, and the real pagination arithmetic still gets
exercised. Text matching ignores case and diacritics, and stays locale independent on purpose:
under a Turkish locale, `.current` would fold `I` to a dotless `ı` and a search for `Italian` would
stop matching `italian`.

---

## Key design decisions

**A mock transport, not a mock service.** The obvious way to load bundled JSON is to give
`RecipeService` a local implementation, but then the app never exercises its own networking,
pagination, decoding or error handling, which are the parts most worth showing. Instead
`MockURLProtocol` intercepts below Alamofire and `MockAPIRouter` answers with the bytes a server
would have sent, envelope and all. Everything above the socket runs unmodified.

**Two model shapes.** `Remote*` types are fully optional and mirror the wire, domain types are not.
The mapper between them is the only code that sees both, so a backend contract change has exactly
one place to break, and a partial record degrades to a partial row instead of an empty screen.

**`RecipeSummary` and `Recipe` are separate types**, rather than one type with the detail fields
left optional. A list cell then cannot reach for steps that were never fetched, and `Recipe` has no
fields that are only nil in list context. The split rule: identity, photograph and facets belong to
the summary, prose and the three collections belong to the recipe.

**`SectionState` instead of `isLoading` plus `error` plus `items`.** It covers the four states a
screen can actually be in: `loading`, `loaded`, `empty` and `failed`. Zero rows gets its own case
and its own copy instead of a `loaded([])` the view has to second guess. It also owns the two
transitions worth getting right: a refresh keeps its content instead of flashing a spinner, and a
cancelled task never paints an error, which matters because SwiftUI cancels `.task` on disappear.

**Generation counters for cancellation.** `.task(id:)` cancels the previous call but does not wait
for it, so a cancelled request can resume and land its result over newer state. Every view model
that loads bumps a counter and discards results from an older generation. That is what makes fast
typing, fast filter changes and fast back navigation safe.

**Views derive nothing.** Every value a view renders comes from a view model, down to the small
ones: a chip, a servings option and a suggestion row each have their own. It keeps formatting and
branching testable, and it lets a preview put any state on screen by supplying a mock.

**The overlay edits a draft.** The search screen never mutates the query the list underneath is
showing. It hands back a `RecipeSearchResult` on submit and the list applies it, so closing the
overlay is a genuine cancel. The two ways out, applying a filter or jumping straight to a recipe,
are modelled as two cases instead of one nullable result.

**Protocol-typed dependencies with defaulted parameters**, as in
`init(recipeService: RecipeServiceProtocol = AppContainer.shared.recipeService)`. Production wiring
stays a single line at the call site, and a test passes a mock without a DI framework, a registry,
or a global to reset between cases.

**Swift 6 concurrency without `@MainActor` everywhere.** Models and services are `nonisolated` and
`Sendable`, while view models are main actor bound by virtue of being observable UI state. A service
that needs to report errors captures a `@Sendable` closure resolved on the main actor instead of
reaching back into it.

---

## Assumptions and tradeoffs

- **The JSON is treated as a backend, not a bundle.** The fixture stands in for the database a
  server queries, which is why filtering happens in the router at request time rather than in a view
  model over a preloaded array. The cost is a mock router with real filtering logic inside it. The
  benefit is that no feature code knows the difference.
- **Ingredient quantities are display strings.** `"320 g"`, `"6"`, `"to taste"`. The source data
  cannot support arithmetic, since a third of its ingredients carry no unit at all, and nothing in
  the product scales a recipe. Modelling a value and a unit would invent precision the data does not
  have.
- **Difficulty is an enum, cuisine and meal type and category are not.** The difficulty set is
  closed, small, and the UI switches on it. The open ended facets stay `String`, because an enum
  would have to drop a value it has no case for, and dropping an entry silently is worse than
  showing a word the app does not recognise.
- **Vegetarian is one switch, not three states.** The UI offers on or off, where off means no
  filter. The query model does support `is_vegetarian=false`, the overlay simply has no control that
  sets it.
- **Search is substring matching.** No stemming, no fuzzy matching, no relevance ranking. Results
  come back in catalogue order, which is all `sort=latest` means here. A real backend would rank
  them, but inventing a ranking over 36 rows would prove nothing.
- **Category suggestions are matched client side.** The list is six items and does not change
  between keystrokes, so it is fetched once and filtered in memory instead of costing a request per
  keypress. Recipe suggestions do hit the endpoint, debounced.
- **Recent searches are the only persistence.** One array of strings under one key, with no model
  and no migration story. Anything larger would need a schema, and the exercise does not.
- **Photographs load for real.** The mock transport intercepts data requests only, and Kingfisher
  keeps its own session, so images come from their real hosts. The app needs a network connection to
  look right even though its data is local.
- **Coordinators are views.** A UIKit style coordinator object would need its own lifetime
  management alongside SwiftUI's. Making a coordinator a view hands that to SwiftUI, at the cost of
  the word meaning something slightly different than it does in UIKit.
- **Subclassing for list titling.** The three ways into the results list differ only in what they
  call themselves, so `CategoryRecipeListViewModel` and `SearchRecipeListViewModel` override two
  properties rather than duplicating a pager. Composition would be tidier in principle and noisier
  in practice for two strings.

---

## Known limitations

1. **The ingredient checklist does not persist.** Ticking an ingredient on the detail screen is
   purely cosmetic. It lives in the view model and is gone when the screen is, with no store behind
   it and no sync to anything else.
2. **No real backend.** `AppConfig.baseUrl` points at `api.example.com`, which does not exist. Every
   data request is answered from `Resources/MockData`. Setting `usesMockAPI` to `false` makes the
   app talk to that host for real and fail, exactly as it would against a misconfigured server.
3. **The mock query engine is linear.** It filters, then slices, on every request. That is correct
   and readable at 36 rows, but it is not an index and it is not how a server would do this.
4. **No search ranking or typo tolerance.** A query either matches a substring or it does not.
5. **Recent searches cannot be cleared from the UI.** `RecentSearchStore.clear()` exists and is
   tested, but no screen calls it yet. They also sit in plain `UserDefaults`, which is fine for
   search terms but not a pattern to copy for anything sensitive.
6. **No favouriting, no shopping list, no offline catalogue.** All out of scope for the exercise,
   and there is no write path anywhere in the app.
7. **English only.** Every user facing string goes through a string catalogue and is ready to be
   translated, but only `en` is populated.
8. **Dark mode is partial.** The asset catalogue carries a dark appearance for every colour, but
   about half the tokens currently resolve to the same value in both, so dark mode is declared
   rather than designed.
9. **Pagination is forward only.** There is no jump to page and no total pages control beyond the
   result count, because the UI only ever scrolls.

---

## Testing

Around 340 `@Test` cases under `Tests/`, written with Swift Testing and mirroring the module tree.
They cover the mappers, including malformed and sparse payloads, `RecipeQuery` encoding and facet
arithmetic, the mock router's filtering and pagination, the API client's decoding and error paths,
and every view model's loading, empty, failure, cancellation and pagination behaviour. None of them
need a network or a booted app.

`UITests/` holds a launch test. `.maestro/` holds four end-to-end flows: browsing a category,
searching and filtering, switching the result layout, and leaving a results list. They drive the
real app on a simulator and select on accessibility identifiers rather than visible copy, so a copy
change does not break a flow.

---

## Development workflow

Work happens on feature branches off `develop`, one pull request per piece of work. **CodeRabbit
reviews every PR**, commenting inline on the diff, and its findings are either addressed with a
commit or answered in the thread before anything merges. The template in
`.github/pull_request_template.md` sets out what a PR is expected to carry: what changed and why,
visuals for anything user facing, steps to test, and a checklist covering formatting, lint, tests
and both schemes building.

GitHub Actions (`.github/workflows/ci.yml`) runs on every push to `main` or `develop` and on every
pull request. It picks the newest released Xcode on the runner, ignoring betas and release
candidates, checks formatting with `swiftformat --lint`, resolves packages, builds and tests the
`RecipeTest` scheme on a simulator, then builds `RecipeTest-Staging`. SwiftLint runs as a build tool
plugin, so lint failures surface in the build itself. The rules for both live in `.swiftformat` and
`.swiftlint.yml`.
