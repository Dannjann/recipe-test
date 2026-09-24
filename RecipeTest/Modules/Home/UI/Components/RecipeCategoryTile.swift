//
//  RecipeCategoryTile.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

/// `baseWidth` is what three columns, 20pt margins and 14pt gutters leave on the narrowest phone.
struct RecipeCategoryTile: View {
  let category: RecipeCategory
  let onTap: SingleResult<RecipeCategory>

  var body: some View {
    Button {
      onTap(category)
    } label: {
      VStack(spacing: 8) {
        photograph

        Text(category.name)
          .themeTextStyle(.subheadlineSemibold)
          .themeColor(.textPrimary)
          .multilineTextAlignment(.center)
      }
    }
    .buttonStyle(.plain)
    .accessibilityElement(children: .combine)
    .accessibilityLabel(Text(category.name))
    .accessibilityAddTraits(.isButton)
  }
}

// MARK: - Getters

extension RecipeCategoryTile {
  static var baseWidth: CGFloat {
    104
  }
}

// MARK: - Subviews

private extension RecipeCategoryTile {
  var photograph: some View {
    CachedAsyncImage(url: category.imageURL) {
      Color.themeColor(.surfacesBackground3)
    }
    .aspectRatio(contentMode: .fill)
    .frame(maxWidth: .infinity)
    .aspectRatio(1, contentMode: .fit)
    .clipShape(.rect(cornerRadius: 24))
    .cardShadow()
  }
}

#Preview("Tile") {
  RecipeCategoryTile(category: .dummy(), onTap: { _ in })
    .frame(width: RecipeCategoryTile.baseWidth)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.themeColor(.surfacesBackground))
}

#Preview("No photograph, long name") {
  RecipeCategoryTile(category: .dummy(name: "Slow Cooker Dinners", imageURL: nil), onTap: { _ in })
    .frame(width: RecipeCategoryTile.baseWidth)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.themeColor(.surfacesBackground))
}
