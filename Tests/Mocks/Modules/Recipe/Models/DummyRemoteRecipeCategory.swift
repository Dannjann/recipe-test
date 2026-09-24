//
//  DummyRemoteRecipeCategory.swift
//  Tests
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation
@testable import RecipeTest

extension RemoteRecipeCategory {
  static func dummy(
    id: String? = "cat-01",
    name: String? = "Meal",
    imageUrl: String? = "https://example.com/meal.jpg",
    recipeCount: Int? = 18
  ) -> RemoteRecipeCategory {
    RemoteRecipeCategory(
      id: id,
      name: name,
      imageUrl: imageUrl,
      recipeCount: recipeCount
    )
  }
}
