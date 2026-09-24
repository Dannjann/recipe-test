//
//  MockRecipeService.swift
//  Tests
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation
@testable import RecipeTest

/// Shaped like `MockRecipeAPI`: one `MockAPICall` per method, so one call can fail alone.
final class MockRecipeService: RecipeServiceProtocol {
  struct RecipesRequest: Equatable {
    let query: RecipeQuery
    let page: Page
  }

  let recipes: MockAPICall<RecipesRequest, RecipeListPage>
  let recipe: MockAPICall<String, Recipe>
  let categories: MockAPICall<Void, [RecipeCategory]>

  init(
    recipes: RecipeListPage = RecipeListPage(
      recipes: [.dummy()],
      meta: .dummy()
    ),
    recipe: Recipe? = nil,
    categories: [RecipeCategory] = [.dummy()]
  ) {
    self.recipes = MockAPICall(returning: recipes)
    self.categories = MockAPICall(returning: categories)

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
  func getRecipes(
    query: RecipeQuery,
    page: Page
  ) async throws -> RecipeListPage {
    try await recipes.invoke(RecipesRequest(
      query: query,
      page: page
    ))
  }

  func getRecipe(id: String) async throws -> Recipe {
    try await recipe.invoke(id)
  }

  func getCategories() async throws -> [RecipeCategory] {
    try await categories.invoke(())
  }
}
