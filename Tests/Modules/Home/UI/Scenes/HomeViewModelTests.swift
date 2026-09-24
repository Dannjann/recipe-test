//
//  HomeViewModelTests.swift
//  Tests
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation
@testable import RecipeTest
import Testing

@MainActor
struct HomeViewModelTests {
  @Test
  func loadContent_bothSucceed_loadsBothSections() async {
    let service = MockRecipeService(
      recipes: RecipeListPage(recipes: [.dummy(id: "rcp-001")], meta: .dummy()),
      categories: [.dummy(id: "cat-01")]
    )
    let sut = HomeViewModel(recipeService: service)

    await sut.loadContent()

    #expect(sut.latestRecipes.value?.map(\.id) == ["rcp-001"])
    #expect(sut.categories.value?.map(\.id) == ["cat-01"])
  }

  @Test
  func loadContent_asksForTheSixLatestRecipes() async {
    let service = MockRecipeService()
    let sut = HomeViewModel(recipeService: service)

    await sut.loadContent()

    #expect(service.recipes.lastRequest?.query.sort == .latest)
    #expect(service.recipes.lastRequest?.page == Page(index: 1, size: 6))
  }

  /// The point of per-section state: one outage costs one section.
  @Test
  func loadContent_categoriesFails_leavesTheRecipesSectionLoaded() async {
    let service = MockRecipeService()
    service.categories.fails(with: AppError.unknown)
    let sut = HomeViewModel(recipeService: service)

    await sut.loadContent()

    #expect(sut.latestRecipes.isLoaded)
    #expect(sut.categories.isLoaded == false)
  }

  @Test
  func loadContent_recipesFails_leavesTheCategoriesSectionLoaded() async {
    let service = MockRecipeService()
    service.recipes.fails(with: AppError.unknown)
    let sut = HomeViewModel(recipeService: service)

    await sut.loadContent()

    #expect(sut.categories.isLoaded)
    #expect(sut.latestRecipes.isLoaded == false)
  }

  @Test
  func loadContent_noRows_reportsEmptyRatherThanAnEmptyLoad() async {
    let service = MockRecipeService(
      recipes: RecipeListPage(recipes: [], meta: .dummy()),
      categories: []
    )
    let sut = HomeViewModel(recipeService: service)

    await sut.loadContent()

    #expect(sut.latestRecipes == .empty)
    #expect(sut.categories == .empty)
  }

  @Test
  func loadLatestRecipes_afterAFailure_recoversTheSection() async {
    let service = MockRecipeService()
    service.recipes.fails(with: AppError.unknown)
    let sut = HomeViewModel(recipeService: service)
    await sut.loadContent()

    service.recipes.returns(RecipeListPage(recipes: [.dummy(id: "rcp-002")], meta: .dummy()))
    await sut.loadLatestRecipes()

    #expect(sut.latestRecipes.value?.map(\.id) == ["rcp-002"])
  }

  /// Review Focus 3. Retry has to clear the stale message before the new answer lands,
  /// or the section sits on an error while it is already refetching.
  @Test
  func loadLatestRecipes_fromFailed_clearsTheErrorBeforeTheResponseArrives() async {
    let service = MockRecipeService()
    service.recipes.fails(with: AppError.unknown)
    let sut = HomeViewModel(recipeService: service)
    await sut.loadContent()

    let observed = StateBox()
    service.recipes.responds { _ in
      await observed.record(sut.latestRecipes)

      return RecipeListPage(recipes: [.dummy()], meta: .dummy())
    }
    await sut.loadLatestRecipes()

    #expect(observed.value == .loading)
  }

  /// Review Focus 2. A refresh keeps what the reader is already looking at; replacing it
  /// with a spinner blanks the screen underneath a refresh control that is already
  /// spinning.
  @Test
  func loadContent_whenAlreadyLoaded_keepsTheContentVisibleWhileRefreshing() async {
    let service = MockRecipeService()
    let sut = HomeViewModel(recipeService: service)
    await sut.loadContent()

    let observed = StateBox()
    service.recipes.responds { _ in
      await observed.record(sut.latestRecipes)

      return RecipeListPage(recipes: [.dummy()], meta: .dummy())
    }
    await sut.loadContent()

    #expect(observed.value?.isLoaded == true)
  }

  /// Review Focus 1. SwiftUI cancels `.task` on disappear; that must not paint an error.
  @Test
  func loadLatestRecipes_whenCancelled_keepsTheSectionItAlreadyHad() async {
    let service = MockRecipeService()
    let sut = HomeViewModel(recipeService: service)
    await sut.loadContent()
    let loaded = sut.latestRecipes

    service.recipes.fails(with: CancellationError())
    await sut.loadLatestRecipes()

    #expect(sut.latestRecipes == loaded)
  }

  @Test
  func loadLatestRecipes_whenTheURLLoadIsCancelled_keepsTheSectionItAlreadyHad() async {
    let service = MockRecipeService()
    let sut = HomeViewModel(recipeService: service)
    await sut.loadContent()
    let loaded = sut.latestRecipes

    service.recipes.fails(with: URLError(.cancelled))
    await sut.loadLatestRecipes()

    #expect(sut.latestRecipes == loaded)
  }

  @Test
  func loadCategories_whenItFails_showsTheErrorDescription() async {
    let service = MockRecipeService()
    service.categories.fails(with: RecipeServiceError.unmappableRecipe(id: "rcp-001"))
    let sut = HomeViewModel(recipeService: service)

    await sut.loadCategories()

    #expect(sut.categories == .failed(RecipeServiceError.unmappableRecipe(id: "rcp-001").localizedDescription))
  }
}

// MARK: - Helpers

/// Lets a stubbed response read the state the view model is in *while* that response is
/// still in flight. A captured `var` cannot be written from the stub's closure — it
/// escapes into `MockAPICall` and runs off the test's isolation — so the observation goes
/// through a reference instead.
private final class StateBox: @unchecked Sendable {
  private let lock = NSLock()
  private var recorded: SectionState<[RecipeSummary]>?

  var value: SectionState<[RecipeSummary]>? {
    lock.withLock { recorded }
  }

  func record(_ state: SectionState<[RecipeSummary]>) {
    lock.withLock { recorded = state }
  }
}
