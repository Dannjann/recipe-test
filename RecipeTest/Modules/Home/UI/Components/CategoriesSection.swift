//
//  CategoriesSection.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

struct CategoriesSection: View {
  let viewModel: any HomeViewModelProtocol
  let onCategoryTap: SingleResult<RecipeCategory>

  @ScaledMetric(relativeTo: .body) private var minHeight: CGFloat = RecipeCategoryTile.baseWidth

  var body: some View {
    SectionStateView(
      state: viewModel.categories,
      minHeight: minHeight,
      emptyMessage: .Home.homeCategoriesEmpty,
      onRetryTap: { Task { await viewModel.loadCategories() } }
    ) { categories in
      RecipeCategoryGrid(
        categories: categories,
        onCategoryTap: onCategoryTap
      )
    }
  }
}

#Preview {
  CategoriesSection(
    viewModel: MockHomeViewModel.loaded(),
    onCategoryTap: { _ in }
  )
  .frame(
    maxWidth: .infinity,
    maxHeight: .infinity
  )
  .background(Color.themeColor(.surfacesBackground))
}
