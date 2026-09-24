//
//  RecipeSearchApplyTests.swift
//  Tests
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation
@testable import RecipeTest
import Testing

/// What the overlay and the list underneath do to each other — the seam the two coordinators
/// wire together, tested without either of them.
@MainActor
struct RecipeSearchApplyTests {
  @Test
  func editingTheDraft_withoutApplying_neverReachesTheList() async {
    let service = MockRecipeService()
    let list = RecipeListViewModelTestFactory.make(
      request: .category(.dummy(name: "Desserts")),
      service: service
    )
    await list.loadFirstPage()
    let requestsBefore = service.recipes.callCount

    let overlay = RecipeSearchViewModelTestFactory.make(query: list.query)
    overlay.toggleVegetarian()
    overlay.addInclude("garlic")
    overlay.set(searchText: "mango")

    #expect(service.recipes.callCount == requestsBefore)
    #expect(list.facetChips.isEmpty)
    #expect(list.searchPlaceholder.contains("Desserts"))
  }

  @Test
  func applying_fromACategoryList_carriesTheCategoryThrough() async {
    let service = MockRecipeService()
    let list = RecipeListViewModelTestFactory.make(
      request: .category(.dummy(name: "Desserts")),
      service: service
    )
    let overlay = RecipeSearchViewModelTestFactory.make(query: list.query)
    overlay.toggleVegetarian()
    overlay.set(searchText: "mango")

    await apply(overlay, to: list)

    #expect(service.recipes.lastRequest?.query.category == "Desserts")
    #expect(service.recipes.lastRequest?.query.isVegetarian == true)
    #expect(service.recipes.lastRequest?.query.searchText == "mango")
    #expect(list.title == "Desserts")
  }

  @Test
  func applying_theOverlaysOwnFacets_becomeTheListsChips() async {
    let service = MockRecipeService()
    let list = RecipeListViewModelTestFactory.make(service: service)
    let overlay = RecipeSearchViewModelTestFactory.make()
    overlay.toggleVegetarian()
    overlay.addExclude("pork")

    await apply(overlay, to: list)

    #expect(list.facetChips.map(\.label).count == 2)
    #expect(list.showsClearAllChips)
  }

  @Test
  func clearingInTheOverlay_thenApplying_leavesTheListUnfiltered() async {
    let service = MockRecipeService()
    let list = RecipeListViewModelTestFactory.make(service: service)
    let overlay = RecipeSearchViewModelTestFactory.make(query: RecipeQuery(
      searchText: "mango",
      isVegetarian: true,
      includeIngredients: ["garlic"]
    ))

    overlay.clearAll()
    await apply(overlay, to: list)

    #expect(list.facetChips.isEmpty)
    #expect(service.recipes.lastRequest?.query == .empty)
  }
}

// MARK: - Helpers

private extension RecipeSearchApplyTests {
  func apply(
    _ overlay: RecipeSearchViewModel,
    to list: RecipeListViewModel
  ) async {
    guard case let .apply(query) = overlay.apply() else {
      Issue.record("apply() did not return .apply")
      return
    }

    await list.apply(query: query)
  }
}
