//
//  DebugLoggingHelpers.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2024 Danjan. All rights reserved.
//

import Foundation

nonisolated extension DebugLogger.Context {
  static let networking = DebugLogger.Context("networking")
  static let appError = DebugLogger.Context("appError")

  /// logging made on this category must be deleted after done usually
  static let debugging = DebugLogger.Context("debugging")
}

nonisolated func debugLog(_ message: String) {
  DebugLogger.shared.log(.debugging, message)
}

nonisolated func debugLogError(_ appError: AppError) {
  DebugLogger.shared.log(
    .appError,
    "\(appError.errorDescription ?? "Unknown")",
    level: .error,
    showLocationOverride: true
  )
}

nonisolated func debugLogError(_ error: Error) {
  DebugLogger.shared.log(.appError, "\(error.localizedDescription)", level: .error, showLocationOverride: true)
}
