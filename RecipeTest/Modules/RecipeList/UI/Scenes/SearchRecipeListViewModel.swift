//
//  SearchRecipeListViewModel.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

/// Stores no text of its own: the overlay hands this screen a new query without rebuilding it,
/// and a stored copy would leave the pill advertising the search before last.
final class SearchRecipeListViewModel: RecipeListViewModel {
  // MARK: - Overrides

  override var title: String {
    String(localized: .RecipeList.recipeListTitleSearchResults)
  }

  override var scopedSearchPlaceholder: String {
    String(localized: .RecipeList.recipeListSearchPlaceholderAll)
  }
}
