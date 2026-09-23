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

  /// A plain `Error` has no `errorDescription`; must not render as an empty message.
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

  /// A torn-down `.task` throws; that isn't a real failure and must stay retryable.
  @Test
  func loadFirstPage_whenCancelled_reportsNoErrorAndStaysRetryable() async {
    let service = MockRecipeService()
    service.recipes.fails(with: CancellationError())
    let sut = makeSUT(service: service)

    await sut.loadFirstPage()

    #expect(sut.loadState == .idle)
    #expect(sut.recipes.isEmpty)
  }

  /// `.task` re-fires on reappearance; refetching would reset the user's scroll position.
  @Test
  func loadFirstPage_calledTwice_onlyFetchesOnce() async {
    let service = MockRecipeService()
    let sut = makeSUT(service: service)

    await sut.loadFirstPage()
    await sut.loadFirstPage()

    #expect(service.recipes.callCount == 1)
  }

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

  @Test
  func loadNextPage_appendsAfterTheExistingRows() async {
    let service = MockRecipeService()
    service.recipes.responds { page in
      page.index == 1
        ? .dummy(ids: ["rcp-001", "rcp-002"], total: 4, perPage: 2, currentPage: 1, lastPage: 2)
        : .dummy(ids: ["rcp-003", "rcp-004"], total: 4, perPage: 2, currentPage: 2, lastPage: 2)
    }
    let sut = makeSUT(service: service, pageSize: 2)

    await sut.loadFirstPage()
    await sut.loadNextPage()

    #expect(sut.recipes.map(\.id) == ["rcp-001", "rcp-002", "rcp-003", "rcp-004"])
    #expect(service.recipes.requests.map(\.index) == [1, 2])
  }

  @Test
  func loadNextPage_onTheLastPage_doesNotAsk() async {
    let service = MockRecipeService(page: .dummy(ids: ["rcp-001"], total: 1, perPage: 10, currentPage: 1, lastPage: 1))
    let sut = makeSUT(service: service)

    await sut.loadFirstPage()
    await sut.loadNextPage()

    #expect(sut.hasLoadedAllData)
    #expect(service.recipes.callCount == 1)
  }

  /// A short page isn't necessarily the last one; only the pagination meta says so.
  @Test
  func loadNextPage_afterAShortPageThatIsNotTheLast_keepsGoing() async {
    let service = MockRecipeService(
      page: .dummy(
        ids: ["rcp-001", "rcp-002", "rcp-003", "rcp-004", "rcp-005", "rcp-006", "rcp-007"],
        total: 30,
        perPage: 10,
        currentPage: 1,
        lastPage: 3
      )
    )
    let sut = makeSUT(service: service)

    await sut.loadFirstPage()

    #expect(sut.hasLoadedAllData == false)

    await sut.loadNextPage()

    #expect(service.recipes.requests.map(\.index) == [1, 2])
  }

  @Test
  func loadNextPage_whenItFails_keepsTheRowsAndReportsInTheFooter() async {
    let service = MockRecipeService()
    service.recipes.responds { page in
      guard page.index == 1 else { throw AppError.noInternetConnection }

      return .dummy(ids: ["rcp-001"], total: 4, perPage: 1, currentPage: 1, lastPage: 4)
    }
    let sut = makeSUT(service: service, pageSize: 1)

    await sut.loadFirstPage()
    await sut.loadNextPage()

    #expect(sut.recipes.map(\.id) == ["rcp-001"])
    #expect(sut.loadState == .loaded)
    #expect(sut.nextPageError == AppError.noInternetConnection.localizedDescription)
    #expect(sut.isLoadingNextPage == false)
  }

  @Test
  func loadNextPage_afterAFailure_canRetryAndClearsTheFooterError() async {
    let service = MockRecipeService()
    service.recipes.responds { page in
      guard page.index == 1 else { throw AppError.noInternetConnection }

      return .dummy(ids: ["rcp-001"], total: 2, perPage: 1, currentPage: 1, lastPage: 2)
    }
    let sut = makeSUT(service: service, pageSize: 1)

    await sut.loadFirstPage()
    await sut.loadNextPage()

    service.recipes.returns(.dummy(ids: ["rcp-002"], total: 2, perPage: 1, currentPage: 2, lastPage: 2))
    await sut.loadNextPage()

    #expect(sut.recipes.map(\.id) == ["rcp-001", "rcp-002"])
    #expect(sut.nextPageError == nil)
  }

  /// Duplicate ids break `ForEach` identity; a real backend can repeat one across pages.
  @Test
  func loadNextPage_withARepeatedId_keepsOnlyTheFirst() async {
    let service = MockRecipeService()
    service.recipes.responds { page in
      page.index == 1
        ? .dummy(ids: ["rcp-001", "rcp-002"], total: 4, perPage: 2, currentPage: 1, lastPage: 2)
        : .dummy(ids: ["rcp-002", "rcp-003"], total: 4, perPage: 2, currentPage: 2, lastPage: 2)
    }
    let sut = makeSUT(service: service, pageSize: 2)

    await sut.loadFirstPage()
    await sut.loadNextPage()

    #expect(sut.recipes.map(\.id) == ["rcp-001", "rcp-002", "rcp-003"])
  }

  @Test
  func loadNextPage_beforeTheFirstPageLoaded_doesNothing() async {
    let service = MockRecipeService()
    let sut = makeSUT(service: service)

    await sut.loadNextPage()

    #expect(service.recipes.wasCalled == false)
  }

  /// `select(layout:)` is view-only; touching paging state here could double-request or wedge the spinner.
  @Test
  func select_doesNotDisturbPaging() async {
    let service = MockRecipeService(page: .dummy(ids: ["rcp-001"], total: 4, perPage: 1, currentPage: 1, lastPage: 4))
    let sut = makeSUT(service: service, pageSize: 1)

    await sut.loadFirstPage()
    sut.select(layout: .grid)

    #expect(sut.layout == .grid)
    #expect(sut.isLoadingNextPage == false)
    #expect(sut.hasLoadedAllData == false)

    service.recipes.returns(.dummy(ids: ["rcp-002"], total: 4, perPage: 1, currentPage: 2, lastPage: 4))
    await sut.loadNextPage()

    #expect(service.recipes.requests.map(\.index) == [1, 2])
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
