//
//  RecipeCategoryMapper.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

/// Turns a `RemoteRecipeCategory` into a `RecipeCategory`.
nonisolated enum RecipeCategoryMapper {
  /// Requires `id` and `name`. A tile with neither a label nor an identity is not a tile.
  static func toDomain(from remote: RemoteRecipeCategory) -> RecipeCategory? {
    guard
      let id = remote.id, !id.isEmpty,
      let name = remote.name, !name.isEmpty
    else {
      return nil
    }

    return RecipeCategory(
      id: id,
      name: name,
      imageURL: remote.imageUrl.flatMap { URL(string: $0) },
      recipeCount: remote.recipeCount ?? 0
    )
  }
}
