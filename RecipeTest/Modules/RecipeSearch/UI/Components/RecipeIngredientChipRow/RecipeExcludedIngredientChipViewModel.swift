//
//  RecipeExcludedIngredientChipViewModel.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

/// An ingredient the recipe must not contain.
nonisolated struct RecipeExcludedIngredientChipViewModel: RecipeIngredientChipViewModelProtocol {
  let ingredient: String
}

// MARK: - Getters

nonisolated extension RecipeExcludedIngredientChipViewModel {
  /// The side is part of the identity: both rows can hold the same word over the life of an
  /// edit, and two chips sharing an id would break `ForEach`'s diffing.
  var id: String {
    "exclude-\(ingredient)"
  }

  /// The same colour the results list's facet chips use, so an ingredient looks the same in
  /// the overlay as it does on the list.
  var backgroundColorStyle: Color.ThemeColor {
    .complementaryShade2
  }

  var accessibilityIdentifier: String {
    RecipeSearchAccessibilityID.excludeChipRemoveButton(ingredient)
  }
}
