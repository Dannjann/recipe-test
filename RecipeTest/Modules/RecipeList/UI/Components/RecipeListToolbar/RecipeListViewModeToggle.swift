//
//  RecipeListViewModeToggle.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

struct RecipeListViewModeToggle: View {
  let viewModel: any RecipeListViewModelProtocol
  let onSelect: SingleResult<RecipeListViewMode>

  @Namespace private var indicator

  var body: some View {
    HStack(spacing: trackSpacing) {
      ForEach(viewModel.viewModeSegments) { segment in
        segmentView(for: segment)
      }
    }
    .padding(trackInset)
    .background(
      Color.themeColor(.surfacesFieldsAndTags),
      in: .capsule
    )
    .animation(
      .snappy,
      value: viewModel.viewMode
    )
    .accessibilityElement(children: .contain)
  }
}

// MARK: - Getters

private extension RecipeListViewModeToggle {
  var contentSpacing: CGFloat {
    6
  }

  var trackSpacing: CGFloat {
    0
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
}

// MARK: - Subviews

private extension RecipeListViewModeToggle {
  func segmentView(for segment: any RecipeListViewModeSegmentViewModelProtocol) -> some View {
    Button(
      action: { onSelect(segment.mode) },
      label: {
        HStack(spacing: contentSpacing) {
          Image(systemName: segment.symbolName)

          Text(segment.label)
            .themeTextStyle(.captionBold)
        }
        .foregroundStyle(.themeColor(segment.foregroundColorStyle))
        .padding(
          .horizontal,
          horizontalGutter
        )
        .padding(
          .vertical,
          verticalGutter
        )
        .background { indicatorView(for: segment) }
      }
    )
    .buttonStyle(.plain)
    .accessibilityIdentifier(segment.accessibilityIdentifier)
    .accessibilityLabel(Text(segment.label))
    .accessibilityAddTraits(segment.showsIndicator ? [.isButton, .isSelected] : .isButton)
  }

  @ViewBuilder
  func indicatorView(for segment: any RecipeListViewModeSegmentViewModelProtocol) -> some View {
    if segment.showsIndicator {
      Capsule()
        .fill(Color.themeColor(.surfacesBrandDefault))
        .matchedGeometryEffect(
          id: indicatorID,
          in: indicator
        )
    }
  }
}

#if DEBUG
  #Preview("Grid selected") {
    RecipeListViewModeToggle(
      viewModel: MockRecipeListViewModel.loaded(),
      onSelect: { _ in }
    )
  }

  #Preview("List selected") {
    RecipeListViewModeToggle(
      viewModel: MockRecipeListViewModel.loaded(viewMode: .list),
      onSelect: { _ in }
    )
  }
#endif
