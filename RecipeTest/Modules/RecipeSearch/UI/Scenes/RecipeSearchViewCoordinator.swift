//
//  RecipeSearchViewCoordinator.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

/// Owns the overlay's own stack, so the typing screen is a real push with a real back gesture
/// rather than a second state inside one view.
struct RecipeSearchViewCoordinator: ViewCoordinator {
  /// `nil` means the user closed the overlay without applying anything.
  let onFinish: SingleResult<RecipeSearchResult?>

  @State private var viewModel: RecipeSearchViewModel
  @State private var isEditingQuery = false

  @Namespace private var queryFieldNamespace

  init(
    request: RecipeSearchRequest,
    onFinish: @escaping SingleResult<RecipeSearchResult?>,
    recentSearchStore: RecentSearchStoreProtocol = AppContainer.shared.recentSearchStore
  ) {
    self.onFinish = onFinish
    _viewModel = State(initialValue: RecipeSearchViewModel(
      request: request,
      recentSearchStore: recentSearchStore
    ))
  }

  var body: some View {
    NavigationStack {
      RecipeSearchView(
        viewModel: viewModel,
        queryFieldNamespace: queryFieldNamespace,
        onCloseTap: handleCloseTap(),
        onFieldTap: handleFieldTap(),
        onSubmitTap: handleSubmitTap()
      )
      .toolbarVisibility(
        .hidden,
        for: .navigationBar
      )
      .navigationDestination(isPresented: $isEditingQuery) {
        RecipeSearchInputViewCoordinator(
          text: viewModel.hasFieldText ? viewModel.fieldText : "",
          onFinish: handleInputFinish()
        )
        .navigationTransition(.zoom(
          sourceID: RecipeSearchView.queryFieldID,
          in: queryFieldNamespace
        ))
        .toolbarVisibility(
          .hidden,
          for: .navigationBar
        )
      }
    }
  }
}

// MARK: - Handlers

private extension RecipeSearchViewCoordinator {
  func handleCloseTap() -> VoidResult {
    { onFinish(nil) }
  }

  func handleFieldTap() -> VoidResult {
    { isEditingQuery = true }
  }

  func handleSubmitTap() -> VoidResult {
    { onFinish(viewModel.apply()) }
  }

  func handleInputFinish() -> SingleResult<RecipeSearchInputSelection?> {
    { selection in
      isEditingQuery = false

      switch selection {
      case let .text(text):
        viewModel.set(searchText: text)

      case let .recipe(summary):
        onFinish(.openRecipe(summary))

      case nil:
        break
      }
    }
  }
}

#if DEBUG
  #Preview {
    RecipeSearchViewCoordinator(
      request: RecipeSearchRequest(query: .empty),
      onFinish: { _ in },
      recentSearchStore: RecentSearchStore()
    )
  }
#endif
