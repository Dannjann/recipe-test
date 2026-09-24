//
//  RecipeServingsOptionViewModelTests.swift
//  Tests
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation
@testable import RecipeTest
import SwiftUI
import Testing

struct RecipeServingsOptionViewModelTests {
  @Test
  func label_everyOption_readsAsItsRawValue() {
    let options = RecipeServings.allCases.map { RecipeServingsOptionViewModel(servings: $0) }

    #expect(options.map(\.label) == ["1", "2", "4", "6+"])
  }

  @Test
  func accessibilityIdentifier_theOpenEndedOption_keepsThePlusOut() {
    let option = RecipeSelectedServingsOptionViewModel(servings: .sixOrMore)

    #expect(option.accessibilityIdentifier == "recipe-search-servings-option-6-plus")
  }

  @Test
  func accessibilityIdentifier_aPlainOption_carriesItsValue() {
    let option = RecipeServingsOptionViewModel(servings: .four)

    #expect(option.accessibilityIdentifier == "recipe-search-servings-option-4")
  }

  /// The selected and unselected options must differ in what they paint, or the picker would
  /// give no sign of which one is active.
  @Test
  func colorStyles_selection_flipsTheSurfaceAndTheLabel() {
    let plain = RecipeServingsOptionViewModel(servings: .four)
    let selected = RecipeSelectedServingsOptionViewModel(servings: .four)

    #expect(plain.backgroundColorStyle == .surfacesFieldsAndTags)
    #expect(plain.labelColorStyle == .textPrimary)
    #expect(selected.backgroundColorStyle == .surfacesBrandDefault)
    #expect(selected.labelColorStyle == .textInverted)
  }

  @Test
  func accessibilityTraits_onlyTheSelectedOption_readsAsSelected() {
    #expect(RecipeServingsOptionViewModel(servings: .four)
      .accessibilityTraits == .isButton)
    #expect(RecipeSelectedServingsOptionViewModel(servings: .four)
      .accessibilityTraits == [.isButton, .isSelected])
  }
}
