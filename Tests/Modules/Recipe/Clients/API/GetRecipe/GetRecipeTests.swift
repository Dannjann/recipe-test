//
//  GetRecipeTests.swift
//  Tests
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation
@testable import RecipeTest
import Testing

struct GetRecipeTests {
  @Test
  func response200_decodesTheWholeRecipe() throws {
    let sut = try #require(try makeSUT())

    #expect(sut.id == "rcp-001")
    #expect(sut.title == "Spaghetti alla Carbonara")
    #expect(sut.description?.isEmpty == false)
    #expect(sut.gallery?.count == 3)
    #expect(sut.steps?.count == 6)
    #expect(sut.isVegetarian == false)
  }

  /// Ingredients are a flat list of display strings now — no group wrapper, no numeric
  /// quantity, no unit.
  @Test
  func response200_decodesFlatIngredients() throws {
    let sut = try #require(try makeSUT())

    let ingredients = try #require(sut.ingredients)
    #expect(ingredients.count == 6)

    let first = try #require(ingredients.first)
    #expect(first.name == "Spaghetti")
    #expect(first.quantityText == "320 g")
    #expect(first.isMain == true)
  }

  /// Most ingredients have no photograph, so a null here must decode rather than throw.
  @Test
  func response200_decodesANullIngredientImage() throws {
    let sut = try #require(try makeSUT())

    #expect(sut.ingredients?.contains { $0.imageUrl == nil } == true)
  }

  /// Steps are plain strings, so payload order is display order.
  @Test
  func response200_decodesStepsAsStrings() throws {
    let sut = try #require(try makeSUT())

    #expect(sut.steps?.first?.hasPrefix("Bring a large pan") == true)
  }

  /// Every property is optional, so a row carrying only the two required fields decodes
  /// rather than throwing — that is what keeps one thin row from failing a whole page.
  @Test
  func response200_withOnlyTheRequiredFields_decodesTheRestAsNil() throws {
    let sut = try #require(try makeSUT(fixture: "GetRecipeTests_200_minimal"))

    #expect(sut.id == "rcp-036")
    #expect(sut.title == "Vegan Chocolate Cake")
    #expect(sut.ingredients == nil)
    #expect(sut.steps == nil)
    #expect(sut.gallery == nil)
  }
}

// MARK: - Helpers

private extension GetRecipeTests {
  func makeSUT(fixture: String = "GetRecipeTests_200") throws -> RemoteRecipe? {
    try Fixture.apiResponse(fixture).decodedValue()
  }
}
