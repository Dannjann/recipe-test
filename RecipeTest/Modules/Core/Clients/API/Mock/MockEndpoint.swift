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
  /// A placeholder photo. The seed is the filename, so a given URL gets a stable image.
  case image(seed: String)

  /// `GET recipes` — a page of the recipe list.
  case recipes

  /// `GET recipes/{id}` — one recipe, sliced out of the same fixture the list uses.
  case recipe(id: String)

  /// Matches on the trailing path components, so the versioned prefix (`/api/v1/...`)
  /// does not have to be repeated here.
  static func match(path: String, method: String) -> MockEndpoint? {
    let components = path.split(separator: "/").map(String.init)
    let resource = components.last ?? ""

    guard method.uppercased() == "GET" else { return nil }

    if components.dropLast().last == "images" {
      return .image(seed: (resource as NSString).deletingPathExtension)
    }

    // Checked before the collection below: `recipes/rcp-001` and `recipes` differ only
    // in whether a resource name sits in front of the last component.
    if components.dropLast().last == "recipes" {
      return .recipe(id: resource)
    }

    switch resource {
    case "recipes":
      return .recipes

    default:
      return nil
    }
  }

  /// Both recipe endpoints read the same file — a detail is one row of the collection,
  /// not a second copy of it.
  var fixtureName: String? {
    switch self {
    case .image:
      nil

    case .recipes,
         .recipe:
      "recipes"
    }
  }

  var isPaginated: Bool {
    switch self {
    case .recipes:
      true

    case .image,
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

    case .image,
         .recipes:
      nil
    }
  }

  var contentType: String {
    switch self {
    case .image:
      "image/png"

    case .recipes,
         .recipe:
      "application/json"
    }
  }
}
