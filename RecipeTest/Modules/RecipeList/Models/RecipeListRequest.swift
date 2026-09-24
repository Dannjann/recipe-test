//
//  RecipeListRequest.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

/// What a results list was asked for: the filter to run, and what the list is *of*.
///
/// The screen reads both and never learns which entry point built them, which is what lets
/// a category tap, a search and a filter sheet all push the same route.
nonisolated struct RecipeListRequest: Hashable {
  /// What the list is of, not the words on the bar — the view model turns this into copy,
  /// and the same value also decides the search pill's placeholder.
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
  /// Sets the filter and the heading from one value, so a list titled "Desserts" that
  /// filters on "Snacks" is not constructible.
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

// MARK: - Methods

nonisolated extension RecipeListRequest {
  /// Used when a facet is removed: the filter changes, what the list is of does not.
  func replacingQuery(_ query: RecipeQuery) -> Self {
    RecipeListRequest(
      query: query,
      title: title
    )
  }
}
