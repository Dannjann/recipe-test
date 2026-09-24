//
//  RecipeListViewModeSegmentViewModel.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

nonisolated struct RecipeListViewModeSegmentViewModel: RecipeListViewModeSegmentViewModelProtocol, Equatable {
  let mode: RecipeListViewMode
  let isSelected: Bool
}

// MARK: - Getters

nonisolated extension RecipeListViewModeSegmentViewModel {
  var id: RecipeListViewMode {
    mode
  }

  var label: LocalizedStringResource {
    switch mode {
    case .grid:
      .RecipeList.recipeListViewModeGrid

    case .list:
      .RecipeList.recipeListViewModeList
    }
  }

  var symbolName: String {
    switch mode {
    case .grid:
      "square.grid.2x2"

    case .list:
      "list.bullet"
    }
  }

  var foregroundColorStyle: Color.ThemeColor {
    isSelected ? .textInverted : .textPrimary
  }

  var showsIndicator: Bool {
    isSelected
  }

  var accessibilityIdentifier: String {
    "recipe-list-view-mode-\(identifierSuffix)-button"
  }
}

// MARK: - Getters > Constants

private nonisolated extension RecipeListViewModeSegmentViewModel {
  var identifierSuffix: String {
    switch mode {
    case .grid:
      "grid"

    case .list:
      "list"
    }
  }
}
