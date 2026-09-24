//
//  RecipeSearchInputSelection.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

/// What picking a suggestion means to the screen that pushed the typing screen.
nonisolated enum RecipeSearchInputSelection: Equatable {
  /// Fill the field and go back to the filters.
  case text(String)
  /// Leave the overlay entirely and open this recipe.
  case recipe(RecipeSummary)
}
