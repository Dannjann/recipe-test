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

/// Serialized: `MockURLProtocol.router` is process-global, and Swift Testing runs suites
/// in parallel. Two suites configuring it at once would flake against each other.
@Suite(.serialized)
struct APIClientRecipeTests {
  @Test
  func getRecipes_returnsThePageAndItsMeta() async throws {
    let sut = makeSUT()

    let (recipes, meta) = try await sut.getRecipes(page: 1, perPage: 5)

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

    let (recipes, _) = try await sut.getRecipes(page: 1, perPage: 1)
    let first = try #require(recipes.first)

    #expect(first.heroImageUrl?.hasSuffix("spaghetti-alla-carbonara.png") == true)
    #expect(first.totalTimeMinutes == 25)
    #expect(first.ratingCount == 2147)
  }

  /// Proves `page` and `per_page` actually reach the query string — the router slices on
  /// them, so a wrong parameter name would come back as page 1 every time.
  @Test
  func getRecipes_sendsThePageParameters() async throws {
    let sut = makeSUT()

    let (recipes, meta) = try await sut.getRecipes(page: 2, perPage: 5)

    #expect(recipes.first?.id == "rcp-006")
    #expect(meta.currentPage == 2)
  }

  @Test
  func getRecipes_pastTheLastPage_returnsAnEmptyPage() async throws {
    let sut = makeSUT()

    let (recipes, meta) = try await sut.getRecipes(page: 99, perPage: 5)

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
    #expect(recipe.ingredientGroups?.isEmpty == false)
    #expect(recipe.author?.name == "Tobias Lindqvist")
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
      _ = try await sut.getRecipes(page: 1, perPage: 5)
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
