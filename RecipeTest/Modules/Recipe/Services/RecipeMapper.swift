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
/// Same contract as `RecipeSummaryMapper`: nil means the payload is not usable. Unlike a
/// list page there is nothing to degrade to, so `RecipeService` turns that nil into a
/// named error rather than an empty screen.
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
      description: remote.description ?? "",
      heroImageURL: remote.heroImageUrl.flatMap { URL(string: $0) },
      category: remote.category,
      cuisine: remote.cuisine,
      mealType: remote.mealType,
      totalTimeMinutes: remote.totalTimeMinutes,
      servings: remote.servings,
      difficulty: remote.difficulty.flatMap { RecipeDifficulty(rawValue: $0) },
      isVegetarian: remote.isVegetarian ?? false,
      gallery: (remote.gallery ?? []).compactMap { URL(string: $0) },
      ingredients: ingredients(from: remote.ingredients ?? [], recipeID: id),
      steps: remote.steps ?? []
    )
  }
}

// MARK: - Ingredients

private nonisolated extension RecipeMapper {
  /// Identity is synthesised from the recipe id and the ingredient's position: the
  /// contract carries no ingredient ids, but a `ForEach` still needs stable identity,
  /// and position within a recipe is stable.
  ///
  /// `enumerated()` runs before the `compactMap` so a dropped ingredient does not
  /// renumber the ones after it.
  static func ingredients(from remote: [RemoteRecipeIngredient], recipeID: String) -> [RecipeIngredient] {
    remote.enumerated().compactMap { index, ingredient in
      guard let name = ingredient.name, !name.isEmpty else {
        return nil
      }

      return RecipeIngredient(
        id: "\(recipeID)-\(index)",
        quantityText: ingredient.quantityText ?? "",
        name: name,
        imageURL: ingredient.imageUrl.flatMap { URL(string: $0) },
        isMain: ingredient.isMain ?? false
      )
    }
  }
}
