//
//  RecipeDetailSectionHeader.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

struct RecipeDetailSectionHeader: View {
  let title: LocalizedStringResource

  var body: some View {
    Text(title)
      .themeTextStyle(.title2)
      .themeColor(.textPrimary)
      .frame(
        maxWidth: .infinity,
        alignment: .leading
      )
      .padding(
        .horizontal,
        horizontalPadding
      )
      .padding(
        .top,
        topPadding
      )
      .padding(
        .bottom,
        bottomPadding
      )
      .accessibilityAddTraits(.isHeader)
  }
}

// MARK: - Getters

private extension RecipeDetailSectionHeader {
  var horizontalPadding: CGFloat {
    20
  }

  var topPadding: CGFloat {
    28
  }

  var bottomPadding: CGFloat {
    14
  }
}

#if DEBUG
  #Preview {
    VStack(spacing: 0) {
      RecipeDetailSectionHeader(title: .RecipeDetail.recipeDetailMainIngredientsTitle)
      RecipeDetailSectionHeader(title: .RecipeDetail.recipeDetailIngredientsTitle)
      RecipeDetailSectionHeader(title: .RecipeDetail.recipeDetailInstructionsTitle)
    }
    .frame(
      maxWidth: .infinity,
      maxHeight: .infinity
    )
    .background(Color.themeColor(.surfacesBackground2))
  }
#endif
