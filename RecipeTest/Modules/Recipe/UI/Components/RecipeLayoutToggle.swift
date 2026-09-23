//
//  RecipeLayoutToggle.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

struct RecipeLayoutToggle: View {
  let layout: RecipeListLayout
  let onSelect: SingleResult<RecipeListLayout>

  var body: some View {
    Button {
      onSelect(layout.toggled)
    } label: {
      Image(systemName: iconName)
        .foregroundStyle(Color.themeColor(.iconsDefault))
    }
    .accessibilityLabel(Text(accessibilityLabel))
    .accessibilityIdentifier("recipeList.layoutToggle")
  }
}

// MARK: - Getters

private extension RecipeLayoutToggle {
  /// Shows the layout the button switches *to*.
  var iconName: String {
    switch layout.toggled {
    case .list: "list.bullet"
    case .grid: "square.grid.2x2"
    }
  }

  var accessibilityLabel: String {
    switch layout.toggled {
    case .list: String(localized: .Recipe.recipeListLayoutList)
    case .grid: String(localized: .Recipe.recipeListLayoutGrid)
    }
  }
}

// MARK: - Previews

#Preview("Currently list") {
  RecipeLayoutToggle(layout: .list, onSelect: { _ in })
}

#Preview("Currently grid") {
  RecipeLayoutToggle(layout: .grid, onSelect: { _ in })
}
