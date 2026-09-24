//
//  HomeViewCoordinator.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

/// The handlers are empty on purpose: their destinations do not exist yet, and wiring them
/// now keeps adding one an edit to this file alone.
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
  func handleSearchTap() -> VoidResult {
    {}
  }

  func handleRecipeTap() -> SingleResult<String> {
    { _ in }
  }

  func handleCategoryTap() -> SingleResult<RecipeCategory> {
    { _ in }
  }
}

#Preview {
  NavigationStack {
    HomeViewCoordinator()
  }
}
