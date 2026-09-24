//
//  RecipeIngredientChipViewModelProtocol.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

nonisolated protocol RecipeIngredientChipViewModelProtocol: Identifiable {
  var id: String { get }
  var label: String { get }
  var removeAccessibilityLabel: String { get }

  var backgroundColorStyle: Color.ThemeColor { get }
  var accessibilityIdentifier: String { get }
}
