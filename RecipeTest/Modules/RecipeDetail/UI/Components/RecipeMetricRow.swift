//
//  RecipeMetricRow.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

/// Three columns at default text sizes, one column at accessibility sizes: three scaled
/// labels and their icons do not fit a card a third of the screen wide.
struct RecipeMetricRow: View {
  let totalTimeMinutes: Int?
  let servings: Int?
  let difficulty: RecipeDifficulty?

  @Environment(\.dynamicTypeSize) private var dynamicTypeSize

  var body: some View {
    layout {
      RecipeMetricCard(
        title: .RecipeDetail.recipeDetailCookingTimeTitle,
        systemImage: "clock",
        value: timeText,
        background: .surfacesAccentPeach
      )

      RecipeMetricCard(
        title: .RecipeDetail.recipeDetailServingsTitle,
        systemImage: "person.2",
        value: servingsText,
        background: .surfacesAccentMint
      )

      RecipeMetricCard(
        title: .RecipeDetail.recipeDetailDifficultyTitle,
        systemImage: "chart.bar",
        value: difficultyText,
        background: .surfacesAccentSky
      )
    }
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

private extension RecipeMetricRow {
  var layout: AnyLayout {
    dynamicTypeSize.isAccessibilitySize
      ? AnyLayout(VStackLayout(spacing: spacing))
      : AnyLayout(HStackLayout(spacing: spacing))
  }

  var spacing: CGFloat {
    10
  }

  var horizontalPadding: CGFloat {
    20
  }

  var topPadding: CGFloat {
    20
  }

  /// Reproduces the prototype's `fmtTime` — "25 min", "1 hr 25 min" — and localizes the
  /// units rather than assembling them by hand.
  var timeText: String? {
    guard let totalTimeMinutes else { return nil }

    return Duration
      .seconds(totalTimeMinutes * 60)
      .formatted(.units(
        allowed: [.hours, .minutes],
        width: .abbreviated
      ))
  }

  var servingsText: String? {
    servings.map { String($0) }
  }

  var difficultyText: String? {
    difficulty.map { String(localized: $0.displayName) }
  }
}

#if DEBUG
  #Preview("All three present") {
    RecipeMetricRow(
      totalTimeMinutes: 25,
      servings: 4,
      difficulty: .medium
    )
    .frame(
      maxWidth: .infinity,
      maxHeight: .infinity,
      alignment: .top
    )
    .background(Color.themeColor(.surfacesBackground2))
  }

  #Preview("Over an hour") {
    RecipeMetricRow(
      totalTimeMinutes: 305,
      servings: 8,
      difficulty: .hard
    )
    .frame(
      maxWidth: .infinity,
      maxHeight: .infinity,
      alignment: .top
    )
    .background(Color.themeColor(.surfacesBackground2))
  }

  #Preview("All three missing") {
    RecipeMetricRow(
      totalTimeMinutes: nil,
      servings: nil,
      difficulty: nil
    )
    .frame(
      maxWidth: .infinity,
      maxHeight: .infinity,
      alignment: .top
    )
    .background(Color.themeColor(.surfacesBackground2))
  }

  #Preview("AX3") {
    RecipeMetricRow(
      totalTimeMinutes: 25,
      servings: 4,
      difficulty: .medium
    )
    .frame(
      maxWidth: .infinity,
      maxHeight: .infinity,
      alignment: .top
    )
    .background(Color.themeColor(.surfacesBackground2))
    .environment(
      \.dynamicTypeSize,
      .accessibility3
    )
  }
#endif
