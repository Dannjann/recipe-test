//
//  RecipeSuggestionRow.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

struct RecipeSuggestionRow: View {
  let viewModel: any RecipeSuggestionRowViewModelProtocol
  let onTap: VoidResult

  var body: some View {
    Button(
      action: onTap,
      label: {
        HStack(spacing: contentSpacing) {
          tile

          VStack(
            alignment: .leading,
            spacing: labelSpacing
          ) {
            Text(viewModel.title)
              .themeTextStyle(.bodyBold)
              .themeColor(.textPrimary)
              .lineLimit(titleLineLimit)

            Text(viewModel.detail)
              .themeTextStyle(.footnoteRegular)
              .themeColor(.textSecondary)
              .lineLimit(titleLineLimit)
          }
          .frame(
            maxWidth: .infinity,
            alignment: .leading
          )
        }
        .padding(
          .vertical,
          verticalGutter
        )
        .padding(
          .horizontal,
          horizontalGutter
        )
        .contentShape(.rect)
      }
    )
    .buttonStyle(.plain)
    .accessibilityIdentifier(viewModel.accessibilityIdentifier)
  }
}

// MARK: - Subviews

private extension RecipeSuggestionRow {
  @ViewBuilder
  var tile: some View {
    if let imageURL = viewModel.imageURL {
      CachedAsyncImage(url: imageURL)
        .scaledToFill()
        .frame(
          width: tileSize,
          height: tileSize
        )
        .clipShape(.rect(cornerRadius: tileCornerRadius))
    } else {
      Image(systemName: viewModel.symbolName)
        .foregroundStyle(.themeColor(.iconsSecondary))
        .frame(
          width: tileSize,
          height: tileSize
        )
        .background(
          Color.themeColor(.surfacesFieldsAndTags),
          in: .rect(cornerRadius: tileCornerRadius)
        )
    }
  }
}

// MARK: - Getters > Constants

private extension RecipeSuggestionRow {
  var contentSpacing: CGFloat {
    12
  }

  var labelSpacing: CGFloat {
    2
  }

  var horizontalGutter: CGFloat {
    20
  }

  var verticalGutter: CGFloat {
    8
  }

  var tileSize: CGFloat {
    44
  }

  var tileCornerRadius: CGFloat {
    12
  }

  var titleLineLimit: Int {
    1
  }
}

#if DEBUG
  #Preview("Query") {
    RecipeSuggestionRow(
      viewModel: RecipeSuggestionRowViewModel(suggestion: .query("ado")),
      onTap: {}
    )
  }

  #Preview("Recent") {
    RecipeSuggestionRow(
      viewModel: RecipeSuggestionRowViewModel(suggestion: .recent("pho")),
      onTap: {}
    )
  }

  #Preview("Recipe") {
    RecipeSuggestionRow(
      viewModel: RecipeSuggestionRowViewModel(suggestion: .recipe(.dummy())),
      onTap: {}
    )
  }
#endif
