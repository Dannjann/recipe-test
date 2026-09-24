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
        // Never reached: `.empty` is answered above.
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

  /// A two-up grid at accessibility sizes clips the name off every card.
  var columnCount: Int {
    guard
      viewModel.viewMode == .grid,
      !dynamicTypeSize.isAccessibilitySize
    else { return singleColumnCount }

    return gridColumnCount
  }

  var singleColumnCount: Int {
    1
  }

  var gridColumnCount: Int {
    2
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

  var rowSpacing: CGFloat {
    0
  }

  var pagingTriggerHeight: CGFloat {
    0
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
        VStack(spacing: rowSpacing) {
          row(for: card)
            .transition(.opacity)

          pagingTrigger(for: card)
        }
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

  /// A sibling, not a modifier: hung off the row, switching view mode would restart the task.
  func pagingTrigger(for card: RecipeCardViewModel) -> some View {
    Color.clear
      .frame(height: pagingTriggerHeight)
      .task { await viewModel.loadNextPageIfNeeded(after: card.id) }
  }

  /// A `matchedGeometryEffect` would be inert: one view holds each id in both modes.
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
