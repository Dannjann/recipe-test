//
//  RecipeSearchViewModel.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

@Observable
final class RecipeSearchViewModel: RecipeSearchViewModelProtocol {
  /// Every control edits this and nothing else. The applied query stays with the screen
  /// underneath until `apply()` hands a new one back, so closing changes nothing.
  private(set) var draft: RecipeQuery

  private let recentSearchStore: RecentSearchStoreProtocol

  init(
    request: RecipeSearchRequest,
    recentSearchStore: RecentSearchStoreProtocol = AppContainer.shared.recentSearchStore
  ) {
    draft = request.query
    self.recentSearchStore = recentSearchStore
  }
}

// MARK: - Getters

extension RecipeSearchViewModel {
  var fieldText: String {
    hasFieldText
      ? draft.searchText ?? ""
      : String(localized: .RecipeSearch.recipeSearchFieldPlaceholder)
  }

  var hasFieldText: Bool {
    !(draft.searchText ?? "").isEmpty
  }

  var isVegetarian: Bool {
    draft.isVegetarian ?? false
  }

  var searchesSteps: Bool {
    draft.searchesSteps
  }

  var servingsOptions: [RecipeServingsOptionViewModel] {
    RecipeServings.allCases.map {
      RecipeServingsOptionViewModel(
        servings: $0,
        isSelected: $0 == draft.servings
      )
    }
  }

  var includeChips: [RecipeIngredientChipViewModel] {
    draft.includeIngredients.map {
      RecipeIngredientChipViewModel(
        ingredient: $0,
        kind: .include
      )
    }
  }

  var excludeChips: [RecipeIngredientChipViewModel] {
    draft.excludeIngredients.map {
      RecipeIngredientChipViewModel(
        ingredient: $0,
        kind: .exclude
      )
    }
  }

  var showsClearAll: Bool {
    hasFieldText || !draft.activeFacets.isEmpty
  }
}

// MARK: - Inputs

extension RecipeSearchViewModel {
  /// Off means "no filter", not "not vegetarian": the overlay offers one switch, and
  /// `isVegetarian == false` is a filter of its own that nothing here can set.
  func toggleVegetarian() {
    draft.isVegetarian = isVegetarian ? nil : true
  }

  func toggleSearchesSteps() {
    draft.searchesSteps.toggle()
  }

  func select(servings: RecipeServings) {
    draft.servings = draft.servings == servings ? nil : servings
  }

  func addInclude(_ text: String) {
    add(
      text,
      to: \.includeIngredients,
      removingFrom: \.excludeIngredients
    )
  }

  func addExclude(_ text: String) {
    add(
      text,
      to: \.excludeIngredients,
      removingFrom: \.includeIngredients
    )
  }

  func remove(chip: RecipeIngredientChipViewModel) {
    switch chip.kind {
    case .include:
      draft.includeIngredients.removeAll { $0 == chip.ingredient }

    case .exclude:
      draft.excludeIngredients.removeAll { $0 == chip.ingredient }
    }
  }

  func set(searchText: String) {
    let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

    draft.searchText = trimmed.isEmpty ? nil : trimmed
  }

  /// Clears the text as well as the facets, unlike the results list's `clearFacets()`, which
  /// keeps what scopes the list. This button means "start again".
  func clearAll() {
    draft = draft.clearingFacets()
    draft.searchText = nil
  }

  func apply() -> RecipeSearchResult {
    if let searchText = draft.searchText {
      recentSearchStore.record(searchText)
    }

    return .apply(draft)
  }
}

// MARK: - Helpers

private extension RecipeSearchViewModel {
  /// Lower-cased and trimmed so "  Garlic " and "garlic" are one chip, and removed from the
  /// opposite list so the query never asks for a recipe that both contains and omits it.
  func add(
    _ text: String,
    to keyPath: WritableKeyPath<RecipeQuery, [String]>,
    removingFrom other: WritableKeyPath<RecipeQuery, [String]>
  ) {
    let ingredient = text
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .lowercased()

    guard
      !ingredient.isEmpty,
      !draft[keyPath: keyPath].contains(ingredient)
    else { return }

    draft[keyPath: other].removeAll { $0 == ingredient }
    draft[keyPath: keyPath].append(ingredient)
  }
}
