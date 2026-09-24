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
    _viewModel = State(initialValue: Self.viewModel(
      for: request,
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

// MARK: - Scene

private extension RecipeListViewCoordinator {
  static func viewModel(
    for request: RecipeListRequest,
    recipeService: RecipeServiceProtocol
  ) -> RecipeListViewModel {
    switch request.title {
    case let .category(name):
      CategoryRecipeListViewModel(
        categoryName: name,
        query: request.query,
        recipeService: recipeService
      )

    case let .search(text):
      SearchRecipeListViewModel(
        searchText: text,
        query: request.query,
        recipeService: recipeService
      )

    case .all:
      RecipeListViewModel(
        query: request.query,
        recipeService: recipeService
      )
    }
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
