//
//  RecipeListViewModelFactory.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

@MainActor
enum RecipeListViewModelFactory {
  static func make(
    request: RecipeListRequest,
    recipeService: RecipeServiceProtocol
  ) -> RecipeListViewModel {
    switch request.title {
    case let .category(name):
      CategoryRecipeListViewModel(
        categoryName: name,
        query: request.query,
        recipeService: recipeService
      )

    case let .search(text):
      SearchRecipeListViewModel(
        searchText: text,
        query: request.query,
        recipeService: recipeService
      )

    case .all:
      RecipeListViewModel(
        query: request.query,
        recipeService: recipeService
      )
    }
  }
}
