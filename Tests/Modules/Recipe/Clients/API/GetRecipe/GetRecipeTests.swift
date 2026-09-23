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
  func response200_decodesTheDetailFields() throws {
    let sut = try #require(try makeSUT())

    #expect(sut.id == "rcp-001")
    #expect(sut.title == "Spaghetti alla Carbonara")
    #expect(sut.fullDescription?.isEmpty == false)
    #expect(sut.servings == 4)
    #expect(sut.prepTimeMinutes == 10)
    #expect(sut.cookTimeMinutes == 15)
    #expect(sut.cuisine == "italian")
    #expect(sut.mealType == "dinner")
    #expect(sut.allergens == ["gluten", "eggs", "dairy"])
    #expect(sut.dietaryAttributes == [])
    #expect(sut.updatedAt == "2026-07-01T07:07:00.000Z")
  }

  @Test
  func response200_decodesTheAuthorAndNutrition() throws {
    let sut = try #require(try makeSUT())

    let author = try #require(sut.author)
    #expect(author.id == "aut-02")
    #expect(author.name == "Tobias Lindqvist")
    #expect(author.avatarUrl?.hasSuffix("author-aut-02.png") == true)

    let nutrition = try #require(sut.nutrition)
    #expect(nutrition.caloriesPerServing == 712)
    #expect(nutrition.proteinGrams == 29.4)
    #expect(nutrition.sodiumMilligrams == 980.0)
  }

  @Test
  func response200_decodesTheGallery() throws {
    let sut = try #require(try makeSUT())

    let gallery = try #require(sut.gallery)
    #expect(gallery.count == 2)
    #expect(gallery.first?.id == "med-001-1")
    #expect(gallery.first?.altText?.isEmpty == false)
  }

  @Test
  func response200_decodesIngredientGroupsAndTheirIngredients() throws {
    let sut = try #require(try makeSUT())

    let groups = try #require(sut.ingredientGroups)
    #expect(groups.count == 1)

    let group = try #require(groups.first)
    #expect(group.id == "grp-001-1")
    // A single unnamed list: null means "this recipe has one list", not a missing value.
    #expect(group.title == nil)

    let ingredients = try #require(group.ingredients)
    #expect(ingredients.count == 6)

    let first = try #require(ingredients.first)
    #expect(first.name == "Spaghetti")
    #expect(first.quantity == 320.0)
    #expect(first.unit == "gram")
    #expect(first.isOptional == false)

    let optional = try #require(ingredients.first { $0.name == "Black Pepper" })
    #expect(optional.isOptional == true)
    #expect(optional.quantity == nil)
    #expect(optional.note == "as required")
  }

  @Test
  func response200_decodesSteps() throws {
    let sut = try #require(try makeSUT())

    let steps = try #require(sut.steps)
    #expect(steps.count == 6)
    #expect(steps.map(\.number) == [1, 2, 3, 4, 5, 6])

    let first = try #require(steps.first)
    #expect(first.id == "stp-001-1")
    #expect(first.durationSeconds == 600)
    #expect(first.imageUrl?.hasSuffix("step-1.png") == true)
    #expect(steps.dropFirst().first?.imageUrl == nil)
  }

  /// `author` and `nutrition` are the only two top-level fields the fixture ever sends
  /// as null. A row that omits both must still decode.
  @Test
  func response200Minimal_decodesWithNoAuthorOrNutrition() throws {
    let sut = try #require(try makeSUT(fixture: "GetRecipeTests_200_minimal"))

    #expect(sut.id == "rcp-021")
    #expect(sut.author == nil)
    #expect(sut.nutrition == nil)
    #expect(sut.title?.isEmpty == false)
  }
}

// MARK: - Helpers

private extension GetRecipeTests {
  func makeSUT(fixture: String = "GetRecipeTests_200") throws -> RemoteRecipe? {
    try Fixture.apiResponse(fixture).decodedValue()
  }
}
