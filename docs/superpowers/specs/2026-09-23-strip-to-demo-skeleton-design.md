# Strip RecipeTest to a Demo Skeleton

**Date:** 2026-09-23
**Status:** Approved, ready for implementation planning

## Goal

Reduce the RecipeTest boilerplate to structure, navigation, and coordinators, and replace
its live networking with local JSON served through a fake transport — while keeping every
layer above the socket real, so the app still demonstrates genuine loading, error, and
pagination behaviour.

This is a demo app for an exam. Nothing here needs to reach a server, but everything needs
to *look and behave* as though it does.

## Constraints

- SwiftUI lane only (`APP_LANE = SWIFTUI_APP`). The UIKit lane has no entry point in this
  project and is not coming back.
- The Xcode project uses `PBXFileSystemSynchronizedRootGroup`. Deleting a file on disk
  removes it from the target automatically; no `.pbxproj` edit is needed for file removal.
  Dependency changes still require `.pbxproj` edits.
- `xcodebuild` is available (Xcode 27). Every stage must end on a green build.

## Decisions

Four forks were settled before design:

| Decision | Choice | Consequence |
|---|---|---|
| Mock depth | Stub the transport, keep Alamofire | Highest fidelity; real headers, status codes, envelope decoding, error mapping |
| Dead-code sweep | Aggressive, SwiftUI-only | ~100 files removed |
| Session/keychain | Remove entirely | Valet dependency dropped; no `Authorization` header |
| Sample module | Rename to Recipe, keep it working | End-to-end vertical slice as the reference pattern |

## Architecture

### Request path after the change

```
RecipeService
  └─ RecipeAPIProtocol
       └─ APIClient  (real, unchanged)
            └─ Alamofire.Session  (real, custom configuration)
                 └─ URLSession  (real)
                      └─ MockURLProtocol        ← the only fake component
                           └─ MockAPIRouter
                                └─ Resources/MockData/recipes.json
```

`MockURLProtocol` receives a fully-formed `URLRequest` — real URL, real headers, real query
string — and returns a real `HTTPURLResponse` with real body bytes. Everything above it
runs unmodified: header construction, status-code handling, `APIResponse` envelope
decoding, `APIClientError.failedRequest` mapping, and `RemoteRecipe → Recipe` mapping.

### Mock components

All under `Modules/Core/Clients/API/Mock/`:

- **`MockURLProtocol`** — `URLProtocol` subclass. Resolves the request through
  `MockAPIRouter`, waits the configured latency, then completes with an `HTTPURLResponse`
  and body data. Registered via `URLSessionConfiguration.protocolClasses`.
- **`MockAPIRouter`** — maps `(HTTPMethod, path)` to a `MockEndpoint`. Owns the latency
  setting (default 400ms) and a `failureMode` switch for demonstrating error and empty
  states on demand.
- **`MockEndpoint`** — one case per endpoint, carrying its fixture name and status code.

### Pagination

`Resources/MockData/recipes.json` holds the **complete** recipe list as a flat array. The
router reads `page` and `per_page` off the query string, slices the array, and synthesizes
the `meta` envelope (`current_page`, `per_page`, `total`, `last_page`).

This is deliberate: slicing at request time exercises the real pagination path in
`RecipeService.loadNextItemsPage` and `DataPaginator`, where a set of pre-baked
`page_1.json` / `page_2.json` files would only exercise file loading.

### Toggle

`AppConfigProtocol` gains `var usesMockAPI: Bool` with a default of `true`.
`AppContainer.api` reads it and builds either a mocked or a stock `Alamofire.Session`.
Setting it to `false` yields a live client against `AppConfig.baseUrl` with no other edit —
the demo can become a real app by changing one line.

## Deletions

### Straight deletions

| Area | Approx. count | Reason |
|---|---|---|
| `Modules/Core/UI/ViewControllers/**` | 11 | UIKit lane, unreachable |
| `Modules/Core/UI/Views/**` | 5 | `BaseView`, `CustomView`, placeholder cells — all UIKit |
| `Helpers/Protocols/Presenters/Dialog/**` | 4 | Alert-based, never called from SwiftUI |
| `Helpers/Protocols/Presenters/Sheet/**` | 6 | Alert-based, never called from SwiftUI |
| `Helpers/Protocols/UIKit/**` | 2 | `NibLoadable`, `Attributeable` |
| `Helpers/Protocols/CollectionView/**` | 1 | `Reusable` |
| `Extensions/UIKit/**` | ~22 of 25 | Keep only what the compiler demands |
| `Extensions/Foundation/**` | ~22 of 30 | Keep only what the compiler demands |
| `Extensions/Valet/**` | 1 | Valet dropped |
| `Extensions/WebKit/**` | 1 | No `WKWebView` survives `WebViewController` |
| `Extensions/Alamofire/**` | 1 | Verify against `APIClient` first; delete only if unused |
| `Modules/Shared/Services/Session/**` | 2 | Session removed |
| `Tests/Modules/Shared/Services/Session/**` | 1 | Session removed |

### Determining the exact keep-list

A grep-based reference check was attempted and rejected as the source of truth: symbols
named `formatter`, `cell`, `text`, `map`, and `range` match unrelated code throughout, so
its counts are false-positive-heavy.

The keep-list is therefore **compiler-driven**: delete the full candidate set, build, and
restore precisely the files the compiler reports as missing. The build is the authority,
not a heuristic. The final report must state which files were actually restored and why.

### Salvage operations — the sharp edges

These two are not straight deletions and are the most likely source of a broken build:

1. **`ProcessViewModelProtocol`** lives in `Modules/Core/UI/ViewControllers/Process/`, but
   `Navigation/SwiftUI/ViewCoordinatorProtocol.startProcess` depends on it. Move
   `ProcessViewModelProtocol.swift` to `Navigation/SwiftUI/` before deleting the folder.
   `ProcessController.swift` goes with its siblings.

2. **`LoadingOverlay`, `Snackbar`, `SnackbarInfoPresenter`** import UIKit but are reached
   from `Extensions/SwiftUI/View/View+Result.swift`, which every screen's error handling
   funnels through. These **stay**, together with `Helpers/Protocols/Presenters/Info/**`
   and `Helpers/Protocols/Presenters/Progress/**`. Only the Alert-based Dialog and Sheet
   presenters are removed.

## Session removal

Delete `SessionService`, `SessionServiceProtocol`, `Extensions/Valet/`, and
`SessionServiceTests`. Remove `AppContainer.session` and `AppContainer.valet`.

`APIClient.init` loses its `accessTokenProvider` parameter, and
`httpRequestHeaders(withAuth:)` loses the `Authorization` branch. `AppContainer.api`'s
`onError` handler loses the `clearSession` call, which makes
`AppContainer.isUnauthorizedAPIError` dead — remove it too.

`AppCoordinator` takes a `session` parameter it only stores; remove the parameter and the
stored property.

## Recipe module

Rename `Modules/Sample/` to `Modules/Recipe/` and rename throughout:

| From | To |
|---|---|
| `SampleItem` | `Recipe` |
| `RemoteSampleItem` | `RemoteRecipe` |
| `SampleService` / `SampleServiceProtocol` | `RecipeService` / `RecipeServiceProtocol` |
| `SampleAPIProtocol` | `RecipeAPIProtocol` |
| `APIClient+Sample` | `APIClient+Recipe` |
| `SampleScreen` / `SampleScreenViewModel` | `RecipeListScreen` / `RecipeListViewModel` |
| `SampleDetailScreen` | `RecipeDetailScreen` |
| `SampleViewCoordinator` | `RecipeViewCoordinator` |
| `Route.Sample` | `Route.Recipe` |
| `Sample.xcstrings` | `Recipe.xcstrings` |
| `AppContainer.sampleService` | `AppContainer.recipeService` |

`Recipe` gains real fields so the detail screen has content: `title`, `imageURL`,
`cookTimeMinutes`, `servings`, `ingredients`, `steps`. `RemoteRecipe` mirrors these with
snake_case coding keys and maps to the domain type, following the existing
`RemoteSampleItem` pattern.

The endpoint path becomes `recipes` (from `sample-items`).

## Dependencies

Drop **Valet** only. Alamofire, Kingfisher, and SwiftLintPlugins stay.

Removing Valet requires four `.pbxproj` edits plus one `Package.resolved` edit:

1. The `XCRemoteSwiftPackageReference "Valet"` block
2. Both `XCSwiftPackageProductDependency` entries (one per app target)
3. The entry in the project's `packageReferences` list
4. Both `PBXBuildFile` / frameworks-phase references
5. The `valet` pin in `Package.resolved`

`Extensions/UIKit/UIImageView/UIImageView+URL.swift` is deleted (UIKit), but Kingfisher
stays for `CachedAsyncImage`.

## Testing

| Test | Action |
|---|---|
| `SessionServiceTests` | Delete — session removed |
| `SampleServiceTests` | Rename to `RecipeServiceTests`, update to `RecipeService` |
| `APIResponseTests` + 3 fixtures | Keep unchanged — still exercises the envelope |
| `SampleItemsTests_200.json` | Rename to `RecipesTests_200.json`, update shape |
| `PaginationTests` | Keep |
| `PathRouterTests` | Keep |
| `ThemedControlTests` | Keep |
| Extension tests | Prune to match surviving extensions |
| **New:** `MockAPIRouterTests` | Page-slicing maths, meta synthesis, unknown-path handling |
| **New:** `MockURLProtocolTests` | Status codes, latency, failure-mode injection |

## Verification

Every stage ends on a green build. The work is not complete until all of these pass and
their output has been seen:

```
xcodebuild build -scheme RecipeTest -destination 'platform=iOS Simulator,name=iPhone 17'
xcodebuild test  -scheme RecipeTest -destination 'platform=iOS Simulator,name=iPhone 17'
```

Plus a manual check that the app launches, the recipe list populates from
`recipes.json` after the simulated latency, scrolling pages in more rows, and tapping a row
pushes the detail screen.

Claims of completion must cite actual command output. A stage that cannot be verified is
reported as unverified, not as done.

## Out of scope

- Adding any recipe feature beyond the list/detail slice (search, favourites, filtering)
- Theme or visual redesign — the existing theme system stays as-is
- CI workflow changes beyond what a green build requires
- Converting the project to a real backend

## Open item

The project is **not a git repository**, so this spec cannot be committed and the strip
has no undo. Recommend `git init` plus a baseline commit before any deletion begins.
