//
//  RecipeListFooter.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

/// Sits below the last loaded row. A failed page is reported here and never over the rows the
/// user already has.
struct RecipeListFooter: View {
  let viewModel: any RecipeListViewModelProtocol
  let onRetryTap: VoidResult

  var body: some View {
    if viewModel.isLoadingNextPage {
      ProgressView()
        .tint(.themeColor(.iconsBrandDefault))
        .frame(
          maxWidth: .infinity,
          minHeight: minHeight
        )
        .accessibilityLabel(Text(.RecipeList.recipeListFooterLoadingAccessibilityLabel))
    } else if let nextPageError = viewModel.nextPageError {
      failure(nextPageError)
    }
  }
}

// MARK: - Getters

private extension RecipeListFooter {
  var contentSpacing: CGFloat {
    8
  }

  var minHeight: CGFloat {
    64
  }

  var horizontalGutter: CGFloat {
    20
  }
}

// MARK: - Subviews

private extension RecipeListFooter {
  func failure(_ detail: String) -> some View {
    VStack(spacing: contentSpacing) {
      Text(detail)
        .themeTextStyle(.subheadlineRegular)
        .themeColor(.textSecondary)
        .multilineTextAlignment(.center)

      Button(
        action: onRetryTap,
        label: { Text(.Shared.sharedRetry) }
      )
      .buttonStyle(.plain)
      .themeTextStyle(.bodyBold)
      .foregroundStyle(.themeColor(.textBrandDefault))
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

#if DEBUG
  #Preview("Loading a page") {
    RecipeListFooter(
      viewModel: MockRecipeListViewModel.paging(),
      onRetryTap: {}
    )
  }

  #Preview("A page failed") {
    RecipeListFooter(
      viewModel: MockRecipeListViewModel.pagingFailed(),
      onRetryTap: {}
    )
  }
#endif
