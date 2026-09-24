//
//  RecipeDetailViewCoordinator.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

struct RecipeDetailViewCoordinator: ViewCoordinator {
  @Environment(PathRouter.self) private var pathRouter

  @State private var viewModel: RecipeDetailViewModel

  init(
    summary: RecipeSummary,
    recipeService: RecipeServiceProtocol = AppContainer.shared.recipeService
  ) {
    _viewModel = State(initialValue: RecipeDetailViewModel(
      summary: summary,
      recipeService: recipeService
    ))
  }

  var body: some View {
    RecipeDetailView(
      viewModel: viewModel,
      onBackTap: handleBackTap()
    )
  }
}

// MARK: - Handlers

private extension RecipeDetailViewCoordinator {
  func handleBackTap() -> VoidResult {
    { pathRouter.pop() }
  }
}

#if DEBUG
  #Preview {
    NavigationStack {
      RecipeDetailViewCoordinator(summary: .dummy())
    }
    .environment(PathRouter())
  }
#endif
