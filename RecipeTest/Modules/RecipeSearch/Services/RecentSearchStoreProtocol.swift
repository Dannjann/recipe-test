//
//  RecentSearchStoreProtocol.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

/// What the search field's idle state reads, and what the Search button writes to.
///
/// The project's first persistence, kept deliberately small: one array of strings under one
/// key, no model and no migration story.
@MainActor
protocol RecentSearchStoreProtocol: AppServiceProtocol {
  var searches: [String] { get }

  func record(_ text: String)
  func clear()
}
