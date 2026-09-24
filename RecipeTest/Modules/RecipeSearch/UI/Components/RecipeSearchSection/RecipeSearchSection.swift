//
//  RecipeSearchSection.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

/// One card in the overlay. The title is optional because the two toggle sections carry their
/// heading inside the row, beside the switch.
struct RecipeSearchSection<Content: View>: View {
  let title: LocalizedStringResource?

  @ViewBuilder let content: () -> Content

  var body: some View {
    VStack(
      alignment: .leading,
      spacing: contentSpacing
    ) {
      if let title {
        Text(title)
          .themeTextStyle(.title3)
          .themeColor(.textPrimary)
          .accessibilityAddTraits(.isHeader)
      }

      content()
    }
    .frame(
      maxWidth: .infinity,
      alignment: .leading
    )
    .padding(contentInset)
    .background(
      Color.themeColor(.surfacesBackground2),
      in: .rect(cornerRadius: cornerRadius)
    )
    .cardShadow()
    .padding(
      .horizontal,
      horizontalGutter
    )
  }
}

// MARK: - Getters > Constants

private extension RecipeSearchSection {
  var contentSpacing: CGFloat {
    12
  }

  var contentInset: CGFloat {
    20
  }

  var cornerRadius: CGFloat {
    28
  }

  var horizontalGutter: CGFloat {
    20
  }
}

#if DEBUG
  #Preview("Titled") {
    RecipeSearchSection(title: .RecipeSearch.recipeSearchSectionServingsTitle) {
      Text(verbatim: "Content")
    }
    .frame(
      maxWidth: .infinity,
      maxHeight: .infinity
    )
    .background(Color.themeColor(.surfacesBackground))
  }

  #Preview("Untitled") {
    RecipeSearchSection(title: nil) {
      Text(verbatim: "Content")
    }
    .frame(
      maxWidth: .infinity,
      maxHeight: .infinity
    )
    .background(Color.themeColor(.surfacesBackground))
  }
#endif
