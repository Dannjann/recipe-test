//
//  Recipe.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

/// A full recipe, as the app uses it.
///
/// Carries the summary's fields as well as the detail's, so a detail screen reached
/// without a preceding list fetch needs nothing else.
nonisolated struct Recipe: Equatable, Identifiable {
  let id: String
  let title: String
  let shortDescription: String
  let fullDescription: String
  let heroImageURL: URL?
  let totalTimeMinutes: Int?
  let prepTimeMinutes: Int?
  let cookTimeMinutes: Int?
  let servings: Int?
  let difficulty: RecipeDifficulty?
  let cuisine: String?
  let mealType: String?
  let tags: [String]
  let dietaryAttributes: [String]
  let allergens: [String]
  let rating: Double
  let ratingCount: Int
  let updatedAt: Date?
  let author: RecipeAuthor?
  let nutrition: RecipeNutrition?
  let gallery: [RecipeMedia]
  let ingredientGroups: [RecipeIngredientGroup]
  let steps: [RecipeStep]
}
