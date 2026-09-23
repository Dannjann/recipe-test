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
    let sut = RecipeService(api: api)

    _ = try await sut.getRecipes(page: Page(index: 3, size: 20))

    #expect(api.recipes.callCount == 1)
    #expect(api.recipes.lastRequest == MockRecipeAPI.RecipesRequest(page: 3, perPage: 20))
  }

  @Test
  func getRecipes_mapsTheRowsIntoSummaries() async throws {
    let api = MockRecipeAPI(recipes: [.dummy(id: "rcp-001"), .dummy(id: "rcp-002")])
    let sut = RecipeService(api: api)

    let page = try await sut.getRecipes(page: Page(size: 10))

    #expect(page.recipes.map(\.id) == ["rcp-001", "rcp-002"])
    #expect(page.recipes.first?.title == "Spaghetti alla Carbonara")
  }

  /// One unusable row costs itself, not the nine good rows around it.
  @Test
  func getRecipes_dropsUnmappableRowsAndKeepsTheRest() async throws {
    let api = MockRecipeAPI(recipes: [.dummy(id: "rcp-001"), .dummy(id: nil), .dummy(id: "rcp-003")])
    let sut = RecipeService(api: api)

    let page = try await sut.getRecipes(page: Page(size: 10))

    #expect(page.recipes.map(\.id) == ["rcp-001", "rcp-003"])
  }

  @Test
  func getRecipes_carriesThePaginationMetaThrough() async throws {
    let api = MockRecipeAPI(meta: .dummy(total: 36, perPage: 5, currentPage: 2, lastPage: 8))
    let sut = RecipeService(api: api)

    let page = try await sut.getRecipes(page: Page(index: 2, size: 5))

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
    let sut = RecipeService(api: api)

    let page = try await sut.getRecipes(page: Page(index: 99, size: 5))

    #expect(page.recipes.isEmpty)
    #expect(page.hasLoadedAllData)
  }

  @Test
  func getRecipes_propagatesAnAPIError() async throws {
    let api = MockRecipeAPI()
    api.recipes.fails(with: AppError.noInternetConnection)
    let sut = RecipeService(api: api)

    await #expect(throws: AppError.self) {
      _ = try await sut.getRecipes(page: Page(size: 10))
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
    let sut = RecipeService(api: api)

    let first = try await sut.getRecipes(page: Page(index: 1, size: 10))
    let second = try await sut.getRecipes(page: Page(index: 2, size: 10))

    #expect(first.recipes.first?.id == "rcp-1")
    #expect(second.recipes.first?.id == "rcp-2")
    #expect(api.recipes.requests.map(\.page) == [1, 2])
  }

  @Test
  func getRecipe_sendsTheID() async throws {
    let api = MockRecipeAPI()
    let sut = RecipeService(api: api)

    _ = try await sut.getRecipe(id: "rcp-007")

    #expect(api.recipe.lastRequest == "rcp-007")
    #expect(api.recipe.callCount == 1)
  }

  @Test
  func getRecipe_mapsTheRecipe() async throws {
    let api = MockRecipeAPI(recipe: .dummy(id: "rcp-007", title: "Chicken Katsu Curry"))
    let sut = RecipeService(api: api)

    let recipe = try await sut.getRecipe(id: "rcp-007")

    #expect(recipe.id == "rcp-007")
    #expect(recipe.title == "Chicken Katsu Curry")
    #expect(recipe.steps.isEmpty == false)
  }

  /// A detail screen with no recipe has nothing to show, so there is no partial result to
  /// degrade to — unlike a list, where a bad row is simply dropped.
  @Test
  func getRecipe_withAnUnmappableRow_throws() async throws {
    let api = MockRecipeAPI(recipe: .dummy(title: nil))
    let sut = RecipeService(api: api)

    await #expect(throws: AppError.self) {
      _ = try await sut.getRecipe(id: "rcp-001")
    }
  }

  @Test
  func getRecipe_propagatesAnAPIError() async throws {
    let api = MockRecipeAPI()
    api.recipe.fails(with: AppError.noInternetConnection)
    let sut = RecipeService(api: api)

    await #expect(throws: AppError.self) {
      _ = try await sut.getRecipe(id: "rcp-001")
    }
  }

  /// Stubs are per endpoint: a failing list must not take the detail call down with it.
  @Test
  func getRecipe_succeedsWhileTheListEndpointIsFailing() async throws {
    let api = MockRecipeAPI()
    api.recipes.fails(with: AppError.noInternetConnection)
    let sut = RecipeService(api: api)

    let recipe = try await sut.getRecipe(id: "rcp-001")

    #expect(recipe.id == "rcp-001")
    #expect(api.recipes.wasCalled == false)
  }
}
