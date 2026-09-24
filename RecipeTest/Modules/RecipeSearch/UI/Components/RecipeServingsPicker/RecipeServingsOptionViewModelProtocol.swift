//
//  RecipeServingsOptionViewModelProtocol.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

nonisolated protocol RecipeServingsOptionViewModelProtocol: Identifiable {
  var id: RecipeServings { get }
  var label: String { get }
  var isSelected: Bool { get }
  var accessibilityLabel: String { get }

  /// Not derived from the label: an identifier a flow selects on must not move with the copy.
  var accessibilityIdentifier: String { get }
}
