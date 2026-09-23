//
//  RecipeListLayout.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

nonisolated enum RecipeListLayout: CaseIterable, Equatable {
  case list
  case grid
}

// MARK: - Getters

nonisolated extension RecipeListLayout {
  var columns: [GridItem] {
    switch self {
    case .list:
      [GridItem(.flexible(), spacing: Self.spacing)]
    case .grid:
      [
        GridItem(.flexible(), spacing: Self.spacing),
        GridItem(.flexible(), spacing: Self.spacing),
      ]
    }
  }

  var toggled: Self {
    switch self {
    case .list: .grid
    case .grid: .list
    }
  }

  static var spacing: CGFloat {
    12
  }
}
