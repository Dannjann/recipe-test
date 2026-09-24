//
//  CategoryRecipeListViewModel.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

final class CategoryRecipeListViewModel: RecipeListViewModel {
  private let categoryName: String

  init(
    categoryName: String,
    query: RecipeQuery,
    recipeService: RecipeServiceProtocol
  ) {
    self.categoryName = categoryName

    super.init(
      query: query,
      recipeService: recipeService
    )
  }

  // MARK: - Overrides

  override var title: String {
    categoryName
  }

  override var searchPlaceholder: String {
    String(localized: .RecipeList.recipeListSearchPlaceholderCategory(categoryName))
  }
}
