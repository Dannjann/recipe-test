//
//  MockEndpoint.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

/// One case per endpoint the mock transport knows how to answer.
///
/// Add a case and a fixture file when you add an endpoint; an unmatched path deliberately
/// produces a 404 rather than silently succeeding, so a typo in a resource path fails the
/// same way it would against a real backend.
///
/// The base project ships only the image case — a feature module adds its own:
///
///     case catalog
///
/// matched on its resource name below, with `catalog.json` in `Resources/MockData` and
/// `isPaginated` set to whether the endpoint pages.
nonisolated enum MockEndpoint: Equatable {
  /// A placeholder photo. The seed is the filename, so a given URL gets a stable image.
  case image(seed: String)

  /// Matches on the trailing path components, so the versioned prefix (`/api/v1/...`)
  /// does not have to be repeated here.
  static func match(path: String, method: String) -> MockEndpoint? {
    let components = path.split(separator: "/").map(String.init)
    let resource = components.last ?? ""

    guard method.uppercased() == "GET" else { return nil }

    if components.dropLast().last == "images" {
      return .image(seed: (resource as NSString).deletingPathExtension)
    }

    // switch resource {
    // case "catalog":
    //   return .catalog
    //
    // default:
    //   return nil
    // }

    return nil
  }

  var fixtureName: String? {
    switch self {
    case .image:
      nil
    }
  }

  var isPaginated: Bool {
    switch self {
    case .image:
      false
    }
  }

  var contentType: String {
    switch self {
    case .image:
      "image/png"
    }
  }
}
