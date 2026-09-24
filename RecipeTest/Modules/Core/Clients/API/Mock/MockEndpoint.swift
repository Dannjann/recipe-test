//
//  MockEndpoint.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

/// One case per endpoint the mock transport knows how to answer.
///
/// Add a case and a fixture file when you add an endpoint; an unmatched path deliberately
/// produces a 404 rather than silently succeeding, so a typo in a resource path fails the
/// same way it would against a real backend.
nonisolated enum MockEndpoint: Equatable {
  /// `GET recipes` — a page of the recipe list.
  case recipes

  /// `GET recipes/{id}` — one recipe, sliced out of the same fixture the list uses.
  case recipe(id: String)

  /// `GET categories` — the browse tiles and their recipe counts.
  case categories

  /// Matches on the trailing path components, so the versioned prefix (`/api/v1/...`)
  /// does not have to be repeated here.
  static func match(path: String, method: String) -> MockEndpoint? {
    let components = path.split(separator: "/").map(String.init)
    let resource = components.last ?? ""

    guard method.uppercased() == "GET" else { return nil }

    // Checked before the collection below: `recipes/rcp-001` and `recipes` differ only
    // in whether a resource name sits in front of the last component.
    if components.dropLast().last == "recipes" {
      return .recipe(id: resource)
    }

    switch resource {
    case "recipes":
      return .recipes

    case "categories":
      return .categories

    default:
      return nil
    }
  }

  /// Both recipe endpoints read the same file — a detail is one row of the collection,
  /// not a second copy of it.
  var fixtureName: String? {
    switch self {
    case .recipes,
         .recipe:
      "recipes"

    case .categories:
      "categories"
    }
  }

  var isPaginated: Bool {
    switch self {
    case .recipes:
      true

    case .categories,
         .recipe:
      false
    }
  }

  /// The id of the single row this endpoint answers with, when it addresses one resource
  /// rather than a collection. Nil for a collection endpoint.
  var fixtureRowID: String? {
    switch self {
    case let .recipe(id):
      id

    case .categories,
         .recipes:
      nil
    }
  }

  /// Whether the query engine may narrow this endpoint's rows.
  ///
  /// Only the recipe collection carries the keys those filters read. A categories request
  /// that happened to carry `?category=Pasta` would otherwise match no tile and answer
  /// 200 with an empty grid.
  var isFilterable: Bool {
    switch self {
    case .recipe,
         .recipes:
      true

    case .categories:
      false
    }
  }

  var contentType: String {
    switch self {
    case .categories,
         .recipes,
         .recipe:
      "application/json"
    }
  }
}
