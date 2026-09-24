//
//  APIClientRecipeTests.swift
//  Tests
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation
@testable import RecipeTest
import Testing

/// `.serialized` runs this suite's own tests one at a time, which is what stops each
/// `makeSUT` from overwriting `MockURLProtocol.router` while the previous test's request
/// is still in flight.
///
/// It does *not* stop another suite running alongside this one — the trait orders tests
/// within a suite, not across suites. What makes the process-global router safe today is
/// that this is the only suite that writes it. A second suite driving `.mocked()` cannot
/// be made safe by copying this trait: nest both suites inside one `.serialized` parent,
/// or they will race on the global.
@Suite(.serialized)
struct APIClientRecipeTests {
  @Test
  func getRecipes_returnsThePageAndItsMeta() async throws {
    let sut = makeSUT()

    let (recipes, meta) = try await sut.getRecipes(query: .empty, page: 1, perPage: 5)

    #expect(recipes.count == 5)
    #expect(recipes.first?.id == "rcp-001")
    #expect(meta.currentPage == 1)
    #expect(meta.perPage == 5)
    #expect(meta.total == 36)
    #expect(meta.hasLoadedAllData == false)
  }

  /// The production path decodes through `GenericAPIModel.decoder()`, not through
  /// `RemoteRecipeSummary.decoder()`. This is what proves the snake_case keys survive it.
  @Test
  func getRecipes_decodesSnakeCaseKeysThroughTheClient() async throws {
    let sut = makeSUT()

    let (recipes, _) = try await sut.getRecipes(query: .empty, page: 1, perPage: 1)
    let first = try #require(recipes.first)

    #expect(first.heroImageUrl?.hasPrefix("https://") == true)
    #expect(first.totalTimeMinutes == 25)
  }

  /// Proves `page` and `per_page` actually reach the query string — the router slices on
  /// them, so a wrong parameter name would come back as page 1 every time.
  @Test
  func getRecipes_sendsThePageParameters() async throws {
    let sut = makeSUT()

    let (recipes, meta) = try await sut.getRecipes(query: .empty, page: 2, perPage: 5)

    #expect(recipes.first?.id == "rcp-006")
    #expect(meta.currentPage == 2)
  }

  @Test
  func getRecipes_pastTheLastPage_returnsAnEmptyPage() async throws {
    let sut = makeSUT()

    let (recipes, meta) = try await sut.getRecipes(query: .empty, page: 99, perPage: 5)

    #expect(recipes.isEmpty)
    #expect(meta.hasLoadedAllData)
  }

  @Test
  func getRecipe_returnsTheFullRecipe() async throws {
    let sut = makeSUT()

    let recipe = try await sut.getRecipe(id: "rcp-001")

    #expect(recipe.id == "rcp-001")
    #expect(recipe.title == "Spaghetti alla Carbonara")
    #expect(recipe.steps?.isEmpty == false)
    #expect(recipe.ingredients?.isEmpty == false)
    #expect(recipe.gallery?.count == 3)
  }

  /// A `Bool` facet across the real encoder. `URLEncoding`'s default `boolEncoding` is
  /// `.numeric`, which sends `1`; a router comparing against `"true"` then reads it as
  /// false and returns the exact complement of what was asked for. Asserting the rows are
  /// vegetarian — rather than merely fewer — is what catches that.
  @Test
  func getRecipes_withABooleanFacet_filtersTheRightWay() async throws {
    let sut = makeSUT()

    let (vegetarian, _) = try await sut.getRecipes(
      query: RecipeQuery(isVegetarian: true),
      page: 1,
      perPage: 100
    )
    let (meat, _) = try await sut.getRecipes(
      query: RecipeQuery(isVegetarian: false),
      page: 1,
      perPage: 100
    )

    #expect(vegetarian.count == 12)
    #expect(meat.count == 24)
    #expect(vegetarian.allSatisfy { $0.isVegetarian == true })
    #expect(meat.allSatisfy { $0.isVegetarian == false })
  }

  /// An array facet across the real encoder. `URLEncoding`'s default `arrayEncoding` is
  /// `.brackets`, which sends `include_ingredients[]=…`; a router reading the bare name
  /// sees no filter at all and passes every row through.
  @Test
  func getRecipes_withAnArrayFacet_narrowsToRecipesContainingTheIngredient() async throws {
    let sut = makeSUT()

    let (all, _) = try await sut.getRecipes(query: .empty, page: 1, perPage: 100)
    let (withGarlic, _) = try await sut.getRecipes(
      query: RecipeQuery(includeIngredients: ["garlic"]),
      page: 1,
      perPage: 100
    )
    let (withoutGarlic, _) = try await sut.getRecipes(
      query: RecipeQuery(excludeIngredients: ["garlic"]),
      page: 1,
      perPage: 100
    )

    #expect(withGarlic.isEmpty == false)
    #expect(withGarlic.count < all.count)
    #expect(withGarlic.count + withoutGarlic.count == all.count)
  }

  /// The prototype's "search in steps" toggle, across the real encoder — another `Bool`,
  /// and the one whose failure looks like "no extra results" rather than a wrong answer.
  @Test
  func getRecipes_searchingSteps_findsMoreThanTitlesAlone() async throws {
    let sut = makeSUT()

    let (narrow, _) = try await sut.getRecipes(
      query: RecipeQuery(searchText: "simmer"),
      page: 1,
      perPage: 100
    )
    let (wide, _) = try await sut.getRecipes(
      query: RecipeQuery(searchText: "simmer", searchesSteps: true),
      page: 1,
      perPage: 100
    )

    #expect(wide.count > narrow.count)
  }

  /// The filters travel as query parameters through the real client and the real router,
  /// which is the only place the encoder's wire names and the router's reads meet.
  @Test
  func getRecipes_appliesTheQueryEndToEnd() async throws {
    let sut = makeSUT()

    let (all, _) = try await sut.getRecipes(query: .empty, page: 1, perPage: 100)
    let (pasta, meta) = try await sut.getRecipes(
      query: RecipeQuery(category: "Pasta"),
      page: 1,
      perPage: 100
    )

    #expect(pasta.count < all.count)
    #expect(pasta.allSatisfy { $0.category == "Pasta" })
    #expect(meta.total == pasta.count)
  }

  @Test
  func getCategories_returnsTheBrowseTiles() async throws {
    let sut = makeSUT()

    let categories = try await sut.getCategories()

    #expect(categories.count == 6)
    #expect(categories.compactMap(\.recipeCount).reduce(0, +) == 36)
  }

  /// A 404 must arrive as a typed request failure carrying the status, not as a decoding
  /// error on the error body.
  @Test
  func getRecipe_withAnUnknownID_throwsAFailedRequest() async throws {
    let sut = makeSUT()

    await #expect(throws: APIClientError.self) {
      _ = try await sut.getRecipe(id: "rcp-999")
    }
  }

  @Test
  func getRecipes_inServerErrorMode_throwsAndReportsTheError() async throws {
    let recorder = ErrorRecorder()
    let sut = makeSUT(failureMode: .serverError, onError: recorder.record)

    await #expect(throws: APIClientError.self) {
      _ = try await sut.getRecipes(query: .empty, page: 1, perPage: 5)
    }

    #expect(recorder.count > 0)
  }
}

// MARK: - Helpers

private extension APIClientRecipeTests {
  func makeSUT(
    failureMode: MockAPIRouter.FailureMode = .none,
    onError: @escaping SendableErrorResult = { _ in }
  ) -> APIClient {
    MockURLProtocol.router = MockAPIRouter(
      configuration: .init(latency: .zero, failureMode: failureMode)
    )

    return APIClient(
      sessionManager: .mocked(),
      baseURL: URL(string: "https://api.example.com/api")!,
      version: "v1",
      onError: onError
    )
  }
}
