//
//  AppErrorTests.swift
//  Tests
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation
@testable import RecipeTest
import Testing

struct AppErrorTests {
  @Test
  func failureReason_ofUnauthorized_isTheReasonItCarries() {
    let sut = AppError.unauthorized("Token expired")

    #expect(sut.failureReason == "Token expired")
  }

  /// `.abnormalState` carries a reason that no property exposed: `failureReason` sent it
  /// to the default branch, so a thrown one could not be diagnosed from either property.
  @Test
  func failureReason_ofAbnormalState_isTheReasonItCarries() {
    let sut = AppError.abnormalState("Coordinator had no root")

    #expect(sut.failureReason == "Coordinator had no root")
  }

  @Test
  func failureReason_ofACaseCarryingNoReason_fallsBackToTheUnknownText() {
    let sut = AppError.unknown

    #expect(sut.failureReason == String(localized: .Shared.sharedErrorUnknown))
  }

  @Test
  func errorDescription_ofNoInternetConnection_isItsOwnText() {
    let sut = AppError.noInternetConnection

    #expect(sut.errorDescription == String(localized: .Shared.sharedErrorNoInternetConnection))
  }
}
