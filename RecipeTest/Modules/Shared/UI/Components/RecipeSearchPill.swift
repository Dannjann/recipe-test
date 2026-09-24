//
//  RecipeSearchPill.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

/// Opens the search overlay rather than accepting input.
struct RecipeSearchPill: View {
  let placeholder: String
  let onTap: VoidResult

  @Environment(\.dynamicTypeSize) private var dynamicTypeSize

  @ScaledMetric(relativeTo: .body) private var height: CGFloat = RecipeSearchPill.baseHeight

  var body: some View {
    Button(
      action: onTap,
      label: {
        HStack(spacing: contentSpacing) {
          Image(systemName: searchSymbolName)
            .foregroundStyle(.themeColor(.iconsDefault))

          Text(placeholder)
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
          Color.themeColor(.surfacesFieldsAndTags),
          in: .capsule
        )
      }
    )
    .buttonStyle(.plain)
    .accessibilityIdentifier("recipe-search-pill-button")
    .cardShadow()
    .padding(
      .horizontal,
      horizontalGutter
    )
  }
}

// MARK: - Getters

extension RecipeSearchPill {
  static var baseHeight: CGFloat {
    56
  }
}

// MARK: - Getters > Constants

private extension RecipeSearchPill {
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
  #Preview("Home placeholder") {
    RecipeSearchPill(
      placeholder: String(localized: .Home.homeSearchPlaceholder),
      onTap: {}
    )
    .frame(
      maxWidth: .infinity,
      maxHeight: .infinity
    )
    .background(Color.themeColor(.surfacesBackground))
  }

  #Preview("Scoped to a category") {
    RecipeSearchPill(
      placeholder: "Search Desserts",
      onTap: {}
    )
    .frame(
      maxWidth: .infinity,
      maxHeight: .infinity
    )
    .background(Color.themeColor(.surfacesBackground))
  }
#endif
