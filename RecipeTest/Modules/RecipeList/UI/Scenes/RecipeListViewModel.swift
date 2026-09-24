//
//  RecipeListViewModel.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

/// Titling is all an entry point changes, so each one subclasses rather than being injected.
@Observable
class RecipeListViewModel: RecipeListViewModelProtocol {
  private(set) var recipes: SectionState<[RecipeCardViewModel]> = .loading
  private(set) var isLoadingNextPage = false
  private(set) var nextPageErrorText: String?
  private(set) var viewMode: RecipeListViewMode = .grid

  /// Readable by a subclass, which titles itself from it.
  private(set) var query: RecipeQuery

  /// `nil` once the last page has landed — the pager reads this as "stop asking".
  private var nextPage: Page?
  private var resultTotal: Int?
  private var hasLoadedOnce = false
  private var generation = 0

  private let recipeService: RecipeServiceProtocol

  init(
    query: RecipeQuery,
    recipeService: RecipeServiceProtocol
  ) {
    self.query = query
    self.recipeService = recipeService
  }

  // MARK: - Overridables

  var title: String {
    String(localized: .RecipeList.recipeListTitleAll)
  }

  var scopedSearchPlaceholder: String {
    String(localized: .RecipeList.recipeListSearchPlaceholderAll)
  }
}

// MARK: - Getters

extension RecipeListViewModel {
  /// The applied text, quoted, falling back to what the list is scoped to. The prototype's
  /// second pill line is not reproduced: the chip row below already shows those values.
  var searchPlaceholder: String {
    guard
      let searchText = query.searchText,
      !searchText.isEmpty
    else { return scopedSearchPlaceholder }

    return String(localized: .RecipeList.recipeListSearchPlaceholderQuery(searchText))
  }

  var resultCountText: String? {
    guard
      recipes.isLoaded,
      let resultTotal
    else { return nil }

    return String(localized: .RecipeList.recipeListResultCount(resultTotal))
  }

  var facetChips: [RecipeFacetChipViewModel] {
    query.activeFacets.map(RecipeFacetChipViewModel.init)
  }

  var showsClearAllChips: Bool {
    facetChips.count > 1
  }

  /// An empty category set no filters, so blaming them would be a lie.
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

  var viewModeSegments: [RecipeListViewModeSegmentViewModel] {
    RecipeListViewMode.allCases.map {
      RecipeListViewModeSegmentViewModel(
        mode: $0,
        isSelected: $0 == viewMode
      )
    }
  }
}

// MARK: - Getters > Private

private extension RecipeListViewModel {
  var hasFacets: Bool {
    !query.activeFacets.isEmpty
  }

  var lastCardID: String? {
    guard let cards = recipes.value else { return nil }

    return cards.last?.id
  }
}

// MARK: - Getters > Constants

private extension RecipeListViewModel {
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
  /// SwiftUI restarts the screen's `.task` on the way back from a pushed recipe.
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
    nextPageErrorText = nil
    nextPage = nil

    do {
      let page = try await recipeService.getRecipes(
        query: query,
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

  func loadNextPageIfNeeded(after cardID: String) async {
    guard
      let nextPage,
      !isLoadingNextPage,
      nextPageErrorText == nil,
      lastCardID == cardID
    else { return }

    await loadNextPage(nextPage)
  }

  func retryNextPage() async {
    guard
      let nextPage,
      !isLoadingNextPage
    else { return }

    nextPageErrorText = nil

    await loadNextPage(nextPage)
  }

  func remove(facet: RecipeQueryFacet) async {
    query = query.removing(facet)

    await loadFirstPage()
  }

  func clearFacets() async {
    query = query.clearingFacets()

    await loadFirstPage()
  }

  /// `loadFirstPage` bumps the generation, so a next page in flight is discarded rather than
  /// appended onto this result set.
  func apply(query: RecipeQuery) async {
    self.query = query

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

    // Unconditional: a stale-generation return would otherwise leave the footer spinning.
    defer { isLoadingNextPage = false }

    do {
      let loaded = try await recipeService.getRecipes(
        query: query,
        page: page
      )

      // A facet changed mid-flight: appending now would mix two result sets.
      guard generation == self.generation else { return }

      resultTotal = loaded.meta.total
      let didAppend = append(loaded.recipes)

      // Without a new tail row nothing would ask again, so stop rather than strand.
      nextPage = loaded.hasLoadedAllData || !didAppend ? nil : page.next
    } catch {
      guard generation == self.generation else { return }

      // Leaving the screen must not leave a failure waiting for the next visit.
      guard !error.isCancellation else { return }

      nextPageErrorText = error.failureDetail ?? String(localized: .Shared.sharedErrorSomethingWentWrong)
    }
  }

  /// Drops ids already held: a duplicate in a `ForEach` breaks SwiftUI's diffing.
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
