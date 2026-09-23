//
//  FixtureLoader.swift
//  Tests
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation
@testable import RecipeTest
import Testing

/// Loads a JSON fixture from the test bundle.
///
/// Fixtures are named `<SuiteName>_<statusCode>[_<variant>].json` and live next to the
/// suite that uses them.
enum Fixture {
  static func data(_ name: String) throws -> Data {
    let url = try #require(
      Bundle(for: BundleToken.self).url(forResource: name, withExtension: "json"),
      "Missing fixture: \(name).json"
    )

    return try Data(contentsOf: url)
  }

  static func apiResponse(_ name: String) throws -> APIResponse {
    try JSONDecoder().decode(APIResponse.self, from: data(name))
  }

  private final class BundleToken {}
}
