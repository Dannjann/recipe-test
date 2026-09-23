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
  private(set) var recipes: [RecipeSummary] = []
  private(set) var layout: RecipeListLayout = .list
  private(set) var loadState: RecipeListLoadState = .idle
  private(set) var isLoadingNextPage = false
  private(set) var nextPageError: String?
  private(set) var hasLoadedAllData = false

  private let service: any RecipeServiceProtocol
  private let pageSize: Int

  private var nextPage: Page

  /// Bumped each time page one is (re)requested; stale-generation results are discarded.
  private var generation = 0

  /// A counter, not a Bool: a Bool lets a nested refresh's `defer` clear the flag while an outer one is still in flight.
  private var refreshDepth = 0

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

  /// Does not set `.loading`: that would blank a screen the user is looking at, and `.refreshable` draws its own indicator.
  func refresh() async {
    let token = startNewGeneration()

    refreshDepth += 1
    defer { refreshDepth -= 1 }

    isLoadingNextPage = false
    nextPageError = nil

    await loadPageOne(token: token, keepingRowsOnFailure: true)
  }

  func loadNextPage() async {
    guard
      loadState == .loaded,
      refreshDepth == 0,
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

  func startNewGeneration() -> Int {
    generation += 1

    return generation
  }

  func append(_ newRecipes: [RecipeSummary]) {
    let existing = Set(recipes.map(\.id))

    recipes += newRecipes.filter { !existing.contains($0.id) }
  }
}
