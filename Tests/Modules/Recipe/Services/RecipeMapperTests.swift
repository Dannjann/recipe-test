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
  func toDomain_mapsTheDetailsOwnFields() throws {
    let sut = try #require(RecipeMapper.toDomain(from: .dummy()))

    #expect(sut.description == "Roman pasta bound with egg yolk and pecorino.")
    #expect(sut.gallery.count == 2)
    #expect(sut.steps == ["Boil the water.", "Toss off the heat."])
    #expect(sut.ingredients.count == 1)
    #expect(sut.ingredients.first?.quantityText == "320 g")
    #expect(sut.ingredients.first?.isMain == true)
  }

  /// The contract carries no ingredient ids, but a `ForEach` still needs stable identity,
  /// and position within a recipe is stable.
  @Test
  func toDomain_synthesisesIngredientIDsFromTheRecipeAndPosition() throws {
    let sut = try #require(RecipeMapper.toDomain(from: .dummy(
      id: "rcp-007",
      ingredients: [.dummy(name: "Tofu"), .dummy(name: "Rice paper")]
    )))

    #expect(sut.ingredients.map(\.id) == ["rcp-007-0", "rcp-007-1"])
  }

  /// Most of the 370 ingredients have no photograph, so this is the common case, not the
  /// edge case.
  @Test
  func toDomain_withAnIngredientWithoutAPhotograph_keepsIt() throws {
    let sut = try #require(RecipeMapper.toDomain(from: .dummy(
      ingredients: [.dummy(name: "Salt", imageUrl: nil)]
    )))

    #expect(sut.ingredients.count == 1)
    #expect(sut.ingredients.first?.imageURL == nil)
  }

  /// A nameless line cannot be rendered, but the recipe around it still can.
  @Test
  func toDomain_withANamelessIngredient_dropsThatLineOnly() throws {
    let sut = try #require(RecipeMapper.toDomain(from: .dummy(
      ingredients: [.dummy(name: nil), .dummy(name: "Spaghetti")]
    )))

    #expect(sut.ingredients.map(\.name) == ["Spaghetti"])
  }

  /// Dropping a line must not renumber the ones after it, or identity moves between
  /// renders of the same payload.
  @Test
  func toDomain_withADroppedIngredient_doesNotRenumberTheRest() throws {
    let sut = try #require(RecipeMapper.toDomain(from: .dummy(
      id: "rcp-001",
      ingredients: [.dummy(name: "Spaghetti"), .dummy(name: nil), .dummy(name: "Bacon")]
    )))

    #expect(sut.ingredients.map(\.id) == ["rcp-001-0", "rcp-001-2"])
  }

  @Test
  func toDomain_withAbsentCollections_fallsBackToEmpty() throws {
    let sut = try #require(RecipeMapper.toDomain(from: .dummy(
      description: nil,
      gallery: nil,
      ingredients: nil,
      steps: nil
    )))

    #expect(sut.description.isEmpty)
    #expect(sut.gallery.isEmpty)
    #expect(sut.ingredients.isEmpty)
    #expect(sut.steps.isEmpty)
  }

  /// Payload order is display order now that steps are plain strings, so nothing may
  /// reorder them.
  @Test
  func toDomain_keepsStepsInPayloadOrder() throws {
    let sut = try #require(RecipeMapper.toDomain(from: .dummy(steps: ["Third", "First", "Second"])))

    #expect(sut.steps == ["Third", "First", "Second"])
  }

  @Test
  func toDomain_withAnUnusableGalleryURL_dropsThatPhotographOnly() throws {
    let sut = try #require(RecipeMapper.toDomain(from: .dummy(
      gallery: ["https://example.com/1.jpg", ""]
    )))

    #expect(sut.gallery.count == 1)
  }

  @Test
  func toDomain_withoutAnID_dropsTheRecipe() {
    #expect(RecipeMapper.toDomain(from: .dummy(id: nil)) == nil)
  }

  @Test
  func toDomain_withoutATitle_dropsTheRecipe() {
    #expect(RecipeMapper.toDomain(from: .dummy(title: nil)) == nil)
  }
}
