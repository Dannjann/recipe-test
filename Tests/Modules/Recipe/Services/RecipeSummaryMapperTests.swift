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
  func toDomain_mapsEveryFieldAListRowRenders() throws {
    let sut = try #require(RecipeSummaryMapper.toDomain(from: .dummy()))

    #expect(sut.id == "rcp-001")
    #expect(sut.title == "Spaghetti alla Carbonara")
    #expect(sut.category == "Pasta")
    #expect(sut.cuisine == "italian")
    #expect(sut.mealType == "dinner")
    #expect(sut.totalTimeMinutes == 25)
    #expect(sut.servings == 4)
    #expect(sut.difficulty == .medium)
    #expect(sut.isVegetarian == false)
    #expect(sut.heroImageURL?.host() == "www.themealdb.com")
  }

  @Test
  func toDomain_withoutAnID_dropsTheRow() {
    #expect(RecipeSummaryMapper.toDomain(from: .dummy(id: nil)) == nil)
    #expect(RecipeSummaryMapper.toDomain(from: .dummy(id: "")) == nil)
  }

  @Test
  func toDomain_withoutATitle_dropsTheRow() {
    #expect(RecipeSummaryMapper.toDomain(from: .dummy(title: nil)) == nil)
    #expect(RecipeSummaryMapper.toDomain(from: .dummy(title: "")) == nil)
  }

  /// A difficulty the app has no case for costs that one badge, not the row. Dropping the
  /// row would hide a recipe because a vocabulary grew.
  @Test
  func toDomain_withAnUnknownDifficulty_keepsTheRowAndNilsTheBadge() throws {
    let sut = try #require(RecipeSummaryMapper.toDomain(from: .dummy(difficulty: "impossible")))

    #expect(sut.difficulty == nil)
  }

  @Test
  func toDomain_withoutAVegetarianFlag_fallsBackToFalse() throws {
    let sut = try #require(RecipeSummaryMapper.toDomain(from: .dummy(isVegetarian: nil)))

    #expect(sut.isVegetarian == false)
  }

  @Test
  func toDomain_withAnUnusableHeroURL_keepsTheRow() throws {
    let sut = try #require(RecipeSummaryMapper.toDomain(from: .dummy(heroImageUrl: nil)))

    #expect(sut.heroImageURL == nil)
  }

  /// The facets the list filters on are open vocabularies, so an unrecognised value is
  /// carried through as written rather than normalised or dropped.
  @Test
  func toDomain_carriesOpenFacetsThrough() throws {
    let sut = try #require(RecipeSummaryMapper.toDomain(from: .dummy(category: "Brunch", cuisine: "cornish")))

    #expect(sut.category == "Brunch")
    #expect(sut.cuisine == "cornish")
  }
}
