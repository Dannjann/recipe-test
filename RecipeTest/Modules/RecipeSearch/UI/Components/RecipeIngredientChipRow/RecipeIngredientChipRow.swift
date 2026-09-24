//
//  RecipeIngredientChipRow.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

/// Scrolls horizontally rather than wrapping, matching `RecipeFacetChipRow`: an ingredient
/// looks and behaves the same in the overlay as it does on the results list.
struct RecipeIngredientChipRow: View {
  let chips: [RecipeIngredientChipViewModel]
  let onRemoveTap: SingleResult<RecipeIngredientChipViewModel>

  var body: some View {
    if !chips.isEmpty {
      ScrollView(.horizontal) {
        HStack(spacing: contentSpacing) {
          ForEach(chips) { chip in
            RecipeIngredientChip(
              viewModel: chip,
              onRemoveTap: { onRemoveTap(chip) }
            )
          }
        }
      }
      .scrollIndicators(.hidden)
    }
  }
}

// MARK: - Getters

private extension RecipeIngredientChipRow {
  var contentSpacing: CGFloat {
    8
  }
}

#if DEBUG
  #Preview("Included") {
    RecipeIngredientChipRow(
      chips: ["garlic", "soy sauce"].map {
        RecipeIngredientChipViewModel(
          ingredient: $0,
          kind: .include
        )
      },
      onRemoveTap: { _ in }
    )
    .padding()
    .background(Color.themeColor(.surfacesBackground2))
  }

  #Preview("Excluded") {
    RecipeIngredientChipRow(
      chips: ["pork"].map {
        RecipeIngredientChipViewModel(
          ingredient: $0,
          kind: .exclude
        )
      },
      onRemoveTap: { _ in }
    )
    .padding()
    .background(Color.themeColor(.surfacesBackground2))
  }
#endif
