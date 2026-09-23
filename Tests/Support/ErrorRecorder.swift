//
//  ErrorRecorder.swift
//  Tests
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

/// Captures what an `APIClient`'s `onError` closure was handed.
///
/// `@unchecked Sendable` with a lock rather than a plain array: `onError` is
/// `@Sendable` and Alamofire may call it off the test's own thread.
final class ErrorRecorder: @unchecked Sendable {
  private let lock = NSLock()
  private var recorded: [any Error] = []

  var errors: [any Error] {
    lock.withLock { recorded }
  }

  var count: Int {
    errors.count
  }

  func record(_ error: any Error) {
    lock.withLock { recorded.append(error) }
  }
}
