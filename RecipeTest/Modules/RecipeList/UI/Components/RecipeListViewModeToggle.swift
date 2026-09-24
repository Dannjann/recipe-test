//
//  RecipeListViewModeToggle.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

/// The prototype's segmented control, indicator and all. A pair of `Button`s rather than a
/// `Picker`, because the selected capsule slides between them.
struct RecipeListViewModeToggle: View {
  let selected: RecipeListViewMode
  let onSelect: SingleResult<RecipeListViewMode>

  @Namespace private var indicator

  var body: some View {
    HStack(spacing: 0) {
      ForEach(
        RecipeListViewMode.allCases,
        id: \.self
      ) { mode in
        segment(for: mode)
      }
    }
    .padding(trackInset)
    .background(
      Color.themeColor(.surfacesFieldsAndTags),
      in: .capsule
    )
    .animation(
      .snappy,
      value: selected
    )
    .accessibilityElement(children: .contain)
  }
}

// MARK: - Getters

private extension RecipeListViewModeToggle {
  var contentSpacing: CGFloat {
    6
  }

  var trackInset: CGFloat {
    4
  }

  var horizontalGutter: CGFloat {
    12
  }

  var verticalGutter: CGFloat {
    6
  }

  var indicatorID: String {
    "selected"
  }

  func label(for mode: RecipeListViewMode) -> LocalizedStringResource {
    switch mode {
    case .grid:
      .RecipeList.recipeListViewModeGrid

    case .list:
      .RecipeList.recipeListViewModeList
    }
  }

  func symbolName(for mode: RecipeListViewMode) -> String {
    switch mode {
    case .grid:
      "square.grid.2x2"

    case .list:
      "list.bullet"
    }
  }
}

// MARK: - Subviews

private extension RecipeListViewModeToggle {
  func segment(for mode: RecipeListViewMode) -> some View {
    let isSelected = mode == selected

    return Button(
      action: { onSelect(mode) },
      label: {
        HStack(spacing: contentSpacing) {
          Image(systemName: symbolName(for: mode))

          Text(label(for: mode))
            .themeTextStyle(.captionBold)
        }
        .foregroundStyle(.themeColor(isSelected ? .textInverted : .textPrimary))
        .padding(
          .horizontal,
          horizontalGutter
        )
        .padding(
          .vertical,
          verticalGutter
        )
        .background {
          if isSelected {
            Capsule()
              .fill(Color.themeColor(.surfacesBrandDefault))
              .matchedGeometryEffect(
                id: indicatorID,
                in: indicator
              )
          }
        }
      }
    )
    .buttonStyle(.plain)
    .accessibilityLabel(Text(label(for: mode)))
    .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
  }
}

#if DEBUG
  #Preview("Grid selected") {
    RecipeListViewModeToggle(
      selected: .grid,
      onSelect: { _ in }
    )
  }

  #Preview("List selected") {
    RecipeListViewModeToggle(
      selected: .list,
      onSelect: { _ in }
    )
  }
#endif
