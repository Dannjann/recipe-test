//
//  RecipeViewCoordinator.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

struct RecipeViewCoordinator: ViewCoordinator {
  @Environment(PathRouter.self) private var pathRouter

  @State private var viewModel: RecipeListViewModel

  /// The service arrives as an init parameter, so `State(wrappedValue:)` is used rather
  /// than a property initializer — it evaluates only on first render.
  init(service: any RecipeServiceProtocol = AppContainer.shared.recipeService) {
    _viewModel = State(wrappedValue: RecipeListViewModel(service: service))
  }

  var body: some View {
    RecipeListView(viewModel: viewModel) { recipe in
      pathRouter.push(Route.Recipe.detail(recipe))
    }
    .navigationDestination(for: Route.Recipe.self) { route in
      switch route {
      case let .detail(recipe):
        RecipeDetailPlaceholderView(recipe: recipe)
      }
    }
  }
}
