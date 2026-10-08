# CLAUDE.md

Guidance for working in the Resell iOS (SwiftUI) codebase. Match these conventions when
adding or changing code. The goal is code that reads like the code already here.

## Project Layout

- `Resell/Views/` — SwiftUI views, grouped by feature (`Home/`, `Settings/`,
  `NewListing/`) plus a shared `Components/` folder for reusable UI.
- `Resell/ViewModels/` — one ViewModel per screen, each in its own file.
- `Resell/Models/` — `Codable` value types mapped from the backend JSON (plus a
  `Firebase Models/` subfolder for Firestore documents).
- `Resell/API/` — the networking and platform layer: `NetworkManager`, `APIClient`,
  `GoogleAuthManager`, `FirestoreManager`, `KeychainManager`, caches.
- `Resell/Utils/` — `Constants` (design system), `Keys`, `Router`, haptics, and
  `Extensions/` (reusable view modifiers and type helpers).
- `Resell/Core/` — app entry (`ResellApp`, `ResellAppDelegate`) and versioning.

## Core Principles

1. **Self-documenting code.** Names carry the meaning. Prefer a clear name over a comment
   explaining an unclear one. `getSavedPosts()`, `shouldRetryOn401(_:)`,
   `sortPostsByDate(_:)` say what they do without prose.
2. Make sure to seperate all complex logic into ViewModels for the specific Views, complex logic should never be in the views. 
3. **Minimal comments — but document the API surface.** Don't narrate obvious code. Do use
   Swift doc comments (`///` or `/** */`) on non-trivial types and functions so the symbol
   reads well in Xcode Quick Help — the `NetworkManager` request templates are the model to
   follow. Reserve inline `//` comments for genuinely non-obvious logic (e.g. why a 401 is
   retried, why a timestamp heuristic exists). Don't leave commented-out code or
   scratch/placeholder files (`Untitled.swift`, `sfsfs.swift`) in new work.
4. **Clean separation of concerns.** Views render; ViewModels hold state and orchestrate;
   the `API/` layer owns side effects (network, auth, storage, caching); Models are inert
   `Codable` value types. Never call `URLSession` or build requests from a `View` — go
   through `NetworkManager`.
5. **Prefer the newest iOS APIs.** Reach for modern Swift concurrency (`async`/`await`,
   `Task`), `NavigationStack`, and current SwiftUI first. Only fall back to older patterns
   (Combine pipelines, completion handlers) when interoperating with code that still uses
   them.

## File Header

Every source file starts with the standard header:

```swift
//
//  <FileName>.swift
//  Resell
//
//  Created by <Author> on <M/D/YY>.
//
```

## Organizing a File with `// MARK:`

Group members with `// MARK: -` sections. Common section names in this codebase:

- Views: `// MARK: - Properties`, `// MARK: - UI`
- ViewModels: `// MARK: - Properties`, `// MARK: - Functions`, `// MARK: - Private Methods`
- `NetworkManager`: sections per feature area (`// MARK: - User Networking Functions`,
  `// MARK: - App Version`, …)

## Views

Break a view into small, named pieces instead of one giant `body`. Use `private` computed
properties for sub-views and `private func`s for parameterized ones.

```swift
struct HomeView: View {

    @EnvironmentObject private var router: Router
    @ObservedObject private var viewModel = HomeViewModel.shared
    @State private var presentPopup = false

    var body: some View {
        ScrollView {
            VStack {
                headerView
                filtersView
                ProductsGalleryView(items: viewModel.filteredItems, onScrollToBottom: viewModel.fetchMoreItems)
            }
        }
        .onAppear { viewModel.getAllPosts() }
    }

    private var headerView: some View { /* ... */ }
    private var filtersView: some View { /* ... */ }
}
```

Conventions:
- Keep `body` a readable outline of named sub-views. If a closure grows past a few lines,
  extract it into a computed property or `func`.
- Shared, reusable UI goes in `Views/Components/` (e.g. `ProductsGalleryView`,
  `PurpleButton`, `Icon`, `ShimmerView`), not inline in a feature view.
- Pull styling from `Constants` — `Constants.Colors`, `Constants.Fonts`,
  `Constants.Spacing`. **Do not** hardcode `Font.custom("Rubik-Medium", size: 22)` or raw
  hex colors inline; add the token to `Constants.Fonts`/`Constants.Colors` and use it.
  (Some existing views still inline fonts — don't copy that; prefer the token.)
- Factor reusable behavior into `ViewModifier`s exposed through a `View` extension
  (`.loadingView(isLoading:)`, `.endEditingOnTap()`), not repeated inline modifiers.

## Navigation — the Router

Navigation is centralized in `Router` (an `ObservableObject` injected via
`@EnvironmentObject`). Screens are values in the `Route` enum, and the nav stack is driven
by `router.path`.

```swift
@EnvironmentObject private var router: Router

router.push(.productDetails(post))   // navigate forward
router.pop()                          // go back one
router.popToRoot()                    // back to root
```

Conventions:
- Add a new screen by adding a `case` to `Router.Route` (with any associated value it
  needs) and handling it where the `NavigationStack(path:)` maps routes to views. Don't
  scatter `NavigationLink`s that bypass the router.
- `Route` is `Hashable`; associated model values (`Post`, `Transaction`, …) must stay
  `Hashable`.

## ViewModels

Each screen has its own `@MainActor class XViewModel: ObservableObject` in its own file,
exposing `@Published` state.

```swift
@MainActor
class HomeViewModel: ObservableObject {

    // MARK: - Properties

    @Published var filteredItems: [Post] = []
    @Published var isLoading: Bool = false

    // MARK: - Functions

    func getAllPosts(forceRefresh: Bool = false) { /* ... */ }

    // MARK: - Private Methods

    private func shouldUseCachedData() -> Bool { /* ... */ }
}
```

Conventions:
- Always `@MainActor` — all `@Published` mutation happens on the main actor.
- Views hold ViewModels with `@StateObject` (owner) or `@ObservedObject`/`@EnvironmentObject`
  (shared). App-wide, long-lived ViewModels injected once in `MainView` use
  `@EnvironmentObject`.
- **Singletons:** some ViewModels are `static let shared` with `private init()` (e.g.
  `HomeViewModel`, `SearchViewModel`) so state survives navigation. Use this only for
  genuinely global screen state; prefer a plain instance otherwise.
- **Cross-ViewModel wiring:** pass a reference via a `configure(mainViewModel:)` method
  rather than reaching into globals; use `NotificationCenter` (see
  `Constants.Notifications`) for decoupled events like "new listing created."
- Derive displayed data with computed properties instead of storing redundant copies.
- **Prefer the `@Observable` macro (iOS 17+) for new ViewModels** — plain `var` state, held
  with `@State`/`@Bindable` in the view. The `ObservableObject` + `@Published` pattern above
  is the current convention across the app; don't refactor it wholesale, but lean toward
  `@Observable` for new screens.

## Networking

All backend access goes through `NetworkManager.shared`. It's built on generic, documented
request templates conforming to the `APIClient` protocol:

```swift
func get<T: Decodable>(url: URL) async throws -> T
func post<T: Decodable, U: Encodable>(url: URL, body: U) async throws -> T
func delete(url: URL) async throws
```

Add a new endpoint as a small, single-purpose async method that builds its URL with
`constructURL(endpoint:)` and delegates to a template — never assemble a `URLRequest`
inline in a feature area:

```swift
func getUserByID(id: String) async throws -> UserResponse {
    let url = try constructURL(endpoint: "/user/id/\(id)/")
    return try await get(url: url)
}
```

Conventions:
- Requests route through the central `perform(requestBuilder:)` executor, which injects the
  `Bearer` token, and on a `401` refreshes auth via `GoogleAuthManager` and retries once
  (up to `maxAttempts`). Reuse it — don't build a parallel request path.
- `hostURL` switches on `#if DEBUG` between `Keys.devServerURL` and `Keys.prodServerURL`.
  All secrets/URLs live in `Keys` — never hardcode them.
- Use the manager's shared `jsonEncoder`/`jsonDecoder` (configured for the backend's ISO8601
  date format). Don't spin up ad-hoc coders with different date strategies.
- Errors are surfaced as `ErrorResponse`; handle failures where the call is made.

## Concurrency

Use modern Swift concurrency (`async`/`await`, `Task`). Avoid new Combine pipelines and raw
`DispatchQueue` in feature code.

- Kick off async work from sync callbacks with `Task { }`, hop to the main actor for UI
  state, and use `defer` to reliably reset flags like `isLoading`:

  ```swift
  func getAllPosts(forceRefresh: Bool = false) {
      isLoading = true
      Task {
          defer { Task { @MainActor in isLoading = false } }
          do {
              let response = try await NetworkManager.shared.getAllPosts()
              filteredItems = Post.sortPostsByDate(response.posts)
          } catch {
              NetworkManager.shared.logger.error("Error in getAllPosts: \(error)")
          }
      }
  }
  ```

- Prefer `.task { }` over `.onAppear { Task { } }` for view-lifecycle async work.
- For optimistic UI (e.g. save/unsave), snapshot prior state, mutate locally, then roll back
  in the `catch` (see `toggleLocalSaveStatus`).

## Models

Models are `struct`s conforming to `Codable`, `Identifiable`, `Hashable`, and `Equatable`
as needed, mapping backend JSON.

- Use `CodingKeys` to bridge snake_case/backend names to Swift `camelCase`.
- When identity is by `id`, implement `==` and `hash(into:)` on `id` only (see `Post`).
- Colocate request/response wrapper structs (`PostsResponse`, `PostBody`, …) with the model.
- Put pure, reusable transforms on the model as `static`/instance helpers
  (`Post.sortPostsByDate(_:)`), not duplicated in ViewModels.

## Platform Managers (API layer)

Cross-cutting, long-lived concerns are `shared` singletons in `Resell/API/`:
`NetworkManager`, `GoogleAuthManager`, `FirestoreManager`, `KeychainManager`, and image
caches. Use `static let shared` + `private init()`.

- Auth flows through `GoogleAuthManager.shared` (`getValidToken()`,
  `refreshSignInIfNeeded()`, `forceLogout(reason:)`). Don't manage tokens elsewhere.
- Image loading uses **Kingfisher**; cache limits/expiration are configured centrally
  (see `configureImageCache()`). Use the shared `CachedImageView`/`AggressiveCachedImageView`
  components rather than configuring downloads per call site.

## Logging

Use `os.Logger` — **not `print`**. `NetworkManager` and `GoogleAuthManager` expose a
`logger`; log through it and include context:

```swift
NetworkManager.shared.logger.error("Error in \(#file) \(#function): \(error)")
```

Gate debug-only logging behind `#if DEBUG`. The codebase still has stray `print(...)` calls
— replace them with `logger` when you touch that code; don't add new ones.

## Constants, Keys & Persistence

- All colors, fonts, spacing, and notification names live in `Constants` (nested enums with
  `static let`). Reference them everywhere — no magic numbers, inline hex, or literal
  `NotificationCenter` name strings.
- All API URLs, client IDs, and secrets live in `Keys`. Never hardcode a URL or key.
- Use `@AppStorage` for small, simple persistence (e.g. `blockedUsers`); use
  `KeychainManager` for anything sensitive (tokens/credentials).

## Quick Checklist Before You Commit

- [ ] Standard file header present.
- [ ] `// MARK: -` sections in the conventional order.
- [ ] Non-trivial symbols have `///` doc comments; no narration comments, no commented-out
      code, no placeholder files.
- [ ] View split into named `private` sub-views; reusable UI lives in `Components/`.
- [ ] All complex logic is in ViewModels not in the Views themselves.
- [ ] Navigation goes through `Router`; new screens added as `Route` cases.
- [ ] ViewModel is `@MainActor`; `@Observable` for new screens; shared instances justified.
- [ ] Network access goes through a `NetworkManager` endpoint method using the request
      templates — no inline `URLRequest`s, no ad-hoc coders.
- [ ] Async work uses `async`/`await` + `Task`; UI mutation on the main actor; no new Combine.
- [ ] Colors, fonts, spacing, notification names from `Constants`; URLs/secrets from `Keys`.
- [ ] Errors logged through `logger`, not `print`.
