//
//  RecipeSuggestionRowViewModel.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

nonisolated struct RecipeSuggestionRowViewModel: RecipeSuggestionRowViewModelProtocol, Equatable {
  let suggestion: RecipeSuggestion
}

// MARK: - Getters

nonisolated extension RecipeSuggestionRowViewModel {
  var id: String {
    switch suggestion {
    case let .query(text):
      "query-\(text)"

    case let .recent(text):
      "recent-\(text)"

    case let .category(category):
      "category-\(category.id)"

    case let .recipe(summary):
      "recipe-\(summary.id)"
    }
  }

  var title: String {
    switch suggestion {
    case let .query(text):
      String(localized: .RecipeSearch.recipeSearchSuggestionQueryTitle(text))

    case let .recent(text):
      text

    case let .category(category):
      category.name

    case let .recipe(summary):
      summary.title
    }
  }

  var detail: String {
    switch suggestion {
    case .query:
      String(localized: .RecipeSearch.recipeSearchSuggestionQueryDetail)

    case .recent:
      String(localized: .RecipeSearch.recipeSearchSuggestionRecentDetail)

    case .category:
      String(localized: .RecipeSearch.recipeSearchSuggestionCategoryDetail)

    case let .recipe(summary):
      summary.cuisine ?? String(localized: .RecipeSearch.recipeSearchSuggestionRecipeDetail)
    }
  }

  var imageURL: URL? {
    switch suggestion {
    case let .category(category):
      category.imageURL

    case let .recipe(summary):
      summary.heroImageURL

    case .query, .recent:
      nil
    }
  }

  var symbolName: String? {
    switch suggestion {
    case .query:
      "magnifyingglass"

    case .recent:
      "clock"

    case .category, .recipe:
      nil
    }
  }

  var accessibilityIdentifier: String {
    "recipe-search-suggestion-\(id)"
  }
}
