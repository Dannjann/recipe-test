//
//  RecipeCardViewModelTests.swift
//  Tests
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation
@testable import RecipeTest
import Testing

struct RecipeCardViewModelTests {
  @Test
  func cookingTimeText_underAnHour_readsInMinutes() {
    let sut = RecipeCardViewModel(summary: .dummy(totalTimeMinutes: 25))

    #expect(sut.cookingTimeText == "25 min")
  }

  @Test
  func cookingTimeText_aWholeHour_omitsTheMinutes() {
    let sut = RecipeCardViewModel(summary: .dummy(totalTimeMinutes: 60))

    #expect(sut.cookingTimeText == "1 hr")
  }

  /// `Duration`'s abbreviated units join with a list separator, so this reads "1 hr, 30 min"
  /// rather than the prototype's "1 hr 30 min". The punctuation is the formatter's to
  /// localize; what matters is that 90 stops being printed as 90 of anything.
  @Test
  func cookingTimeText_overAnHour_readsBothUnits() {
    let sut = RecipeCardViewModel(summary: .dummy(totalTimeMinutes: 90))

    #expect(sut.cookingTimeText == "1 hr, 30 min")
  }

  @Test
  func cookingTimeText_noTime_isNil() {
    let sut = RecipeCardViewModel(summary: .dummy(totalTimeMinutes: nil))

    #expect(sut.cookingTimeText == nil)
  }

  @Test
  func cuisineAndCategory_bothPresent_joinsThemCapitalised() {
    let sut = RecipeCardViewModel(summary: .dummy(
      category: "Pasta",
      cuisine: "italian"
    ))

    #expect(sut.cuisineAndCategory == "Italian · Pasta")
  }

  @Test
  func cuisineAndCategory_onlyOnePresent_isThatOneAlone() {
    let sut = RecipeCardViewModel(summary: .dummy(
      category: nil,
      cuisine: "thai"
    ))

    #expect(sut.cuisineAndCategory == "Thai")
  }

  @Test
  func cuisineAndCategory_neitherPresent_isNil() {
    let sut = RecipeCardViewModel(summary: .dummy(
      category: nil,
      cuisine: nil
    ))

    #expect(sut.cuisineAndCategory == nil)
  }

  @Test
  func servingsText_isTheBareNumber() {
    let sut = RecipeCardViewModel(summary: .dummy(servings: 4))

    #expect(sut.servingsText == "4")
  }

  @Test
  func servingsText_noServings_isNil() {
    let sut = RecipeCardViewModel(summary: .dummy(servings: nil))

    #expect(sut.servingsText == nil)
  }

  @Test
  func accessibilityLabel_everythingPresent_readsTitleThenMetrics() {
    let sut = RecipeCardViewModel(summary: .dummy(
      title: "Chicken Adobo",
      totalTimeMinutes: 45,
      servings: 4
    ))

    #expect(sut.accessibilityLabel == "Chicken Adobo, 45 min, serves 4")
  }

  @Test
  func accessibilityLabel_noMetrics_isTheTitleAlone() {
    let sut = RecipeCardViewModel(summary: .dummy(
      title: "Chicken Adobo",
      totalTimeMinutes: nil,
      servings: nil
    ))

    #expect(sut.accessibilityLabel == "Chicken Adobo")
  }

  @Test
  func identity_isTheRecipeID() {
    let sut = RecipeCardViewModel(summary: .dummy(id: "rcp-042"))

    #expect(sut.id == "rcp-042")
  }
}
