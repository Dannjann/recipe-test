//
//  DummyRemoteRecipeSummary.swift
//  Tests
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation
@testable import RecipeTest

extension RemoteRecipeSummary {
  static func dummy(
    id: String? = "rcp-001",
    title: String? = "Spaghetti alla Carbonara",
    category: String? = "Pasta",
    cuisine: String? = "italian",
    mealType: String? = "dinner",
    totalTimeMinutes: Int? = 25,
    servings: Int? = 4,
    difficulty: String? = "medium",
    isVegetarian: Bool? = false,
    heroImageUrl: String? = "https://www.themealdb.com/images/media/meals/llcbn01574260722.jpg"
  ) -> RemoteRecipeSummary {
    RemoteRecipeSummary(
      id: id,
      title: title,
      category: category,
      cuisine: cuisine,
      mealType: mealType,
      totalTimeMinutes: totalTimeMinutes,
      servings: servings,
      difficulty: difficulty,
      isVegetarian: isVegetarian,
      heroImageUrl: heroImageUrl
    )
  }
}
