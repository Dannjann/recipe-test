//
//  GetCategoriesTests.swift
//  Tests
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation
@testable import RecipeTest
import Testing

struct GetCategoriesTests {
  @Test
  func response200_decodesTheBrowseTiles() throws {
    let sut = try makeSUT()

    let data: [RemoteRecipeCategory]? = try sut.decodedValue()

    #expect(data?.count == 6)

    let first = try #require(data?.first)
    #expect(first.id == "cat-01")
    #expect(first.name == "Meal")
    #expect(first.imageUrl?.hasPrefix("https://") == true)
  }

  /// The tile prints "*n* recipes", so the count has to survive the snake_case decoder.
  @Test
  func response200_decodesTheRecipeCount() throws {
    let sut = try makeSUT()

    let data: [RemoteRecipeCategory]? = try sut.decodedValue()

    #expect(data?.first?.recipeCount == 18)
    #expect(data?.compactMap(\.recipeCount).reduce(0, +) == 36)
  }
}

// MARK: - Helpers

private extension GetCategoriesTests {
  func makeSUT() throws -> APIResponse {
    try Fixture.apiResponse("GetCategoriesTests_200")
  }
}
