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
  let onRecipeTap: SingleResult<RecipeSummary>

  var body: some View {
    ScrollView(.horizontal) {
      LazyHStack(spacing: cardSpacing) {
        ForEach(recipes) { recipe in
          LatestRecipeCard(
            recipe: recipe,
            onTap: onRecipeTap
          )
        }
      }
      .scrollTargetLayout()
      .padding(
        .vertical,
        shadowBleed
      )
    }
    .scrollIndicators(.hidden)
    .scrollTargetBehavior(.viewAligned)
    // Not `.padding`: `.viewAligned` snaps to the content edge, which padding does not move.
    .contentMargins(
      .horizontal,
      horizontalGutter,
      for: .scrollContent
    )
    .padding(
      .vertical,
      -shadowBleed
    )
    .accessibilityLabel(Text(.Home.homeLatestRecipesTitle))
  }
}

// MARK: - Getters

private extension LatestRecipeCarousel {
  var cardSpacing: CGFloat {
    14
  }

  var horizontalGutter: CGFloat {
    20
  }

  /// Added inside the scroll view and taken back off outside it, so `cardShadow` has room the
  /// scroll view would otherwise clip. The two uses must stay equal and opposite.
  var shadowBleed: CGFloat {
    16
  }
}

#if DEBUG
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
#endif
