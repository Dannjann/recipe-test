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
    Button {
      onTap(recipe.id)
    } label: {
      photograph
        .frame(width: width, height: height)
        .overlay(alignment: .bottom) { gradient }
        .overlay(alignment: .bottomLeading) { title }
        .clipShape(.rect(cornerRadius: 28))
    }
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

// MARK: - Subviews

private extension LatestRecipeCard {
  var photograph: some View {
    CachedAsyncImage(url: recipe.heroImageURL) {
      Color.themeColor(.surfacesBackground3)
    }
    .aspectRatio(contentMode: .fill)
    .frame(width: width, height: height)
    .clipped()
  }

  var gradient: some View {
    LinearGradient(
      stops: [
        .init(color: .black.opacity(0), location: 0.35),
        .init(color: .black.opacity(0.3), location: 0.6),
        .init(color: .black.opacity(0.8), location: 1),
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
      // Truncating is what a reader raised the text size to avoid.
      .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)
      .padding(16)
  }
}

#Preview("Card") {
  LatestRecipeCard(recipe: .init(
    id: "rcp-001",
    title: "Spaghetti alla Carbonara",
    heroImageURL: URL(string: "https://www.themealdb.com/images/media/meals/llcbn01574260722.jpg"),
    category: "Pasta",
    cuisine: "italian",
    mealType: "dinner",
    totalTimeMinutes: 25,
    servings: 4,
    difficulty: .medium,
    isVegetarian: false
  ), onTap: { _ in })
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.themeColor(.surfacesBackground))
}

#Preview("Card — no photograph") {
  LatestRecipeCard(recipe: .init(
    id: "rcp-002",
    title: "Pão de Queijo",
    heroImageURL: nil,
    category: "Snacks",
    cuisine: "brazilian",
    mealType: "snack",
    totalTimeMinutes: 40,
    servings: 6,
    difficulty: .easy,
    isVegetarian: true
  ), onTap: { _ in })
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.themeColor(.surfacesBackground))
}

#Preview("Card — long title, AX5") {
  LatestRecipeCard(recipe: .init(
    id: "rcp-003",
    title: "Slow-Braised Beef Short Rib with Gremolata and Soft Polenta",
    heroImageURL: nil,
    category: "Meal",
    cuisine: "italian",
    mealType: "dinner",
    totalTimeMinutes: 240,
    servings: 4,
    difficulty: .hard,
    isVegetarian: false
  ), onTap: { _ in })
    .environment(\.dynamicTypeSize, .accessibility5)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.themeColor(.surfacesBackground))
}
