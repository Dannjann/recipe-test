//
//  MockRecipeListViewModel.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

#if DEBUG

  /// In the app target, not `Tests/`, because a SwiftUI preview cannot import the test target.
  @Observable
  final class MockRecipeListViewModel: RecipeListViewModelProtocol {
    private(set) var recipes: [RecipeSummary]
    private(set) var layout: RecipeListLayout
    private(set) var loadState: RecipeListLoadState
    private(set) var isLoadingNextPage: Bool
    private(set) var nextPageError: String?
    private(set) var hasLoadedAllData: Bool
    private(set) var loadedPageCount: Int

    private(set) var loadFirstPageCallCount = 0
    private(set) var refreshCallCount = 0
    private(set) var loadNextPageCallCount = 0
    private(set) var selectedLayouts: [RecipeListLayout] = []

    init(
      recipes: [RecipeSummary] = RecipeSummary.dummyList(),
      layout: RecipeListLayout = .list,
      loadState: RecipeListLoadState = .loaded,
      isLoadingNextPage: Bool = false,
      nextPageError: String? = nil,
      hasLoadedAllData: Bool = true,
      loadedPageCount: Int = 1
    ) {
      self.recipes = recipes
      self.layout = layout
      self.loadState = loadState
      self.isLoadingNextPage = isLoadingNextPage
      self.nextPageError = nextPageError
      self.hasLoadedAllData = hasLoadedAllData
      self.loadedPageCount = loadedPageCount
    }
  }

  // MARK: - RecipeListViewModelProtocol

  extension MockRecipeListViewModel {
    func loadFirstPage() async {
      loadFirstPageCallCount += 1
    }

    func refresh() async {
      refreshCallCount += 1
    }

    func loadNextPage() async {
      loadNextPageCallCount += 1
    }

    func select(layout: RecipeListLayout) {
      selectedLayouts.append(layout)
      self.layout = layout
    }
  }

#endif
