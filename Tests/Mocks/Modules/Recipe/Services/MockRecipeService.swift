//
//  MockRecipeService.swift
//  Tests
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation
@testable import RecipeTest

/// A `RecipeServiceProtocol` double, built the same way as `MockRecipeAPI`: one
/// `MockAPICall` per endpoint, so a test can stub per-request answers with `responds` and
/// assert on `requests` without a bag of loose properties.
final class MockRecipeService: RecipeServiceProtocol {
  enum MockError: Error {
    /// `getRecipe(id:)` has no caller until the detail stage. Throwing beats returning a
    /// hand-built `Recipe`, which would mean constructing a dozen nested domain types
    /// that nothing in this stage reads.
    case notStubbed
  }

  let recipes: MockAPICall<Page, RecipeListPage>

  init(page: RecipeListPage = .dummy()) {
    recipes = MockAPICall(returning: page)
  }
}

// MARK: - RecipeServiceProtocol

extension MockRecipeService {
  func getRecipes(page: Page) async throws -> RecipeListPage {
    try await recipes.invoke(page)
  }

  func getRecipe(id _: String) async throws -> Recipe {
    throw MockError.notStubbed
  }
}
