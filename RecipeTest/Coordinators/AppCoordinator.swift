//
//  AppCoordinator.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

/// The root of the SwiftUI coordinator tree. Owns the `PathRouter` backing the
/// `NavigationStack` and decides which flow is shown.
///
/// One flow today: the recipe list. Branch here on session state once the app has
/// accounts.
struct AppCoordinator: ViewCoordinator {
  @State private var pathRouter: PathRouter = .init()

  var body: some View {
    NavigationStack(path: $pathRouter.path) {
      RecipeViewCoordinator()
    }
    .environment(pathRouter)
  }
}
