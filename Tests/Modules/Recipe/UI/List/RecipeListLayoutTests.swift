//
//  RecipeListLayoutTests.swift
//  Tests
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation
@testable import RecipeTest
import SwiftUI
import Testing

struct RecipeListLayoutTests {
  @Test
  func list_isASingleColumn() {
    #expect(RecipeListLayout.list.columns.count == 1)
  }

  @Test
  func grid_isOneAdaptiveColumnAtTheMinimumCardWidth() {
    let columns = RecipeListLayout.grid.columns

    #expect(columns.count == 1)

    guard case let .adaptive(minimum, _) = columns.first?.size else {
      Issue.record("Expected the grid to be laid out adaptively")

      return
    }

    #expect(minimum == RecipeListLayout.gridMinimumCardWidth)
  }

  /// The toggle is meaningless if the narrowest phone we support cannot fit two cards.
  @Test
  func grid_fitsTwoColumnsOnTheNarrowestSupportedWidth() {
    let narrowestScreenWidth: CGFloat = 320
    let available = narrowestScreenWidth - RecipeListLayout.spacing * 2
    let twoColumns = RecipeListLayout.gridMinimumCardWidth * 2 + RecipeListLayout.spacing

    #expect(twoColumns <= available)
  }

  @Test
  func toggled_roundTripsBackToItself() {
    #expect(RecipeListLayout.list.toggled == .grid)
    #expect(RecipeListLayout.grid.toggled == .list)
    #expect(RecipeListLayout.list.toggled.toggled == .list)
  }

  @Test
  func loadState_distinguishesFailureMessages() {
    #expect(RecipeListLoadState.failed("a") != RecipeListLoadState.failed("b"))
    #expect(RecipeListLoadState.loaded == RecipeListLoadState.loaded)
  }
}
