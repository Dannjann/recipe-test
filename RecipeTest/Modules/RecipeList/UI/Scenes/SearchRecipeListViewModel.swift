//
//  SearchRecipeListViewModel.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

final class SearchRecipeListViewModel: RecipeListViewModel {
  private let searchText: String

  init(
    searchText: String,
    query: RecipeQuery,
    recipeService: RecipeServiceProtocol
  ) {
    self.searchText = searchText

    super.init(
      query: query,
      recipeService: recipeService
    )
  }

  // MARK: - Overrides

  override var title: String {
    String(localized: .RecipeList.recipeListTitleSearchResults)
  }

  override var searchPlaceholder: String {
    String(localized: .RecipeList.recipeListSearchPlaceholderSearch(searchText))
  }
}
