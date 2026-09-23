//
//  MockURLProtocol.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

/// Intercepts requests below Alamofire and answers them from bundled JSON.
///
/// Everything above this class runs unmodified — header construction, status-code
/// handling, `APIResponse` envelope decoding and error mapping all behave exactly as they
/// would against a real server. Only the socket is missing.
final nonisolated class MockURLProtocol: URLProtocol {
  /// Set once at launch, before any request is issued. `nonisolated(unsafe)` because
  /// `URLProtocol` is configured at the class level and `URLSession` builds instances on
  /// its own queues; the value is written once during bootstrap and only read thereafter.
  nonisolated(unsafe) static var router = MockAPIRouter()

  private var isCancelled = false

  override class func canInit(with request: URLRequest) -> Bool {
    true
  }

  override class func canonicalRequest(for request: URLRequest) -> URLRequest {
    request
  }

  override func startLoading() {
    let router = Self.router
    let latency = router.configuration.latency

    // Delivered on a background queue after the configured latency, so the app sees a
    // real loading state rather than an instantaneous response.
    let deadline: DispatchTime = .now() + .milliseconds(latency.milliseconds)

    DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: deadline) { [weak self] in
      guard let self, !isCancelled else { return }

      deliver(using: router)
    }
  }

  override func stopLoading() {
    isCancelled = true
  }
}

// MARK: - Delivery

private nonisolated extension MockURLProtocol {
  func deliver(using router: MockAPIRouter) {
    do {
      let result = try router.response(for: request)

      guard
        let url = request.url,
        let response = HTTPURLResponse(
          url: url,
          statusCode: result.status,
          httpVersion: "HTTP/1.1",
          headerFields: ["Content-Type": result.contentType]
        )
      else {
        client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
        return
      }

      client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
      client?.urlProtocol(self, didLoad: result.body)
      client?.urlProtocolDidFinishLoading(self)
    } catch {
      client?.urlProtocol(self, didFailWithError: error)
    }
  }
}

// MARK: - Duration

private nonisolated extension Duration {
  /// `DispatchTime` needs an integer offset; `Duration` only exposes its parts.
  var milliseconds: Int {
    let (seconds, attoseconds) = components

    return Int(seconds * 1000) + Int(attoseconds / 1_000_000_000_000_000)
  }
}
