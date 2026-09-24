//
//  RecipeServingsOptionViewModelTests.swift
//  Tests
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation
@testable import RecipeTest
import Testing

struct RecipeServingsOptionViewModelTests {
  @Test
  func label_everyOption_readsAsItsRawValue() {
    let options = RecipeServings.allCases.map {
      RecipeServingsOptionViewModel(
        servings: $0,
        isSelected: false
      )
    }

    #expect(options.map(\.label) == ["1", "2", "4", "6+"])
  }

  @Test
  func accessibilityIdentifier_theOpenEndedOption_keepsThePlusOut() {
    let option = RecipeServingsOptionViewModel(
      servings: .sixOrMore,
      isSelected: true
    )

    #expect(option.accessibilityIdentifier == "recipe-search-servings-option-6-plus")
  }

  @Test
  func accessibilityIdentifier_aPlainOption_carriesItsValue() {
    let option = RecipeServingsOptionViewModel(
      servings: .four,
      isSelected: false
    )

    #expect(option.accessibilityIdentifier == "recipe-search-servings-option-4")
  }
}
