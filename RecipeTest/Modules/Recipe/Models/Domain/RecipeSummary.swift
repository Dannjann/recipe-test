//
//  RecipeSummary.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

/// One row of the recipe list, as the app uses it.
///
/// Separate from `Recipe` rather than one type with the detail fields left optional: a
/// list cell then cannot reach for steps that were never fetched, and `Recipe` has no
/// optionals that are "only nil in list context".
///
/// The split rule is that the summary carries the row's identity, its photograph and its
/// facets, while the prose and the three collections belong to `Recipe`. `category` and
/// `cuisine` are here because the list row prints `cuisine · category`; `description` is
/// not, because no list surface renders it.
nonisolated struct RecipeSummary: Hashable, Identifiable {
  let id: String
  let title: String
  let heroImageURL: URL?
  let category: String?
  let cuisine: String?
  let mealType: String?
  let totalTimeMinutes: Int?
  let servings: Int?
  let difficulty: RecipeDifficulty?
  let isVegetarian: Bool
}
