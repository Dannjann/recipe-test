//
//  RecipeListViewCoordinator.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

struct RecipeListViewCoordinator: ViewCoordinator {
  @Environment(PathRouter.self) private var pathRouter

  @State private var viewModel: RecipeListViewModel

  init(
    request: RecipeListRequest,
    recipeService: RecipeServiceProtocol = AppContainer.shared.recipeService
  ) {
    _viewModel = State(initialValue: RecipeListViewModelFactory.make(
      request: request,
      recipeService: recipeService
    ))
  }

  var body: some View {
    RecipeListView(
      viewModel: viewModel,
      onSearchTap: handleSearchTap(),
      onRecipeTap: handleRecipeTap()
    )
  }
}

// MARK: - Handlers

private extension RecipeListViewCoordinator {
  func handleSearchTap() -> VoidResult {
    {
      // TODO: Push the search overlay once it exists
    }
  }

  func handleRecipeTap() -> SingleResult<RecipeSummary> {
    { pathRouter.push(Route.Recipe.detail($0)) }
  }
}

#if DEBUG
  #Preview {
    NavigationStack {
      RecipeListViewCoordinator(request: .category(.dummy(name: "Desserts")))
    }
    .environment(PathRouter())
  }
#endif
