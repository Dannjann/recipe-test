//
//  RecipeListGrid.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

/// Its own view rather than a computed property on `RecipeListView`, so that the rows and
/// the layout are read here: a page arriving redraws this and not the screen around it.
struct RecipeListGrid: View {
  let viewModel: any RecipeListViewModelProtocol
  var onRecipeTap: SingleResult<RecipeSummary> = DefaultClosure.singleResult()

  var body: some View {
    LazyVGrid(
      columns: viewModel.layout.columns,
      spacing: RecipeListLayout.spacing
    ) {
      ForEach(viewModel.recipes) { recipe in
        Button {
          onRecipeTap(recipe)
        } label: {
          RecipeCard(recipe: recipe, layout: viewModel.layout)
        }
        .buttonStyle(.plain)
      }
    }
    .animation(.snappy, value: viewModel.layout)
  }
}

// MARK: - Previews

#if DEBUG

  #Preview("List") {
    ScrollView {
      RecipeListGrid(viewModel: MockRecipeListViewModel())
        .padding(RecipeListLayout.spacing)
    }
  }

  #Preview("Grid") {
    ScrollView {
      RecipeListGrid(viewModel: MockRecipeListViewModel(layout: .grid))
        .padding(RecipeListLayout.spacing)
    }
  }

#endif
