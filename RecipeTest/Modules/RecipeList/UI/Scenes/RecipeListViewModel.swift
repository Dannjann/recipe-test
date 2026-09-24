//
//  RecipeListViewModel.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

@Observable
final class RecipeListViewModel: RecipeListViewModelProtocol {
  private(set) var recipes: SectionState<[RecipeCardViewModel]> = .loading
  private(set) var isLoadingNextPage = false
  private(set) var nextPageError: String?
  private(set) var viewMode: RecipeListViewMode = .grid

  /// Mutable: removing a facet rewrites the query and reloads, without rebuilding the screen.
  private var request: RecipeListRequest

  /// `nil` once the last page has landed — the pager reads this as "stop asking".
  private var nextPage: Page?
  private var resultTotal: Int?
  private var hasLoadedOnce = false
  private var generation = 0

  private let recipeService: RecipeServiceProtocol

  init(
    request: RecipeListRequest,
    recipeService: RecipeServiceProtocol
  ) {
    self.request = request
    self.recipeService = recipeService
  }
}

// MARK: - Getters

extension RecipeListViewModel {
  var title: String {
    switch request.title {
    case let .category(name):
      name

    case .search:
      String(localized: .RecipeList.recipeListTitleSearchResults)

    case .all:
      String(localized: .RecipeList.recipeListTitleAll)
    }
  }

  var searchPlaceholder: String {
    switch request.title {
    case let .category(name):
      String(localized: .RecipeList.recipeListSearchPlaceholderCategory(name))

    case let .search(text):
      String(localized: .RecipeList.recipeListSearchPlaceholderSearch(text))

    case .all:
      String(localized: .RecipeList.recipeListSearchPlaceholderAll)
    }
  }

  /// Gated on `isLoaded` rather than cleared by hand on every failure: a count only means
  /// something beside the rows it counts.
  var resultCountText: String? {
    guard
      recipes.isLoaded,
      let resultTotal
    else { return nil }

    return String(localized: .RecipeList.recipeListResultCount(resultTotal))
  }

  var facetChips: [RecipeFacetChipViewModel] {
    request.query.activeFacets.map(RecipeFacetChipViewModel.init)
  }

  /// One chip removes itself; "Clear all" only earns its place once there are several.
  var showsClearAllChips: Bool {
    facetChips.count > 1
  }

  /// "No recipes match your filters" is a lie when the user set no filter — which is every
  /// empty category, the only empty state the category entry point can reach today.
  var emptyTitle: LocalizedStringResource {
    hasFacets
      ? .RecipeList.recipeListEmptyTitle
      : .RecipeList.recipeListEmptyNoResultsTitle
  }

  var emptyDetail: LocalizedStringResource? {
    hasFacets ? .RecipeList.recipeListEmptyDetail : nil
  }

  var showsClearFiltersButton: Bool {
    hasFacets
  }
}

// MARK: - Getters > Constants

private extension RecipeListViewModel {
  var hasFacets: Bool {
    !request.query.activeFacets.isEmpty
  }

  var pageSize: Int {
    20
  }

  var firstPage: Page {
    Page(
      index: 1,
      size: pageSize
    )
  }
}

// MARK: - Inputs

extension RecipeListViewModel {
  /// What the screen's `.task` calls. SwiftUI cancels that task when the list is covered by a
  /// pushed recipe and restarts it on the way back; reloading there would discard every page
  /// after the first and drop the user's scroll position. A failed or cancelled first load
  /// leaves this false, so returning to the screen does retry.
  func loadFirstPageIfNeeded() async {
    guard !hasLoadedOnce else { return }

    await loadFirstPage()
  }

  func loadFirstPage() async {
    generation += 1
    let generation = self.generation
    let previous = recipes
    recipes = previous.refreshing
    isLoadingNextPage = false
    nextPageError = nil
    nextPage = nil

    do {
      let page = try await recipeService.getRecipes(
        query: request.query,
        page: firstPage
      )

      guard generation == self.generation else { return }

      resultTotal = page.meta.total
      recipes = .rows(page.recipes.map(RecipeCardViewModel.init))
      nextPage = page.hasLoadedAllData ? nil : firstPage.next
      hasLoadedOnce = true
    } catch {
      guard generation == self.generation else { return }

      recipes = previous.recovering(from: error)
    }
  }

  /// The view reports which row appeared; this decides whether that means anything. Guards
  /// against a tail row reappearing, a page already in flight, and a failure the user has
  /// not retried yet.
  func loadNextPageIfNeeded(after cardID: String) async {
    guard
      let nextPage,
      !isLoadingNextPage,
      nextPageError == nil,
      recipes.value?.last?.id == cardID
    else { return }

    await loadNextPage(nextPage)
  }

  func retryNextPage() async {
    guard
      let nextPage,
      !isLoadingNextPage
    else { return }

    nextPageError = nil

    await loadNextPage(nextPage)
  }

  func remove(facet: RecipeQueryFacet) async {
    request = request.replacingQuery(request.query.removing(facet))

    await loadFirstPage()
  }

  func clearFacets() async {
    request = request.replacingQuery(request.query.clearingFacets())

    await loadFirstPage()
  }

  func select(viewMode: RecipeListViewMode) {
    self.viewMode = viewMode
  }
}

// MARK: - Helpers

private extension RecipeListViewModel {
  func loadNextPage(_ page: Page) async {
    let generation = self.generation
    isLoadingNextPage = true

    // Unconditional: a stale-generation return would otherwise leave the footer spinning,
    // and today it is only cleared by `loadFirstPage` happening to run next.
    defer { isLoadingNextPage = false }

    do {
      let loaded = try await recipeService.getRecipes(
        query: request.query,
        page: page
      )

      // A facet was removed while this was in flight: it answers a query the screen no
      // longer shows, and appending it would mix two result sets.
      guard generation == self.generation else { return }

      resultTotal = loaded.meta.total
      let didAppend = append(loaded.recipes)

      // A page that adds nothing new means the server is repeating itself. Advancing the
      // cursor would strand the list: the trigger is the tail row appearing, and without a
      // new tail row nothing ever asks again.
      nextPage = loaded.hasLoadedAllData || !didAppend ? nil : page.next
    } catch {
      guard generation == self.generation else { return }

      // Leaving the screen must not leave a failure waiting for the next visit.
      guard !error.isCancellation else { return }

      nextPageError = error.failureDetail ?? String(localized: .Shared.sharedErrorSomethingWentWrong)
    }
  }

  /// Ids already held are dropped rather than appended: a repeated row would put a duplicate
  /// id into a `ForEach`, and SwiftUI's diffing stops being able to tell the rows apart.
  /// Returns whether the page actually added anything.
  @discardableResult
  func append(_ summaries: [RecipeSummary]) -> Bool {
    let current = recipes.value ?? []
    let known = Set(current.map(\.id))
    let appended = summaries
      .filter { !known.contains($0.id) }
      .map(RecipeCardViewModel.init)

    recipes = .rows(current + appended)

    return !appended.isEmpty
  }
}
