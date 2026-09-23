//
//  Error+Presentation.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

nonisolated extension Error {
  /// Text safe to put in front of a user.
  ///
  /// `localizedDescription` rather than `(self as? LocalizedError)?.errorDescription`:
  /// the latter is nil for any error that does not conform, which would put an empty
  /// string in an error state. `AppError` and `RecipeServiceError` both conform, so their
  /// catalogued copy is what comes back; anything else degrades to Foundation's generic
  /// sentence instead of to nothing.
  var displayMessage: String {
    localizedDescription
  }

  /// Whether this error means "the caller went away", rather than "the request failed".
  ///
  /// SwiftUI cancels a `.task` when its view disappears, and `URLSession` reports that as
  /// `URLError.cancelled` rather than as `CancellationError` — both have to be caught, or
  /// navigating away mid-load leaves a failure on screen for the user to come back to.
  var isCancellation: Bool {
    self is CancellationError || (self as? URLError)?.code == .cancelled
  }
}
