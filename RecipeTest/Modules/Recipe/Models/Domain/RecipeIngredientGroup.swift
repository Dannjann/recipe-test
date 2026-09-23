//
//  RecipeIngredientGroup.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

/// A named section of an ingredient list — "For the béchamel", and so on.
///
/// `title` is optional because a recipe with a single list leaves it null: that means
/// "one unnamed list", not a missing value.
nonisolated struct RecipeIngredientGroup: Equatable, Identifiable {
  let id: String
  let title: String?
  let ingredients: [RecipeIngredient]
}

/// Lives with the group because an ingredient only exists inside one.
///
/// `quantity` and `unit` are both optional and independent: "6 egg yolks" has a quantity
/// and no unit, "salt, as required" has neither.
nonisolated struct RecipeIngredient: Equatable, Identifiable {
  let id: String
  let name: String
  let quantity: Double?
  let unit: String?
  let note: String?
  let isOptional: Bool
}
