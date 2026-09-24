//
//  RecipeCategorySuggestionRowViewModel.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

/// A category whose name matches what is being typed. Picking one searches for its name rather
/// than scoping the list to it, which is what the prototype's field does.
nonisolated struct RecipeCategorySuggestionRowViewModel: RecipeSuggestionRowViewModelProtocol {
  let category: RecipeCategory
}

// MARK: - Getters

nonisolated extension RecipeCategorySuggestionRowViewModel {
  var id: String {
    "category-\(category.id)"
  }

  var title: String {
    category.name
  }

  var detail: String {
    String(localized: .RecipeSearch.recipeSearchSuggestionCategoryDetail)
  }

  var imageURL: URL? {
    category.imageURL
  }

  var symbolName: String {
    "fork.knife"
  }

  var selection: RecipeSearchInputSelection {
    .text(category.name)
  }
}
