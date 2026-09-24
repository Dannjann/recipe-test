//
//  MockRecentSearchStore.swift
//  Tests
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation
@testable import RecipeTest

/// `recorded` is kept beside `searches` so a test can assert what was written without
/// depending on the ordering and de-duplication the real store applies on the way in.
@MainActor
final class MockRecentSearchStore: RecentSearchStoreProtocol {
  private(set) var recorded: [String] = []

  var searches: [String] = []
}

// MARK: - RecentSearchStoreProtocol

extension MockRecentSearchStore {
  func record(_ text: String) {
    recorded.append(text)
    searches.insert(
      text,
      at: 0
    )
  }

  func clear() {
    searches = []
  }
}
