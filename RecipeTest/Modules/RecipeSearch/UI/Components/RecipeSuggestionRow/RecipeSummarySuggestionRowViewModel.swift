//
//  RecipeSummarySuggestionRowViewModel.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

/// A matching recipe. The only row that leaves the overlay entirely rather than filling the
/// field, which is why `selection` carries the summary instead of text.
nonisolated struct RecipeSummarySuggestionRowViewModel: RecipeSuggestionRowViewModelProtocol {
  let summary: RecipeSummary
}

// MARK: - Getters

nonisolated extension RecipeSummarySuggestionRowViewModel {
  var id: String {
    "recipe-\(summary.id)"
  }

  var title: String {
    summary.title
  }

  var detail: String {
    summary.cuisine ?? String(localized: .RecipeSearch.recipeSearchSuggestionRecipeDetail)
  }

  var imageURL: URL? {
    summary.heroImageURL
  }

  var symbolName: String {
    "fork.knife"
  }

  var selection: RecipeSearchInputSelection {
    .recipe(summary)
  }
}
