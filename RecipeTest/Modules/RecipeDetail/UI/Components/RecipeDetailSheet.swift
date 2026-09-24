//
//  RecipeDetailSheet.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

/// The white panel that rides up over the gallery. The overview and the metric row come
/// from the summary and are always present; only the body waits on the request.
struct RecipeDetailSheet: View {
  let viewModel: any RecipeDetailViewModelProtocol

  var body: some View {
    VStack(
      alignment: .leading,
      spacing: 0
    ) {
      RecipeOverviewSection(
        title: viewModel.title,
        description: viewModel.descriptionText
      )

      RecipeMetricRow(
        cookingTimeText: viewModel.cookingTimeText,
        servingsText: viewModel.servingsText,
        difficultyText: viewModel.difficultyText
      )

      content(for: viewModel.detail)
    }
    .padding(
      .top,
      topPadding
    )
    .frame(
      maxWidth: .infinity,
      alignment: .leading
    )
    .background(Color.themeColor(.surfacesBackground2))
    .clipShape(.rect(
      topLeadingRadius: cornerRadius,
      topTrailingRadius: cornerRadius
    ))
    .padding(
      .top,
      -overlap
    )
  }
}

// MARK: - Getters

private extension RecipeDetailSheet {
  var topPadding: CGFloat {
    8
  }

  var cornerRadius: CGFloat {
    32
  }

  /// How far the sheet rides up over the gallery. Applied as negative padding rather than
  /// `.offset`, which would draw the panel up but still reserve its full height, leaving a
  /// band of the screen's background below the last step.
  var overlap: CGFloat {
    32
  }

  var bodyMinHeight: CGFloat {
    240
  }
}

// MARK: - Subviews

private extension RecipeDetailSheet {
  func content(for state: SectionState<Recipe>) -> some View {
    SectionStateView(
      state: state,
      minHeight: bodyMinHeight,
      emptyMessage: .RecipeDetail.recipeDetailDetailEmpty,
      onRetryTap: { Task { await viewModel.loadDetail() } },
      content: { recipe in
        RecipeDetailBody(
          recipe: recipe,
          checkedIngredientIDs: viewModel.checkedIngredientIDs,
          onIngredientTap: { id in viewModel.toggleIngredient(id: id) }
        )
      }
    )
  }
}

#if DEBUG
  #Preview("Loaded") {
    ScrollView {
      RecipeDetailSheet(viewModel: MockRecipeDetailViewModel.loaded())
    }
    .background(Color.themeColor(.surfacesBackground))
  }

  #Preview("Loading") {
    ScrollView {
      RecipeDetailSheet(viewModel: MockRecipeDetailViewModel.loading())
    }
    .background(Color.themeColor(.surfacesBackground))
  }

  #Preview("Failed") {
    ScrollView {
      RecipeDetailSheet(viewModel: MockRecipeDetailViewModel.failed())
    }
    .background(Color.themeColor(.surfacesBackground))
  }
#endif
