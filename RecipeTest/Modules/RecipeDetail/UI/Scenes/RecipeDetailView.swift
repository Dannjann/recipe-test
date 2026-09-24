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

  @ScaledMetric(relativeTo: .body) private var galleryHeight: CGFloat = RecipeGallery.baseHeight

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

  /// The prototype turns the bar on once the recipe's name is within 104pt of the top.
  /// The name sits 78pt below the gallery, so the trigger is the gallery's height less 78.
  var stickyBarThreshold: CGFloat {
    galleryHeight - 78
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
