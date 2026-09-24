//
//  View+RecipeRoutes.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

extension View {
  /// Registers the destinations for `Route.Recipe`, so the app's root composes the module
  /// by name without knowing which coordinator answers a case or what the case carries.
  func recipeRoutes() -> some View {
    navigationDestination(for: Route.Recipe.self) { route in
      switch route {
      case let .detail(summary):
        RecipeDetailViewCoordinator(summary: summary)
      }
    }
  }
}
