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
  let cookingTimeText: String?
  let servingsText: String?
  let difficultyText: LocalizedStringResource?

  @Environment(\.dynamicTypeSize) private var dynamicTypeSize

  var body: some View {
    layout {
      RecipeMetricCard(
        title: .RecipeDetail.recipeDetailCookingTimeTitle,
        systemImage: "clock",
        value: cookingTimeValue,
        background: .surfacesAccentPeach
      )

      RecipeMetricCard(
        title: .RecipeDetail.recipeDetailServingsTitle,
        systemImage: "person.2",
        value: servingsValue,
        background: .surfacesAccentMint
      )

      RecipeMetricCard(
        title: .RecipeDetail.recipeDetailDifficultyTitle,
        systemImage: "chart.bar",
        value: difficultyValue,
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

  /// Already formatted by the view model; `verbatim` keeps it from being read as a key.
  var cookingTimeValue: Text? {
    cookingTimeText.map { Text(verbatim: $0) }
  }

  var servingsValue: Text? {
    servingsText.map { Text(verbatim: $0) }
  }

  var difficultyValue: Text? {
    difficultyText.map { Text($0) }
  }
}

#if DEBUG
  #Preview("All three present") {
    RecipeMetricRow(
      cookingTimeText: "25 min",
      servingsText: "4",
      difficultyText: .RecipeDetail.recipeDetailDifficultyMedium
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
      cookingTimeText: "5 hr 5 min",
      servingsText: "8",
      difficultyText: .RecipeDetail.recipeDetailDifficultyHard
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
      cookingTimeText: nil,
      servingsText: nil,
      difficultyText: nil
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
      cookingTimeText: "25 min",
      servingsText: "4",
      difficultyText: .RecipeDetail.recipeDetailDifficultyMedium
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
