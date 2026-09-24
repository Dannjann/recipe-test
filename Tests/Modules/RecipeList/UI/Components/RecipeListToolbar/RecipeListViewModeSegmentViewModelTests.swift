//
//  RecipeListViewModeSegmentViewModelTests.swift
//  Tests
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

@testable import RecipeTest
import SwiftUI
import Testing

struct RecipeListViewModeSegmentViewModelTests {
  @Test
  func showsIndicator_onlyOnTheSelectedSegment() {
    #expect(RecipeListViewModeSegmentViewModel(
      mode: .grid,
      isSelected: true
    ).showsIndicator)

    #expect(RecipeListViewModeSegmentViewModel(
      mode: .grid,
      isSelected: false
    ).showsIndicator == false)
  }

  @Test
  func foregroundColorStyle_invertsOnlyWhileSelected() {
    #expect(RecipeListViewModeSegmentViewModel(
      mode: .list,
      isSelected: true
    ).foregroundColorStyle == .textInverted)

    #expect(RecipeListViewModeSegmentViewModel(
      mode: .list,
      isSelected: false
    ).foregroundColorStyle == .textPrimary)
  }

  /// These exact strings are what `.maestro/switch-result-layout.yaml` taps on.
  @Test
  func accessibilityIdentifier_isTheOneTheFlowsSelectOn() {
    #expect(RecipeListViewModeSegmentViewModel(
      mode: .grid,
      isSelected: false
    ).accessibilityIdentifier == "recipe-list-view-mode-grid-button")

    #expect(RecipeListViewModeSegmentViewModel(
      mode: .list,
      isSelected: false
    ).accessibilityIdentifier == "recipe-list-view-mode-list-button")
  }

  @Test
  func symbolName_differsPerMode() {
    let grid = RecipeListViewModeSegmentViewModel(
      mode: .grid,
      isSelected: false
    )
    let list = RecipeListViewModeSegmentViewModel(
      mode: .list,
      isSelected: false
    )

    #expect(grid.symbolName != list.symbolName)
  }

  @Test
  func identity_isTheModeItself() {
    let sut = RecipeListViewModeSegmentViewModel(
      mode: .list,
      isSelected: false
    )

    #expect(sut.id == .list)
  }
}
