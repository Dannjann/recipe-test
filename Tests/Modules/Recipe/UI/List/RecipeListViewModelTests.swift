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

  // MARK: Paging trigger

  /// `loadedPageCount` is what the list footer keys its `.task(id:)` on. The three tests
  /// below pin the cases where a page lands without changing the row count — if the count
  /// stalls there, the footer never re-fires and paging is over for the session.

  @Test
  func loadFirstPage_startsThePageCountAtOne() async {
    let service = MockRecipeService(page: .dummy(ids: ["rcp-001"]))
    let sut = makeSUT(service: service)

    await sut.loadFirstPage()

    #expect(sut.loadedPageCount == 1)
  }

  @Test
  func loadNextPage_whenEveryRowIsADuplicate_stillAdvancesThePageCount() async {
    let service = MockRecipeService()
    service.recipes.responds { page in
      .dummy(
        ids: ["rcp-001", "rcp-002"],
        total: 6,
        perPage: 2,
        currentPage: page.index,
        lastPage: 3
      )
    }
    let sut = makeSUT(service: service, pageSize: 2)

    await sut.loadFirstPage()
    await sut.loadNextPage()

    #expect(sut.recipes.count == 2)
    #expect(sut.loadedPageCount == 2)
  }

  @Test
  func loadNextPage_whenThePageArrivesEmpty_stillAdvancesThePageCount() async {
    let service = MockRecipeService()
    service.recipes.responds { page in
      page.index == 1
        ? .dummy(ids: ["rcp-001", "rcp-002"], total: 6, perPage: 2, currentPage: 1, lastPage: 3)
        : .dummy(ids: [], total: 6, perPage: 2, currentPage: page.index, lastPage: 3)
    }
    let sut = makeSUT(service: service, pageSize: 2)

    await sut.loadFirstPage()
    await sut.loadNextPage()

    #expect(sut.recipes.count == 2)
    #expect(sut.hasLoadedAllData == false)
    #expect(sut.loadedPageCount == 2)
  }

  @Test
  func refresh_rewindsThePageCountToOne() async {
    let service = MockRecipeService()
    service.recipes.responds { page in
      .dummy(
        ids: ["rcp-00\(page.index)"],
        total: 6,
        perPage: 1,
        currentPage: page.index,
        lastPage: 3
      )
    }
    let sut = makeSUT(service: service, pageSize: 1)

    await sut.loadFirstPage()
    await sut.loadNextPage()

    #expect(sut.loadedPageCount == 2)

    await sut.refresh()

    #expect(sut.loadedPageCount == 1)
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

  @Test
  func refresh_replacesTheRowsRatherThanAppending() async {
    let service = MockRecipeService(page: .dummy(ids: ["rcp-001", "rcp-002"]))
    let sut = makeSUT(service: service)

    await sut.loadFirstPage()
    service.recipes.returns(.dummy(ids: ["rcp-009"]))
    await sut.refresh()

    #expect(sut.recipes.map(\.id) == ["rcp-009"])
  }

  @Test
  func refresh_startsAgainFromPageOne() async {
    let service = MockRecipeService()
    service.recipes.responds { page in
      .dummy(ids: ["rcp-00\(page.index)"], total: 9, perPage: 1, currentPage: page.index, lastPage: 9)
    }
    let sut = makeSUT(service: service, pageSize: 1)

    await sut.loadFirstPage()
    await sut.loadNextPage()
    await sut.refresh()
    await sut.loadNextPage()

    #expect(service.recipes.requests.map(\.index) == [1, 2, 1, 2])
  }

  /// Clearing the rows before the request would flash an empty list on every pull, and destroy content if it failed.
  @Test
  func refresh_whenItFails_keepsTheRowsAndTheLoadedState() async {
    let service = MockRecipeService(page: .dummy(ids: ["rcp-001"]))
    let sut = makeSUT(service: service)

    await sut.loadFirstPage()
    service.recipes.fails(with: AppError.noInternetConnection)
    await sut.refresh()

    #expect(sut.recipes.map(\.id) == ["rcp-001"])
    #expect(sut.loadState == .loaded)
  }

  /// Two page-one requests are outstanding; the refresh's must win even if the initial load's answers last.
  @Test(.timeLimit(.minutes(1)))
  func refresh_duringAnInFlightFirstLoad_winsRegardlessOfOrder() async {
    let service = MockRecipeService()
    let sut = makeSUT(service: service)

    let gate = CallGate()
    service.recipes.responds { _ in
      guard await gate.arrive() == 1 else { return .dummy(ids: ["fresh"]) }

      await gate.waitUntilOpen()

      return .dummy(ids: ["stale"])
    }

    async let firstLoad: Void = sut.loadFirstPage()
    await gate.waitForArrivals(1)

    await sut.refresh()
    await gate.open()
    await firstLoad

    #expect(sut.recipes.map(\.id) == ["fresh"])
  }

  /// A next page that returns after a refresh belongs to a list that no longer exists.
  @Test(.timeLimit(.minutes(1)))
  func refresh_discardsANextPageThatWasAlreadyInFlight() async {
    let service = MockRecipeService()
    let sut = makeSUT(service: service, pageSize: 1)

    service.recipes.returns(.dummy(ids: ["rcp-001"], total: 9, perPage: 1, currentPage: 1, lastPage: 9))
    await sut.loadFirstPage()

    let gate = CallGate()
    service.recipes.responds { _ in
      guard await gate.arrive() == 1 else {
        return .dummy(ids: ["rcp-999"], total: 9, perPage: 1, currentPage: 1, lastPage: 9)
      }

      await gate.waitUntilOpen()

      return .dummy(ids: ["late"], total: 9, perPage: 1, currentPage: 2, lastPage: 9)
    }

    async let nextPage: Void = sut.loadNextPage()
    await gate.waitForArrivals(1)

    await sut.refresh()
    await gate.open()
    await nextPage

    #expect(sut.recipes.map(\.id) == ["rcp-999"])
  }

  @Test(.timeLimit(.minutes(1)))
  func loadNextPage_startedDuringARefresh_isRefused() async {
    let service = MockRecipeService()
    let sut = makeSUT(service: service, pageSize: 1)

    service.recipes.returns(.dummy(ids: ["rcp-001"], total: 9, perPage: 1, currentPage: 1, lastPage: 9))
    await sut.loadFirstPage()

    let gate = CallGate()
    service.recipes.responds { _ in
      guard await gate.arrive() == 1 else {
        return .dummy(ids: ["late"], total: 9, perPage: 1, currentPage: 7, lastPage: 9)
      }

      await gate.waitUntilOpen()

      return .dummy(ids: ["rcp-999"], total: 9, perPage: 1, currentPage: 1, lastPage: 9)
    }

    async let refresh: Void = sut.refresh()
    await gate.waitForArrivals(1)

    await sut.loadNextPage()
    await gate.open()
    await refresh

    #expect(service.recipes.callCount == 2)
    #expect(sut.recipes.map(\.id) == ["rcp-999"])
  }

  /// Pins the `!isLoadingNextPage` guard: a footer flickering in and out of view must not fire overlapping requests for the same page.
  @Test(.timeLimit(.minutes(1)))
  func loadNextPage_whileOneIsAlreadyInFlight_doesNotDoubleRequest() async {
    let service = MockRecipeService()
    let sut = makeSUT(service: service, pageSize: 1)

    service.recipes.returns(.dummy(ids: ["rcp-001"], total: 9, perPage: 1, currentPage: 1, lastPage: 9))
    await sut.loadFirstPage()

    let gate = CallGate()
    service.recipes.responds { _ in
      _ = await gate.arrive()
      await gate.waitUntilOpen()

      return .dummy(ids: ["rcp-002"], total: 9, perPage: 1, currentPage: 2, lastPage: 9)
    }

    async let inFlight: Void = sut.loadNextPage()
    await gate.waitForArrivals(1)

    await sut.loadNextPage()
    await gate.open()
    await inFlight

    #expect(service.recipes.requests.map(\.index) == [1, 2])
  }

  @Test
  func refresh_whenItFails_doesNotRewindPagination() async {
    let service = MockRecipeService()
    service.recipes.responds { page in
      .dummy(ids: ["rcp-00\(page.index)"], total: 9, perPage: 1, currentPage: page.index, lastPage: 9)
    }
    let sut = makeSUT(service: service, pageSize: 1)

    await sut.loadFirstPage()
    await sut.loadNextPage()

    service.recipes.fails(with: AppError.noInternetConnection)
    await sut.refresh()

    service.recipes.responds { page in
      .dummy(ids: ["rcp-00\(page.index)"], total: 9, perPage: 1, currentPage: page.index, lastPage: 9)
    }
    await sut.loadNextPage()

    #expect(service.recipes.requests.map(\.index) == [1, 2, 1, 3])
  }

  @Test(.timeLimit(.minutes(1)))
  func loadNextPage_duringANestedRefresh_isRefused() async {
    let service = MockRecipeService()
    let sut = makeSUT(service: service, pageSize: 1)

    service.recipes.returns(.dummy(ids: ["rcp-001"], total: 9, perPage: 1, currentPage: 1, lastPage: 9))
    await sut.loadFirstPage()

    let gate = CallGate()
    service.recipes.responds { _ in
      guard await gate.arrive() == 1 else {
        return .dummy(ids: ["rcp-00B"], total: 9, perPage: 1, currentPage: 1, lastPage: 9)
      }

      await gate.waitUntilOpen()

      return .dummy(ids: ["rcp-00A"], total: 9, perPage: 1, currentPage: 1, lastPage: 9)
    }

    async let outerRefresh: Void = sut.refresh()
    await gate.waitForArrivals(1)

    async let innerRefresh: Void = sut.refresh()
    await innerRefresh

    await sut.loadNextPage()

    await gate.open()
    await outerRefresh

    #expect(service.recipes.requests.map(\.index) == [1, 1, 1])
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

// MARK: - Helpers > Ordering

/// Orders two concurrent calls to the same stub so an arrival order is guaranteed rather than hoped for.
private actor CallGate {
  private var arrivals = 0
  private var isOpen = false
  private var openWaiters: [CheckedContinuation<Void, Never>] = []
  private var arrivalWaiters: [CheckedContinuation<Void, Never>] = []

  func arrive() -> Int {
    arrivals += 1

    for continuation in arrivalWaiters {
      continuation.resume()
    }

    arrivalWaiters = []

    return arrivals
  }

  func waitUntilOpen() async {
    guard !isOpen else { return }

    await withCheckedContinuation { continuation in
      openWaiters.append(continuation)
    }
  }

  /// Blocks until `count` calls have provably entered the stub, so a stub can be swapped without racing the task's own start.
  func waitForArrivals(_ count: Int) async {
    while arrivals < count {
      await withCheckedContinuation { continuation in
        arrivalWaiters.append(continuation)
      }
    }
  }

  func open() {
    isOpen = true

    for continuation in openWaiters {
      continuation.resume()
    }

    openWaiters = []
  }
}
