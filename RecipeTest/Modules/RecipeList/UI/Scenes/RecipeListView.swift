//
//  RecipeListView.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

struct RecipeListView: View {
  let viewModel: any RecipeListViewModelProtocol
  let onSearchTap: VoidResult
  let onRecipeTap: SingleResult<RecipeSummary>

  var body: some View {
    ScrollView(.vertical) {
      VStack(
        alignment: .leading,
        spacing: sectionSpacing
      ) {
        RecipeSearchPill(
          placeholder: viewModel.searchPlaceholder,
          onTap: onSearchTap
        )

        RecipeFacetChipRow(
          viewModel: viewModel,
          onRemoveTap: { facet in Task { await viewModel.remove(facet: facet) } },
          onClearAllTap: { Task { await viewModel.clearFacets() } }
        )

        RecipeListToolbar(
          viewModel: viewModel,
          onViewModeSelect: { viewMode in viewModel.select(viewMode: viewMode) }
        )

        RecipeListResults(
          viewModel: viewModel,
          onRecipeTap: onRecipeTap
        )

        RecipeListFooter(
          viewModel: viewModel,
          onRetryTap: { Task { await viewModel.retryNextPage() } }
        )
      }
      .padding(
        .vertical,
        contentInset
      )
    }
    .scrollIndicators(.hidden)
    .background(Color.themeColor(.surfacesBackground))
    .navigationTitle(viewModel.title)
    // The system back button is what keeps the interactive swipe-back the detail screen lost.
    .navigationBarTitleDisplayMode(.large)
    .toolbarVisibility(
      .visible,
      for: .navigationBar
    )
    .task { await viewModel.loadFirstPageIfNeeded() }
  }
}

// MARK: - Getters

private extension RecipeListView {
  var sectionSpacing: CGFloat {
    16
  }

  var contentInset: CGFloat {
    12
  }
}

#if DEBUG
  #Preview("Loaded") {
    NavigationStack {
      RecipeListView(
        viewModel: MockRecipeListViewModel.loaded(),
        onSearchTap: {},
        onRecipeTap: { _ in }
      )
    }
  }

  #Preview("Filtered") {
    NavigationStack {
      RecipeListView(
        viewModel: MockRecipeListViewModel.filtered(),
        onSearchTap: {},
        onRecipeTap: { _ in }
      )
    }
  }

  #Preview("An empty category") {
    NavigationStack {
      RecipeListView(
        viewModel: MockRecipeListViewModel.emptyCategory(),
        onSearchTap: {},
        onRecipeTap: { _ in }
      )
    }
  }

  #Preview("A page failed") {
    NavigationStack {
      RecipeListView(
        viewModel: MockRecipeListViewModel.pagingFailed(),
        onSearchTap: {},
        onRecipeTap: { _ in }
      )
    }
  }
#endif
