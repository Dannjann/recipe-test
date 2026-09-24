//
//  IngredientChecklist.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

struct IngredientChecklist: View {
  let ingredients: [RecipeIngredient]
  let checkedIngredientIDs: Set<String>
  let onIngredientTap: SingleResult<String>

  var body: some View {
    VStack(spacing: spacing) {
      ForEach(ingredients) { ingredient in
        IngredientChecklistRow(
          ingredient: ingredient,
          isChecked: checkedIngredientIDs.contains(ingredient.id),
          onTap: onIngredientTap
        )
      }
    }
    .padding(
      .horizontal,
      horizontalPadding
    )
  }
}

// MARK: - Getters

private extension IngredientChecklist {
  var spacing: CGFloat {
    8
  }

  var horizontalPadding: CGFloat {
    20
  }
}

#if DEBUG
  #Preview {
    IngredientChecklist(
      ingredients: Recipe.dummy().ingredients,
      checkedIngredientIDs: ["rcp-001-0", "rcp-001-3"],
      onIngredientTap: { _ in }
    )
    .frame(
      maxWidth: .infinity,
      maxHeight: .infinity,
      alignment: .top
    )
    .background(Color.themeColor(.surfacesBackground2))
  }
#endif
