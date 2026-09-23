//
//  RecipeServiceError.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

/// What `RecipeService` throws on its own account, as distinct from an error the API
/// layer raised and this service merely passed through.
///
/// One case today: a response that decoded cleanly but carried a recipe the mapper could
/// not turn into a domain model. That is a backend contract break, not a transport
/// failure, and it is worth telling apart from `AppError.unknown` — which says nothing
/// about what went wrong and so reads the same as every other unhandled case.
nonisolated enum RecipeServiceError: Error, Equatable {
  /// The detail payload for `id` decoded, but carried no usable `id` or `title`.
  case unmappableRecipe(id: String)
}

// MARK: - LocalizedError

nonisolated extension RecipeServiceError: LocalizedError {
  var errorDescription: String? {
    switch self {
    case .unmappableRecipe:
      String(localized: .Core.coreErrorParseFailed)
    }
  }
}
