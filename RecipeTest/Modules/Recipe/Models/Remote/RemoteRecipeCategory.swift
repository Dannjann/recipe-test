//
//  RemoteRecipeCategory.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

/// One browse tile, as the API sends it.
nonisolated struct RemoteRecipeCategory: APIModel, Decodable, Equatable {
  let id: String?
  let name: String?
  let imageUrl: String?
  let recipeCount: Int?
}
