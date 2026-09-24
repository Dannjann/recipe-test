//
//  AppCoordinator.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

/// Owns the `PathRouter` backing the `NavigationStack` and decides which flow is shown.
struct AppCoordinator: ViewCoordinator {
  @State private var pathRouter: PathRouter = .init()

  var body: some View {
    NavigationStack(path: $pathRouter.path) {
      HomeViewCoordinator()
        .navigationDestination(for: Route.Recipe.self) { route in
          switch route {
          case let .detail(summary):
            RecipeDetailViewCoordinator(summary: summary)
          }
        }
    }
    .environment(pathRouter)
  }
}
