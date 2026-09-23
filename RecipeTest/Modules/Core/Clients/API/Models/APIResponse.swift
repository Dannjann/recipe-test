//
//  APIResponse.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2018 Danjan. All rights reserved.
//

import Foundation

/// An object representation of the server's JSON response.
nonisolated struct APIResponse {
  /// Intentionally set to Optional-Any as it could be of any type or just be nil.
  /// It's up to the call site to determine the exact type of its value.
  /// If it's a Decodable type, use the method `decodedValue(forKeyPath:decoder:)`.
  var data: Any?
  var meta: Any?

  /// The response's status.
  ///
  /// Read from the envelope's `http_status` when the backend sends one; otherwise
  /// `APIClient` fills it in from the transport after decoding. See
  /// `carriesEnvelopeStatus`.
  var statusCode: HTTPStatusCode

  /// Whether `statusCode` came from the body rather than from the HTTP response.
  ///
  /// The envelope keys below (`http_status`, `error_code`, `message`, `errors`) describe
  /// one backend convention, not every backend. Decoding treats all of them as optional so
  /// a plain-JSON API still parses; this flag is what lets `APIClient` tell "the body said
  /// 422" from "the body said nothing and the transport said 422".
  private(set) var carriesEnvelopeStatus: Bool

  /// Could be a success or an error message depending on the type of result.
  var message: String?
  var errorCode: APIErrorCode = .default

  var errors: [String: [String]]?

  /// A response with no body — a 204, or any status the transport reported before there
  /// was anything to decode.
  init(statusCode: HTTPStatusCode) {
    self.statusCode = statusCode
    carriesEnvelopeStatus = false
  }
}

nonisolated extension APIResponse: Decodable {
  enum CodingKeys: String, CodingKey {
    case data
    case meta
    case message
    case errors
    case statusCode = "http_status"
    case errorCode = "error_code"
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    data = try (container.decodeIfPresent(AnyDecodable.self, forKey: .data))?.value
    meta = try (container.decodeIfPresent(AnyDecodable.self, forKey: .meta))?.value
    message = try container.decodeIfPresent(String.self, forKey: .message)
    errors = try container.decodeIfPresent([String: [String]].self, forKey: .errors)
    errorCode = (try? container.decode(APIErrorCode.self, forKey: .errorCode)) ?? .default

    let envelopeStatus = try container.decodeIfPresent(HTTPStatusCode.self, forKey: .statusCode)
    statusCode = envelopeStatus ?? .ok
    carriesEnvelopeStatus = envelopeStatus != nil
  }
}

// MARK: - Helpers

nonisolated extension APIResponse {
  /// Decodes the contents of the `data` property, if available, into its inferred Decodable type.
  ///
  /// Sample usage:
  ///
  ///     // Single object:
  ///     // {
  ///     //   "status": 200,
  ///     //   "data": {
  ///     //     "post_id": "xyz123", "title": "...", ...
  ///     //   }
  ///     // }
  ///     let post: Post! = instance.decodedValue()
  ///
  ///     // Array of objects:
  ///     // {
  ///     //   "status": 200,
  ///     //   "data": {
  ///     //     "posts": [{...}, {...}, ...]
  ///     //   }
  ///     // }
  ///     let posts: [Post]? = instance.decodedValue(forKeyPath: "posts")
  ///
  /// - parameter forKeyPath: Specify as needed. This only works with Dictionary types.
  ///       If nil, assumes `data` is for the inferred decodable type.
  /// - parameter decoder: A pre-configured JSONDecoder instance. Defaults to `GenericAPIModel`s decoder.
  ///
  /// - returns: The decoded value or nil.
  func decodedValue<T: Decodable>(forKeyPath: String? = nil, decoder: JSONDecoder? = nil) throws -> T? {
    guard var payload = data else { return nil }

    if let keyPath = forKeyPath {
      guard let d = nestedData(keyPath) else { return nil }
      payload = d
    }

    guard JSONSerialization.isValidJSONObject(payload) else {
      debugLog("payload: \(String(describing: payload))")
      guard let val = payload as? T else { return nil }
      return val
    }

    let json = try JSONSerialization.data(withJSONObject: payload)
    return try (decoder ?? GenericAPIModel.decoder()).decode(T.self, from: json)
  }

  func decodeMeta<T: Decodable>(decoder: JSONDecoder? = nil) throws -> T? {
    guard let meta else { return nil }

    guard JSONSerialization.isValidJSONObject(meta) else {
      guard let val = meta as? T else { return nil }
      return val
    }

    let json = try JSONSerialization.data(withJSONObject: meta)
    return try (decoder ?? GenericAPIModel.decoder()).decode(T.self, from: json)
  }

  /// Returns the data at the given `keyPath`. Nil if path doesn't exist.
  private func nestedData(_ keyPath: String) -> Any? {
    guard let payload = data, !keyPath.isEmpty else { return nil }
    guard let dict = payload as? [String: Any] else { return nil }
    return dict[keyPath: keyPath] as Any
  }
}
