//
//  RecipeMapper.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

/// Turns a `RemoteRecipe` into a `Recipe`.
///
/// Each nested relation gets its own helper below with its own idea of what makes an
/// entry unusable. The rule throughout: drop the smallest thing that is broken. A
/// gallery photo with no URL costs that photo, an ingredient with no name costs that
/// ingredient, and only a missing id or title costs the whole recipe.
nonisolated enum RecipeMapper {
  static func toDomain(from remote: RemoteRecipe) -> Recipe? {
    guard
      let id = remote.id, !id.isEmpty,
      let title = remote.title, !title.isEmpty
    else {
      return nil
    }

    return Recipe(
      id: id,
      title: title,
      shortDescription: remote.shortDescription ?? "",
      fullDescription: remote.fullDescription ?? "",
      heroImageURL: parseURL(remote.heroImageUrl),
      totalTimeMinutes: remote.totalTimeMinutes,
      prepTimeMinutes: remote.prepTimeMinutes,
      cookTimeMinutes: remote.cookTimeMinutes,
      servings: remote.servings,
      difficulty: remote.difficulty.flatMap { RecipeDifficulty(rawValue: $0) },
      cuisine: remote.cuisine,
      mealType: remote.mealType,
      tags: remote.tags ?? [],
      dietaryAttributes: remote.dietaryAttributes ?? [],
      allergens: remote.allergens ?? [],
      rating: remote.rating ?? 0,
      ratingCount: remote.ratingCount ?? 0,
      updatedAt: remote.updatedAt.flatMap { DateFormatter.iso8601.date(from: $0) },
      author: remote.author.flatMap { mapAuthor(from: $0) },
      nutrition: remote.nutrition.map { mapNutrition(from: $0) },
      gallery: (remote.gallery ?? []).compactMap { mapMedia(from: $0) },
      ingredientGroups: (remote.ingredientGroups ?? []).compactMap { mapGroup(from: $0) },
      steps: (remote.steps ?? [])
        .compactMap { mapStep(from: $0) }
        .sorted { $0.number < $1.number }
    )
  }
}

// MARK: - Relations

private nonisolated extension RecipeMapper {
  static func parseURL(_ string: String?) -> URL? {
    string.flatMap { URL(string: $0) }
  }

  /// An author with no name has nothing to show, so the recipe goes out without one.
  static func mapAuthor(from remote: RemoteRecipeAuthor) -> RecipeAuthor? {
    guard
      let id = remote.id, !id.isEmpty,
      let name = remote.name, !name.isEmpty
    else {
      return nil
    }

    return RecipeAuthor(
      id: id,
      name: name,
      avatarURL: parseURL(remote.avatarUrl),
      profileURL: parseURL(remote.profileUrl)
    )
  }

  /// Never fails: every figure is independently optional, and a block with only some of
  /// them filled in is a shape the API really sends.
  static func mapNutrition(from remote: RemoteRecipeNutrition) -> RecipeNutrition {
    RecipeNutrition(
      caloriesPerServing: remote.caloriesPerServing,
      proteinGrams: remote.proteinGrams,
      carbohydrateGrams: remote.carbohydrateGrams,
      fatGrams: remote.fatGrams,
      fibreGrams: remote.fibreGrams,
      sodiumMilligrams: remote.sodiumMilligrams
    )
  }

  static func mapMedia(from remote: RemoteRecipeMedia) -> RecipeMedia? {
    guard
      let id = remote.id, !id.isEmpty,
      let url = parseURL(remote.url)
    else {
      return nil
    }

    return RecipeMedia(id: id, url: url, altText: remote.altText)
  }

  /// A group left with no usable ingredients would render as a heading with nothing
  /// under it, so it is dropped rather than shown empty.
  static func mapGroup(from remote: RemoteIngredientGroup) -> RecipeIngredientGroup? {
    guard let id = remote.id, !id.isEmpty else { return nil }

    let ingredients = (remote.ingredients ?? []).compactMap { mapIngredient(from: $0) }

    guard !ingredients.isEmpty else { return nil }

    return RecipeIngredientGroup(id: id, title: remote.title, ingredients: ingredients)
  }

  static func mapIngredient(from remote: RemoteIngredient) -> RecipeIngredient? {
    guard
      let id = remote.id, !id.isEmpty,
      let name = remote.name, !name.isEmpty
    else {
      return nil
    }

    return RecipeIngredient(
      id: id,
      name: name,
      quantity: remote.quantity,
      unit: remote.unit,
      note: remote.note,
      isOptional: remote.isOptional ?? false
    )
  }

  /// A step with no number cannot be placed in the sequence, and one with no text has
  /// nothing to instruct. Either way it is not a step.
  static func mapStep(from remote: RemoteRecipeStep) -> RecipeStep? {
    guard
      let id = remote.id, !id.isEmpty,
      let number = remote.number,
      let text = remote.text, !text.isEmpty
    else {
      return nil
    }

    return RecipeStep(
      id: id,
      number: number,
      text: text,
      imageURL: parseURL(remote.imageUrl),
      durationSeconds: remote.durationSeconds
    )
  }
}
