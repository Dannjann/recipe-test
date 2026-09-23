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
    case let .unauthorized(reason):
      reason
    default:
      String(localized: .Shared.sharedErrorUnknown)
    }
  }
}
