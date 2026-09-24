//
//  RecipeMetricCard.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

/// `value` is optional because all three metrics are optional on the domain model. A nil
/// shows an em dash and announces the unavailable copy, rather than an empty card.
struct RecipeMetricCard: View {
  let title: LocalizedStringResource
  let systemImage: String
  let value: String?
  let background: Color.ThemeColor

  @ScaledMetric(relativeTo: .body) private var minHeight: CGFloat = RecipeMetricCard.baseMinHeight

  var body: some View {
    VStack(
      alignment: .leading,
      spacing: spacing
    ) {
      header

      Spacer(minLength: 0)

      Text(value ?? unavailableSymbol)
        .themeTextStyle(.title3)
        .themeColor(.textPrimary)
    }
    .padding(
      .horizontal,
      horizontalPadding
    )
    .padding(
      .vertical,
      verticalPadding
    )
    .frame(
      maxWidth: .infinity,
      minHeight: minHeight,
      alignment: .leading
    )
    .background(
      Color.themeColor(background),
      in: .rect(cornerRadius: cornerRadius)
    )
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(Text(title))
    .accessibilityValue(accessibilityValue)
  }
}

// MARK: - Getters

extension RecipeMetricCard {
  static var baseMinHeight: CGFloat {
    112
  }
}

private extension RecipeMetricCard {
  var spacing: CGFloat {
    12
  }

  /// Tighter than the card's vertical rhythm: at 12pt the label still needs every point
  /// it can get beside the icon, or "Cooking" breaks mid-word in a 110pt card.
  var headerSpacing: CGFloat {
    6
  }

  var horizontalPadding: CGFloat {
    14
  }

  var verticalPadding: CGFloat {
    14
  }

  var cornerRadius: CGFloat {
    24
  }

  var unavailableSymbol: String {
    "—"
  }

  var accessibilityValue: Text {
    guard let value else {
      return Text(.RecipeDetail.recipeDetailMetricUnavailable)
    }

    return Text(value)
  }
}

// MARK: - Subviews

private extension RecipeMetricCard {
  var header: some View {
    HStack(
      alignment: .top,
      spacing: headerSpacing
    ) {
      Text(title)
        .themeTextStyle(.footnoteRegular)
        .themeColor(.textPrimary)
        .multilineTextAlignment(.leading)
        .lineLimit(2)
        .minimumScaleFactor(0.8)

      Spacer(minLength: 0)

      Image(systemName: systemImage)
        .foregroundStyle(.themeColor(.iconsDefault))
    }
  }
}

#if DEBUG
  #Preview("With a value") {
    RecipeMetricCard(
      title: .RecipeDetail.recipeDetailCookingTimeTitle,
      systemImage: "clock",
      value: "25 min",
      background: .surfacesAccentPeach
    )
    .padding(20)
    .background(Color.themeColor(.surfacesBackground2))
  }

  #Preview("Value unavailable") {
    RecipeMetricCard(
      title: .RecipeDetail.recipeDetailDifficultyTitle,
      systemImage: "chart.bar",
      value: nil,
      background: .surfacesAccentSky
    )
    .padding(20)
    .background(Color.themeColor(.surfacesBackground2))
  }
#endif
