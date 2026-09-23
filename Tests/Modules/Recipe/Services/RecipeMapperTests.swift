//
//  RecipeMapperTests.swift
//  Tests
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation
@testable import RecipeTest
import Testing

struct RecipeMapperTests {
  @Test
  func toDomain_mapsACompleteRecipe() throws {
    let sut = try #require(RecipeMapper.toDomain(from: .dummy()))

    #expect(sut.id == "rcp-001")
    #expect(sut.title == "Spaghetti alla Carbonara")
    #expect(sut.fullDescription == "The whole dish turns on one trick.")
    #expect(sut.servings == 4)
    #expect(sut.prepTimeMinutes == 10)
    #expect(sut.cookTimeMinutes == 15)
    #expect(sut.totalTimeMinutes == 25)
    #expect(sut.difficulty == .medium)
    #expect(sut.cuisine == "italian")
    #expect(sut.mealType == "dinner")
    #expect(sut.allergens == ["gluten", "eggs"])
    #expect(sut.dietaryAttributes == [])
  }

  @Test
  func toDomain_withoutAnID_returnsNil() {
    #expect(RecipeMapper.toDomain(from: .dummy(id: nil)) == nil)
  }

  @Test
  func toDomain_withAnEmptyID_returnsNil() {
    #expect(RecipeMapper.toDomain(from: .dummy(id: "")) == nil)
  }

  @Test
  func toDomain_withoutATitle_returnsNil() {
    #expect(RecipeMapper.toDomain(from: .dummy(title: nil)) == nil)
  }

  @Test
  func toDomain_withAnEmptyTitle_returnsNil() {
    #expect(RecipeMapper.toDomain(from: .dummy(title: "")) == nil)
  }

  /// A difficulty the app has no case for must not cost the recipe. Today the fixture
  /// only sends easy/medium/hard; a backend adding "expert" must degrade, not break.
  @Test
  func toDomain_withAnUnknownDifficulty_keepsTheRecipeAndDropsTheValue() throws {
    let sut = try #require(RecipeMapper.toDomain(from: .dummy(difficulty: "expert")))

    #expect(sut.difficulty == nil)
    #expect(sut.id == "rcp-001")
  }

  @Test(arguments: [("easy", RecipeDifficulty.easy), ("medium", .medium), ("hard", .hard)])
  func toDomain_mapsEveryKnownDifficulty(raw: String, expected: RecipeDifficulty) throws {
    let sut = try #require(RecipeMapper.toDomain(from: .dummy(difficulty: raw)))

    #expect(sut.difficulty == expected)
  }

  @Test
  func toDomain_mapsTheAuthor() throws {
    let sut = try #require(RecipeMapper.toDomain(from: .dummy()))
    let author = try #require(sut.author)

    #expect(author.id == "aut-02")
    #expect(author.name == "Tobias Lindqvist")
    #expect(author.avatarURL?.absoluteString.hasSuffix("author-aut-02.png") == true)
  }

  /// Author and nutrition are the only relations the API ever sends as null.
  @Test
  func toDomain_withoutAuthorOrNutrition_keepsTheRecipe() throws {
    let sut = try #require(RecipeMapper.toDomain(from: .dummy(author: nil, nutrition: nil)))

    #expect(sut.author == nil)
    #expect(sut.nutrition == nil)
    #expect(sut.id == "rcp-001")
  }

  /// An author row with no name is not an author. The recipe survives without one.
  @Test
  func toDomain_withAnUnusableAuthor_keepsTheRecipe() throws {
    let sut = try #require(RecipeMapper.toDomain(from: .dummy(author: .dummy(name: nil))))

    #expect(sut.author == nil)
    #expect(sut.id == "rcp-001")
  }

  @Test
  func toDomain_mapsNutrition() throws {
    let sut = try #require(RecipeMapper.toDomain(from: .dummy()))
    let nutrition = try #require(sut.nutrition)

    #expect(nutrition.caloriesPerServing == 712)
    #expect(nutrition.proteinGrams == 29.4)
    #expect(nutrition.sodiumMilligrams == 980.0)
  }

  @Test
  func toDomain_dropsGalleryEntriesWithAnUnusableURL() throws {
    let gallery: [RemoteRecipeMedia] = [.dummy(id: "med-1"), .dummy(id: "med-2", url: nil)]

    let sut = try #require(RecipeMapper.toDomain(from: .dummy(gallery: gallery)))

    #expect(sut.gallery.map(\.id) == ["med-1"])
  }

  @Test
  func toDomain_mapsIngredientGroupsAndTheirIngredients() throws {
    let group = RemoteIngredientGroup.dummy(
      title: "For the sauce",
      ingredients: [.dummy(id: "ing-1", name: "Spaghetti"), .dummy(id: "ing-2", name: "Pecorino", unit: nil)]
    )

    let sut = try #require(RecipeMapper.toDomain(from: .dummy(ingredientGroups: [group])))

    #expect(sut.ingredientGroups.count == 1)
    #expect(sut.ingredientGroups.first?.title == "For the sauce")
    #expect(sut.ingredientGroups.first?.ingredients.map(\.name) == ["Spaghetti", "Pecorino"])
    #expect(sut.ingredientGroups.first?.ingredients.last?.unit == nil)
  }

  @Test
  func toDomain_dropsIngredientsWithNoName() throws {
    let group = RemoteIngredientGroup.dummy(
      ingredients: [.dummy(id: "ing-1", name: "Spaghetti"), .dummy(id: "ing-2", name: nil)]
    )

    let sut = try #require(RecipeMapper.toDomain(from: .dummy(ingredientGroups: [group])))

    #expect(sut.ingredientGroups.first?.ingredients.map(\.id) == ["ing-1"])
  }

  /// A group whose ingredients all failed would render as a bare heading with nothing
  /// under it. Drop it instead.
  @Test
  func toDomain_dropsAGroupLeftWithNoIngredients() throws {
    let empty = RemoteIngredientGroup.dummy(id: "grp-empty", ingredients: [.dummy(name: nil)])
    let good = RemoteIngredientGroup.dummy(id: "grp-good")

    let sut = try #require(RecipeMapper.toDomain(from: .dummy(ingredientGroups: [empty, good])))

    #expect(sut.ingredientGroups.map(\.id) == ["grp-good"])
  }

  /// Display order must come from `number`, not from the order the payload happens to
  /// list them in.
  @Test
  func toDomain_ordersStepsByNumber() throws {
    let steps: [RemoteRecipeStep] = [
      .dummy(id: "stp-3", number: 3),
      .dummy(id: "stp-1", number: 1),
      .dummy(id: "stp-2", number: 2),
    ]

    let sut = try #require(RecipeMapper.toDomain(from: .dummy(steps: steps)))

    #expect(sut.steps.map(\.id) == ["stp-1", "stp-2", "stp-3"])
  }

  @Test
  func toDomain_dropsStepsMissingTheirNumberOrText() throws {
    let steps: [RemoteRecipeStep] = [
      .dummy(id: "stp-1", number: 1),
      .dummy(id: "stp-2", number: nil),
      .dummy(id: "stp-3", number: 3, text: nil),
    ]

    let sut = try #require(RecipeMapper.toDomain(from: .dummy(steps: steps)))

    #expect(sut.steps.map(\.id) == ["stp-1"])
  }

  @Test
  func toDomain_parsesTheUpdatedAtTimestamp() throws {
    let sut = try #require(RecipeMapper.toDomain(from: .dummy()))
    let updatedAt = try #require(sut.updatedAt)

    #expect(updatedAt == DateFormatter.iso8601.date(from: "2026-07-01T07:07:00.000Z"))
  }

  /// One unparseable timestamp costs that field, not the recipe. This is the reason the
  /// DTO keeps it as a String instead of using a decoder date strategy.
  @Test
  func toDomain_withAnUnparseableTimestamp_keepsTheRecipe() throws {
    let sut = try #require(RecipeMapper.toDomain(from: .dummy(updatedAt: "last Tuesday")))

    #expect(sut.updatedAt == nil)
    #expect(sut.id == "rcp-001")
  }

  @Test
  func toDomain_withEveryOptionalRelationAbsent_fillsWithEmptyCollections() throws {
    let remote = RemoteRecipe.dummy(
      shortDescription: nil,
      fullDescription: nil,
      tags: nil,
      dietaryAttributes: nil,
      allergens: nil,
      author: nil,
      nutrition: nil,
      gallery: nil,
      ingredientGroups: nil,
      steps: nil
    )

    let sut = try #require(RecipeMapper.toDomain(from: remote))

    #expect(sut.shortDescription == "")
    #expect(sut.fullDescription == "")
    #expect(sut.tags == [])
    #expect(sut.dietaryAttributes == [])
    #expect(sut.allergens == [])
    #expect(sut.gallery == [])
    #expect(sut.ingredientGroups == [])
    #expect(sut.steps == [])
  }
}
