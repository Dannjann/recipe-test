//
//  MainIngredientTile.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

struct MainIngredientTile: View {
  let ingredient: RecipeIngredient

  var body: some View {
    VStack(spacing: spacing) {
      CachedAsyncImage(url: ingredient.imageURL) {
        Color.themeColor(.surfacesBackground3)
      }
      .aspectRatio(contentMode: .fill)
      .frame(
        width: Self.baseImageSize,
        height: Self.baseImageSize
      )
      .clipShape(.rect(cornerRadius: cornerRadius))

      Text(ingredient.name)
        .themeTextStyle(.footnoteBold)
        .themeColor(.textPrimary)
        .multilineTextAlignment(.center)
    }
    .frame(width: Self.baseWidth)
    .accessibilityElement(children: .combine)
  }
}

// MARK: - Getters

extension MainIngredientTile {
  static var baseImageSize: CGFloat {
    74
  }

  static var baseWidth: CGFloat {
    78
  }
}

private extension MainIngredientTile {
  var spacing: CGFloat {
    8
  }

  var cornerRadius: CGFloat {
    22
  }
}

#if DEBUG
  #Preview("No photograph") {
    MainIngredientTile(ingredient: .dummy())
      .padding(20)
      .background(Color.themeColor(.surfacesBackground2))
  }

  #Preview("Long name, AX3") {
    MainIngredientTile(ingredient: .dummy(name: "Flat-Leaf Parsley"))
      .padding(20)
      .background(Color.themeColor(.surfacesBackground2))
      .environment(
        \.dynamicTypeSize,
        .accessibility3
      )
  }
#endif
