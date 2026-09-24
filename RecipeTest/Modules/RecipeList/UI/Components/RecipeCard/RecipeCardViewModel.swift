//
//  RecipeCardViewModel.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

/// A struct, not an `@Observable` class: `SectionState` constrains its value to `Equatable`.
nonisolated struct RecipeCardViewModel: RecipeCardViewModelProtocol, Equatable {
  let summary: RecipeSummary
}

// MARK: - Getters

nonisolated extension RecipeCardViewModel {
  var id: String {
    summary.id
  }

  var title: String {
    summary.title
  }

  var imageURL: URL? {
    summary.heroImageURL
  }

  /// The API stores cuisine lower-cased ("italian"); the prototype prints it capitalised.
  var cuisineAndCategory: String? {
    let parts = [
      summary.cuisine?.localizedCapitalized,
      summary.category,
    ].compactMap(\.self)

    guard !parts.isEmpty else { return nil }

    return parts.joined(separator: metadataSeparator)
  }

  var cookingTimeText: String? {
    Duration.cookingTimeText(totalMinutes: summary.totalTimeMinutes)
  }

  var servingsText: String? {
    summary.servings.map { String($0) }
  }

  var accessibilityLabel: String {
    var parts = [title]

    if let cookingTimeText {
      parts.append(cookingTimeText)
    }

    if let servings = summary.servings {
      parts.append(String(localized: .RecipeList.recipeListCardServingsAccessibilityLabel(servings)))
    }

    return parts.joined(separator: accessibilitySeparator)
  }

  /// The grid card draws no cuisine or category, so only the row speaks them.
  var rowAccessibilityLabel: String {
    guard let cuisineAndCategory else { return accessibilityLabel }

    return [
      title,
      cuisineAndCategory,
      cookingTimeText,
      summary.servings.map { String(localized: .RecipeList.recipeListCardServingsAccessibilityLabel($0)) },
    ]
    .compactMap(\.self)
    .joined(separator: accessibilitySeparator)
  }
}

// MARK: - Getters > Constants

private nonisolated extension RecipeCardViewModel {
  var metadataSeparator: String {
    String(localized: .RecipeList.recipeListCardMetadataSeparator)
  }

  var accessibilitySeparator: String {
    String(localized: .RecipeList.recipeListCardAccessibilitySeparator)
  }
}
