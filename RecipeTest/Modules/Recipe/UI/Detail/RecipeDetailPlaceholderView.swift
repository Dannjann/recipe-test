//
//  RecipeDetailPlaceholderView.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

struct RecipeDetailPlaceholderView: View {
  @Environment(\.theme) var theme: any ThemeProtocol

  let recipe: RecipeSummary

  var body: some View {
    VStack(spacing: 12) {
      Text(recipe.title)
        .font(theme.textStyle.title2.font)
        .foregroundStyle(theme.color.textPrimary.color)
        .multilineTextAlignment(.center)

      Text(String(localized: .Recipe.recipeDetailPlaceholderMessage))
        .font(theme.textStyle.bodyRegular.font)
        .foregroundStyle(theme.color.textSecondary.color)
        .multilineTextAlignment(.center)
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(theme.color.surfacesBackground.color)
    .navigationTitle(Text(recipe.title))
    .navigationBarTitleDisplayMode(.inline)
  }
}

// MARK: - Previews

#if DEBUG

  #Preview {
    NavigationStack {
      RecipeDetailPlaceholderView(recipe: .dummy())
    }
  }

#endif
