//
//  RecipeDifficulty+DisplayName.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

nonisolated extension RecipeDifficulty {
  var displayName: LocalizedStringResource {
    switch self {
    case .easy:
      .RecipeDetail.recipeDetailDifficultyEasy

    case .medium:
      .RecipeDetail.recipeDetailDifficultyMedium

    case .hard:
      .RecipeDetail.recipeDetailDifficultyHard
    }
  }
}
