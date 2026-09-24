//
//  RecipeSearchViewModelProtocol.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

@MainActor
protocol RecipeSearchViewModelProtocol: AnyObject, Observable {
  /// What the user actually typed, empty when they have not. Separate from `fieldText` so
  /// the typing screen prefills with the search rather than with the placeholder.
  var searchText: String { get }

  var fieldText: String { get }
  var fieldTextColorStyle: Color.ThemeColor { get }
  var fieldAccessibilityValue: String { get }
  var showsFieldClear: Bool { get }

  var isVegetarian: Bool { get }
  var searchesSteps: Bool { get }
  var servingsOptions: [any RecipeServingsOptionViewModelProtocol] { get }
  var includeChips: [any RecipeIngredientChipViewModelProtocol] { get }
  var excludeChips: [any RecipeIngredientChipViewModelProtocol] { get }
  var showsClearAll: Bool { get }

  /// Changes when `clearAll()` runs, so the ingredient fields can drop what is half-typed.
  var clearToken: Int { get }

  /// What the overlay hands back. Reading it has no side effect; `recordSearch()` has the one.
  var result: RecipeSearchResult { get }

  func toggleVegetarian()
  func toggleSearchesSteps()
  func select(servings: RecipeServings)
  func addInclude(_ text: String)
  func addExclude(_ text: String)
  func removeInclude(_ ingredient: String)
  func removeExclude(_ ingredient: String)
  func set(searchText: String)
  func clearAll()
  func recordSearch()
}
