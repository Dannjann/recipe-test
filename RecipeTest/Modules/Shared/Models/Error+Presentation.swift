//
//  Error+Presentation.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

nonisolated extension Error {
  var displayMessage: String {
    localizedDescription
  }

  /// Today's transport (Alamofire via a bare continuation) never actually produces
  /// `CancellationError` or `URLError.cancelled` — this guards for when it does.
  var isCancellation: Bool {
    self is CancellationError || (self as? URLError)?.code == .cancelled
  }
}
