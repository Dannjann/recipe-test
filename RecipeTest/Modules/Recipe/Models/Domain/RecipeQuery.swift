//
//  RecipeQuery.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

/// Every filter the prototype's list surfaces can apply, in one value.
///
/// A struct rather than nine parameters on `getRecipes`: `APIRequestParameters` exists for
/// exactly that case, and it supplies the snake_case-converting encoder, so the wire names
/// fall out of the property names with no hand-written mapping.
nonisolated struct RecipeQuery: APIRequestParameters, Equatable {
  var searchText: String?
  var category: String?
  var cuisine: String?
  var isVegetarian: Bool?
  var servings: RecipeServings?
  var includeIngredients: [String]
  var excludeIngredients: [String]
  var searchesSteps: Bool
  var sort: RecipeSort?

  init(
    searchText: String? = nil,
    category: String? = nil,
    cuisine: String? = nil,
    isVegetarian: Bool? = nil,
    servings: RecipeServings? = nil,
    includeIngredients: [String] = [],
    excludeIngredients: [String] = [],
    searchesSteps: Bool = false,
    sort: RecipeSort? = nil
  ) {
    self.searchText = searchText
    self.category = category
    self.cuisine = cuisine
    self.isVegetarian = isVegetarian
    self.servings = servings
    self.includeIngredients = includeIngredients
    self.excludeIngredients = excludeIngredients
    self.searchesSteps = searchesSteps
    self.sort = sort
  }

  /// The unfiltered query. `GET recipes` with this carries only `page` and `per_page`.
  static let empty = RecipeQuery()
}

// MARK: - Encoding

nonisolated extension RecipeQuery {
  /// Nil facets, empty lists and an un-toggled `searchesSteps` are dropped rather than
  /// sent empty: a router handed `category=` would filter on the empty string.
  ///
  /// `false` for `isVegetarian` is kept — that is a filter the user set, not an absence.
  ///
  /// The values are narrowed to the three types this query can hold rather than left as
  /// `Any`: `APIClient.request` is `async`, so anything crossing into it has to be
  /// `Sendable`, and `Any` is not.
  func queryParameters() throws -> [String: any Sendable] {
    let data = try Self.encoder().encode(self)

    guard let encoded = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
      return [:]
    }

    var parameters: [String: any Sendable] = [:]

    for (key, value) in encoded {
      switch value {
      case let string as String:
        parameters[key] = string

      case let flag as Bool:
        parameters[key] = flag

      case let list as [String] where !list.isEmpty:
        parameters[key] = list

      case is [String]:
        // An empty list is a filter nobody set.
        break

      default:
        // A facet of some other type would otherwise vanish from the request with no
        // compile error and no failing test — a filter that silently does nothing.
        assertionFailure("RecipeQuery.\(key) encodes to an unsupported type: \(type(of: value))")
      }
    }

    if !searchesSteps {
      parameters.removeValue(forKey: "searches_steps")
    }

    return parameters
  }
}

/// How many the recipe serves, as a filter.
///
/// An enum rather than an `Int` because the prototype's fourth option is `6+` — a lower
/// bound, not a value. Raw values are the wire strings, so encoding is free.
nonisolated enum RecipeServings: String, Equatable, CaseIterable, Codable {
  case one = "1"
  case two = "2"
  case four = "4"
  case sixOrMore = "6+"
}

/// The only ordering the product has. `latest` is the fixture's own order, which stores
/// newest first — nothing else can define it now that `updated_at` is gone.
nonisolated enum RecipeSort: String, Equatable, Codable {
  case latest
}
