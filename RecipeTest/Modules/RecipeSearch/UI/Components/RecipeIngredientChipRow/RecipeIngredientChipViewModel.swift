//
//  RecipeIngredientChipViewModel.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

nonisolated struct RecipeIngredientChipViewModel: RecipeIngredientChipViewModelProtocol {
  enum Kind: String {
    case include
    case exclude
  }

  let ingredient: String
  let kind: Kind
}

// MARK: - Getters

nonisolated extension RecipeIngredientChipViewModel {
  /// The kind is part of the identity: both rows can hold the same word over the life of an
  /// edit, and two chips sharing an id would break `ForEach`'s diffing.
  var id: String {
    "\(kind.rawValue)-\(ingredient)"
  }

  var label: String {
    ingredient
  }

  var removeAccessibilityLabel: String {
    String(localized: .RecipeSearch.recipeSearchChipRemoveAccessibilityLabel(ingredient))
  }

  /// The same two colours the results list's facet chips use, so an ingredient looks the same
  /// in the overlay as it does on the list.
  var backgroundColorStyle: Color.ThemeColor {
    kind == .exclude ? .complementaryShade2 : .complementaryShade1
  }

  var accessibilityIdentifier: String {
    "recipe-search-\(kind.rawValue)-chip-\(ingredient)-remove-button"
  }
}
