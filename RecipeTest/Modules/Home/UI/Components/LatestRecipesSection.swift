//
//  LatestRecipesSection.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

/// A `View`, not a computed property on `HomeView`: a computed one is inlined and would
/// invalidate the whole screen whenever either section resolved.
struct LatestRecipesSection: View {
  let viewModel: any HomeViewModelProtocol
  let onRecipeTap: SingleResult<String>

  @ScaledMetric(relativeTo: .body) private var minHeight: CGFloat = LatestRecipeCard.baseHeight

  var body: some View {
    SectionStateView(
      state: viewModel.latestRecipes,
      minHeight: minHeight,
      emptyMessage: .Home.homeLatestRecipesEmpty,
      onRetryTap: { Task { await viewModel.loadLatestRecipes() } }
    ) { recipes in
      LatestRecipeCarousel(
        recipes: recipes,
        onRecipeTap: onRecipeTap
      )
    }
  }
}

#if DEBUG
  #Preview {
    LatestRecipesSection(
      viewModel: MockHomeViewModel.loaded(),
      onRecipeTap: { _ in }
    )
    .frame(
      maxWidth: .infinity,
      maxHeight: .infinity
    )
    .background(Color.themeColor(.surfacesBackground))
  }
#endif
