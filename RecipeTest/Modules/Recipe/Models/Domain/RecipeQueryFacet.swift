//
//  RecipeQueryFacet.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

/// `category` and `searchText` are absent: both are already the list's title.
nonisolated enum RecipeQueryFacet: Hashable {
  case vegetarian(Bool)
  case servings(RecipeServings)
  case include(String)
  case exclude(String)
  case searchesSteps
}

// MARK: - Getters

nonisolated extension RecipeQuery {
  /// Ordered as the prototype's chip row orders them, so the row is stable across reloads.
  var activeFacets: [RecipeQueryFacet] {
    var facets: [RecipeQueryFacet] = []

    if let isVegetarian {
      facets.append(.vegetarian(isVegetarian))
    }

    if let servings {
      facets.append(.servings(servings))
    }

    // A repeated ingredient would put the same chip id into a `ForEach` twice.
    facets.append(contentsOf: includeIngredients.uniqued().map(RecipeQueryFacet.include))
    facets.append(contentsOf: excludeIngredients.uniqued().map(RecipeQueryFacet.exclude))

    if searchesSteps {
      facets.append(.searchesSteps)
    }

    return facets
  }
}

// MARK: - Removal

nonisolated extension RecipeQuery {
  func removing(_ facet: RecipeQueryFacet) -> RecipeQuery {
    var query = self

    switch facet {
    case .vegetarian:
      query.isVegetarian = nil

    case .servings:
      query.servings = nil

    case let .include(ingredient):
      query.includeIngredients.removeAll { $0 == ingredient }

    case let .exclude(ingredient):
      query.excludeIngredients.removeAll { $0 == ingredient }

    case .searchesSteps:
      query.searchesSteps = false
    }

    return query
  }

  func clearingFacets() -> RecipeQuery {
    var query = self
    query.isVegetarian = nil
    query.servings = nil
    query.includeIngredients = []
    query.excludeIngredients = []
    query.searchesSteps = false

    return query
  }
}
