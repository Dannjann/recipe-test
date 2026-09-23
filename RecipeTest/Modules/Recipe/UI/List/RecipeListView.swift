//
//  RecipeListView.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

struct RecipeListView: View {
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
    .background(Color.themeColor(.surfacesBackground))
    .navigationTitle(Text(String(localized: .Recipe.recipeListTitle)))
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
      messageState(
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
        messageState(
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
      VStack(spacing: 8) {
        Text(nextPageError)
          .themeTextStyle(.footnoteRegular)
          .themeColor(.textSecondary)
          .multilineTextAlignment(.center)

        Button(String(localized: .Recipe.recipeListErrorRetry)) {
          Task { await viewModel.loadNextPage() }
        }
        .themeTextStyle(.bodySemibold)
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

  func messageState(
    title: String,
    detail: String?,
    retry: (() async -> Void)?
  ) -> some View {
    VStack(spacing: 8) {
      Text(title)
        .themeTextStyle(.bodySemibold)
        .themeColor(.textPrimary)
        .multilineTextAlignment(.center)

      if let detail {
        Text(detail)
          .themeTextStyle(.subheadlineRegular)
          .themeColor(.textSecondary)
          .multilineTextAlignment(.center)
      }

      if let retry {
        Button(String(localized: .Recipe.recipeListErrorRetry)) {
          Task { await retry() }
        }
        .themeTextStyle(.bodySemibold)
        .padding(.top, 4)
      }
    }
    .padding(RecipeListLayout.spacing * 2)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
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
