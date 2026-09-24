//
//  RecipeCategoryGrid.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

struct RecipeCategoryGrid: View {
  let categories: [RecipeCategory]
  let onCategoryTap: SingleResult<RecipeCategory>

  @ScaledMetric(relativeTo: .body) private var tileWidth: CGFloat = RecipeCategoryTile.baseWidth

  var body: some View {
    LazyVGrid(
      columns: columns,
      spacing: rowSpacing
    ) {
      ForEach(categories) { category in
        RecipeCategoryTile(
          category: category,
          onTap: onCategoryTap
        )
      }
    }
    .padding(
      .horizontal,
      horizontalGutter
    )
  }
}

// MARK: - Getters

private extension RecipeCategoryGrid {
  var columnSpacing: CGFloat {
    14
  }

  var rowSpacing: CGFloat {
    18
  }

  var horizontalGutter: CGFloat {
    20
  }

  /// Adaptive, not a fixed three: the tile has to shed columns at accessibility sizes.
  var columns: [GridItem] {
    [GridItem(
      .adaptive(minimum: tileWidth),
      spacing: columnSpacing
    )]
  }
}

#if DEBUG
  #Preview {
    RecipeCategoryGrid(
      categories: MockHomeViewModel.sampleCategories,
      onCategoryTap: { _ in }
    )
    .frame(
      maxWidth: .infinity,
      maxHeight: .infinity
    )
    .background(Color.themeColor(.surfacesBackground))
  }
#endif
