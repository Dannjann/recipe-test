//
//  RecipeDetailPlaceholderView.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

struct RecipeDetailPlaceholderView: View {
  let recipe: RecipeSummary

  var body: some View {
    VStack(spacing: 12) {
      Text(recipe.title)
        .themeTextStyle(.title2)
        .themeColor(.textPrimary)
        .multilineTextAlignment(.center)

      Text(String(localized: .Recipe.recipeDetailPlaceholderMessage))
        .themeTextStyle(.bodyRegular)
        .themeColor(.textSecondary)
        .multilineTextAlignment(.center)
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.themeColor(.surfacesBackground))
    .navigationTitle(Text(recipe.title))
    .navigationBarTitleDisplayMode(.inline)
  }
}

// MARK: - Previews

#Preview {
  NavigationStack {
    RecipeDetailPlaceholderView(recipe: .dummy())
  }
}
