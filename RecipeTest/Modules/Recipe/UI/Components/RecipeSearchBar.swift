//
//  RecipeSearchBar.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

/// Purely presentational — will be wrapped in a Button when search is wired.
struct RecipeSearchBar: View {
  @Environment(\.theme) private var theme: any ThemeProtocol

  var body: some View {
    HStack(spacing: Self.iconTextSpacing) {
      Image(systemName: "magnifyingglass")
        .foregroundStyle(theme.color.iconsSecondary.color)

      Text(String(localized: .Recipe.recipeListSearchPlaceholder))
        .font(theme.textStyle.bodyRegular.font)
        .foregroundStyle(theme.color.textTertiary.color)

      Spacer(minLength: 0)
    }
    .padding(.horizontal, Self.horizontalPadding)
    .frame(height: Self.height)
    .background(theme.color.surfacesFieldsAndTags.color)
    .clipShape(RoundedRectangle(cornerRadius: Self.cornerRadius))
    // Hidden until search is wired: otherwise it offers VoiceOver and Switch Control a
    // search field that does nothing.
    .accessibilityHidden(true)
    .accessibilityIdentifier("recipeList.searchBar")
  }
}

// MARK: - Constants

private extension RecipeSearchBar {
  static var iconTextSpacing: CGFloat {
    8
  }

  static var horizontalPadding: CGFloat {
    12
  }

  static var height: CGFloat {
    44
  }

  static var cornerRadius: CGFloat {
    10
  }
}

// MARK: - Previews

#if DEBUG

  #Preview {
    RecipeSearchBar()
      .padding()
      .background(DefaultTheme().color.surfacesBackground.color)
  }

#endif
