//
//  RecipeFacetChipRow.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

/// Renders nothing when the request carries no facets, which is every category tap today.
struct RecipeFacetChipRow: View {
  let viewModel: any RecipeListViewModelProtocol
  let onRemoveTap: SingleResult<RecipeQueryFacet>
  let onClearAllTap: VoidResult

  var body: some View {
    if !viewModel.facetChips.isEmpty {
      ScrollView(.horizontal) {
        HStack(spacing: contentSpacing) {
          ForEach(viewModel.facetChips) { chip in
            RecipeFacetChip(
              viewModel: chip,
              onRemoveTap: onRemoveTap
            )
          }

          if viewModel.showsClearAllChips {
            Button(
              action: onClearAllTap,
              label: { Text(.RecipeList.recipeListFacetsClearAll) }
            )
            .buttonStyle(.plain)
            .themeTextStyle(.captionBold)
            .foregroundStyle(.themeColor(.textBrandDefault))
          }
        }
        .padding(
          .horizontal,
          horizontalGutter
        )
      }
      .scrollIndicators(.hidden)
    }
  }
}

// MARK: - Getters

private extension RecipeFacetChipRow {
  var contentSpacing: CGFloat {
    8
  }

  var horizontalGutter: CGFloat {
    20
  }
}

#if DEBUG
  #Preview("Several facets") {
    RecipeFacetChipRow(
      viewModel: MockRecipeListViewModel.filtered(),
      onRemoveTap: { _ in },
      onClearAllTap: {}
    )
  }

  #Preview("No facets") {
    RecipeFacetChipRow(
      viewModel: MockRecipeListViewModel.loaded(),
      onRemoveTap: { _ in },
      onClearAllTap: {}
    )
    .border(Color.themeColor(.bordersDefault))
  }
#endif
