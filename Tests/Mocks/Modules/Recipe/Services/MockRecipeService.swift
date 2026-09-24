//
//  MockRecipeService.swift
//  Tests
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation
@testable import RecipeTest

/// A `RecipeServiceProtocol` double, shaped like `MockRecipeAPI`: one `MockAPICall` per
/// method, so one endpoint can be made to fail while its neighbours keep answering —
/// which is the whole point of the screen this doubles for.
final class MockRecipeService: RecipeServiceProtocol {
  /// Named rather than a tuple so `lastRequest` can be compared in one `#expect`.
  struct RecipesRequest: Equatable {
    let query: RecipeQuery
    let page: Page
  }

  let recipes: MockAPICall<RecipesRequest, RecipeListPage>
  let recipe: MockAPICall<String, Recipe>
  let categories: MockAPICall<Void, [RecipeCategory]>

  init(
    recipes: RecipeListPage = RecipeListPage(recipes: [.dummy()], meta: .dummy()),
    recipe: Recipe? = nil,
    categories: [RecipeCategory] = [.dummy()]
  ) {
    self.recipes = MockAPICall(returning: recipes)
    self.categories = MockAPICall(returning: categories)

    // `Recipe` has no dummy yet — no screen in this stage fetches one. A test that needs
    // the detail call stubs it itself rather than paying for a factory nothing reads.
    self.recipe = MockAPICall(
      returning: recipe ?? Recipe(
        id: "rcp-001",
        title: "Spaghetti alla Carbonara",
        description: "",
        heroImageURL: nil,
        category: nil,
        cuisine: nil,
        mealType: nil,
        totalTimeMinutes: nil,
        servings: nil,
        difficulty: nil,
        isVegetarian: false,
        gallery: [],
        ingredients: [],
        steps: []
      )
    )
  }
}

// MARK: - RecipeServiceProtocol

extension MockRecipeService {
  func getRecipes(query: RecipeQuery, page: Page) async throws -> RecipeListPage {
    try await recipes.invoke(RecipesRequest(query: query, page: page))
  }

  func getRecipe(id: String) async throws -> Recipe {
    try await recipe.invoke(id)
  }

  func getCategories() async throws -> [RecipeCategory] {
    try await categories.invoke(())
  }
}
