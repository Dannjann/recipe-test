//
//  RecipeDetailBody.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

/// Everything below the metric cards — the part that has to wait for `getRecipe`.
struct RecipeDetailBody: View {
  let recipe: Recipe
  let checkedIngredientIDs: Set<String>
  let onIngredientTap: SingleResult<String>

  var body: some View {
    VStack(
      alignment: .leading,
      spacing: 0
    ) {
      if !mainIngredients.isEmpty {
        RecipeDetailSectionHeader(title: .RecipeDetail.recipeDetailMainIngredientsTitle)
        MainIngredientsStrip(ingredients: mainIngredients)
      }

      if !recipe.ingredients.isEmpty {
        RecipeDetailSectionHeader(title: .RecipeDetail.recipeDetailIngredientsTitle)

        IngredientChecklist(
          ingredients: recipe.ingredients,
          checkedIngredientIDs: checkedIngredientIDs,
          onIngredientTap: onIngredientTap
        )
      }

      if !recipe.steps.isEmpty {
        RecipeDetailSectionHeader(title: .RecipeDetail.recipeDetailInstructionsTitle)
        RecipeInstructions(steps: recipe.steps)
      }

      if isEmpty {
        empty
      }
    }
    .frame(
      maxWidth: .infinity,
      alignment: .leading
    )
  }
}

// MARK: - Getters

private extension RecipeDetailBody {
  var mainIngredients: [RecipeIngredient] {
    recipe.ingredients.filter(\.isMain)
  }

  /// The request succeeded and carried nothing to cook with. Without this the sheet is a
  /// title, three metric cards and a panel of white space.
  var isEmpty: Bool {
    recipe.ingredients.isEmpty && recipe.steps.isEmpty
  }

  var emptyMinHeight: CGFloat {
    240
  }

  var horizontalPadding: CGFloat {
    20
  }
}

// MARK: - Subviews

private extension RecipeDetailBody {
  var empty: some View {
    Text(.RecipeDetail.recipeDetailDetailEmpty)
      .themeTextStyle(.bodyRegular)
      .themeColor(.textSecondary)
      .multilineTextAlignment(.center)
      .frame(
        maxWidth: .infinity,
        minHeight: emptyMinHeight
      )
      .padding(
        .horizontal,
        horizontalPadding
      )
  }
}

#if DEBUG
  #Preview("Full recipe") {
    ScrollView {
      RecipeDetailBody(
        recipe: .dummy(),
        checkedIngredientIDs: ["rcp-001-0"],
        onIngredientTap: { _ in }
      )
    }
    .background(Color.themeColor(.surfacesBackground2))
  }

  #Preview("Nothing to cook with") {
    ScrollView {
      RecipeDetailBody(
        recipe: .dummy(
          ingredients: [],
          steps: []
        ),
        checkedIngredientIDs: [],
        onIngredientTap: { _ in }
      )
    }
    .background(Color.themeColor(.surfacesBackground2))
  }
#endif
