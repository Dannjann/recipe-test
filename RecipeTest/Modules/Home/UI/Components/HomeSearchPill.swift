//
//  HomeSearchPill.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

/// A `Button`, not a `TextField`: it opens the search overlay rather than accepting input.
struct HomeSearchPill: View {
  let onTap: VoidResult

  @Environment(\.dynamicTypeSize) private var dynamicTypeSize

  @ScaledMetric(relativeTo: .body) private var height: CGFloat = 56

  var body: some View {
    Button(action: onTap) {
      HStack(spacing: 10) {
        Image(systemName: "magnifyingglass")
          .foregroundStyle(.themeColor(.iconsDefault))

        Text(.Home.homeSearchPlaceholder)
          .themeTextStyle(.bodyRegular)
          .themeColor(.textPrimary)
          .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)
      }
      .frame(
        maxWidth: .infinity,
        minHeight: height
      )
      .padding(
        .horizontal,
        20
      )
      .background(
        Color.themeColor(.surfacesBackground2),
        in: .capsule
      )
    }
    .buttonStyle(.plain)
    .cardShadow()
    .padding(
      .horizontal,
      20
    )
  }
}

#Preview {
  HomeSearchPill(onTap: {})
    .frame(
      maxWidth: .infinity,
      maxHeight: .infinity
    )
    .background(Color.themeColor(.surfacesBackground))
}
