//
//  MockRecipeAPI.swift
//  Tests
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation
@testable import RecipeTest

/// A `RecipeAPIProtocol` double.
///
/// The class itself holds nothing but one `MockAPICall` per endpoint; everything a test
/// stubs or asserts goes through those. Immutable `let` properties of `Sendable` type, so
/// the `Sendable` conformance the protocol requires is checked rather than asserted.
final class MockRecipeAPI: RecipeAPIProtocol {
  /// Named rather than a tuple so `lastRequest` can be compared in one `#expect`.
  struct RecipesRequest: Equatable {
    let page: Int
    let perPage: Int
  }

  let recipes: MockAPICall<RecipesRequest, ([RemoteRecipeSummary], RemotePaginationMetaInfo)>
  let recipe: MockAPICall<String, RemoteRecipe>

  init(
    recipes: [RemoteRecipeSummary] = [.dummy()],
    meta: RemotePaginationMetaInfo = .dummy(),
    recipe: RemoteRecipe = .dummy()
  ) {
    self.recipes = MockAPICall(returning: (recipes, meta))
    self.recipe = MockAPICall(returning: recipe)
  }
}

// MARK: - RecipeAPIProtocol

extension MockRecipeAPI {
  func getRecipes(page: Int, perPage: Int) async throws -> ([RemoteRecipeSummary], RemotePaginationMetaInfo) {
    try await recipes.invoke(RecipesRequest(page: page, perPage: perPage))
  }

  func getRecipe(id: String) async throws -> RemoteRecipe {
    try await recipe.invoke(id)
  }
}
