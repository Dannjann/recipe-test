//
//  AppError.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2024 Danjan. All rights reserved.
//

import Foundation

nonisolated enum AppError: Error {
  case unauthorized(_ reason: String)
  case unknown
  case abnormalState(_ reason: String)
  case noInternetConnection
  case uploadMultipartDataCountMismatch
}

nonisolated extension AppError: LocalizedError {
  var errorDescription: String? {
    switch self {
    case .unauthorized:
      String(localized: .Shared.sharedErrorAuthorizationRequired)
    case .noInternetConnection:
      String(localized: .Shared.sharedErrorNoInternetConnection)
    default:
      String(localized: .Shared.sharedErrorSomethingWentWrong)
    }
  }

  var failureReason: String? {
    switch self {
    case let .unauthorized(reason),
         let .abnormalState(reason):
      reason
    default:
      String(localized: .Shared.sharedErrorUnknown)
    }
  }
}

// MARK: - Presentation

nonisolated extension AppError {
  /// True for the cases whose `errorDescription` falls through to the generic heading.
  ///
  /// A surface that already shows that heading as its own title has nothing to gain from
  /// repeating it as a detail underneath. Kept beside `errorDescription` so the two cannot
  /// drift apart, and written as an exhaustive switch so a new case has to choose a side.
  var isDescribedByGenericHeading: Bool {
    switch self {
    case .unauthorized,
         .noInternetConnection:
      false

    case .unknown,
         .abnormalState,
         .uploadMultipartDataCountMismatch:
      true
    }
  }
}
