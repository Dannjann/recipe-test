//
//  RecipeListLoadState.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

/// What occupies the recipe list screen.
///
/// There is deliberately no `empty` case. Empty is `.loaded` with no rows, which keeps one
/// source of truth for what is on screen — with a separate case, `loadState` and `recipes`
/// can disagree and the screen has two contradictory answers about what to draw.
///
/// This enum covers the *screen*. What happens at the bottom edge of an already-loaded
/// list is carried separately by `isLoadingNextPage` and `nextPageError`, because a failed
/// next page must not take the screen away from the rows the user already has.
nonisolated enum RecipeListLoadState: Equatable {
  /// Nothing attempted yet.
  case idle
  /// The first page is in flight and the screen is empty.
  case loading
  /// Rows are the source of truth; `recipes.isEmpty` is the empty state.
  case loaded
  /// The first page failed and the screen is empty. Carries the message to show.
  case failed(String)
}
