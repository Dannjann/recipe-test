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
  func getRecipes(page: Int, perPage: Int) async throws -> ([RemoteRecipeSummary], RemotePaginationMetaInfo) {
    let response = try await request(
      "recipes",
      method: .get,
      parameters: [
        "page": page,
        "per_page": perPage,
      ],
      encoding: URLEncoding.default
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
}
