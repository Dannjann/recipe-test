//
//  RecipeLayoutToggle.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

struct RecipeLayoutToggle: View {
  @Environment(\.theme) var theme: any ThemeProtocol

  let layout: RecipeListLayout
  let onSelect: SingleResult<RecipeListLayout>

  var body: some View {
    Button {
      onSelect(layout.toggled)
    } label: {
      Image(systemName: iconName)
        .foregroundStyle(theme.color.iconsDefault.color)
    }
    .accessibilityLabel(Text(accessibilityLabel))
    .accessibilityIdentifier("recipeList.layoutToggle")
  }
}

// MARK: - Getters

private extension RecipeLayoutToggle {
  var destination: RecipeListLayout {
    layout.toggled
  }

  /// Shows the layout the button switches *to*.
  var iconName: String {
    switch destination {
    case .list: "list.bullet"
    case .grid: "square.grid.2x2"
    }
  }

  var accessibilityLabel: String {
    switch destination {
    case .list: String(localized: .Recipe.recipeListLayoutList)
    case .grid: String(localized: .Recipe.recipeListLayoutGrid)
    }
  }
}

// MARK: - Previews

#if DEBUG

  #Preview("Currently list") {
    RecipeLayoutToggle(layout: .list, onSelect: { _ in })
  }

  #Preview("Currently grid") {
    RecipeLayoutToggle(layout: .grid, onSelect: { _ in })
  }

#endif
