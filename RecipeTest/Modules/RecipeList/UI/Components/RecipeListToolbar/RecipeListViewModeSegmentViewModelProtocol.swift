//
//  RecipeListViewModeSegmentViewModelProtocol.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

nonisolated protocol RecipeListViewModeSegmentViewModelProtocol: Identifiable {
  var id: RecipeListViewMode { get }
  var label: LocalizedStringResource { get }
  var symbolName: String { get }
  var foregroundColorStyle: Color.ThemeColor { get }
  var showsIndicator: Bool { get }

  /// Not derived from the label: an identifier a flow selects on must not move with the copy.
  var accessibilityIdentifier: String { get }

  var mode: RecipeListViewMode { get }
}
