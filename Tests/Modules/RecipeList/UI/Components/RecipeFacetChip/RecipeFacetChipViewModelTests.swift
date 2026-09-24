//
//  RecipeFacetChipViewModelTests.swift
//  Tests
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

@testable import RecipeTest
import SwiftUI
import Testing

struct RecipeFacetChipViewModelTests {
  @Test
  func label_vegetarianTrue_readsVegetarian() {
    let sut = RecipeFacetChipViewModel(facet: .vegetarian(true))

    #expect(sut.label == "Vegetarian")
  }

  @Test
  func label_vegetarianFalse_saysSoRatherThanRepeatingTheOppositeFilter() {
    let sut = RecipeFacetChipViewModel(facet: .vegetarian(false))

    #expect(sut.label == "Not vegetarian")
  }

  @Test
  func label_servings_usesTheWireValueIncludingTheOpenEndedOne() {
    #expect(RecipeFacetChipViewModel(facet: .servings(.four)).label == "4 servings")
    #expect(RecipeFacetChipViewModel(facet: .servings(.sixOrMore)).label == "6+ servings")
  }

  @Test
  func label_includeAndExclude_namePrefixTheIngredient() {
    #expect(RecipeFacetChipViewModel(facet: .include("garlic")).label == "Include: garlic")
    #expect(RecipeFacetChipViewModel(facet: .exclude("peanuts")).label == "Exclude: peanuts")
  }

  @Test
  func label_searchesSteps_readsSearchInSteps() {
    let sut = RecipeFacetChipViewModel(facet: .searchesSteps)

    #expect(sut.label == "Search in steps")
  }

  @Test
  func removeAccessibilityLabel_namesWhatItRemoves() {
    let sut = RecipeFacetChipViewModel(facet: .vegetarian(true))

    #expect(sut.removeAccessibilityLabel == "Remove Vegetarian")
  }

  @Test
  func backgroundColorStyle_tintsOnlyAnExcludedIngredientDifferently() {
    #expect(RecipeFacetChipViewModel(facet: .exclude("peanuts")).backgroundColorStyle == .complementaryShade2)
    #expect(RecipeFacetChipViewModel(facet: .include("garlic")).backgroundColorStyle == .complementaryShade1)
    #expect(RecipeFacetChipViewModel(facet: .vegetarian(true)).backgroundColorStyle == .complementaryShade1)
  }

  @Test
  func accessibilityIdentifier_distinguishesOneChipFromAnother() {
    #expect(
      RecipeFacetChipViewModel(facet: .include("garlic")).accessibilityIdentifier
        == "recipe-list-facet-chip-include-garlic-remove-button"
    )
    #expect(
      RecipeFacetChipViewModel(facet: .exclude("garlic")).accessibilityIdentifier
        == "recipe-list-facet-chip-exclude-garlic-remove-button"
    )
    #expect(
      RecipeFacetChipViewModel(facet: .vegetarian(true)).accessibilityIdentifier
        == "recipe-list-facet-chip-vegetarian-remove-button"
    )
  }

  @Test
  func accessibilityIdentifier_doesNotTrackTheLabel() {
    let sut = RecipeFacetChipViewModel(facet: .searchesSteps)

    #expect(sut.accessibilityIdentifier.contains(sut.label) == false)
  }

  @Test
  func identity_isTheFacetItself() {
    let sut = RecipeFacetChipViewModel(facet: .include("garlic"))

    #expect(sut.id == .include("garlic"))
  }
}
