//
//  RecipeSearchViewModelTests.swift
//  Tests
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation
@testable import RecipeTest
import Testing

@MainActor
struct RecipeSearchViewModelTests {
  @Test
  func draft_seededFromTheRequest_carriesTheTextAndTheCategory() {
    let sut = RecipeSearchViewModelTestFactory.make(query: RecipeQuery(
      searchText: "mango",
      category: "Desserts"
    ))

    #expect(sut.fieldText == "mango")
    #expect(sut.hasFieldText)
    #expect(sut.draft.category == "Desserts")
  }

  @Test
  func fieldText_noSearchText_isThePlaceholder() {
    let sut = RecipeSearchViewModelTestFactory.make()

    #expect(!sut.hasFieldText)
    #expect(sut.fieldText == String(localized: .RecipeSearch.recipeSearchFieldPlaceholder))
  }

  @Test
  func toggleVegetarian_switchedOffAgain_clearsTheFilterRatherThanSettingFalse() {
    let sut = RecipeSearchViewModelTestFactory.make()

    sut.toggleVegetarian()
    #expect(sut.draft.isVegetarian == true)

    sut.toggleVegetarian()
    #expect(sut.draft.isVegetarian == nil)
  }

  @Test
  func toggleSearchesSteps_twice_returnsToOff() {
    let sut = RecipeSearchViewModelTestFactory.make()

    sut.toggleSearchesSteps()
    #expect(sut.draft.searchesSteps)

    sut.toggleSearchesSteps()
    #expect(!sut.draft.searchesSteps)
  }

  @Test
  func select_theServingsAlreadySelected_clearsIt() {
    let sut = RecipeSearchViewModelTestFactory.make()

    sut.select(servings: .four)
    #expect(sut.draft.servings == .four)

    sut.select(servings: .four)
    #expect(sut.draft.servings == nil)
  }

  @Test
  func select_aDifferentServings_replacesTheSelection() {
    let sut = RecipeSearchViewModelTestFactory.make()

    sut.select(servings: .four)
    sut.select(servings: .sixOrMore)

    #expect(sut.draft.servings == .sixOrMore)
    #expect(sut.servingsOptions.filter(\.isSelected).map(\.label) == ["6+"])
  }

  @Test
  func addInclude_paddedAndCapitalised_storesOneTrimmedLowercasedChip() {
    let sut = RecipeSearchViewModelTestFactory.make()

    sut.addInclude("  Garlic ")
    sut.addInclude("garlic")

    #expect(sut.draft.includeIngredients == ["garlic"])
    #expect(sut.includeChips.count == 1)
  }

  @Test
  func addInclude_blank_storesNothing() {
    let sut = RecipeSearchViewModelTestFactory.make()

    sut.addInclude("   ")

    #expect(sut.draft.includeIngredients.isEmpty)
  }

  @Test
  func addInclude_anIngredientAlreadyExcluded_movesItRatherThanHoldingBoth() {
    let sut = RecipeSearchViewModelTestFactory.make()
    sut.addExclude("pork")

    sut.addInclude("pork")

    #expect(sut.draft.includeIngredients == ["pork"])
    #expect(sut.draft.excludeIngredients.isEmpty)
  }

  @Test
  func addExclude_anIngredientAlreadyIncluded_movesItRatherThanHoldingBoth() {
    let sut = RecipeSearchViewModelTestFactory.make()
    sut.addInclude("pork")

    sut.addExclude("pork")

    #expect(sut.draft.excludeIngredients == ["pork"])
    #expect(sut.draft.includeIngredients.isEmpty)
  }

  @Test
  func remove_anIncludeChip_leavesTheExcludeSideAlone() {
    let sut = RecipeSearchViewModelTestFactory.make()
    sut.addInclude("garlic")
    sut.addExclude("pork")

    sut.remove(chip: RecipeIngredientChipViewModel(
      ingredient: "garlic",
      kind: .include
    ))

    #expect(sut.draft.includeIngredients.isEmpty)
    #expect(sut.draft.excludeIngredients == ["pork"])
  }

  @Test
  func set_paddedSearchText_storesItTrimmed() {
    let sut = RecipeSearchViewModelTestFactory.make()

    sut.set(searchText: "  adobo ")

    #expect(sut.draft.searchText == "adobo")
  }

  @Test
  func set_blankSearchText_clearsItRatherThanStoringAnEmptyString() {
    let sut = RecipeSearchViewModelTestFactory.make(query: RecipeQuery(searchText: "adobo"))

    sut.set(searchText: "   ")

    #expect(sut.draft.searchText == nil)
  }

  @Test
  func clearAll_afterEditing_clearsTheTextAndTheFacetsButKeepsTheCategory() {
    let sut = RecipeSearchViewModelTestFactory.make(query: RecipeQuery(
      searchText: "mango",
      category: "Desserts"
    ))
    sut.toggleVegetarian()
    sut.addInclude("garlic")
    sut.toggleSearchesSteps()

    sut.clearAll()

    #expect(sut.draft.searchText == nil)
    #expect(sut.draft.activeFacets.isEmpty)
    #expect(sut.draft.category == "Desserts")
    #expect(!sut.showsClearAll)
  }

  @Test
  func showsClearAll_textOnly_isTrue() {
    let sut = RecipeSearchViewModelTestFactory.make(query: RecipeQuery(searchText: "adobo"))

    #expect(sut.showsClearAll)
  }

  @Test
  func apply_withText_returnsTheDraftAndRecordsTheSearch() {
    let store = MockRecentSearchStore()
    let sut = RecipeSearchViewModelTestFactory.make(
      query: RecipeQuery(searchText: "adobo"),
      store: store
    )
    sut.toggleVegetarian()

    guard case let .apply(query) = sut.apply() else {
      Issue.record("apply() did not return .apply")
      return
    }

    #expect(query == sut.draft)
    #expect(query.isVegetarian == true)
    #expect(store.recorded == ["adobo"])
  }

  @Test
  func apply_withoutText_recordsNothing() {
    let store = MockRecentSearchStore()
    let sut = RecipeSearchViewModelTestFactory.make(store: store)
    sut.toggleVegetarian()

    _ = sut.apply()

    #expect(store.recorded.isEmpty)
  }
}

// MARK: - Factory

@MainActor
enum RecipeSearchViewModelTestFactory {
  static func make(
    query: RecipeQuery = .empty,
    store: RecentSearchStoreProtocol = MockRecentSearchStore()
  ) -> RecipeSearchViewModel {
    RecipeSearchViewModel(
      request: RecipeSearchRequest(query: query),
      recentSearchStore: store
    )
  }
}
