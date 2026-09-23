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
/// The nested types live in this file rather than one each: they are field lists with
/// no behaviour and are only ever read as part of a recipe.
///
/// `updatedAt` stays a `String` here and is parsed in `RecipeMapper`. Handing it to a
/// decoder date strategy would make one unparseable timestamp throw away the entire
/// recipe; in the mapper it costs that one field.
nonisolated struct RemoteRecipe: APIModel, Decodable, Equatable {
  let id: String?
  let slug: String?
  let title: String?
  let shortDescription: String?
  let fullDescription: String?
  let heroImageUrl: String?
  let servings: Int?
  let prepTimeMinutes: Int?
  let cookTimeMinutes: Int?
  let totalTimeMinutes: Int?
  let difficulty: String?
  let cuisine: String?
  let mealType: String?
  let tags: [String]?
  let dietaryAttributes: [String]?
  let allergens: [String]?
  let rating: Double?
  let ratingCount: Int?
  let updatedAt: String?
  let author: RemoteRecipeAuthor?
  let nutrition: RemoteRecipeNutrition?
  let gallery: [RemoteRecipeMedia]?
  let ingredientGroups: [RemoteIngredientGroup]?
  let steps: [RemoteRecipeStep]?
}

nonisolated struct RemoteRecipeAuthor: APIModel, Decodable, Equatable {
  let id: String?
  let name: String?
  let avatarUrl: String?
  let profileUrl: String?
}

nonisolated struct RemoteRecipeNutrition: APIModel, Decodable, Equatable {
  let caloriesPerServing: Int?
  let proteinGrams: Double?
  let carbohydrateGrams: Double?
  let fatGrams: Double?
  let fibreGrams: Double?
  let sodiumMilligrams: Double?
}

nonisolated struct RemoteRecipeMedia: APIModel, Decodable, Equatable {
  let id: String?
  let url: String?
  let altText: String?
}

nonisolated struct RemoteIngredientGroup: APIModel, Decodable, Equatable {
  let id: String?
  let title: String?
  let ingredients: [RemoteIngredient]?
}

nonisolated struct RemoteIngredient: APIModel, Decodable, Equatable {
  let id: String?
  let name: String?
  let quantity: Double?
  let unit: String?
  let note: String?
  let isOptional: Bool?
}

nonisolated struct RemoteRecipeStep: APIModel, Decodable, Equatable {
  let id: String?
  let number: Int?
  let text: String?
  let imageUrl: String?
  let durationSeconds: Int?
}
