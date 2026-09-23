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

    #expect(data?.count == 3)

    let first = try #require(data?.first)
    #expect(first.id == "rcp-001")
    #expect(first.slug == "spaghetti-alla-carbonara")
    #expect(first.title == "Spaghetti alla Carbonara")
    #expect(first.shortDescription?.hasPrefix("Roman pasta") == true)
    #expect(first.totalTimeMinutes == 25)
    #expect(first.difficulty == "medium")
    #expect(first.rating == 4.8)
    #expect(first.ratingCount == 2147)
    #expect(first.tags == ["quick", "classic", "five-ingredient"])
  }

  /// `hero_image_url` reaching `heroImageUrl` is the whole snake_case contract. If the
  /// property were named `heroImageURL`, the converting decoder would leave it nil.
  @Test
  func response200_mapsSnakeCaseKeys() throws {
    let sut = try makeSUT()

    let data: [RemoteRecipeSummary]? = try sut.decodedValue()
    let first = try #require(data?.first)

    #expect(first.heroImageUrl?.hasSuffix("spaghetti-alla-carbonara.png") == true)
  }

  @Test
  func response200_decodesPaginationMeta() throws {
    let sut = try makeSUT()

    let meta: RemotePaginationMetaInfo? = try sut.decodeMeta()

    #expect(meta?.total == 36)
    #expect(meta?.perPage == 3)
    #expect(meta?.currentPage == 1)
    #expect(meta?.lastPage == 12)
  }
}

// MARK: - Helpers

private extension GetRecipesTests {
  func makeSUT() throws -> APIResponse {
    try Fixture.apiResponse("GetRecipesTests_200")
  }
}
