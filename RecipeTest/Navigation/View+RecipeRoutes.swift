//
//  View+RecipeRoutes.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

extension View {
  /// Registers the destinations for `Route.Recipe`, so the app's root composes the flow by
  /// name without knowing which coordinator answers a case or what the case carries.
  ///
  /// Filed under `Navigation/` rather than in a module: the namespace spans `RecipeDetail`
  /// and `RecipeList`, so leaving it inside either one would make that module depend on its
  /// sibling for no reason but where the file sits.
  func recipeRoutes() -> some View {
    navigationDestination(for: Route.Recipe.self) { route in
      switch route {
      case let .detail(summary):
        RecipeDetailViewCoordinator(summary: summary)

      case let .list(request):
        RecipeListViewCoordinator(request: request)
      }
    }
  }
}
