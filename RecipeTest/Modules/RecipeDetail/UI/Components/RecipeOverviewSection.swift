//
//  RecipeOverviewSection.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

struct RecipeOverviewSection: View {
  let title: String
  let description: String

  var body: some View {
    VStack(
      alignment: .leading,
      spacing: spacing
    ) {
      Text(title)
        .themeTextStyle(.largeTitle)
        .themeColor(.textPrimary)
        .accessibilityAddTraits(.isHeader)

      if !description.isEmpty {
        Text(description)
          .themeTextStyle(.bodyRegular)
          .themeColor(.textSecondary)
      }
    }
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
  }
}

// MARK: - Getters

private extension RecipeOverviewSection {
  var spacing: CGFloat {
    10
  }

  var horizontalPadding: CGFloat {
    20
  }

  var topPadding: CGFloat {
    20
  }
}

#if DEBUG
  #Preview("With a description") {
    RecipeOverviewSection(
      title: "Spaghetti alla Carbonara",
      description: "Roman pasta bound with egg yolk and pecorino — never cream."
    )
    .frame(
      maxWidth: .infinity,
      maxHeight: .infinity,
      alignment: .top
    )
    .background(Color.themeColor(.surfacesBackground2))
  }

  #Preview("Title only") {
    RecipeOverviewSection(
      title: "Spaghetti alla Carbonara",
      description: ""
    )
    .frame(
      maxWidth: .infinity,
      maxHeight: .infinity,
      alignment: .top
    )
    .background(Color.themeColor(.surfacesBackground2))
  }
#endif
