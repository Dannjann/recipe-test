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
nonisolated struct RecipeSummary: Equatable, Hashable, Identifiable {
  let id: String
  let title: String
  let shortDescription: String
  let heroImageURL: URL?
  let totalTimeMinutes: Int?
  let difficulty: RecipeDifficulty?
  let rating: Double
  let ratingCount: Int
  let tags: [String]
}
