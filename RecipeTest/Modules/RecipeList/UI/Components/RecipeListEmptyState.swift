//
//  RecipeListEmptyState.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

/// Not `SectionStateView`: that models a retry, and an empty results list offers to clear the
/// filters instead. Which copy it shows is the view model's decision, not this view's.
struct RecipeListEmptyState: View {
  let viewModel: any RecipeListViewModelProtocol
  let onClearFiltersTap: VoidResult

  var body: some View {
    VStack(spacing: contentSpacing) {
      Text(viewModel.emptyTitle)
        .themeTextStyle(.bodyBold)
        .themeColor(.textPrimary)
        .multilineTextAlignment(.center)

      if let emptyDetail = viewModel.emptyDetail {
        Text(emptyDetail)
          .themeTextStyle(.subheadlineRegular)
          .themeColor(.textSecondary)
          .multilineTextAlignment(.center)
      }

      if viewModel.showsClearFiltersButton {
        Button(
          action: onClearFiltersTap,
          label: { Text(.RecipeList.recipeListEmptyClearFilters) }
        )
        .buttonStyle(.plain)
        .themeTextStyle(.bodyBold)
        .foregroundStyle(.themeColor(.textBrandDefault))
      }
    }
    .frame(
      maxWidth: .infinity,
      minHeight: minHeight
    )
    .padding(
      .horizontal,
      horizontalGutter
    )
  }
}

// MARK: - Getters

private extension RecipeListEmptyState {
  var contentSpacing: CGFloat {
    12
  }

  var minHeight: CGFloat {
    240
  }

  var horizontalGutter: CGFloat {
    20
  }
}

#if DEBUG
  #Preview("An empty category") {
    RecipeListEmptyState(
      viewModel: MockRecipeListViewModel.emptyCategory(),
      onClearFiltersTap: {}
    )
  }

  #Preview("Filtered to nothing") {
    RecipeListEmptyState(
      viewModel: MockRecipeListViewModel.emptyFiltered(),
      onClearFiltersTap: {}
    )
  }
#endif
