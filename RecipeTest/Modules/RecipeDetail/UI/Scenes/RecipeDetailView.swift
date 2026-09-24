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
      .navigationBarTitleDisplayMode(.inline)
      .toolbar { titleItem }
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

  /// Transparent until the recipe's own name has gone: two copies of it on screen at once is
  /// what the fade exists to avoid.
  var titleOpacity: Double {
    isTitleOffscreen ? 1 : 0
  }

  var titleLineLimit: Int {
    1
  }

  var toolbarBackgroundVisibility: Visibility {
    isTitleOffscreen ? .visible : .hidden
  }

  /// The bar's background is only half of what the system draws up there. The scroll edge
  /// effect blurs whatever sits under the bar on its own terms and does not answer to
  /// `toolbarBackgroundVisibility`, so leaving it alone frosted the top of the gallery
  /// while the bar itself was transparent. It arms on the same condition as the background.
  var isScrollEdgeEffectHidden: Bool {
    !isTitleOffscreen
  }
}

// MARK: - Subviews

private extension RecipeDetailView {
  /// Styled here rather than left to `navigationTitle`: this screen's bar does not pick up
  /// the title attributes `UINavigationBar.applyThemeAppearance` installs, so the name
  /// rendered in the system font while the list's own title rendered in the app's.
  @ToolbarContentBuilder
  var titleItem: some ToolbarContent {
    ToolbarItem(placement: .principal) {
      Text(viewModel.title)
        .themeTextStyle(.title2)
        .themeColor(.textPrimary)
        .lineLimit(titleLineLimit)
        .opacity(titleOpacity)
        .accessibilityAddTraits(.isHeader)
        .accessibilityHidden(!isTitleOffscreen)
    }
  }

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
    .scrollEdgeEffectHidden(
      isScrollEdgeEffectHidden,
      for: .top
    )
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
