//
//  KeyValueStoreClientProtocol.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

/// The slice of a key-value store the app actually uses.
///
/// Exists so services never speak to `UserDefaults` directly. A store is a library like any
/// other, so it belongs behind a client; a service that knew about `UserDefaults` could not be
/// pointed at anything else without being rewritten.
@MainActor
protocol KeyValueStoreClientProtocol: AnyObject {
  func stringArray(forKey key: String) -> [String]?
  func set(_ value: [String], forKey key: String)
  func removeObject(forKey key: String)
}
