//
//  RecipeCard.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

/// The grid presentation of one result: a square photograph above the name and metrics.
struct RecipeCard: View {
  let viewModel: any RecipeCardViewModelProtocol
  let onTap: SingleResult<RecipeSummary>

  var body: some View {
    Button(
      action: { onTap(viewModel.summary) },
      label: {
        VStack(
          alignment: .leading,
          spacing: contentSpacing
        ) {
          photograph

          VStack(
            alignment: .leading,
            spacing: contentSpacing
          ) {
            Text(viewModel.title)
              .themeTextStyle(.subheadlineSemibold)
              .themeColor(.textPrimary)
              .multilineTextAlignment(.leading)

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
        .background(
          Color.themeColor(.surfacesBackground2),
          in: .rect(cornerRadius: cornerRadius)
        )
      }
    )
    .buttonStyle(.plain)
    .cardShadow()
    .accessibilityElement(children: .combine)
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
}

// MARK: - Subviews

private extension RecipeCard {
  var photograph: some View {
    CachedAsyncImage(url: viewModel.imageURL) {
      Color.themeColor(.surfacesBackground3)
    }
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
