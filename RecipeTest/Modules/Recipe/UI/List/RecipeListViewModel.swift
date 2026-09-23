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

  func refresh() async {
    // Task 4.
  }

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

  /// Filters ids already on screen. A `ForEach` keyed on a duplicated `Identifiable` id
  /// drops rows and animates wrongly, and a paginated backend whose rows shift between
  /// requests will hand you the same recipe on two pages.
  func append(_ newRecipes: [RecipeSummary]) {
    let existing = Set(recipes.map(\.id))

    recipes += newRecipes.filter { !existing.contains($0.id) }
  }
}
