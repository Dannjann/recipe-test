//
//  RecipeListRequest.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

/// Lets a category tap, a search and a filter sheet all push the same route.
nonisolated struct RecipeListRequest: Hashable {
  enum Title: Hashable {
    case category(String)
    case search(String)
    case all
  }

  let query: RecipeQuery
  let title: Title
}

// MARK: - Entry points

nonisolated extension RecipeListRequest {
  static func category(_ category: RecipeCategory) -> Self {
    RecipeListRequest(
      query: RecipeQuery(category: category.name),
      title: .category(category.name)
    )
  }

  static func search(
    _ text: String,
    query: RecipeQuery = .empty
  ) -> Self {
    var searched = query
    searched.searchText = text

    return RecipeListRequest(
      query: searched,
      title: .search(text)
    )
  }

  static func all(query: RecipeQuery = .empty) -> Self {
    RecipeListRequest(
      query: query,
      title: .all
    )
  }
}
