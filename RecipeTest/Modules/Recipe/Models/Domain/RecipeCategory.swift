//
//  RecipeCategory.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

/// One browse tile on the home grid.
///
/// `recipeCount` is served rather than derived: the tile prints "*n* recipes", and a
/// client cannot count what pagination has not fetched.
nonisolated struct RecipeCategory: Equatable, Identifiable {
  let id: String
  let name: String
  let imageURL: URL?
  let recipeCount: Int
}
