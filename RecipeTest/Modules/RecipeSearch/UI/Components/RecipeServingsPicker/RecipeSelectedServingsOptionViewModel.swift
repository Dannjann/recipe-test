//
//  RecipeSelectedServingsOptionViewModel.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

/// The servings option the draft is filtering on. At most one exists at a time.
nonisolated struct RecipeSelectedServingsOptionViewModel: RecipeServingsOptionViewModelProtocol {
  let servings: RecipeServings
}

// MARK: - Getters

nonisolated extension RecipeSelectedServingsOptionViewModel {
  var backgroundColorStyle: Color.ThemeColor {
    .surfacesBrandDefault
  }

  var labelColorStyle: Color.ThemeColor {
    .textInverted
  }

  var accessibilityTraits: AccessibilityTraits {
    [.isButton, .isSelected]
  }
}
