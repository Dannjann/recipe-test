//
//  HomeView.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

struct HomeView: View {
  let viewModel: any HomeViewModelProtocol
  let onSearchTap: VoidResult
  let onRecipeTap: SingleResult<String>
  let onCategoryTap: SingleResult<RecipeCategory>

  var body: some View {
    ScrollView(.vertical) {
      VStack(alignment: .leading, spacing: 0) {
        logo

        HomeSearchPill(onTap: onSearchTap)

        HomeSectionHeader(title: .Home.homeLatestRecipesTitle)
        LatestRecipesSection(viewModel: viewModel, onRecipeTap: onRecipeTap)

        HomeSectionHeader(title: .Home.homeCategoriesTitle)
        CategoriesSection(viewModel: viewModel, onCategoryTap: onCategoryTap)
      }
      .padding(.bottom, 40)
    }
    .scrollIndicators(.hidden)
    .background(Color.themeColor(.surfacesBackground))
    .toolbarVisibility(.hidden, for: .navigationBar)
    .refreshable { await viewModel.loadContent() }
    .task { await viewModel.loadContent() }
  }
}

// MARK: - Subviews

private extension HomeView {
  var logo: some View {
    Image(.bokkieBitesLogo)
      .resizable()
      .scaledToFit()
      .frame(width: 112)
      .padding(.leading, 20)
      .padding(.top, 8)
      .padding(.bottom, 20)
      .accessibilityLabel(Text(.Home.homeLogoAccessibilityLabel))
      .accessibilityAddTraits(.isHeader)
  }
}

#Preview("Loaded") {
  NavigationStack {
    HomeView(
      viewModel: MockHomeViewModel.loaded(),
      onSearchTap: {},
      onRecipeTap: { _ in },
      onCategoryTap: { _ in }
    )
  }
}

#Preview("Loading") {
  NavigationStack {
    HomeView(
      viewModel: MockHomeViewModel.loading(),
      onSearchTap: {},
      onRecipeTap: { _ in },
      onCategoryTap: { _ in }
    )
  }
}

#Preview("Recipes failed") {
  NavigationStack {
    HomeView(
      viewModel: MockHomeViewModel.recipesFailed(),
      onSearchTap: {},
      onRecipeTap: { _ in },
      onCategoryTap: { _ in }
    )
  }
}

#Preview("Empty") {
  NavigationStack {
    HomeView(
      viewModel: MockHomeViewModel.empty(),
      onSearchTap: {},
      onRecipeTap: { _ in },
      onCategoryTap: { _ in }
    )
  }
}

#Preview("Loaded — AX3") {
  NavigationStack {
    HomeView(
      viewModel: MockHomeViewModel.loaded(),
      onSearchTap: {},
      onRecipeTap: { _ in },
      onCategoryTap: { _ in }
    )
  }
  .environment(\.dynamicTypeSize, .accessibility3)
}
