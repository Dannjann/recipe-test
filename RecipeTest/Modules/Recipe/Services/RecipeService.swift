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
/// Errors from the API layer propagate unchanged: `APIClient` has already reported them
/// through its own `onError`, so repeating that here would double-count them. `onError`
/// below is for the failures this service raises itself — a payload that decoded but
/// could not be mapped never passes through the client's reporting, and without this
/// seam a backend contract break would surface only as a failed screen with no signal
/// anywhere.
final nonisolated class RecipeService: RecipeServiceProtocol {
  private let api: any RecipeAPIProtocol
  private let onError: SendableErrorResult

  init(
    api: any RecipeAPIProtocol,
    onError: @escaping SendableErrorResult
  ) {
    self.api = api
    self.onError = onError
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
  ///
  /// Reported through `onError` as well as thrown. The response itself was well-formed,
  /// so nothing below this line saw a failure — this is the only place the break is
  /// visible.
  func getRecipe(id: String) async throws -> Recipe {
    let remote = try await api.getRecipe(id: id)

    guard let recipe = RecipeMapper.toDomain(from: remote) else {
      let error = RecipeServiceError.unmappableRecipe(id: id)
      onError(error)

      throw error
    }

    return recipe
  }
}
