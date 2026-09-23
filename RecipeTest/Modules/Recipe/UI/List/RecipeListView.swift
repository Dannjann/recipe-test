//
//  RecipeListView.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

struct RecipeListView: View {
  @Environment(\.theme) private var theme: any ThemeProtocol

  let viewModel: any RecipeListViewModelProtocol
  var onRecipeTap: SingleResult<RecipeSummary> = DefaultClosure.singleResult()

  var body: some View {
    VStack(spacing: 0) {
      RecipeSearchBar()
        .padding(.horizontal, RecipeListLayout.spacing)
        .padding(.bottom, RecipeListLayout.spacing)

      content
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(theme.color.surfacesBackground.color)
    .navigationTitle(.Recipe.recipeListTitle)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        RecipeLayoutToggle(layout: viewModel.layout) { layout in
          viewModel.select(layout: layout)
        }
      }
    }
    .task {
      await viewModel.loadFirstPage()
    }
  }
}

// MARK: - Subviews

private extension RecipeListView {
  @ViewBuilder
  var content: some View {
    switch viewModel.loadState {
    case .idle, .loading:
      ProgressView()
        .frame(maxWidth: .infinity, maxHeight: .infinity)

    case let .failed(message):
      RecipeListMessageView(
        title: message,
        onRetry: { await viewModel.loadFirstPage() }
      )
      .frame(maxHeight: .infinity)

    case .loaded:
      RecipeListContent(viewModel: viewModel, onRecipeTap: onRecipeTap)
    }
  }
}

// MARK: - Previews

#if DEBUG

  #Preview("Loaded — list") {
    NavigationStack {
      RecipeListView(viewModel: MockRecipeListViewModel())
    }
  }

  #Preview("Loaded — grid") {
    NavigationStack {
      RecipeListView(viewModel: MockRecipeListViewModel(layout: .grid))
    }
  }

  #Preview("Loading next page") {
    NavigationStack {
      RecipeListView(
        viewModel: MockRecipeListViewModel(isLoadingNextPage: true, hasLoadedAllData: false)
      )
    }
  }

  #Preview("Next page failed") {
    NavigationStack {
      RecipeListView(
        viewModel: MockRecipeListViewModel(
          nextPageError: AppError.noInternetConnection.localizedDescription,
          hasLoadedAllData: false
        )
      )
    }
  }

  #Preview("Empty") {
    NavigationStack {
      RecipeListView(viewModel: MockRecipeListViewModel(recipes: []))
    }
  }

  #Preview("Failed") {
    NavigationStack {
      RecipeListView(
        viewModel: MockRecipeListViewModel(
          recipes: [],
          loadState: .failed(AppError.noInternetConnection.localizedDescription)
        )
      )
    }
  }

  #Preview("Loading") {
    NavigationStack {
      RecipeListView(viewModel: MockRecipeListViewModel(recipes: [], loadState: .loading))
    }
  }

  #Preview("Accessibility text size") {
    NavigationStack {
      RecipeListView(viewModel: MockRecipeListViewModel())
    }
    .dynamicTypeSize(.accessibility3)
  }

#endif
