//
//  RecipeSuggestionRowViewModelProtocol.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

nonisolated protocol RecipeSuggestionRowViewModelProtocol: Identifiable {
  var id: String { get }
  var title: String { get }
  var detail: String { get }
  var imageURL: URL? { get }

  /// Stands in where there is no photograph — a recent search has none, and neither does the
  /// row offering back what is being typed.
  var symbolName: String? { get }
  var accessibilityIdentifier: String { get }
}
