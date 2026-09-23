//
//  MockAPICall.swift
//  Tests
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

/// Records the calls made to one endpoint of a mock API, and decides what it answers.
///
/// One of these per endpoint, rather than a flat bag of `xToReturn`, `xCallCount` and
/// `lastRequestedX` properties spread across the mock. That shape buys four things:
///
/// - each endpoint's stub and its recorded calls stay together, so two endpoints cannot
///   overwrite each other's "last requested" state;
/// - one endpoint can be made to fail while its neighbours keep answering;
/// - `responds` is here from the start, so a test needing page 2 to differ from page 1
///   does not get a lookup table bolted onto the mock;
/// - there is no `reset()` to keep in sync — a test builds a fresh mock.
///
/// `@unchecked Sendable` with one lock: the mock conforms to a `Sendable` protocol, and
/// an `async` call may resume on a different thread than it started on.
final class MockAPICall<Request, Response>: @unchecked Sendable {
  private enum Outcome {
    case success(Response)
    case failure(any Error)
    case handler((Request) async throws -> Response)
  }

  private let lock = NSLock()
  private var recorded: [Request] = []
  private var outcome: Outcome

  init(returning response: Response) {
    outcome = .success(response)
  }
}

// MARK: - Recorded calls

extension MockAPICall {
  var requests: [Request] {
    lock.withLock { recorded }
  }

  var callCount: Int {
    requests.count
  }

  var lastRequest: Request? {
    requests.last
  }

  var wasCalled: Bool {
    callCount > 0
  }
}

// MARK: - Stubbing

extension MockAPICall {
  /// Answer every call with this value.
  func returns(_ response: Response) {
    setOutcome(.success(response))
  }

  /// Fail every call with this error. Scoped to this endpoint — a sibling endpoint on the
  /// same mock goes on answering normally.
  func fails(with error: any Error) {
    setOutcome(.failure(error))
  }

  /// Answer each call from the request itself, for a test where the second page has to
  /// differ from the first.
  func responds(_ handler: @escaping (Request) async throws -> Response) {
    setOutcome(.handler(handler))
  }

  private func setOutcome(_ newValue: Outcome) {
    lock.withLock { outcome = newValue }
  }
}

// MARK: - Invocation

extension MockAPICall {
  /// Called by the mock's protocol method: records the request, then answers with
  /// whatever the test stubbed.
  func invoke(_ request: Request) async throws -> Response {
    let current: Outcome = lock.withLock {
      recorded.append(request)

      return outcome
    }

    switch current {
    case let .success(response):
      return response

    case let .failure(error):
      throw error

    case let .handler(handler):
      return try await handler(request)
    }
  }
}
