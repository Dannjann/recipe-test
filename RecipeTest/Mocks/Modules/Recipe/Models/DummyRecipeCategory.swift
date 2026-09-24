//
//  DummyRecipeCategory.swift
//  Tests
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

nonisolated extension RecipeCategory {
  static func dummy(
    id: String = "cat-01",
    name: String = "Meal",
    imageURL: URL? = URL(string: "https://example.com/meal.jpg"),
    recipeCount: Int = 18
  ) -> RecipeCategory {
    RecipeCategory(
      id: id,
      name: name,
      imageURL: imageURL,
      recipeCount: recipeCount
    )
  }
}
