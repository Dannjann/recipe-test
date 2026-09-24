//
//  RecipeSearchFooter.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

/// Sits outside the scroll view, so Search is reachable however far down the filters run.
struct RecipeSearchFooter: View {
  let showsClearAll: Bool
  let onClearAllTap: VoidResult
  let onSubmitTap: VoidResult

  var body: some View {
    HStack(spacing: contentSpacing) {
      if showsClearAll {
        Button(
          action: onClearAllTap,
          label: {
            Text(.RecipeSearch.recipeSearchFooterClearAll)
              .themeTextStyle(.bodyBold)
              .themeColor(.textBrandDefault)
              .frame(minHeight: minimumTargetSize)
              .contentShape(.rect)
          }
        )
        .buttonStyle(.plain)
        .accessibilityIdentifier(RecipeSearchAccessibilityID.clearAllButton)
      }

      Spacer(minLength: 0)

      Button(
        action: onSubmitTap,
        label: {
          HStack(spacing: labelSpacing) {
            Image(systemName: searchSymbolName)

            Text(.RecipeSearch.recipeSearchFooterSubmit)
          }
          .themeTextStyle(.bodyBold)
          .foregroundStyle(.themeColor(.textInverted))
          .padding(
            .horizontal,
            buttonGutter
          )
          .frame(minHeight: minimumTargetSize)
          .background(
            Color.themeColor(.surfacesBrandDefault),
            in: .capsule
          )
          .contentShape(.capsule)
        }
      )
      .buttonStyle(.plain)
      .accessibilityIdentifier(RecipeSearchAccessibilityID.submitButton)
    }
    .padding(
      .horizontal,
      horizontalGutter
    )
    .padding(
      .vertical,
      verticalGutter
    )
    .background(.ultraThinMaterial)
  }
}

// MARK: - Getters > Constants

private extension RecipeSearchFooter {
  var contentSpacing: CGFloat {
    12
  }

  var labelSpacing: CGFloat {
    6
  }

  var horizontalGutter: CGFloat {
    20
  }

  var verticalGutter: CGFloat {
    12
  }

  var buttonGutter: CGFloat {
    24
  }

  var minimumTargetSize: CGFloat {
    44
  }

  var searchSymbolName: String {
    "magnifyingglass"
  }
}

#if DEBUG
  #Preview("With Clear all") {
    RecipeSearchFooter(
      showsClearAll: true,
      onClearAllTap: {},
      onSubmitTap: {}
    )
  }

  #Preview("Nothing to clear") {
    RecipeSearchFooter(
      showsClearAll: false,
      onClearAllTap: {},
      onSubmitTap: {}
    )
  }
#endif
