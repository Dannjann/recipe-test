//
//  RecipeListToolbar.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

struct RecipeListToolbar: View {
  let viewModel: any RecipeListViewModelProtocol
  let onViewModeSelect: SingleResult<RecipeListViewMode>

  var body: some View {
    HStack(spacing: contentSpacing) {
      if let resultCountText = viewModel.resultCountText {
        Text(resultCountText)
          .themeTextStyle(.footnoteRegular)
          .themeColor(.textSecondary)
          .accessibilityIdentifier("recipe-list-result-count-label")
      }

      Spacer(minLength: 0)

      RecipeListViewModeToggle(
        viewModel: viewModel,
        onSelect: onViewModeSelect
      )
    }
    .padding(
      .horizontal,
      horizontalGutter
    )
  }
}

// MARK: - Getters

private extension RecipeListToolbar {
  var contentSpacing: CGFloat {
    12
  }

  var horizontalGutter: CGFloat {
    20
  }
}

#if DEBUG
  #Preview("With a count") {
    RecipeListToolbar(
      viewModel: MockRecipeListViewModel.loaded(),
      onViewModeSelect: { _ in }
    )
  }

  #Preview("Before the count lands") {
    RecipeListToolbar(
      viewModel: MockRecipeListViewModel.loading(),
      onViewModeSelect: { _ in }
    )
  }
#endif
