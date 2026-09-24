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
  let description: String
  let heroImageURL: URL?
  let category: String?
  let cuisine: String?
  let mealType: String?
  let totalTimeMinutes: Int?
  let servings: Int?
  let difficulty: RecipeDifficulty?
  let isVegetarian: Bool
  let gallery: [URL]
  let ingredients: [RecipeIngredient]
  let steps: [String]
}

/// One line of the ingredients checklist.
///
/// `quantityText` is a display string rather than a number and a unit: the source data
/// cannot support arithmetic — a third of its ingredients carry no unit at all — and
/// nothing in the product does arithmetic on it.
///
/// Lives in this file because an ingredient exists only inside a recipe.
nonisolated struct RecipeIngredient: Equatable, Identifiable {
  let id: String
  let quantityText: String
  let name: String
  let imageURL: URL?
  let isMain: Bool
}
