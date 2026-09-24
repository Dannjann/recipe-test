//
//  RecipeCard.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

struct RecipeCard: View {
  let viewModel: any RecipeCardViewModelProtocol
  let onTap: SingleResult<RecipeSummary>

  @Environment(\.dynamicTypeSize) private var dynamicTypeSize

  var body: some View {
    Button(
      action: { onTap(viewModel.summary) },
      label: {
        VStack(
          alignment: .leading,
          spacing: contentSpacing
        ) {
          photograph

          details
        }
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
    .accessibilityLabel(Text(viewModel.accessibilityLabel))
    .accessibilityAddTraits(.isButton)
  }
}

// MARK: - Getters

private extension RecipeCard {
  var contentSpacing: CGFloat {
    8
  }

  var textGutter: CGFloat {
    12
  }

  var cornerRadius: CGFloat {
    20
  }

  var titleLineLimit: Int {
    2
  }
}

// MARK: - Subviews

private extension RecipeCard {
  /// `reservesSpace` holds both lines whether the name fills them or not, so two cards in a
  /// grid row are the same height. At accessibility sizes the grid is a single column, so
  /// nothing sits alongside to line up with, and truncating is what a reader raised the text
  /// size to avoid.
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
      spacing: contentSpacing
    ) {
      title

      RecipeCardMetadata(viewModel: viewModel)
    }
    .frame(
      maxWidth: .infinity,
      alignment: .leading
    )
    .padding(
      .horizontal,
      textGutter
    )
    .padding(
      .bottom,
      textGutter
    )
  }

  var photograph: some View {
    CachedAsyncImage(
      url: viewModel.imageURL,
      placeholder: { Color.themeColor(.surfacesBackground3) }
    )
    .aspectRatio(contentMode: .fill)
    .frame(maxWidth: .infinity)
    .aspectRatio(
      1,
      contentMode: .fit
    )
    .clipShape(.rect(
      topLeadingRadius: cornerRadius,
      bottomLeadingRadius: 0,
      bottomTrailingRadius: 0,
      topTrailingRadius: cornerRadius
    ))
  }
}

#if DEBUG
  #Preview("Card") {
    RecipeCard(
      viewModel: MockRecipeListViewModel.sampleCards[0],
      onTap: { _ in }
    )
    .frame(width: 180)
    .frame(
      maxWidth: .infinity,
      maxHeight: .infinity
    )
    .background(Color.themeColor(.surfacesBackground))
  }

  #Preview("No photograph, no metrics") {
    RecipeCard(
      viewModel: MockRecipeListViewModel.bareCard,
      onTap: { _ in }
    )
    .frame(width: 180)
    .frame(
      maxWidth: .infinity,
      maxHeight: .infinity
    )
    .background(Color.themeColor(.surfacesBackground))
  }
#endif
