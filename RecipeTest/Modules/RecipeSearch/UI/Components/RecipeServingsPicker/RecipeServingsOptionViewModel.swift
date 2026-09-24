//
//  RecipeServingsOptionViewModel.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

/// A servings option the draft is not filtering on.
nonisolated struct RecipeServingsOptionViewModel: RecipeServingsOptionViewModelProtocol {
  let servings: RecipeServings
}

// MARK: - Getters

nonisolated extension RecipeServingsOptionViewModel {
  var backgroundColorStyle: Color.ThemeColor {
    .surfacesFieldsAndTags
  }

  var labelColorStyle: Color.ThemeColor {
    .textPrimary
  }

  var accessibilityTraits: AccessibilityTraits {
    .isButton
  }
}
