//
//  RecipeAPIProtocol.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

/// The recipe endpoints, owned by this feature rather than by Core.
///
/// `APIClient` conforms to it in `APIClient+Recipe`. That indirection is what gives the
/// service a seam: `RecipeService` depends on this protocol, so a test substitutes
/// `MockRecipeAPI` and never goes near `URLSession`.
///
/// Speaks the wire's vocabulary — `Int` page numbers and remote DTOs. Translating the
/// app's `Page` into `page` and `per_page` is the service's job, not this layer's.
/// `RecipeQuery` crosses unchanged because it *is* wire vocabulary: it encodes itself.
nonisolated protocol RecipeAPIProtocol: Sendable {
  func getRecipes(
    query: RecipeQuery,
    page: Int,
    perPage: Int
  ) async throws -> ([RemoteRecipeSummary], RemotePaginationMetaInfo)

  func getRecipe(id: String) async throws -> RemoteRecipe

  func getCategories() async throws -> [RemoteRecipeCategory]
}
