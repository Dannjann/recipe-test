//
//  HomeViewModel.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

@Observable
final class HomeViewModel: HomeViewModelProtocol {
  private(set) var latestRecipes: SectionState<[RecipeSummary]> = .loading
  private(set) var categories: SectionState<[RecipeCategory]> = .loading

  private var latestRecipesGeneration = 0
  private var categoriesGeneration = 0

  private let recipeService: RecipeServiceProtocol

  init(recipeService: RecipeServiceProtocol) {
    self.recipeService = recipeService
  }
}

// MARK: - Getters

private extension HomeViewModel {
  /// The prototype's carousel length. A teaser, not a page: nothing here paginates.
  var latestRecipesPageSize: Int {
    6
  }
}

// MARK: - Inputs

extension HomeViewModel {
  func loadContent() async {
    async let recipesLoad: Void = loadLatestRecipes()
    async let categoriesLoad: Void = loadCategories()

    _ = await (recipesLoad, categoriesLoad)
  }

  func loadLatestRecipes() async {
    latestRecipesGeneration += 1
    let generation = latestRecipesGeneration
    let previous = latestRecipes
    latestRecipes = previous.refreshing

    do {
      let page = try await recipeService.getRecipes(
        query: RecipeQuery(sort: .latest),
        page: Page(
          index: 1,
          size: latestRecipesPageSize
        )
      )

      guard generation == latestRecipesGeneration else { return }

      latestRecipes = .rows(page.recipes)
    } catch {
      guard generation == latestRecipesGeneration else { return }

      latestRecipes = previous.recovering(from: error)
    }
  }

  func loadCategories() async {
    categoriesGeneration += 1
    let generation = categoriesGeneration
    let previous = categories
    categories = previous.refreshing

    do {
      let loaded = try await recipeService.getCategories()

      guard generation == categoriesGeneration else { return }

      categories = .rows(loaded)
    } catch {
      guard generation == categoriesGeneration else { return }

      categories = previous.recovering(from: error)
    }
  }
}
