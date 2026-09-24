//
//  RecipeSearchFieldButton.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

/// A `Button` shaped like a field, not a `TextField`: typing happens on the pushed screen,
/// where the suggestions are.
struct RecipeSearchFieldButton: View {
  let text: String
  let textColorStyle: Color.ThemeColor
  let accessibilityValue: String
  let showsClear: Bool
  let onTap: VoidResult
  let onClearTap: VoidResult

  @Environment(\.dynamicTypeSize) private var dynamicTypeSize

  @ScaledMetric(relativeTo: .body) private var height: CGFloat = RecipeSearchFieldButton.baseHeight

  var body: some View {
    HStack(spacing: contentSpacing) {
      Button(
        action: onTap,
        label: {
          HStack(spacing: contentSpacing) {
            Image(systemName: searchSymbolName)
              .foregroundStyle(.themeColor(.iconsDefault))

            Text(text)
              .themeTextStyle(.bodyRegular)
              .themeColor(textColorStyle)
              .lineLimit(textLineLimit)
              .frame(
                maxWidth: .infinity,
                alignment: .leading
              )
          }
          .contentShape(.rect)
        }
      )
      .buttonStyle(.plain)
      .accessibilityIdentifier(RecipeSearchAccessibilityID.fieldButton)
      .accessibilityLabel(Text(.RecipeSearch.recipeSearchFieldAccessibilityLabel))
      .accessibilityValue(Text(accessibilityValue))

      if showsClear {
        Button(
          action: onClearTap,
          label: {
            Image(systemName: clearSymbolName)
              .foregroundStyle(.themeColor(.iconsSecondary))
          }
        )
        .buttonStyle(.plain)
        .accessibilityIdentifier(RecipeSearchAccessibilityID.fieldClearButton)
        .accessibilityLabel(Text(.RecipeSearch.recipeSearchFieldClearAccessibilityLabel))
      }
    }
    .padding(
      .horizontal,
      horizontalGutter
    )
    .frame(
      maxWidth: .infinity,
      minHeight: height
    )
    .fieldCapsule()
  }
}

// MARK: - Getters

extension RecipeSearchFieldButton {
  static var baseHeight: CGFloat {
    56
  }
}

// MARK: - Getters > Constants

private extension RecipeSearchFieldButton {
  var contentSpacing: CGFloat {
    10
  }

  var horizontalGutter: CGFloat {
    16
  }

  var searchSymbolName: String {
    "magnifyingglass"
  }

  var clearSymbolName: String {
    "xmark.circle.fill"
  }

  var textLineLimit: Int? {
    dynamicTypeSize.isAccessibilitySize ? nil : 1
  }
}

#if DEBUG
  #Preview("Placeholder") {
    RecipeSearchFieldButton(
      text: "Search recipes or ingredients",
      textColorStyle: .textTertiary,
      accessibilityValue: "Nothing entered",
      showsClear: false,
      onTap: {},
      onClearTap: {}
    )
    .padding()
    .background(Color.themeColor(.surfacesBackground2))
  }

  #Preview("With text") {
    RecipeSearchFieldButton(
      text: "adobo",
      textColorStyle: .textPrimary,
      accessibilityValue: "adobo",
      showsClear: true,
      onTap: {},
      onClearTap: {}
    )
    .padding()
    .background(Color.themeColor(.surfacesBackground2))
  }
#endif
