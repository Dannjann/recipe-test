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
    LazyVGrid(columns: columns, spacing: 18) {
      ForEach(categories) { category in
        RecipeCategoryTile(category: category, onTap: onCategoryTap)
      }
    }
    .padding(.horizontal, 20)
  }
}

// MARK: - Getters

private extension RecipeCategoryGrid {
  /// Adaptive, not a fixed three: the tile has to shed columns at accessibility sizes.
  var columns: [GridItem] {
    [GridItem(.adaptive(minimum: tileWidth), spacing: 14)]
  }
}

#Preview {
  RecipeCategoryGrid(categories: MockHomeViewModel.sampleCategories, onCategoryTap: { _ in })
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.themeColor(.surfacesBackground))
}
