//
//  RecipeListFooter.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

/// Its own view, not a computed property on `RecipeListView`: the paging state it reads
/// changes on every page, and a computed property would share the screen's invalidation
/// boundary and redraw the search bar and the toolbar along with it.
struct RecipeListFooter: View {
  @Environment(\.theme) private var theme: any ThemeProtocol

  let viewModel: any RecipeListViewModelProtocol

  var body: some View {
    if viewModel.hasLoadedAllData {
      EmptyView()
    } else if let nextPageError = viewModel.nextPageError {
      VStack(spacing: Self.spacing) {
        Text(nextPageError)
          .font(theme.textStyle.footnoteRegular.font)
          .foregroundStyle(theme.color.textSecondary.color)
          .multilineTextAlignment(.center)

        Button(String(localized: .Recipe.recipeListErrorRetry)) {
          Task { await viewModel.loadNextPage() }
        }
        .font(theme.textStyle.bodySemibold.font)
      }
      .padding(.vertical, RecipeListLayout.spacing)
    } else {
      ProgressView()
        .padding(.vertical, RecipeListLayout.spacing)
        .task(id: viewModel.loadedPageCount) {
          await viewModel.loadNextPage()
        }
    }
  }
}

// MARK: - Constants

private extension RecipeListFooter {
  static var spacing: CGFloat {
    8
  }
}

// MARK: - Previews

#if DEBUG

  #Preview("Loading the next page") {
    RecipeListFooter(
      viewModel: MockRecipeListViewModel(isLoadingNextPage: true, hasLoadedAllData: false)
    )
  }

  #Preview("Next page failed") {
    RecipeListFooter(
      viewModel: MockRecipeListViewModel(
        nextPageError: AppError.noInternetConnection.localizedDescription,
        hasLoadedAllData: false
      )
    )
  }

#endif
