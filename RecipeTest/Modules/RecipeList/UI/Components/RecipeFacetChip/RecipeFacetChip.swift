//
//  RecipeFacetChip.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

struct RecipeFacetChip: View {
  let viewModel: any RecipeFacetChipViewModelProtocol
  let onRemoveTap: SingleResult<RecipeQueryFacet>

  var body: some View {
    Button(
      action: { onRemoveTap(viewModel.id) },
      label: {
        HStack(spacing: contentSpacing) {
          Text(viewModel.label)
            .themeTextStyle(.captionRegular)
            .themeColor(.textPrimary)

          Image(systemName: removeSymbolName)
            .foregroundStyle(.themeColor(.iconsSecondary))
        }
        .padding(
          .horizontal,
          horizontalGutter
        )
        .padding(
          .vertical,
          verticalGutter
        )
        .frame(minHeight: minimumTargetSize)
        .background(
          Color.themeColor(background),
          in: .capsule
        )
        .contentShape(.capsule)
      }
    )
    .buttonStyle(.plain)
    .accessibilityElement(children: .ignore)
    .accessibilityIdentifier("recipe-list-facet-chip-remove-button")
    .accessibilityLabel(Text(viewModel.removeAccessibilityLabel))
    .accessibilityAddTraits(.isButton)
  }
}

// MARK: - Getters

private extension RecipeFacetChip {
  var background: Color.ThemeColor {
    viewModel.isExclusion ? .complementaryShade3 : .surfacesFieldsAndTags
  }

  var contentSpacing: CGFloat {
    6
  }

  var horizontalGutter: CGFloat {
    12
  }

  var verticalGutter: CGFloat {
    6
  }

  var removeSymbolName: String {
    "xmark"
  }

  /// The glyph alone is about 15pt across. The whole chip is the button so the target
  /// clears the 44pt minimum without the capsule growing to match it visually.
  var minimumTargetSize: CGFloat {
    44
  }
}

#if DEBUG
  #Preview("Included") {
    RecipeFacetChip(
      viewModel: RecipeFacetChipViewModel(facet: .include("garlic")),
      onRemoveTap: { _ in }
    )
  }

  #Preview("Excluded") {
    RecipeFacetChip(
      viewModel: RecipeFacetChipViewModel(facet: .exclude("peanuts")),
      onRemoveTap: { _ in }
    )
  }
#endif
