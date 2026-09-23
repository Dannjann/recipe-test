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
  /// A view model checks this so a torn-down `.task` never renders as a server failure and
  /// always leaves the load retryable, rather than stuck on `.failed`. It recognises both
  /// `CancellationError` and `URLError.cancelled` — the two shapes Swift Concurrency and
  /// `URLSession` use for the same event.
  ///
  /// Today's transport produces neither: `APIClient` wraps Alamofire in a bare
  /// `withCheckedThrowingContinuation` with no `withTaskCancellationHandler`, so a
  /// cancelled `.task` never reaches this property as an error at all — the request is
  /// simply left running and its result discarded. This guard is a contract held in
  /// advance of that gap being closed, not a path this app's networking exercises today.
  var isCancellation: Bool {
    self is CancellationError || (self as? URLError)?.code == .cancelled
  }
}
