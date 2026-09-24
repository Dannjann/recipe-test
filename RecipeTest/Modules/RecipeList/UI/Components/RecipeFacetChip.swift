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
    HStack(spacing: contentSpacing) {
      Text(viewModel.label)
        .themeTextStyle(.captionRegular)
        .themeColor(.textPrimary)

      Button(
        action: { onRemoveTap(viewModel.id) },
        label: {
          Image(systemName: removeSymbolName)
            .foregroundStyle(.themeColor(.iconsSecondary))
        }
      )
      .buttonStyle(.plain)
      .accessibilityLabel(Text(viewModel.removeAccessibilityLabel))
    }
    .padding(
      .horizontal,
      horizontalGutter
    )
    .padding(
      .vertical,
      verticalGutter
    )
    .background(
      Color.themeColor(background),
      in: .capsule
    )
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
