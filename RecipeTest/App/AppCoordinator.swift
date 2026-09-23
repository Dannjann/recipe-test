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
/// The base project has no feature modules, so the stack roots on a placeholder. Replace
/// `placeholder` with your first module's coordinator — `CatalogViewCoordinator(pathRouter:
/// pathRouter)` — or branch here on `session.isActive` once the app has accounts.
struct AppCoordinator: ViewCoordinator {
  @State private var pathRouter: PathRouter = .init()

  var body: some View {
    NavigationStack(path: $pathRouter.path) {
      placeholder
    }
    .environment(pathRouter)
  }
}

// MARK: - Subviews

private extension AppCoordinator {
  /// Verbatim on purpose: a placeholder that ships for one commit does not belong in a
  /// string catalog.
  var placeholder: some View {
    VStack(spacing: 8) {
      Text(verbatim: "RecipeTest")
        .themeTextStyle(.title2)
        .themeColor(.textPrimary)

      Text(verbatim: "Base project. No feature modules yet.")
        .themeTextStyle(.bodyRegular)
        .themeColor(.textSecondary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.themeColor(.surfacesBackground))
  }
}
