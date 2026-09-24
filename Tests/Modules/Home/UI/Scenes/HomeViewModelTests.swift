//
//  HomeViewModelTests.swift
//  Tests
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Alamofire
import Foundation
@testable import RecipeTest
import Testing

@MainActor
struct HomeViewModelTests {
  @Test
  func loadContent_bothSucceed_loadsBothSections() async {
    let service = MockRecipeService(
      recipes: RecipeListPage(
        recipes: [.dummy(id: "rcp-001")],
        meta: .dummy()
      ),
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
    #expect(service.recipes.lastRequest?.page == Page(
      index: 1,
      size: 6
    ))
  }

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
      recipes: RecipeListPage(
        recipes: [],
        meta: .dummy()
      ),
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

    service.recipes.returns(RecipeListPage(
      recipes: [.dummy(id: "rcp-002")],
      meta: .dummy()
    ))
    await sut.loadLatestRecipes()

    #expect(sut.latestRecipes.value?.map(\.id) == ["rcp-002"])
  }

  @Test
  func loadLatestRecipes_fromFailed_clearsTheErrorBeforeTheResponseArrives() async {
    let service = MockRecipeService()
    service.recipes.fails(with: AppError.unknown)
    let sut = HomeViewModel(recipeService: service)
    await sut.loadContent()

    let observed = StateBox()
    service.recipes.responds { _ in
      observed.record(sut.latestRecipes)

      return RecipeListPage(
        recipes: [.dummy()],
        meta: .dummy()
      )
    }
    await sut.loadLatestRecipes()

    #expect(observed.value == .loading)
  }

  @Test
  func loadContent_whenAlreadyLoaded_keepsTheContentVisibleWhileRefreshing() async {
    let service = MockRecipeService()
    let sut = HomeViewModel(recipeService: service)
    await sut.loadContent()

    let observed = StateBox()
    service.recipes.responds { _ in
      observed.record(sut.latestRecipes)

      return RecipeListPage(
        recipes: [.dummy()],
        meta: .dummy()
      )
    }
    await sut.loadContent()

    #expect(observed.value?.isLoaded == true)
  }

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
  func loadLatestRecipes_whenAlamofireReportsAnExplicitCancel_keepsTheSectionItAlreadyHad() async {
    let service = MockRecipeService()
    let sut = HomeViewModel(recipeService: service)
    await sut.loadContent()
    let loaded = sut.latestRecipes

    service.recipes.fails(with: AFError.explicitlyCancelled)
    await sut.loadLatestRecipes()

    #expect(sut.latestRecipes == loaded)
  }

  @Test
  func loadLatestRecipes_whenAlamofireWrapsACancelledURLError_keepsTheSectionItAlreadyHad() async {
    let service = MockRecipeService()
    let sut = HomeViewModel(recipeService: service)
    await sut.loadContent()
    let loaded = sut.latestRecipes

    service.recipes.fails(with: AFError.sessionTaskFailed(error: URLError(.cancelled)))
    await sut.loadLatestRecipes()

    #expect(sut.latestRecipes == loaded)
  }

  @Test
  func loadLatestRecipes_whenARetryFromFailedIsCancelled_leavesTheSectionRetryable() async {
    let service = MockRecipeService()
    service.recipes.fails(with: AppError.unknown)
    let sut = HomeViewModel(recipeService: service)
    await sut.loadContent()

    service.recipes.fails(with: URLError(.cancelled))
    await sut.loadLatestRecipes()

    #expect(sut.latestRecipes == .failed(nil))
  }

  @Test
  func loadCategories_whenARetryFromFailedIsCancelled_leavesTheSectionRetryable() async {
    let service = MockRecipeService()
    service.categories.fails(with: AppError.unknown)
    let sut = HomeViewModel(recipeService: service)
    await sut.loadContent()

    service.categories.fails(with: URLError(.cancelled))
    await sut.loadCategories()

    #expect(sut.categories == .failed(nil))
  }

  @Test
  func loadLatestRecipes_whenASlowFailureLandsAfterAFasterSuccess_keepsTheFreshContent() async {
    let service = MockRecipeService()
    let sut = HomeViewModel(recipeService: service)

    let slowStarted = AsyncSignal()
    let slowMayFinish = AsyncSignal()
    service.recipes.responds { _ in
      slowStarted.signal()
      await slowMayFinish.wait()

      throw AppError.unknown
    }
    let slow = Task { await sut.loadLatestRecipes() }
    await slowStarted.wait()

    service.recipes.returns(RecipeListPage(
      recipes: [.dummy(id: "fresh")],
      meta: .dummy()
    ))
    await sut.loadLatestRecipes()
    slowMayFinish.signal()
    await slow.value

    #expect(sut.latestRecipes.value?.map(\.id) == ["fresh"])
  }

  @Test
  func loadCategories_whenASlowSuccessLandsAfterANewerOne_keepsTheNewerResult() async {
    let service = MockRecipeService()
    let sut = HomeViewModel(recipeService: service)

    let slowStarted = AsyncSignal()
    let slowMayFinish = AsyncSignal()
    service.categories.responds { _ in
      slowStarted.signal()
      await slowMayFinish.wait()

      return [.dummy(id: "stale")]
    }
    let slow = Task { await sut.loadCategories() }
    await slowStarted.wait()

    service.categories.returns([.dummy(id: "newer")])
    await sut.loadCategories()
    slowMayFinish.signal()
    await slow.value

    #expect(sut.categories.value?.map(\.id) == ["newer"])
  }

  @Test
  func loadCategories_whenARefreshOfAnEmptySectionIsCancelled_staysEmpty() async {
    let service = MockRecipeService()
    service.categories.returns([])
    let sut = HomeViewModel(recipeService: service)
    await sut.loadCategories()

    service.categories.fails(with: CancellationError())
    await sut.loadCategories()

    #expect(sut.categories == .empty)
  }

  @Test
  func loadCategories_whenTheErrorOnlyRepeatsTheGenericHeading_carriesNoDetail() async {
    let service = MockRecipeService()
    service.categories.fails(with: AppError.unknown)
    let sut = HomeViewModel(recipeService: service)

    await sut.loadCategories()

    #expect(sut.categories == .failed(nil))
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

/// A reference, not a captured `var`: the stub closure escapes and runs off the test's isolation.
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

/// Pins the interleaving an overlapping-load test needs, instead of racing on sleeps.
private final class AsyncSignal: @unchecked Sendable {
  private let lock = NSLock()
  private var isSignalled = false
  private var waiters: [CheckedContinuation<Void, Never>] = []

  func signal() {
    let resumed: [CheckedContinuation<Void, Never>] = lock.withLock {
      isSignalled = true
      defer { waiters = [] }

      return waiters
    }

    resumed.forEach { $0.resume() }
  }

  func wait() async {
    await withCheckedContinuation { continuation in
      let alreadySignalled: Bool = lock.withLock {
        guard isSignalled else {
          waiters.append(continuation)

          return false
        }

        return true
      }

      if alreadySignalled {
        continuation.resume()
      }
    }
  }
}
