//
//  RecipeSuggestion.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

/// One row the search field can offer.
///
/// `query` and `recent` are both a piece of text the field would take, but they are separate
/// cases because they are offered for different reasons and read differently in the list — a
/// `recent` row is something the user searched before, a `query` row is what they are typing
/// right now.
nonisolated enum RecipeSuggestion: Equatable {
  case query(String)
  case recent(String)
  case category(RecipeCategory)
  case recipe(RecipeSummary)
}
