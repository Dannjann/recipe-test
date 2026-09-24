//
//  RecipeServingsOptionViewModel.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

nonisolated struct RecipeServingsOptionViewModel: RecipeServingsOptionViewModelProtocol {
  let servings: RecipeServings
  let isSelected: Bool
}

// MARK: - Getters

nonisolated extension RecipeServingsOptionViewModel {
  var id: RecipeServings {
    servings
  }

  /// `RecipeServings.rawValue` is already the display string — "1", "2", "4", "6+".
  var label: String {
    servings.rawValue
  }

  var accessibilityLabel: String {
    String(localized: .RecipeSearch.recipeSearchServingsAccessibilityLabel(servings.rawValue))
  }

  var accessibilityIdentifier: String {
    "recipe-search-servings-option-\(identifierSuffix)"
  }
}

// MARK: - Getters > Private

private nonisolated extension RecipeServingsOptionViewModel {
  /// "6+" would put a character into an identifier a selector has to escape.
  var identifierSuffix: String {
    servings == .sixOrMore ? "6-plus" : servings.rawValue
  }
}
