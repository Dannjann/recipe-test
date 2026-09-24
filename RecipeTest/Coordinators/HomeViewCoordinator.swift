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
  @State private var searchRequest: RecipeSearchRequest?

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
    .fullScreenCover(item: $searchRequest) { request in
      RecipeSearchViewCoordinator(
        request: request,
        onFinish: handleSearchFinish
      )
    }
  }
}

// MARK: - Home Scene

private extension HomeViewCoordinator {
  var handleSearchTap: VoidResult {
    { searchRequest = RecipeSearchRequest(query: .empty) }
  }

  /// Home holds no filter of its own, so applying one pushes the list that does.
  var handleSearchFinish: SingleResult<RecipeSearchResult?> {
    { result in
      searchRequest = nil

      switch result {
      case let .apply(query):
        push(query: query)

      case let .openRecipe(summary):
        pathRouter.push(Route.Recipe.detail(summary))

      case nil:
        break
      }
    }
  }

  func push(query: RecipeQuery) {
    let searchText = query.searchText ?? ""

    pathRouter.push(Route.Recipe.list(
      searchText.isEmpty
        ? .all(query: query)
        : .search(
          searchText,
          query: query
        )
    ))
  }

  var handleRecipeTap: SingleResult<RecipeSummary> {
    { summary in pathRouter.push(Route.Recipe.detail(summary)) }
  }

  var handleCategoryTap: SingleResult<RecipeCategory> {
    { pathRouter.push(Route.Recipe.list(.category($0))) }
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
