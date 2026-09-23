//
//  Model.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2019 Danjan. All rights reserved.
//

import Foundation

nonisolated protocol Model {
  /// Returns a **JSONDecoder** instance that's configured for the conforming type.
  static func decoder() -> JSONDecoder

  /// Returns a **JSONEncoder** instance that's configured for the conforming type.
  static func encoder() -> JSONEncoder
}

// MARK: - Decodable

nonisolated extension Model where Self: Decodable {
  static func decoder() -> JSONDecoder {
    JSONDecoder()
  }

  static func decode(_ data: Data) throws -> Self {
    try decoder().decode(self, from: data)
  }

  static func decode(_ dictionary: [String: Any]) throws -> Self {
    try decode(JSONSerialization.data(withJSONObject: dictionary))
  }
}

// MARK: - APIModel

nonisolated protocol APIModel: Model {}

nonisolated extension APIModel {
  static func decoder() -> JSONDecoder {
    // You can set your preferred decoding strategies here.
    let d = JSONDecoder()
    d.dateDecodingStrategy = .formatted(.iso8601)
    d.keyDecodingStrategy = .convertFromSnakeCase
    return d
  }

  static func encoder() -> JSONEncoder {
    // You can set your preferred encoding strategies here.
    let e = JSONEncoder()
    e.dateEncodingStrategy = .formatted(.iso8601)
    e.keyEncodingStrategy = .convertToSnakeCase
    return e
  }
}

/// Just a stand-in model for us to access the static **APIModel**
/// functions like `decoder()` and `encoder()`.
nonisolated struct GenericAPIModel: APIModel {}

// MARK: - APIRequestParameters

/// A Model type that is intended for parameterized API endpoint wrapper methods. Specifically,
/// those methods that have more than two non-Closure parameters.
nonisolated protocol APIRequestParameters: APIModel, Codable {}
