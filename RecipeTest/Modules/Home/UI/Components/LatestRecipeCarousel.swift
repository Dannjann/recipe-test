//
//  LatestRecipeCarousel.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

struct LatestRecipeCarousel: View {
  let recipes: [RecipeSummary]
  let onRecipeTap: SingleResult<String>

  var body: some View {
    ScrollView(.horizontal) {
      LazyHStack(spacing: 14) {
        ForEach(recipes) { recipe in
          LatestRecipeCard(
            recipe: recipe,
            onTap: onRecipeTap
          )
        }
      }
      .scrollTargetLayout()
      // Paired with the negative padding below: room for cardShadow, which the scroll view clips.
      .padding(
        .vertical,
        16
      )
    }
    .scrollIndicators(.hidden)
    .scrollTargetBehavior(.viewAligned)
    // Not `.padding`: `.viewAligned` snaps to the content edge, which padding does not move.
    .contentMargins(
      .horizontal,
      20,
      for: .scrollContent
    )
    .padding(
      .vertical,
      -16
    )
    .accessibilityLabel(Text(.Home.homeLatestRecipesTitle))
  }
}

#Preview {
  LatestRecipeCarousel(
    recipes: MockHomeViewModel.sampleRecipes,
    onRecipeTap: { _ in }
  )
  .frame(
    maxWidth: .infinity,
    maxHeight: .infinity
  )
  .background(Color.themeColor(.surfacesBackground))
}
