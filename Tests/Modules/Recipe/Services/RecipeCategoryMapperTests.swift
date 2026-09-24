//
//  RecipeCategoryMapperTests.swift
//  Tests
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation
@testable import RecipeTest
import Testing

struct RecipeCategoryMapperTests {
  @Test
  func toDomain_mapsATile() throws {
    let sut = try #require(RecipeCategoryMapper.toDomain(from: .dummy()))

    #expect(sut.id == "cat-01")
    #expect(sut.name == "Meal")
    #expect(sut.imageURL == URL(string: "https://example.com/meal.jpg"))
    #expect(sut.recipeCount == 18)
  }

  /// The tile prints "*n* recipes"; a missing count shows zero rather than hiding the
  /// whole browse tile.
  @Test
  func toDomain_withoutACount_fallsBackToZero() throws {
    let sut = try #require(RecipeCategoryMapper.toDomain(from: .dummy(imageUrl: nil, recipeCount: nil)))

    #expect(sut.recipeCount == 0)
    #expect(sut.imageURL == nil)
  }

  @Test
  func toDomain_withoutAnIDOrAName_dropsTheTile() {
    #expect(RecipeCategoryMapper.toDomain(from: .dummy(id: nil)) == nil)
    #expect(RecipeCategoryMapper.toDomain(from: .dummy(name: nil)) == nil)
  }
}
