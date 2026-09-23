//
//  APIClient.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2018 Danjan. All rights reserved.
//

import Alamofire
import Foundation

/// Request parameters as they cross into the networking layer.
///
/// Mirrors Alamofire's `Parameters` (`[String: any Any & Sendable]`) so feature code can
/// build request parameters without importing Alamofire.
typealias RequestParameters = Parameters

nonisolated struct APIClientFailedRequestInfo: APIClientFailedRequestInfoType {
  let status: HTTPStatusCode
  let message: String
  let errorCode: APIErrorCode
}

final nonisolated class APIClient: APIClientProtocol {
  let sessionManager: Alamofire.Session
  let baseURL: URL
  let version: String

  let onError: SendableErrorResult

  init(
    sessionManager: Alamofire.Session = .default,
    baseURL: URL,
    version: String,
    onError: @escaping SendableErrorResult
  ) {
    self.sessionManager = sessionManager
    self.baseURL = baseURL
    self.version = version
    self.onError = onError
  }

  func reset() {
    // Cancel all inflight and queued network requests.
    sessionManager.session.getAllTasks { tasks in
      tasks.forEach { $0.cancel() }
    }
  }

  /// Returns the default set of HTTP headers.
  ///
  /// - parameter contentType: The type of data sent in requests such as POST and PUT.
  /// - parameter additionalHeaders: Your custom headers.
  ///
  func httpRequestHeaders(
    contentType: HTTPRequestHeaderContentType = .json,
    additionalHeaders: HTTPHeaders? = nil
  ) -> HTTPHeaders {
    var headers = HTTPHeaders.default
    headers.add(.contentType(contentType.rawValue))

    if contentType == .json {
      headers.add(.accept(contentType.rawValue))
    }

    additionalHeaders?.forEach { newHeader in
      headers.add(newHeader)
    }

    return headers
  }
}

nonisolated extension APIClient {
  @discardableResult
  func request(
    _ resourcePath: String,
    method: HTTPMethod = .get,
    version: String? = nil,
    parameters: RequestParameters? = nil,
    encoding: ParameterEncoding = URLEncoding.default,
    headers: HTTPHeaders? = nil
  ) async throws -> APIResponse {
    let requestUrl = endpointURL(resourcePath, version: version)
    let request = sessionManager.request(
      requestUrl,
      method: method,
      parameters: parameters,
      encoding: encoding,
      headers: headers ?? httpRequestHeaders()
    )

    do {
      return try await request.apiResponse()
    } catch {
      onError(error)
      throw error
    }
  }
}

// MARK: - Alamofire.DataRequest

nonisolated extension DataRequest {
  /// Parses the response on whatever queue Alamofire completed on, then hands back a
  /// `Result`. Both entry points below funnel through it so the callback and async paths
  /// cannot drift apart — they previously disagreed about 204s.
  @discardableResult
  func apiResponse(
    queue: DispatchQueue = .main,
    completion: @escaping SendableSingleResult<Result<APIResponse, any Error>>
  ) -> DataRequest {
    responseData(queue: queue) { response in
      completion(Self.parse(response))
    }
  }

  @discardableResult
  func apiResponse(queue: DispatchQueue = .main) async throws -> APIResponse {
    try await withCheckedThrowingContinuation { continuation in
      responseData(queue: queue) { response in
        continuation.resume(with: Self.parse(response))
      }
    }
  }

  /// The single place a raw Alamofire response becomes an `APIResponse` or an error.
  ///
  /// Internal rather than private so the status-handling rules below can be tested against
  /// a constructed `AFDataResponse` instead of a live socket. Not part of the API any
  /// feature code should call — go through `apiResponse()`.
  static func parse(_ response: AFDataResponse<Data>) -> Result<APIResponse, any Error> {
    if case let .failure(error) = response.result {
      if let urlError = error.underlyingError as? URLError, urlError.code == .notConnectedToInternet {
        return .failure(AppError.noInternetConnection)
      }

      return .failure(error)
    }

    // Not force-unwrapped: a response can complete without an `HTTPURLResponse` behind it.
    // Mapped with `nearestTo:` rather than `rawValue:` — the enum does not list every
    // status a deployment emits, and an unlisted one coming back `nil` was indistinguishable
    // from "this response carried no status at all".
    let transportCode = response.response.flatMap { HTTPStatusCode(nearestTo: $0.statusCode) }
    let transportFailed = transportCode?.isFailure ?? false

    // Checked before decoding — a 204 body is empty, and decoding it would fail first.
    if transportCode == .noContent {
      return .success(APIResponse(statusCode: .noContent))
    }

    guard let responseData = response.value else {
      guard let transportCode, transportFailed else {
        return .failure(APIClientError.dataNotFound(Data.self))
      }

      return .failure(Self.failedRequest(status: transportCode, body: nil))
    }

    let decoded: APIResponse

    do {
      decoded = try JSONDecoder().decode(APIResponse.self, from: Self.utf8Data(from: responseData))
    } catch {
      // A failing status whose body is not the envelope — an edge proxy's HTML error page,
      // say. The status is the useful part of that response; reporting the `DecodingError`
      // instead loses it and tells the caller the wrong thing went wrong.
      guard let transportCode, transportFailed else { return .failure(error) }

      return .failure(Self.failedRequest(status: transportCode, body: nil))
    }

    var resp = decoded

    // A backend that does not wrap its responses sends no `http_status`; the transport
    // is then the only source of truth for the status.
    if !resp.carriesEnvelopeStatus, let transportCode {
      resp.statusCode = transportCode
    }

    // Both layers are checked, and the envelope is not merely a fallback for a missing
    // transport status. A backend answering HTTP 200 with `{"http_status": 422, ...}` is
    // reporting a failed request — reading only the transport, which is what almost every
    // response has, handed exactly that case back to the caller as a success.
    let envelopeCode = resp.carriesEnvelopeStatus ? resp.statusCode : nil

    guard let failure = [transportCode, envelopeCode].compactMap(\.self).first(where: \.isFailure) else {
      return .success(resp)
    }

    return .failure(Self.failedRequest(status: failure, body: resp))
  }

  /// `body` is nil when there was nothing decodable to read a message out of.
  private static func failedRequest(status: HTTPStatusCode, body: APIResponse?) -> APIClientError {
    let info = APIClientFailedRequestInfo(
      status: status,
      message: body?.message ?? String(localized: .Core.coreErrorUnknownApplication),
      errorCode: body?.errorCode ?? .default
    )

    return .failedRequest(info)
  }

  private static func utf8Data(from data: Data) throws -> Data {
    let encoding = Self.detectEncoding(of: data)
    guard encoding != .utf8 else { return data }
    guard let responseString = String(data: data, encoding: encoding) else {
      throw UTF8ConversionError.stringConversionFailed(encoding: encoding)
    }
    guard let utf8Data = responseString.data(using: .utf8) else {
      throw UTF8ConversionError.utf8ConversionFailed
    }
    return utf8Data
  }

  static func detectEncoding(of data: Data) -> String.Encoding {
    if String(data: data, encoding: .utf8) != nil {
      return .utf8
    }

    var convertedString: NSString?
    let encodingRaw = NSString.stringEncoding(
      for: data,
      encodingOptions: [StringEncodingDetectionOptionsKey.suggestedEncodingsKey: [String.Encoding.utf8.rawValue]],
      convertedString: &convertedString,
      usedLossyConversion: nil
    )

    // If detection fails, NSString returns 0 which maps to an invalid String.Encoding.
    // Prefer UTF-8 as a safe default for most web APIs.
    guard encodingRaw != 0 else {
      return .utf8
    }

    return String.Encoding(rawValue: encodingRaw)
  }
}
