//
//  RecipeRecentSuggestionRowViewModel.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

/// Something searched for before. Separate from the query row because the two are offered for
/// different reasons and read differently in the list.
nonisolated struct RecipeRecentSuggestionRowViewModel: RecipeSuggestionRowViewModelProtocol {
  let text: String
}

// MARK: - Getters

nonisolated extension RecipeRecentSuggestionRowViewModel {
  var id: String {
    "recent-\(text)"
  }

  var title: String {
    text
  }

  var detail: String {
    String(localized: .RecipeSearch.recipeSearchSuggestionRecentDetail)
  }

  var imageURL: URL? {
    nil
  }

  var symbolName: String {
    "clock"
  }

  var selection: RecipeSearchInputSelection {
    .text(text)
  }
}
