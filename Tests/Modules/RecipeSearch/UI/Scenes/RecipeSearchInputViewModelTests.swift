//
//  RecipeSearchInputViewModelTests.swift
//  Tests
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation
@testable import RecipeTest
import Testing

@MainActor
struct RecipeSearchInputViewModelTests {
  @Test
  func update_emptyText_rendersRecentsAndMakesNoRequest() async {
    let service = MockRecipeService()
    let store = MockRecentSearchStore()
    store.searches = ["adobo", "pho"]
    let sut = makeSUT(
      service: service,
      store: store
    )

    await sut.update(text: "")

    #expect(sut.queryRow == nil)
    #expect(sut.sections.value?.first?.rows.map(\.title) == ["adobo", "pho"])
    #expect(!service.recipes.wasCalled)
  }

  @Test
  func update_emptyTextWithNoHistory_isEmptyRatherThanLoaded() async {
    let sut = makeSUT()

    await sut.update(text: "")

    #expect(sut.sections == .empty)
  }

  @Test
  func update_moreRecentsThanTheListShows_offersOnlyTheFirstFour() async {
    let store = MockRecentSearchStore()
    store.searches = ["one", "two", "three", "four", "five"]
    let sut = makeSUT(store: store)

    await sut.update(text: "")

    #expect(sut.sections.value?.first?.rows.count == 4)
  }

  @Test
  func queryRow_textTyped_offersItBack() async {
    let sut = makeSUT()

    await sut.update(text: "ado")

    #expect(sut.queryRow?.title.contains("ado") == true)
  }

  @Test
  func update_typedText_matchesCategoriesCaseInsensitively() async {
    let service = MockRecipeService(categories: [.dummy(name: "Desserts")])
    let sut = makeSUT(service: service)

    await sut.update(text: "dess")

    #expect(titles(of: sut).contains("Desserts"))
  }

  @Test
  func update_typedText_asksTheServiceForThatText() async {
    let service = MockRecipeService()
    let sut = makeSUT(service: service)

    await sut.update(text: "  Adobo  ")

    #expect(service.recipes.lastRequest?.query.searchText == "Adobo")
  }

  @Test
  func update_nothingMatches_isEmptyAndKeepsTheQueryRow() async {
    let service = MockRecipeService(
      recipes: RecipeListPage(
        recipes: [],
        meta: .dummy(total: 0)
      ),
      categories: []
    )
    let sut = makeSUT(service: service)

    await sut.update(text: "zzzz")

    #expect(sut.sections == .empty)
    #expect(sut.queryRow != nil)
  }

  @Test
  func update_theFetchFails_failsTheSectionButKeepsTheQueryRow() async {
    let service = MockRecipeService()
    service.recipes.fails(with: AppError.unknown)
    let sut = makeSUT(service: service)

    await sut.update(text: "ado")

    #expect(sut.queryRow != nil)

    guard case .failed = sut.sections else {
      Issue.record("Expected a failed state, got \(sut.sections)")
      return
    }
  }

  @Test
  func update_theFetchIsCancelled_paintsNeitherAnErrorNorASpinner() async {
    let service = MockRecipeService()
    service.recipes.fails(with: CancellationError())
    let sut = makeSUT(service: service)

    await sut.update(text: "ado")

    #expect(sut.sections != .loading)

    if case .failed = sut.sections {
      Issue.record("A cancelled fetch must not paint an error")
    }
  }

  @Test
  func select_aRecipeRow_returnsTheRecipe() {
    let summary = RecipeSummary.dummy(id: "rcp-007")
    let sut = makeSUT()

    let selection = sut.select(RecipeSuggestionRowViewModel(suggestion: .recipe(summary)))

    #expect(selection == .recipe(summary))
  }

  @Test
  func select_aCategoryRow_fillsTheFieldWithItsName() {
    let sut = makeSUT()

    let selection = sut.select(RecipeSuggestionRowViewModel(
      suggestion: .category(.dummy(name: "Desserts"))
    ))

    #expect(selection == .text("Desserts"))
  }

  @Test
  func select_aRecentRow_fillsTheFieldWithIt() {
    let sut = makeSUT()

    let selection = sut.select(RecipeSuggestionRowViewModel(suggestion: .recent("pho")))

    #expect(selection == .text("pho"))
  }
}

// MARK: - Helpers

private extension RecipeSearchInputViewModelTests {
  func makeSUT(
    text: String = "",
    service: MockRecipeService = MockRecipeService(),
    store: RecentSearchStoreProtocol = MockRecentSearchStore()
  ) -> RecipeSearchInputViewModel {
    RecipeSearchInputViewModel(
      text: text,
      recipeService: service,
      recentSearchStore: store
    )
  }

  func titles(of sut: RecipeSearchInputViewModel) -> [String] {
    sut.sections.value?.flatMap { $0.rows.map(\.title) } ?? []
  }
}
