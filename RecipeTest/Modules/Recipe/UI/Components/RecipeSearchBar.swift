//
//  RecipeSearchBar.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

struct RecipeSearchBar: View {
  /// Deliberately inert — will push a filter page when wired.
  var onTap: VoidResult = DefaultClosure.voidResult()

  var body: some View {
    Button(action: onTap) {
      HStack(spacing: 8) {
        Image(systemName: "magnifyingglass")
          .foregroundStyle(Color.themeColor(.iconsSecondary))

        Text(String(localized: .Recipe.recipeListSearchPlaceholder))
          .themeTextStyle(.bodyRegular)
          .themeColor(.textTertiary)

        Spacer(minLength: 0)
      }
      .padding(.horizontal, 12)
      .frame(height: 44)
      .background(Color.themeColor(.surfacesFieldsAndTags))
      .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    .buttonStyle(.plain)
    .allowsHitTesting(false)
    .accessibilityIdentifier("recipeList.searchBar")
  }
}

// MARK: - Previews

#Preview {
  RecipeSearchBar()
    .padding()
    .background(Color.themeColor(.surfacesBackground))
}
