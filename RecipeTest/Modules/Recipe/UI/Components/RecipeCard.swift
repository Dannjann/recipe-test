//
//  RecipeCard.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

struct RecipeCard: View {
  @Environment(\.theme) var theme: any ThemeProtocol

  let recipe: RecipeSummary
  let layout: RecipeListLayout

  var body: some View {
    content
      .padding(Self.padding)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(theme.color.surfacesBackground2.color)
      .clipShape(RoundedRectangle(cornerRadius: Self.cornerRadius))
      .overlay {
        RoundedRectangle(cornerRadius: Self.cornerRadius)
          .stroke(theme.color.bordersDefault.color, lineWidth: 1)
      }
      // One element, not three. Without this, VoiceOver stops on the image, the title and
      // the description separately for every card in a 36-row list.
      .accessibilityElement(children: .combine)
      .accessibilityIdentifier("recipeList.card.\(recipe.id)")
  }
}

// MARK: - Subviews

private extension RecipeCard {
  @ViewBuilder
  var content: some View {
    switch layout {
    case .list:
      HStack(alignment: .top, spacing: Self.padding) {
        image

        text
      }

    case .grid:
      VStack(alignment: .leading, spacing: Self.padding) {
        image

        text
      }
    }
  }

  /// Fixed frames in both axes prevent images from sizing themselves as they download,
  /// which would reflow the entire grid.
  @ViewBuilder
  var image: some View {
    switch layout {
    case .list:
      CachedAsyncImage(url: recipe.heroImageURL)
        .aspectRatio(contentMode: .fill)
        .frame(width: Self.listImageSide, height: Self.listImageSide)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: Self.imageCornerRadius))

    case .grid:
      CachedAsyncImage(url: recipe.heroImageURL)
        .aspectRatio(contentMode: .fill)
        .frame(height: Self.gridImageHeight)
        .frame(maxWidth: .infinity)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: Self.imageCornerRadius))
    }
  }

  var text: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(recipe.title)
        .font(theme.textStyle.bodySemibold.font)
        .foregroundStyle(theme.color.textPrimary.color)
        .lineLimit(2)

      Text(recipe.shortDescription)
        .font(theme.textStyle.subheadlineRegular.font)
        .foregroundStyle(theme.color.textSecondary.color)
        .lineLimit(layout == .list ? 2 : 3)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

// MARK: - Constants

private extension RecipeCard {
  static var padding: CGFloat {
    12
  }

  static var cornerRadius: CGFloat {
    12
  }

  static var imageCornerRadius: CGFloat {
    8
  }

  static var listImageSide: CGFloat {
    96
  }

  static var gridImageHeight: CGFloat {
    120
  }
}

// MARK: - Previews

#if DEBUG

  #Preview("List") {
    RecipeCard(recipe: .dummy(), layout: .list)
      .padding()
      .background(DefaultTheme().color.surfacesBackground.color)
  }

  #Preview("Grid") {
    HStack(spacing: RecipeListLayout.spacing) {
      RecipeCard(recipe: .dummy(), layout: .grid)
      RecipeCard(recipe: .dummy(id: "rcp-002", title: "Miso-Glazed Aubergine"), layout: .grid)
    }
    .padding()
    .background(DefaultTheme().color.surfacesBackground.color)
  }

  #Preview("Long title and description") {
    RecipeCard(
      recipe: .dummy(
        title: "Slow-Braised Beef Short Rib with Gremolata and Soft Polenta",
        shortDescription: String(repeating: "A very long description that must not be allowed to run away. ", count: 4)
      ),
      layout: .list
    )
    .padding()
    .background(DefaultTheme().color.surfacesBackground.color)
  }

#endif
