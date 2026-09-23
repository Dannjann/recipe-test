//
//  RecipeListLayoutTests.swift
//  Tests
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation
@testable import RecipeTest
import Testing

struct RecipeListLayoutTests {
  @Test
  func list_isASingleColumn() {
    #expect(RecipeListLayout.list.columns.count == 1)
  }

  @Test
  func grid_isTwoColumns() {
    #expect(RecipeListLayout.grid.columns.count == 2)
  }

  /// The toolbar button shows the layout you would switch *to*, so this has to be an
  /// involution — toggling twice is the identity.
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
