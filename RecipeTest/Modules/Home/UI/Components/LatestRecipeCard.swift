//
//  LatestRecipeCard.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

/// Both dimensions scale: the title sits inside the card, so a fixed box would clip it.
struct LatestRecipeCard: View {
  let recipe: RecipeSummary
  let onTap: SingleResult<String>

  @Environment(\.dynamicTypeSize) private var dynamicTypeSize

  @ScaledMetric(relativeTo: .body) private var width: CGFloat = LatestRecipeCard.baseWidth
  @ScaledMetric(relativeTo: .body) private var height: CGFloat = LatestRecipeCard.baseHeight

  var body: some View {
    Button(
      action: { onTap(recipe.id) },
      label: {
        photograph
          .frame(
            width: width,
            height: height
          )
          .overlay(alignment: .bottom) { gradient }
          .overlay(alignment: .bottomLeading) { title }
          .clipShape(.rect(cornerRadius: cornerRadius))
      }
    )
    .buttonStyle(.plain)
    .cardShadow()
    .accessibilityElement(children: .combine)
    .accessibilityLabel(Text(recipe.title))
    .accessibilityAddTraits(.isButton)
  }
}

// MARK: - Getters

extension LatestRecipeCard {
  static var baseWidth: CGFloat {
    170
  }

  static var baseHeight: CGFloat {
    240
  }
}

private extension LatestRecipeCard {
  var cornerRadius: CGFloat {
    28
  }

  var titleInset: CGFloat {
    16
  }

  var titleLineLimit: Int? {
    // Truncating is what a reader raised the text size to avoid.
    dynamicTypeSize.isAccessibilitySize ? nil : 2
  }
}

// MARK: - Subviews

private extension LatestRecipeCard {
  var photograph: some View {
    CachedAsyncImage(url: recipe.heroImageURL) {
      Color.themeColor(.surfacesBackground3)
    }
    .aspectRatio(contentMode: .fill)
    .frame(
      width: width,
      height: height
    )
    .clipped()
  }

  var gradient: some View {
    LinearGradient(
      stops: [
        .init(
          color: .black.opacity(0),
          location: 0.35
        ),
        .init(
          color: .black.opacity(0.3),
          location: 0.6
        ),
        .init(
          color: .black.opacity(0.8),
          location: 1
        ),
      ],
      startPoint: .top,
      endPoint: .bottom
    )
    .frame(height: height)
    .allowsHitTesting(false)
  }

  var title: some View {
    Text(recipe.title)
      .themeTextStyle(.bodyBold)
      .themeColor(.textWhite)
      .multilineTextAlignment(.leading)
      .lineLimit(titleLineLimit)
      .padding(titleInset)
  }
}

#if DEBUG
  #Preview("Card") {
    LatestRecipeCard(
      recipe: .dummy(),
      onTap: { _ in }
    )
    .frame(
      maxWidth: .infinity,
      maxHeight: .infinity
    )
    .background(Color.themeColor(.surfacesBackground))
  }

  #Preview("No photograph") {
    LatestRecipeCard(
      recipe: .dummy(
        title: "Pão de Queijo",
        heroImageURL: nil
      ),
      onTap: { _ in }
    )
    .frame(
      maxWidth: .infinity,
      maxHeight: .infinity
    )
    .background(Color.themeColor(.surfacesBackground))
  }

  #Preview("Long title, AX5") {
    LatestRecipeCard(
      recipe: .dummy(
        title: "Slow-Braised Beef Short Rib with Gremolata and Soft Polenta",
        heroImageURL: nil
      ),
      onTap: { _ in }
    )
    .environment(
      \.dynamicTypeSize,
      .accessibility5
    )
    .frame(
      maxWidth: .infinity,
      maxHeight: .infinity
    )
    .background(Color.themeColor(.surfacesBackground))
  }
#endif
