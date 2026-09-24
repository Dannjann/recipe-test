//
//  RecipeIngredientChipViewModelTests.swift
//  Tests
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation
@testable import RecipeTest
import Testing

struct RecipeIngredientChipViewModelTests {
  @Test
  func id_theSameWordOnBothSides_differsBySide() {
    let included = RecipeIncludedIngredientChipViewModel(ingredient: "pork")
    let excluded = RecipeExcludedIngredientChipViewModel(ingredient: "pork")

    #expect(included.id != excluded.id)
  }

  @Test
  func backgroundColorStyle_anExclusion_readsAsAnExclusion() {
    #expect(RecipeIncludedIngredientChipViewModel(ingredient: "pork")
      .backgroundColorStyle == .complementaryShade1)
    #expect(RecipeExcludedIngredientChipViewModel(ingredient: "pork")
      .backgroundColorStyle == .complementaryShade2)
  }

  @Test
  func accessibilityIdentifier_eitherSide_namesItsSide() {
    #expect(RecipeIncludedIngredientChipViewModel(ingredient: "pork")
      .accessibilityIdentifier == "recipe-search-include-chip-pork-remove-button")
    #expect(RecipeExcludedIngredientChipViewModel(ingredient: "pork")
      .accessibilityIdentifier == "recipe-search-exclude-chip-pork-remove-button")
  }

  @Test
  func removeAccessibilityLabel_anyChip_namesTheIngredient() {
    #expect(RecipeIncludedIngredientChipViewModel(ingredient: "pork")
      .removeAccessibilityLabel.contains("pork"))
  }

  @Test
  func label_anyChip_isTheIngredient() {
    #expect(RecipeExcludedIngredientChipViewModel(ingredient: "pork").label == "pork")
  }
}
