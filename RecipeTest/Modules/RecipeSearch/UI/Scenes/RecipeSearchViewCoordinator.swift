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
///
/// Both scenes are this one coordinator's: the typing screen is a step in the overlay's flow,
/// not a flow of its own, and it has nowhere to go that the filters cannot already reach.
struct RecipeSearchViewCoordinator: ViewCoordinator {
  /// `nil` means the user closed the overlay without applying anything.
  let onFinish: SingleResult<RecipeSearchResult?>

  @State private var viewModel: RecipeSearchViewModel

  /// Lives as long as the overlay rather than as long as one push, so going back to the
  /// filters and returning does not throw away suggestions already fetched. `fullScreenCover`
  /// keys on the request, so a fresh overlay still starts with a fresh one.
  @State private var inputViewModel: RecipeSearchInputViewModel

  @State private var isEditingQuery = false

  @Namespace private var queryFieldNamespace

  init(
    request: RecipeSearchRequest,
    onFinish: @escaping SingleResult<RecipeSearchResult?>,
    recipeService: RecipeServiceProtocol = AppContainer.shared.recipeService,
    recentSearchStore: RecentSearchStoreProtocol = AppContainer.shared.recentSearchStore
  ) {
    self.onFinish = onFinish
    _viewModel = State(initialValue: RecipeSearchViewModel(
      request: request,
      recentSearchStore: recentSearchStore
    ))
    _inputViewModel = State(initialValue: RecipeSearchInputViewModel(
      text: request.query.searchText ?? "",
      recipeService: recipeService,
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
        RecipeSearchInputView(
          text: viewModel.searchText,
          viewModel: inputViewModel,
          onBackTap: handleInputBackTap(),
          onSelect: handleInputSelect(),
          onSubmit: handleInputSubmit()
        )
        .navigationTransition(.zoom(
          sourceID: RecipeSearchAccessibilityID.queryField,
          in: queryFieldNamespace
        ))
        .toolbarVisibility(
          .hidden,
          for: .navigationBar
        )
      }
    }
    // The filter scene paints itself translucent, which only reads as translucent if the
    // cover stops painting a page of its own behind it. The typing screen stays opaque: a
    // pushed destination sits on a backing of SwiftUI's that nothing here can clear.
    .presentationBackground(.clear)
  }
}

// MARK: - Handlers > Search Scene

private extension RecipeSearchViewCoordinator {
  func handleCloseTap() -> VoidResult {
    { onFinish(nil) }
  }

  func handleFieldTap() -> VoidResult {
    { isEditingQuery = true }
  }

  func handleSubmitTap() -> VoidResult {
    {
      viewModel.recordSearch()
      onFinish(viewModel.result)
    }
  }
}

// MARK: - Handlers > Search Input Scene

private extension RecipeSearchViewCoordinator {
  /// The back button leaves the field as it was.
  func handleInputBackTap() -> VoidResult {
    { isEditingQuery = false }
  }

  func handleInputSelect() -> SingleResult<any RecipeSuggestionRowViewModelProtocol> {
    { finish(selection: $0.selection) }
  }

  /// Typing a term and hitting return is the same act as picking the "Search for …" row.
  func handleInputSubmit() -> SingleResult<String> {
    { finish(selection: .text($0)) }
  }

  func finish(selection: RecipeSearchInputSelection) {
    isEditingQuery = false

    switch selection {
    case let .text(text):
      viewModel.set(searchText: text)

    case let .recipe(summary):
      onFinish(.openRecipe(summary))
    }
  }
}

#if DEBUG
  #Preview {
    RecipeSearchViewCoordinator(
      request: RecipeSearchRequest(query: .empty),
      onFinish: { _ in }
    )
  }
#endif
