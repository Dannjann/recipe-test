//
//  RecipeIngredientChipViewModelProtocol.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

/// One ingredient the draft is filtering on.
///
/// A type per side rather than one type carrying which side it is on: the two differ only in
/// their colour and their identity, and each answers for itself.
nonisolated protocol RecipeIngredientChipViewModelProtocol: Identifiable {
  var id: String { get }
  var ingredient: String { get }
  var backgroundColorStyle: Color.ThemeColor { get }
  var accessibilityIdentifier: String { get }
}

// MARK: - Getters

nonisolated extension RecipeIngredientChipViewModelProtocol {
  var label: String {
    ingredient
  }

  var removeAccessibilityLabel: String {
    String(localized: .RecipeSearch.recipeSearchChipRemoveAccessibilityLabel(ingredient))
  }
}
