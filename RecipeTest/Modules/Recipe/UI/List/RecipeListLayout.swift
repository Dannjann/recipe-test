//
//  RecipeListLayout.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

/// How the recipe list arranges its cards.
///
/// A view concern, deliberately not a domain model: nothing in the service or model layer
/// has any reason to know the screen has two modes.
///
/// Both modes are the same `LazyVGrid` with a different column count, which is what lets
/// the screen keep its scroll position across a toggle — swapping in a structurally
/// different container would rebuild the scroll view and lose it.
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

  /// The mode this one switches to. The toolbar button is labelled for its destination,
  /// not its current state.
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
