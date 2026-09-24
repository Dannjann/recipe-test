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

  @ScaledMetric(relativeTo: .body) private var height: CGFloat = HomeSearchPill.baseHeight

  var body: some View {
    Button(
      action: onTap,
      label: {
        HStack(spacing: contentSpacing) {
          Image(systemName: searchSymbolName)
            .foregroundStyle(.themeColor(.iconsDefault))

          Text(.Home.homeSearchPlaceholder)
            .themeTextStyle(.bodyRegular)
            .themeColor(.textPrimary)
            .lineLimit(placeholderLineLimit)
        }
        .frame(
          maxWidth: .infinity,
          minHeight: height
        )
        .padding(
          .horizontal,
          horizontalGutter
        )
        .background(
          Color.themeColor(.surfacesBackground2),
          in: .capsule
        )
      }
    )
    .buttonStyle(.plain)
    .cardShadow()
    .padding(
      .horizontal,
      horizontalGutter
    )
  }
}

// MARK: - Getters

extension HomeSearchPill {
  static var baseHeight: CGFloat {
    56
  }
}

private extension HomeSearchPill {
  var contentSpacing: CGFloat {
    10
  }

  var horizontalGutter: CGFloat {
    20
  }

  var searchSymbolName: String {
    "magnifyingglass"
  }

  var placeholderLineLimit: Int? {
    dynamicTypeSize.isAccessibilitySize ? nil : 1
  }
}

#if DEBUG
  #Preview {
    HomeSearchPill(onTap: {})
      .frame(
        maxWidth: .infinity,
        maxHeight: .infinity
      )
      .background(Color.themeColor(.surfacesBackground))
  }
#endif
