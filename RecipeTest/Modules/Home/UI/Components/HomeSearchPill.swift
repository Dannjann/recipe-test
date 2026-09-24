//
//  HomeSearchPill.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

/// The search affordance at the top of Home.
///
/// A `Button` rather than a `TextField`: tapping it opens the search overlay in a later
/// stage; nothing is typed into it here. It is not a Liquid Glass surface on purpose —
/// the prototype is a flat cream sheet with soft brown shadows, and glass would read as a
/// different product.
struct HomeSearchPill: View {
  let onTap: VoidResult

  @ScaledMetric(relativeTo: .body) private var height: CGFloat = 56

  var body: some View {
    Button(action: onTap) {
      HStack(spacing: 10) {
        Image(systemName: "magnifyingglass")
          .foregroundStyle(.themeColor(.iconsDefault))

        Text(.Home.homeSearchPlaceholder)
          .themeTextStyle(.bodyRegular)
          .themeColor(.textPrimary)
          .lineLimit(1)
      }
      .frame(maxWidth: .infinity, minHeight: height)
      .padding(.horizontal, 20)
      .background(Color.themeColor(.surfacesBackground2), in: .capsule)
    }
    .buttonStyle(.plain)
    .cardShadow()
    .padding(.horizontal, 20)
  }
}

#Preview {
  HomeSearchPill(onTap: {})
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.themeColor(.surfacesBackground))
}
