//
//  RecipeListContent.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

/// Keeps the rows and the empty message inside the same `ScrollView`, so pulling to
/// refresh works whether or not the list has rows in it.
struct RecipeListContent: View {
  let viewModel: any RecipeListViewModelProtocol
  var onRecipeTap: SingleResult<RecipeSummary> = DefaultClosure.singleResult()

  var body: some View {
    ScrollView {
      if viewModel.recipes.isEmpty {
        RecipeListMessageView(
          title: String(localized: .Recipe.recipeListEmptyTitle),
          detail: String(localized: .Recipe.recipeListEmptyMessage)
        )
        .containerRelativeFrame(.vertical)
      } else {
        // Lazy, not a plain VStack: a ScrollView builds every child eagerly, which would
        // request page 2 on the first frame.
        LazyVStack(spacing: 0) {
          RecipeListGrid(viewModel: viewModel, onRecipeTap: onRecipeTap)

          RecipeListFooter(viewModel: viewModel)
        }
      }
    }
    .contentMargins(.horizontal, RecipeListLayout.spacing, for: .scrollContent)
    .refreshable {
      await viewModel.refresh()
    }
  }
}

// MARK: - Previews

#if DEBUG

  #Preview("Rows") {
    RecipeListContent(viewModel: MockRecipeListViewModel())
  }

  #Preview("Empty") {
    RecipeListContent(viewModel: MockRecipeListViewModel(recipes: []))
  }

#endif
