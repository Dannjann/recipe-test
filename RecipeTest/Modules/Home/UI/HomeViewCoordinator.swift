//
//  HomeViewCoordinator.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

/// Owns the Home flow: it constructs the scene's view model and is the only type that
/// decides where a tap on Home leads.
///
/// Every handler below is empty in this stage — the search overlay, the recipe list and
/// the recipe detail do not exist yet. They are wired anyway so that adding them is an
/// edit to this file and nothing else.
///
/// No `PathRouter` yet, deliberately. `AppCoordinator` already publishes one into the
/// environment; this coordinator picks it up with `@Environment(PathRouter.self)` when it
/// has a destination to push, rather than storing one it never reads.
struct HomeViewCoordinator: ViewCoordinator {
  @State private var viewModel: HomeViewModel

  init(recipeService: RecipeServiceProtocol = AppContainer.shared.recipeService) {
    _viewModel = State(initialValue: HomeViewModel(recipeService: recipeService))
  }

  var body: some View {
    HomeView(
      viewModel: viewModel,
      onSearchTap: handleSearchTap(),
      onRecipeTap: handleRecipeTap(),
      onCategoryTap: handleCategoryTap()
    )
  }
}

// MARK: - Handlers

private extension HomeViewCoordinator {
  /// Next stage: presents the search and filter overlay.
  func handleSearchTap() -> VoidResult {
    {}
  }

  /// Next stage: pushes `Route.Home.recipeDetail(id)`.
  func handleRecipeTap() -> SingleResult<String> {
    { _ in }
  }

  /// Next stage: pushes `Route.Home.recipeList(category)`.
  func handleCategoryTap() -> SingleResult<RecipeCategory> {
    { _ in }
  }
}

#Preview {
  NavigationStack {
    HomeViewCoordinator()
  }
}
