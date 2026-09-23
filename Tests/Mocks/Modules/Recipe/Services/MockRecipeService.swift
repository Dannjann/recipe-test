//
//  MockRecipeService.swift
//  Tests
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation
@testable import RecipeTest

final class MockRecipeService: RecipeServiceProtocol {
  enum MockError: Error {
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
