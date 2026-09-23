//
//  APIClientProtocol.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2020 Danjan. All rights reserved.
//

import Foundation

nonisolated enum HTTPRequestHeaderContentType: String {
  case json = "application/json"
  case urlEncoded = "application/x-www-form-urlencoded"
}

nonisolated protocol APIClientProtocol: AppServiceProtocol, Sendable {
  var baseURL: URL { get }
  var version: String { get }

  func reset()
}

nonisolated extension APIClientProtocol {
  func endpointURL(
    _ resourcePath: String,
    version: String? = nil
  ) -> URL {
    baseURL.appendingPathComponent("\(version ?? self.version)/\(resourcePath)")
  }
}

nonisolated protocol APIClientFailedRequestInfoType: Sendable {
  var status: HTTPStatusCode { get }

  var message: String { get }

  var errorCode: APIErrorCode { get }
}

// MARK: - APIClientError

nonisolated enum APIClientError: Error {
  case failedRequest(APIClientFailedRequestInfoType)
  case dataNotFound(_ expectedType: Any.Type)
  case unparseableData(_ dataString: String)
  case unknown
}

nonisolated extension APIClientError: LocalizedError {
  var errorDescription: String? {
    switch self {
    case let .failedRequest(info):
      info.message
    case .dataNotFound:
      String(localized: .Core.coreErrorDataNotFound)
    case .unparseableData:
      String(localized: .Core.coreErrorParseFailed)
    default:
      String(localized: .Core.coreErrorUnknown)
    }
  }

  var failureReason: String? {
    switch self {
    case let .failedRequest(info):
      String(localized: .Core.coreErrorHttpStatus(String(describing: info.status), info.message))
    case let .dataNotFound(type):
      String(localized: .Core.coreErrorExpectedGotNil(String(describing: type)))
    case let .unparseableData(dataString):
      String(localized: .Core.coreErrorParseFailedDetail(dataString))
    default:
      String(localized: .Core.coreErrorUnknown)
    }
  }
}
