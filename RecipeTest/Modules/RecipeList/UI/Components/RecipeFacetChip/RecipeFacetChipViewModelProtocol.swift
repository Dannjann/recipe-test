//
//  RecipeFacetChipViewModelProtocol.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

nonisolated protocol RecipeFacetChipViewModelProtocol: Identifiable {
  var id: RecipeQueryFacet { get }
  var label: String { get }
  var removeAccessibilityLabel: String { get }

  var backgroundColorStyle: Color.ThemeColor { get }

  /// Not derived from the label: an identifier a flow selects on must not move with the copy.
  var accessibilityIdentifier: String { get }
}
