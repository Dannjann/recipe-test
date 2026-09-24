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
  let chips: [any RecipeIngredientChipViewModelProtocol]

  /// Carries the ingredient rather than the chip, so the caller decides which side it is
  /// removing from without having to ask the chip what it is.
  let onRemoveTap: SingleResult<String>

  var body: some View {
    if !chips.isEmpty {
      ScrollView(.horizontal) {
        HStack(spacing: contentSpacing) {
          ForEach(chips, id: \.id) { chip in
            RecipeIngredientChip(
              viewModel: chip,
              onRemoveTap: { onRemoveTap(chip.ingredient) }
            )
          }
        }
      }
      .scrollIndicators(.hidden)
    }
  }
}

// MARK: - Getters > Constants

private extension RecipeIngredientChipRow {
  var contentSpacing: CGFloat {
    8
  }
}

#if DEBUG
  #Preview("Included") {
    RecipeIngredientChipRow(
      chips: ["garlic", "soy sauce"].map {
        RecipeIncludedIngredientChipViewModel(ingredient: $0)
      },
      onRemoveTap: { _ in }
    )
    .padding()
    .background(Color.themeColor(.surfacesBackground2))
  }

  #Preview("Excluded") {
    RecipeIngredientChipRow(
      chips: ["pork"].map {
        RecipeExcludedIngredientChipViewModel(ingredient: $0)
      },
      onRemoveTap: { _ in }
    )
    .padding()
    .background(Color.themeColor(.surfacesBackground2))
  }
#endif
