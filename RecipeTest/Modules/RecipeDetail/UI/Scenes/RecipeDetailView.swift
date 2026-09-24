//
//  RecipeDetailView.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

/// The system navigation bar, not a bar of its own: hiding it is what took the interactive
/// swipe back with it. The bar stays transparent over the gallery and only takes on its
/// background and title once the recipe's name has scrolled away, which is how the screen
/// behaved when it drew that bar itself.
struct RecipeDetailView: View {
  let viewModel: any RecipeDetailViewModelProtocol

  @State private var isTitleOffscreen = false

  var body: some View {
    scrollView
      .background(Color.themeColor(.surfacesBackground))
      .navigationTitle(navigationTitle)
      .navigationBarTitleDisplayMode(.inline)
      .toolbarBackgroundVisibility(
        toolbarBackgroundVisibility,
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
  var titleFade: Animation {
    .easeOut(duration: 0.25)
  }

  var stickyBarThreshold: CGFloat {
    RecipeGallery.baseHeight - stickyBarLead
  }

  /// How far above the gallery's bottom edge the title has already scrolled out of reach.
  var stickyBarLead: CGFloat {
    78
  }

  /// Empty until the recipe's own name has gone: two copies of it on screen at once is what
  /// the fade exists to avoid.
  var navigationTitle: String {
    isTitleOffscreen ? viewModel.title : ""
  }

  var toolbarBackgroundVisibility: Visibility {
    isTitleOffscreen ? .visible : .hidden
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
    .onScrollGeometryChange(
      for: Bool.self,
      of: { geometry in
        geometry.contentOffset.y > stickyBarThreshold
      },
      action: { _, isOffscreen in
        withAnimation(titleFade) { isTitleOffscreen = isOffscreen }
      }
    )
  }
}

#if DEBUG
  #Preview("Loaded") {
    NavigationStack {
      RecipeDetailView(
        viewModel: MockRecipeDetailViewModel.loaded()
      )
    }
  }

  #Preview("Loading") {
    NavigationStack {
      RecipeDetailView(
        viewModel: MockRecipeDetailViewModel.loading()
      )
    }
  }

  #Preview("Failed") {
    NavigationStack {
      RecipeDetailView(
        viewModel: MockRecipeDetailViewModel.failed()
      )
    }
  }

  #Preview("No photographs") {
    NavigationStack {
      RecipeDetailView(
        viewModel: MockRecipeDetailViewModel.noPhotographs()
      )
    }
  }

  #Preview("Nothing to cook with") {
    NavigationStack {
      RecipeDetailView(
        viewModel: MockRecipeDetailViewModel.withoutABody()
      )
    }
  }

  #Preview("Metrics missing") {
    NavigationStack {
      RecipeDetailView(
        viewModel: MockRecipeDetailViewModel.missingMetrics()
      )
    }
  }

  #Preview("Loaded — AX3") {
    NavigationStack {
      RecipeDetailView(
        viewModel: MockRecipeDetailViewModel.partiallyChecked()
      )
    }
    .environment(
      \.dynamicTypeSize,
      .accessibility3
    )
  }
#endif
