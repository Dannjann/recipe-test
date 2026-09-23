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

nonisolated extension UTF8ConversionError {
  var errorDescription: String? {
    switch self {
    case let .stringConversionFailed(encoding):
      String(localized: .Shared.sharedErrorUtf8DataToString(Int(encoding.rawValue)))
    case .utf8ConversionFailed:
      String(localized: .Shared.sharedErrorUtf8StringToData)
    }
  }
}
