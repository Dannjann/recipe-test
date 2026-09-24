//
//  RemoteRecipe.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

/// A full recipe, as the API sends it.
///
/// The summary's fields plus the detail's, so a detail screen reached without a preceding
/// list fetch needs nothing else.
nonisolated struct RemoteRecipe: APIModel, Decodable, Equatable {
  let id: String?
  let title: String?
  let description: String?
  let category: String?
  let cuisine: String?
  let mealType: String?
  let totalTimeMinutes: Int?
  let servings: Int?
  let difficulty: String?
  let isVegetarian: Bool?
  let heroImageUrl: String?
  let gallery: [String]?
  let ingredients: [RemoteRecipeIngredient]?
  let steps: [String]?
}

/// Lives in this file rather than its own: an ingredient exists only inside a recipe, and
/// the two are only ever read together.
nonisolated struct RemoteRecipeIngredient: APIModel, Decodable, Equatable {
  let quantityText: String?
  let name: String?
  let imageUrl: String?
  let isMain: Bool?
}
