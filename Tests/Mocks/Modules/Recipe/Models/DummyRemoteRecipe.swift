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
    slug: String? = "spaghetti-alla-carbonara",
    title: String? = "Spaghetti alla Carbonara",
    shortDescription: String? = "Roman pasta bound with egg yolk and pecorino.",
    fullDescription: String? = "The whole dish turns on one trick.",
    heroImageUrl: String? = "https://api.example.com/api/v1/images/carbonara.png",
    servings: Int? = 4,
    prepTimeMinutes: Int? = 10,
    cookTimeMinutes: Int? = 15,
    totalTimeMinutes: Int? = 25,
    difficulty: String? = "medium",
    cuisine: String? = "italian",
    mealType: String? = "dinner",
    tags: [String]? = ["quick"],
    dietaryAttributes: [String]? = [],
    allergens: [String]? = ["gluten", "eggs"],
    rating: Double? = 4.8,
    ratingCount: Int? = 2147,
    updatedAt: String? = "2026-07-01T07:07:00.000Z",
    author: RemoteRecipeAuthor? = .dummy(),
    nutrition: RemoteRecipeNutrition? = .dummy(),
    gallery: [RemoteRecipeMedia]? = [.dummy()],
    ingredientGroups: [RemoteIngredientGroup]? = [.dummy()],
    steps: [RemoteRecipeStep]? = [.dummy(id: "stp-1", number: 1), .dummy(id: "stp-2", number: 2)]
  ) -> RemoteRecipe {
    RemoteRecipe(
      id: id,
      slug: slug,
      title: title,
      shortDescription: shortDescription,
      fullDescription: fullDescription,
      heroImageUrl: heroImageUrl,
      servings: servings,
      prepTimeMinutes: prepTimeMinutes,
      cookTimeMinutes: cookTimeMinutes,
      totalTimeMinutes: totalTimeMinutes,
      difficulty: difficulty,
      cuisine: cuisine,
      mealType: mealType,
      tags: tags,
      dietaryAttributes: dietaryAttributes,
      allergens: allergens,
      rating: rating,
      ratingCount: ratingCount,
      updatedAt: updatedAt,
      author: author,
      nutrition: nutrition,
      gallery: gallery,
      ingredientGroups: ingredientGroups,
      steps: steps
    )
  }
}

extension RemoteRecipeAuthor {
  static func dummy(
    id: String? = "aut-02",
    name: String? = "Tobias Lindqvist",
    avatarUrl: String? = "https://api.example.com/api/v1/images/author-aut-02.png",
    profileUrl: String? = "https://example.com/cooks/tobias-lindqvist"
  ) -> RemoteRecipeAuthor {
    RemoteRecipeAuthor(id: id, name: name, avatarUrl: avatarUrl, profileUrl: profileUrl)
  }
}

extension RemoteRecipeNutrition {
  static func dummy(
    caloriesPerServing: Int? = 712,
    proteinGrams: Double? = 29.4,
    carbohydrateGrams: Double? = 63.8,
    fatGrams: Double? = 36.2,
    fibreGrams: Double? = 3.1,
    sodiumMilligrams: Double? = 980.0
  ) -> RemoteRecipeNutrition {
    RemoteRecipeNutrition(
      caloriesPerServing: caloriesPerServing,
      proteinGrams: proteinGrams,
      carbohydrateGrams: carbohydrateGrams,
      fatGrams: fatGrams,
      fibreGrams: fibreGrams,
      sodiumMilligrams: sodiumMilligrams
    )
  }
}

extension RemoteRecipeMedia {
  static func dummy(
    id: String? = "med-001-1",
    url: String? = "https://api.example.com/api/v1/images/carbonara-1.png",
    altText: String? = "Spaghetti alla Carbonara, photograph 1"
  ) -> RemoteRecipeMedia {
    RemoteRecipeMedia(id: id, url: url, altText: altText)
  }
}

extension RemoteIngredientGroup {
  static func dummy(
    id: String? = "grp-001-1",
    title: String? = nil,
    ingredients: [RemoteIngredient]? = [.dummy()]
  ) -> RemoteIngredientGroup {
    RemoteIngredientGroup(id: id, title: title, ingredients: ingredients)
  }
}

extension RemoteIngredient {
  static func dummy(
    id: String? = "ing-001-1-1",
    name: String? = "Spaghetti",
    quantity: Double? = 320.0,
    unit: String? = "gram",
    note: String? = nil,
    isOptional: Bool? = false
  ) -> RemoteIngredient {
    RemoteIngredient(id: id, name: name, quantity: quantity, unit: unit, note: note, isOptional: isOptional)
  }
}

extension RemoteRecipeStep {
  static func dummy(
    id: String? = "stp-001-1",
    number: Int? = 1,
    text: String? = "Bring a large pan of well-salted water to the boil.",
    imageUrl: String? = nil,
    durationSeconds: Int? = 600
  ) -> RemoteRecipeStep {
    RemoteRecipeStep(id: id, number: number, text: text, imageUrl: imageUrl, durationSeconds: durationSeconds)
  }
}
