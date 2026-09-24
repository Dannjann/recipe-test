//
//  RecipeCardViewModelProtocol.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

/// Everything a results row draws, already derived. A card view formats nothing.
///
/// Not `Equatable`: the views hold this as `any RecipeCardViewModelProtocol`, and a `Self`
/// requirement buys nothing there. `RecipeCardViewModel` is `Equatable` as a struct, which is
/// what `SectionState` needs.
nonisolated protocol RecipeCardViewModelProtocol: Identifiable {
  var id: String { get }
  var title: String { get }
  var imageURL: URL? { get }
  var cuisineAndCategory: String? { get }
  var cookingTimeText: String? { get }
  var servingsText: String? { get }
  var accessibilityLabel: String { get }

  /// The list row also prints cuisine and category, so it announces more than the grid card.
  var rowAccessibilityLabel: String { get }

  /// The payload a row tap pushes. Not rendered by anything.
  var summary: RecipeSummary { get }
}
