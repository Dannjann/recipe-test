//
//  APIClient+Recipe.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Alamofire
import Foundation

nonisolated extension APIClient: RecipeAPIProtocol {
  /// The query's own parameters ride alongside paging rather than inside it: paging
  /// belongs to the caller, the filters belong to the query.
  func getRecipes(
    query: RecipeQuery,
    page: Int,
    perPage: Int
  ) async throws -> ([RemoteRecipeSummary], RemotePaginationMetaInfo) {
    var parameters: [String: any Sendable] = try query.queryParameters()
    parameters["page"] = page
    parameters["per_page"] = perPage

    let response = try await request(
      "recipes",
      method: .get,
      parameters: parameters,
      encoding: Self.filterEncoding
    )

    return try decodeModelWithMeta(response)
  }

  func getRecipe(id: String) async throws -> RemoteRecipe {
    let response = try await request(
      "recipes/\(id)",
      method: .get,
      encoding: URLEncoding.default
    )

    return try decodeModel(response)
  }

  func getCategories() async throws -> [RemoteRecipeCategory] {
    let response = try await request(
      "categories",
      method: .get,
      encoding: URLEncoding.default
    )

    return try decodeModel(response)
  }
}

// MARK: - Encoding

private nonisolated extension APIClient {
  /// `URLEncoding.default` is `.brackets` + `.numeric`, which would send
  /// `include_ingredients[]=garlic` and `is_vegetarian=1`. The contract is repeated keys
  /// and literal booleans, so both are set explicitly rather than inherited.
  ///
  /// This is not cosmetic: under the defaults the router matches neither spelling, and a
  /// filter it cannot see is a filter that silently passes everything.
  static var filterEncoding: URLEncoding {
    URLEncoding(destination: .methodDependent, arrayEncoding: .noBrackets, boolEncoding: .literal)
  }
}
