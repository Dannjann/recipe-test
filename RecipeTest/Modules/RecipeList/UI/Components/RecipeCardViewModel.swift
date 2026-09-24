//
//  RecipeCardViewModel.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

/// A struct rather than an `@Observable` class: `SectionState` constrains its value to
/// `Equatable`, which a struct over a `Hashable` summary gets for free, and there is no
/// mutable state here to observe.
nonisolated struct RecipeCardViewModel: RecipeCardViewModelProtocol {
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

  /// The API stores cuisine lower-cased ("italian") and category title-cased ("Pasta"),
  /// while the prototype prints both capitalised.
  var cuisineAndCategory: String? {
    let parts = [
      summary.cuisine?.localizedCapitalized,
      summary.category,
    ].compactMap(\.self)

    guard !parts.isEmpty else { return nil }

    return parts.joined(separator: metadataSeparator)
  }

  /// The same expression `RecipeDetailViewModel` uses, so one duration is never spelled two
  /// ways — the units localize themselves rather than coming from a catalog.
  var cookingTimeText: String? {
    guard let totalTimeMinutes = summary.totalTimeMinutes else { return nil }

    return Duration
      .seconds(totalTimeMinutes * 60)
      .formatted(.units(
        allowed: [.hours, .minutes],
        width: .abbreviated
      ))
  }

  var servingsText: String? {
    summary.servings.map { String($0) }
  }

  /// The visible servings text is a bare number beside an icon; only the spoken form says
  /// "serves".
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
}

// MARK: - Getters > Constants

private nonisolated extension RecipeCardViewModel {
  var metadataSeparator: String {
    " · "
  }

  var accessibilitySeparator: String {
    ", "
  }
}
