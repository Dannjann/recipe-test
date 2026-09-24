//
//  DummyRemoteRecipe.swift
//  Tests
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation
@testable import RecipeTest

extension RemoteRecipe {
  static func dummy(
    id: String? = "rcp-001",
    title: String? = "Spaghetti alla Carbonara",
    description: String? = "Roman pasta bound with egg yolk and pecorino.",
    category: String? = "Pasta",
    cuisine: String? = "italian",
    mealType: String? = "dinner",
    totalTimeMinutes: Int? = 25,
    servings: Int? = 4,
    difficulty: String? = "medium",
    isVegetarian: Bool? = false,
    heroImageUrl: String? = "https://www.themealdb.com/images/media/meals/llcbn01574260722.jpg",
    gallery: [String]? = ["https://example.com/1.jpg", "https://example.com/2.jpg"],
    ingredients: [RemoteRecipeIngredient]? = [.dummy()],
    steps: [String]? = ["Boil the water.", "Toss off the heat."]
  ) -> RemoteRecipe {
    RemoteRecipe(
      id: id,
      title: title,
      description: description,
      category: category,
      cuisine: cuisine,
      mealType: mealType,
      totalTimeMinutes: totalTimeMinutes,
      servings: servings,
      difficulty: difficulty,
      isVegetarian: isVegetarian,
      heroImageUrl: heroImageUrl,
      gallery: gallery,
      ingredients: ingredients,
      steps: steps
    )
  }
}

extension RemoteRecipeIngredient {
  static func dummy(
    quantityText: String? = "320 g",
    name: String? = "Spaghetti",
    imageUrl: String? = nil,
    isMain: Bool? = true
  ) -> RemoteRecipeIngredient {
    RemoteRecipeIngredient(
      quantityText: quantityText,
      name: name,
      imageUrl: imageUrl,
      isMain: isMain
    )
  }
}
