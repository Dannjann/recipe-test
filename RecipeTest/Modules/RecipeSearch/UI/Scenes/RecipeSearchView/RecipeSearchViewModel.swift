//
//  RecipeSearchViewModel.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

@Observable
final class RecipeSearchViewModel: RecipeSearchViewModelProtocol {
  /// Every control edits this and nothing else. The applied query stays with the screen
  /// underneath until `result` hands a new one back, so closing changes nothing.
  private(set) var draft: RecipeQuery

  /// Bumped by `clearAll()`. The ingredient fields own their half-typed text, so "start
  /// again" has to reach them somehow; they key their identity off this.
  private(set) var clearToken = 0

  private let recentSearchStore: RecentSearchStoreProtocol

  init(
    request: RecipeSearchRequest,
    recentSearchStore: RecentSearchStoreProtocol
  ) {
    draft = request.query
    self.recentSearchStore = recentSearchStore
  }
}

// MARK: - Getters

extension RecipeSearchViewModel {
  var searchText: String {
    draft.searchText ?? ""
  }

  var fieldText: String {
    fieldIsPlaceholder
      ? String(localized: .RecipeSearch.recipeSearchFieldPlaceholder)
      : searchText
  }

  var fieldIsPlaceholder: Bool {
    searchText.isEmpty
  }

  var fieldTextColorStyle: Color.ThemeColor {
    fieldIsPlaceholder ? .textTertiary : .textPrimary
  }

  /// Spoken instead of `fieldText`, which VoiceOver would otherwise read as though the user
  /// had typed the placeholder.
  var fieldAccessibilityValue: String {
    fieldIsPlaceholder
      ? String(localized: .RecipeSearch.recipeSearchFieldEmptyAccessibilityValue)
      : searchText
  }

  var showsFieldClear: Bool {
    !fieldIsPlaceholder
  }

  var isVegetarian: Bool {
    draft.isVegetarian ?? false
  }

  var searchesSteps: Bool {
    draft.searchesSteps
  }

  var servingsOptions: [any RecipeServingsOptionViewModelProtocol] {
    RecipeServings.allCases.map { servings -> any RecipeServingsOptionViewModelProtocol in
      guard servings == draft.servings else {
        return RecipeServingsOptionViewModel(servings: servings)
      }

      return RecipeSelectedServingsOptionViewModel(servings: servings)
    }
  }

  var includeChips: [any RecipeIngredientChipViewModelProtocol] {
    draft.includeIngredients.map { RecipeIncludedIngredientChipViewModel(ingredient: $0) }
  }

  var excludeChips: [any RecipeIngredientChipViewModelProtocol] {
    draft.excludeIngredients.map { RecipeExcludedIngredientChipViewModel(ingredient: $0) }
  }

  var showsClearAll: Bool {
    !fieldIsPlaceholder || !draft.activeFacets.isEmpty
  }

  /// What the overlay hands back. A query, so reading it twice is the same as reading it once
  /// — recording the search is `recordSearch()`'s job, not this one's.
  var result: RecipeSearchResult {
    .apply(draft)
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

  func removeInclude(_ ingredient: String) {
    draft.includeIngredients.removeAll { $0 == ingredient }
  }

  func removeExclude(_ ingredient: String) {
    draft.excludeIngredients.removeAll { $0 == ingredient }
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
    clearToken += 1
  }

  /// Separate from `result` so the Search button's one side effect is its own step: a caller
  /// that only wants to read the draft cannot leave a search in the recents by accident.
  func recordSearch() {
    guard let searchText = draft.searchText else { return }

    recentSearchStore.record(searchText)
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

    guard !ingredient.isEmpty else { return }

    // Before the duplicate guard: a draft seeded from a query holding the same ingredient on
    // both sides would otherwise keep it on both, which asks for a recipe that contains and
    // omits the same thing.
    draft[keyPath: other].removeAll { $0 == ingredient }

    guard !draft[keyPath: keyPath].contains(ingredient) else { return }

    draft[keyPath: keyPath].append(ingredient)
  }
}
