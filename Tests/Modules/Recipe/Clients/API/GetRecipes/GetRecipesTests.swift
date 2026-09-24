//
//  GetRecipesTests.swift
//  Tests
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation
@testable import RecipeTest
import Testing

struct GetRecipesTests {
  @Test
  func response200_decodesTheSummaries() throws {
    let sut = try makeSUT()

    let data: [RemoteRecipeSummary]? = try sut.decodedValue()

    #expect(data?.count == 2)

    let first = try #require(data?.first)
    #expect(first.id == "rcp-001")
    #expect(first.title == "Spaghetti alla Carbonara")
    #expect(first.category == "Pasta")
    #expect(first.cuisine == "italian")
    #expect(first.servings == 4)
    #expect(first.totalTimeMinutes == 25)
    #expect(first.difficulty == "medium")
  }

  /// `hero_image_url` reaching `heroImageUrl`, and `is_vegetarian` reaching
  /// `isVegetarian`, is the whole snake_case contract. If either property were named with
  /// a nicer acronym casing, the converting decoder would leave it nil.
  @Test
  func response200_mapsSnakeCaseKeys() throws {
    let sut = try makeSUT()

    let data: [RemoteRecipeSummary]? = try sut.decodedValue()
    let first = try #require(data?.first)

    #expect(first.heroImageUrl?.hasPrefix("https://") == true)
    #expect(first.isVegetarian == false)
    #expect(first.mealType == "dinner")
  }

  @Test
  func response200_decodesPaginationMeta() throws {
    let sut = try makeSUT()

    let meta: RemotePaginationMetaInfo? = try sut.decodeMeta()

    #expect(meta?.total == 36)
    #expect(meta?.perPage == 2)
    #expect(meta?.currentPage == 1)
    #expect(meta?.lastPage == 18)
  }
}

// MARK: - Helpers

private extension GetRecipesTests {
  func makeSUT() throws -> APIResponse {
    try Fixture.apiResponse("GetRecipesTests_200")
  }
}
