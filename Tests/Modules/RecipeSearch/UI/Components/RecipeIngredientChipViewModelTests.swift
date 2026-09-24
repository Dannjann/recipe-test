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
  func id_theSameWordOnBothSides_differsByKind() {
    #expect(chip(kind: .include).id != chip(kind: .exclude).id)
  }

  @Test
  func backgroundColorStyle_anExclusion_readsAsAnExclusion() {
    #expect(chip(kind: .include).backgroundColorStyle == .surfacesFieldsAndTags)
    #expect(chip(kind: .exclude).backgroundColorStyle == .complementaryShade3)
  }

  @Test
  func accessibilityIdentifier_anExclusion_namesItsSide() {
    #expect(chip(kind: .exclude).accessibilityIdentifier == "recipe-search-exclude-chip-pork-remove-button")
  }

  @Test
  func removeAccessibilityLabel_anyChip_namesTheIngredient() {
    #expect(chip(kind: .include).removeAccessibilityLabel.contains("pork"))
  }
}

// MARK: - Helpers

private extension RecipeIngredientChipViewModelTests {
  func chip(kind: RecipeIngredientChipViewModel.Kind) -> RecipeIngredientChipViewModel {
    RecipeIngredientChipViewModel(
      ingredient: "pork",
      kind: kind
    )
  }
}
