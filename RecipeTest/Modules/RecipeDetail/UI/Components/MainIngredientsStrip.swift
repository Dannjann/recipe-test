//
//  MainIngredientsStrip.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

struct MainIngredientsStrip: View {
  let ingredients: [RecipeIngredient]

  var body: some View {
    ScrollView(.horizontal) {
      LazyHStack(
        alignment: .top,
        spacing: spacing
      ) {
        ForEach(ingredients) { ingredient in
          MainIngredientTile(ingredient: ingredient)
        }
      }
      .scrollTargetLayout()
    }
    .scrollIndicators(.hidden)
    .contentMargins(
      .horizontal,
      horizontalGutter,
      for: .scrollContent
    )
    .accessibilityLabel(Text(.RecipeDetail.recipeDetailMainIngredientsTitle))
  }
}

// MARK: - Getters

private extension MainIngredientsStrip {
  var spacing: CGFloat {
    14
  }

  var horizontalGutter: CGFloat {
    20
  }
}

#if DEBUG
  #Preview {
    MainIngredientsStrip(ingredients: Recipe.dummy().ingredients.filter(\.isMain))
      .frame(
        maxWidth: .infinity,
        maxHeight: .infinity,
        alignment: .top
      )
      .background(Color.themeColor(.surfacesBackground2))
  }
#endif
