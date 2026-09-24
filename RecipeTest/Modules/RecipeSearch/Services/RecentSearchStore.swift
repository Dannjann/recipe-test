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
  /// A client rather than `UserDefaults` itself: this type owns the ordering and de-duplication
  /// rules, and knows nothing about where the array ends up.
  private let store: KeyValueStoreClientProtocol

  init(store: KeyValueStoreClientProtocol) {
    self.store = store
  }
}

// MARK: - Getters

extension RecentSearchStore {
  var searches: [String] {
    store.stringArray(forKey: storageKey) ?? []
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

    store.set(
      Array(recorded.prefix(limit)),
      forKey: storageKey
    )
  }

  func clear() {
    store.removeObject(forKey: storageKey)
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
