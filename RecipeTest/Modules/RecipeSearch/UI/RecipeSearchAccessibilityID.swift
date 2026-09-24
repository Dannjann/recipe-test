//
//  RecipeSearchAccessibilityID.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

/// Every identifier the search overlay puts on screen, in one place.
///
/// The Maestro flows in `.maestro/` select on these strings, so they are API: changing a value
/// here breaks a flow, and a flow that breaks silently passes for the wrong reason. Keeping
/// them together is what makes that cost visible when one is edited.
nonisolated enum RecipeSearchAccessibilityID {
  static var closeButton: String {
    "recipe-search-close-button"
  }

  static var fieldButton: String {
    "recipe-search-field-button"
  }

  static var fieldClearButton: String {
    "recipe-search-field-clear-button"
  }

  /// The zoom transition's source, rather than something a flow selects.
  static var queryField: String {
    "recipe-search-query-field"
  }

  static var vegetarianToggle: String {
    "recipe-search-vegetarian-toggle"
  }

  static var stepsToggle: String {
    "recipe-search-steps-toggle"
  }

  static var includeField: String {
    "recipe-search-include-field"
  }

  static var includeAddButton: String {
    "recipe-search-include-add-button"
  }

  static var excludeField: String {
    "recipe-search-exclude-field"
  }

  static var excludeAddButton: String {
    "recipe-search-exclude-add-button"
  }

  static var clearAllButton: String {
    "recipe-search-clear-all-button"
  }

  static var submitButton: String {
    "recipe-search-submit-button"
  }

  static var inputBackButton: String {
    "recipe-search-input-back-button"
  }

  static var inputField: String {
    "recipe-search-input-field"
  }
}

// MARK: - Composed

nonisolated extension RecipeSearchAccessibilityID {
  static func includeChipRemoveButton(_ ingredient: String) -> String {
    "recipe-search-include-chip-\(ingredient)-remove-button"
  }

  static func excludeChipRemoveButton(_ ingredient: String) -> String {
    "recipe-search-exclude-chip-\(ingredient)-remove-button"
  }

  /// Takes the suffix rather than the servings value: "6+" would put a character into an
  /// identifier a selector has to escape.
  static func servingsOption(suffix: String) -> String {
    "recipe-search-servings-option-\(suffix)"
  }

  static func suggestionRow(id: String) -> String {
    "recipe-search-suggestion-\(id)"
  }
}
