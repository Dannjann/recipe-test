//
//  RecipeListViewModelProtocol.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

@MainActor
protocol RecipeListViewModelProtocol: Observable, AnyObject {
  // MARK: Outputs

  var recipes: [RecipeSummary] { get }
  var layout: RecipeListLayout { get }
  var loadState: RecipeListLoadState { get }
  var isLoadingNextPage: Bool { get }
  var nextPageError: String? { get }
  var hasLoadedAllData: Bool { get }
  var loadedPageCount: Int { get }

  // MARK: Inputs

  func loadFirstPage() async
  func refresh() async
  func loadNextPage() async
  func select(layout: RecipeListLayout)
}
