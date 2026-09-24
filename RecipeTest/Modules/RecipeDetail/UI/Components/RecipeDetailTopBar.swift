//
//  RecipeDetailTopBar.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

/// The prototype draws a floating back button and a separate sticky title bar. They never
/// usefully coexist, so this is one control: the button is always present, and the bar's
/// background, border and title fade in together once the recipe's name scrolls away.
///
/// The title fades on `opacity` rather than being inserted, so it keeps its identity and
/// genuinely cross-fades with the background behind it; `accessibilityHidden` is what
/// takes it out of VoiceOver's reach while it is invisible.
struct RecipeDetailTopBar: View {
  let title: String
  let isTitleOffscreen: Bool
  let onBackTap: VoidResult

  var body: some View {
    HStack(spacing: spacing) {
      backButton

      Text(title)
        .themeTextStyle(.title2)
        .themeColor(.textPrimary)
        .lineLimit(1)
        .truncationMode(.tail)
        .opacity(isTitleOffscreen ? 1 : 0)
        .accessibilityHidden(!isTitleOffscreen)

      Spacer(minLength: 0)
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
      alignment: .leading
    )
    .background(background)
    .animation(
      .easeOut(duration: 0.25),
      value: isTitleOffscreen
    )
  }
}

// MARK: - Getters

extension RecipeDetailTopBar {
  static var baseButtonSize: CGFloat {
    56
  }
}

private extension RecipeDetailTopBar {
  var spacing: CGFloat {
    12
  }

  var horizontalPadding: CGFloat {
    20
  }

  var verticalPadding: CGFloat {
    10
  }
}

// MARK: - Subviews

private extension RecipeDetailTopBar {
  var backButton: some View {
    Button(
      action: onBackTap,
      label: {
        Image(systemName: "chevron.left")
          .themeTextStyle(.bodyBold)
          .foregroundStyle(.themeColor(.iconsDefault))
          .frame(
            width: Self.baseButtonSize,
            height: Self.baseButtonSize
          )
          .background(
            Color.themeColor(.surfacesBackground2),
            in: .circle
          )
      }
    )
    .buttonStyle(.plain)
    .cardShadow()
    .accessibilityIdentifier("recipe-detail-back-button")
    .accessibilityLabel(Text(.RecipeDetail.recipeDetailBackAccessibilityLabel))
  }

  var background: some View {
    Color.themeColor(.surfacesBackground2)
      .opacity(isTitleOffscreen ? 1 : 0)
      .overlay(alignment: .bottom) {
        Rectangle()
          .fill(.themeColor(.bordersDefault))
          .frame(height: isTitleOffscreen ? 1 : 0)
      }
      .ignoresSafeArea(edges: .top)
  }
}

#if DEBUG
  #Preview("Over a photograph") {
    RecipeDetailTopBar(
      title: "Spaghetti alla Carbonara",
      isTitleOffscreen: false,
      onBackTap: {}
    )
    .frame(
      maxWidth: .infinity,
      maxHeight: .infinity,
      alignment: .top
    )
    .background(Color.themeColor(.surfacesBackground3))
  }

  #Preview("Title scrolled away") {
    RecipeDetailTopBar(
      title: "Slow-Braised Beef Short Rib with Gremolata and Soft Polenta",
      isTitleOffscreen: true,
      onBackTap: {}
    )
    .frame(
      maxWidth: .infinity,
      maxHeight: .infinity,
      alignment: .top
    )
    .background(Color.themeColor(.surfacesBackground))
  }
#endif
