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
  func loadFirstPage_succeeds_mapsEveryRecipeToACard() async {
    let service = MockRecipeService(recipes: RecipeListPageFactory.page(ids: [
      "rcp-001",
      "rcp-002",
    ]))
    let sut = RecipeListViewModelFactory.make(service: service)

    await sut.loadFirstPage()

    #expect(sut.recipes.value?.map(\.id) == ["rcp-001", "rcp-002"])
  }

  @Test
  func loadFirstPage_asksForTwentyRowsOfTheRequestsOwnQuery() async {
    let service = MockRecipeService()
    let sut = RecipeListViewModelFactory.make(
      request: .category(.dummy(name: "Desserts")),
      service: service
    )

    await sut.loadFirstPage()

    #expect(service.recipes.lastRequest?.query.category == "Desserts")
    #expect(service.recipes.lastRequest?.page == Page(
      index: 1,
      size: 20
    ))
  }

  @Test
  func loadFirstPage_noRows_isEmptyRatherThanLoadedWithNothing() async {
    let service = MockRecipeService(recipes: RecipeListPageFactory.page(ids: []))
    let sut = RecipeListViewModelFactory.make(service: service)

    await sut.loadFirstPage()

    #expect(sut.recipes == .empty)
  }

  @Test
  func loadFirstPage_fails_reportsTheFailure() async {
    let service = MockRecipeService()
    service.recipes.fails(with: AppError.unknown)
    let sut = RecipeListViewModelFactory.make(service: service)

    await sut.loadFirstPage()

    #expect(sut.recipes.isLoaded == false)
  }

  @Test
  func loadFirstPage_cancelled_keepsThePreviousState() async {
    let service = MockRecipeService(recipes: RecipeListPageFactory.page(ids: ["rcp-001"]))
    let sut = RecipeListViewModelFactory.make(service: service)
    await sut.loadFirstPage()
    let loaded = sut.recipes
    service.recipes.fails(with: CancellationError())

    await sut.loadFirstPage()

    #expect(sut.recipes == loaded)
  }

  @Test
  func resultCountText_followsTheServersTotalAndNotTheRowsLoaded() async {
    let service = MockRecipeService(recipes: RecipeListPageFactory.page(
      ids: ["rcp-001"],
      total: 36,
      lastPage: 2
    ))
    let sut = RecipeListViewModelFactory.make(service: service)

    await sut.loadFirstPage()

    #expect(sut.resultCountText == "36 recipes")
  }

  @Test
  func resultCountText_oneResult_isSingular() async {
    let service = MockRecipeService(recipes: RecipeListPageFactory.page(
      ids: ["rcp-001"],
      total: 1
    ))
    let sut = RecipeListViewModelFactory.make(service: service)

    await sut.loadFirstPage()

    #expect(sut.resultCountText == "1 recipe")
  }

  @Test
  func resultCountText_beforeAnythingLoads_isNil() {
    #expect(RecipeListViewModelFactory.make().resultCountText == nil)
  }

  @Test
  func resultCountText_afterAFailure_isNil() async {
    let service = MockRecipeService()
    service.recipes.fails(with: AppError.unknown)
    let sut = RecipeListViewModelFactory.make(service: service)

    await sut.loadFirstPage()

    #expect(sut.resultCountText == nil)
  }

  @Test
  func title_aCategory_isTheCategorysOwnName() {
    let sut = RecipeListViewModelFactory.make(request: .category(.dummy(name: "Desserts")))

    #expect(sut.title == "Desserts")
  }

  @Test
  func title_aSearch_readsSearchResults() {
    let sut = RecipeListViewModelFactory.make(request: .search("adobo"))

    #expect(sut.title == "Search results")
  }

  @Test
  func title_everything_readsAllRecipes() {
    #expect(RecipeListViewModelFactory.make(request: .all()).title == "All recipes")
  }

  @Test
  func searchPlaceholder_scopesItselfToWhatTheListIsOf() {
    let category = RecipeListViewModelFactory.make(request: .category(.dummy(name: "Desserts")))
    let search = RecipeListViewModelFactory.make(request: .search("pho"))
    let all = RecipeListViewModelFactory.make(request: .all())

    #expect(category.searchPlaceholder == "Search Desserts")
    #expect(search.searchPlaceholder == "“pho”")
    #expect(all.searchPlaceholder == "Search recipes or ingredients")
  }

  @Test
  func viewMode_startsOnTheGridAndFollowsTheToggle() {
    let sut = RecipeListViewModelFactory.make()

    #expect(sut.viewMode == .grid)

    sut.select(viewMode: .list)

    #expect(sut.viewMode == .list)
  }
}

// MARK: - Paging

@MainActor
struct RecipeListViewModelPagingTests {
  @Test
  func loadFirstPage_oneFullResultSet_neverAsksForASecondPage() async {
    let service = MockRecipeService(recipes: RecipeListPageFactory.page(
      ids: ["rcp-001"],
      total: 6,
      lastPage: 1
    ))
    let sut = RecipeListViewModelFactory.make(service: service)
    await sut.loadFirstPage()

    await sut.loadNextPageIfNeeded(after: "rcp-001")

    #expect(service.recipes.callCount == 1)
  }

  @Test
  func loadNextPageIfNeeded_atTheTail_appendsTheNextPage() async {
    let service = RecipeListPageFactory.twoPageService()
    let sut = RecipeListViewModelFactory.make(service: service)
    await sut.loadFirstPage()

    await sut.loadNextPageIfNeeded(after: "rcp-001")

    #expect(sut.recipes.value?.map(\.id) == ["rcp-001", "rcp-002"])
  }

  @Test
  func loadNextPageIfNeeded_notAtTheTail_makesNoRequest() async {
    let service = RecipeListPageFactory.twoPageService(firstPageIDs: [
      "rcp-001",
      "rcp-009",
    ])
    let sut = RecipeListViewModelFactory.make(service: service)
    await sut.loadFirstPage()

    await sut.loadNextPageIfNeeded(after: "rcp-001")

    #expect(service.recipes.callCount == 1)
  }

  @Test
  func loadNextPageIfNeeded_aPageRepeatingARowAlreadyHeld_doesNotDuplicateIt() async {
    let service = RecipeListPageFactory.twoPageService(secondPageIDs: [
      "rcp-001",
      "rcp-002",
    ])
    let sut = RecipeListViewModelFactory.make(service: service)
    await sut.loadFirstPage()

    await sut.loadNextPageIfNeeded(after: "rcp-001")

    #expect(sut.recipes.value?.map(\.id) == ["rcp-001", "rcp-002"])
  }

  @Test
  func loadNextPageIfNeeded_whileAPageIsInFlight_makesNoSecondRequest() async {
    let service = RecipeListPageFactory.twoPageService()
    let sut = RecipeListViewModelFactory.make(service: service)
    await sut.loadFirstPage()
    let reentry = Reentry()

    service.recipes.responds { request in
      if request.page.index == 2, await reentry.isFirstTime() {
        await sut.loadNextPageIfNeeded(after: "rcp-001")
      }

      return RecipeListPageFactory.page(
        ids: ["rcp-002"],
        total: 40,
        currentPage: 2,
        lastPage: 2
      )
    }

    await sut.loadNextPageIfNeeded(after: "rcp-001")

    #expect(service.recipes.requests.filter { $0.page.index == 2 }.count == 1)
  }

  @Test
  func loadNextPageIfNeeded_fails_keepsTheRowsAndReportsTheFailure() async {
    let service = RecipeListPageFactory.twoPageService()
    let sut = RecipeListViewModelFactory.make(service: service)
    await sut.loadFirstPage()
    service.recipes.fails(with: AppError.noInternetConnection)

    await sut.loadNextPageIfNeeded(after: "rcp-001")

    #expect(sut.recipes.value?.map(\.id) == ["rcp-001"])
    #expect(sut.nextPageError != nil)
    #expect(sut.isLoadingNextPage == false)
  }

  @Test
  func loadNextPageIfNeeded_afterAFailure_doesNotRetryByItself() async {
    let service = RecipeListPageFactory.twoPageService()
    let sut = RecipeListViewModelFactory.make(service: service)
    await sut.loadFirstPage()
    service.recipes.fails(with: AppError.noInternetConnection)
    await sut.loadNextPageIfNeeded(after: "rcp-001")
    let callsAfterTheFailure = service.recipes.callCount

    await sut.loadNextPageIfNeeded(after: "rcp-001")

    #expect(service.recipes.callCount == callsAfterTheFailure)
  }

  @Test
  func retryNextPage_asksForTheSamePageAgainAndClearsTheError() async {
    let service = RecipeListPageFactory.twoPageService()
    let sut = RecipeListViewModelFactory.make(service: service)
    await sut.loadFirstPage()
    service.recipes.fails(with: AppError.noInternetConnection)
    await sut.loadNextPageIfNeeded(after: "rcp-001")
    service.recipes.returns(RecipeListPageFactory.page(
      ids: ["rcp-002"],
      total: 40,
      currentPage: 2,
      lastPage: 2
    ))

    await sut.retryNextPage()

    #expect(service.recipes.lastRequest?.page.index == 2)
    #expect(sut.nextPageError == nil)
    #expect(sut.recipes.value?.map(\.id) == ["rcp-001", "rcp-002"])
  }

  @Test
  func loadNextPageIfNeeded_cancelled_leavesNoErrorAndNoSpinner() async {
    let service = RecipeListPageFactory.twoPageService()
    let sut = RecipeListViewModelFactory.make(service: service)
    await sut.loadFirstPage()
    service.recipes.fails(with: CancellationError())

    await sut.loadNextPageIfNeeded(after: "rcp-001")

    #expect(sut.nextPageError == nil)
    #expect(sut.isLoadingNextPage == false)
    #expect(sut.recipes.value?.map(\.id) == ["rcp-001"])
  }

  @Test
  func loadNextPageIfNeeded_theLastPage_stopsThePager() async {
    let service = RecipeListPageFactory.twoPageService()
    let sut = RecipeListViewModelFactory.make(service: service)
    await sut.loadFirstPage()
    await sut.loadNextPageIfNeeded(after: "rcp-001")
    let callsAfterPageTwo = service.recipes.callCount

    await sut.loadNextPageIfNeeded(after: "rcp-002")

    #expect(service.recipes.callCount == callsAfterPageTwo)
  }
}

// MARK: - Facets

@MainActor
struct RecipeListViewModelFacetTests {
  @Test
  func facetChips_areDerivedFromTheRequestsQuery() {
    let sut = RecipeListViewModelFactory.make(request: .all(query: RecipeQuery(
      isVegetarian: true,
      servings: .four
    )))

    #expect(sut.facetChips.map(\.label) == ["Vegetarian", "4 servings"])
  }

  @Test
  func facetChips_aCategoryOnlyRequest_hasNone() {
    let sut = RecipeListViewModelFactory.make(request: .category(.dummy(name: "Desserts")))

    #expect(sut.facetChips.isEmpty)
  }

  @Test
  func showsClearAllChips_onlyOnceMoreThanOneFacetIsSet() {
    let one = RecipeListViewModelFactory.make(request: .all(query: RecipeQuery(isVegetarian: true)))
    let several = RecipeListViewModelFactory.make(request: .all(query: RecipeQuery(
      isVegetarian: true,
      servings: .two
    )))

    #expect(one.showsClearAllChips == false)
    #expect(several.showsClearAllChips)
  }

  @Test
  func remove_reloadsFromPageOneWithoutThatFacet() async {
    let service = MockRecipeService()
    let sut = RecipeListViewModelFactory.make(
      request: .all(query: RecipeQuery(
        isVegetarian: true,
        servings: .two
      )),
      service: service
    )
    await sut.loadFirstPage()

    await sut.remove(facet: .vegetarian(true))

    #expect(service.recipes.lastRequest?.query.isVegetarian == nil)
    #expect(service.recipes.lastRequest?.query.servings == .two)
    #expect(service.recipes.lastRequest?.page.index == 1)
    #expect(sut.facetChips.map(\.label) == ["2 servings"])
  }

  @Test
  func clearFacets_dropsThemAllAndKeepsTheCategory() async {
    let service = MockRecipeService()
    let sut = RecipeListViewModelFactory.make(
      request: .all(query: RecipeQuery(
        category: "Vegan",
        isVegetarian: true,
        servings: .two
      )),
      service: service
    )
    await sut.loadFirstPage()

    await sut.clearFacets()

    #expect(sut.facetChips.isEmpty)
    #expect(service.recipes.lastRequest?.query.category == "Vegan")
  }

  @Test
  func remove_whileAPageIsInFlight_discardsThatPage() async {
    let service = RecipeListPageFactory.twoPageService()
    let sut = RecipeListViewModelFactory.make(
      request: .all(query: RecipeQuery(isVegetarian: true)),
      service: service
    )
    await sut.loadFirstPage()

    async let paging: Void = sut.loadNextPageIfNeeded(after: "rcp-001")
    await sut.remove(facet: .vegetarian(true))
    await paging

    #expect(sut.recipes.value?.map(\.id) == ["rcp-001"])
  }

  @Test
  func emptyCopy_withFacetsSet_blamesTheFilters() {
    let sut = RecipeListViewModelFactory.make(request: .all(query: RecipeQuery(isVegetarian: true)))

    #expect(String(localized: sut.emptyTitle) == "No recipes match your filters")
    #expect(sut.emptyDetail != nil)
    #expect(sut.showsClearFiltersButton)
  }

  @Test
  func emptyCopy_withNoFacets_doesNotBlameAFilterNobodySet() {
    let sut = RecipeListViewModelFactory.make(request: .category(.dummy(name: "Desserts")))

    #expect(String(localized: sut.emptyTitle) == "No recipes here yet")
    #expect(sut.emptyDetail == nil)
    #expect(sut.showsClearFiltersButton == false)
  }
}

// MARK: - Helpers

/// Lets one stubbed response re-enter the view model exactly once, to prove the in-flight
/// guard holds without a sleep or a continuation.
actor Reentry {
  private var hasRun = false

  func isFirstTime() -> Bool {
    defer { hasRun = true }

    return !hasRun
  }
}

@MainActor
enum RecipeListViewModelFactory {
  static func make(
    request: RecipeListRequest = .all(),
    service: RecipeServiceProtocol = MockRecipeService()
  ) -> RecipeListViewModel {
    RecipeListViewModel(
      request: request,
      recipeService: service
    )
  }
}

enum RecipeListPageFactory {
  static func page(
    ids: [String],
    total: Int? = nil,
    currentPage: Int = 1,
    lastPage: Int = 1
  ) -> RecipeListPage {
    RecipeListPage(
      recipes: ids.map { .dummy(id: $0) },
      meta: .dummy(
        total: total ?? ids.count,
        perPage: 20,
        from: 1,
        to: ids.count,
        currentPage: currentPage,
        lastPage: lastPage
      )
    )
  }

  /// Two pages of one row each, so the tail row's id is predictable.
  static func twoPageService(
    firstPageIDs: [String] = ["rcp-001"],
    secondPageIDs: [String] = ["rcp-002"]
  ) -> MockRecipeService {
    let service = MockRecipeService()

    service.recipes.responds { request in
      request.page.index == 1
        ? page(
          ids: firstPageIDs,
          total: 40,
          currentPage: 1,
          lastPage: 2
        )
        : page(
          ids: secondPageIDs,
          total: 40,
          currentPage: 2,
          lastPage: 2
        )
    }

    return service
  }
}
