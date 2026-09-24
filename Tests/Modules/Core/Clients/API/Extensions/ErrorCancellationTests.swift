//
//  ErrorCancellationTests.swift
//  Tests
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Alamofire
import Foundation
@testable import RecipeTest
import Testing

struct ErrorCancellationTests {
  @Test
  func isCancellation_forASwiftConcurrencyCancel_isTrue() {
    #expect(CancellationError().isCancellation)
  }

  @Test
  func isCancellation_forABareCancelledURLError_isTrue() {
    #expect(URLError(.cancelled).isCancellation)
  }

  @Test
  func isCancellation_forAnAlamofireExplicitCancel_isTrue() {
    #expect(AFError.explicitlyCancelled.isCancellation)
  }

  @Test
  func isCancellation_forAnAlamofireWrappedCancelledURLError_isTrue() {
    #expect(AFError.sessionTaskFailed(error: URLError(.cancelled)).isCancellation)
  }

  @Test
  func isCancellation_forARealFailure_isFalse() {
    #expect(AppError.unknown.isCancellation == false)
    #expect(URLError(.timedOut).isCancellation == false)
    #expect(AFError.sessionTaskFailed(error: URLError(.notConnectedToInternet)).isCancellation == false)
  }
}
