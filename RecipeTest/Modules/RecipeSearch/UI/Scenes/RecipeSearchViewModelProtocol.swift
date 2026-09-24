//
//  RecipeSearchViewModelProtocol.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

/// The concrete element view models are named rather than their protocols because `ForEach`
/// needs a concrete `Identifiable`. The element *views* still depend on the protocols.
@MainActor
protocol RecipeSearchViewModelProtocol: AnyObject, Observable {
  var fieldText: String { get }
  var hasFieldText: Bool { get }

  var isVegetarian: Bool { get }
  var searchesSteps: Bool { get }
  var servingsOptions: [RecipeServingsOptionViewModel] { get }
  var includeChips: [RecipeIngredientChipViewModel] { get }
  var excludeChips: [RecipeIngredientChipViewModel] { get }
  var showsClearAll: Bool { get }

  func toggleVegetarian()
  func toggleSearchesSteps()
  func select(servings: RecipeServings)
  func addInclude(_ text: String)
  func addExclude(_ text: String)
  func remove(chip: RecipeIngredientChipViewModel)
  func set(searchText: String)
  func clearAll()
  func apply() -> RecipeSearchResult
}
