//
//  RecipeListMessageView.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

/// The list's two non-content states — nothing to show, and could not load — drawn the
/// same way. Vertical sizing is left to the caller: the failed state fills the screen,
/// the empty one fills its scroll container so it can still be pulled to refresh.
struct RecipeListMessageView: View {
  @Environment(\.theme) private var theme: any ThemeProtocol

  let title: String
  var detail: String?
  var onRetry: (() async -> Void)?

  var body: some View {
    VStack(spacing: Self.spacing) {
      Text(title)
        .font(theme.textStyle.bodySemibold.font)
        .foregroundStyle(theme.color.textPrimary.color)
        .multilineTextAlignment(.center)

      if let detail {
        Text(detail)
          .font(theme.textStyle.subheadlineRegular.font)
          .foregroundStyle(theme.color.textSecondary.color)
          .multilineTextAlignment(.center)
      }

      if let onRetry {
        Button(String(localized: .Recipe.recipeListErrorRetry)) {
          Task { await onRetry() }
        }
        .font(theme.textStyle.bodySemibold.font)
        .padding(.top, Self.retryTopPadding)
      }
    }
    .padding(RecipeListLayout.spacing * 2)
    .frame(maxWidth: .infinity)
  }
}

// MARK: - Constants

private extension RecipeListMessageView {
  static var spacing: CGFloat {
    8
  }

  static var retryTopPadding: CGFloat {
    4
  }
}

// MARK: - Previews

#if DEBUG

  #Preview("Empty") {
    RecipeListMessageView(
      title: String(localized: .Recipe.recipeListEmptyTitle),
      detail: String(localized: .Recipe.recipeListEmptyMessage)
    )
  }

  #Preview("Failed with retry") {
    RecipeListMessageView(
      title: AppError.noInternetConnection.localizedDescription,
      onRetry: {}
    )
  }

#endif
