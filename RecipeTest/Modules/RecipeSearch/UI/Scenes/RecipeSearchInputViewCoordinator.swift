//
//  RecipeSearchInputViewCoordinator.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

struct RecipeSearchInputViewCoordinator: ViewCoordinator {
  let text: String

  /// `nil` means the back button — the field is left as it was.
  let onFinish: SingleResult<RecipeSearchInputSelection?>

  @State private var viewModel: RecipeSearchInputViewModel

  init(
    text: String,
    onFinish: @escaping SingleResult<RecipeSearchInputSelection?>,
    recipeService: RecipeServiceProtocol = AppContainer.shared.recipeService,
    recentSearchStore: RecentSearchStoreProtocol = AppContainer.shared.recentSearchStore
  ) {
    self.text = text
    self.onFinish = onFinish
    _viewModel = State(initialValue: RecipeSearchInputViewModel(
      text: text,
      recipeService: recipeService,
      recentSearchStore: recentSearchStore
    ))
  }

  var body: some View {
    RecipeSearchInputView(
      text: text,
      viewModel: viewModel,
      onBackTap: handleBackTap(),
      onSelect: handleSelect(),
      onSubmit: handleSubmit()
    )
  }
}

// MARK: - Handlers

private extension RecipeSearchInputViewCoordinator {
  func handleBackTap() -> VoidResult {
    { onFinish(nil) }
  }

  func handleSelect() -> SingleResult<RecipeSuggestionRowViewModel> {
    { onFinish(viewModel.select($0)) }
  }

  /// Typing a term and hitting return is the same act as picking the "Search for …" row.
  func handleSubmit() -> SingleResult<String> {
    { onFinish(.text($0)) }
  }
}

#if DEBUG
  #Preview {
    NavigationStack {
      RecipeSearchInputViewCoordinator(
        text: "",
        onFinish: { _ in }
      )
    }
  }
#endif
