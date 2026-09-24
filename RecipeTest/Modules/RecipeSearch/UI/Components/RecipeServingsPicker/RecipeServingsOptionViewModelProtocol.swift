//
//  RecipeServingsOptionViewModelProtocol.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

/// One option in the servings picker.
///
/// A type per state rather than one type carrying `isSelected`: selection changes only what the
/// option paints and how it reads to VoiceOver, so each state answers for itself and the view
/// is left with nothing to decide.
nonisolated protocol RecipeServingsOptionViewModelProtocol: Identifiable {
  var servings: RecipeServings { get }

  var backgroundColorStyle: Color.ThemeColor { get }
  var labelColorStyle: Color.ThemeColor { get }

  /// Carries `.isSelected` or not, so the picker applies traits rather than deriving them.
  var accessibilityTraits: AccessibilityTraits { get }
}

// MARK: - Getters

nonisolated extension RecipeServingsOptionViewModelProtocol {
  var id: RecipeServings {
    servings
  }

  /// `RecipeServings.rawValue` is already the display string — "1", "2", "4", "6+".
  var label: String {
    servings.rawValue
  }

  var accessibilityLabel: String {
    String(localized: .RecipeSearch.recipeSearchServingsAccessibilityLabel(servings.rawValue))
  }

  /// Not derived from the label: an identifier a flow selects on must not move with the copy.
  var accessibilityIdentifier: String {
    RecipeSearchAccessibilityID.servingsOption(suffix: identifierSuffix)
  }
}

// MARK: - Getters > Private

private nonisolated extension RecipeServingsOptionViewModelProtocol {
  /// "6+" would put a character into an identifier a selector has to escape.
  var identifierSuffix: String {
    servings == .sixOrMore ? "6-plus" : servings.rawValue
  }
}
