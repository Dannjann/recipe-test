//
//  RecipeSuggestionSection.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

struct RecipeSuggestionSection: View {
  let viewModel: RecipeSuggestionSectionViewModel
  let onRowTap: SingleResult<RecipeSuggestionRowViewModel>

  var body: some View {
    VStack(
      alignment: .leading,
      spacing: contentSpacing
    ) {
      if let title = viewModel.title {
        Text(title)
          .themeTextStyle(.subheadlineSemibold)
          .themeColor(.textSecondary)
          .accessibilityAddTraits(.isHeader)
          .padding(
            .horizontal,
            horizontalGutter
          )
      }

      ForEach(viewModel.rows) { row in
        RecipeSuggestionRow(
          viewModel: row,
          onTap: { onRowTap(row) }
        )
      }
    }
  }
}

// MARK: - Getters

private extension RecipeSuggestionSection {
  var contentSpacing: CGFloat {
    8
  }

  var horizontalGutter: CGFloat {
    20
  }
}

#if DEBUG
  #Preview {
    RecipeSuggestionSection(
      viewModel: RecipeSuggestionSectionViewModel(
        id: "recent",
        title: .RecipeSearch.recipeSearchSuggestionSectionRecent,
        rows: ["pho", "adobo"].map { RecipeSuggestionRowViewModel(suggestion: .recent($0)) }
      ),
      onRowTap: { _ in }
    )
  }
#endif
