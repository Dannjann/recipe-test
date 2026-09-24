//
//  RecipeSuggestionRowViewModelProtocol.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

/// One row the search field can offer.
///
/// A type per kind of row rather than one type switching over a kind: each conformer answers
/// for itself, so adding a kind is a new file rather than a new case in five getters.
nonisolated protocol RecipeSuggestionRowViewModelProtocol: Identifiable {
  var id: String { get }
  var title: String { get }
  var detail: String { get }
  var imageURL: URL? { get }

  /// Stands in where there is no photograph — a recent search has none, neither does the row
  /// offering back what is being typed, and a category or recipe may simply be missing one.
  var symbolName: String { get }

  /// What picking this row means to the screen that pushed the typing screen. Answered by the
  /// row rather than decided by a switch somewhere else.
  var selection: RecipeSearchInputSelection { get }
}

// MARK: - Getters

nonisolated extension RecipeSuggestionRowViewModelProtocol {
  var accessibilityIdentifier: String {
    RecipeSearchAccessibilityID.suggestionRow(id: id)
  }

  /// Everything the row paints, in one comparable value.
  ///
  /// `SectionState` is `Equatable` so SwiftUI can leave an untouched section alone, and an
  /// array of existentials has no synthesised `==` to give it.
  var renderedIdentity: String {
    [
      id,
      title,
      detail,
      imageURL?.absoluteString ?? "",
      symbolName,
    ]
    .joined(separator: fieldSeparator)
  }
}

// MARK: - Getters > Constants

private nonisolated extension RecipeSuggestionRowViewModelProtocol {
  /// A unit separator, so a title carrying the delimiter cannot forge a match against a
  /// different row whose fields happen to concatenate the same way.
  var fieldSeparator: String {
    "\u{1F}"
  }
}
