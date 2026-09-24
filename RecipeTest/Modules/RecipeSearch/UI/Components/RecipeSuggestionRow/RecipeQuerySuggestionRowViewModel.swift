//
//  RecipeQuerySuggestionRowViewModel.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

/// Offers back what is being typed right now — "Search for …".
nonisolated struct RecipeQuerySuggestionRowViewModel: RecipeSuggestionRowViewModelProtocol {
  let text: String
}

// MARK: - Getters

nonisolated extension RecipeQuerySuggestionRowViewModel {
  var id: String {
    "query-\(text)"
  }

  var title: String {
    String(localized: .RecipeSearch.recipeSearchSuggestionQueryTitle(text))
  }

  var detail: String {
    String(localized: .RecipeSearch.recipeSearchSuggestionQueryDetail)
  }

  var imageURL: URL? {
    nil
  }

  var symbolName: String {
    "magnifyingglass"
  }

  var selection: RecipeSearchInputSelection {
    .text(text)
  }
}
