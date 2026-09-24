//
//  Error+Cancellation.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Alamofire
import Foundation

nonisolated extension Error {
  /// Lives here rather than in a caller: recognising a cancellation means knowing that the
  /// transport wraps `URLError` instead of surfacing it, and Alamofire stops at this layer.
  var isCancellation: Bool {
    if self is CancellationError {
      return true
    }

    if (self as? URLError)?.code == .cancelled {
      return true
    }

    guard let afError = asAFError else { return false }

    return afError.isExplicitlyCancelledError
      || (afError.underlyingError as? URLError)?.code == .cancelled
  }
}
