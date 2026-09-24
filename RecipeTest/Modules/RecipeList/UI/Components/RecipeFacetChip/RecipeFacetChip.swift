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
          Color.themeColor(viewModel.backgroundColorStyle),
          in: .capsule
        )
        .contentShape(.capsule)
      }
    )
    .buttonStyle(.plain)
    .accessibilityElement(children: .ignore)
    .accessibilityIdentifier(viewModel.accessibilityIdentifier)
    .accessibilityLabel(Text(viewModel.removeAccessibilityLabel))
    .accessibilityAddTraits(.isButton)
  }
}

// MARK: - Getters

private extension RecipeFacetChip {
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

  /// The whole chip is the button, so the target clears 44pt without the capsule growing.
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
