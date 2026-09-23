//
//  RecipeListViewModelTests.swift
//  Tests
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation
@testable import RecipeTest
import Testing

@MainActor
struct RecipeListViewModelTests {
  @Test
  func loadFirstPage_populatesTheRowsAndLoads() async {
    let service = MockRecipeService(page: .dummy(ids: ["rcp-001", "rcp-002"]))
    let sut = makeSUT(service: service)

    await sut.loadFirstPage()

    #expect(sut.recipes.map(\.id) == ["rcp-001", "rcp-002"])
    #expect(sut.loadState == .loaded)
  }

  @Test
  func loadFirstPage_asksForPageOneAtTheConfiguredSize() async {
    let service = MockRecipeService()
    let sut = makeSUT(service: service, pageSize: 25)

    await sut.loadFirstPage()

    #expect(service.recipes.lastRequest == Page(index: 1, size: 25))
  }

  /// No rows is a legitimate answer, not a failure. It has to land on `.loaded` so the
  /// screen shows the empty state rather than an error with a Retry button.
  @Test
  func loadFirstPage_withNoRows_isLoadedAndEmpty() async {
    let service = MockRecipeService(page: .dummy(ids: []))
    let sut = makeSUT(service: service)

    await sut.loadFirstPage()

    #expect(sut.recipes.isEmpty)
    #expect(sut.loadState == .loaded)
  }

  @Test
  func loadFirstPage_whenTheServiceThrows_failsWithAMessage() async {
    let service = MockRecipeService()
    service.recipes.fails(with: AppError.noInternetConnection)
    let sut = makeSUT(service: service)

    await sut.loadFirstPage()

    #expect(sut.recipes.isEmpty)
    #expect(sut.loadState == .failed(AppError.noInternetConnection.localizedDescription))
  }

  /// REVIEW FOCUS 3. The service can propagate anything. A plain `Error` has no
  /// `errorDescription`, and a view model reading that directly would put an empty string
  /// on screen — an error state with no error in it.
  @Test
  func loadFirstPage_whenTheErrorIsNotLocalized_stillShowsSomething() async {
    struct Unhelpful: Error {}

    let service = MockRecipeService()
    service.recipes.fails(with: Unhelpful())
    let sut = makeSUT(service: service)

    await sut.loadFirstPage()

    guard case let .failed(message) = sut.loadState else {
      Issue.record("expected .failed, got \(sut.loadState)")
      return
    }

    #expect(!message.isEmpty)
  }

  /// REVIEW FOCUS 1. SwiftUI cancels a `.task` when the view disappears, so navigating
  /// away mid-load throws. Showing that as a server failure is wrong, and leaving
  /// `.failed` behind means coming back never retries — `.task` re-fires but
  /// `loadFirstPage` would see a state it treats as terminal.
  @Test
  func loadFirstPage_whenCancelled_reportsNoErrorAndStaysRetryable() async {
    let service = MockRecipeService()
    service.recipes.fails(with: CancellationError())
    let sut = makeSUT(service: service)

    await sut.loadFirstPage()

    #expect(sut.loadState == .idle)
    #expect(sut.recipes.isEmpty)
  }

  /// `.task` fires again every time the view reappears — returning from the detail push,
  /// for instance. A second call must not refetch, because that would also reset the
  /// user's scroll position to the top of a freshly replaced array.
  @Test
  func loadFirstPage_calledTwice_onlyFetchesOnce() async {
    let service = MockRecipeService()
    let sut = makeSUT(service: service)

    await sut.loadFirstPage()
    await sut.loadFirstPage()

    #expect(service.recipes.callCount == 1)
  }

  /// ...but a *failed* first load must stay retryable, which is what the error state's
  /// Retry button calls.
  @Test
  func loadFirstPage_afterAFailure_fetchesAgain() async {
    let service = MockRecipeService()
    service.recipes.fails(with: AppError.noInternetConnection)
    let sut = makeSUT(service: service)

    await sut.loadFirstPage()
    service.recipes.returns(.dummy(ids: ["rcp-001"]))
    await sut.loadFirstPage()

    #expect(service.recipes.callCount == 2)
    #expect(sut.recipes.map(\.id) == ["rcp-001"])
    #expect(sut.loadState == .loaded)
  }
}

// MARK: - Helpers

@MainActor
private extension RecipeListViewModelTests {
  func makeSUT(
    service: MockRecipeService,
    pageSize: Int = 10
  ) -> RecipeListViewModel {
    RecipeListViewModel(service: service, pageSize: pageSize)
  }
}
