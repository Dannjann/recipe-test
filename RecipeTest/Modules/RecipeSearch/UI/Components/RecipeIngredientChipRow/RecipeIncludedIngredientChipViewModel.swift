//
//  RecipeIncludedIngredientChipViewModel.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

/// An ingredient the recipe must contain.
nonisolated struct RecipeIncludedIngredientChipViewModel: RecipeIngredientChipViewModelProtocol {
  let ingredient: String
}

// MARK: - Getters

nonisolated extension RecipeIncludedIngredientChipViewModel {
  /// The side is part of the identity: both rows can hold the same word over the life of an
  /// edit, and two chips sharing an id would break `ForEach`'s diffing.
  var id: String {
    "include-\(ingredient)"
  }

  /// The same colour the results list's facet chips use, so an ingredient looks the same in
  /// the overlay as it does on the list.
  var backgroundColorStyle: Color.ThemeColor {
    .complementaryShade1
  }

  var accessibilityIdentifier: String {
    RecipeSearchAccessibilityID.includeChipRemoveButton(ingredient)
  }
}
