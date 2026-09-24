//
//  RecipeSuggestionSectionViewModel.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

nonisolated struct RecipeSuggestionSectionViewModel: Identifiable {
  let id: RecipeSuggestionSectionID
  let title: LocalizedStringResource?
  let rows: [any RecipeSuggestionRowViewModelProtocol]
}

// MARK: - Equatable

extension RecipeSuggestionSectionViewModel: Equatable {
  /// Written out because `rows` holds existentials, which have no synthesised `==`. Comparing
  /// what each row paints rather than only its id keeps a re-fetch that changed a title from
  /// being mistaken for no change at all.
  nonisolated static func == (
    lhs: RecipeSuggestionSectionViewModel,
    rhs: RecipeSuggestionSectionViewModel
  ) -> Bool {
    lhs.id == rhs.id
      && lhs.title == rhs.title
      && lhs.rows.map(\.renderedIdentity) == rhs.rows.map(\.renderedIdentity)
  }
}

/// The sections the suggestion list can show, in the order it shows them.
///
/// An enum rather than three string literals spread across the view model and its mock: the
/// raw values are `ForEach` identities, so a typo in one of them would be a silent diffing bug.
nonisolated enum RecipeSuggestionSectionID: String {
  case recent
  case categories
  case recipes
}
