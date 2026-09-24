//
//  RecipeDetailViewModelTests.swift
//  Tests
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation
@testable import RecipeTest
import Testing

@MainActor
struct RecipeDetailViewModelTests {
  @Test
  func loadDetail_succeeds_fetchesTheSummarysRecipe() async {
    let service = MockRecipeService(recipe: .dummy(id: "rcp-007"))
    let sut = RecipeDetailViewModel(
      summary: .dummy(id: "rcp-007"),
      recipeService: service
    )

    await sut.loadDetail()

    #expect(service.recipe.lastRequest == "rcp-007")
    #expect(sut.detail.value?.id == "rcp-007")
  }

  @Test
  func headerGetters_beforeTheDetailLands_readTheSummary() {
    let sut = RecipeDetailViewModel(
      summary: .dummy(
        title: "Pad Thai",
        totalTimeMinutes: 20,
        servings: 2,
        difficulty: .easy
      ),
      recipeService: MockRecipeService()
    )

    #expect(sut.title == "Pad Thai")
    #expect(sut.totalTimeMinutes == 20)
    #expect(sut.servings == 2)
    #expect(sut.difficulty == .easy)
  }

  @Test
  func headerGetters_afterTheDetailLands_readTheRecipe() async {
    let service = MockRecipeService(recipe: .dummy(
      title: "Pad Thai, revised",
      totalTimeMinutes: 35,
      servings: 6,
      difficulty: .hard
    ))
    let sut = RecipeDetailViewModel(
      summary: .dummy(
        title: "Pad Thai",
        totalTimeMinutes: 20,
        servings: 2,
        difficulty: .easy
      ),
      recipeService: service
    )

    await sut.loadDetail()

    #expect(sut.title == "Pad Thai, revised")
    #expect(sut.totalTimeMinutes == 35)
    #expect(sut.servings == 6)
    #expect(sut.difficulty == .hard)
  }

  @Test
  func loadDetail_fails_leavesTheHeaderOnTheSummary() async {
    let service = MockRecipeService()
    service.recipe.fails(with: AppError.unknown)
    let sut = RecipeDetailViewModel(
      summary: .dummy(title: "Pad Thai"),
      recipeService: service
    )

    await sut.loadDetail()

    #expect(sut.detail.isLoaded == false)
    #expect(sut.title == "Pad Thai")
  }

  @Test
  func loadDetail_cancelled_keepsThePreviousState() async {
    let service = MockRecipeService()
    let sut = RecipeDetailViewModel(
      summary: .dummy(),
      recipeService: service
    )
    await sut.loadDetail()
    let loaded = sut.detail
    service.recipe.fails(with: CancellationError())

    await sut.loadDetail()

    #expect(sut.detail == loaded)
  }

  @Test
  func loadDetail_cancelledFromAFailedSection_staysFailed() async {
    let service = MockRecipeService()
    service.recipe.fails(with: AppError.unknown)
    let sut = RecipeDetailViewModel(
      summary: .dummy(),
      recipeService: service
    )
    await sut.loadDetail()
    let failed = sut.detail
    service.recipe.fails(with: CancellationError())

    await sut.loadDetail()

    #expect(sut.detail == failed)
    #expect(sut.detail.isLoaded == false)
  }

  @Test
  func loadDetail_retryingAfterAFailure_clearsTheErrorBeforeTheResponse() async {
    let service = MockRecipeService()
    service.recipe.fails(with: AppError.unknown)
    let sut = RecipeDetailViewModel(
      summary: .dummy(),
      recipeService: service
    )
    await sut.loadDetail()
    let gate = Gate()
    service.recipe.responds { _ in
      await gate.wait()

      return .dummy()
    }

    async let retry: Void = sut.loadDetail()
    await Task.yield()
    let midFlight = sut.detail
    gate.open()
    await retry

    #expect(midFlight == .loading)
    #expect(sut.detail.isLoaded)
  }

  @Test
  func loadDetail_supersededByASecondLoad_keepsOnlyTheSecondResult() async {
    let counter = CallCounter()
    let gate = Gate()
    let service = MockRecipeService()
    service.recipe.responds { _ in
      guard counter.next() > 1 else {
        await gate.wait()

        return .dummy(id: "stale")
      }

      return .dummy(id: "fresh")
    }
    let sut = RecipeDetailViewModel(
      summary: .dummy(),
      recipeService: service
    )

    async let first: Void = sut.loadDetail()
    await Task.yield()
    async let second: Void = sut.loadDetail()
    await Task.yield()
    gate.open()
    _ = await (first, second)

    #expect(sut.detail.value?.id == "fresh")
  }

  @Test
  func galleryURLs_beforeTheDetailLands_isTheSummarysPhotograph() {
    let hero = URL(string: "https://example.com/hero.jpg")
    let sut = RecipeDetailViewModel(
      summary: .dummy(heroImageURL: hero),
      recipeService: MockRecipeService()
    )

    #expect(sut.galleryURLs == [hero].compactMap(\.self))
  }

  @Test
  func galleryURLs_afterTheDetailLands_isTheRecipesGallery() async {
    let gallery = [
      URL(string: "https://example.com/1.jpg"),
      URL(string: "https://example.com/2.jpg"),
    ].compactMap(\.self)
    let service = MockRecipeService(recipe: .dummy(gallery: gallery))
    let sut = RecipeDetailViewModel(
      summary: .dummy(),
      recipeService: service
    )

    await sut.loadDetail()

    #expect(sut.galleryURLs == gallery)
  }

  @Test
  func galleryURLs_withNoPhotographsAnywhere_isEmpty() async {
    let service = MockRecipeService(recipe: .dummy(
      heroImageURL: nil,
      gallery: []
    ))
    let sut = RecipeDetailViewModel(
      summary: .dummy(heroImageURL: nil),
      recipeService: service
    )

    await sut.loadDetail()

    #expect(sut.galleryURLs.isEmpty)
  }

  @Test
  func toggleIngredient_addsThenRemovesTheID() {
    let sut = RecipeDetailViewModel(
      summary: .dummy(),
      recipeService: MockRecipeService()
    )

    sut.toggleIngredient(id: "rcp-001-0")
    let afterFirst = sut.checkedIngredientIDs
    sut.toggleIngredient(id: "rcp-001-0")

    #expect(afterFirst == ["rcp-001-0"])
    #expect(sut.checkedIngredientIDs.isEmpty)
  }

  @Test
  func toggleIngredient_leavesTheOtherIngredientsUntouched() {
    let sut = RecipeDetailViewModel(
      summary: .dummy(),
      recipeService: MockRecipeService()
    )

    sut.toggleIngredient(id: "rcp-001-0")
    sut.toggleIngredient(id: "rcp-001-1")
    sut.toggleIngredient(id: "rcp-001-0")

    #expect(sut.checkedIngredientIDs == ["rcp-001-1"])
  }

  @Test
  func checkedIngredients_surviveAReFetch() async {
    let service = MockRecipeService(recipe: .dummy())
    let sut = RecipeDetailViewModel(
      summary: .dummy(),
      recipeService: service
    )
    await sut.loadDetail()
    sut.toggleIngredient(id: "rcp-001-2")

    await sut.loadDetail()

    #expect(sut.checkedIngredientIDs == ["rcp-001-2"])
    #expect(sut.detail.value?.ingredients.contains { $0.id == "rcp-001-2" } == true)
  }
}

// MARK: - Support

/// `responds` takes a `@Sendable` closure, so a plain captured `var` will not compile.
private final class CallCounter: @unchecked Sendable {
  private let lock = NSLock()
  private var value = 0

  func next() -> Int {
    lock.withLock {
      value += 1

      return value
    }
  }
}

/// Holds a stubbed response open until the test lets it go, so ordering is decided by the
/// test rather than by how long a sleep happens to take on the machine running it.
private final class Gate: @unchecked Sendable {
  private let lock = NSLock()
  private var continuation: CheckedContinuation<Void, Never>?
  private var isOpen = false

  func wait() async {
    await withCheckedContinuation { continuation in
      lock.lock()

      guard !isOpen else {
        lock.unlock()

        return continuation.resume()
      }

      self.continuation = continuation
      lock.unlock()
    }
  }

  func open() {
    lock.lock()
    isOpen = true
    let waiting = continuation
    continuation = nil
    lock.unlock()

    waiting?.resume()
  }
}
