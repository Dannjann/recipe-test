//
//  HomeViewCoordinator.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

struct HomeViewCoordinator: ViewCoordinator {
  @Environment(PathRouter.self) private var pathRouter

  @State private var viewModel: HomeViewModel

  init(recipeService: RecipeServiceProtocol = AppContainer.shared.recipeService) {
    _viewModel = State(initialValue: HomeViewModel(recipeService: recipeService))
  }

  var body: some View {
    HomeView(
      viewModel: viewModel,
      onSearchTap: handleSearchTap,
      onRecipeTap: handleRecipeTap,
      onCategoryTap: handleCategoryTap
    )
  }
}

// MARK: - Home Scene

private extension HomeViewCoordinator {
  var handleSearchTap: VoidResult {
    {
      // TODO: Push the search scene once it exists
    }
  }

  var handleRecipeTap: SingleResult<RecipeSummary> {
    { summary in pathRouter.push(Route.Recipe.detail(summary)) }
  }

  var handleCategoryTap: SingleResult<RecipeCategory> {
    { _ in
      // TODO: Push the category listing scene once it exists
    }
  }
}

#if DEBUG
  #Preview {
    NavigationStack {
      HomeViewCoordinator()
    }
    .environment(PathRouter())
  }
#endif
