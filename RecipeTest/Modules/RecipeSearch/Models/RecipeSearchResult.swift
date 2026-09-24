//
//  RecipeSearchResult.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

/// What the overlay hands back.
///
/// Two cases because it has two exits: the Search button, and a recipe suggestion that skips
/// the results list entirely. Closing the overlay returns neither.
nonisolated enum RecipeSearchResult: Hashable {
  case apply(RecipeQuery)
  case openRecipe(RecipeSummary)
}
