//
//  RecentSearchStore.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

@MainActor
final class RecentSearchStore: RecentSearchStoreProtocol {
  /// Injected rather than reached for inside, which is the whole of this type's test seam: a
  /// test hands it a throwaway suite instead of writing into whatever is installed.
  private let defaults: UserDefaults

  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
  }
}

// MARK: - Getters

extension RecentSearchStore {
  var searches: [String] {
    defaults.stringArray(forKey: storageKey) ?? []
  }
}

// MARK: - Inputs

extension RecentSearchStore {
  func record(_ text: String) {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

    guard !trimmed.isEmpty else { return }

    // Case-insensitively: "Adobo" searched after "adobo" is the same search, and two
    // spellings of one term would spend two of the four rows the list has to offer.
    var recorded = searches.filter { $0.caseInsensitiveCompare(trimmed) != .orderedSame }
    recorded.insert(
      trimmed,
      at: 0
    )

    defaults.set(
      Array(recorded.prefix(limit)),
      forKey: storageKey
    )
  }

  func clear() {
    defaults.removeObject(forKey: storageKey)
  }
}

// MARK: - Getters > Constants

private extension RecentSearchStore {
  var storageKey: String {
    "recipeSearch.recentSearches"
  }

  var limit: Int {
    10
  }
}
