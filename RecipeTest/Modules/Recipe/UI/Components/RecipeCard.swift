//
//  RecipeCard.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

struct RecipeCard: View {
  @Environment(\.theme) private var theme: any ThemeProtocol
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize

  @ScaledMetric(relativeTo: .body) private var listImageSide: CGFloat = 96
  @ScaledMetric(relativeTo: .body) private var gridImageHeight: CGFloat = 120

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
      .accessibilityElement(children: .combine)
      .accessibilityIdentifier("recipeList.card.\(recipe.id)")
  }
}

// MARK: - Subviews

private extension RecipeCard {
  /// `AnyLayout`, not a `switch` returning two stacks: separate branches would give the
  /// arms separate structural identity, so toggling list↔grid would rebuild every card
  /// rather than transition it.
  var content: some View {
    cardLayout {
      image

      text
    }
  }

  /// Fixed in both axes, so images do not resize as they download and reflow the grid.
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
        .lineLimit(titleLineLimit)

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
  /// A list card stacks like a grid one at accessibility text sizes: a thumbnail scaled to
  /// match text that large leaves the title only a few points of width beside it.
  var effectiveLayout: RecipeListLayout {
    dynamicTypeSize.isAccessibilitySize ? .grid : layout
  }

  var cardLayout: AnyLayout {
    switch effectiveLayout {
    case .list: AnyLayout(HStackLayout(alignment: .top, spacing: Self.padding))
    case .grid: AnyLayout(VStackLayout(alignment: .leading, spacing: Self.padding))
    }
  }

  var imageWidth: CGFloat? {
    switch effectiveLayout {
    case .list: listImageSide
    case .grid: nil
    }
  }

  var imageHeight: CGFloat {
    switch effectiveLayout {
    case .list: listImageSide
    case .grid: gridImageHeight
    }
  }

  var imageMaxWidth: CGFloat? {
    switch effectiveLayout {
    case .list: nil
    case .grid: .infinity
    }
  }

  /// Unclamped at accessibility sizes: truncating is what the reader raised the text size
  /// to avoid, and the card is free to grow.
  var titleLineLimit: Int? {
    dynamicTypeSize.isAccessibilitySize ? nil : Self.titleLines
  }

  var descriptionLineLimit: Int? {
    guard !dynamicTypeSize.isAccessibilitySize else { return nil }

    switch effectiveLayout {
    case .list: return Self.listDescriptionLines
    case .grid: return Self.gridDescriptionLines
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

  static var titleLines: Int {
    2
  }

  static var listDescriptionLines: Int {
    2
  }

  static var gridDescriptionLines: Int {
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

  #Preview("List at an accessibility text size") {
    RecipeCard(recipe: .dummy(), layout: .list)
      .padding()
      .background(DefaultTheme().color.surfacesBackground.color)
      .dynamicTypeSize(.accessibility3)
  }

#endif
