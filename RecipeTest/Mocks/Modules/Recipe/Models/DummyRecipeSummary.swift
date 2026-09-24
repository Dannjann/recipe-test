//
//  DummyRecipeSummary.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

#if DEBUG
  nonisolated extension RecipeSummary {
    static func dummy(
      id: String = "rcp-001",
      title: String = "Spaghetti alla Carbonara",
      heroImageURL: URL? = URL(string: "https://example.com/carbonara.jpg"),
      category: String? = "Pasta",
      cuisine: String? = "italian",
      mealType: String? = "dinner",
      totalTimeMinutes: Int? = 25,
      servings: Int? = 4,
      difficulty: RecipeDifficulty? = .medium,
      isVegetarian: Bool = false
    ) -> RecipeSummary {
      RecipeSummary(
        id: id,
        title: title,
        heroImageURL: heroImageURL,
        category: category,
        cuisine: cuisine,
        mealType: mealType,
        totalTimeMinutes: totalTimeMinutes,
        servings: servings,
        difficulty: difficulty,
        isVegetarian: isVegetarian
      )
    }
  }
#endif
