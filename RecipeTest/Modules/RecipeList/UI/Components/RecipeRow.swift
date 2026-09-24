//
//  RecipeRow.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

/// The list presentation of one result: a thumbnail beside the name, its cuisine and
/// category, and the same metrics the grid card draws.
struct RecipeRow: View {
  let viewModel: any RecipeCardViewModelProtocol
  let onTap: SingleResult<RecipeSummary>

  @ScaledMetric(relativeTo: .body) private var scaledThumbnailSize: CGFloat = RecipeRow.baseThumbnailSize

  var body: some View {
    Button(
      action: { onTap(viewModel.summary) },
      label: {
        HStack(spacing: contentSpacing) {
          photograph

          VStack(
            alignment: .leading,
            spacing: textSpacing
          ) {
            Text(viewModel.title)
              .themeTextStyle(.subheadlineSemibold)
              .themeColor(.textPrimary)
              .multilineTextAlignment(.leading)

            if let cuisineAndCategory = viewModel.cuisineAndCategory {
              Text(cuisineAndCategory)
                .themeTextStyle(.captionRegular)
                .themeColor(.textSecondary)
            }

            RecipeCardMetadata(viewModel: viewModel)
          }

          Spacer(minLength: 0)
        }
        .padding(contentGutter)
        .background(
          Color.themeColor(.surfacesBackground2),
          in: .rect(cornerRadius: cornerRadius)
        )
      }
    )
    .buttonStyle(.plain)
    .cardShadow()
    .accessibilityElement(children: .combine)
    .accessibilityLabel(Text(viewModel.rowAccessibilityLabel))
    .accessibilityAddTraits(.isButton)
  }
}

// MARK: - Getters

extension RecipeRow {
  static var baseThumbnailSize: CGFloat {
    88
  }
}

private extension RecipeRow {
  /// Clamped rather than left to scale freely: at AX5 the raw scale takes 88pt past 270pt,
  /// which on a 393pt screen leaves the title about two characters of width.
  var thumbnailSize: CGFloat {
    min(
      scaledThumbnailSize,
      maxThumbnailSize
    )
  }

  var maxThumbnailSize: CGFloat {
    132
  }

  var contentSpacing: CGFloat {
    12
  }

  var textSpacing: CGFloat {
    4
  }

  var contentGutter: CGFloat {
    12
  }

  var cornerRadius: CGFloat {
    20
  }

  var thumbnailCornerRadius: CGFloat {
    14
  }
}

// MARK: - Subviews

private extension RecipeRow {
  var photograph: some View {
    CachedAsyncImage(url: viewModel.imageURL) {
      Color.themeColor(.surfacesBackground3)
    }
    .aspectRatio(contentMode: .fill)
    .frame(
      width: thumbnailSize,
      height: thumbnailSize
    )
    .clipShape(.rect(cornerRadius: thumbnailCornerRadius))
  }
}

#if DEBUG
  #Preview("Row") {
    RecipeRow(
      viewModel: MockRecipeListViewModel.sampleCards[0],
      onTap: { _ in }
    )
    .padding()
    .frame(
      maxWidth: .infinity,
      maxHeight: .infinity
    )
    .background(Color.themeColor(.surfacesBackground))
  }

  #Preview("No photograph, no metrics") {
    RecipeRow(
      viewModel: MockRecipeListViewModel.bareCard,
      onTap: { _ in }
    )
    .padding()
    .frame(
      maxWidth: .infinity,
      maxHeight: .infinity
    )
    .background(Color.themeColor(.surfacesBackground))
  }
#endif
