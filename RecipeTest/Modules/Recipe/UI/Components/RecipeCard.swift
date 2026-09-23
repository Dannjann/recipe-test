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
          .stroke(theme.color.bordersDefault.color, lineWidth: Self.borderWidth)
      }
      // One element, not three. Without this, VoiceOver stops on the image, the title and
      // the description separately for every card in a 36-row list.
      .accessibilityElement(children: .combine)
      .accessibilityIdentifier("recipeList.card.\(recipe.id)")
  }
}

// MARK: - Subviews

private extension RecipeCard {
  /// `AnyLayout`, not a `switch` returning two stacks: separate branches would give the
  /// arms separate structural identity, so toggling list↔grid would tear down and rebuild
  /// every card rather than transition it.
  var content: some View {
    cardLayout {
      image

      text
    }
  }

  /// Fixed frames in both axes prevent images from sizing themselves as they download,
  /// which would reflow the entire grid.
  var image: some View {
    CachedAsyncImage(url: recipe.heroImageURL)
      .scaledToFill()
      .frame(width: imageWidth, height: imageHeight)
      .frame(maxWidth: imageMaxWidth)
      .clipped()
      .clipShape(RoundedRectangle(cornerRadius: Self.imageCornerRadius))
  }

  var text: some View {
    VStack(alignment: .leading, spacing: Self.textSpacing) {
      Text(recipe.title)
        .font(theme.textStyle.bodySemibold.font)
        .foregroundStyle(theme.color.textPrimary.color)
        .lineLimit(Self.titleLineLimit)

      Text(recipe.shortDescription)
        .font(theme.textStyle.subheadlineRegular.font)
        .foregroundStyle(theme.color.textSecondary.color)
        .lineLimit(descriptionLineLimit)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

// MARK: - Getters

private extension RecipeCard {
  var cardLayout: AnyLayout {
    switch layout {
    case .list: AnyLayout(HStackLayout(alignment: .top, spacing: Self.padding))
    case .grid: AnyLayout(VStackLayout(alignment: .leading, spacing: Self.padding))
    }
  }

  var imageWidth: CGFloat? {
    switch layout {
    case .list: Self.listImageSide
    case .grid: nil
    }
  }

  var imageHeight: CGFloat {
    switch layout {
    case .list: Self.listImageSide
    case .grid: Self.gridImageHeight
    }
  }

  var imageMaxWidth: CGFloat? {
    switch layout {
    case .list: nil
    case .grid: .infinity
    }
  }

  var descriptionLineLimit: Int {
    switch layout {
    case .list: Self.listDescriptionLineLimit
    case .grid: Self.gridDescriptionLineLimit
    }
  }
}

// MARK: - Constants

private extension RecipeCard {
  static var padding: CGFloat {
    12
  }

  static var textSpacing: CGFloat {
    4
  }

  static var cornerRadius: CGFloat {
    12
  }

  static var imageCornerRadius: CGFloat {
    8
  }

  static var borderWidth: CGFloat {
    1
  }

  static var listImageSide: CGFloat {
    96
  }

  static var gridImageHeight: CGFloat {
    120
  }

  static var titleLineLimit: Int {
    2
  }

  static var listDescriptionLineLimit: Int {
    2
  }

  static var gridDescriptionLineLimit: Int {
    3
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
