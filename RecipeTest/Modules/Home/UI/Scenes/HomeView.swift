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

// MARK: - LatestRecipesSection

/// A `View`, not a computed property: a computed one is inlined and would invalidate all of `HomeView`.
private struct LatestRecipesSection: View {
  let viewModel: any HomeViewModelProtocol
  let onRecipeTap: SingleResult<String>

  @ScaledMetric(relativeTo: .body) private var minHeight: CGFloat = LatestRecipeCard.baseHeight

  var body: some View {
    SectionStateView(
      state: viewModel.latestRecipes,
      minHeight: minHeight,
      emptyMessage: .Home.homeLatestRecipesEmpty,
      onRetryTap: { Task { await viewModel.loadLatestRecipes() } }
    ) { recipes in
      LatestRecipeCarousel(recipes: recipes, onRecipeTap: onRecipeTap)
    }
  }
}

// MARK: - CategoriesSection

private struct CategoriesSection: View {
  let viewModel: any HomeViewModelProtocol
  let onCategoryTap: SingleResult<RecipeCategory>

  @ScaledMetric(relativeTo: .body) private var minHeight: CGFloat = RecipeCategoryTile.baseWidth

  var body: some View {
    SectionStateView(
      state: viewModel.categories,
      minHeight: minHeight,
      emptyMessage: .Home.homeCategoriesEmpty,
      onRetryTap: { Task { await viewModel.loadCategories() } }
    ) { categories in
      RecipeCategoryGrid(categories: categories, onCategoryTap: onCategoryTap)
    }
  }
}

// MARK: - LatestRecipeCarousel

private struct LatestRecipeCarousel: View {
  let recipes: [RecipeSummary]
  let onRecipeTap: SingleResult<String>

  var body: some View {
    ScrollView(.horizontal) {
      LazyHStack(spacing: 14) {
        ForEach(recipes) { recipe in
          LatestRecipeCard(recipe: recipe, onTap: onRecipeTap)
        }
      }
      .scrollTargetLayout()
      // Paired with the negative padding below: room for cardShadow, which the scroll view clips.
      .padding(.vertical, 16)
    }
    .scrollIndicators(.hidden)
    .scrollTargetBehavior(.viewAligned)
    // Not `.padding`: `.viewAligned` snaps to the content edge, which padding does not move.
    .contentMargins(.horizontal, 20, for: .scrollContent)
    .padding(.vertical, -16)
    .accessibilityLabel(Text(.Home.homeLatestRecipesTitle))
  }
}

// MARK: - RecipeCategoryGrid

private struct RecipeCategoryGrid: View {
  let categories: [RecipeCategory]
  let onCategoryTap: SingleResult<RecipeCategory>

  @ScaledMetric(relativeTo: .body) private var tileWidth: CGFloat = RecipeCategoryTile.baseWidth

  /// Adaptive, not a fixed three: the tile has to shed columns at accessibility sizes.
  private var columns: [GridItem] {
    [GridItem(.adaptive(minimum: tileWidth), spacing: 14)]
  }

  var body: some View {
    LazyVGrid(columns: columns, spacing: 18) {
      ForEach(categories) { category in
        RecipeCategoryTile(category: category, onTap: onCategoryTap)
      }
    }
    .padding(.horizontal, 20)
  }
}

// MARK: - Previews

#if DEBUG
  @Observable
  private final class PreviewHomeViewModel: HomeViewModelProtocol {
    var latestRecipes: SectionState<[RecipeSummary]>
    var categories: SectionState<[RecipeCategory]>

    init(
      latestRecipes: SectionState<[RecipeSummary]>,
      categories: SectionState<[RecipeCategory]>
    ) {
      self.latestRecipes = latestRecipes
      self.categories = categories
    }

    func loadContent() async {}
    func loadLatestRecipes() async {}
    func loadCategories() async {}
  }

  private extension RecipeSummary {
    static func preview(_ id: String, _ title: String) -> RecipeSummary {
      RecipeSummary(
        id: id,
        title: title,
        heroImageURL: nil,
        category: "Meal",
        cuisine: "filipino",
        mealType: "dinner",
        totalTimeMinutes: 45,
        servings: 4,
        difficulty: .easy,
        isVegetarian: false
      )
    }
  }

  private extension RecipeCategory {
    static func preview(_ id: String, _ name: String) -> RecipeCategory {
      RecipeCategory(id: id, name: name, imageURL: nil, recipeCount: 4)
    }
  }

  private let previewRecipes: [RecipeSummary] = [
    .preview("rcp-001", "Chicken Adobo"),
    .preview("rcp-002", "Pavlova"),
    .preview("rcp-003", "Gỏi Cuốn"),
    .preview("rcp-004", "Pão de Queijo"),
    .preview("rcp-005", "Pad Thai"),
    .preview("rcp-006", "Leche Flan"),
  ]

  private let previewCategories: [RecipeCategory] = [
    .preview("cat-01", "Meal"),
    .preview("cat-02", "Rice"),
    .preview("cat-03", "Snacks"),
    .preview("cat-04", "Desserts"),
    .preview("cat-05", "Vegan"),
    .preview("cat-06", "Pasta"),
  ]

  private func previewHome(
    latestRecipes: SectionState<[RecipeSummary]>,
    categories: SectionState<[RecipeCategory]>
  ) -> some View {
    NavigationStack {
      HomeView(
        viewModel: PreviewHomeViewModel(latestRecipes: latestRecipes, categories: categories),
        onSearchTap: {},
        onRecipeTap: { _ in },
        onCategoryTap: { _ in }
      )
    }
  }

  #Preview("Loaded") {
    previewHome(latestRecipes: .loaded(previewRecipes), categories: .loaded(previewCategories))
  }

  #Preview("Loading") {
    previewHome(latestRecipes: .loading, categories: .loading)
  }

  #Preview("Recipes failed, categories loaded") {
    previewHome(
      latestRecipes: .failed("The Internet connection appears to be offline."),
      categories: .loaded(previewCategories)
    )
  }

  #Preview("Empty") {
    previewHome(latestRecipes: .empty, categories: .empty)
  }

  #Preview("Loaded — AX3") {
    previewHome(latestRecipes: .loaded(previewRecipes), categories: .loaded(previewCategories))
      .environment(\.dynamicTypeSize, .accessibility3)
  }
#endif
