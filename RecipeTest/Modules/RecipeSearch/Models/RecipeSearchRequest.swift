//
//  RecipeSearchRequest.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

/// What the overlay opens with: the filter the screen underneath is already showing.
///
/// `Identifiable` so `fullScreenCover(item:)` can key on it, and the query *is* the identity —
/// reopening the overlay for a different filter presents a fresh one rather than reusing a
/// draft seeded from the previous screen.
nonisolated struct RecipeSearchRequest: Identifiable, Hashable {
  let query: RecipeQuery
}

// MARK: - Getters

nonisolated extension RecipeSearchRequest {
  var id: RecipeQuery {
    query
  }
}
