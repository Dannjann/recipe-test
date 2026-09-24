//
//  RecipeInstructionRow.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

struct RecipeInstructionRow: View {
  let number: Int
  let total: Int
  let text: String

  var body: some View {
    HStack(
      alignment: .top,
      spacing: spacing
    ) {
      badge

      Text(text)
        .themeTextStyle(.bodyRegular)
        .themeColor(.textPrimary)
        .frame(
          maxWidth: .infinity,
          alignment: .leading
        )
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(Text(.RecipeDetail.recipeDetailStepPosition(
      number,
      total
    )))
    .accessibilityValue(Text(text))
  }
}

// MARK: - Getters

extension RecipeInstructionRow {
  static var baseBadgeSize: CGFloat {
    32
  }
}

private extension RecipeInstructionRow {
  var spacing: CGFloat {
    14
  }
}

// MARK: - Subviews

private extension RecipeInstructionRow {
  var badge: some View {
    Text(String(number))
      .themeTextStyle(.subheadlineSemibold)
      .themeColor(.textPrimary)
      .frame(
        width: Self.baseBadgeSize,
        height: Self.baseBadgeSize
      )
      .background(
        Color.themeColor(.surfacesAccentSky),
        in: .circle
      )
  }
}

#if DEBUG
  #Preview {
    RecipeInstructionRow(
      number: 3,
      total: 5,
      text: "Beat the egg yolks with the grated pecorino and a great deal of black pepper."
    )
    .padding(20)
    .background(Color.themeColor(.surfacesBackground2))
  }
#endif
