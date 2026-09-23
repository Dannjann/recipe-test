//
//  HTTPStatusCodes.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2019 Danjan. All rights reserved.
//

import Foundation

/// HTTP response status codes indicate whether a specific HTTP request has been
/// successfully completed. Responses are grouped in five classes: informational responses,
/// successful responses, redirects, client errors, and servers errors. The below
/// status codes are defined by [section 10 of RFC 2616](https://tools.ietf.org/html/rfc2616#section-10).
/// You can find an updated specification in [RFC 7231](https://tools.ietf.org/html/rfc7231#section-6.5.1).
///
/// Link: https://developer.mozilla.org/en-US/docs/Web/HTTP/Status
///
nonisolated enum HTTPStatusCode: Int, Codable {
  enum Classification {
    case requestInfo
    case success
    case redirection
    case requestError
    case serverError
  }

  // -- Information Responses

  case `continue` = 100
  case switchingProtocols = 101
  case processing = 102

  // -- Successful Responses

  case ok = 200
  case created = 201
  case accepted = 202
  case nonAuthoritativeInformation = 203
  case noContent = 204
  case resetContent = 205
  case partialContent = 206
  case multiStatus = 207
  case alreadyReported = 208
  case iAmUsed = 226

  // -- Redirection Messages

  case multipleChoices = 300
  case movedPermanently = 301
  case found = 302
  case seeOther = 303
  case notModified = 304
  case useProxy = 305
  case temporaryRedirect = 307
  case permanentRedirect = 308

  // -- Client Error Responses

  case badRequest = 400
  case unauthorized = 401
  case paymentRequired = 402
  case forbidden = 403
  case notFound = 404
  case methodNotAllowed = 405
  case notAcceptable = 406
  case proxyAuthenticationRequired = 407
  case requestTimeout = 408
  case conflict = 409
  case gone = 410
  case lengthRequired = 411
  case preconditionFailed = 412
  case payloadTooLarge = 413
  case requestURITooLong = 414
  case unsupportedMediaType = 415
  case requestedRangeNotSatisfiable = 416
  case expectationFailed = 417
  case iAmATeapot = 418
  case misdirectedRequest = 421
  case unprocessableEntity = 422
  case locked = 423
  case failedDependency = 424
  case upgradeRequired = 426
  case preconditionRequired = 428
  case tooManyRequests = 429
  case requestHeaderFieldsTooLarge = 431
  case connectionClosedWithoutResponse = 444
  case unavailableForLegalReasons = 451
  case clientClosedRequest = 499

  // -- Server Error Responses

  case internalServerError = 500
  case notImplemented = 501
  case badGateway = 502
  case serviceUnavailable = 503
  case gatewayTimeout = 504
  case httpVersionNotSupported = 505
  case variantAlsoNegotiates = 506
  case insufficientStorage = 507
  case loopDetected = 508
  case notExtended = 510
  case networkAuthenticationRequired = 511
  case networkConnectTimeoutError = 599
}

nonisolated extension HTTPStatusCode {
  var classification: Classification {
    switch self {
    case Self.continue ... Self.processing:
      .requestInfo
    case Self.ok ... Self.iAmUsed:
      .success
    case Self.multipleChoices ... Self.permanentRedirect:
      .redirection
    case Self.badRequest ... Self.clientClosedRequest:
      .requestError
    default:
      // Self.internalServerError...Self.networkConnectTimeoutError
      .serverError
    }
  }

  var isSuccess: Bool {
    classification == .success
  }

  var isRequestError: Bool {
    classification == .requestError
  }

  var isServerError: Bool {
    classification == .serverError
  }
}

// MARK: - Comparable

nonisolated extension HTTPStatusCode: Comparable {
  static func < (lhs: HTTPStatusCode, rhs: HTTPStatusCode) -> Bool {
    lhs.rawValue < rhs.rawValue
  }

  static func <= (lhs: HTTPStatusCode, rhs: HTTPStatusCode) -> Bool {
    lhs.rawValue <= rhs.rawValue
  }

  static func >= (lhs: HTTPStatusCode, rhs: HTTPStatusCode) -> Bool {
    lhs.rawValue >= rhs.rawValue
  }

  static func > (lhs: HTTPStatusCode, rhs: HTTPStatusCode) -> Bool {
    lhs.rawValue > rhs.rawValue
  }
}
