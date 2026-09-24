//
//  RecipeSearchInputViewModelProtocol.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

/// What picking a suggestion means to the screen that pushed this one.
nonisolated enum RecipeSearchInputSelection: Equatable {
  /// Fill the field and go back to the filters.
  case text(String)
  /// Leave the overlay entirely and open this recipe.
  case recipe(RecipeSummary)
}

@MainActor
protocol RecipeSearchInputViewModelProtocol: AnyObject, Observable {
  /// Outside `sections` on purpose: this row has to survive a slow fetch and a failed one,
  /// because a network problem must never stop somebody searching for what they typed.
  var queryRow: RecipeSuggestionRowViewModel? { get }
  var sections: SectionState<[RecipeSuggestionSectionViewModel]> { get }
  var emptyText: LocalizedStringResource { get }

  func update(text: String) async
  func select(_ row: RecipeSuggestionRowViewModel) -> RecipeSearchInputSelection
}
