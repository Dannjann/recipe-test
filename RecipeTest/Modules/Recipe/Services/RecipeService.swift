//
//  RecipeService.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

/// Fetches recipes and hands back domain models.
///
/// Depends on `RecipeAPIProtocol` rather than on `APIClient`, which is what lets a test
/// substitute `MockRecipeAPI` and run without a network or a simulator.
///
/// Errors from the API layer propagate unchanged. `APIClient` has already reported them
/// through `onError`, so there is nothing useful to add here.
final nonisolated class RecipeService: RecipeServiceProtocol {
  private let api: any RecipeAPIProtocol

  init(api: any RecipeAPIProtocol) {
    self.api = api
  }
}

// MARK: - Methods

nonisolated extension RecipeService {
  /// A row that cannot be mapped is dropped from the page rather than failing it — one
  /// bad row must not cost the user the other nine.
  func getRecipes(page: Page) async throws -> RecipeListPage {
    let (remote, meta) = try await api.getRecipes(page: page.index, perPage: page.size)

    return RecipeListPage(
      recipes: remote.compactMap { RecipeSummaryMapper.toDomain(from: $0) },
      meta: meta
    )
  }

  /// Unlike a list page, there is no partial result to degrade to: a detail screen with
  /// no recipe has nothing to show.
  func getRecipe(id: String) async throws -> Recipe {
    let remote = try await api.getRecipe(id: id)

    guard let recipe = RecipeMapper.toDomain(from: remote) else {
      throw AppError.unknown
    }

    return recipe
  }
}
