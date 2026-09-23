//
//  RecipeDifficulty.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

/// How hard a recipe is to cook.
///
/// An enum rather than a raw string because the set is closed and small, and a badge in
/// the UI has to switch on it. An unrecognised value maps to `nil` in the mapper rather
/// than failing the row — see `RecipeSummaryMapper`.
///
/// The open-ended facets — cuisine, meal type, tags, dietary attributes, allergens —
/// deliberately stay `String`. An enum would have to drop a value it has no case for,
/// and silently dropping an entry from an allergen list is worse than showing a word the
/// app does not recognise.
nonisolated enum RecipeDifficulty: String, Equatable, CaseIterable {
  case easy
  case medium
  case hard
}
