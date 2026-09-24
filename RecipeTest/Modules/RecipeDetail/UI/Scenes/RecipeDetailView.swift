//
//  RecipeDetailView.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

struct RecipeDetailView: View {
  let viewModel: any RecipeDetailViewModelProtocol
  let onBackTap: VoidResult

  @State private var isTitleOffscreen = false

  /// A `ZStack`, not an `.overlay` on the scroll view. The scroll view ignores the top
  /// safe area so the gallery runs behind the status bar; the stack itself respects it,
  /// which is what puts the back button below the clock instead of under it. The bar's
  /// own background reaches back up over the status bar.
  var body: some View {
    ZStack(alignment: .top) {
      scrollView

      topBar
    }
    .background(Color.themeColor(.surfacesBackground))
    .toolbarVisibility(
      .hidden,
      for: .navigationBar
    )
    .task { await viewModel.loadDetail() }
  }
}

// MARK: - Getters

private extension RecipeDetailView {
  var bottomPadding: CGFloat {
    40
  }

  /// Tuned on device: the bar arms just as the recipe's name leaves the top of the screen.
  /// Derived from the gallery's height rather than measured, so a change to the sheet's
  /// overlap or its top paddings has to be re-tuned here.
  var stickyBarThreshold: CGFloat {
    RecipeGallery.baseHeight - 78
  }
}

// MARK: - Subviews

private extension RecipeDetailView {
  var scrollView: some View {
    ScrollView(.vertical) {
      VStack(
        alignment: .leading,
        spacing: 0
      ) {
        RecipeGallery(
          urls: viewModel.galleryURLs,
          accessibilityTitle: viewModel.title
        )

        RecipeDetailSheet(viewModel: viewModel)
      }
      .padding(
        .bottom,
        bottomPadding
      )
    }
    .scrollIndicators(.hidden)
    .ignoresSafeArea(edges: .top)
    .onScrollGeometryChange(for: Bool.self) { geometry in
      geometry.contentOffset.y > stickyBarThreshold
    } action: { _, isOffscreen in
      isTitleOffscreen = isOffscreen
    }
  }

  var topBar: some View {
    RecipeDetailTopBar(
      title: viewModel.title,
      isTitleOffscreen: isTitleOffscreen,
      onBackTap: onBackTap
    )
  }
}

#if DEBUG
  #Preview("Loaded") {
    NavigationStack {
      RecipeDetailView(
        viewModel: MockRecipeDetailViewModel.loaded(),
        onBackTap: {}
      )
    }
  }

  #Preview("Loading") {
    NavigationStack {
      RecipeDetailView(
        viewModel: MockRecipeDetailViewModel.loading(),
        onBackTap: {}
      )
    }
  }

  #Preview("Failed") {
    NavigationStack {
      RecipeDetailView(
        viewModel: MockRecipeDetailViewModel.failed(),
        onBackTap: {}
      )
    }
  }

  #Preview("No photographs") {
    NavigationStack {
      RecipeDetailView(
        viewModel: MockRecipeDetailViewModel.noPhotographs(),
        onBackTap: {}
      )
    }
  }

  #Preview("Nothing to cook with") {
    NavigationStack {
      RecipeDetailView(
        viewModel: MockRecipeDetailViewModel.withoutABody(),
        onBackTap: {}
      )
    }
  }

  #Preview("Metrics missing") {
    NavigationStack {
      RecipeDetailView(
        viewModel: MockRecipeDetailViewModel.missingMetrics(),
        onBackTap: {}
      )
    }
  }

  #Preview("Loaded — AX3") {
    NavigationStack {
      RecipeDetailView(
        viewModel: MockRecipeDetailViewModel.partiallyChecked(),
        onBackTap: {}
      )
    }
    .environment(
      \.dynamicTypeSize,
      .accessibility3
    )
  }
#endif
