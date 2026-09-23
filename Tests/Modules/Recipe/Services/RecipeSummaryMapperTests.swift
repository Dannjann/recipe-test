//
//  RecipeSummaryMapperTests.swift
//  Tests
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation
@testable import RecipeTest
import Testing

struct RecipeSummaryMapperTests {
  @Test
  func toDomain_mapsACompleteRow() throws {
    let sut = try #require(RecipeSummaryMapper.toDomain(from: .dummy()))

    #expect(sut.id == "rcp-001")
    #expect(sut.title == "Spaghetti alla Carbonara")
    #expect(sut.shortDescription == "Roman pasta bound with egg yolk and pecorino.")
    #expect(sut.heroImageURL?.absoluteString == "https://api.example.com/api/v1/images/carbonara.png")
    #expect(sut.totalTimeMinutes == 25)
    #expect(sut.difficulty == .medium)
    #expect(sut.rating == 4.8)
    #expect(sut.ratingCount == 2147)
    #expect(sut.tags == ["quick", "classic"])
  }

  @Test
  func toDomain_withoutAnID_returnsNil() {
    #expect(RecipeSummaryMapper.toDomain(from: .dummy(id: nil)) == nil)
  }

  @Test
  func toDomain_withAnEmptyID_returnsNil() {
    #expect(RecipeSummaryMapper.toDomain(from: .dummy(id: "")) == nil)
  }

  @Test
  func toDomain_withoutATitle_returnsNil() {
    #expect(RecipeSummaryMapper.toDomain(from: .dummy(title: nil)) == nil)
  }

  @Test
  func toDomain_withAnEmptyTitle_returnsNil() {
    #expect(RecipeSummaryMapper.toDomain(from: .dummy(title: "")) == nil)
  }

  /// Everything except id and title has a defined fallback. A row that carries only the
  /// two required fields is still a usable list row.
  @Test
  func toDomain_withOnlyTheRequiredFields_fillsTheRest() throws {
    let remote = RemoteRecipeSummary.dummy(
      shortDescription: nil,
      heroImageUrl: nil,
      totalTimeMinutes: nil,
      difficulty: nil,
      rating: nil,
      ratingCount: nil,
      tags: nil
    )

    let sut = try #require(RecipeSummaryMapper.toDomain(from: remote))

    #expect(sut.shortDescription == "")
    #expect(sut.heroImageURL == nil)
    #expect(sut.totalTimeMinutes == nil)
    #expect(sut.difficulty == nil)
    #expect(sut.rating == 0)
    #expect(sut.ratingCount == 0)
    #expect(sut.tags == [])
  }

  /// A difficulty the app has no case for must not cost the row. Today the fixture only
  /// sends easy/medium/hard; a backend adding "expert" must degrade, not break.
  @Test
  func toDomain_withAnUnknownDifficulty_keepsTheRowAndDropsTheValue() throws {
    let sut = try #require(RecipeSummaryMapper.toDomain(from: .dummy(difficulty: "expert")))

    #expect(sut.difficulty == nil)
    #expect(sut.id == "rcp-001")
  }

  @Test
  func toDomain_withAnUnparseableHeroImageURL_keepsTheRow() throws {
    let sut = try #require(RecipeSummaryMapper.toDomain(from: .dummy(heroImageUrl: "")))

    #expect(sut.heroImageURL == nil)
    #expect(sut.id == "rcp-001")
  }

  @Test(arguments: [("easy", RecipeDifficulty.easy), ("medium", .medium), ("hard", .hard)])
  func toDomain_mapsEveryKnownDifficulty(raw: String, expected: RecipeDifficulty) throws {
    let sut = try #require(RecipeSummaryMapper.toDomain(from: .dummy(difficulty: raw)))

    #expect(sut.difficulty == expected)
  }
}
