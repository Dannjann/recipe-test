//
//  HomeSectionHeader.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

struct HomeSectionHeader: View {
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
        20
      )
      .padding(
        .top,
        30
      )
      .padding(
        .bottom,
        14
      )
      .accessibilityAddTraits(.isHeader)
  }
}

#Preview {
  VStack(spacing: 0) {
    HomeSectionHeader(title: .Home.homeLatestRecipesTitle)
    HomeSectionHeader(title: .Home.homeCategoriesTitle)
  }
  .frame(
    maxWidth: .infinity,
    maxHeight: .infinity
  )
  .background(Color.themeColor(.surfacesBackground))
}
