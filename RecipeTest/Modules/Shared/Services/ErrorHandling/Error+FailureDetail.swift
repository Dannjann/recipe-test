//
//  Error+FailureDetail.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

nonisolated extension Error {
  /// An error that describes itself with the generic heading would print the same sentence
  /// twice, since the failure treatment already shows that heading as the title.
  ///
  /// Lives on `Error` rather than on `SectionState` because the results list reports a failed
  /// page in a footer that is not a `SectionState` at all, and one rule spelled twice is how
  /// the two drift.
  var failureDetail: String? {
    switch self {
    case let appError as AppError:
      appError.isDescribedByGenericHeading ? nil : appError.localizedDescription

    default:
      localizedDescription
    }
  }
}
