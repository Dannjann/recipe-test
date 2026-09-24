//
//  RecipeListResults.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

struct RecipeListResults: View {
  let viewModel: any RecipeListViewModelProtocol
  let onRecipeTap: SingleResult<RecipeSummary>

  @Environment(\.dynamicTypeSize) private var dynamicTypeSize

  var body: some View {
    if case .empty = viewModel.recipes {
      RecipeListEmptyState(
        viewModel: viewModel,
        onClearFiltersTap: { Task { await viewModel.clearFacets() } }
      )
    } else {
      SectionStateView(
        state: viewModel.recipes,
        minHeight: minHeight,
        // Never reached: `.empty` is answered above, because this list's empty state offers
        // to clear the filters and `SectionStateView` only models a retry.
        emptyMessage: viewModel.emptyTitle,
        onRetryTap: { Task { await viewModel.loadFirstPage() } },
        content: { grid($0) }
      )
    }
  }
}

// MARK: - Getters

private extension RecipeListResults {
  var columns: [GridItem] {
    Array(
      repeating: GridItem(
        .flexible(),
        spacing: itemSpacing
      ),
      count: columnCount
    )
  }

  /// One column in list mode, and one at accessibility sizes whatever the toggle says — a
  /// two-up grid at those sizes clips the name off every card.
  var columnCount: Int {
    guard
      viewModel.viewMode == .grid,
      !dynamicTypeSize.isAccessibilitySize
    else { return 1 }

    return 2
  }

  var itemSpacing: CGFloat {
    16
  }

  var horizontalGutter: CGFloat {
    20
  }

  var minHeight: CGFloat {
    240
  }
}

// MARK: - Subviews

private extension RecipeListResults {
  func grid(_ loaded: [RecipeCardViewModel]) -> some View {
    LazyVGrid(
      columns: columns,
      spacing: itemSpacing
    ) {
      ForEach(loaded) { card in
        row(for: card)
          .transition(.opacity)
          .task { await viewModel.loadNextPageIfNeeded(after: card.id) }
      }
    }
    .padding(
      .horizontal,
      horizontalGutter
    )
    .animation(
      .snappy,
      value: viewModel.viewMode
    )
  }

  /// A `matchedGeometryEffect` here would be inert: one view holds each id in both modes, so
  /// there is no second view to interpolate against, while the real swap happens inside this
  /// builder and tears the cell down beneath it. The spec's named fallback ships instead —
  /// the column change animates the frame, and the two presentations cross-fade.
  @ViewBuilder
  func row(for card: RecipeCardViewModel) -> some View {
    switch viewModel.viewMode {
    case .grid:
      RecipeCard(
        viewModel: card,
        onTap: onRecipeTap
      )

    case .list:
      RecipeRow(
        viewModel: card,
        onTap: onRecipeTap
      )
    }
  }
}

#if DEBUG
  #Preview("Grid") {
    ScrollView {
      RecipeListResults(
        viewModel: MockRecipeListViewModel.loaded(),
        onRecipeTap: { _ in }
      )
    }
    .background(Color.themeColor(.surfacesBackground))
  }

  #Preview("List") {
    ScrollView {
      RecipeListResults(
        viewModel: MockRecipeListViewModel.loaded(viewMode: .list),
        onRecipeTap: { _ in }
      )
    }
    .background(Color.themeColor(.surfacesBackground))
  }

  #Preview("Loading") {
    RecipeListResults(
      viewModel: MockRecipeListViewModel.loading(),
      onRecipeTap: { _ in }
    )
  }

  #Preview("Failed") {
    RecipeListResults(
      viewModel: MockRecipeListViewModel.failed(),
      onRecipeTap: { _ in }
    )
  }

  #Preview("Filtered to nothing") {
    RecipeListResults(
      viewModel: MockRecipeListViewModel.emptyFiltered(),
      onRecipeTap: { _ in }
    )
  }
#endif
