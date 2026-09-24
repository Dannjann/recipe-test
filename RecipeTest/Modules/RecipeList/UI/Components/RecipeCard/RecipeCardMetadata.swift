//
//  RecipeCardMetadata.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

/// The clock-and-servings strip both row presentations draw. Renders nothing at all when the
/// recipe carries neither metric, rather than leaving a stray separator behind.
struct RecipeCardMetadata: View {
  let viewModel: any RecipeCardViewModelProtocol

  @Environment(\.dynamicTypeSize) private var dynamicTypeSize

  var body: some View {
    layout {
      if let cookingTimeText = viewModel.cookingTimeText {
        metric(
          symbolName: clockSymbolName,
          text: cookingTimeText
        )
      }

      if let servingsText = viewModel.servingsText {
        metric(
          symbolName: servingsSymbolName,
          text: servingsText
        )
      }
    }
  }
}

// MARK: - Getters

private extension RecipeCardMetadata {
  var layout: AnyLayout {
    dynamicTypeSize.isAccessibilitySize
      ? AnyLayout(VStackLayout(
        alignment: .leading,
        spacing: itemSpacing
      ))
      : AnyLayout(HStackLayout(spacing: itemSpacing))
  }

  var itemSpacing: CGFloat {
    12
  }

  var contentSpacing: CGFloat {
    4
  }

  var clockSymbolName: String {
    "clock"
  }

  var servingsSymbolName: String {
    "person.2"
  }
}

// MARK: - Subviews

private extension RecipeCardMetadata {
  func metric(
    symbolName: String,
    text: String
  ) -> some View {
    HStack(spacing: contentSpacing) {
      Image(systemName: symbolName)
        .foregroundStyle(.themeColor(.iconsSecondary))

      Text(text)
        .themeTextStyle(.captionRegular)
        .themeColor(.textSecondary)
    }
  }
}

#if DEBUG
  #Preview("Both metrics") {
    RecipeCardMetadata(viewModel: MockRecipeListViewModel.sampleCards[0])
  }

  #Preview("Neither metric") {
    RecipeCardMetadata(viewModel: MockRecipeListViewModel.bareCard)
      .border(Color.themeColor(.bordersDefault))
  }
#endif
