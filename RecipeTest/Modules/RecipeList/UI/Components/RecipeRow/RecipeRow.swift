//
//  RecipeRow.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

struct RecipeRow: View {
  let viewModel: any RecipeCardViewModelProtocol
  let onTap: SingleResult<RecipeSummary>

  @Environment(\.dynamicTypeSize) private var dynamicTypeSize

  @ScaledMetric(relativeTo: .body) private var scaledThumbnailSize: CGFloat = RecipeRow.baseThumbnailSize

  var body: some View {
    Button(
      action: { onTap(viewModel.summary) },
      label: {
        HStack(spacing: contentSpacing) {
          photograph

          details

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
    .accessibilityIdentifier("recipe-list-card-\(viewModel.id)")
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

// MARK: - Getters > Constants

private extension RecipeRow {
  /// At AX5 the raw scale takes 88pt past 270pt, leaving the title no room on a 393pt screen.
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

  var titleLineLimit: Int {
    2
  }
}

// MARK: - Subviews

private extension RecipeRow {
  /// `reservesSpace` holds both lines whether the name fills them or not, so a row is the
  /// same height whichever recipe it carries. At accessibility sizes truncating is what a
  /// reader raised the text size to avoid.
  @ViewBuilder
  var title: some View {
    let text = Text(viewModel.title)
      .themeTextStyle(.subheadlineSemibold)
      .themeColor(.textPrimary)
      .multilineTextAlignment(.leading)

    if dynamicTypeSize.isAccessibilitySize {
      text
    } else {
      text.lineLimit(
        titleLineLimit,
        reservesSpace: true
      )
    }
  }

  var details: some View {
    VStack(
      alignment: .leading,
      spacing: textSpacing
    ) {
      title

      if let cuisineAndCategory = viewModel.cuisineAndCategory {
        Text(cuisineAndCategory)
          .themeTextStyle(.captionRegular)
          .themeColor(.textSecondary)
      }

      RecipeCardMetadata(viewModel: viewModel)
    }
  }

  var photograph: some View {
    CachedAsyncImage(
      url: viewModel.imageURL,
      placeholder: { Color.themeColor(.surfacesBackground3) }
    )
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
