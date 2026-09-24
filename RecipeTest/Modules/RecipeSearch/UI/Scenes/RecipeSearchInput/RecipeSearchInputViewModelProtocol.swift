//
//  RecipeSearchInputViewModelProtocol.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

@MainActor
protocol RecipeSearchInputViewModelProtocol: AnyObject, Observable {
  /// Outside `sections` on purpose: this row has to survive a slow fetch and a failed one,
  /// because a network problem must never stop somebody searching for what they typed.
  var queryRow: (any RecipeSuggestionRowViewModelProtocol)? { get }
  var sections: SectionState<[RecipeSuggestionSectionViewModel]> { get }
  var emptyText: LocalizedStringResource { get }

  func update(text: String) async
}
