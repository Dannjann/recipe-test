//
//  RecipeFacetChipViewModelTests.swift
//  Tests
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation
@testable import RecipeTest
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
  func isExclusion_isTrueOnlyForAnExcludedIngredient() {
    #expect(RecipeFacetChipViewModel(facet: .exclude("peanuts")).isExclusion)
    #expect(RecipeFacetChipViewModel(facet: .include("garlic")).isExclusion == false)
    #expect(RecipeFacetChipViewModel(facet: .vegetarian(true)).isExclusion == false)
  }

  @Test
  func identity_isTheFacetItself() {
    let sut = RecipeFacetChipViewModel(facet: .include("garlic"))

    #expect(sut.id == .include("garlic"))
  }
}
