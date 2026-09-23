//
//  RecipeListView.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

struct RecipeListView: View {
  @Environment(\.theme) var theme: any ThemeProtocol

  let viewModel: any RecipeListViewModelProtocol
  var onRecipeTap: SingleResult<RecipeSummary> = DefaultClosure.singleResult()

  var body: some View {
    VStack(spacing: 0) {
      RecipeSearchBar()
        .padding(.horizontal, RecipeListLayout.spacing)
        .padding(.bottom, RecipeListLayout.spacing)

      content
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(theme.color.surfacesBackground.color)
    .navigationTitle(.Recipe.recipeListTitle)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        RecipeLayoutToggle(layout: viewModel.layout) { layout in
          viewModel.select(layout: layout)
        }
      }
    }
    .task {
      await viewModel.loadFirstPage()
    }
  }
}

// MARK: - Subviews

private extension RecipeListView {
  @ViewBuilder
  var content: some View {
    switch viewModel.loadState {
    case .idle, .loading:
      ProgressView()
        .frame(maxWidth: .infinity, maxHeight: .infinity)

    case let .failed(message):
      messageStateView(
        title: message,
        detail: nil,
        retry: { await viewModel.loadFirstPage() }
      )

    case .loaded:
      if viewModel.recipes.isEmpty {
        emptyState
      } else {
        scroller
      }
    }
  }

  /// LazyVStack, not a plain one: a ScrollView builds every child eagerly, which would
  /// request page 2 on the first frame. Pairs with the footer's `.task(id:)` to re-fire.
  var scroller: some View {
    ScrollView {
      LazyVStack(spacing: 0) {
        LazyVGrid(
          columns: viewModel.layout.columns,
          spacing: RecipeListLayout.spacing
        ) {
          ForEach(viewModel.recipes) { recipe in
            RecipeCard(recipe: recipe, layout: viewModel.layout)
              .onTapGesture {
                onRecipeTap(recipe)
              }
              .accessibilityAddTraits(.isButton)
          }
        }
        .animation(.snappy, value: viewModel.layout)

        // Outside the grid so the footer spans both columns instead of one cell.
        footer
      }
      .padding(.horizontal, RecipeListLayout.spacing)
    }
    .refreshable {
      await viewModel.refresh()
    }
  }

  var emptyState: some View {
    GeometryReader { proxy in
      ScrollView {
        messageStateView(
          title: String(localized: .Recipe.recipeListEmptyTitle),
          detail: String(localized: .Recipe.recipeListEmptyMessage),
          retry: nil
        )
        .frame(minHeight: proxy.size.height)
      }
      .refreshable {
        await viewModel.refresh()
      }
    }
  }

  @ViewBuilder
  var footer: some View {
    if viewModel.hasLoadedAllData {
      EmptyView()
    } else if let nextPageError = viewModel.nextPageError {
      VStack(spacing: Self.messageSpacing) {
        Text(nextPageError)
          .font(theme.textStyle.footnoteRegular.font)
          .foregroundStyle(theme.color.textSecondary.color)
          .multilineTextAlignment(.center)

        Button(String(localized: .Recipe.recipeListErrorRetry)) {
          Task { await viewModel.loadNextPage() }
        }
        .font(theme.textStyle.bodySemibold.font)
      }
      .padding(.vertical, RecipeListLayout.spacing)
    } else {
      ProgressView()
        .padding(.vertical, RecipeListLayout.spacing)
        .task(id: viewModel.recipes.count) {
          await viewModel.loadNextPage()
        }
    }
  }

  func messageStateView(
    title: String,
    detail: String?,
    retry: (() async -> Void)?
  ) -> some View {
    VStack(spacing: Self.messageSpacing) {
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

      if let retry {
        Button(String(localized: .Recipe.recipeListErrorRetry)) {
          Task { await retry() }
        }
        .font(theme.textStyle.bodySemibold.font)
        .padding(.top, Self.retryTopPadding)
      }
    }
    .padding(RecipeListLayout.spacing * 2)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

// MARK: - Constants

private extension RecipeListView {
  static var messageSpacing: CGFloat {
    8
  }

  static var retryTopPadding: CGFloat {
    4
  }
}

// MARK: - Previews

#if DEBUG

  #Preview("Loaded — list") {
    NavigationStack {
      RecipeListView(viewModel: MockRecipeListViewModel())
    }
  }

  #Preview("Loaded — grid") {
    NavigationStack {
      RecipeListView(viewModel: MockRecipeListViewModel(layout: .grid))
    }
  }

  #Preview("Loading next page") {
    NavigationStack {
      RecipeListView(
        viewModel: MockRecipeListViewModel(isLoadingNextPage: true, hasLoadedAllData: false)
      )
    }
  }

  #Preview("Next page failed") {
    NavigationStack {
      RecipeListView(
        viewModel: MockRecipeListViewModel(
          nextPageError: AppError.noInternetConnection.localizedDescription,
          hasLoadedAllData: false
        )
      )
    }
  }

  #Preview("Empty") {
    NavigationStack {
      RecipeListView(viewModel: MockRecipeListViewModel(recipes: []))
    }
  }

  #Preview("Failed") {
    NavigationStack {
      RecipeListView(
        viewModel: MockRecipeListViewModel(
          recipes: [],
          loadState: .failed(AppError.noInternetConnection.localizedDescription)
        )
      )
    }
  }

  #Preview("Loading") {
    NavigationStack {
      RecipeListView(viewModel: MockRecipeListViewModel(recipes: [], loadState: .loading))
    }
  }

#endif
