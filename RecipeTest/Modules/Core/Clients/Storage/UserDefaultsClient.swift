//
//  UserDefaultsClient.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

/// The only type in the app that knows `UserDefaults` exists.
///
/// The suite is injected rather than reached for inside, which is this type's test seam: a test
/// hands it a throwaway suite instead of writing into whatever is installed on the machine.
@MainActor
final class UserDefaultsClient: KeyValueStoreClientProtocol {
  private let defaults: UserDefaults

  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
  }
}

// MARK: - Reads

extension UserDefaultsClient {
  func stringArray(forKey key: String) -> [String]? {
    defaults.stringArray(forKey: key)
  }
}

// MARK: - Writes

extension UserDefaultsClient {
  func set(
    _ value: [String],
    forKey key: String
  ) {
    defaults.set(
      value,
      forKey: key
    )
  }

  func removeObject(forKey key: String) {
    defaults.removeObject(forKey: key)
  }
}
