//
//  RecipeIngredientChip.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

struct RecipeIngredientChip: View {
  let viewModel: any RecipeIngredientChipViewModelProtocol
  let onRemoveTap: VoidResult

  var body: some View {
    Button(
      action: onRemoveTap,
      label: {
        HStack(spacing: contentSpacing) {
          Text(viewModel.label)
            .themeTextStyle(.captionRegular)
            .themeColor(.textPrimary)

          Image(systemName: removeSymbolName)
            .themeTextStyle(.captionBold)
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

// MARK: - Getters > Constants

private extension RecipeIngredientChip {
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
    RecipeIngredientChip(
      viewModel: RecipeIngredientChipViewModel(
        ingredient: "garlic",
        kind: .include
      ),
      onRemoveTap: {}
    )
  }

  #Preview("Excluded") {
    RecipeIngredientChip(
      viewModel: RecipeIngredientChipViewModel(
        ingredient: "pork",
        kind: .exclude
      ),
      onRemoveTap: {}
    )
  }
#endif
