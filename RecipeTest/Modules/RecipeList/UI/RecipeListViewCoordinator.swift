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
  @State private var searchRequest: RecipeSearchRequest?

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
    .fullScreenCover(item: $searchRequest) { request in
      RecipeSearchViewCoordinator(
        request: request,
        onFinish: handleSearchFinish()
      )
    }
  }
}

// MARK: - Handlers

private extension RecipeListViewCoordinator {
  /// Opened with the applied query, so the overlay comes up showing what this list is
  /// already filtered by.
  func handleSearchTap() -> VoidResult {
    { searchRequest = RecipeSearchRequest(query: viewModel.query) }
  }

  /// Re-queries this screen rather than pushing another one: five taps on the pill leave one
  /// list on the stack, not five.
  func handleSearchFinish() -> SingleResult<RecipeSearchResult?> {
    { result in
      searchRequest = nil

      switch result {
      case let .apply(query):
        Task { await viewModel.apply(query: query) }

      case let .openRecipe(summary):
        pathRouter.push(Route.Recipe.detail(summary))

      case nil:
        break
      }
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
