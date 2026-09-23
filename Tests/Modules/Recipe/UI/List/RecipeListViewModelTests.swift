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

  /// Without this the pager asks for page 5, page 6, page 7... forever, because a real
  /// backend answers a page past the end with an empty slice rather than an error.
  @Test
  func loadNextPage_onTheLastPage_doesNotAsk() async {
    let service = MockRecipeService(page: .dummy(ids: ["rcp-001"], total: 1, perPage: 10, currentPage: 1, lastPage: 1))
    let sut = makeSUT(service: service)

    await sut.loadFirstPage()
    await sut.loadNextPage()

    #expect(sut.hasLoadedAllData)
    #expect(service.recipes.callCount == 1)
  }

  /// REVIEW FOCUS 4. Seven rows for a `perPage` of ten, but `currentPage` is still below
  /// `lastPage`. Inferring "done" from a short page stops here and silently hides the
  /// rest of the catalogue — only the meta gets to decide.
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

  /// A failed page three leaves the user's rows alone. Taking the screen away because the
  /// bottom edge failed would be a far worse trade than a retry button in the footer.
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

  /// A `ForEach` over duplicated `Identifiable` ids misbehaves visibly. The mock backend
  /// cannot produce one, but a real paginated backend whose underlying rows shift between
  /// requests absolutely can.
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

  /// REVIEW FOCUS 5. The toggle is a pure view concern. Touching paging state here either
  /// double-requests a page or wedges the footer's spinner on forever.
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
