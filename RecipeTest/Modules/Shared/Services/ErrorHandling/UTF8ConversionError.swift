//
//  UTF8ConversionError.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2024 Danjan. All rights reserved.
//

import Foundation

nonisolated enum UTF8ConversionError: Error {
  case stringConversionFailed(encoding: String.Encoding)
  case utf8ConversionFailed
}

/// `LocalizedError`, not a bare extension: `errorDescription` is only consulted by
/// Foundation when the type actually conforms. Without it, `localizedDescription` —
/// which is what `debugLogError(_:)` logs — falls back to the generic "operation
/// couldn't be completed" text and the encoding detail below is never seen.
nonisolated extension UTF8ConversionError: LocalizedError {
  var errorDescription: String? {
    switch self {
    case let .stringConversionFailed(encoding):
      String(localized: .Shared.sharedErrorUtf8DataToString(Int(encoding.rawValue)))
    case .utf8ConversionFailed:
      String(localized: .Shared.sharedErrorUtf8StringToData)
    }
  }
}
