//
//  RecipeServiceTests.swift
//  Tests
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation
@testable import RecipeTest
import Testing

struct RecipeServiceTests {
  @Test
  func getRecipes_translatesThePageIntoPageAndPerPage() async throws {
    let api = MockRecipeAPI()
    let sut = makeSUT(api: api)

    _ = try await sut.getRecipes(query: .empty, page: Page(index: 3, size: 20))

    #expect(api.recipes.callCount == 1)
    #expect(api.recipes.lastRequest == MockRecipeAPI.RecipesRequest(query: .empty, page: 3, perPage: 20))
  }

  @Test
  func getRecipes_mapsTheRowsIntoSummaries() async throws {
    let api = MockRecipeAPI(recipes: [.dummy(id: "rcp-001"), .dummy(id: "rcp-002")])
    let sut = makeSUT(api: api)

    let page = try await sut.getRecipes(query: .empty, page: Page(size: 10))

    #expect(page.recipes.map(\.id) == ["rcp-001", "rcp-002"])
    #expect(page.recipes.first?.title == "Spaghetti alla Carbonara")
  }

  /// One unusable row costs itself, not the nine good rows around it.
  @Test
  func getRecipes_dropsUnmappableRowsAndKeepsTheRest() async throws {
    let api = MockRecipeAPI(recipes: [.dummy(id: "rcp-001"), .dummy(id: nil), .dummy(id: "rcp-003")])
    let sut = makeSUT(api: api)

    let page = try await sut.getRecipes(query: .empty, page: Page(size: 10))

    #expect(page.recipes.map(\.id) == ["rcp-001", "rcp-003"])
  }

  @Test
  func getRecipes_carriesThePaginationMetaThrough() async throws {
    let api = MockRecipeAPI(meta: .dummy(total: 36, perPage: 5, currentPage: 2, lastPage: 8))
    let sut = makeSUT(api: api)

    let page = try await sut.getRecipes(query: .empty, page: Page(index: 2, size: 5))

    #expect(page.meta.currentPage == 2)
    #expect(page.meta.lastPage == 8)
    #expect(page.hasLoadedAllData == false)
  }

  /// A page past the end comes back empty with the page number that was asked for. A
  /// pager reading `hasLoadedAllData` must stop here rather than request page 100.
  @Test
  func getRecipes_pastTheLastPage_reportsEverythingLoaded() async throws {
    let api = MockRecipeAPI(
      recipes: [],
      meta: .dummy(total: 36, perPage: 5, from: nil, to: nil, currentPage: 99, lastPage: 8)
    )
    let sut = makeSUT(api: api)

    let page = try await sut.getRecipes(query: .empty, page: Page(index: 99, size: 5))

    #expect(page.recipes.isEmpty)
    #expect(page.hasLoadedAllData)
  }

  @Test
  func getRecipes_propagatesAnAPIError() async throws {
    let api = MockRecipeAPI()
    api.recipes.fails(with: AppError.noInternetConnection)
    let sut = makeSUT(api: api)

    await #expect(throws: AppError.self) {
      _ = try await sut.getRecipes(query: .empty, page: Page(size: 10))
    }
  }

  /// `responds` answers from the request, so page 2 differs from page 1 without a second
  /// mock or a lookup table.
  @Test
  func getRecipes_canBeStubbedPerPage() async throws {
    let api = MockRecipeAPI()
    api.recipes.responds { request in
      ([.dummy(id: "rcp-\(request.page)")], .dummy(currentPage: request.page))
    }
    let sut = makeSUT(api: api)

    let first = try await sut.getRecipes(query: .empty, page: Page(index: 1, size: 10))
    let second = try await sut.getRecipes(query: .empty, page: Page(index: 2, size: 10))

    #expect(first.recipes.first?.id == "rcp-1")
    #expect(second.recipes.first?.id == "rcp-2")
    #expect(api.recipes.requests.map(\.page) == [1, 2])
  }

  /// The filters are the whole point of the widened endpoint: a query that does not
  /// reach the API layer is a screen whose chips do nothing.
  @Test
  func getRecipes_forwardsTheQueryUntouched() async throws {
    let api = MockRecipeAPI()
    let sut = makeSUT(api: api)
    let query = RecipeQuery(
      searchText: "garlic",
      category: "Vegan",
      isVegetarian: true,
      servings: .sixOrMore,
      includeIngredients: ["garlic"],
      searchesSteps: true
    )

    _ = try await sut.getRecipes(query: query, page: Page(index: 1, size: 10))

    #expect(api.recipes.lastRequest?.query == query)
  }

  @Test
  func getCategories_mapsTheTiles() async throws {
    let api = MockRecipeAPI(categories: [.dummy(id: "cat-01", name: "Meal", recipeCount: 18)])
    let sut = makeSUT(api: api)

    let categories = try await sut.getCategories()

    #expect(categories.map(\.name) == ["Meal"])
    #expect(categories.first?.recipeCount == 18)
  }

  /// A malformed tile is one missing tile on the grid, not a failed home screen.
  @Test
  func getCategories_dropsUnmappableTilesAndKeepsTheRest() async throws {
    let api = MockRecipeAPI(categories: [.dummy(name: "Meal"), .dummy(id: nil), .dummy(name: "Rice")])
    let sut = makeSUT(api: api)

    let categories = try await sut.getCategories()

    #expect(categories.map(\.name) == ["Meal", "Rice"])
  }

  @Test
  func getCategories_propagatesAnAPIError() async throws {
    let api = MockRecipeAPI()
    api.categories.fails(with: AppError.noInternetConnection)
    let sut = makeSUT(api: api)

    await #expect(throws: AppError.self) {
      _ = try await sut.getCategories()
    }
  }

  @Test
  func getRecipe_sendsTheID() async throws {
    let api = MockRecipeAPI()
    let sut = makeSUT(api: api)

    _ = try await sut.getRecipe(id: "rcp-007")

    #expect(api.recipe.lastRequest == "rcp-007")
    #expect(api.recipe.callCount == 1)
  }

  @Test
  func getRecipe_mapsTheRecipe() async throws {
    let api = MockRecipeAPI(recipe: .dummy(id: "rcp-007", title: "Chicken Katsu Curry"))
    let sut = makeSUT(api: api)

    let recipe = try await sut.getRecipe(id: "rcp-007")

    #expect(recipe.id == "rcp-007")
    #expect(recipe.title == "Chicken Katsu Curry")
    #expect(recipe.steps.isEmpty == false)
  }

  /// A detail screen with no recipe has nothing to show, so there is no partial result to
  /// degrade to — unlike a list, where a bad row is simply dropped.
  ///
  /// Named rather than `AppError.unknown`: the caller can tell a backend contract break
  /// from every other unhandled failure, and the id it names is what makes the report
  /// actionable.
  @Test
  func getRecipe_withAnUnmappableRow_throwsAnUnmappableRecipeError() async throws {
    let api = MockRecipeAPI(recipe: .dummy(title: nil))
    let sut = makeSUT(api: api)

    await #expect(throws: RecipeServiceError.unmappableRecipe(id: "rcp-001")) {
      _ = try await sut.getRecipe(id: "rcp-001")
    }
  }

  /// The response decoded cleanly, so `APIClient.onError` never saw a failure. Without
  /// this report the break would show up as a failed screen and nothing else.
  @Test
  func getRecipe_withAnUnmappableRow_reportsTheError() async {
    let recorder = ErrorRecorder()
    let api = MockRecipeAPI(recipe: .dummy(title: nil))
    let sut = makeSUT(api: api, onError: recorder.record)

    _ = try? await sut.getRecipe(id: "rcp-001")

    #expect(recorder.count == 1)
    #expect(recorder.errors.first as? RecipeServiceError == .unmappableRecipe(id: "rcp-001"))
  }

  /// An error the API layer already reported is passed through untouched. Reporting it a
  /// second time here would double-count it in monitoring.
  @Test
  func getRecipe_withAnAPIError_doesNotReportItASecondTime() async {
    let recorder = ErrorRecorder()
    let api = MockRecipeAPI()
    api.recipe.fails(with: AppError.noInternetConnection)
    let sut = makeSUT(api: api, onError: recorder.record)

    _ = try? await sut.getRecipe(id: "rcp-001")

    #expect(recorder.count == 0)
  }

  @Test
  func getRecipe_propagatesAnAPIError() async throws {
    let api = MockRecipeAPI()
    api.recipe.fails(with: AppError.noInternetConnection)
    let sut = makeSUT(api: api)

    await #expect(throws: AppError.self) {
      _ = try await sut.getRecipe(id: "rcp-001")
    }
  }

  /// Stubs are per endpoint: a failing list must not take the detail call down with it.
  @Test
  func getRecipe_succeedsWhileTheListEndpointIsFailing() async throws {
    let api = MockRecipeAPI()
    api.recipes.fails(with: AppError.noInternetConnection)
    let sut = makeSUT(api: api)

    let recipe = try await sut.getRecipe(id: "rcp-001")

    #expect(recipe.id == "rcp-001")
    #expect(api.recipes.wasCalled == false)
  }
}

// MARK: - Helpers

private extension RecipeServiceTests {
  /// `onError` defaults to a sink: only the reporting test cares what the service
  /// raises on its own account, and the other twelve would carry an unused argument.
  func makeSUT(
    api: MockRecipeAPI,
    onError: @escaping SendableErrorResult = { _ in }
  ) -> RecipeService {
    RecipeService(api: api, onError: onError)
  }
}
