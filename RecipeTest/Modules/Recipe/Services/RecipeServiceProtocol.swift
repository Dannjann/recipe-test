//
//  RecipeServiceProtocol.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

/// What a view model will depend on. Domain types only — nothing above this line has any
/// reason to know the API's JSON shape.
nonisolated protocol RecipeServiceProtocol: AppServiceProtocol, Sendable {
  func getRecipes(query: RecipeQuery, page: Page) async throws -> RecipeListPage

  func getRecipe(id: String) async throws -> Recipe

  func getCategories() async throws -> [RecipeCategory]
}
